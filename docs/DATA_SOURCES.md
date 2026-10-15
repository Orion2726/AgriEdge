# Data sources

What a farmer needs from the internet, where AgriEdge gets it, and whether a key is needed.
Data reaches phones in one of two ways:

- **Phone-direct:** the phone fetches it itself whenever it has internet.
- **Through the server:** the AgriEdge server fetches it and phones sync it every ~15 s.

Either way, phones without internet get the latest copy from a nearby phone over Bluetooth (newest wins).

## In the app now

| Data | Source | Key | How it arrives | Notes |
|---|---|---|---|---|
| Weather forecast (5 days), rain chance | [Open-Meteo](https://open-meteo.com) | None | Phone-direct | CC BY 4.0 |
| Topsoil moisture, crop water use (ET₀) | Open-Meteo (`soil_moisture_0_to_1cm`, `et0_fao_evapotranspiration`) | None | Phone-direct | Drives the "plan irrigation" hint |
| Mandi (wholesale) prices | [data.gov.in Agmarknet daily prices](https://www.data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi) | **Free key** (email/mobile sign-up, no card) | Through the server, every 3 h | All states. Used when a key is set |
| Mandi prices (fallback) | [Mandi Price API](https://mandi-api.vercel.app) (`mandi-api.onrender.com/v1`) | None | Through the server, every 3 h | MH, UP, PB, MP, KA only. CC BY-NC-SA 4.0 (non-commercial, attribution) |
| Minimum Support Price | Government of India (CCEA): Kharif 2026-27 (13 May 2026), Rabi 2027-28 (30 Sep 2026) | None | Through the server | Published once a season; no API exists, so the figures are entered in `backend/src/db/index.js` |
| Fertiliser prices (store) | Urea ₹266.50/45 kg and DAP ₹1,350/50 kg are government-fixed MRPs | None | Through the server | Other store items are typical retail prices |
| Farm news | Public RSS (Economic Times Agriculture, Krishi Jagran) | None | Phone-direct | Headlines link to the original |
| Official advisories | Published in the control panel | — | Through the server | |
| Farmer disease reports, outbreak clusters | Farmers' phones (Bluetooth mesh plus upload) | — | Mesh and server | The regional examples outside the demo area are demonstration data |
| Farm-supplies listings | Farmers' phones (Sell tab) | — | Server; offline phones browse via Bluetooth | Buying needs a live server connection |

### Mandi price details

- The server keeps one row per commodity: the **median modal price** across all mandis that reported on the latest arrival date, labelled e.g. "Median of 45 mandis · KA, MH, MP, PB, UP".
- Rice uses **paddy (common)** prices, because MSP is fixed for paddy.
- A price edited in the control panel becomes *manual* and is not overwritten until you press **Use live**.
- If every source fails, the last good prices stay.

## Turning on all-India mandi prices (free key)

1. Open the mandi price dataset: <https://data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi>
2. Click the yellow **⚙ Generate API Key** button on that page.
3. If you're not signed in, a box says **"To Generate API key.."**. Click **Login | Register**. Sign-in goes through **Jan Parichay / MeriPehchaan**, the government single sign-on, in a new window. Create an account there with your mobile number and OTP if you don't have one, then sign in. You come back to the dataset page.
4. Click **⚙ Generate API Key** again. The box says *"You don't have API Key. Click on 'Generate API Key' to generate."* Click **Generate API Key**.
5. The box now shows **API Key: …** with a copy icon. (Once signed in, the key is also listed under **My Account** on the portal.) Copy it. Don't press **Regenerate API Key** later unless you mean to: the old key stops working.
6. In the AgriEdge control panel, go to **Data Sources**, paste the key in **data.gov.in API key** and press **Save**. Or start the server with `DATA_GOV_IN_API_KEY=<key> npm start`.
7. Optionally pick **Prefer mandis in state** (e.g. Tamil Nadu), then press **Refresh prices now**. The status should read "updated … from data.gov.in", and price rows are tagged `live · data.gov.in`. If the key is wrong or rate-limited, prices quietly keep coming from the keyless source.

## Considered but not added

| Data | Why not |
|---|---|
| Soil properties by location (ISRIC SoilGrids, keyless) | The public API is in beta and did not answer during testing. The soil form uses the farmer's Soil Health Card instead |
| Satellite crop health / NDVI (Agromonitoring, Sentinel Hub) | Needs a free key plus a field boundary drawn per farm, which is too much for a demo |
| IMD district agromet advisories and weather warnings | IMD's API is restricted to whitelisted IPs |
| Pest and disease outbreak data (NPSS) | No public API. AgriEdge collects its own reports from farmers |
| Commodity futures (NCDEX) | No free API |
| Government schemes (PM-KISAN status etc.) | Needs the farmer's Aadhaar or login. Not suitable for this app |
