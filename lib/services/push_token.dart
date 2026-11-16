import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';

/// Keeps the server's push token for the logged-in user up to date.
/// Login already sends it; this also sends it when the app opens already
/// logged in, and whenever Firebase gives this phone a new token.
class PushToken {
  static bool _listening = false;

  static bool get _loggedIn => (Globals.user?.token ?? '').isNotEmpty;

  /// This phone's token, or null if Firebase can't give one right now.
  static Future<String?> current() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      return null;
    }
  }

  /// Sends this phone's token for the logged-in user. Never throws.
  static Future<void> sync([String? token]) async {
    _listenForRefresh();
    if (!_loggedIn) return;
    token ??= await current();
    if (token == null) return;
    try {
      await GeneralRepository().saveFcmToken(token);
    } catch (_) {
      // Offline or server error: tried again on the next app start
    }
  }

  static void _listenForRefresh() {
    if (_listening) return;
    _listening = true;
    FirebaseMessaging.instance.onTokenRefresh
        .listen((token) => sync(token), onError: (_) {});
  }
}
