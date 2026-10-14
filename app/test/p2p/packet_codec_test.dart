import 'dart:typed_data';

import 'package:agriedge/core/p2p/packet/p2p_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P2pAlertPacket', () {
    late DiseaseAlertPayload payload;

    setUp(() {
      payload = DiseaseAlertPayload(
        cropId: 'potato',
        label: 'Potato___Late_blight',
        confidence: 0.91,
        severity: 'high',
        latE6: 28613900,
        lngE6: 77209000,
        observedAt: DateTime.utc(2026, 1, 1, 12),
        expiresAt: DateTime.utc(2026, 1, 4, 12),
        sourceDeviceId: 'abc123',
      );
    });

    test('encode/decode round-trips exactly', () async {
      final nonce = P2pAlertPacket.randomNonce();
      final packetId = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      final packet = P2pAlertPacket(
        version: 1,
        type: P2pAlertPacketType.diseaseAlert,
        ttlHops: 10,
        createdAt: payload.observedAt,
        nonce: nonce,
        packetId: packetId,
        payload: payload.toMap(),
      );

      final decoded = P2pAlertPacket.decode(packet.encode());

      expect(decoded.version, 1);
      expect(decoded.type, P2pAlertPacketType.diseaseAlert);
      expect(decoded.ttlHops, 10);
      expect(decoded.createdAt, payload.observedAt);
      expect(decoded.nonce, nonce);
      expect(decoded.packetId, packetId);
      expect(decoded.isSigned, isFalse);

      final decodedPayload = DiseaseAlertPayload.fromMap(decoded.payload);
      expect(decodedPayload.cropId, 'potato');
      expect(decodedPayload.label, 'Potato___Late_blight');
      expect(decodedPayload.confidence, 0.91);
      expect(decodedPayload.lat, closeTo(28.6139, 0.0001));
      expect(decodedPayload.lng, closeTo(77.209, 0.0001));
    });

    test('round-trips signature and signer public key when present', () {
      final fakeSignature = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final fakeKey = Uint8List.fromList(List.generate(32, (i) => (i + 1) % 256));
      final fakePacketId = Uint8List.fromList(List.generate(16, (i) => i));
      final packet = P2pAlertPacket(
        version: 1,
        type: P2pAlertPacketType.diseaseAlert,
        ttlHops: 5,
        createdAt: payload.observedAt,
        nonce: P2pAlertPacket.randomNonce(),
        packetId: fakePacketId,
        payload: payload.toMap(),
        signature: fakeSignature,
        signerPublicKey: fakeKey,
      );

      final decoded = P2pAlertPacket.decode(packet.encode());
      expect(decoded.isSigned, isTrue);
      expect(decoded.signature, fakeSignature);
      expect(decoded.signerPublicKey, fakeKey);
    });

    test('computePacketId is deterministic for identical inputs', () async {
      final nonce = P2pAlertPacket.randomNonce();
      final id1 = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      final id2 = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      expect(id1, id2);
    });

    test('computePacketId differs when payload differs', () async {
      final nonce = P2pAlertPacket.randomNonce();
      final id1 = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      final otherPayload = DiseaseAlertPayload(
        cropId: 'potato',
        label: 'Potato___Early_blight', // only this differs
        confidence: payload.confidence,
        severity: payload.severity,
        latE6: payload.latE6,
        lngE6: payload.lngE6,
        observedAt: payload.observedAt,
        expiresAt: payload.expiresAt,
        sourceDeviceId: payload.sourceDeviceId,
      );
      final id2 = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: otherPayload.toMap(),
      );
      expect(id1, isNot(id2));
    });

    test('packetIdHex is lowercase hex, 32 chars for a 16-byte id', () async {
      final nonce = P2pAlertPacket.randomNonce();
      final packetId = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      final packet = P2pAlertPacket(
        version: 1,
        type: P2pAlertPacketType.diseaseAlert,
        ttlHops: 10,
        createdAt: payload.observedAt,
        nonce: nonce,
        packetId: packetId,
        payload: payload.toMap(),
      );
      expect(packet.packetIdHex.length, 32);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(packet.packetIdHex), isTrue);
    });

    test('copyWithDecrementedTtl only changes ttlHops', () async {
      final nonce = P2pAlertPacket.randomNonce();
      final packetId = await P2pAlertPacket.computePacketId(
        type: P2pAlertPacketType.diseaseAlert,
        createdAt: payload.observedAt,
        nonce: nonce,
        payload: payload.toMap(),
      );
      final packet = P2pAlertPacket(
        version: 1,
        type: P2pAlertPacketType.diseaseAlert,
        ttlHops: 10,
        createdAt: payload.observedAt,
        nonce: nonce,
        packetId: packetId,
        payload: payload.toMap(),
      );
      final decremented = packet.copyWithDecrementedTtl();
      expect(decremented.ttlHops, 9);
      expect(decremented.packetId, packet.packetId);
      expect(decremented.payload, packet.payload);
    });
  });
}
