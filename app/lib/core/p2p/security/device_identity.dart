import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This device's signing identity for the P2P protocol — see
/// docs/P2P_ALERT_PROTOCOL.md §9. The seed lives in platform secure storage
/// (iOS Keychain / Android Keystore) so it survives app restarts but never
/// leaves the device; the public key doubles as this device's P2P address
/// (DiseaseAlertPayload.sourceDeviceId).
class DeviceIdentity {
  const DeviceIdentity._(this._keyPair, this.publicKeyBytes);

  final SimpleKeyPair _keyPair;
  final Uint8List publicKeyBytes;

  static const _seedStorageKey = 'p2p_device_identity_seed_v1';
  static final _ed25519 = Ed25519();

  String get publicKeyHex =>
      publicKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Short, stable P2P address used on the wire by transports (8 bytes) and
  /// shown in the UI so two farmers can tell whose phone is whose.
  Uint8List get shortIdBytes => Uint8List.sublistView(publicKeyBytes, 0, shortIdLength);
  String get shortIdHex => shortIdOfPublicKeyHex(publicKeyHex);

  static const shortIdLength = 8;

  /// The short id that corresponds to a full hex public key (e.g. a packet's
  /// sourceDeviceId).
  static String shortIdOfPublicKeyHex(String publicKeyHex) =>
      publicKeyHex.substring(0, shortIdLength * 2);

  static Future<DeviceIdentity> loadOrCreate(FlutterSecureStorage storage) async {
    final existingSeedB64 = await storage.read(key: _seedStorageKey);
    final SimpleKeyPair keyPair;
    if (existingSeedB64 != null) {
      keyPair = await _ed25519.newKeyPairFromSeed(base64Decode(existingSeedB64));
    } else {
      keyPair = await _ed25519.newKeyPair();
      final seed = await keyPair.extractPrivateKeyBytes();
      await storage.write(key: _seedStorageKey, value: base64Encode(seed));
    }
    final publicKey = await keyPair.extractPublicKey();
    return DeviceIdentity._(keyPair, Uint8List.fromList(publicKey.bytes));
  }

  Future<Uint8List> sign(Uint8List message) async {
    final signature = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  static Future<bool> verify(
    Uint8List message, {
    required Uint8List signature,
    required Uint8List publicKeyBytes,
  }) async {
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    return _ed25519.verify(
      message,
      signature: Signature(signature, publicKey: publicKey),
    );
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) {
  return DeviceIdentity.loadOrCreate(ref.watch(secureStorageProvider));
});
