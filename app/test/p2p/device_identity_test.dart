import 'dart:convert';
import 'dart:typed_data';

import 'package:agriedge/core/p2p/security/device_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loadOrCreate generates a 32-byte public key', () async {
    final identity = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    expect(identity.publicKeyBytes.length, 32);
    expect(identity.publicKeyHex.length, 64);
  });

  test('loadOrCreate returns the same identity across calls with the same storage', () async {
    const storage = FlutterSecureStorage();
    final first = await DeviceIdentity.loadOrCreate(storage);
    final second = await DeviceIdentity.loadOrCreate(storage);
    expect(second.publicKeyHex, first.publicKeyHex);
  });

  test('two independently-created identities are different', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final a = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    FlutterSecureStorage.setMockInitialValues({}); // fresh storage = fresh identity
    final b = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    expect(a.publicKeyHex, isNot(b.publicKeyHex));
  });

  test('sign then verify succeeds for the correct message and key', () async {
    final identity = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    final message = Uint8List.fromList(utf8.encode('disease alert payload'));
    final signature = await identity.sign(message);

    final valid = await DeviceIdentity.verify(
      message,
      signature: signature,
      publicKeyBytes: identity.publicKeyBytes,
    );
    expect(valid, isTrue);
  });

  test('verify fails if the message was tampered with', () async {
    final identity = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    final message = Uint8List.fromList(utf8.encode('disease alert payload'));
    final signature = await identity.sign(message);

    final tampered = Uint8List.fromList(utf8.encode('disease alert PAYLOAD'));
    final valid = await DeviceIdentity.verify(
      tampered,
      signature: signature,
      publicKeyBytes: identity.publicKeyBytes,
    );
    expect(valid, isFalse);
  });

  test('verify fails against a different device\'s public key', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final signer = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
    final message = Uint8List.fromList(utf8.encode('disease alert payload'));
    final signature = await signer.sign(message);

    FlutterSecureStorage.setMockInitialValues({});
    final impostor = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());

    final valid = await DeviceIdentity.verify(
      message,
      signature: signature,
      publicKeyBytes: impostor.publicKeyBytes,
    );
    expect(valid, isFalse);
  });
}
