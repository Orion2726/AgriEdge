import 'package:agriedge/core/p2p/packet/p2p_packet.dart';
import 'package:agriedge/core/p2p/relevance/relevance_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineKm', () {
    test('same point is zero distance', () {
      expect(haversineKm(28.6139, 77.2090, 28.6139, 77.2090), closeTo(0, 0.001));
    });

    test('Delhi to Mumbai is roughly 1150km', () {
      // Well-known approximate real-world distance — sanity-checks the
      // formula isn't off by an order of magnitude or using the wrong units.
      final km = haversineKm(28.6139, 77.2090, 19.0760, 72.8777);
      expect(km, inInclusiveRange(1100, 1200));
    });
  });

  group('RelevanceEngine', () {
    const engine = RelevanceEngine();

    DiseaseAlertPayload payloadAt({
      required double lat,
      required double lng,
      String cropId = 'potato',
      String severity = 'high',
      double confidence = 0.9,
      Duration age = Duration.zero,
      Duration ttlRemaining = const Duration(hours: 71),
    }) {
      final observedAt = DateTime.now().toUtc().subtract(age);
      return DiseaseAlertPayload(
        cropId: cropId,
        label: 'Potato___Late_blight',
        confidence: confidence,
        severity: severity,
        latE6: (lat * 1e6).round(),
        lngE6: (lng * 1e6).round(),
        observedAt: observedAt,
        expiresAt: observedAt.add(age + ttlRemaining),
        sourceDeviceId: 'test',
      );
    }

    test('nearby + matching crop + fresh + high severity scores above threshold', () {
      final payload = payloadAt(lat: 28.6139, lng: 77.2090);
      final breakdown = engine.score(
        payload: payload,
        deviceLat: 28.62, // ~1km away
        deviceLng: 77.21,
        myCropIds: ['potato'],
        alreadyForwardedToThisPeer: false,
      );
      expect(breakdown.score, greaterThanOrEqualTo(engine.forwardThreshold));
      expect(
        engine.shouldForward(
          payload: payload,
          deviceLat: 28.62,
          deviceLng: 77.21,
          myCropIds: ['potato'],
          alreadyForwardedToThisPeer: false,
        ),
        isTrue,
      );
    });

    test('far away + non-matching crop scores low', () {
      final payload = payloadAt(lat: 28.6139, lng: 77.2090, severity: 'low', confidence: 0.3);
      final breakdown = engine.score(
        payload: payload,
        deviceLat: 19.0760, // Mumbai — far from Delhi
        deviceLng: 72.8777,
        myCropIds: ['wheat'], // doesn't grow potato
        alreadyForwardedToThisPeer: false,
      );
      expect(breakdown.score, lessThan(engine.forwardThreshold));
    });

    test('already-forwarded-to-this-peer is vetoed regardless of relevance', () {
      final payload = payloadAt(lat: 28.6139, lng: 77.2090);
      final shouldForward = engine.shouldForward(
        payload: payload,
        deviceLat: 28.6139, // identical location — maximally relevant otherwise
        deviceLng: 77.2090,
        myCropIds: ['potato'],
        alreadyForwardedToThisPeer: true,
      );
      expect(shouldForward, isFalse);
    });

    test('freshness decays to zero once past expiry', () {
      final payload = payloadAt(
        lat: 28.6139,
        lng: 77.2090,
        age: const Duration(hours: 100), // older than the 72h TTL used elsewhere
        ttlRemaining: Duration.zero,
      );
      final breakdown = engine.score(
        payload: payload,
        deviceLat: 28.6139,
        deviceLng: 77.2090,
        myCropIds: ['potato'],
        alreadyForwardedToThisPeer: false,
      );
      expect(breakdown.freshness, 0.0);
    });

    test('severity ordering: high > medium > low, all else equal', () {
      double scoreFor(String severity) {
        final payload = payloadAt(lat: 28.6139, lng: 77.2090, severity: severity);
        return engine
            .score(
              payload: payload,
              deviceLat: 28.6139,
              deviceLng: 77.2090,
              myCropIds: ['potato'],
              alreadyForwardedToThisPeer: false,
            )
            .score;
      }

      final high = scoreFor('high');
      final medium = scoreFor('medium');
      final low = scoreFor('low');
      expect(high, greaterThan(medium));
      expect(medium, greaterThan(low));
    });
  });

  test('a phone without a location fix still forwards a relevant alert', () {
    final observedAt = DateTime.now().toUtc();
    final payload = DiseaseAlertPayload(
      cropId: 'potato',
      label: 'Potato___Late_blight',
      confidence: 0.9,
      severity: 'high',
      latE6: 28613900,
      lngE6: 77209000,
      observedAt: observedAt,
      expiresAt: observedAt.add(const Duration(hours: 72)),
      sourceDeviceId: 'x',
    );
    const engine = RelevanceEngine();
    final b = engine.score(
        payload: payload, deviceLat: null, deviceLng: null, myCropIds: const [], alreadyForwardedToThisPeer: false);
    expect(b.geographic, RelevanceEngine.unknownLocationGeographic);
    expect(engine.shouldForward(
        payload: payload, deviceLat: null, deviceLng: null, myCropIds: const [], alreadyForwardedToThisPeer: false),
        isTrue);
  });
}
