# AgriEdge backend (local dev only — no deployment)

Node.js + Express + SQLite (`better-sqlite3`). Runs on your machine only.

## Run it

```bash
cd backend
npm install
npm rebuild better-sqlite3   # npm 11 blocks install scripts; this compiles the native module
npm start                    # PORT=4001 by default; prints the panel URL and the address for phones
```

Linux firewall (ufw) — allow phones on the LAN to reach the server once:
`sudo ufw allow from <lan-subnet>/24 to any port 4001 proto tcp`

## Control panel (for demos)

Open `http://localhost:<port>/` on the laptop. From there you can publish
**official disease reports**, change **mandi prices / MSP**, change **order
status**, and watch **reports uploaded by phones** and **which phones are
connected**. Online phones poll every ~15 s; whatever they receive is passed on
over Bluetooth to nearby phones that have no internet (and reports made on
those offline phones travel back the same way and appear in the panel).

Demo with two phones: phone B on the laptop's Wi-Fi/hotspot (server address set),
phone A with no route to the laptop (mobile data off, or another Wi-Fi), both with
AgriEdge open within Bluetooth range.

## Connect phones

Phones can't use your computer's `localhost`. Put the phones and the computer on
the same Wi-Fi/hotspot, make sure the port is allowed by the computer's firewall,
then in the app open **More → Sync & server**, enter `http://<computer-LAN-IP>:<port>`
and tap **Save & test**. The app works without a server too (on-device disease
checks, crop advice, Bluetooth sharing, weather/news from the internet); only
prices/MSP/catalogue/uploads need it. A phone on a different network cannot reach
this local server.

## Install the app on another phone

`app/build/app/outputs/flutter-apk/app-release.apk` — build with
`cd app && flutter build apk --release --target-platform android-arm,android-arm64`,
copy to the phone and open it (allow "install unknown apps").

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
