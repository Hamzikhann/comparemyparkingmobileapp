// Staff web version: browser notifications, tab-title unread count and an
// alert sound (no Firebase on the web). On the phone every call does nothing.
export 'web_notify_stub.dart' if (dart.library.js_interop) 'web_notify_web.dart';
