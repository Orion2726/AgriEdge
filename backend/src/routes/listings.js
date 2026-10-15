const express = require('express');
const { db } = require('../db');

const router = express.Router();

const CATEGORIES = new Set(['Produce', 'Seed', 'Fertilizer', 'Pesticide', 'Equipment', 'Livestock', 'Other']);
const ID_RE = /^[\w-]{8,64}$/;
const text = (v, max) => (v == null ? null : String(v).trim().slice(0, max) || null);
const device = (req) => req.get('X-AgriEdge-Device') || null;

const toJson = (r) => ({
  id: r.id,
  sellerName: r.seller_name,
  phone: r.phone,
  title: r.title,
  category: r.category,
  quantity: r.quantity,
  unit: r.unit,
  price: r.price,
  place: r.place,
  note: r.note,
  status: r.status,
  mine: false,
  createdAt: r.created_at,
  soldAt: r.sold_at,
});

/** Available listings, plus every listing this phone posted (any status). */
router.get('/', (req, res) => {
  const me = device(req);
  const rows = db
    .prepare(
      `SELECT * FROM listings WHERE status = 'available' OR (? IS NOT NULL AND seller_device = ?)
       ORDER BY created_at DESC LIMIT 200`
    )
    .all(me, me);
  res.json(rows.map((r) => ({ ...toJson(r), mine: me != null && r.seller_device === me })));
});

/** Post a listing. Idempotent on id, so a queued offline post can be retried. */
router.post('/', (req, res) => {
  const b = req.body || {};
  const quantity = Number(b.quantity), price = Number(b.price);
  if (!ID_RE.test(String(b.id || ''))) return res.status(400).json({ error: 'id is required' });
  if (!text(b.title, 80) || !text(b.sellerName, 60)) return res.status(400).json({ error: 'title and sellerName are required' });
  if (!CATEGORIES.has(b.category)) return res.status(400).json({ error: 'unknown category' });
  if (!(quantity > 0) || !(price > 0)) return res.status(400).json({ error: 'quantity and price must be > 0' });
  db.prepare(
    `INSERT INTO listings (id, seller_device, seller_name, phone, title, category, quantity, unit, price, place, note, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO NOTHING`
  ).run(b.id, device(req), text(b.sellerName, 60), text(b.phone, 20), text(b.title, 80), b.category, quantity,
    text(b.unit, 20) || 'unit', price, text(b.place, 80), text(b.note, 280), b.createdAt || new Date().toISOString());
  res.status(201).json(toJson(db.prepare('SELECT * FROM listings WHERE id = ?').get(b.id)));
});

/**
 * Buy a listing. One transaction checks it is still available and marks it
 * sold, so two phones can't buy the same thing. Creates an order the buyer
 * can follow like a store order.
 */
router.post('/:id/buy', (req, res) => {
  const orderId = String(req.body?.orderId || '');
  if (!ID_RE.test(orderId)) return res.status(400).json({ error: 'orderId is required' });
  const me = device(req);
  const result = db.transaction(() => {
    const l = db.prepare('SELECT * FROM listings WHERE id = ?').get(req.params.id);
    if (!l) return { code: 404, error: 'This listing no longer exists.' };
    if (l.status !== 'available') return { code: 409, error: 'Sorry, this was just sold to someone else.' };
    if (me && l.seller_device === me) return { code: 409, error: 'This is your own listing.' };
    const now = new Date().toISOString();
    db.prepare("UPDATE listings SET status = 'sold', buyer_device = ?, order_id = ?, sold_at = ? WHERE id = ?")
      .run(me, orderId, now, l.id);
    db.prepare("INSERT INTO orders (id, created_at, total_amount, status, buyer_device) VALUES (?, ?, ?, 'received', ?)")
      .run(orderId, now, l.price * l.quantity, me);
    db.prepare('INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price) VALUES (?, ?, ?, ?, ?)')
      .run(orderId, `listing:${l.id}`, `${l.title} (${l.quantity} ${l.unit}) from ${l.seller_name}`, 1, l.price * l.quantity);
    return { code: 201, body: { orderId, status: 'received', seller: l.seller_name, phone: l.phone, total: l.price * l.quantity } };
  })();
  if (result.error) return res.status(result.code).json({ error: result.error });
  res.status(result.code).json(result.body);
});

/** Seller takes a listing down. */
router.delete('/:id', (req, res) => {
  const r = db
    .prepare("UPDATE listings SET status = 'withdrawn' WHERE id = ? AND status = 'available' AND seller_device IS ?")
    .run(req.params.id, device(req));
  res.json({ withdrawn: r.changes });
});

module.exports = router;
