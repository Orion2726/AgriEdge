import 'dart:typed_data';

import 'package:agriedge/core/p2p/transport/ble_framing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sender = Uint8List.fromList(List.generate(8, (i) => i + 1));
  Uint8List bytes(int n, [int seed = 0]) => Uint8List.fromList(List.generate(n, (i) => (i + seed) & 0xFF));

  test('fragments and reassembles across many small chunks (default 20-byte ATT MTU)', () {
    final datagram = bytes(418);
    final chunks = BleFraming.fragment(datagram: datagram, msgId: 7, senderId: sender, maxChunkLength: 20);
    expect(chunks.length, greaterThan(20));
    final r = BleReassembler();
    ReassemblyResult? last;
    for (final c in chunks) {
      last = r.accept('link', c);
    }
    expect(last, isA<ReassemblyComplete>());
    final done = last as ReassemblyComplete;
    expect(done.datagram, datagram);
    expect(done.senderId, sender);
    expect(done.msgId, 7);
  });

  test('a single chunk carries a whole packet at a 512-byte MTU', () {
    final chunks = BleFraming.fragment(datagram: bytes(418), msgId: 1, senderId: sender, maxChunkLength: 512);
    expect(chunks, hasLength(1));
    expect(BleReassembler().accept('l', chunks.single), isA<ReassemblyComplete>());
  });

  test('interrupted transfer is not spliced onto the next message', () {
    final r = BleReassembler();
    final first = BleFraming.fragment(datagram: bytes(100), msgId: 1, senderId: sender, maxChunkLength: 30);
    final second = BleFraming.fragment(datagram: bytes(60, 9), msgId: 2, senderId: sender, maxChunkLength: 30);
    r.accept('l', first[0]); // sender drops out after one chunk
    ReassemblyResult? last;
    for (final c in second) {
      last = r.accept('l', c);
    }
    expect((last as ReassemblyComplete).datagram, bytes(60, 9));
  });

  test('continuation of a different message is rejected and resets the link', () {
    final r = BleReassembler();
    final a = BleFraming.fragment(datagram: bytes(100), msgId: 1, senderId: sender, maxChunkLength: 30);
    final b = BleFraming.fragment(datagram: bytes(100), msgId: 2, senderId: sender, maxChunkLength: 30);
    r.accept('l', a[0]);
    expect(r.accept('l', b[1]), isA<ReassemblyRejected>());
    expect(r.pendingLinkCount, 0);
  });

  test('out-of-order and duplicated chunks are rejected', () {
    final r = BleReassembler();
    final a = BleFraming.fragment(datagram: bytes(100), msgId: 1, senderId: sender, maxChunkLength: 30);
    r.accept('l', a[0]);
    r.accept('l', a[1]);
    expect(r.accept('l', a[1]), isA<ReassemblyRejected>());
  });

  test('oversized declared length is refused before buffering', () {
    final header = BleFraming.fragment(datagram: bytes(10), msgId: 1, senderId: sender, maxChunkLength: 64).single;
    ByteData.sublistView(header).setUint32(6, BleFraming.maxDatagramLength + 1);
    final res = BleReassembler().accept('l', header);
    expect(res, isA<ReassemblyRejected>());
    expect(() => BleFraming.fragment(
          datagram: bytes(BleFraming.maxDatagramLength + 1), msgId: 1, senderId: sender, maxChunkLength: 512),
        throwsArgumentError);
  });

  test('garbage and truncated frames are rejected', () {
    final r = BleReassembler();
    expect(r.accept('l', Uint8List.fromList([1, 2, 3])), isA<ReassemblyRejected>());
    expect(r.accept('l', Uint8List.fromList([0x00, 1, 0, 0, 0, 0, 9, 9])), isA<ReassemblyRejected>());
    expect(r.accept('l', Uint8List.fromList([BleFraming.magic, BleFraming.flagFirst, 0, 1, 0, 0, 0])),
        isA<ReassemblyRejected>());
  });

  test('message shorter than declared is rejected on its last chunk', () {
    final chunk = BleFraming.fragment(datagram: bytes(10), msgId: 1, senderId: sender, maxChunkLength: 64).single;
    ByteData.sublistView(chunk).setUint32(6, 11);
    expect(BleReassembler().accept('l', chunk), isA<ReassemblyRejected>());
  });

  test('stale partial messages expire', () {
    var now = DateTime(2026);
    final r = BleReassembler(clock: () => now);
    final a = BleFraming.fragment(datagram: bytes(100), msgId: 1, senderId: sender, maxChunkLength: 30);
    r.accept('l', a[0]);
    now = now.add(const Duration(seconds: 31));
    r.dropStale();
    expect(r.pendingLinkCount, 0);
    expect(r.accept('l', a[1]), isA<ReassemblyRejected>());
  });

  test('links are independent', () {
    final r = BleReassembler();
    final a = BleFraming.fragment(datagram: bytes(50), msgId: 1, senderId: sender, maxChunkLength: 30);
    final b = BleFraming.fragment(datagram: bytes(50, 3), msgId: 1, senderId: sender, maxChunkLength: 30);
    ReassemblyResult? ra, rb;
    for (var i = 0; i < a.length; i++) {
      ra = r.accept('x', a[i]); // interleaved with another phone's message
      rb = r.accept('y', b[i]);
    }
    expect((ra as ReassemblyComplete).datagram, bytes(50));
    expect((rb as ReassemblyComplete).datagram, bytes(50, 3));
  });
}
