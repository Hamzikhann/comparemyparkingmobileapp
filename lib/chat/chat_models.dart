import 'dart:convert';
import 'dart:typed_data';

import 'package:parkingapp/data/api/config.dart';

/// Chat data models (match backend modules/chat/chat.serializers.js).
/// Ids are the API's encrypted ids; `seq` is the message order number.

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
int? _int(dynamic v) => v == null ? null : int.tryParse(v.toString());

/// Profile photo URL (same rule as UserModel: relative paths live under /api).
String? chatImageUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '${AppConfig.baseUrl}/api$path';
}

class ChatUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? imageURL;
  final String? role;
  bool online;
  DateTime? lastSeenAt;

  ChatUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageURL,
    this.role,
    this.online = false,
    this.lastSeenAt,
  });

  String get name => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final s = (f + l).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  factory ChatUser.fromJson(Map<String, dynamic> j) => ChatUser(
        id: (j['id'] ?? '').toString(),
        firstName: (j['firstName'] ?? '').toString(),
        lastName: (j['lastName'] ?? '').toString(),
        imageURL: j['imageURL']?.toString(),
        role: j['role']?.toString(),
        online: j['online'] == true,
        lastSeenAt: _date(j['lastSeenAt']),
      );
}

class ChatMember extends ChatUser {
  final String memberRole;
  int lastReadSeq;
  int lastDeliveredSeq;

  ChatMember({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.imageURL,
    super.role,
    super.online,
    super.lastSeenAt,
    this.memberRole = 'member',
    this.lastReadSeq = 0,
    this.lastDeliveredSeq = 0,
  });

  factory ChatMember.fromJson(Map<String, dynamic> j) {
    final u = ChatUser.fromJson(j);
    return ChatMember(
      id: u.id,
      firstName: u.firstName,
      lastName: u.lastName,
      imageURL: u.imageURL,
      role: u.role,
      online: u.online,
      lastSeenAt: u.lastSeenAt,
      memberRole: (j['memberRole'] ?? 'member').toString(),
      lastReadSeq: _int(j['lastReadSeq']) ?? 0,
      lastDeliveredSeq: _int(j['lastDeliveredSeq']) ?? 0,
    );
  }
}

class ChatReplyPreview {
  final String id;
  final int? seq;
  final String? senderId;
  final String type;
  final String preview;

  ChatReplyPreview(
      {required this.id,
      this.seq,
      this.senderId,
      required this.type,
      required this.preview});

  factory ChatReplyPreview.fromJson(Map<String, dynamic> j) => ChatReplyPreview(
        id: (j['id'] ?? '').toString(),
        seq: _int(j['seq']),
        senderId: j['senderId']?.toString(),
        type: (j['type'] ?? 'text').toString(),
        preview: (j['preview'] ?? '').toString(),
      );
}

/// Local delivery state of MY messages before the server has them.
enum SendState { sending, failed, sent }

/// A file on a message (photo, video, voice note, document).
/// Download it from [url] with the login header (ChatApi.authHeaders).
class ChatAttachment {
  final String id;
  final String mimeType;
  final String? fileName;
  final int sizeBytes;
  final int? durationMs;
  final int? width;
  final int? height;
  final bool hasThumbnail; // video preview frame on the server

  ChatAttachment({
    required this.id,
    required this.mimeType,
    this.fileName,
    required this.sizeBytes,
    this.durationMs,
    this.width,
    this.height,
    this.hasThumbnail = false,
  });

  String get url =>
      '${AppConfig.baseUrl}/api/chat/media/${Uri.encodeComponent(id)}';

  String get thumbUrl => '$url?thumb=1';

  /// Stable cache key (the URL is stable too, but ids are long).
  String get cacheKey => 'chat-att-${id.hashCode}-$sizeBytes';

  double get aspectRatio =>
      (width != null && height != null && width! > 0 && height! > 0)
          ? width! / height!
          : 4 / 3;

  factory ChatAttachment.fromJson(Map<String, dynamic> j) => ChatAttachment(
        id: (j['id'] ?? '').toString(),
        mimeType: (j['mimeType'] ?? 'application/octet-stream').toString(),
        fileName: j['fileName']?.toString(),
        sizeBytes: _int(j['sizeBytes']) ?? 0,
        durationMs: _int(j['durationMs']),
        width: _int(j['width']),
        height: _int(j['height']),
        hasThumbnail: j['hasThumbnail'] == true,
      );
}

/// A file I'm sending: lives on the local message until the server has it.
class OutgoingMedia {
  final String localPath;
  final String kind; // image | video | audio | file
  final String mimeType;
  final String fileName;
  final int sizeBytes;
  final int? durationMs;
  final int? width;
  final int? height;
  String? attachmentId; // set after upload/init
  bool uploaded = false;
  double progress = 0; // 0..1
  Object? cancelToken; // dio CancelToken while uploading
  final String? thumbPath; // JPEG first frame (videos)
  final int? thumbSizeBytes;
  Uint8List? bytes; // web version: the file's contents (no file path there)

  OutgoingMedia({
    this.bytes,
    required this.localPath,
    required this.kind,
    required this.mimeType,
    required this.fileName,
    required this.sizeBytes,
    this.durationMs,
    this.width,
    this.height,
    this.thumbPath,
    this.thumbSizeBytes,
  });

  ChatAttachment toAttachment() => ChatAttachment(
        id: attachmentId ?? '',
        mimeType: mimeType,
        fileName: fileName,
        sizeBytes: sizeBytes,
        durationMs: durationMs,
        width: width,
        height: height,
      );
}

/// One person's emoji on a message.
class ChatReaction {
  final String userId;
  final String emoji;
  ChatReaction({required this.userId, required this.emoji});
}

/// Edit / delete-for-everyone time limits (same as the server).
const kEditWindow = Duration(minutes: 15);
const kDeleteForEveryoneWindow = Duration(hours: 1);

class ChatMessage {
  final String id; // '' while sending
  final int? seq; // null while sending
  final String conversationId;
  final String? senderId; // null = system
  final String type; // text | location | system | image | video | audio | file
  final String? body; // text, location JSON, or a media caption
  final List<ChatAttachment> attachments;
  final List<ChatReaction> reactions;
  OutgoingMedia? outgoing; // my media still uploading / sending
  final bool isDeleted;
  final bool isForwarded;
  final bool isEdited;
  final String? clientMsgKey;
  final ChatReplyPreview? replyTo;
  final DateTime createdAt;
  SendState sendState;

  ChatMessage({
    required this.id,
    required this.seq,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.body,
    this.attachments = const [],
    this.reactions = const [],
    this.outgoing,
    this.isDeleted = false,
    this.isForwarded = false,
    this.isEdited = false,
    this.clientMsgKey,
    this.replyTo,
    required this.createdAt,
    this.sendState = SendState.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] ?? '').toString(),
        seq: _int(j['seq']),
        conversationId: (j['conversationId'] ?? '').toString(),
        senderId: j['senderId']?.toString(),
        type: (j['type'] ?? 'text').toString(),
        body: j['body']?.toString(),
        reactions: ((j['reactions'] as List?) ?? [])
            .map((r) => ChatReaction(
                userId: (r['userId'] ?? '').toString(),
                emoji: (r['emoji'] ?? '').toString()))
            .toList(),
        attachments: ((j['attachments'] as List?) ?? [])
            .map((a) => ChatAttachment.fromJson(Map<String, dynamic>.from(a)))
            .toList(),
        isDeleted: j['isDeleted'] == true,
        isForwarded: j['isForwarded'] == true,
        isEdited: j['isEdited'] == true,
        clientMsgKey: j['clientMsgKey']?.toString(),
        replyTo: j['replyTo'] is Map
            ? ChatReplyPreview.fromJson(Map<String, dynamic>.from(j['replyTo']))
            : null,
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
      );

  /// Location messages carry {lat, lng, label} as JSON text.
  ({double lat, double lng, String? label})? get location {
    if (type != 'location' || body == null) return null;
    try {
      final m = jsonDecode(body!) as Map<String, dynamic>;
      return (
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        label: m['label']?.toString()
      );
    } catch (_) {
      return null;
    }
  }

  bool get isSent => seq != null && id.isNotEmpty;
  bool get canEditNow =>
      isSent &&
      !isDeleted &&
      (type == 'text' || isMedia) &&
      DateTime.now().difference(createdAt) < kEditWindow;
  bool get canDeleteForEveryoneNow =>
      isSent &&
      !isDeleted &&
      DateTime.now().difference(createdAt) < kDeleteForEveryoneWindow;

  /// Reactions grouped: emoji -> how many.
  Map<String, int> get reactionCounts {
    final out = <String, int>{};
    for (final r in reactions) {
      out[r.emoji] = (out[r.emoji] ?? 0) + 1;
    }
    return out;
  }

  bool get isMedia =>
      type == 'image' || type == 'video' || type == 'audio' || type == 'file';

  /// The file on this message (server copy, or my local one while sending).
  ChatAttachment? get attachment =>
      attachments.isNotEmpty ? attachments.first : outgoing?.toAttachment();

  String? get caption =>
      isMedia && body != null && body!.trim().isNotEmpty ? body : null;

  String get previewText {
    if (isDeleted) return 'This message was deleted';
    switch (type) {
      case 'location':
        return '📍 Location';
      case 'image':
        return '📷 ${caption ?? 'Photo'}';
      case 'video':
        return '🎥 ${caption ?? 'Video'}';
      case 'audio':
        return '🎤 Voice message';
      case 'file':
        return '📄 ${attachment?.fileName ?? 'Document'}';
      default:
        return body ?? '';
    }
  }
}

class ChatLastMessage {
  final int? seq;
  final String? senderId;
  final String type;
  final String preview;
  final DateTime? createdAt;

  ChatLastMessage(
      {this.seq,
      this.senderId,
      required this.type,
      required this.preview,
      this.createdAt});

  factory ChatLastMessage.fromJson(Map<String, dynamic> j) => ChatLastMessage(
        seq: _int(j['seq']),
        senderId: j['senderId']?.toString(),
        type: (j['type'] ?? 'text').toString(),
        preview: (j['preview'] ?? '').toString(),
        createdAt: _date(j['createdAt']),
      );

  factory ChatLastMessage.fromMessage(ChatMessage m) => ChatLastMessage(
        seq: m.seq,
        senderId: m.senderId,
        type: m.type,
        preview: m.previewText,
        createdAt: m.createdAt,
      );
}

class ChatConversation {
  final String id;
  final String type; // direct | group
  final String? title;
  final String? avatarUrl;
  final String? avatarAttachmentId; // group photo (GET /chat/media/<id>)
  final String? createdById;
  final String myRole; // admin | member (groups)
  ChatLastMessage? lastMessage;
  DateTime? lastMessageAt;
  int unreadCount;
  bool isPinned;
  bool isArchived;
  DateTime? mutedUntil;
  final List<ChatMember> members;

  ChatConversation({
    required this.id,
    required this.type,
    this.title,
    this.avatarUrl,
    this.avatarAttachmentId,
    this.createdById,
    this.myRole = 'member',
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.mutedUntil,
    required this.members,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> j) => ChatConversation(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? 'direct').toString(),
        title: j['title']?.toString(),
        avatarUrl: j['avatarUrl']?.toString(),
        avatarAttachmentId: j['avatarAttachmentId']?.toString(),
        createdById: j['createdById']?.toString(),
        myRole: (j['myRole'] ?? 'member').toString(),
        lastMessage: j['lastMessage'] is Map
            ? ChatLastMessage.fromJson(
                Map<String, dynamic>.from(j['lastMessage']))
            : null,
        lastMessageAt: _date(j['lastMessageAt']),
        unreadCount: _int(j['unreadCount']) ?? 0,
        isPinned: j['isPinned'] == true,
        isArchived: j['isArchived'] == true,
        mutedUntil: _date(j['mutedUntil']),
        members: ((j['members'] as List?) ?? [])
            .map((m) => ChatMember.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  bool get isGroup => type == 'group';
  bool get amAdmin => myRole == 'admin';

  /// Group photo URL (load with ChatApi.authHeaders), or null.
  String? get groupPhotoUrl => avatarAttachmentId == null
      ? null
      : '${AppConfig.baseUrl}/api/chat/media/${Uri.encodeComponent(avatarAttachmentId!)}';
  bool get isMuted => mutedUntil != null && mutedUntil!.isAfter(DateTime.now());

  /// For 1-to-1 chats: the other person.
  ChatMember? other(String meId) {
    for (final m in members) {
      if (m.id != meId) return m;
    }
    return null;
  }

  String displayName(String meId) =>
      isGroup ? (title ?? 'Group') : (other(meId)?.name ?? 'Chat');

  /// The admin's 1-to-1 chat with the Reports Bot (server role "Bot").
  bool isBotChat(String meId) =>
      !isGroup && (other(meId)?.role ?? '').toLowerCase() == 'bot';
}

/// A report requested from the Reports Bot (POST /chat/bot/report-request).
class BotReportJob {
  final String jobId;
  final String airportName;
  final String fromDate;
  final String toDate;
  final String format;
  final String status; // queued | sent | processing | done | failed
  final String? error;

  BotReportJob.fromJson(Map<String, dynamic> j)
      : jobId = (j['jobId'] ?? '').toString(),
        airportName = (j['airportName'] ?? '').toString(),
        fromDate = (j['fromDate'] ?? '').toString(),
        toDate = (j['toDate'] ?? '').toString(),
        format = (j['format'] ?? '').toString(),
        status = (j['status'] ?? '').toString(),
        error = j['error']?.toString();
}

// ------------------------------------------------------------------ cache
// toJson mirrors the server shapes so fromJson can read the phone's cache.

String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

extension ChatUserJson on ChatUser {
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'imageURL': imageURL,
        'role': role,
        'online': false, // presence is live-only
        'lastSeenAt': _iso(lastSeenAt),
        if (this is ChatMember) ...{
          'memberRole': (this as ChatMember).memberRole,
          'lastReadSeq': (this as ChatMember).lastReadSeq,
          'lastDeliveredSeq': (this as ChatMember).lastDeliveredSeq,
        },
      };
}

extension ChatMessageJson on ChatMessage {
  Map<String, dynamic> toJson() => {
        'id': id,
        'seq': seq,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': type,
        'body': body,
        'isDeleted': isDeleted,
        'isForwarded': isForwarded,
        'isEdited': isEdited,
        'clientMsgKey': clientMsgKey,
        'replyTo': replyTo == null
            ? null
            : {
                'id': replyTo!.id,
                'seq': replyTo!.seq,
                'senderId': replyTo!.senderId,
                'type': replyTo!.type,
                'preview': replyTo!.preview,
              },
        'attachments': [
          for (final a in attachments)
            {
              'id': a.id,
              'mimeType': a.mimeType,
              'fileName': a.fileName,
              'sizeBytes': a.sizeBytes,
              'durationMs': a.durationMs,
              'width': a.width,
              'height': a.height,
              'hasThumbnail': a.hasThumbnail,
            }
        ],
        'reactions': [
          for (final r in reactions) {'userId': r.userId, 'emoji': r.emoji}
        ],
        'createdAt': _iso(createdAt),
      };
}

extension ChatConversationJson on ChatConversation {
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'avatarUrl': avatarUrl,
        'avatarAttachmentId': avatarAttachmentId,
        'createdById': createdById,
        'myRole': myRole,
        'lastMessage': lastMessage == null
            ? null
            : {
                'seq': lastMessage!.seq,
                'senderId': lastMessage!.senderId,
                'type': lastMessage!.type,
                'preview': lastMessage!.preview,
                'createdAt': _iso(lastMessage!.createdAt),
              },
        'lastMessageAt': _iso(lastMessageAt),
        'unreadCount': unreadCount,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'mutedUntil': _iso(mutedUntil),
        'members': [for (final m in members) m.toJson()],
      };
}
