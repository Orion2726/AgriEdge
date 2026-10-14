# AgriEdge backend (local dev only — no deployment)

Node.js + Express + SQLite (`better-sqlite3`). Runs on your machine only; the
Flutter app points at `http://localhost:4001` (see
`app/lib/core/constants/app_constants.dart`).

## Run it

```bash
cd backend
npm install
npm start
```

First run seeds sample market prices, MSP rates, a product catalog, and a
handful of demo disease detections (see `src/db/index.js` — clearly not real
Agmarknet/CACP/crowdsourced data, just enough to exercise every screen).

## Endpoints

| Method | Path                              | Purpose |
|--------|-----------------------------------|---------|
| GET    | `/api/prices`                     | Latest mandi prices |
| GET    | `/api/prices/forecast/:commodity` | 7-day forecast (stub — see `ml_bridge/price_forecast`) |
| GET    | `/api/msp`                        | MSP rates |
| GET    | `/api/products`                   | Order catalog |
| POST   | `/api/orders`                     | Place/sync an order |
| POST   | `/api/soil-reports`               | Submit a soil report, get ranked crop recommendations back |
| GET    | `/api/crop-recommendation/:id`    | Recompute recommendations for a stored report |
| POST   | `/api/detections`                 | Upload a crowdsourced disease-detection event |
| POST   | `/api/p2p-events`                 | Gateway-sync a disease-alert packet carried over the BLE mesh (see docs/P2P_ALERT_PROTOCOL.md) |
| GET    | `/api/alerts/nearby`              | Clustered nearby-disease alerts (`?lat=&lng=&radiusKm=`) |
| POST   | `/api/assistant/query`            | Mock-RAG FAQ answer |
| GET    | `/api/models/disease/:cropId`             | Downloadable `.tflite` for that crop (404 until you drop one in) |
| GET    | `/api/models/disease/:cropId/manifest`    | That crop's model version manifest |
| GET    | `/api/models/disease/:cropId/labels`      | That crop's labels.txt |
| GET    | `/api/models/crop-recommendation`         | Downloadable crop-recommendation `.tflite` |
| GET    | `/api/models/crop-recommendation/manifest`| Crop-recommendation model version manifest |
| GET    | `/api/models/crop-recommendation/labels`  | Crop-recommendation labels.txt |
| GET    | `/api/models/price-forecast`              | Downloadable price-forecast `.tflite` |
| GET    | `/api/models/price-forecast/manifest`     | Price-forecast model version manifest |
| GET    | `/api/models/price-forecast/labels`       | Price-forecast labels.txt |
| GET    | `/api/models/price-forecast/volatility-bands` | Empirical p10/p90 price-ratio bands per commodity |

## Where the 2 server-side models plug in

- `src/ml_bridge/crop_recommendation/` — currently a rule-based stand-in.
  See its `README.md` for the ONNX contract.
- `src/ml_bridge/price_forecast/` — currently a random-walk stand-in. See
  its `README.md` for the ONNX contract.

Full model specs (architecture, preprocessing, export format) are in
`../docs/MODEL_SPECS.md`.
