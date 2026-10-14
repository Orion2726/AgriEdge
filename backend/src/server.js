const express = require('express');
const path = require('path');
const cors = require('cors');
const { seedIfEmpty } = require('./db');

seedIfEmpty();

const app = express();
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
// Web control panel for demos: add official reports, change prices/MSP,
// watch phone uploads and connected phones.
app.use(express.static(path.join(__dirname, '..', 'public')));
app.use('/api', admin.router);

app.use('/api/prices', require('./routes/prices'));
app.use('/api/msp', require('./routes/msp'));
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/soil-reports', require('./routes/soil'));
app.use('/api/crop-recommendation', require('./routes/crop-recommendation'));
app.use('/api/detections', require('./routes/detections'));
app.use('/api/p2p-events', require('./routes/p2p-events'));
app.use('/api/alerts', require('./routes/alerts'));
app.use('/api/assistant', require('./routes/assistant'));
app.use('/api/models', require('./routes/models'));

const PORT = process.env.PORT || 4001;
app.listen(PORT, '0.0.0.0', () => {
  const lan = Object.values(require('os').networkInterfaces())
    .flat()
    .filter((i) => i && i.family === 'IPv4' && !i.internal)
    .map((i) => `http://${i.address}:${PORT}`);
  console.log(`AgriEdge server running.\n  Control panel: http://localhost:${PORT}/`);
  for (const url of lan) console.log(`  Phones: enter ${url} in More → Sync & server`);
});
