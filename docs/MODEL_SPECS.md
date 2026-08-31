# AgriEdge — Model Specifications

Three models are trained outside this repo and dropped in as files. This
doc is the single source of truth for their architecture, preprocessing,
export format, exact input/output contract, and where the resulting file
goes. The app and backend code already implement everything around these
contracts (loading, fallback-to-mock, inference calls) — training and
dropping in the file is the only remaining step for each.

| Model | Runs where | Framework | Export format | Drop-in location |
|---|---|---|---|---|
| Disease detection | On-device (Flutter) | Keras (TF) → TFLite | `.tflite` | `app/assets/ml/disease/model.tflite` and/or `backend/assets/models/disease/model.tflite` |
| Crop recommendation | Server (Node backend) | scikit-learn + XGBoost | ONNX | `backend/src/ml_bridge/crop_recommendation/model.onnx` |
| Market price forecast | Server (Node backend) | Keras (TF) | ONNX | `backend/src/ml_bridge/price_forecast/*.onnx` |

---

## 1. Disease Detection

**Where it's used**: `app/lib/features/disease_detection/ml/tflite_disease_service.dart`.
Runs fully on-device via `tflite_flutter` — zero network required. If no
usable model is found, the service returns a mocked, clearly-labeled result
(`isMock: true`) so the rest of the feature (treatment lookup, detection
history, sync queue) is testable before training anything.

### Data

- Base: [PlantVillage](https://www.kaggle.com/datasets/emmarex/plantdisease) dataset.
- Augment with region-specific images collected via the app's own capture
  flow (crowdsourced, consent-gated — see `DiseaseDetectionRepository.recordDetection`),
  for local crop varieties and real field-lighting conditions.
- The 16-class label set currently wired up (`app/assets/ml/disease/labels.txt`)
  covers Tomato, Potato, Maize, Rice, Cotton — extend/replace this list to
  match whatever your training data actually covers, then update
  `app/assets/knowledge_base/treatments.json` with matching entries (the
  treatment lookup is a plain key match on the label string).

### Preprocessing & augmentation

- Resize to 224×224.
- Augmentation: rotation, horizontal/vertical flip, brightness/contrast
  jitter — target robustness to real field-lighting conditions, not studio
  photos.
- Normalize to **[-1, 1]**: `pixel / 127.5 - 1.0` per channel. This exact
  formula is hardcoded in `TFLiteDiseaseService._preprocess()` — if you
  train with different normalization (e.g. `[0,1]` or ImageNet mean/std),
  update that function to match, and update
  `app/assets/ml/disease/model_manifest.json`'s `inputNormalization` field
  to document the change.

### Architecture

- Backbone: **MobileNetV2** or **EfficientNet-Lite0**, pretrained on
  ImageNet, transfer-learned (freeze backbone, train a new classification
  head; optionally fine-tune the last few backbone blocks).
- Head: GlobalAveragePooling2D → Dense(N classes) → softmax.

### Compression

- Post-training **INT8 quantization** (TFLite converter, representative
  dataset from your training set for calibration).
- Optional pruning + knowledge distillation from a larger teacher model if
  quantization drops accuracy too much.

### Export

TensorFlow Lite (`.tflite`) via `tf.lite.TFLiteConverter`.

### Exact I/O contract

| | Shape | Type | Notes |
|---|---|---|---|
| Input | `[1, 224, 224, 3]` | float32 | RGB, normalized to `[-1, 1]` |
| Output | `[1, N]` | float32 | Softmax over N classes, same order as `labels.txt` |

`N` and the class order **must** match `app/assets/ml/disease/labels.txt`
line-for-line (index 0 = line 1, etc.). The service argmaxes the output —
it does not re-apply softmax, so the model must already output a proper
probability distribution.

### Drop-in

Two independent delivery paths — do either or both:

1. **Bundled in the app** (works offline from first install):
   - `app/assets/ml/disease/model.tflite`
   - Update `app/assets/ml/disease/model_manifest.json`: bump `version`,
     set `"isPlaceholder": false`.
   - Update `app/assets/ml/disease/labels.txt` if the class set changed.
   - Update `app/assets/knowledge_base/treatments.json` if labels changed.
2. **Downloadable at runtime** (upgrade without an app-store release —
   the app's Sync & Data screen has a "Download" button wired to this):
   - `backend/assets/models/disease/model.tflite`
   - `backend/assets/models/disease/manifest.json` (see that directory's
     `README.md` for the exact shape)

`ModelManager` (`app/lib/core/ml/model_manager.dart`) prefers a downloaded
model over the bundled one if both are present, so path 2 always wins once
a farmer has downloaded an update.

---

## 2. Crop Recommendation

**Where it's used**: `backend/src/routes/soil.js` calls
`ml_bridge/crop_recommendation/predict()`. Currently a rule-based stand-in
(distance from hardcoded ideal N/P/K/pH ranges per crop) — replace it with
the trained ensemble without touching any route or Flutter code; see
`backend/src/ml_bridge/crop_recommendation/README.md` for the mechanical
swap steps.

### Data

- Soil Health Card (SHC) parameters: N, P, K, pH, organic carbon — entered
  manually or OCR-scanned in-app (OCR scan is a stubbed "coming soon"
  button today in `soil_report_screen.dart`).
- Enriched with location climate data: rainfall, temperature, humidity
  (IMD / weather API — currently manual entry fields in the same form,
  defaulting to 0 if the farmer doesn't know them).
- Historical crop-yield-vs-soil-and-climate data for the training set
  itself (external to this repo).

### Architecture

- **Random Forest** + **XGBoost**, combined via **soft voting**
  (`sklearn.ensemble.VotingClassifier(voting='soft')`, or manually average
  `predict_proba` from each).
- Multi-class classifier over your crop label set.

### Export

**ONNX**, via `skl2onnx` (for the RF / the whole `VotingClassifier`) and
`onnxmltools` (for the XGBoost sub-model, if exporting separately). Run
inside the Node backend via `onnxruntime-node` — no separate Python service
needed at request time.

### Exact I/O contract

**Input** — `Float32Array`, shape `[1, 8]`, feature order fixed as:

```
[nitrogen, phosphorus, potassium, ph, organicCarbon, rainfallMm, temperatureC, humidityPct]
```

**Output** — ranked array of:

```json
{ "cropName": "Rice", "suitabilityScore": 0.87, "nutrientAdvice": ["..."] }
```

`nutrientAdvice` is **not** a model output — it's computed separately from
threshold rules against the same soil inputs (see `buildNutrientAdvice()`
in `predict.js`). Keep that function (or an improved version) regardless of
what the classifier becomes; only the ranking/`suitabilityScore` comes from
the trained model.

### Drop-in

`backend/src/ml_bridge/crop_recommendation/`:

- `model.onnx`
- `label_map.json` — `{"0": "Rice", "1": "Wheat", ...}` (class index → crop name)
- `feature_scaler.json` — mean/std or min/max per feature, if trained on
  standardized inputs

Then rewrite `predict()` in that directory's `predict.js` to load the ONNX
session once at module scope and run inference instead of the rule-based
scoring. Full steps in that directory's `README.md`.

---

## 3. Market Price Forecasting

**Where it's used**: `backend/src/routes/prices.js`, endpoint
`GET /api/prices/forecast/:commodity`, calling
`ml_bridge/price_forecast/forecast()`. Currently a random-walk stand-in.
**Not yet wired into the Flutter UI** — `market_price_screen.dart` only
shows live price vs MSP today; adding a forecast chart is a small follow-up
once real predictions exist. See `backend/src/ml_bridge/price_forecast/README.md`.

### Data

- Daily mandi prices per commodity per mandi: **Agmarknet API**.
- MSP figures (separate from this model): **data.gov.in** / CACP
  publications — already ingested as static/manual seed data in
  `backend/src/db/index.js#seedMsp`, no model involved there.

### Architecture

- **LSTM or GRU**, Keras/TensorFlow.
- Either one model per commodity, or a single model with commodity/mandi
  as a categorical embedding input (scales better as you add commodities,
  but needs more training data).

### Export

**ONNX** via `tf2onnx`, run via `onnxruntime-node` in the Node backend —
same runtime choice as the crop-recommendation model, so the backend only
needs one ONNX inference dependency.

### Exact I/O contract

**Input**: last 30 daily prices for the commodity/mandi, `Float32Array`,
shape `[1, 30, 1]` (plus commodity/mandi categorical input(s) if using the
single multi-commodity model — document your own ID mapping in
`metadata.json`, see below).

**Output**: `Float32Array`, shape `[1, 7]` — predicted price for each of
the next 7 days, same units as input (₹/quintal).

### Drop-in

`backend/src/ml_bridge/price_forecast/`:

- Per-commodity: `<commodity-slug>.onnx` (e.g. `wheat.onnx`), **or**
- Single multi-commodity: `model.onnx` + `metadata.json` (commodity/mandi
  name → categorical ID mapping, plus normalization stats used on the
  price series)

Then rewrite `forecast()` in that directory's `predict.js` to load the
session and run real inference instead of the random walk.

---

## Sanity-checking a model before dropping it in

For the on-device model, the fastest check is: does `Interpreter.fromFile()`
load it without throwing, and does `interpreter.getOutputTensor(0).shape`
match `[1, N]`? A quick Python check before export is usually faster:

```python
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()
print(interpreter.get_input_details())   # expect shape [1, 224, 224, 3], dtype float32
print(interpreter.get_output_details())  # expect shape [1, N], dtype float32
```

For the two ONNX models, `onnxruntime`'s `InferenceSession.get_inputs()` /
`get_outputs()` gives you the same shape/dtype check in Python before you
even touch the Node backend.
