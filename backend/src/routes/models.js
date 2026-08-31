const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const MODEL_DIR = path.join(__dirname, '..', '..', 'assets', 'models', 'disease');
const MODEL_PATH = path.join(MODEL_DIR, 'model.tflite');
const MANIFEST_PATH = path.join(MODEL_DIR, 'manifest.json');

// Backs the app's "download updated model" action (ModelManager in
// core/ml/model_manager.dart) — an alternative delivery path to bundling
// model.tflite directly in the app's assets, so updated models don't need
// an app-store release. See backend/assets/models/disease/README.md.
router.get('/disease', (req, res) => {
  if (!fs.existsSync(MODEL_PATH)) {
    return res
      .status(404)
      .json({ error: 'No trained model uploaded yet. Drop model.tflite into backend/assets/models/disease/.' });
  }
  res.sendFile(MODEL_PATH);
});

router.get('/disease/manifest', (req, res) => {
  if (fs.existsSync(MANIFEST_PATH)) {
    return res.sendFile(MANIFEST_PATH);
  }
  res.json({ modelId: 'disease_detection_v0', version: '0.0.0-placeholder', isPlaceholder: true });
});

module.exports = router;
