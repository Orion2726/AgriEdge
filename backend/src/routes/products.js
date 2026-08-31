const express = require('express');
const { db } = require('../db');

const router = express.Router();

router.get('/', (req, res) => {
  const rows = db
    .prepare('SELECT id, name, category, price_per_unit, unit, image_url, description FROM products')
    .all();
  res.json(
    rows.map((r) => ({
      id: r.id,
      name: r.name,
      category: r.category,
      pricePerUnit: r.price_per_unit,
      unit: r.unit,
      imageUrl: r.image_url,
      description: r.description,
    }))
  );
});

module.exports = router;
