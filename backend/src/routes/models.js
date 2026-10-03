const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const MODELS_ROOT = path.join(__dirname, '..', '..', 'assets', 'models', 'disease');

// Crop id comes from the URL — restrict to a safe charset before ever
// touching the filesystem, so a request can't path-traverse out of
// assets/models/disease/ (e.g. cropId="../../..").
const CROP_ID_PATTERN = /^[a-z_]+$/;

function cropDir(cropId) {
  if (!CROP_ID_PATTERN.test(cropId)) return null;
  const dir = path.join(MODELS_ROOT, cropId);
  // Defense in depth: confirm the resolved path is still inside MODELS_ROOT.
  if (!dir.startsWith(MODELS_ROOT + path.sep)) return null;
  return dir;
}

// Backs the app's per-crop "download updated model" action (ModelManager in
// core/ml/model_manager.dart) — an alternative delivery path to bundling
// each crop's model.tflite directly in the app's assets, so updated models
// don't need an app-store release. See backend/assets/models/disease/README.md.
router.get('/disease/:cropId', (req, res) => {
  const dir = cropDir(req.params.cropId);
  if (!dir) return res.status(400).json({ error: 'Invalid cropId' });
  const modelPath = path.join(dir, 'model.tflite');
  if (!fs.existsSync(modelPath)) {
    return res.status(404).json({
      error: `No trained model uploaded yet for "${req.params.cropId}". Drop model.tflite into backend/assets/models/disease/${req.params.cropId}/.`,
    });
  }
  res.sendFile(modelPath);
});

router.get('/disease/:cropId/manifest', (req, res) => {
  const dir = cropDir(req.params.cropId);
  if (!dir) return res.status(400).json({ error: 'Invalid cropId' });
  const manifestPath = path.join(dir, 'manifest.json');
  if (fs.existsSync(manifestPath)) {
    return res.sendFile(manifestPath);
  }
  res.json({
    cropId: req.params.cropId,
    modelId: `${req.params.cropId}_disease_detection_v0`,
    version: '0.0.0-placeholder',
    isPlaceholder: true,
  });
});

router.get('/disease/:cropId/labels', (req, res) => {
  const dir = cropDir(req.params.cropId);
  if (!dir) return res.status(400).json({ error: 'Invalid cropId' });
  const labelsPath = path.join(dir, 'labels.txt');
  if (!fs.existsSync(labelsPath)) {
    return res.status(404).json({ error: `No labels.txt for "${req.params.cropId}".` });
  }
  res.type('text/plain').sendFile(labelsPath);
});

// Crop recommendation is a single model (not one per crop) — backs
// CropRecommendationMlService's download action, same pattern as the
// disease routes above. See backend/assets/models/crop-recommendation/.
const CROP_REC_DIR = path.join(__dirname, '..', '..', 'assets', 'models', 'crop-recommendation');

router.get('/crop-recommendation', (req, res) => {
  const modelPath = path.join(CROP_REC_DIR, 'model.tflite');
  if (!fs.existsSync(modelPath)) {
    return res.status(404).json({
      error: 'No trained model uploaded yet. Drop model.tflite into backend/assets/models/crop-recommendation/.',
    });
  }
  res.sendFile(modelPath);
});

router.get('/crop-recommendation/manifest', (req, res) => {
  const manifestPath = path.join(CROP_REC_DIR, 'manifest.json');
  if (fs.existsSync(manifestPath)) {
    return res.sendFile(manifestPath);
  }
  res.json({ modelId: 'crop_recommendation_v0', version: '0.0.0-placeholder', isPlaceholder: true });
});

router.get('/crop-recommendation/labels', (req, res) => {
  const labelsPath = path.join(CROP_REC_DIR, 'labels.txt');
  if (!fs.existsSync(labelsPath)) {
    return res.status(404).json({ error: 'No labels.txt for crop-recommendation.' });
  }
  res.type('text/plain').sendFile(labelsPath);
});

// Price forecast is also a single model — same pattern again. See
// backend/assets/models/price-forecast/.
const PRICE_FORECAST_DIR = path.join(__dirname, '..', '..', 'assets', 'models', 'price-forecast');

router.get('/price-forecast', (req, res) => {
  const modelPath = path.join(PRICE_FORECAST_DIR, 'model.tflite');
  if (!fs.existsSync(modelPath)) {
    return res.status(404).json({
      error: 'No trained model uploaded yet. Drop model.tflite into backend/assets/models/price-forecast/.',
    });
  }
  res.sendFile(modelPath);
});

router.get('/price-forecast/manifest', (req, res) => {
  const manifestPath = path.join(PRICE_FORECAST_DIR, 'manifest.json');
  if (fs.existsSync(manifestPath)) {
    return res.sendFile(manifestPath);
  }
  res.json({ modelId: 'price_forecast_v0', version: '0.0.0-placeholder', isPlaceholder: true });
});

router.get('/price-forecast/labels', (req, res) => {
  const labelsPath = path.join(PRICE_FORECAST_DIR, 'labels.txt');
  if (!fs.existsSync(labelsPath)) {
    return res.status(404).json({ error: 'No labels.txt for price-forecast.' });
  }
  res.type('text/plain').sendFile(labelsPath);
});

router.get('/price-forecast/volatility-bands', (req, res) => {
  const bandsPath = path.join(PRICE_FORECAST_DIR, 'volatility_bands.json');
  if (!fs.existsSync(bandsPath)) {
    return res.status(404).json({ error: 'No volatility_bands.json for price-forecast.' });
  }
  res.sendFile(bandsPath);
});

module.exports = router;
