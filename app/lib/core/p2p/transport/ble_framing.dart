import 'dart:typed_data';

/// GATT-write framing for BleTransport. A datagram (one encoded
/// P2pAlertPacket, a few hundred bytes) rarely fits in one ATT write — the
/// default MTU leaves 20 bytes per write — so it is split into chunks, each
/// carrying a small header:
///
/// ```
/// every chunk:  magic 0xAE (1B) | flags (1B) | msgId (2B) | seq (2B)
/// first chunk:  + totalLength (4B) + senderId (8B)
/// ```
///
/// flags: bit0 = first chunk, bit1 = last chunk. `senderId` is the sending
/// device's stable P2P identity (first 8 bytes of its Ed25519 public key —
/// see DeviceIdentity), which the receiver needs because Android rotates the
/// BLE address it sees for a writer, and that address differs from the one
/// the same phone advertises with.
///
/// Every chunk names its message and position, so an interrupted transfer
/// (peer walked away mid-message, app killed) or a restarted one can't be
/// silently spliced onto the next message — the reassembler drops the stale
/// partial message and reports why.
class BleFraming {
  BleFraming._();

  static const magic = 0xAE;
  static const flagFirst = 0x01;
  static const flagLast = 0x02;
  static const baseHeaderLength = 6;
  static const firstHeaderLength = baseHeaderLength + 4 + senderIdLength;
  static const senderIdLength = 8;

  /// Hard cap on a reassembled datagram. Alert packets are ~0.4 KB, or up
  /// to ~105 KB with an attached compressed photo; anything bigger is
  /// malformed or hostile and is rejected before any buffer is allocated.
  static const maxDatagramLength = 160 * 1024;

  /// Splits [datagram] into chunks no larger than [maxChunkLength] bytes
  /// (the negotiated ATT write length).
  static List<Uint8List> fragment({
    required Uint8List datagram,
    required int msgId,
    required Uint8List senderId,
    required int maxChunkLength,
  }) {
    if (senderId.length != senderIdLength) {
      throw ArgumentError.value(senderId.length, 'senderId.length', 'must be $senderIdLength');
    }
    if (datagram.length > maxDatagramLength) {
      throw ArgumentError.value(datagram.length, 'datagram.length', 'exceeds $maxDatagramLength');
    }
    if (maxChunkLength <= firstHeaderLength) {
      throw ArgumentError.value(maxChunkLength, 'maxChunkLength', 'too small for the frame header');
    }

    final chunks = <Uint8List>[];
    var offset = 0;
    var seq = 0;
    do {
      final first = seq == 0;
      final headerLength = first ? firstHeaderLength : baseHeaderLength;
      final dataLength = (datagram.length - offset).clamp(0, maxChunkLength - headerLength);
      final last = offset + dataLength >= datagram.length;

      final chunk = Uint8List(headerLength + dataLength);
      final view = ByteData.sublistView(chunk);
      view.setUint8(0, magic);
      view.setUint8(1, (first ? flagFirst : 0) | (last ? flagLast : 0));
      view.setUint16(2, msgId & 0xFFFF);
      view.setUint16(4, seq);
      if (first) {
        view.setUint32(6, datagram.length);
        chunk.setRange(10, 10 + senderIdLength, senderId);
      }
      chunk.setRange(headerLength, chunk.length, datagram, offset);
      chunks.add(chunk);

      offset += dataLength;
      seq++;
    } while (offset < datagram.length);
    return chunks;
  }
}

sealed class ReassemblyResult {
  const ReassemblyResult();
}

/// More chunks are needed.
class ReassemblyPending extends ReassemblyResult {
  const ReassemblyPending();
}

class ReassemblyComplete extends ReassemblyResult {
  const ReassemblyComplete({required this.senderId, required this.msgId, required this.datagram});
  final Uint8List senderId;
  final int msgId;
  final Uint8List datagram;
}

/// The chunk was rejected; any partial message for this link was dropped.
/// The receiver should answer the GATT write with an error so the sender
/// knows the transfer failed and retries it.
class ReassemblyRejected extends ReassemblyResult {
  const ReassemblyRejected(this.reason);
  final String reason;
}

class _Partial {
  _Partial({
    required this.msgId,
    required this.senderId,
    required this.expectedLength,
    required this.lastChunkAt,
  });

  final int msgId;
  final Uint8List senderId;
  final int expectedLength;
  DateTime lastChunkAt;
  final BytesBuilder bytes = BytesBuilder(copy: false);
  int nextSeq = 1;
}

/// Receiver side of [BleFraming]. Keyed by link (the writer's BLE address):
/// GATT writes from one link arrive in order, and BleTransport serializes its
/// own sends per peer, so at most one message is in flight per link.
class BleReassembler {
  BleReassembler({this.staleAfter = const Duration(seconds: 30), DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Duration staleAfter;
  final DateTime Function() _clock;
  final Map<String, _Partial> _partials = {};

  int get pendingLinkCount => _partials.length;

  ReassemblyResult accept(String linkId, Uint8List chunk) {
    dropStale();
    if (chunk.length < BleFraming.baseHeaderLength || chunk[0] != BleFraming.magic) {
      _partials.remove(linkId);
      return const ReassemblyRejected('not an AgriEdge frame');
    }
    final view = ByteData.sublistView(chunk);
    final flags = view.getUint8(1);
    final msgId = view.getUint16(2);
    final seq = view.getUint16(4);
    final first = flags & BleFraming.flagFirst != 0;
    final last = flags & BleFraming.flagLast != 0;

    _Partial? partial;
    final int dataStart;
    if (first) {
      if (seq != 0) {
        _partials.remove(linkId);
        return const ReassemblyRejected('first chunk with non-zero seq');
      }
      if (chunk.length < BleFraming.firstHeaderLength) {
        _partials.remove(linkId);
        return const ReassemblyRejected('truncated first-chunk header');
      }
      final expectedLength = view.getUint32(6);
      if (expectedLength > BleFraming.maxDatagramLength) {
        _partials.remove(linkId);
        return ReassemblyRejected(
            'declared length $expectedLength exceeds ${BleFraming.maxDatagramLength}');
      }
      // A new first chunk supersedes any unfinished message on this link —
      // the sender gave up on it (e.g. reconnected after a dropped link).
      partial = _Partial(
        msgId: msgId,
        senderId: Uint8List.fromList(chunk.sublist(10, 10 + BleFraming.senderIdLength)),
        expectedLength: expectedLength,
        lastChunkAt: _clock(),
      );
      _partials[linkId] = partial;
      dataStart = BleFraming.firstHeaderLength;
    } else {
      partial = _partials[linkId];
      if (partial == null) {
        return ReassemblyRejected('continuation chunk (msg $msgId seq $seq) with no message in progress');
      }
      if (partial.msgId != msgId || partial.nextSeq != seq) {
        _partials.remove(linkId);
        return ReassemblyRejected(
            'out-of-order chunk: expected msg ${partial.msgId} seq ${partial.nextSeq}, got msg $msgId seq $seq');
      }
      partial.nextSeq++;
      partial.lastChunkAt = _clock();
      dataStart = BleFraming.baseHeaderLength;
    }

    partial.bytes.add(Uint8List.sublistView(chunk, dataStart));
    if (partial.bytes.length > partial.expectedLength) {
      _partials.remove(linkId);
      return ReassemblyRejected(
          'message overran its declared length ${partial.expectedLength}');
    }
    if (!last) return const ReassemblyPending();

    _partials.remove(linkId);
    if (partial.bytes.length != partial.expectedLength) {
      return ReassemblyRejected(
          'message ended at ${partial.bytes.length} of ${partial.expectedLength} bytes');
    }
    return ReassemblyComplete(
      senderId: partial.senderId,
      msgId: partial.msgId,
      datagram: partial.bytes.takeBytes(),
    );
  }

  /// Forget a link's partial message, e.g. when that central disconnects.
  void dropLink(String linkId) => _partials.remove(linkId);

  void dropAll() => _partials.clear();

  /// Drops partial messages that stopped arriving — an interrupted transfer
  /// must not pin memory or poison the link forever. Measured from the last
  /// chunk, not the first: a photo over a slow link may take longer than
  /// [staleAfter] in total while still making progress.
  void dropStale() {
    final now = _clock();
    _partials.removeWhere((_, p) => now.difference(p.lastChunkAt) > staleAfter);
  }
}

String hexOf(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
