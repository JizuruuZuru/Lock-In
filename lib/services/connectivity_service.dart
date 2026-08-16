import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOffline() async {
    // connectivity_plus 6.x reports every active transport, so an offline
    // device is an empty list or one holding only `none`.
    final results = await Connectivity().checkConnectivity();
    if (results.every((result) => result == ConnectivityResult.none)) {
      return true;
    }

    try {
      final lookup = await InternetAddress.lookup('example.com');
      return lookup.isEmpty;
    } on SocketException {
      return true;
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
