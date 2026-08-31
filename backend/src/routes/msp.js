const express = require('express');
const { db } = require('../db');

const router = express.Router();

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT crop, season, year, price_per_quintal FROM msp_rates').all();
  res.json(
    rows.map((r) => ({
      crop: r.crop,
      season: r.season,
      year: r.year,
      pricePerQuintal: r.price_per_quintal,
    }))
  );
});

module.exports = router;
