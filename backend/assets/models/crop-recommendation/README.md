# Crop recommendation model — downloadable copy

This directory backs the app's runtime "download updated model" action for
crop recommendation (`CropRecommendationModelManager.downloadModel()`),
mirroring `app/assets/ml/crop_recommendation/` (the bundled copy shipped
with the app itself). Keep both in sync when retraining.

Files:

- `model.tflite`
- `labels.txt` — one crop name per line, index-aligned with the model's
  output tensor (alphabetical order from training)
- `manifest.json`, e.g.:

```json
{
  "modelId": "crop_recommendation_v1",
  "version": "1.0.0",
  "isPlaceholder": false,
  "inputShape": [1, 7],
  "inputFeatureOrder": ["N", "P", "K", "temperature_c", "humidity_pct", "ph", "rainfall_mm"],
  "inputNormalization": "raw",
  "outputShape": [1, 22],
  "sha256": "<sha256 of model.tflite>"
}
```

`inputNormalization: "raw"` means the model has a `Normalization` layer
baked into the graph and expects raw, unnormalized feature values — see
`docs/MODEL_SPECS.md` section 2 for the full contract and training details.

`GET /api/models/crop-recommendation`, `GET /api/models/crop-recommendation/manifest`,
and `GET /api/models/crop-recommendation/labels` serve these three files as-is.
