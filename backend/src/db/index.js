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
]) {
  try {
    db.exec(ddl);
  } catch (_) {
    // column already exists
  }
}

/**
 * Sample data only — NOT real Agmarknet/MSP/CACP figures. Swap
 * seedPrices/seedMsp for a real Agmarknet + data.gov.in ingestion job before
 * relying on this for anything but local development. See docs/MODEL_SPECS.md.
 */
function seedIfEmpty() {
  const priceCount = db.prepare('SELECT COUNT(*) AS c FROM prices').get().c;
  if (priceCount === 0) seedPrices();

  const mspCount = db.prepare('SELECT COUNT(*) AS c FROM msp_rates').get().c;
  if (mspCount === 0) seedMsp();

  const productCount = db.prepare('SELECT COUNT(*) AS c FROM products').get().c;
  if (productCount === 0) seedProducts();

  const detectionCount = db.prepare('SELECT COUNT(*) AS c FROM detections').get().c;
  if (detectionCount === 0) seedDetections();

  const regionalCount = db.prepare("SELECT COUNT(*) AS c FROM detections WHERE id LIKE 'seed-region-%'").get().c;
  if (regionalCount === 0) seedRegionalDemo();
}

function seedPrices() {
  const today = new Date().toISOString().slice(0, 10);
  const rows = [
    ['Wheat', 'Azadpur Mandi, Delhi', 2450, today],
    ['Rice', 'Azadpur Mandi, Delhi', 2250, today],
    ['Maize', 'Karnal Mandi', 2000, today],
    ['Cotton', 'Adampur Mandi', 6800, today],
    ['Mustard', 'Alwar Mandi', 5300, today],
    ['Potato', 'Agra Mandi', 1250, today],
    ['Tomato', 'Azadpur Mandi, Delhi', 1600, today],
    ['Soybean', 'Indore Mandi', 4450, today],
  ];
  const insert = db.prepare(
    'INSERT INTO prices (commodity, mandi, price_per_quintal, price_date) VALUES (?, ?, ?, ?)'
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

function seedMsp() {
  const year = new Date().getFullYear();
  const rows = [
    ['Wheat', 'Rabi', year, 2425],
    ['Rice', 'Kharif', year, 2300],
    ['Maize', 'Kharif', year, 2225],
    ['Cotton', 'Kharif', year, 7521],
    ['Mustard', 'Rabi', year, 5950],
    ['Potato', 'Rabi', year, 1200],
    ['Tomato', 'Year-round', year, 1400],
    ['Soybean', 'Kharif', year, 4892],
  ];
  const insert = db.prepare(
    'INSERT INTO msp_rates (crop, season, year, price_per_quintal) VALUES (?, ?, ?, ?)'
  );
  const tx = db.transaction((rows) => rows.forEach((r) => insert.run(...r)));
  tx(rows);
}

function seedProducts() {
  const rows = [
    ['prod-urea', 'Urea (45kg bag)', 'Fertilizer', 266, 'bag', null, 'Nitrogen fertilizer, government-subsidized rate.'],
    ['prod-dap', 'DAP (50kg bag)', 'Fertilizer', 1350, 'bag', null, 'Di-ammonium phosphate for phosphorus deficiency.'],
    ['prod-mop', 'MOP / Potash (50kg bag)', 'Fertilizer', 1700, 'bag', null, 'Muriate of Potash for potassium correction.'],
    ['prod-wheat-seed', 'Certified Wheat Seed (40kg)', 'Seed', 1800, 'bag', null, 'High-yield certified wheat seed variety.'],
    ['prod-rice-seed', 'Certified Rice Seed (25kg)', 'Seed', 1200, 'bag', null, 'High-yield certified paddy seed variety.'],
    ['prod-tomato-seed', 'Hybrid Tomato Seed (10g)', 'Seed', 350, 'packet', null, 'Disease-resistant hybrid tomato variety.'],
    ['prod-sprayer', 'Knapsack Sprayer 16L', 'Equipment', 1450, 'unit', null, 'Manual pesticide/fungicide sprayer.'],
    ['prod-neem-oil', 'Neem Oil Concentrate 1L', 'Pesticide', 420, 'bottle', null, 'Organic pest control, safe pre-harvest interval.'],
    ['prod-hand-tiller', 'Hand Tiller / Khurpi Set', 'Equipment', 350, 'set', null, 'Basic hand tools for weeding and soil prep.'],
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

module.exports = { db, seedIfEmpty };
