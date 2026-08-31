# Market Price Forecasting — model drop-in contract

`predict.js` currently implements a **naive random-walk stand-in** (last
known price + small noise) so `GET /api/prices/forecast/:commodity` returns
real-shaped data before a trained model exists. Replace it with the trained
LSTM/GRU without touching `routes/prices.js` — it only calls
`forecast(lastKnownPrice, days)`.

## What to drop in

1. Train an LSTM/GRU per commodity (or one model with commodity/mandi as a
   categorical input) per `docs/MODEL_SPECS.md`.
2. Export to **ONNX** via `tf2onnx`.
3. Place the exported file(s) in this directory:
   - Per-commodity: `<commodity-slug>.onnx` (e.g. `wheat.onnx`)
   - Or a single multi-commodity model: `model.onnx` + `metadata.json`
     mapping commodity/mandi names to the categorical IDs used at training
     time, plus normalization stats (mean/std or min/max used on the price
     series).
4. Add `onnxruntime-node` to `backend/package.json` and rewrite `forecast()`
   to load the session once and run inference instead of the random walk.

## Contract `forecast()` must keep

**Input**: a window of the last 30 daily prices for the commodity/mandi,
`Float32Array`, shape `[1, 30, 1]` (plus commodity/mandi categorical
input(s) if using the single multi-commodity model).

**Output**: `Float32Array` of length 7 — predicted price for each of the
next 7 days, same units as the input (₹/quintal).

This endpoint is not yet called from the Flutter app's UI — it exists so
the backend contract and model-drop-in path are ready. Wiring a "7-day
forecast" chart into `market_price_screen.dart` is a small follow-up once
real predictions are worth showing to farmers.
