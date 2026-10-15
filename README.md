# Æ AgriEdge

**Offline-first farming assistant for Android.** AgriEdge checks crop leaves for disease on the phone itself, suggests what to grow from a soil test, shows mandi prices with a 7-day outlook, and passes disease alerts from phone to phone over **Bluetooth**, so farmers without internet still get warnings. A laptop runs a small **control panel** where officials publish advisories and update prices. Phones with internet pick them up and relay them to phones that have none.

> Faculty demonstration prototype. Mandi prices, MSP rates and the regional outbreak list are **sample data**. The ML models are real, but they are tuned to be "good enough" for a demo, not field-validated.

<p align="center">
  <img src="docs/screenshots/app-home.png" width="200" alt="Home screen">
  <img src="docs/screenshots/app-disease-check.png" width="200" alt="Disease check">
  <img src="docs/screenshots/app-nearby-mesh.png" width="200" alt="Nearby alerts over Bluetooth">
  <img src="docs/screenshots/app-price-forecast.png" width="200" alt="Price outlook">
</p>

---

## Download the app

**[⬇ release/AgriEdge.apk](release/AgriEdge.apk)** (Android 7.0+, about 76 MB)

1. Open the link above on GitHub and press **Download raw file**.
2. Open the downloaded file on the phone and allow **Install unknown apps** when asked.
3. Allow **Bluetooth (Nearby devices)** and **Location** when the app asks. They are needed for phone-to-phone sharing.

The APK is signed with a development key, so Play Protect may warn that the app is from an unknown developer. Choose **Install anyway**.

## What it does

| Feature | How it works | Needs internet? |
|---|---|---|
| **Disease check** | Take or pick a leaf photo. On-device TFLite (LiteRT) models for potato, rice, wheat, cotton and corn/sugarcane give a diagnosis with symptoms, treatment and prevention. Below 60 % confidence it says "Not sure" and shows the top two guesses. | No |
| **Nearby alerts (Bluetooth mesh)** | Reports, official advisories, prices and weather are exchanged automatically with any phone running AgriEdge within Bluetooth range: signed, deduplicated, store-and-forward. | No |
| **Gateway relay** | A phone that reaches the server uploads reports it received from offline phones and brings official advisories back down to them. | One phone does |
| **Crop advice** | Enter Soil Health Card values (N, P, K, pH, OC, climate). An on-device model ranks suitable crops. | No |
| **Mandi prices & outlook** | Latest prices against MSP; tap a crop for a 7-day forecast with a realistic range band. | To refresh |
| **Weather & news** | Forecast with spray/irrigation hints; agriculture news. A saved copy is shown when offline. | To refresh |
| **Orders, tips, FAQ** | Demo input-ordering flow, sowing tips from your data, and a searchable farming FAQ. | Orders sync when online |

## Control panel (laptop)

<p align="center">
  <img src="docs/screenshots/panel-dashboard.png" width="820" alt="Control panel dashboard">
</p>

The panel runs at `http://localhost:4001/` and offers:

- **Issue an official advisory.** Crop, disease, severity, area and advice for farmers. Online phones get it within about 15 s, then it hops over Bluetooth to offline phones.
- **Withdraw** an advisory, **edit mandi prices / MSP**, and **change order status**. Every change reaches the phones the same way.
- **Field reports from farmers.** Reports another phone carried in over Bluetooth are tagged **via mesh**.
- **Registered phones** and live counts, with the exact address phones should enter.

<p align="center">
  <img src="docs/screenshots/panel-advisories.png" width="820" alt="Official advisories and field reports">
</p>

## How a report travels

```
 Control panel ── Wi-Fi/LAN ──▶ Phone B (online) ── Bluetooth ──▶ Phone A (no internet)
      ▲                              │                                  │
      └──── upload (gateway) ◀───────┴──────── report made offline ◀────┘
```

1. Phone A has no internet. A farmer shares a disease report on it.
2. Phone A passes the report to phone B over Bluetooth Low Energy as soon as B is in range.
3. Phone B can reach the server, so it uploads the report. The panel shows it as **via mesh**.
4. An official advisory published on the panel goes the other way: server → B → A.

Protocol details: [docs/P2P_ALERT_PROTOCOL.md](docs/P2P_ALERT_PROTOCOL.md).

## Running the demo

### 1. Start the server (laptop)

Requires Node.js 22 or later.

```bash
cd backend
npm install
npm rebuild better-sqlite3   # compiles the native SQLite module
npm start                    # http://localhost:4001
```

The terminal and the panel's header both show the address phones should use, for example `http://10.224.202.74:4001`.

If Linux has a firewall, allow the port once:

```bash
sudo ufw allow 4001/tcp
```

### 2. Connect a phone

Put the phone on the **same Wi-Fi or hotspot** as the laptop. In the app open **More → Sync & server**, enter the address and tap **Save & test**.

### 3. Two-phone mesh demo

- **Phone B** is on the laptop's Wi-Fi with the server address set.
- **Phone A** has no route to the laptop (mobile data off, or a different Wi-Fi).
- Keep AgriEdge **open on both** with Bluetooth on, within a few metres of each other.
- Publish an advisory in the panel. It appears on B, then on A, marked Official.
- Share a report on A (Nearby → Share a report). It appears in the panel as **via mesh**.

## Building from source

Requires Flutter 3.44 or later and the Android SDK.

```bash
cd app
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
# → app/build/app/outputs/flutter-apk/app-release.apk
```

To bake in a default server address, add `--dart-define=AGRIEDGE_BACKEND_URL=http://<laptop-ip>:4001` to the build command.

## Project layout

```
app/                 Flutter app (Android; iOS builds but is untested)
  lib/core/          database (Drift), sync, BLE P2P mesh, ML runners, theme
  lib/features/      one folder per screen/feature
  assets/ml/         TFLite models + labels (disease ×5, crop recommendation, price forecast)
backend/             Node.js + Express + SQLite server and the control panel (public/index.html)
docs/                model specs, P2P protocol, screenshots
release/             ready-to-install APK
```

## Tech

- **App:** Flutter, Riverpod, Drift (SQLite), go_router, `tflite_flutter` 0.12 (LiteRT), `bluetooth_low_energy` (BLE central + peripheral), Poppins font.
- **Models:** transfer-learned CNN classifiers (MobileNetV2 / EfficientNet-Lite) for leaf disease, a small dense network for crop recommendation, and a small dense network for the price outlook (honestly about as accurate as "price stays the same"; the shaded range is the useful part). See [docs/MODEL_SPECS.md](docs/MODEL_SPECS.md).
- **Server:** Node.js, Express, better-sqlite3. The panel is a single dependency-free HTML page.

## Limitations

- Bluetooth sharing runs only while the app is open in the foreground.
- Disease models work best on close-up leaf photos. Wide field shots often come back "Not sure".
- Prices, MSP and regional outbreaks are sample data. Live government feeds would need an API key.
- The server is meant for a local network during a demo and has no login. Do not expose it to the internet.

## Credits

Plant images used for testing came from the PlantVillage dataset and Wikimedia Commons. Poppins is used under the SIL Open Font License (`app/assets/fonts/Poppins-OFL.txt`).
