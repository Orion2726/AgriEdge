enum NearbyAlertSource { network, p2pNearby }

class NearbyAlert {
  const NearbyAlert({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    required this.detectionCount,
    required this.radiusKm,
    required this.windowStart,
    required this.fetchedAt,
    this.source = NearbyAlertSource.network,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final int detectionCount;
  final double radiusKm;
  final DateTime windowStart;
  final DateTime fetchedAt;

  /// network: from the backend's crowdsourced clustering (requires
  /// connectivity to have synced). p2pNearby: fused locally from this
  /// device's own BLE packet cache — see docs/P2P_ALERT_PROTOCOL.md §6,
  /// works fully offline.
  final NearbyAlertSource source;
}
