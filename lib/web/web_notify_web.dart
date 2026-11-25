// Web build (see web_notify.dart).
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Tab hidden, minimised or another window focused.
bool get webPageInBackground {
  try {
    return web.document.hidden || !web.document.hasFocus();
  } catch (_) {
    return false;
  }
}

bool _unlocked = false;
web.AudioContext? _audio;

/// Call on the first click: browsers only allow the permission prompt and
/// sound after the user has interacted with the page.
void webUnlockAlerts() {
  if (_unlocked) return;
  _unlocked = true;
  try {
    if (web.Notification.permission == 'default') {
      web.Notification.requestPermission();
    }
  } catch (_) {}
  try {
    _audio ??= web.AudioContext();
    _audio!.resume();
  } catch (_) {}
}

void webShowNotification(String title, String body,
    {String? tag, void Function()? onClick}) {
  try {
    if (web.Notification.permission != 'granted') return;
    final n = web.Notification(
      title,
      web.NotificationOptions(
          body: body, tag: tag ?? '', icon: 'icons/Icon-192.png'),
    );
    n.onclick = ((web.Event _) {
      web.window.focus();
      n.close();
      onClick?.call();
    }).toJS;
  } catch (_) {}
}

String? _baseTitle;

void webSetUnreadCount(int count) {
  try {
    _baseTitle ??= web.document.title;
    final t = count > 0 ? '($count) $_baseTitle' : _baseTitle!;
    if (web.document.title != t) web.document.title = t;
  } catch (_) {}
}

/// Short two-tone chime (no sound file needed).
void webBeep() {
  try {
    final ctx = _audio ??= web.AudioContext();
    final now = ctx.currentTime;
    for (final (i, freq) in [(0, 880.0), (1, 1320.0)]) {
      final start = now + i * 0.15;
      final o = ctx.createOscillator();
      final g = ctx.createGain();
      o.type = 'sine';
      o.frequency.value = freq;
      g.gain.setValueAtTime(0.0001, start);
      g.gain.exponentialRampToValueAtTime(0.25, start + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, start + 0.3);
      o.connect(g);
      g.connect(ctx.destination);
      o.start(start);
      o.stop(start + 0.32);
    }
  } catch (_) {}
}
