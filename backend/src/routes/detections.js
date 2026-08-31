const express = require('express');
const { db } = require('../db');

const router = express.Router();

router.post('/', (req, res) => {
  const { id, label, confidence, lat, lng, consentShared, createdAt } = req.body;
  if (!id || !label || confidence == null || !createdAt) {
    return res.status(400).json({ error: 'id, label, confidence, createdAt are required' });
  }

  db.prepare(
    `INSERT OR REPLACE INTO detections (id, label, confidence, lat, lng, consent_shared, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  ).run(id, label, confidence, consentShared ? lat ?? null : null, consentShared ? lng ?? null : null, consentShared ? 1 : 0, createdAt);

  res.status(201).json({ id, status: 'received' });
});

module.exports = router;
