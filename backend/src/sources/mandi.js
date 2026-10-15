/**
 * Live mandi (wholesale market) prices for the app's 8 commodities.
 *
 * Providers, in order:
 *  1. data.gov.in Agmarknet daily prices — all states; needs a free API key
 *     (settings.datagov_api_key or env DATA_GOV_IN_API_KEY).
 *  2. mandi-api.onrender.com — no key; same Agmarknet data for MH, UP, PB,
 *     MP and KA (CC BY-NC-SA 4.0).
 *
 * One row per commodity is stored: the median modal price across all mandis
 * reporting on the latest arrival date. Rows edited in the control panel
 * (source = 'manual') are never overwritten. If every provider fails, the
 * previous rows stay as they are.
 */
const { db, getSetting, setSetting } = require('../db');

// App name → Agmarknet commodity names to try. Rice uses paddy prices
// because MSP is fixed for paddy, not milled rice.
const COMMODITIES = {
  Wheat: ['Wheat'],
  Rice: ['Paddy(Common)', 'Paddy(Dhan)(Common)'],
  Maize: ['Maize'],
  Cotton: ['Cotton'],
  Mustard: ['Mustard'],
  Potato: ['Potato'],
  Tomato: ['Tomato'],
  Soybean: ['Soyabean'],
};

const STATE_CODES = {
  'Andhra Pradesh': 'AP', Assam: 'AS', Bihar: 'BR', Chhattisgarh: 'CG', Gujarat: 'GJ', Haryana: 'HR',
  'Himachal Pradesh': 'HP', 'Jammu and Kashmir': 'JK', Jharkhand: 'JH', Karnataka: 'KA', Kerala: 'KL',
  'Madhya Pradesh': 'MP', Maharashtra: 'MH', Odisha: 'OD', Punjab: 'PB', Rajasthan: 'RJ', 'Tamil Nadu': 'TN',
  Telangana: 'TG', Tripura: 'TR', 'Uttar Pradesh': 'UP', Uttarakhand: 'UK', 'West Bengal': 'WB', 'NCT of Delhi': 'DL',
};

const TIMEOUT_MS = 90_000; // Render's free tier can take ~60 s to wake up.

const median = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};

async function getJson(url) {
  const r = await fetch(url, { signal: AbortSignal.timeout(TIMEOUT_MS), headers: { accept: 'application/json' } });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

/** → [{ state, market, modal, date: 'YYYY-MM-DD' }] */
async function fromMandiApi(name, state) {
  const q = new URLSearchParams({ commodity: name });
  if (state) q.set('state', state);
  const body = await getJson(`https://mandi-api.onrender.com/v1/prices?${q}`);
  return (body.data || []).map((r) => ({ state: r.state, market: r.market, modal: Number(r.modal_price), date: r.arrival_date }));
}

async function fromDataGovIn(name, state, key) {
  // Parameter names as in the portal's API docs: state takes the .keyword
  // suffix, commodity doesn't.
  const q = new URLSearchParams({ 'api-key': key, format: 'json', limit: '1000', 'filters[commodity]': name });
  if (state) q.set('filters[state.keyword]', state);
  const body = await getJson(`https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?${q}`);
  if (body.error) throw new Error(body.error);
  return (body.records || []).map((r) => {
    const [d = '', m = '', y = ''] = String(r.arrival_date).trim().split('/'); // DD/MM/YYYY, not always zero-padded
    return {
      state: r.state,
      market: r.market,
      modal: Number(r.modal_price),
      date: `${y.padStart(4, '20')}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`,
    };
  });
}

function summarise(rows) {
  const ok = rows.filter((r) => Number.isFinite(r.modal) && r.modal > 0 && /^\d{4}-\d{2}-\d{2}$/.test(r.date));
  if (!ok.length) return null;
  const latest = ok.reduce((a, r) => (r.date > a ? r.date : a), '');
  const day = ok.filter((r) => r.date === latest);
  const states = [...new Set(day.map((r) => STATE_CODES[r.state] || r.state))].sort();
  const n = new Set(day.map((r) => `${r.state}|${r.market}`)).size;
  return {
    price: Math.round(median(day.map((r) => r.modal))),
    date: latest,
    label: n === 1 ? `${day[0].market}, ${states[0]}` : `Median of ${n} mandis · ${states.join(', ')}`,
  };
}

let running = null;

/** Fetches all commodities; resolves to a status object (also saved in settings). */
function refreshMandiPrices() {
  if (running) return running;
  running = (async () => {
    const key = getSetting('datagov_api_key') || process.env.DATA_GOV_IN_API_KEY || '';
    const state = getSetting('mandi_state') || '';
    const providers = [];
    if (key) providers.push(['data.gov.in', (n) => fromDataGovIn(n, state, key)]);
    // mandi-api only covers 5 states; skip the state filter if it isn't one of them.
    const mandiApiState = ['Maharashtra', 'Uttar Pradesh', 'Punjab', 'Madhya Pradesh', 'Karnataka'].includes(state) ? state : '';
    providers.push(['mandi-api', (n) => fromMandiApi(n, mandiApiState)]);

    const updated = [];
    const used = new Set(); // providers that actually supplied a price
    const errors = [];
    const manual = new Set(db.prepare("SELECT commodity FROM prices WHERE source = 'manual'").all().map((r) => r.commodity));
    for (const [commodity, names] of Object.entries(COMMODITIES)) {
      if (manual.has(commodity)) continue;
      let got = null;
      for (const [provider, fetchRows] of providers) {
        for (const name of names) {
          try {
            const s = summarise(await fetchRows(name));
            if (s) { got = { ...s, provider }; break; }
          } catch (e) {
            errors.push(`${commodity} via ${provider}: ${e.message}`);
          }
        }
        if (got) break;
      }
      if (!got) continue;
      db.transaction(() => {
        db.prepare("DELETE FROM prices WHERE commodity = ? AND COALESCE(source, '') <> 'manual'").run(commodity);
        db.prepare('INSERT INTO prices (commodity, mandi, price_per_quintal, price_date, source) VALUES (?, ?, ?, ?, ?)')
          .run(commodity, got.label, got.price, got.date, got.provider);
      })();
      used.add(got.provider);
      updated.push(`${commodity} ₹${got.price} (${got.provider}, ${got.date})`);
    }
    const status = {
      at: new Date().toISOString(),
      ok: updated.length > 0,
      updated: updated.length,
      skippedManual: manual.size,
      providers: providers.map((p) => p[0]),
      used: [...used],
      errors: errors.slice(0, 5),
    };
    setSetting('mandi_status', JSON.stringify(status));
    console.log(`Mandi prices: ${updated.length} updated${errors.length ? `, ${errors.length} errors` : ''}`);
    return status;
  })().finally(() => { running = null; });
  return running;
}

/** Fetch shortly after start, then every 3 hours. Never blocks the server. */
function scheduleMandiRefresh() {
  const run = () => refreshMandiPrices().catch((e) => console.error('Mandi refresh failed:', e.message));
  setTimeout(run, 2000);
  setInterval(run, 3 * 3600_000).unref();
}

module.exports = { refreshMandiPrices, scheduleMandiRefresh, COMMODITIES };
