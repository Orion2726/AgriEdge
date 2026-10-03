# Price forecast model — downloadable copy

Mirrors `app/assets/ml/price_forecast/` (the bundled copy shipped with the
app). Keep both in sync when retraining.

Files:

- `model.tflite`
- `labels.txt` — one commodity name per line, matching the one-hot column
  order the model was trained with
- `volatility_bands.json` — empirical p10/p90 price-ratio bands per
  commodity per day-ahead (1-7), computed from real historical data. Not a
  model output — a static lookup the app shows alongside the point forecast
  so farmers see a range, not false precision. See `docs/MODEL_SPECS.md`
  section 3 for why: the point forecast ties the naive "price stays the
  same" baseline at this horizon without a recent-price-momentum feature.
- `manifest.json`, e.g.:

```json
{
  "modelId": "price_forecast_v1",
  "version": "1.0.0",
  "isPlaceholder": false,
  "inputShape": [1, 11],
  "inputFeatureOrder": ["Wheat", "Rice", "Maize", "Cotton", "Mustard", "Potato", "Tomato", "Soybean", "month_sin", "month_cos", "today_price"],
  "inputNormalization": "raw",
  "outputShape": [1, 7],
  "sha256": "<sha256 of model.tflite>"
}
```

`GET /api/models/price-forecast`, `GET /api/models/price-forecast/manifest`,
`GET /api/models/price-forecast/labels`, and
`GET /api/models/price-forecast/volatility-bands` serve these four files as-is.
