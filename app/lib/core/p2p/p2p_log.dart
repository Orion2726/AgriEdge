import 'package:flutter/foundation.dart';

/// Debug-build-only diagnostics for the P2P mesh: peer/session ids, message
/// and packet ids, connection state, send/receive/ack events and retry
/// reasons. Logged under a fixed `[P2P]` prefix so two phones' logcats can
/// be grepped and correlated (`adb logcat | grep '\[P2P\]'`). Carries no
/// location or personal data beyond device fingerprints. Compiled out of
/// release builds (kDebugMode is a const false there).
void p2pLog(String message) {
  if (kDebugMode) {
    debugPrint('[P2P] ${DateTime.now().toIso8601String()} $message');
  }
}
