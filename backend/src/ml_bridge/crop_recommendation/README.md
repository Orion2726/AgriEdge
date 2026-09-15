# Crop Recommendation — model drop-in contract (superseded — kept as reference)

**The app itself no longer uses this.** Crop recommendation now runs
on-device via a TFLite model — see `docs/MODEL_SPECS.md` section 2 and
`app/lib/features/crop_recommendation/ml/crop_recommendation_ml_service.dart`.
That was a deliberate change from the ONNX/backend plan this file
originally documented: it's the one feature that required connectivity at
submit time in an otherwise fully offline-first app.

`predict.js` below is still called by `POST /api/soil-reports` for
server-side record-keeping (the app no longer reads its response), and its
`buildNutrientAdvice()` / rule-based scoring were ported directly to Dart as
`CropRecommendationMlService`'s no-model fallback. The ONNX swap-in steps
below are left as-is in case a server-side ensemble is ever wanted for some
other purpose, but this is not the active code path.

---

`predict.js` currently implements a **rule-based stand-in** (distance from
hardcoded ideal N/P/K/pH ranges per crop). It exists only so the app has a
working end-to-end flow before a trained model exists. Replace it with the
real ensemble without touching any other file — `routes/soil.js` only calls
`predict(soil)` and serializes whatever it returns.

## What to drop in

1. Train the RandomForest + XGBoost soft-voting ensemble per
   `docs/MODEL_SPECS.md`.
2. Export the whole `VotingClassifier` (or each sub-model) to **ONNX** via
   `skl2onnx` / `onnxmltools`.
3. Place the exported file at `model.onnx` in this directory, plus:
   - `label_map.json` — `{ "0": "Rice", "1": "Wheat", ... }` (class index → crop name)
   - `feature_scaler.json` — mean/std (or min/max) per feature, if the model
     was trained on standardized inputs
4. Add `onnxruntime-node` to `backend/package.json` and rewrite `predict()`
   to load the session once (module scope, not per-request) and run
   inference, mapping output probabilities back through `label_map.json`.

## Contract `predict()` must keep

**Input** — a plain object, feature order does not matter here (named
fields), but when you build the ONNX input tensor it must be:

```
[nitrogen, phosphorus, potassium, ph, organicCarbon, rainfallMm, temperatureC, humidityPct]
```
as `Float32Array`, shape `[1, 8]`.

**Output** — an array, ranked highest suitability first, of:

```json
{ "cropName": "Rice", "suitabilityScore": 0.87, "nutrientAdvice": ["..."] }
```

`nutrientAdvice` is **not** part of the model's output — it's computed
separately (see `buildNutrientAdvice` in `predict.js`) from simple threshold
rules against the same soil inputs. Keep that function (or an improved
version of it) regardless of what the classifier becomes.
