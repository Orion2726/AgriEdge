const express = require('express');
const { db } = require('../db');

const router = express.Router();

router.post('/', (req, res) => {
  const { id, createdAt, totalAmount, items } = req.body;
  if (!id || !createdAt || !Array.isArray(items)) {
    return res.status(400).json({ error: 'id, createdAt, items[] are required' });
  }

  const insertOrder = db.prepare(
    `INSERT INTO orders (id, created_at, total_amount, status) VALUES (?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET total_amount = excluded.total_amount`
  );
  const insertItem = db.prepare(
    'INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price) VALUES (?, ?, ?, ?, ?)'
  );
  const deleteExistingItems = db.prepare('DELETE FROM order_items WHERE order_id = ?');

  const tx = db.transaction(() => {
    insertOrder.run(id, createdAt, totalAmount ?? 0, 'received');
    deleteExistingItems.run(id);
    for (const item of items) {
      insertItem.run(id, item.productId, item.productName, item.quantity, item.unitPrice);
    }
  });
  tx();

  const { status } = db.prepare('SELECT status FROM orders WHERE id = ?').get(id);
  res.status(201).json({ id, status });
});

// Phones poll their orders' status so changes made in the control panel
// (packed, shipped, delivered…) show up in the app.
router.get('/status', (req, res) => {
  const ids = String(req.query.ids || '').split(',').filter(Boolean).slice(0, 100);
  if (ids.length === 0) return res.json([]);
  const rows = db
    .prepare(`SELECT id, status FROM orders WHERE id IN (${ids.map(() => '?').join(',')})`)
    .all(...ids);
  res.json(rows);
});

module.exports = router;
