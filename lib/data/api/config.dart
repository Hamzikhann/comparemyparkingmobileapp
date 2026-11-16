/// Central place for backend URLs.
///
/// Switch [useLocalBackend] to `false` to go back to the live servers.
class AppConfig {
  /// true  -> local development backend (parkpilotNode on this PC)
  /// false -> live production servers
  static const bool useLocalBackend = false;

  // ---------------- LOCAL (development) ----------------
  // Phone over USB: run `adb reverse tcp:8001 tcp:8001` so the phone's
  // localhost:8001 reaches the PC. (Android emulator: use http://10.0.2.2:8001)
  static const String _localBaseUrl = "http://localhost:8001";

  // ---------------- LIVE (production) ----------------
  static const String _liveBaseUrl = "https://comparemyairportparking.com";

  /// Main API host (requests go to "$baseUrl/api/...").
  static String get baseUrl => useLocalBackend ? _localBaseUrl : _liveBaseUrl;

  /// Base for backend files such as "uploads/pictures/x.jpg" (checkpoint photos).
  /// Live: nginx only sends /api/* to the backend, so files are under /api/uploads.
  static String get filesUrl =>
      useLocalBackend ? _localBaseUrl : '$_liveBaseUrl/api';

  /// socket.io path for chat. On the live domain nginx only sends /api/* to the
  /// backend (/socket.io would reach the website), so live uses /api/socket.io.
  static String get socketPath =>
      useLocalBackend ? '/socket.io' : '/api/socket.io';
}
