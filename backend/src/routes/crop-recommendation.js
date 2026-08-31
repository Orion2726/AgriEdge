const express = require('express');
const { db } = require('../db');
const { predict } = require('../ml_bridge/crop_recommendation/predict');

const router = express.Router();

// Not called by the app UI today (POST /api/soil-reports returns
// recommendations inline) — kept as a standalone endpoint so a stored
// report's recommendation can be recomputed on demand, e.g. after a new
// model is dropped into ml_bridge/crop_recommendation/.
router.get('/:soilReportId', (req, res) => {
  const row = db.prepare('SELECT * FROM soil_reports WHERE id = ?').get(req.params.soilReportId);
  if (!row) return res.status(404).json({ error: 'Soil report not found' });

  const soil = {
    nitrogen: row.nitrogen,
    phosphorus: row.phosphorus,
    potassium: row.potassium,
    ph: row.ph,
    organicCarbon: row.organic_carbon,
    rainfallMm: row.rainfall_mm,
    temperatureC: row.temperature_c,
    humidityPct: row.humidity_pct,
  };
  res.json({ soilReportId: row.id, recommendations: predict(soil) });
});

module.exports = router;
