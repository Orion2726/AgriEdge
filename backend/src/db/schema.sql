CREATE TABLE IF NOT EXISTS prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  commodity TEXT NOT NULL,
  mandi TEXT NOT NULL,
  price_per_quintal REAL NOT NULL,
  price_date TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS msp_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  crop TEXT NOT NULL,
  season TEXT NOT NULL,
  year INTEGER NOT NULL,
  price_per_quintal REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  price_per_unit REAL NOT NULL,
  unit TEXT NOT NULL,
  image_url TEXT,
  description TEXT
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  total_amount REAL NOT NULL,
  status TEXT NOT NULL DEFAULT 'received'
);

CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS soil_reports (
  id TEXT PRIMARY KEY,
  nitrogen REAL NOT NULL,
  phosphorus REAL NOT NULL,
  potassium REAL NOT NULL,
  ph REAL NOT NULL,
  organic_carbon REAL NOT NULL,
  rainfall_mm REAL NOT NULL,
  temperature_c REAL NOT NULL,
  humidity_pct REAL NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS detections (
  id TEXT PRIMARY KEY,
  crop_id TEXT,
  label TEXT NOT NULL,
  confidence REAL NOT NULL,
  lat REAL,
  lng REAL,
  consent_shared INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
