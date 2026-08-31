const express = require('express');
const { db } = require('../db');
const { predict } = require('../ml_bridge/crop_recommendation/predict');

const router = express.Router();

router.post('/', (req, res) => {
  const { id, nitrogen, phosphorus, potassium, ph, organicCarbon, rainfallMm, temperatureC, humidityPct } = req.body;
  if (!id || nitrogen == null || phosphorus == null || potassium == null || ph == null) {
    return res.status(400).json({ error: 'id, nitrogen, phosphorus, potassium, ph are required' });
  }

  const soil = {
    nitrogen,
    phosphorus,
    potassium,
    ph,
    organicCarbon: organicCarbon ?? 0,
    rainfallMm: rainfallMm ?? 0,
    temperatureC: temperatureC ?? 0,
    humidityPct: humidityPct ?? 0,
  };

  db.prepare(
    `INSERT OR REPLACE INTO soil_reports
      (id, nitrogen, phosphorus, potassium, ph, organic_carbon, rainfall_mm, temperature_c, humidity_pct, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    id,
    soil.nitrogen,
    soil.phosphorus,
    soil.potassium,
    soil.ph,
    soil.organicCarbon,
    soil.rainfallMm,
    soil.temperatureC,
    soil.humidityPct,
    new Date().toISOString()
  );

  res.status(201).json({ id, recommendations: predict(soil) });
});

module.exports = router;
