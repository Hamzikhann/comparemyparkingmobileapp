import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:parkingapp/chat/chat_api.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

/// Tick shown on MY messages.
enum Tick { sending, failed, sent, delivered, read }

/// App-wide chat state + live connection (one instance).
///
/// - Connects the socket while the app is in the foreground (push covers the
///   background, because the server only pushes to offline users).
/// - Keeps the chat list, loaded messages, typing and presence.
/// - Outbox: messages typed while offline stay "sending" and are re-sent on
///   reconnect with the same clientMsgKey, so they are never duplicated.
class ChatService extends ChangeNotifier with WidgetsBindingObserver {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const _staffRoles = ['employee', 'administrator'];
  static bool get isStaff =>
      _staffRoles.contains((Globals.user?.roleTitle ?? '').toLowerCase());

  final ChatApi api = ChatApi();
  io.Socket? _socket;
  bool _started = false;
  String? _startedFor;
  Timer? _backgroundTimer;
  bool _inBackground = false;

  bool connected = false;
  bool loadingConversations = false;
  List<ChatConversation> conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, Map<String, Timer>> _typing =
      {}; // convId -> userId -> expiry
  final Map<String, ({bool online, DateTime? lastSeenAt})> _presence = {};

  /// Chat currently open on screen (no unread count / no push banner for it).
  String? activeConversationId;

  String get meId => Globals.user?.id ?? '';

  int get totalUnread => conversations.fold(
      0, (sum, c) => sum + (c.isMuted || c.isArchived ? 0 : c.unreadCount));

  List<ChatMessage> messagesFor(String convId) => _messages[convId] ?? const [];
  bool hasMore(String convId) => _hasMore[convId] ?? true;
  bool isLoaded(String convId) => _messages.containsKey(convId);

  // ------------------------------------------------------------ lifecycle

  /// Call after login (employee/admin shells). Safe to call more than once.
  void start() {
    // A different user logged in (e.g. via an older logout path): reset first
    if (_started && _startedFor != meId) stop();
    if (_started || !isStaff) return;
    _started = true;
    _startedFor = meId;
    WidgetsBinding.instance.addObserver(this);
    _loadCache(); // instant list + readable offline, then refreshed live
    _connect();
    refreshConversations();
  }

  // ---------------------------------------------------------- local cache
  // The chat list + the latest 50 messages per chat are kept in a file per
  // user, so chats open instantly and can be read without signal. Deleted on
  // logout. (Media files have their own cache.)

  static const _cacheMessages = 50;
  Timer? _saveTimer;
  bool _cacheReady = false; // don't overwrite the file before it was read

  Future<File> _cacheFile(String userId) async {
    final dir = await getApplicationSupportDirectory();
    final safe = userId.hashCode.toUnsigned(32).toRadixString(16);
    return File('${dir.path}/chat_cache_$safe.json');
  }

  Future<void> _loadCache() async {
    final forUser = meId;
    try {
      final f = await _cacheFile(forUser);
      if (await f.exists() && conversations.isEmpty && meId == forUser) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        conversations = ((j['conversations'] as List?) ?? [])
            .map((c) => ChatConversation.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        final msgs = Map<String, dynamic>.from((j['messages'] as Map?) ?? {});
        msgs.forEach((convId, list) {
          _messages.putIfAbsent(
              convId,
              () => (list as List)
                  .map(
                      (m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
                  .toList());
          _hasMore[convId] = true;
        });
        _sortConversations();
        loadingConversations = false;
        super.notifyListeners();
      }
    } catch (e) {
      debugPrint('chat: cache read failed: $e');
    } finally {
      _cacheReady = true;
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_started || !_cacheReady) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveCache);
  }

  /// Logout: remove this user's cached chats from the phone.
  Future<void> _deleteCache(String userId) async {
    try {
      final f = await _cacheFile(userId);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('chat: cache delete failed: $e');
    }
  }

  Future<void> _saveCache() async {
    final forUser = _startedFor;
    if (!_started || forUser == null) return;
    try {
      final data = {
        'conversations': [for (final c in conversations) c.toJson()],
        'messages': {
          for (final e in _messages.entries)
            e.key: [
              for (final m in e.value
                  .where((m) => m.seq != null)
                  .toList()
                  .reversed
                  .take(_cacheMessages)
                  .toList()
                  .reversed)
                m.toJson()
            ]
        },
      };
      await (await _cacheFile(forUser)).writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('chat: cache write failed: $e');
    }
  }

  /// Call on logout: drops the connection and all cached chat data.
  void stop() {
    if (!_started) return;
    _started = false;
    _saveTimer?.cancel();
    _cacheReady = false;
    final who = _startedFor;
    if (who != null) {
      _deleteCache(who);
    }
    leftGroups.clear();
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    connected = false;
    conversations = [];
    _messages.clear();
    _hasMore.clear();
    for (final t in _typing.values.expand((m) => m.values)) {
      t.cancel();
    }
    _typing.clear();
    _presence.clear();
    activeConversationId = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      _inBackground = false;
      _backgroundTimer?.cancel();
      if (_socket == null) {
        _connect();
      } else {
        _socket!.emit('chat:active'); // pushes stop, "online" again
      }
      refreshConversations();
    } else if (state == AppLifecycleState.paused) {
      // Tell the server at once that I'm away, so new messages are pushed
      // right away. Keep the connection a little longer (camera / file
      // picker), then close it.
      _inBackground = true;
      _socket?.emit('chat:away');
      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(const Duration(seconds: 10), () {
        _socket?.dispose();
        _socket = null;
        connected = false;
      });
    }
  }

  void _connect() {
    final token = Globals.user?.token ?? '';
    if (token.isEmpty) return;
    final s = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(AppConfig.socketPath)
          .setAuth({'token': token})
          .enableForceNew() // never reuse another login's connection
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .disableAutoConnect()
          .build(),
    );

    s.onConnect((_) {
      connected = true;
      // Reconnected while minimised: still away (keep pushes coming)
      if (_inBackground) s.emit('chat:away');
      notifyListeners();
      _catchUp();
    });
    s.onDisconnect((_) {
      connected = false;
      notifyListeners();
    });
    s.on('chat:message', (d) => _onMessage(Map<String, dynamic>.from(d)));
    s.on('chat:receipt', (d) => _onReceipt(Map<String, dynamic>.from(d)));
    s.on('chat:typing', (d) => _onTyping(Map<String, dynamic>.from(d)));
    s.on('chat:presence', (d) => _onPresence(Map<String, dynamic>.from(d)));
    s.on('chat:message:update', (d) {
      final j = Map<String, dynamic>.from(d);
      _applyUpdate(
          ChatMessage.fromJson(Map<String, dynamic>.from(j['message'])));
    });
    s.on('chat:message:hidden', (d) => _onHidden(Map<String, dynamic>.from(d)));
    s.on('chat:conversation:changed', (d) {
      final id =
          (Map<String, dynamic>.from(d)['conversationId'] ?? '').toString();
      if (id.isNotEmpty) reloadConversation(id);
    });
    s.on('chat:conversation:left', (d) {
      final id =
          (Map<String, dynamic>.from(d)['conversationId'] ?? '').toString();
      _markLeft(id);
    });
    _socket = s;
    s.connect();
  }

  /// After (re)connecting: refresh the list, fetch missed messages for chats
  /// already loaded, and re-send anything still in the outbox.
  Future<void> _catchUp() async {
    await refreshConversations();
    for (final convId in _messages.keys.toList()) {
      final list = _messages[convId]!;
      final lastSeq = list
          .lastWhere((m) => m.seq != null,
              orElse: () => ChatMessage(
                  id: '',
                  seq: 0,
                  conversationId: convId,
                  senderId: null,
                  type: 'text',
                  body: null,
                  createdAt: DateTime.now()))
          .seq;
      try {
        final (missed, _) =
            await api.messages(convId, afterSeq: lastSeq, limit: 100);
        for (final m in missed) {
          _upsert(m);
        }
      } catch (_) {}
      for (final m in list.where((m) => m.seq == null).toList()) {
        if (m.outgoing == null) {
          _deliver(m);
        } else if (m.sendState == SendState.sending &&
            !_mediaBusy.contains(m.clientMsgKey)) {
          _sendMedia(m); // resumes where it stopped (upload or send)
        }
      }
    }
    if (activeConversationId != null) markRead(activeConversationId!);
    notifyListeners();
  }

  // --------------------------------------------------------------- loading

  Future<void> refreshConversations() async {
    if (!isStaff) return;
    // Callers include initState(); never notify listeners during a build
    await Future<void>.delayed(Duration.zero);
    loadingConversations = conversations.isEmpty;
    notifyListeners();
    try {
      conversations = await api.conversations();
      _sortConversations();
    } catch (e) {
      debugPrint('chat: conversations failed: $e');
    } finally {
      loadingConversations = false;
      notifyListeners();
    }
  }

  void _sortConversations() {
    conversations.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final at = a.lastMessageAt ?? DateTime(1970);
      final bt = b.lastMessageAt ?? DateTime(1970);
      return bt.compareTo(at);
    });
  }

  ChatConversation? conversationById(String id) {
    for (final c in conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Ensures a conversation (e.g. opened from a push) is known locally.
  Future<ChatConversation> ensureConversation(String id) async {
    final known = conversationById(id);
    if (known != null) return known;
    final c = await api.conversation(id);
    conversations.add(c);
    _sortConversations();
    notifyListeners();
    return c;
  }

  /// Opens (or creates) the 1-to-1 chat with a contact.
  Future<ChatConversation> openDirect(ChatUser user) async {
    final c = await api.direct(user.id);
    if (conversationById(c.id) == null) {
      conversations.add(c);
      _sortConversations();
      notifyListeners();
    }
    return conversationById(c.id)!;
  }

  Future<void> loadLatest(String convId) async {
    final (list, more) = await api.messages(convId);
    // keep unsent local messages
    final pending = messagesFor(convId).where((m) => m.seq == null).toList();
    _messages[convId] = [...list, ...pending];
    _hasMore[convId] = more;
    notifyListeners();
  }

  Future<void> loadOlder(String convId) async {
    final list = _messages[convId];
    if (list == null || !(hasMore(convId))) return;
    final firstSeq =
        list.firstWhere((m) => m.seq != null, orElse: () => list.first).seq;
    if (firstSeq == null) return;
    final (older, more) = await api.messages(convId, beforeSeq: firstSeq);
    _messages[convId] = [...older, ...list];
    _hasMore[convId] = more;
    notifyListeners();
  }

  // --------------------------------------------------------------- sending

  void sendText(String convId, String text, {ChatMessage? replyTo}) {
    final t = text.trim();
    if (t.isEmpty) return;
    _queue(convId, 'text', t, replyTo: replyTo);
  }

  void sendLocation(String convId, double lat, double lng, {String? label}) {
    _queue(convId, 'location',
        '{"lat":$lat,"lng":$lng${label != null ? ',"label":"${label.replaceAll('"', '')}"' : ''}}');
  }

  void _queue(String convId, String type, String body, {ChatMessage? replyTo}) {
    final local = ChatMessage(
      id: '',
      seq: null,
      conversationId: convId,
      senderId: meId,
      type: type,
      body: body,
      clientMsgKey: const Uuid().v4().replaceAll('-', ''),
      replyTo: replyTo == null
          ? null
          : ChatReplyPreview(
              id: replyTo.id,
              seq: replyTo.seq,
              senderId: replyTo.senderId,
              type: replyTo.type,
              preview: replyTo.previewText),
      createdAt: DateTime.now(),
      sendState: SendState.sending,
    );
    (_messages[convId] ??= []).add(local);
    _bumpConversation(convId, local, fromMe: true);
    notifyListeners();
    _deliver(local);
  }

  /// Retry a failed message (same clientMsgKey: never duplicated).
  void retry(ChatMessage m) {
    m.sendState = SendState.sending;
    notifyListeners();
    if (m.outgoing != null) {
      _sendMedia(m);
    } else {
      _deliver(m);
    }
  }

  // ------------------------------------------------------------------ media

  final Set<String?> _mediaBusy = {};
  final Map<String, String> _localFiles = {}; // attachmentId -> my local copy
  final Map<String, String> _localThumbs = {}; // attachmentId -> my thumbnail

  /// Photo / video / voice note / document. Shows at once with a progress
  /// ring, uploads, then sends. Retry resumes; cancel removes it.
  void sendMedia(String convId, OutgoingMedia file,
      {String? caption, ChatMessage? replyTo}) {
    final c = caption?.trim();
    final local = ChatMessage(
      id: '',
      seq: null,
      conversationId: convId,
      senderId: meId,
      type: file.kind,
      body: (c == null || c.isEmpty) ? null : c,
      outgoing: file,
      clientMsgKey: const Uuid().v4().replaceAll('-', ''),
      replyTo: replyTo == null
          ? null
          : ChatReplyPreview(
              id: replyTo.id,
              seq: replyTo.seq,
              senderId: replyTo.senderId,
              type: replyTo.type,
              preview: replyTo.previewText),
      createdAt: DateTime.now(),
      sendState: SendState.sending,
    );
    (_messages[convId] ??= []).add(local);
    _bumpConversation(convId, local, fromMe: true);
    notifyListeners();
    _sendMedia(local);
  }

  Future<void> _sendMedia(ChatMessage m) async {
    final f = m.outgoing!;
    if (!_mediaBusy.add(m.clientMsgKey)) return;
    try {
      if (f.attachmentId == null || !f.uploaded) {
        final (id, target, thumbTarget) =
            await api.uploadInit(m.conversationId, f);
        // Small preview first (video first frame); failure here is harmless
        if (thumbTarget != null && f.thumbPath != null) {
          try {
            await api.uploadFile(thumbTarget, f.thumbPath!, f.thumbSizeBytes!);
            _localThumbs[id] = f.thumbPath!;
          } catch (e) {
            debugPrint('chat: thumbnail upload failed: $e');
          }
        }
        f.attachmentId = id;
        final token = CancelToken();
        f.cancelToken = token;
        var lastTick = DateTime.now();
        await api.uploadFile(target, f.localPath, f.sizeBytes,
            cancelToken: token, onProgress: (p) {
          f.progress = p;
          final now = DateTime.now();
          if (now.difference(lastTick).inMilliseconds > 150 || p >= 1) {
            lastTick = now;
            notifyListeners();
          }
        });
        f.uploaded = true;
        f.cancelToken = null;
        _localFiles[id] = f.localPath;
      }
      await _deliver(m);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // cancelMedia already removed it
      debugPrint('chat: upload failed: $e');
      m.sendState = SendState.failed;
      notifyListeners();
    } catch (e) {
      debugPrint('chat: media send failed: $e');
      m.sendState = SendState.failed;
      notifyListeners();
    } finally {
      _mediaBusy.remove(m.clientMsgKey);
    }
  }

  /// Stop an upload (or drop a failed one) and remove it from the chat.
  void cancelMedia(ChatMessage m) {
    final t = m.outgoing?.cancelToken;
    if (t is CancelToken) t.cancel();
    _messages[m.conversationId]?.remove(m);
    notifyListeners();
  }

  /// The file for an attachment on this phone: my original if I sent it,
  /// else a cached download (downloaded now if needed).
  Future<File> fileFor(ChatAttachment a,
      {void Function(double)? onProgress, CancelToken? cancelToken}) async {
    final mine = _localFiles[a.id];
    if (mine != null && await File(mine).exists()) return File(mine);
    final dir = Directory('${(await getTemporaryDirectory()).path}/chat_media');
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = (a.fileName ?? '').replaceAll(RegExp(r'[^\w.\- ]'), '_');
    final ext = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '';
    final file = File('${dir.path}/${a.cacheKey}$ext');
    if (await file.exists()) return file;
    await api.download(a, file.path,
        onProgress: onProgress, cancelToken: cancelToken);
    return file;
  }

  /// My original file for an attachment I sent from this phone, if any.
  String? localPathFor(ChatAttachment a) => _localFiles[a.id];

  /// My local video thumbnail for an attachment I sent, if any.
  String? localThumbFor(ChatAttachment a) => _localThumbs[a.id];

  Future<void> _deliver(ChatMessage m) async {
    final payload = {
      'conversationId': m.conversationId,
      'type': m.type,
      'body': m.body,
      'clientMsgKey': m.clientMsgKey,
      if (m.replyTo != null) 'replyToMessageId': m.replyTo!.id,
      if (m.outgoing?.attachmentId != null)
        'attachmentId': m.outgoing!.attachmentId,
    };
    try {
      ChatMessage saved;
      final s = _socket;
      if (s != null && connected) {
        saved = await _emitAck(s, 'chat:send', payload);
      } else {
        saved = await api.send(payload); // REST fallback
      }
      _upsert(saved);
    } catch (e) {
      debugPrint('chat: send failed: $e');
      // Stay in the outbox while offline; mark failed only if online and rejected
      m.sendState = connected ? SendState.failed : SendState.sending;
      notifyListeners();
    }
  }

  Future<ChatMessage> _emitAck(io.Socket s, String event, Map payload) {
    final c = Completer<ChatMessage>();
    s.emitWithAck(event, payload, ack: (data) {
      if (c.isCompleted) return;
      final r = Map<String, dynamic>.from(data as Map);
      if (r['ok'] == true) {
        c.complete(
            ChatMessage.fromJson(Map<String, dynamic>.from(r['message'])));
      } else {
        c.completeError(
            ChatApiException((r['message'] ?? 'Send failed').toString()));
      }
    });
    return c.future.timeout(const Duration(seconds: 10));
  }

  // -------------------------------------------------------------- receipts

  void markRead(String convId) {
    final c = conversationById(convId);
    final last = messagesFor(convId).lastWhere((m) => m.seq != null,
        orElse: () => ChatMessage(
            id: '',
            seq: c?.lastMessage?.seq,
            conversationId: convId,
            senderId: null,
            type: 'text',
            body: null,
            createdAt: DateTime.now()));
    final seq = last.seq;
    if (c != null && c.unreadCount > 0) {
      c.unreadCount = 0;
      notifyListeners();
    }
    if (seq == null) return;
    final s = _socket;
    if (s != null && connected) {
      s.emit('chat:read', {'conversationId': convId, 'upToSeq': seq});
    } else {
      api.read(convId, seq).catchError((_) {});
    }
  }

  /// Tick for one of MY messages, from the other members' read positions.
  Tick tickFor(ChatMessage m) {
    if (m.seq == null) {
      return m.sendState == SendState.failed ? Tick.failed : Tick.sending;
    }
    final c = conversationById(m.conversationId);
    final others = c?.members.where((x) => x.id != meId).toList() ?? [];
    if (others.isEmpty) return Tick.sent;
    if (others.every((x) => x.lastReadSeq >= m.seq!)) return Tick.read;
    if (others.every((x) => x.lastDeliveredSeq >= m.seq!))
      return Tick.delivered;
    return Tick.sent;
  }

  // ---------------------------------------------------------------- typing

  DateTime? _lastTypingSent;
  Timer? _stopTypingTimer;

  /// Call on every text change; throttled to one event per 3 s.
  void userTyping(String convId) {
    final s = _socket;
    if (s == null || !connected) return;
    final now = DateTime.now();
    if (_lastTypingSent == null ||
        now.difference(_lastTypingSent!) > const Duration(seconds: 3)) {
      _lastTypingSent = now;
      s.emit('chat:typing', {'conversationId': convId, 'isTyping': true});
    }
    _stopTypingTimer?.cancel();
    _stopTypingTimer =
        Timer(const Duration(seconds: 4), () => stopTyping(convId));
  }

  void stopTyping(String convId) {
    _stopTypingTimer?.cancel();
    if (_lastTypingSent == null) return;
    _lastTypingSent = null;
    _socket?.emit('chat:typing', {'conversationId': convId, 'isTyping': false});
  }

  /// Names of members currently typing in a chat.
  List<String> typingIn(String convId) {
    final ids = _typing[convId]?.keys ?? const <String>[];
    final c = conversationById(convId);
    return ids
        .map((id) => c?.members
            .firstWhere((m) => m.id == id,
                orElse: () => ChatMember(id: id, firstName: '', lastName: ''))
            .firstName)
        .whereType<String>()
        .toList();
  }

  // -------------------------------------------------------------- presence

  bool isOnline(ChatUser u) => _presence[u.id]?.online ?? u.online;
  DateTime? lastSeen(ChatUser u) => _presence[u.id]?.lastSeenAt ?? u.lastSeenAt;

  // ---------------------------------------------------------- socket events

  void _onMessage(Map<String, dynamic> d) {
    final m = ChatMessage.fromJson(Map<String, dynamic>.from(d['message']));
    final known = conversationById(m.conversationId) != null;
    _upsert(m);
    if (!known) {
      refreshConversations(); // first message of a new chat
      return;
    }
    final fromMe = m.senderId == meId;
    if (!fromMe) {
      _clearTyping(m.conversationId, m.senderId ?? '');
      if (m.seq != null) {
        _socket?.emit('chat:delivered',
            {'conversationId': m.conversationId, 'upToSeq': m.seq});
      }
      if (activeConversationId == m.conversationId) markRead(m.conversationId);
    }
  }

  /// Adds a server message, replacing my local "sending" copy if it matches.
  void _upsert(ChatMessage m) {
    final list = _messages[m.conversationId];
    if (list != null) {
      final i = list.indexWhere((x) =>
          (m.seq != null && x.seq == m.seq) ||
          (m.clientMsgKey != null && x.clientMsgKey == m.clientMsgKey));
      if (i >= 0) {
        list[i] = m;
      } else {
        list.add(m);
        list.sort((a, b) => (a.seq ?? 1 << 62).compareTo(b.seq ?? 1 << 62));
      }
    }
    _bumpConversation(m.conversationId, m, fromMe: m.senderId == meId);
    notifyListeners();
  }

  // -------------------------------------------------- pin / mute / archive

  static const maxPins = 3;

  Future<void> setPinned(ChatConversation c, bool v) async =>
      _replaceConversation(await api.settings(c.id, isPinned: v));

  Future<void> setArchived(ChatConversation c, bool v) async =>
      _replaceConversation(await api.settings(c.id, isArchived: v));

  /// '8h' | '1w' | 'always' | 'off'
  Future<void> setMute(ChatConversation c, String mute) async =>
      _replaceConversation(await api.settings(c.id, mute: mute));

  /// Loads older pages until message [seq] is in memory (for "jump to").
  /// Returns false if it's too far back or not visible to me.
  Future<bool> loadUntil(String convId, int seq) async {
    var loaded = false;
    for (var i = 0; i < 40; i++) {
      final list = _messages[convId] ?? const [];
      if (list.any((m) => m.seq == seq)) {
        if (loaded) notifyListeners();
        return true;
      }
      if (!hasMore(convId) || list.isEmpty) {
        if (loaded) notifyListeners();
        return false;
      }
      loaded = true;
      final firstSeq =
          list.firstWhere((m) => m.seq != null, orElse: () => list.first).seq;
      if (firstSeq == null || firstSeq < seq) return false;
      final (older, more) =
          await api.messages(convId, beforeSeq: firstSeq, limit: 100);
      _messages[convId] = [...older, ...list];
      _hasMore[convId] = more;
    }
    notifyListeners();
    return (_messages[convId] ?? const []).any((m) => m.seq == seq);
  }

  // ---------------------------------------------------------------- groups

  /// Groups I left or was removed from (the open chat shows a notice).
  final Set<String> leftGroups = {};

  void _replaceConversation(ChatConversation c) {
    final i = conversations.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      conversations[i] = c;
    } else {
      conversations.add(c);
    }
    _sortConversations();
    notifyListeners();
  }

  /// Re-fetch one chat (renamed, new photo, members or roles changed).
  Future<ChatConversation?> reloadConversation(String id) async {
    try {
      final c = await api.conversation(id);
      leftGroups.remove(id);
      _replaceConversation(c);
      return c;
    } catch (_) {
      return null; // e.g. I'm no longer a member
    }
  }

  void _markLeft(String id) {
    leftGroups.add(id);
    conversations.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<ChatConversation> createGroup(String title, List<String> memberIds,
      {String? photoPath}) async {
    final c = await api.createGroup(title, memberIds);
    _replaceConversation(c);
    if (photoPath != null) {
      try {
        return await setGroupPhoto(c.id, photoPath);
      } catch (e) {
        debugPrint('chat: group photo failed: $e');
      }
    }
    return c;
  }

  /// Uploads a (already compressed) JPEG and makes it the group photo.
  Future<ChatConversation> setGroupPhoto(String convId, String path) async {
    final f = OutgoingMedia(
      localPath: path,
      kind: 'image',
      mimeType: 'image/jpeg',
      fileName: 'group.jpg',
      sizeBytes: await File(path).length(),
    );
    final (id, target, _) = await api.uploadInit(convId, f);
    await api.uploadFile(target, path, f.sizeBytes);
    _localFiles[id] = path;
    final c = await api.updateGroup(convId, avatarAttachmentId: id);
    _replaceConversation(c);
    return c;
  }

  Future<void> renameGroup(String convId, String title) async =>
      _replaceConversation(await api.updateGroup(convId, title: title));

  Future<void> removeGroupPhoto(String convId) async =>
      _replaceConversation(await api.updateGroup(convId, removeAvatar: true));

  Future<void> addMembers(String convId, List<String> userIds) async =>
      _replaceConversation(await api.addMembers(convId, userIds));

  Future<void> removeMember(String convId, String userId) async =>
      _replaceConversation(await api.removeMember(convId, userId));

  Future<void> setMemberRole(String convId, String userId, String role) async =>
      _replaceConversation(await api.setRole(convId, userId, role));

  Future<void> leaveGroup(String convId) async {
    await api.leaveGroup(convId);
    _markLeft(convId);
  }

  // ------------------------------------------------------- message actions

  /// Edited / deleted-for-everyone / reacted message: replace it in place.
  void _applyUpdate(ChatMessage m) {
    final list = _messages[m.conversationId];
    if (list != null) {
      final i = list.indexWhere((x) => x.seq != null && x.seq == m.seq);
      if (i >= 0) list[i] = m;
    }
    final c = conversationById(m.conversationId);
    if (c != null && c.lastMessage?.seq == m.seq) {
      c.lastMessage = ChatLastMessage.fromMessage(m);
    }
    notifyListeners();
  }

  /// "Delete for me" from this or another of my devices.
  void _onHidden(Map<String, dynamic> d) {
    final convId = (d['conversationId'] ?? '').toString();
    final seq = int.tryParse('${d['seq']}');
    _removeLocal(convId, seq);
  }

  void _removeLocal(String convId, int? seq) {
    if (seq == null) return;
    _messages[convId]?.removeWhere((x) => x.seq == seq);
    if (conversationById(convId)?.lastMessage?.seq == seq) {
      refreshConversations(); // the chat list preview changes
    }
    notifyListeners();
  }

  Future<void> editMessage(ChatMessage m, String body) async =>
      _applyUpdate(await api.edit(m.id, body));

  Future<void> deleteForMe(ChatMessage m) async {
    await api.deleteForMe(m.id);
    _removeLocal(m.conversationId, m.seq);
  }

  Future<void> deleteForEveryone(ChatMessage m) async =>
      _applyUpdate(await api.deleteForEveryone(m.id));

  /// Toggle: my same emoji again removes it.
  Future<void> react(ChatMessage m, String emoji) async =>
      _applyUpdate(await api.react(m.id, emoji));

  String? myReaction(ChatMessage m) {
    for (final r in m.reactions) {
      if (r.userId == meId) return r.emoji;
    }
    return null;
  }

  Future<void> forward(ChatMessage m, List<String> conversationIds) async {
    final sent = await api.forward(m.id, conversationIds);
    for (final x in sent) {
      _upsert(x); // the socket echo is de-duplicated by seq
    }
    if (sent.any((x) => conversationById(x.conversationId) == null)) {
      refreshConversations(); // forwarded into a chat not in my list yet
    }
  }

  void _bumpConversation(String convId, ChatMessage m, {required bool fromMe}) {
    final c = conversationById(convId);
    if (c == null) return;
    final isNewer = c.lastMessage?.seq == null ||
        m.seq == null ||
        (m.seq ?? 0) >= (c.lastMessage?.seq ?? 0);
    if (isNewer) {
      final wasSame = c.lastMessage?.seq != null && c.lastMessage?.seq == m.seq;
      c.lastMessage = ChatLastMessage.fromMessage(m);
      c.lastMessageAt = m.createdAt;
      if (!fromMe &&
          !wasSame &&
          m.seq != null &&
          activeConversationId != convId) {
        c.unreadCount++;
      }
    }
    if (fromMe && m.seq != null) {
      // my own message: I've read everything up to it
      final me = c.members.where((x) => x.id == meId);
      for (final x in me) {
        if (m.seq! > x.lastReadSeq) x.lastReadSeq = m.seq!;
        if (m.seq! > x.lastDeliveredSeq) x.lastDeliveredSeq = m.seq!;
      }
    }
    _sortConversations();
  }

  void _onReceipt(Map<String, dynamic> d) {
    final c = conversationById(d['conversationId'].toString());
    if (c == null) return;
    for (final m in c.members) {
      if (m.id == d['userId'].toString()) {
        final r = (d['readUpToSeq'] as num?)?.toInt() ?? 0;
        final del = (d['deliveredUpToSeq'] as num?)?.toInt() ?? 0;
        if (r > m.lastReadSeq) m.lastReadSeq = r;
        if (del > m.lastDeliveredSeq) m.lastDeliveredSeq = del;
      }
    }
    notifyListeners();
  }

  void _onTyping(Map<String, dynamic> d) {
    final convId = d['conversationId'].toString();
    final userId = d['userId'].toString();
    if (d['isTyping'] == true) {
      final map = _typing[convId] ??= {};
      map[userId]?.cancel();
      // auto-clear if the "stopped" event never arrives
      map[userId] =
          Timer(const Duration(seconds: 6), () => _clearTyping(convId, userId));
      notifyListeners();
    } else {
      _clearTyping(convId, userId);
    }
  }

  void _clearTyping(String convId, String userId) {
    final t = _typing[convId]?.remove(userId);
    if (t != null) {
      t.cancel();
      notifyListeners();
    }
  }

  void _onPresence(Map<String, dynamic> d) {
    _presence[d['userId'].toString()] = (
      online: d['online'] == true,
      lastSeenAt: d['lastSeenAt'] == null
          ? null
          : DateTime.tryParse(d['lastSeenAt'].toString())?.toLocal(),
    );
    notifyListeners();
  }
}
