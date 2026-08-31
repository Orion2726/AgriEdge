const express = require('express');
const { db } = require('../db');

const router = express.Router();

router.post('/', (req, res) => {
  const { id, createdAt, totalAmount, items } = req.body;
  if (!id || !createdAt || !Array.isArray(items)) {
    return res.status(400).json({ error: 'id, createdAt, items[] are required' });
  }

  const insertOrder = db.prepare(
    'INSERT OR REPLACE INTO orders (id, created_at, total_amount, status) VALUES (?, ?, ?, ?)'
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

  res.status(201).json({ id, status: 'received' });
});

module.exports = router;
