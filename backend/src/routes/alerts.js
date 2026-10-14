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

module.exports = router;
