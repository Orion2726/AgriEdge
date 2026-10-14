const express = require('express');
const crypto = require('crypto');
const { db } = require('../db');

const router = express.Router();

// Phones identify themselves with the X-AgriEdge-Device header (their short
// P2P id); kept in memory so the control panel can show who is connected.
const devices = new Map();
function trackDevices(req, _res, next) {
  const id = req.get('X-AgriEdge-Device');
  if (id) {
    const d = devices.get(id) ?? { id, firstSeen: new Date().toISOString(), requests: 0 };
    d.lastSeen = new Date().toISOString();
    d.ip = req.ip.replace('::ffff:', '');
    d.lastPath = req.path;
    d.requests += 1;
    devices.set(id, d);
  }
  next();
}

const SEVERITIES = new Set(['low', 'medium', 'high']);
const LABEL_RE = /^[\w .()'-]{1,80}$/;

// ---- Public (phones) --------------------------------------------------------

/** Active official reports; online phones import and relay them over BLE. */
router.get('/server-reports', (req, res) => {
  const now = new Date().toISOString();
  res.json(
    db
      .prepare('SELECT * FROM server_reports WHERE expires_at > ? ORDER BY created_at DESC LIMIT 100')
      .all(now)
      .map((r) => ({
        id: r.id,
        cropId: r.crop_id,
        label: r.label,
        severity: r.severity,
        lat: r.lat,
        lng: r.lng,
        place: r.place,
        note: r.note,
        createdAt: r.created_at,
        expiresAt: r.expires_at,
      }))
  );
});

// ---- Control panel ------------------------------------------------------------

router.get('/admin/overview', (req, res) => {
  const all = (sql, ...a) => db.prepare(sql).all(...a);
  res.json({
    serverTime: new Date().toISOString(),
    devices: [...devices.values()].sort((a, b) => (a.lastSeen < b.lastSeen ? 1 : -1)),
    serverReports: all('SELECT * FROM server_reports ORDER BY created_at DESC LIMIT 100'),
    phoneReports: all(
      `SELECT packet_id, crop_id, label, severity, lat, lng, note, source_device_id, verified, observed_at, received_at
       FROM p2p_events WHERE source_device_id <> 'server' ORDER BY received_at DESC LIMIT 100`
    ),
    detections: all(
      `SELECT id, crop_id, label, confidence, lat, lng, created_at FROM detections
       WHERE id NOT LIKE 'seed-%' ORDER BY created_at DESC LIMIT 50`
    ),
    prices: all('SELECT * FROM prices ORDER BY commodity'),
    msp: all('SELECT * FROM msp_rates ORDER BY crop'),
    orders: all(
      `SELECT o.*, (SELECT group_concat(quantity || ' x ' || product_name, ', ') FROM order_items i WHERE i.order_id = o.id) AS items
       FROM orders o ORDER BY created_at DESC LIMIT 50`
    ),
    soilReports: all('SELECT * FROM soil_reports ORDER BY created_at DESC LIMIT 20'),
  });
});

router.post('/admin/server-reports', (req, res) => {
  const { cropId, label, severity = 'medium', lat, lng, place, note, hours = 72 } = req.body;
  if (!cropId || !LABEL_RE.test(cropId) || !label || !LABEL_RE.test(label)) {
    return res.status(400).json({ error: 'cropId and label are required (letters, numbers, spaces)' });
  }
  if (!SEVERITIES.has(severity)) return res.status(400).json({ error: 'severity must be low, medium or high' });
  const la = Number(lat), lo = Number(lng), h = Number(hours);
  if (!Number.isFinite(la) || !Number.isFinite(lo) || Math.abs(la) > 90 || Math.abs(lo) > 180) {
    return res.status(400).json({ error: 'valid lat and lng are required' });
  }
  if (!Number.isFinite(h) || h <= 0 || h > 24 * 30) return res.status(400).json({ error: 'hours must be 1..720' });
  const id = crypto.randomUUID();
  const now = new Date();
  db.prepare(
    `INSERT INTO server_reports (id, crop_id, label, severity, lat, lng, place, note, created_at, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(id, cropId, label, severity, la, lo, place ?? null, note ? String(note).slice(0, 280) : null,
    now.toISOString(), new Date(now.getTime() + h * 3600000).toISOString());
  res.status(201).json({ id });
});

/** Ends a report early. Phones that already have it keep it until it expires. */
router.delete('/admin/server-reports/:id', (req, res) => {
  const r = db.prepare('UPDATE server_reports SET expires_at = ? WHERE id = ?').run(new Date().toISOString(), req.params.id);
  res.json({ ended: r.changes });
});

router.put('/admin/prices/:id', (req, res) => {
  const price = Number(req.body.pricePerQuintal);
  if (!Number.isFinite(price) || price <= 0) return res.status(400).json({ error: 'pricePerQuintal must be > 0' });
  const today = new Date().toISOString().slice(0, 10);
  const r = db
    .prepare('UPDATE prices SET price_per_quintal = ?, price_date = ?, mandi = COALESCE(?, mandi) WHERE id = ?')
    .run(price, req.body.priceDate || today, req.body.mandi || null, req.params.id);
  res.json({ updated: r.changes });
});

router.post('/admin/prices', (req, res) => {
  const { commodity, mandi } = req.body;
  const price = Number(req.body.pricePerQuintal);
  if (!commodity || !mandi || !Number.isFinite(price) || price <= 0) {
    return res.status(400).json({ error: 'commodity, mandi and a positive pricePerQuintal are required' });
  }
  db.prepare('INSERT INTO prices (commodity, mandi, price_per_quintal, price_date) VALUES (?, ?, ?, ?)').run(
    commodity, mandi, price, new Date().toISOString().slice(0, 10));
  res.status(201).json({ ok: true });
});

router.delete('/admin/prices/:id', (req, res) => {
  res.json({ deleted: db.prepare('DELETE FROM prices WHERE id = ?').run(req.params.id).changes });
});

router.put('/admin/msp/:id', (req, res) => {
  const price = Number(req.body.pricePerQuintal);
  if (!Number.isFinite(price) || price <= 0) return res.status(400).json({ error: 'pricePerQuintal must be > 0' });
  res.json({ updated: db.prepare('UPDATE msp_rates SET price_per_quintal = ? WHERE id = ?').run(price, req.params.id).changes });
});

router.put('/admin/orders/:id', (req, res) => {
  const status = String(req.body.status || '');
  if (!['received', 'packed', 'shipped', 'delivered', 'cancelled'].includes(status)) {
    return res.status(400).json({ error: 'invalid status' });
  }
  res.json({ updated: db.prepare('UPDATE orders SET status = ? WHERE id = ?').run(status, req.params.id).changes });
});

module.exports = { router, trackDevices };
