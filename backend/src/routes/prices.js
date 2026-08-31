const express = require('express');
const { db } = require('../db');
const { forecast } = require('../ml_bridge/price_forecast/predict');

const router = express.Router();

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT commodity, mandi, price_per_quintal, price_date FROM prices').all();
  res.json(
    rows.map((r) => ({
      commodity: r.commodity,
      mandi: r.mandi,
      pricePerQuintal: r.price_per_quintal,
      priceDate: r.price_date,
    }))
  );
});

// Not yet called from the app UI — see ml_bridge/price_forecast/README.md.
router.get('/forecast/:commodity', (req, res) => {
  const row = db
    .prepare('SELECT price_per_quintal FROM prices WHERE commodity = ? ORDER BY price_date DESC LIMIT 1')
    .get(req.params.commodity);
  if (!row) return res.status(404).json({ error: 'Unknown commodity' });
  res.json({ commodity: req.params.commodity, forecast: forecast(row.price_per_quintal, 7) });
});

module.exports = router;
