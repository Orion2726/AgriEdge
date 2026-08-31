const express = require('express');
const cors = require('cors');
const { seedIfEmpty } = require('./db');

seedIfEmpty();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  console.log(`${req.method} ${req.originalUrl}`);
  next();
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/prices', require('./routes/prices'));
app.use('/api/msp', require('./routes/msp'));
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/soil-reports', require('./routes/soil'));
app.use('/api/crop-recommendation', require('./routes/crop-recommendation'));
app.use('/api/detections', require('./routes/detections'));
app.use('/api/alerts', require('./routes/alerts'));
app.use('/api/assistant', require('./routes/assistant'));
app.use('/api/models', require('./routes/models'));

const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
  console.log(`AgriEdge backend (local dev only, no deployment) listening on http://localhost:${PORT}`);
});
