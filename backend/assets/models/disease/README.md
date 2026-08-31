# Drop the trained disease-detection model here

Once you've trained and exported the model per `docs/MODEL_SPECS.md`:

1. Copy the `.tflite` export to `model.tflite` in this directory.
2. Add a `manifest.json` here, e.g.:

```json
{
  "modelId": "disease_detection_v1",
  "version": "1.0.0",
  "isPlaceholder": false,
  "inputShape": [1, 224, 224, 3],
  "inputNormalization": "[-1,1]",
  "outputShape": [1, 16],
  "sha256": "<sha256 of model.tflite>"
}
```

`GET /api/models/disease` and `GET /api/models/disease/manifest` serve these
two files as-is — that's what backs the "Download" button on the app's
Sync & Data screen (`ModelManager.downloadLatestModel()`).

This is independent of also bundling the model directly into the Flutter
app at `app/assets/ml/disease/model.tflite` — do both if you want the model
present on first install *and* upgradeable without an app-store release.
