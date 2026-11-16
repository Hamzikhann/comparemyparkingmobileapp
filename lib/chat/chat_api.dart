import 'dart:io';

import 'package:dio/dio.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/api.dart';
import 'package:parkingapp/data/api/config.dart';

class ChatApiException implements Exception {
  final String message;
  ChatApiException(this.message);
  @override
  String toString() => message;
}

/// REST calls to /api/chat/* (backend modules/chat/router.js).
/// Live traffic goes over the socket (ChatService); REST is for loading lists,
/// history, and as a fallback when the socket is down.
class ChatApi {
  final Dio _dio = API().sendRequest;

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await _dio.post(
        '/api/chat$path',
        data: body ?? {},
        options: Options(headers: {'access-token': Globals.user?.token ?? ''}),
      );
      return (res.data as Map)['data'];
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Could not reach the chat server';
      throw ChatApiException(msg);
    }
  }

  Future<List<ChatUser>> contacts() async {
    final data = await _post('/contacts') as List;
    return data
        .map((j) => ChatUser.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<ChatConversation>> conversations() async {
    final data = await _post('/conversations/list') as List;
    return data
        .map((j) => ChatConversation.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<ChatConversation> direct(String userId) async =>
      ChatConversation.fromJson(Map<String, dynamic>.from(
          await _post('/conversations/direct', {'userId': userId})));

  Future<ChatConversation> conversation(String conversationId) async =>
      ChatConversation.fromJson(Map<String, dynamic>.from(await _post(
          '/conversations/detail', {'conversationId': conversationId})));

  /// Returns (messages oldest→newest, hasMore).
  Future<(List<ChatMessage>, bool)> messages(String conversationId,
      {int? beforeSeq, int? afterSeq, int limit = 30}) async {
    final data = Map<String, dynamic>.from(await _post('/messages/list', {
      'conversationId': conversationId,
      if (beforeSeq != null) 'beforeSeq': beforeSeq,
      if (afterSeq != null) 'afterSeq': afterSeq,
      'limit': limit,
    }));
    final list = (data['messages'] as List)
        .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    return (list, data['hasMore'] == true);
  }

  Future<ChatMessage> send(Map<String, dynamic> payload) async {
    // (media messages carry 'attachmentId' + optional caption in 'body')
    final data =
        Map<String, dynamic>.from(await _post('/messages/send', payload));
    return ChatMessage.fromJson(Map<String, dynamic>.from(data['message']));
  }

  Future<void> read(String conversationId, int upToSeq) => _post(
      '/messages/read', {'conversationId': conversationId, 'upToSeq': upToSeq});

  // ------------------------------------------------------- message actions

  ChatMessage _msg(dynamic data) => ChatMessage.fromJson(
      Map<String, dynamic>.from((data as Map)['message'] as Map));

  Future<ChatMessage> edit(String messageId, String body) async => _msg(
      await _post('/messages/edit', {'messageId': messageId, 'body': body}));

  Future<void> deleteForMe(String messageId) =>
      _post('/messages/delete', {'messageId': messageId, 'forEveryone': false});

  Future<ChatMessage> deleteForEveryone(String messageId) async =>
      _msg(await _post(
          '/messages/delete', {'messageId': messageId, 'forEveryone': true}));

  /// Same emoji again (or '') removes my reaction.
  Future<ChatMessage> react(String messageId, String emoji) async => _msg(
      await _post('/messages/react', {'messageId': messageId, 'emoji': emoji}));

  Future<List<ChatMessage>> forward(
      String messageId, List<String> conversationIds) async {
    final data = Map<String, dynamic>.from(await _post('/messages/forward',
        {'messageId': messageId, 'conversationIds': conversationIds}));
    return (data['messages'] as List)
        .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  /// Who read / received my message: (readBy, deliveredTo, pending).
  Future<(List<ChatUser>, List<ChatUser>, List<ChatUser>)> messageInfo(
      String messageId) async {
    final d = Map<String, dynamic>.from(
        await _post('/messages/info', {'messageId': messageId}));
    List<ChatUser> users(String k) => ((d[k] as List?) ?? [])
        .map((j) => ChatUser.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    return (users('readBy'), users('deliveredTo'), users('pending'));
  }

  // -------------------------------------------------------------- phase 7a

  /// mute: '8h' | '1w' | 'always' | 'off'
  Future<ChatConversation> settings(String conversationId,
          {bool? isPinned, bool? isArchived, String? mute}) async =>
      _conv(await _post('/conversations/settings', {
        'conversationId': conversationId,
        if (isPinned != null) 'isPinned': isPinned,
        if (isArchived != null) 'isArchived': isArchived,
        if (mute != null) 'mute': mute,
      }));

  /// Text search in one chat: [{seq, id, senderId, type, text, createdAt}]
  Future<List<Map<String, dynamic>>> search(
      String conversationId, String q) async {
    final d = Map<String, dynamic>.from(await _post(
        '/messages/search', {'conversationId': conversationId, 'q': q}));
    return ((d['results'] as List?) ?? [])
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  /// kind: 'media' (photos/videos) or 'docs' (documents/voice notes)
  Future<(List<ChatMessage>, bool)> sharedMedia(
      String conversationId, String kind,
      {int? beforeSeq}) async {
    final d = Map<String, dynamic>.from(await _post('/conversations/media', {
      'conversationId': conversationId,
      'kind': kind,
      if (beforeSeq != null) 'beforeSeq': beforeSeq,
    }));
    return (
      (d['messages'] as List)
          .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
          .toList(),
      d['hasMore'] == true
    );
  }

  Future<Map<String, dynamic>> contactInfo(String userId) async =>
      Map<String, dynamic>.from(
          await _post('/contacts/info', {'userId': userId}));

  /// Administrators: every group [{id, title, avatarAttachmentId, memberCount, isMember}]
  Future<List<Map<String, dynamic>>> allGroups() async =>
      ((await _post('/groups/all')) as List)
          .map((g) => Map<String, dynamic>.from(g))
          .toList();

  Future<ChatConversation> adminJoin(String conversationId) async => _conv(
      await _post('/groups/admin-join', {'conversationId': conversationId}));

  // ---------------------------------------------------------------- groups

  ChatConversation _conv(dynamic d) =>
      ChatConversation.fromJson(Map<String, dynamic>.from(d as Map));

  Future<ChatConversation> createGroup(
          String title, List<String> memberIds) async =>
      _conv(await _post(
          '/groups/create', {'title': title, 'memberIds': memberIds}));

  Future<ChatConversation> updateGroup(String conversationId,
          {String? title,
          String? avatarAttachmentId,
          bool removeAvatar = false}) async =>
      _conv(await _post('/groups/update', {
        'conversationId': conversationId,
        if (title != null) 'title': title,
        if (avatarAttachmentId != null)
          'avatarAttachmentId': avatarAttachmentId,
        if (removeAvatar) 'removeAvatar': true,
      }));

  Future<ChatConversation> addMembers(
          String conversationId, List<String> userIds) async =>
      _conv(await _post('/groups/members/add',
          {'conversationId': conversationId, 'userIds': userIds}));

  Future<ChatConversation> removeMember(
          String conversationId, String userId) async =>
      _conv(await _post('/groups/members/remove',
          {'conversationId': conversationId, 'userId': userId}));

  Future<ChatConversation> setRole(
          String conversationId, String userId, String role) async =>
      _conv(await _post('/groups/members/role',
          {'conversationId': conversationId, 'userId': userId, 'role': role}));

  Future<void> leaveGroup(String conversationId) =>
      _post('/groups/leave', {'conversationId': conversationId});

  // ----------------------------------------------------------------- media

  /// Login header for media downloads (images, video, voice, files).
  static Map<String, String> get authHeaders =>
      {'access-token': Globals.user?.token ?? ''};

  // Plain Dio for file bytes: no JSON logging of big bodies
  static final Dio _files = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(minutes: 10),
    sendTimeout: const Duration(minutes: 10),
  ));

  /// Step 1: reserve the upload. Returns the attachment id + where to PUT.
  /// Returns (attachment id, file target, thumbnail target or null).
  Future<(String, Map<String, dynamic>, Map<String, dynamic>?)> uploadInit(
      String conversationId, OutgoingMedia f) async {
    final data = Map<String, dynamic>.from(await _post('/upload/init', {
      'conversationId': conversationId,
      'kind': f.kind,
      'mimeType': f.mimeType,
      'sizeBytes': f.sizeBytes,
      'fileName': f.fileName,
      if (f.durationMs != null) 'durationMs': f.durationMs,
      if (f.width != null) 'width': f.width,
      if (f.height != null) 'height': f.height,
      if (f.thumbPath != null) 'thumbSizeBytes': f.thumbSizeBytes,
    }));
    return (
      data['attachmentId'].toString(),
      Map<String, dynamic>.from(data['upload'] as Map),
      data['thumbUpload'] is Map
          ? Map<String, dynamic>.from(data['thumbUpload'] as Map)
          : null,
    );
  }

  /// Step 2: PUT a file. [target] is either {url, headers} (DigitalOcean
  /// Spaces, signed) or {path, headers} (our own server, needs the login).
  Future<void> uploadFile(Map<String, dynamic> target, String path, int size,
      {void Function(double)? onProgress, CancelToken? cancelToken}) async {
    final signedUrl = target['url']?.toString();
    final url = signedUrl ?? '${AppConfig.baseUrl}/api/chat${target['path']}';
    final headers = <String, dynamic>{
      ...Map<String, dynamic>.from((target['headers'] as Map?) ?? {}),
      Headers.contentLengthHeader: size,
      if (signedUrl == null) ...authHeaders,
    };
    try {
      await _files.put(
        url,
        data: File(path).openRead(),
        options: Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (onProgress != null && size > 0) {
            onProgress((sent / size).clamp(0, 1));
          }
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final data = e.response?.data;
      throw ChatApiException(data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Upload failed. Check your connection and try again.');
    }
  }

  /// Downloads a chat file to [savePath] (follows the Spaces redirect).
  Future<void> download(ChatAttachment a, String savePath,
      {void Function(double)? onProgress, CancelToken? cancelToken}) async {
    final tmp = '$savePath.part';
    await _files.download(
      a.url,
      tmp,
      options: Options(headers: authHeaders),
      cancelToken: cancelToken,
      onReceiveProgress: (got, total) {
        final t = total > 0 ? total : a.sizeBytes;
        if (onProgress != null && t > 0) onProgress((got / t).clamp(0, 1));
      },
    );
    await File(tmp).rename(savePath);
  }
}
