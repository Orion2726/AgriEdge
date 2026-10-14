import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:cryptography/cryptography.dart';

/// Packet types this protocol carries. Only diseaseAlert is implemented —
/// the value space is reserved so price/MSP/soil can reuse this transport
/// later without a wire-format change (see docs/P2P_ALERT_PROTOCOL.md §3).
enum P2pAlertPacketType {
  diseaseAlert(1),

  /// Latest prices / MSP / weather / news held by the sender — see
  /// core/p2p/snapshot_sync.dart. Applied by the receiver only if newer
  /// than what it already has; never stored as an alert.
  dataSnapshot(2);

  const P2pAlertPacketType(this.wireValue);
  final int wireValue;

  static P2pAlertPacketType fromWireValue(int value) {
    return P2pAlertPacketType.values.firstWhere(
      (t) => t.wireValue == value,
      orElse: () => throw FormatException('Unknown P2pAlertPacketType wire value: $value'),
    );
  }
}

/// Payload for a disease-alert packet. Mirrors the fields already produced
/// by TFLiteDiseaseService + geolocation, so building one of these from an
/// existing DiseaseDetectionEntry is a direct field mapping — see
/// P2pAlertService.
class DiseaseAlertPayload {
  const DiseaseAlertPayload({
    required this.cropId,
    required this.label,
    required this.confidence,
    required this.severity,
    required this.latE6,
    required this.lngE6,
    required this.observedAt,
    required this.expiresAt,
    required this.sourceDeviceId,
    this.detectionId,
    this.note,
    this.photoJpeg,
  });

  /// Max lengths that keep a packet small enough for a quick BLE transfer.
  static const maxNoteLength = 280;
  static const maxPhotoBytes = 14 * 1024;

  final String cropId;
  final String label;
  final double confidence;

  /// 'low' | 'medium' | 'high' — coarse bucket, not a free-form string, so
  /// the relevance engine's severity term (§4) has a fixed small domain.
  final String severity;

  /// Latitude/longitude as microdegrees (value * 1e6, rounded to int) —
  /// same encoding OEPB uses, avoids float round-trip inconsistency feeding
  /// into the deterministic packetId hash.
  final int latE6;
  final int lngE6;

  final DateTime observedAt;
  final DateTime expiresAt;

  /// Hex-encoded Ed25519 public key of the originating device.
  final String sourceDeviceId;

  /// Id of the originating phone's local detection record, when the alert
  /// came from one. Lets the backend recognise that a gateway-synced packet
  /// and the originator's own /api/detections upload are the same
  /// observation, so it isn't counted twice. Omitted from the wire when null
  /// (older packets and their deterministic ids are unaffected).
  final String? detectionId;

  /// Farmer's own words about what they saw (optional, ≤ [maxNoteLength]).
  final String? note;

  /// Small JPEG thumbnail of the affected plant (optional, ≤ [maxPhotoBytes]).
  final Uint8List? photoJpeg;

  double get lat => latE6 / 1e6;
  double get lng => lngE6 / 1e6;

  Map<String, Object?> toMap() => {
        'cropId': cropId,
        'label': label,
        'confidence': confidence,
        'severity': severity,
        'latE6': latE6,
        'lngE6': lngE6,
        'observedAt': observedAt.toUtc().millisecondsSinceEpoch,
        'expiresAt': expiresAt.toUtc().millisecondsSinceEpoch,
        'sourceDeviceId': sourceDeviceId,
        if (detectionId != null) 'detectionId': detectionId,
        if (note != null) 'note': note,
        if (photoJpeg != null) 'photo': photoJpeg,
      };

  static DiseaseAlertPayload fromMap(Map<Object?, Object?> map) {
    return DiseaseAlertPayload(
      cropId: map['cropId'] as String,
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      severity: map['severity'] as String,
      latE6: map['latE6'] as int,
      lngE6: map['lngE6'] as int,
      observedAt: DateTime.fromMillisecondsSinceEpoch(map['observedAt'] as int, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int, isUtc: true),
      sourceDeviceId: map['sourceDeviceId'] as String,
      detectionId: map['detectionId'] as String?,
      note: _limitedNote(map['note']),
      photoJpeg: _limitedPhoto(map['photo']),
    );
  }
}

/// CBOR byte strings decode to a plain `List<int>`, which would re-encode as a
/// CBOR *array* — changing the bytes the packet id and signature cover, so
/// a received photo report or data snapshot would never verify. Restore the
/// known byte-string payload fields to Uint8List so re-encoding is exact.
const _byteFields = {'photo', 'z'};

Map<String, Object?> _restoreByteFields(Map<String, Object?> payload) => {
      for (final e in payload.entries)
        e.key: _byteFields.contains(e.key) && e.value is List
            ? Uint8List.fromList((e.value as List).cast<int>())
            : e.value,
    };

String? _limitedNote(Object? v) {
  if (v is! String) return null;
  return v.length > DiseaseAlertPayload.maxNoteLength ? v.substring(0, DiseaseAlertPayload.maxNoteLength) : v;
}

Uint8List? _limitedPhoto(Object? v) {
  if (v is! List || v.length > DiseaseAlertPayload.maxPhotoBytes) return null;
  return Uint8List.fromList(v.cast<int>());
}

/// Wire packet. Deviates from docs/P2P_ALERT_PROTOCOL.md §3's exact
/// fixed-width binary layout in one way: the header fields are CBOR-encoded
/// alongside the payload (short single-char keys to keep overhead small)
/// instead of a hand-packed byte struct. Same design intent — tiny,
/// deterministic-ID, optionally-signed — without a manual byte-offset
/// format that can't be tested against a real BLE MTU in this environment.
/// There's no wire-compatibility requirement with any non-AgriEdge device,
/// so this is a safe simplification.
class P2pAlertPacket {
  const P2pAlertPacket({
    required this.version,
    required this.type,
    required this.ttlHops,
    required this.createdAt,
    required this.nonce,
    required this.packetId,
    required this.payload,
    this.signature,
    this.signerPublicKey,
  });

  final int version;
  final P2pAlertPacketType type;
  final int ttlHops;
  final DateTime createdAt;
  final Uint8List nonce; // 8 bytes
  final Uint8List packetId; // 16 bytes, deterministic — see computePacketId
  final Map<String, Object?> payload;

  /// 64-byte Ed25519 signature, present iff this packet is signed.
  final Uint8List? signature;

  /// 32-byte Ed25519 public key of the signer, present iff signed. Carried
  /// alongside the signature (rather than requiring the verifier to already
  /// know every peer's key) since relays forward packets from devices
  /// they've never directly met — see §9's relay-trust-asymmetry note.
  final Uint8List? signerPublicKey;

  bool get isSigned => signature != null;

  /// Fields that feed the deterministic packetId — excludes ttlHops
  /// (mutated by every relay hop) and the signature (circular dependency),
  /// same rationale as OEPB's MsgID computation.
  static Future<Uint8List> computePacketId({
    required P2pAlertPacketType type,
    required DateTime createdAt,
    required Uint8List nonce,
    required Map<String, Object?> payload,
  }) async {
    final idInput = cbor.encode(CborValue({
      't': type.wireValue,
      'c': createdAt.toUtc().millisecondsSinceEpoch,
      'n': nonce,
      'p': payload,
    }));
    final digest = await Sha256().hash(idInput);
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  static Uint8List randomNonce([Random? random]) {
    final rand = random ?? Random.secure();
    return Uint8List.fromList(List.generate(8, (_) => rand.nextInt(256)));
  }

  /// Bytes a signature is computed/verified over — mirrors computePacketId's
  /// field selection, plus the (now-known) packetId for immutability binding.
  static Uint8List signingInput({
    required P2pAlertPacketType type,
    required DateTime createdAt,
    required Uint8List nonce,
    required Uint8List packetId,
    required Map<String, Object?> payload,
  }) {
    return Uint8List.fromList(cbor.encode(CborValue({
      't': type.wireValue,
      'c': createdAt.toUtc().millisecondsSinceEpoch,
      'n': nonce,
      'i': packetId,
      'p': payload,
    })));
  }

  Uint8List encode() {
    final map = <String, Object?>{
      'v': version,
      't': type.wireValue,
      'h': ttlHops,
      'c': createdAt.toUtc().millisecondsSinceEpoch,
      'n': nonce,
      'i': packetId,
      'p': payload,
      if (signature != null) 's': signature,
      if (signerPublicKey != null) 'k': signerPublicKey,
    };
    return Uint8List.fromList(cbor.encode(CborValue(map)));
  }

  static P2pAlertPacket decode(Uint8List bytes) {
    final decoded = cbor.decode(bytes).toObject() as Map<Object?, Object?>;
    return P2pAlertPacket(
      version: decoded['v'] as int,
      type: P2pAlertPacketType.fromWireValue(decoded['t'] as int),
      ttlHops: decoded['h'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(decoded['c'] as int, isUtc: true),
      nonce: Uint8List.fromList((decoded['n'] as List).cast<int>()),
      packetId: Uint8List.fromList((decoded['i'] as List).cast<int>()),
      payload: _restoreByteFields((decoded['p'] as Map<Object?, Object?>).cast<String, Object?>()),
      signature:
          decoded['s'] != null ? Uint8List.fromList((decoded['s'] as List).cast<int>()) : null,
      signerPublicKey:
          decoded['k'] != null ? Uint8List.fromList((decoded['k'] as List).cast<int>()) : null,
    );
  }

  String get packetIdHex => packetId.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  P2pAlertPacket copyWithDecrementedTtl() => P2pAlertPacket(
        version: version,
        type: type,
        ttlHops: ttlHops - 1,
        createdAt: createdAt,
        nonce: nonce,
        packetId: packetId,
        payload: payload,
        signature: signature,
        signerPublicKey: signerPublicKey,
      );
}
