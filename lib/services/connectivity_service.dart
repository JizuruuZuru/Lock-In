import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static Future<bool> isOffline() async {
    // connectivity_plus 6.x reports every active transport, so an offline
    // device is an empty list or one holding only `none`.
    final results = await Connectivity().checkConnectivity();
    if (results.every((result) => result == ConnectivityResult.none)) {
      return true;
    }

    // The transport check alone can't tell "connected to Wi-Fi" from
    // "connected to Wi-Fi that has no route out", so it is confirmed with a
    // real DNS lookup — everywhere except the web.
    //
    // `dart:io` compiles on the web but is a stub: every entry point throws
    // `UnsupportedError`, so `InternetAddress.lookup` would fail here rather
    // than answering the question. The browser's own connectivity signal is
    // all that is available, so trust it and report online.
    if (kIsWeb) return false;

    try {
      // Bounded. A DNS lookup on a captive portal or a half-dead network can
      // hang for as long as the OS is willing to wait, and until it answers
      // `offlineStream` emits nothing at all - so the banner stays hidden on
      // exactly the network where somebody most needs to be told. A lookup
      // that cannot finish promptly is, for this purpose, offline.
      final lookup = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isEmpty;
    } on TimeoutException {
      return true;
    } on SocketException {
      return true;
    } on UnsupportedError {
      // A platform without a real dart:io. Fall back to the transport check
      // above, which already said we have one.
      return false;
    }
  }

  /// Current offline state, then an update every time it changes.
  ///
  /// Emits immediately so a banner can paint the right state on its first
  /// frame instead of waiting for the connection to change.
  static Stream<bool> offlineStream() async* {
    yield await isOffline();
    yield* Connectivity()
        .onConnectivityChanged
        .asyncMap((_) => isOffline())
        .distinct();
  }
}
