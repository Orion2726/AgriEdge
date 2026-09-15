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

**Where it's used**: on-device, via
`app/lib/features/crop_recommendation/ml/crop_recommendation_ml_service.dart`
— `SoilReportRepository.submitReport()` calls it synchronously the moment a
soil report is saved, so recommendations are cached immediately and work
fully offline. This deviates from an earlier draft of this doc that
specified a server-side RF+XGBoost/ONNX ensemble in the backend — that
approach required connectivity at submit time (the whole rest of the app is
offline-first; this was the one feature that wasn't), so it was replaced
with an on-device model using the same TFLite/`ModelManager`-style pattern
already built for disease detection. `backend/src/ml_bridge/crop_recommendation/predict.js`
still exists as a rule-based fallback (now also ported to Dart directly in
`CropRecommendationMlService._fallbackPredict()`, used only if no trained
model can be resolved) and the backend's `/api/soil-reports` endpoint still
computes/returns its own copy for server-side record-keeping, but the app
no longer waits on or uses that response.

### Data

Trained on Kaggle's
[atharvaingle/crop-recommendation-dataset](https://www.kaggle.com/datasets/atharvaingle/crop-recommendation-dataset)
— 2200 rows, 22 crop classes, perfectly balanced (100/class). Columns:
`N, P, K, temperature, humidity, ph, rainfall, label`. This dataset has
**no organic_carbon column** — unlike the original 8-feature draft of this
spec, the shipped model uses only the 7 features the dataset actually has.
`organic_carbon` is still collected in the soil report form and used for
the (non-model) nutrient-advice text, just not fed to the classifier.

### Architecture

Small dense NN: `Normalization` (adapted on training data, baked into the
graph) → `Dense(64, relu)` → `Dropout(0.2)` → `Dense(32, relu)` →
`Dense(22, softmax)`. Baking normalization into the graph means the app
feeds raw, unnormalized soil-report values directly — no separate scaler
file to keep in sync between training and inference.

Trained on an 85/15 stratified split; test accuracy 0.9939 (2 misclassified
out of 330).

### Export

**TensorFlow Lite** (`model.tflite`), plain float32 — the whole model is
~15KB, so INT8 quantization wasn't worth the added complexity/representative-dataset
step it required for the (much larger) disease-detection CNNs.

### Exact I/O contract

**Input** — `float32`, shape `[1, 7]`, **raw** (not pre-normalized) feature
order fixed as:

```
[N, P, K, temperature_c, humidity_pct, ph, rainfall_mm]
```

**Output** — `float32`, shape `[1, 22]`, softmax over crop classes, order
matching `labels.txt` (alphabetical: apple, banana, blackgram, chickpea,
coconut, coffee, cotton, grapes, jute, kidneybeans, lentil, maize, mango,
mothbeans, mungbean, muskmelon, orange, papaya, pigeonpeas, pomegranate,
rice, watermelon).

`CropRecommendationMlService.predict()` takes the top 5 by score and
attaches `nutrientAdvice` (threshold rules against N/P/K/pH/organic_carbon,
not a model output) to the top-ranked suggestion only — same behavior the
original rule-based `predict.js` had.

### Drop-in

Bundled: `app/assets/ml/crop_recommendation/{model.tflite,labels.txt,manifest.json}`.
Downloadable-at-runtime: `backend/assets/models/crop-recommendation/{model.tflite,labels.txt,manifest.json}`,
served via `GET /api/models/crop-recommendation(/manifest|/labels)`. Both
copies need to stay in sync — see `backend/assets/models/crop-recommendation/README.md`.

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
