const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');

// AGRIEDGE_DB_PATH lets a test run use a throwaway database instead of the
// shared dev one. data/ is gitignored, so it won't exist on a fresh clone.
const DB_PATH =
  process.env.AGRIEDGE_DB_PATH || path.join(__dirname, '..', '..', 'data', 'agriedge.sqlite');
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
db.exec(schema);

// CREATE TABLE IF NOT EXISTS above only applies to fresh databases — patch
// existing local dev DBs that predate newer columns.
for (const ddl of [
  'ALTER TABLE detections ADD COLUMN crop_id TEXT',
  'ALTER TABLE p2p_events ADD COLUMN detection_id TEXT',
  'ALTER TABLE p2p_events ADD COLUMN note TEXT',
  // Which phone uploaded it; differs from source_device_id when a report was
  // carried to the server by another phone over the mesh.
  'ALTER TABLE p2p_events ADD COLUMN uploaded_by TEXT',
  // Where a price came from: mandi-api / data.gov.in / manual (set in the
  // control panel, never overwritten by a fetch) / sample (old seed rows).
  'ALTER TABLE prices ADD COLUMN source TEXT',
  'ALTER TABLE orders ADD COLUMN buyer_device TEXT',
  // Compressed JPEG of the plant from the farmer's phone (field reports).
  'ALTER TABLE p2p_events ADD COLUMN photo BLOB',
]) {
  try {
    db.exec(ddl);
  } catch (_) {
    // column already exists
  }
}

const getSetting = (key) => db.prepare('SELECT value FROM settings WHERE key = ?').get(key)?.value ?? null;
const setSetting = (key, value) =>
  db.prepare('INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value')
    .run(key, value == null ? null : String(value));

/**
 * Mandi prices come from a live source (src/sources/mandi.js); the rows seeded
 * here are only a placeholder until the first fetch. MSP and the store
 * catalogue are real published figures (see docs/DATA_SOURCES.md).
 */
function seedIfEmpty() {
  const priceCount = db.prepare('SELECT COUNT(*) AS c FROM prices').get().c;
  if (priceCount === 0) seedPrices();

  // v2: real MSP + real fertiliser MRPs. Replaces the old sample rows once on
  // databases created before it.
  if (Number(getSetting('data_version') || 0) < 3) {
    db.transaction(() => {
      db.prepare('DELETE FROM msp_rates').run();
      seedMsp();
      db.prepare('DELETE FROM products').run();
      seedProducts();
      db.prepare("UPDATE prices SET source = 'sample' WHERE source IS NULL").run();
      setSetting('data_version', 3);
    })();
  }

  const detectionCount = db.prepare('SELECT COUNT(*) AS c FROM detections').get().c;
  if (detectionCount === 0) seedDetections();

  const regionalCount = db.prepare("SELECT COUNT(*) AS c FROM detections WHERE id LIKE 'seed-region-%'").get().c;
  if (regionalCount === 0) seedRegionalDemo();
}

/** Placeholder until the first live fetch replaces them (source = 'sample'). */
function seedPrices() {
  const today = new Date().toISOString().slice(0, 10);
  const rows = [
    ['Wheat', 'Sample — waiting for live prices', 2600, today],
    ['Rice', 'Sample — waiting for live prices', 2400, today],
    ['Maize', 'Sample — waiting for live prices', 2100, today],
    ['Cotton', 'Sample — waiting for live prices', 7500, today],
    ['Mustard', 'Sample — waiting for live prices', 6300, today],
    ['Potato', 'Sample — waiting for live prices', 1300, today],
    ['Tomato', 'Sample — waiting for live prices', 1600, today],
    ['Soybean', 'Sample — waiting for live prices', 4800, today],
  ];
  const insert = db.prepare(
    "INSERT INTO prices (commodity, mandi, price_per_quintal, price_date, source) VALUES (?, ?, ?, ?, 'sample')"
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

/**
 * Official MSP, ₹/quintal. Kharif 2026-27 (CCEA, 13 May 2026) and Rabi
 * marketing season 2027-28 (CCEA, 30 Sep 2026). Crop names match the mandi
 * commodity names where the app compares the two (Rice = paddy, common;
 * Cotton = medium staple). Potato and tomato have no MSP.
 */
function seedMsp() {
  const rows = [
    ['Rice', 'Kharif 2026-27 (paddy, common)', 2026, 2441],
    ['Maize', 'Kharif 2026-27', 2026, 2410],
    ['Cotton', 'Kharif 2026-27 (medium staple)', 2026, 8267],
    ['Soybean', 'Kharif 2026-27 (yellow)', 2026, 5708],
    ['Bajra', 'Kharif 2026-27', 2026, 2900],
    ['Jowar', 'Kharif 2026-27 (hybrid)', 2026, 4023],
    ['Ragi', 'Kharif 2026-27', 2026, 5205],
    ['Tur (Arhar)', 'Kharif 2026-27', 2026, 8450],
    ['Moong', 'Kharif 2026-27', 2026, 8780],
    ['Urad', 'Kharif 2026-27', 2026, 8200],
    ['Groundnut', 'Kharif 2026-27', 2026, 7517],
    ['Sunflower seed', 'Kharif 2026-27', 2026, 8343],
    ['Sesamum', 'Kharif 2026-27', 2026, 10346],
    ['Nigerseed', 'Kharif 2026-27', 2026, 10052],
    ['Wheat', 'Rabi 2027-28', 2027, 2610],
    ['Mustard', 'Rabi 2027-28 (rapeseed & mustard)', 2027, 6613],
    ['Gram', 'Rabi 2027-28', 2027, 5958],
    ['Masur (Lentil)', 'Rabi 2027-28', 2027, 7390],
    ['Barley', 'Rabi 2027-28', 2027, 2286],
    ['Safflower', 'Rabi 2027-28', 2027, 7215],
  ];
  const insert = db.prepare(
    'INSERT INTO msp_rates (crop, season, year, price_per_quintal) VALUES (?, ?, ?, ?)'
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

/** Urea and DAP are government-fixed MRPs; the rest are typical retail prices. */
function seedProducts() {
  const rows = [
    ['prod-urea', 'Urea (45 kg bag)', 'Fertilizer', 266.5, 'bag', null, 'Neem-coated urea. Government-fixed MRP ₹266.50 per bag.'],
    ['prod-dap', 'DAP 18:46:0 (50 kg bag)', 'Fertilizer', 1350, 'bag', null, 'Di-ammonium phosphate. MRP held at ₹1,350 per bag.'],
    ['prod-mop', 'MOP / Potash (50 kg bag)', 'Fertilizer', 1550, 'bag', null, 'Muriate of potash for potassium. Approx. retail price.'],
    ['prod-npk', 'NPK 10:26:26 (50 kg bag)', 'Fertilizer', 1470, 'bag', null, 'Complex fertiliser for basal dose. Approx. retail price.'],
    ['prod-ssp', 'SSP (50 kg bag)', 'Fertilizer', 550, 'bag', null, 'Single super phosphate, also gives sulphur. Approx. retail price.'],
    ['prod-wheat-seed', 'Certified Wheat Seed (40 kg)', 'Seed', 1800, 'bag', null, 'Certified seed. Approx. retail price.'],
    ['prod-rice-seed', 'Certified Paddy Seed (25 kg)', 'Seed', 1200, 'bag', null, 'Certified seed. Approx. retail price.'],
    ['prod-sprayer', 'Knapsack Sprayer 16 L', 'Equipment', 1450, 'unit', null, 'Manual sprayer. Approx. retail price.'],
    ['prod-neem-oil', 'Neem Oil 1500 ppm (1 L)', 'Pesticide', 420, 'bottle', null, 'Botanical pest control. Approx. retail price.'],
  ];
  const insert = db.prepare(
    'INSERT INTO products (id, name, category, price_per_unit, unit, image_url, description) VALUES (?, ?, ?, ?, ?, ?, ?)'
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

function seedDetections() {
  // Clustered near a demo coordinate (Delhi) so the nearby-alerts feature
  // has something to show out of the box. Replace with real crowdsourced
  // data once farmers are actually using the app.
  const base = { lat: 28.6139, lng: 77.209 };
  const now = Date.now();
  const jitter = () => (Math.random() - 0.5) * 0.08; // ~ +/- 4km
  const rows = [];
  const clusters = [
    { cropId: 'potato', label: 'Potato___Late_blight', count: 5 },
    { cropId: 'rice', label: 'blast', count: 4 },
    { cropId: 'wheat', label: 'Yellow Rust', count: 2 },
  ];
  let idSeq = 1;
  for (const cluster of clusters) {
    for (let i = 0; i < cluster.count; i++) {
      rows.push([
        `seed-detection-${idSeq++}`,
        cluster.cropId,
        cluster.label,
        0.7 + Math.random() * 0.25,
        base.lat + jitter(),
        base.lng + jitter(),
        1,
        new Date(now - i * 86400000).toISOString(),
      ]);
    }
  }
  const insert = db.prepare(
    'INSERT INTO detections (id, crop_id, label, confidence, lat, lng, consent_shared, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

/**
 * Demo outbreaks in other states so the app's "Other regions" view has
 * something to show before real farmers report there. Demo data only.
 */
function seedRegionalDemo() {
  const clusters = [
    { cropId: 'wheat', label: 'Yellow Rust', lat: 30.9, lng: 75.85, count: 6 }, // Ludhiana
    { cropId: 'cotton', label: 'Bacterial Blight', lat: 21.15, lng: 79.09, count: 4 }, // Nagpur
    { cropId: 'rice', label: 'blast', lat: 16.51, lng: 80.65, count: 5 }, // Vijayawada
    { cropId: 'rice', label: 'brown_spot', lat: 10.79, lng: 78.7, count: 3 }, // Tiruchirappalli
    { cropId: 'potato', label: 'Potato___Early_blight', lat: 26.85, lng: 80.95, count: 4 }, // Lucknow
    { cropId: 'cotton', label: 'Aphids', lat: 23.02, lng: 72.57, count: 3 }, // Ahmedabad
  ];
  const insert = db.prepare(
    'INSERT INTO detections (id, crop_id, label, confidence, lat, lng, consent_shared, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?)'
  );
  const now = Date.now();
  let seq = 1;
  const tx = db.transaction(() => {
    for (const c of clusters) {
      for (let i = 0; i < c.count; i++) {
        insert.run(
          `seed-region-${seq++}`,
          c.cropId,
          c.label,
          0.7 + Math.random() * 0.25,
          c.lat + (Math.random() - 0.5) * 0.2,
          c.lng + (Math.random() - 0.5) * 0.2,
          new Date(now - i * 43200000).toISOString()
        );
      }
    }
  });
  tx();
}

module.exports = { db, seedIfEmpty, getSetting, setSetting };
