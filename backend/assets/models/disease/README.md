# Drop trained disease-detection models here, one subfolder per crop

Each crop gets its own subdirectory, named to match the crop id used
throughout the app (`app/lib/core/ml/crop_catalog.dart`) — currently
`potato/`, `cotton/`, `rice/`, `wheat/`, `staple_crops/`.

Once you've trained and exported a crop's model per `docs/MODEL_SPECS.md`,
drop these three files into `assets/models/disease/<cropId>/`:

- `model.tflite`
- `labels.txt` — one class name per line, index-aligned with the model's
  output tensor
- `manifest.json`, e.g.:

```json
{
  "cropId": "wheat",
  "displayName": "Wheat",
  "modelId": "wheat_disease_detection_v1",
  "version": "1.0.0",
  "isPlaceholder": false,
  "inputShape": [1, 224, 224, 3],
  "inputNormalization": "[-1,1]",
  "outputShape": [1, 15],
  "sha256": "<sha256 of model.tflite>"
}
```

`inputNormalization` matters: use `"[-1,1]"` if the app must pre-normalize
pixels to [-1,1] before inference (e.g. a plain `tf.keras.applications.MobileNetV2`
export), or `"raw_0_255"` if the model has rescaling baked into the graph
itself and expects raw pixel values (e.g. `tf.keras.applications.MobileNetV3*`,
which bundles a `Rescaling` layer by default) — feeding the wrong convention
silently produces garbage predictions instead of an error. Check the graph's
first couple of ops if you're not sure which one a given export needs.

`GET /api/models/disease/:cropId`, `GET /api/models/disease/:cropId/manifest`,
and `GET /api/models/disease/:cropId/labels` serve these three files as-is —
that's what backs the per-crop "Download" buttons on the app's Sync & Data
screen (`ModelManager.downloadModel(cropId)`).

This is independent of also bundling each crop's model directly into the
Flutter app at `app/assets/ml/disease/<cropId>/` — do both if you want the
model present on first install *and* upgradeable without an app-store release.
