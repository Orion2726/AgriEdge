const express = require('express');
const path = require('path');
const cors = require('cors');
const crypto = require('crypto');
const fs = require('fs');
// Local secrets (ADMIN_PASSWORD, DATA_GOV_IN_API_KEY) in backend/.env, never committed.
try {
  process.loadEnvFile(path.join(__dirname, '..', '.env'));
} catch (_) {
  // no .env: rely on real environment variables (e.g. on Render)
}
const { seedIfEmpty } = require('./db');

seedIfEmpty();

const app = express();
// On Render, requests arrive through one proxy hop; trust exactly that one so
// req.ip is the real client (and a forged X-Forwarded-For can't dodge the
// login lockout). Running directly on a laptop, trust no proxy headers.
app.set('trust proxy', process.env.RENDER ? 1 : false);
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  if (!req.path.startsWith('/api/admin/overview')) {
    console.log(`${new Date().toISOString()} ${req.ip.replace('::ffff:', '')} ${req.method} ${req.originalUrl}`);
  }
  next();
});

const admin = require('./routes/admin');
app.use(admin.trackDevices);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Control panel login. When ADMIN_PASSWORD is set (backend/.env locally,
// an environment variable on a host like Render), the panel shows only a
// password box until the right password is entered; nothing else on it, and
// none of its /api/admin data, is served before that. Phone APIs stay open.
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
const ADMIN_SESSION = crypto.createHash('sha256').update(`agriedge-panel:${ADMIN_PASSWORD}`).digest('hex');
const LOGIN_PAGE = fs.readFileSync(path.join(__dirname, 'login.html'), 'utf8');
const sameSecret = (x, y) => {
  const a = Buffer.from(String(x)), b = Buffer.from(String(y));
  return a.length === b.length && crypto.timingSafeEqual(a, b);
};
const signedIn = (req) => {
  const c = String(req.get('cookie') || '').split(/;\s*/).find((v) => v.startsWith('agriedge_admin='));
  return Boolean(c) && sameSecret(c.slice('agriedge_admin='.length), ADMIN_SESSION);
};
const loginPage = (res, status, error = '') =>
  res.status(status).set('Cache-Control', 'no-store').type('html')
    .send(LOGIN_PAGE.replace('<!--ERROR-->', error));

// Slow down password guessing: 10 wrong tries per address per 15 minutes.
const failures = new Map();
app.post('/login', express.urlencoded({ extended: false, limit: '2kb' }), (req, res) => {
  if (!ADMIN_PASSWORD) return res.redirect(303, '/');
  const now = Date.now();
  const f = failures.get(req.ip);
  if (f && f.until > now && f.count >= 10) return loginPage(res, 429, 'Too many wrong tries. Wait 15 minutes.');
  if (sameSecret(req.body?.password ?? '', ADMIN_PASSWORD)) {
    failures.delete(req.ip);
    res.set('Set-Cookie', `agriedge_admin=${ADMIN_SESSION}; Path=/; HttpOnly; SameSite=Strict; Max-Age=2592000${req.secure ? '; Secure' : ''}`);
    return res.redirect(303, '/');
  }
  failures.set(req.ip, { count: (f && f.until > now ? f.count : 0) + 1, until: now + 15 * 60_000 });
  loginPage(res, 401, 'Wrong password.');
});
app.get('/logout', (req, res) => {
  res.set('Set-Cookie', 'agriedge_admin=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0').redirect(303, '/');
});
app.use((req, res, next) => {
  if (!ADMIN_PASSWORD || signedIn(req)) return next();
  if (req.path.startsWith('/api/admin')) return res.status(401).json({ error: 'Sign in to the control panel first' });
  if (req.path.startsWith('/api/') || req.path === '/health') return next(); // phones
  loginPage(res, 200); // the panel itself and anything else
});
// Web control panel for demos: add official reports, change prices/MSP,
// watch phone uploads and connected phones.
app.use(express.static(path.join(__dirname, '..', 'public')));
app.use('/api', admin.router);

app.use('/api/prices', require('./routes/prices'));
app.use('/api/msp', require('./routes/msp'));
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/listings', require('./routes/listings'));
app.use('/api/soil-reports', require('./routes/soil'));
app.use('/api/crop-recommendation', require('./routes/crop-recommendation'));
app.use('/api/detections', require('./routes/detections'));
app.use('/api/p2p-events', require('./routes/p2p-events'));
app.use('/api/alerts', require('./routes/alerts'));
app.use('/api/assistant', require('./routes/assistant'));
app.use('/api/models', require('./routes/models'));

// Live mandi prices: fetched now and every 3 hours (see src/sources/mandi.js).
require('./sources/mandi').scheduleMandiRefresh();

const PORT = process.env.PORT || 4001;
const server = app.listen(PORT, '0.0.0.0', () => {
  const lan = Object.values(require('os').networkInterfaces())
    .flat()
    .filter((i) => i && i.family === 'IPv4' && !i.internal)
    .map((i) => `http://${i.address}:${PORT}`);
  console.log(`AgriEdge server running.\n  Control panel: http://localhost:${PORT}/${ADMIN_PASSWORD ? ' (password protected)' : ' (no password set)'}`);
  for (const url of process.env.RENDER_EXTERNAL_URL ? [process.env.RENDER_EXTERNAL_URL] : lan) {
    console.log(`  Phones: enter ${url} in More → Sync & server`);
  }
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use — another AgriEdge server is probably running.`);
    console.error(`Stop it (e.g. \`fuser -k ${PORT}/tcp\`) or start on another port: PORT=4002 npm start`);
    process.exit(1);
  }
  throw err;
});
