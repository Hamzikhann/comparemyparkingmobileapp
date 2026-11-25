import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parkingapp/chat/web_media.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/chat/chat_api.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/data/api/config.dart';
import 'package:parkingapp/utils/colors.dart';

/// Chat colours, built on the app palette.
class ChatColors {
  static const Color myBubble = Color(0xFFDCEFE7); // light green-teal
  static const Color theirBubble = Colors.white;
  static const Color background = Color(0xFFF2F3F7); // colors.background
  static const Color muted = Color(0xFF6B6B6B);
  static const Color readTick = Color(0xFF34B7F1); // WhatsApp-style blue
  static const Color online = Color(0xFF25D366);
  static const Color unread = colors.secondarynew;
}

class ChatAvatar extends StatelessWidget {
  final ChatUser? user;
  final String? fallbackText;
  final double radius;
  final bool showOnline;

  const ChatAvatar(
      {super.key,
      this.user,
      this.fallbackText,
      this.radius = 24,
      this.showOnline = false});

  @override
  Widget build(BuildContext context) {
    final url = chatImageUrl(user?.imageURL);
    final initials = user?.initials ?? (fallbackText ?? '?');
    final circle = CircleAvatar(
      radius: radius.r,
      backgroundColor: colors.primaryNew.withOpacity(0.12),
      child: url == null
          ? Text(initials,
              style: TextStyle(
                  color: colors.primaryNew,
                  fontWeight: FontWeight.w700,
                  fontSize: (radius * 0.7).sp))
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: radius.r * 2,
                height: radius.r * 2,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Text(initials,
                    style: TextStyle(
                        color: colors.primaryNew,
                        fontWeight: FontWeight.w700,
                        fontSize: (radius * 0.7).sp)),
              ),
            ),
    );
    if (!showOnline || user == null) return circle;
    final online = ChatService.instance.isOnline(user!);
    return Stack(
      children: [
        circle,
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: (radius * 0.55).r,
              height: (radius * 0.55).r,
              decoration: BoxDecoration(
                color: ChatColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class TickIcon extends StatelessWidget {
  final Tick tick;
  final double size;
  const TickIcon(this.tick, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    switch (tick) {
      case Tick.sending:
        return Icon(Icons.schedule, size: size.sp, color: ChatColors.muted);
      case Tick.failed:
        return Icon(Icons.error_outline, size: size.sp, color: Colors.red);
      case Tick.sent:
        return Icon(Icons.done, size: size.sp, color: ChatColors.muted);
      case Tick.delivered:
        return Icon(Icons.done_all, size: size.sp, color: ChatColors.muted);
      case Tick.read:
        return Icon(Icons.done_all, size: size.sp, color: ChatColors.readTick);
    }
  }
}

/// "14:05", "Yesterday", "Mon", "12/11/26" (chat list).
String chatListTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return DateFormat('h:mm a').format(t);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEE').format(t);
  return DateFormat('dd/MM/yy').format(t);
}

/// "Today", "Yesterday", "Monday", "12 November 2026" (date chips in a chat).
String chatDayLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(t);
  return DateFormat('d MMMM yyyy').format(t);
}

/// "online", "last seen today at 14:05", ...
String presenceText(ChatUser u) {
  final s = ChatService.instance;
  if (s.isOnline(u)) return 'online';
  final seen = s.lastSeen(u);
  if (seen == null) return '';
  final label = chatDayLabel(seen);
  final time = DateFormat('h:mm a').format(seen);
  if (label == 'Today') return 'last seen today at $time';
  if (label == 'Yesterday') return 'last seen yesterday at $time';
  return 'last seen $label';
}

/// Message text where web links, emails and phone numbers can be tapped.
class LinkText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const LinkText(this.text, {super.key, this.style});

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  static final _pattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s<>]+[^\s<>.,;:!?)\]"])'
    r'|([\w.+-]+@[\w-]+\.[\w.-]*\w)'
    r'|(\+?\d[\d \-]{6,}\d)',
    caseSensitive: false,
  );
  final List<TapGestureRecognizer> _taps = [];

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  Uri _uriFor(Match m) {
    if (m.group(1) != null) {
      final u = m.group(1)!;
      return Uri.parse(u.toLowerCase().startsWith('www.') ? 'https://$u' : u);
    }
    if (m.group(2) != null) return Uri(scheme: 'mailto', path: m.group(2));
    return Uri(
        scheme: 'tel', path: m.group(3)!.replaceAll(RegExp(r'[ \-]'), ''));
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _pattern.allMatches(widget.text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      }
      final uri = _uriFor(m);
      final tap = TapGestureRecognizer()
        ..onTap = () => launchUrl(uri, mode: LaunchMode.externalApplication);
      _taps.add(tap);
      spans.add(TextSpan(
        text: m.group(0),
        recognizer: tap,
        style: const TextStyle(
            color: Color(0xFF1565C0), decoration: TextDecoration.underline),
      ));
      last = m.end;
    }
    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

/// Avatar for a chat: the other person, or the group photo / group icon.
class ConversationAvatar extends StatelessWidget {
  final ChatConversation conversation;
  final double radius;
  final bool showOnline;
  const ConversationAvatar(this.conversation,
      {super.key, this.radius = 24, this.showOnline = false});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    if (!c.isGroup) {
      return ChatAvatar(
          user: c.other(ChatService.instance.meId),
          radius: radius,
          showOnline: showOnline);
    }
    return GroupAvatar(c.avatarAttachmentId, radius: radius);
  }
}

/// Group photo by attachment id, or the group icon when there is none.
class GroupAvatar extends StatelessWidget {
  final String? attachmentId;
  final double radius;
  const GroupAvatar(this.attachmentId, {super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.group, color: colors.primaryNew, size: radius.r);
    final id = attachmentId;
    final url = (id == null || id.isEmpty)
        ? null
        : '${AppConfig.baseUrl}/api/chat/media/${Uri.encodeComponent(id)}';
    return CircleAvatar(
      radius: radius.r,
      backgroundColor: colors.primaryNew.withOpacity(0.12),
      child: url == null
          ? icon
          : ClipOval(
              child: kIsWeb
                  ? ChatWebImage(id!,
                      width: radius.r * 2,
                      height: radius.r * 2,
                      fit: BoxFit.cover,
                      error: icon)
                  : CachedNetworkImage(
                imageUrl: url,
                cacheKey: 'group-${id.hashCode}',
                httpHeaders: ChatApi.authHeaders,
                width: radius.r * 2,
                height: radius.r * 2,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => icon,
              ),
            ),
    );
  }
}
