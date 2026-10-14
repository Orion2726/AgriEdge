const express = require('express');
const crypto = require('crypto');
const { db } = require('../db');

const router = express.Router();

const EARTH_RADIUS_KM = 6371;
const CLUSTER_WINDOW_DAYS = 30;
const GRID_DEGREES = 0.05; // ~5.5km per cell — coarse grid clustering, see class docstring below
const MIN_CLUSTER_SIZE = 2;

function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Grid-based spatial clustering: groups same-label detections that fall in
 * the same coarse lat/lng grid cell within the time window into one alert.
 * This mirrors the "expert-survey-plus-real-time-aggregation" pattern from
 * the methodology doc, using grid buckets as the cheap stand-in for DBSCAN.
 * Swap for a real DBSCAN (e.g. via a PostGIS ST_ClusterDBSCAN if this ever
 * moves off SQLite) if grid-edge artifacts become a problem at real scale.
 */
router.get('/nearby', (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const radiusKm = parseFloat(req.query.radiusKm) || 25;
  if (Number.isNaN(lat) || Number.isNaN(lng)) {
    return res.status(400).json({ error: 'lat and lng query params are required' });
  }

  const windowStartIso = new Date(Date.now() - CLUSTER_WINDOW_DAYS * 86400000).toISOString();
  const rows = db
    .prepare(
      `SELECT label, lat, lng, created_at FROM detections
       WHERE consent_shared = 1 AND lat IS NOT NULL AND lng IS NOT NULL AND created_at >= ?`
    )
    .all(windowStartIso)
    .concat(
      // Farmer reports carried over the BLE mesh and uploaded by a gateway
      // phone. Skip ones that are the same observation as an uploaded
      // detection (originator uploads both) so nothing is counted twice.
      db
        .prepare(
          `SELECT label, lat, lng, observed_at AS created_at FROM p2p_events
           WHERE observed_at >= ? AND expires_at >= ?
             AND (detection_id IS NULL OR detection_id NOT IN (SELECT id FROM detections))`
        )
        .all(windowStartIso, new Date().toISOString())
    )
    .filter((r) => haversineKm(lat, lng, r.lat, r.lng) <= radiusKm);

  const buckets = new Map();
  for (const row of rows) {
    const cellLat = Math.round(row.lat / GRID_DEGREES);
    const cellLng = Math.round(row.lng / GRID_DEGREES);
    const key = `${row.label}|${cellLat}|${cellLng}`;
    if (!buckets.has(key)) buckets.set(key, []);
    buckets.get(key).push(row);
  }

  const alerts = [];
  for (const [key, points] of buckets) {
    if (points.length < MIN_CLUSTER_SIZE) continue;
    const label = key.split('|')[0];
    const centroidLat = points.reduce((s, p) => s + p.lat, 0) / points.length;
    const centroidLng = points.reduce((s, p) => s + p.lng, 0) / points.length;
    const earliest = points.reduce((min, p) => (p.created_at < min ? p.created_at : min), points[0].created_at);
    alerts.push({
      id: crypto.createHash('sha1').update(key).digest('hex').slice(0, 16),
      label,
      lat: centroidLat,
      lng: centroidLng,
      detectionCount: points.length,
      radiusKm,
      windowStart: earliest,
    });
  }

  alerts.sort((a, b) => b.detectionCount - a.detectionCount);
  res.json(alerts);
});

// Named places for labelling regional clusters (nearest one wins).
const PLACES = [
  ['Chennai, TN', 13.08, 80.27], ['Coimbatore, TN', 11.02, 76.96], ['Madurai, TN', 9.93, 78.12],
  ['Bengaluru, KA', 12.97, 77.59], ['Hyderabad, TG', 17.39, 78.49], ['Vijayawada, AP', 16.51, 80.65],
  ['Mumbai, MH', 19.08, 72.88], ['Pune, MH', 18.52, 73.86], ['Nagpur, MH', 21.15, 79.09],
  ['Indore, MP', 22.72, 75.86], ['Ahmedabad, GJ', 23.02, 72.57], ['Jaipur, RJ', 26.91, 75.79],
  ['Ludhiana, PB', 30.9, 75.85], ['Karnal, HR', 29.69, 76.99], ['New Delhi', 28.61, 77.21],
  ['Lucknow, UP', 26.85, 80.95], ['Patna, BR', 25.59, 85.14], ['Kolkata, WB', 22.57, 88.36],
  ['Bhubaneswar, OD', 20.3, 85.82], ['Guwahati, AS', 26.14, 91.74], ['Kochi, KL', 9.93, 76.27],
];
const REGION_DEGREES = 0.5; // ~55 km cells

/**
 * Disease outbreaks everywhere the server has reports for — beyond Bluetooth
 * range — grouped into ~55 km regions, nearest first. Backs the app's
 * "Other regions" view; the phone's own area is in /nearby.
 */
router.get('/regions', (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const hasLoc = !Number.isNaN(lat) && !Number.isNaN(lng);
  const windowStartIso = new Date(Date.now() - CLUSTER_WINDOW_DAYS * 86400000).toISOString();
  const rows = db
    .prepare(
      `SELECT crop_id, label, lat, lng, created_at FROM detections
       WHERE consent_shared = 1 AND lat IS NOT NULL AND lng IS NOT NULL AND created_at >= ?`
    )
    .all(windowStartIso)
    .concat(
      db
        .prepare(
          `SELECT crop_id, label, lat, lng, observed_at AS created_at FROM p2p_events
           WHERE observed_at >= ? AND (detection_id IS NULL OR detection_id NOT IN (SELECT id FROM detections))`
        )
        .all(windowStartIso)
    );

  const buckets = new Map();
  for (const r of rows) {
    const key = `${r.label}|${Math.round(r.lat / REGION_DEGREES)}|${Math.round(r.lng / REGION_DEGREES)}`;
    if (!buckets.has(key)) buckets.set(key, []);
    buckets.get(key).push(r);
  }
  const regions = [];
  for (const [key, pts] of buckets) {
    const cLat = pts.reduce((s, p) => s + p.lat, 0) / pts.length;
    const cLng = pts.reduce((s, p) => s + p.lng, 0) / pts.length;
    const place = PLACES.reduce((best, p) =>
      haversineKm(cLat, cLng, p[1], p[2]) < haversineKm(cLat, cLng, best[1], best[2]) ? p : best
    );
    regions.push({
      id: crypto.createHash('sha1').update(`region|${key}`).digest('hex').slice(0, 16),
      label: key.split('|')[0],
      cropId: pts.find((p) => p.crop_id)?.crop_id ?? null,
      region: place[0],
      lat: cLat,
      lng: cLng,
      reportCount: pts.length,
      latestAt: pts.reduce((m, p) => (p.created_at > m ? p.created_at : m), pts[0].created_at),
      distanceKm: hasLoc ? Math.round(haversineKm(lat, lng, cLat, cLng)) : null,
    });
  }
  regions.sort((a, b) => (hasLoc ? a.distanceKm - b.distanceKm : b.reportCount - a.reportCount));
  res.json(regions.slice(0, 50));
});

module.exports = router;
