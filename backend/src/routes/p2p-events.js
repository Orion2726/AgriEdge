const express = require('express');
const { db } = require('../db');

const router = express.Router();

// Backs the P2P mesh's opportunistic gateway sync — see
// docs/P2P_ALERT_PROTOCOL.md §7 and app/lib/core/p2p/sync/p2p_gateway_sync.dart.
// INSERT OR REPLACE on packet_id: multiple gateway devices may independently
// upload the same packet (it's been carried/relayed across several phones),
// which is expected and harmless — same dedup key the P2P layer itself uses.
router.post('/', (req, res) => {
  const {
    packetId,
    cropId,
    label,
    confidence,
    severity,
    lat,
    lng,
    observedAt,
    expiresAt,
    sourceDeviceId,
    verified,
    detectionId,
    note,
  } = req.body;

  if (!packetId || !cropId || !label || confidence == null || lat == null || lng == null) {
    return res
      .status(400)
      .json({ error: 'packetId, cropId, label, confidence, lat, lng are required' });
  }

  db.prepare(
    `INSERT OR REPLACE INTO p2p_events
      (packet_id, crop_id, label, confidence, severity, lat, lng, observed_at, expires_at, source_device_id, verified, received_at, detection_id, note, uploaded_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(packet_id) DO UPDATE SET verified = MAX(verified, excluded.verified)`
  ).run(
    packetId,
    cropId,
    label,
    confidence,
    severity ?? 'medium',
    lat,
    lng,
    observedAt ?? new Date().toISOString(),
    expiresAt ?? new Date(Date.now() + 72 * 3600000).toISOString(),
    sourceDeviceId ?? 'unknown',
    verified ? 1 : 0,
    new Date().toISOString(),
    detectionId ?? null,
    typeof note === 'string' ? note.slice(0, 280) : null,
    req.get('X-AgriEdge-Device') || null
  );

  res.status(201).json({ packetId, status: 'received' });
});

module.exports = router;
