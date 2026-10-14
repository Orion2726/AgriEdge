import 'dart:math';

import '../packet/p2p_packet.dart';

/// Weighted terms from docs/P2P_ALERT_PROTOCOL.md §4 — concretizes the
/// disclosure's R = wG·G + wC·C + wS·S + wT·T + wQ·Q − wD·D formula.
/// Starting values, not tuned against real data yet — see §10's
/// "suppression rate" metric for how to validate these against a real
/// multi-device pilot.
class RelevanceWeights {
  const RelevanceWeights({
    this.geographic = 0.3,
    this.crop = 0.25,
    this.severity = 0.2,
    this.freshness = 0.15,
    this.confidence = 0.1,
    this.duplication = 1.0,
  });

  final double geographic;
  final double crop;
  final double severity;
  final double freshness;
  final double confidence;

  /// Weight on the duplication penalty — kept separate from (and typically
  /// much larger than) the other weights, since "already sent to this
  /// exact peer" should near-always veto forwarding regardless of how
  /// relevant the packet is.
  final double duplication;
}

class RelevanceBreakdown {
  const RelevanceBreakdown({
    required this.score,
    required this.geographic,
    required this.crop,
    required this.severity,
    required this.freshness,
    required this.confidence,
    required this.duplicatePenalty,
  });

  final double score;
  final double geographic;
  final double crop;
  final double severity;
  final double freshness;
  final double confidence;
  final double duplicatePenalty;
}

/// Same haversine formula as backend/src/routes/alerts.js's clustering —
/// ported to Dart rather than reimplemented so the two stay in agreement.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double toRad(double deg) => deg * pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

class RelevanceEngine {
  const RelevanceEngine({
    this.weights = const RelevanceWeights(),
    this.forwardThreshold = 0.4,
    this.affectedRadiusKm = 25,
  });

  final RelevanceWeights weights;
  final double forwardThreshold;
  final double affectedRadiusKm;

  RelevanceBreakdown score({
    required DiseaseAlertPayload payload,
    required double deviceLat,
    required double deviceLng,
    required List<String> myCropIds,
    required bool alreadyForwardedToThisPeer,
  }) {
    final distanceKm = haversineKm(payload.lat, payload.lng, deviceLat, deviceLng);
    // Full relevance inside the affected radius, decaying to zero by 2x the
    // radius — a farmer just outside the drawn boundary still benefits from
    // an early warning, just less urgently than one inside it.
    final geographic = (1 - (distanceKm / (affectedRadiusKm * 2))).clamp(0.0, 1.0);

    final crop = myCropIds.contains(payload.cropId) ? 1.0 : 0.2;

    final severity = switch (payload.severity) {
      'high' => 1.0,
      'medium' => 0.6,
      'low' => 0.3,
      _ => 0.5,
    };

    final totalWindow = payload.expiresAt.difference(payload.observedAt).inSeconds;
    final elapsed = DateTime.now().toUtc().difference(payload.observedAt).inSeconds;
    final freshness =
        totalWindow <= 0 ? 0.0 : (1 - (elapsed / totalWindow)).clamp(0.0, 1.0);

    final confidence = payload.confidence.clamp(0.0, 1.0);

    final duplicatePenalty = alreadyForwardedToThisPeer ? 1.0 : 0.0;

    final total = weights.geographic * geographic +
        weights.crop * crop +
        weights.severity * severity +
        weights.freshness * freshness +
        weights.confidence * confidence -
        weights.duplication * duplicatePenalty;

    return RelevanceBreakdown(
      score: total,
      geographic: geographic,
      crop: crop,
      severity: severity,
      freshness: freshness,
      confidence: confidence,
      duplicatePenalty: duplicatePenalty,
    );
  }

  bool shouldForward({
    required DiseaseAlertPayload payload,
    required double deviceLat,
    required double deviceLng,
    required List<String> myCropIds,
    required bool alreadyForwardedToThisPeer,
  }) {
    final breakdown = score(
      payload: payload,
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      myCropIds: myCropIds,
      alreadyForwardedToThisPeer: alreadyForwardedToThisPeer,
    );
    return breakdown.score >= forwardThreshold;
  }
}
