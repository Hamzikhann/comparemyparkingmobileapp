import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/bot_report_sheet.dart';
import 'package:parkingapp/chat/ui/chat_media.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/chat/ui/forward_picker.dart';
import 'package:parkingapp/chat/ui/group_screens.dart';
import 'package:parkingapp/chat/ui/info_screens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// One conversation: messages, ticks, typing, reply, emoji, location.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chat = ChatService.instance;
  final _input = TextEditingController();
  final _scroll = AutoScrollController(); // can scroll to a message (jump to)
  final _focus = FocusNode();
  ChatConversation? _convCache;
  // Always the latest copy (group renamed, members changed...)
  ChatConversation? get _conv => _chat.conversationById(_id) ?? _convCache;
  String? _error;
  ChatMessage? _replyTo;
  ChatMessage? _editing; // my message being edited in the input box
  bool _showEmoji = false;
  bool _loadingOlder = false;

  String get _id => widget.conversationId;

  @override
  void initState() {
    super.initState();
    _chat.start();
    _chat.activeConversationId = _id;
    _scroll.addListener(_onScroll);
    _input.addListener(() => setState(() {})); // send button state
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmoji) setState(() => _showEmoji = false);
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _chat.ensureConversation(_id);
      if (!mounted) return;
      setState(() => _convCache = c);
      await _chat.loadLatest(_id);
      _chat.markRead(_id);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    if (_recording) _recorder.stop();
    _recorder.dispose();
    _chat.stopTyping(_id);
    if (_chat.activeConversationId == _id) _chat.activeConversationId = null;
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // List is reversed: the "end" is the oldest message
  void _onScroll() {
    if (_loadingOlder || !_chat.hasMore(_id)) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _loadingOlder = true;
      _chat.loadOlder(_id).whenComplete(() => _loadingOlder = false);
    }
  }

  void _send() {
    final text = _input.text;
    final editing = _editing;
    if (editing != null) {
      // Saving an edit (an empty caption is allowed, empty text is not)
      if (editing.type == 'text' && text.trim().isEmpty) return;
      setState(() => _editing = null);
      _input.clear();
      _chat
          .editMessage(editing, text.trim())
          .catchError((e) => _snack(e.toString()));
      return;
    }
    if (text.trim().isEmpty) return;
    _chat.sendText(_id, text, replyTo: _replyTo);
    _chat.stopTyping(_id);
    _input.clear();
    setState(() => _replyTo = null);
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _shareLocation() async {
    Navigator.pop(context); // close attach sheet
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Please turn on location services');
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied)
        p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        _snack('Location permission is needed to share your location');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20));
      _chat.sendLocation(_id, pos.latitude, pos.longitude);
    } catch (_) {
      _snack('Could not get your location');
    }
  }

  // ------------------------------------------------------------- media

  static const _mb = 1024 * 1024;
  static const _maxPick = 5; // photos/videos/documents per send
  final _picker = ImagePicker();

  void _sendFile(OutgoingMedia f, {String? caption}) {
    _chat.sendMedia(_id, f, caption: caption, replyTo: _replyTo);
    setState(() => _replyTo = null);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<String> _tempPath(String ext) async =>
      '${(await getTemporaryDirectory()).path}/chat_${DateTime.now().microsecondsSinceEpoch}.$ext';

  bool _isVideoPath(String p) => mimeForPath(p).startsWith('video/');

  /// Camera: take a photo or record a video, then preview + send.
  Future<void> _openCamera() async {
    Navigator.pop(context); // close attach sheet
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(s, 'photo'),
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Record video'),
            onTap: () => Navigator.pop(s, 'video'),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    try {
      final x = choice == 'photo'
          ? await _picker.pickImage(source: ImageSource.camera)
          : await _picker.pickVideo(source: ImageSource.camera);
      if (x == null) return;
      await _previewAndSend([x.path], forceVideo: choice == 'video');
    } catch (e) {
      debugPrint('chat: camera failed: $e');
      _snack('Could not open the camera');
    }
  }

  /// Gallery: up to 5 photos and/or videos.
  Future<void> _openGallery() async {
    Navigator.pop(context);
    try {
      final picked = await _picker.pickMultipleMedia(limit: _maxPick);
      if (picked.isEmpty) return;
      var paths = picked.map((x) => x.path).toList();
      if (paths.length > _maxPick) {
        paths = paths.sublist(0, _maxPick);
        _snack(
            'You can send up to $_maxPick at a time. Sending the first $_maxPick.');
      }
      await _previewAndSend(paths);
    } catch (e) {
      debugPrint('chat: gallery failed: $e');
      _snack('Could not open the gallery');
    }
  }

  Future<void> _previewAndSend(List<String> paths,
      {bool forceVideo = false}) async {
    final items = <PreviewItem>[];
    for (final p in paths) {
      final isVideo = forceVideo || _isVideoPath(p);
      final size = await File(p).length();
      if (isVideo && size > 100 * _mb) {
        _snack('Videos can be at most 100 MB (one was skipped)');
        continue;
      }
      items.add(PreviewItem(
          path: p,
          isVideo: isVideo,
          thumbPath: isVideo ? await _videoThumb(p) : null));
    }
    if (items.isEmpty || !mounted) return;
    final chosen = await Navigator.of(context).push<List<PreviewItem>>(
        MaterialPageRoute(
            builder: (_) => ChatMediaPreview(
                items: items, title: _conv?.displayName(_chat.meId))));
    if (chosen == null) return;
    for (final it in chosen) {
      final f =
          it.isVideo ? await _prepareVideo(it) : await _prepareImage(it.path);
      if (f != null) _sendFile(f, caption: it.caption);
    }
  }

  /// First frame of a video as a small JPEG (shown in the chat bubble).
  Future<String?> _videoThumb(String path) async {
    try {
      return await VideoThumbnail.thumbnailFile(
          video: path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 480,
          quality: 70);
    } catch (e) {
      debugPrint('chat: thumbnail failed: $e');
      return null;
    }
  }

  Future<OutgoingMedia?> _prepareImage(String original) async {
    try {
      // Shrink before upload (saves data; keeps good quality)
      final out = await FlutterImageCompress.compressAndGetFile(
          original, await _tempPath('jpg'),
          minWidth: 1600, minHeight: 1600, quality: 80);
      final path = out?.path ?? original;
      final file = File(path);
      final size = await file.length();
      if (size > 20 * _mb) {
        _snack('Photos can be at most 20 MB (one was skipped)');
        return null;
      }
      final img = await decodeImageFromList(await file.readAsBytes());
      return OutgoingMedia(
        localPath: path,
        kind: 'image',
        mimeType: out != null ? 'image/jpeg' : mimeForPath(path),
        fileName: 'photo.jpg',
        sizeBytes: size,
        width: img.width,
        height: img.height,
      );
    } catch (e) {
      debugPrint('chat: photo prepare failed: $e');
      _snack('Could not use one of the photos');
      return null;
    }
  }

  Future<OutgoingMedia?> _prepareVideo(PreviewItem it) async {
    try {
      final file = File(it.path);
      final size = await file.length();
      int? durMs, w, h, thumbSize;
      final probe = VideoPlayerController.file(file);
      try {
        await probe.initialize();
        durMs = probe.value.duration.inMilliseconds;
        w = probe.value.size.width.round();
        h = probe.value.size.height.round();
      } catch (_) {
      } finally {
        probe.dispose();
      }
      if (it.thumbPath != null) {
        // The frame is already rotated correctly: trust its shape
        final bytes = await File(it.thumbPath!).readAsBytes();
        thumbSize = bytes.length;
        final img = await decodeImageFromList(bytes);
        w = img.width;
        h = img.height;
      }
      final mime = mimeForPath(it.path);
      return OutgoingMedia(
        localPath: it.path,
        kind: 'video',
        mimeType: mime.startsWith('video/') ? mime : 'video/mp4',
        fileName: it.path.split(RegExp(r'[\\/]')).last,
        sizeBytes: size,
        durationMs: durMs,
        width: w,
        height: h,
        thumbPath: it.thumbPath,
        thumbSizeBytes: thumbSize,
      );
    } catch (e) {
      debugPrint('chat: video prepare failed: $e');
      _snack('Could not use one of the videos');
      return null;
    }
  }

  Future<void> _pickDocument() async {
    Navigator.pop(context);
    try {
      final r = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (r == null || r.files.isEmpty) return;
      var files = r.files.where((f) => f.path != null).toList();
      if (files.length > _maxPick) {
        files = files.sublist(0, _maxPick);
        _snack(
            'You can send up to $_maxPick files at a time. Sending the first $_maxPick.');
      }
      final tooBig = files.where((f) => f.size > 100 * _mb).length;
      files = files.where((f) => f.size <= 100 * _mb).toList();
      if (tooBig > 0) _snack('Files can be at most 100 MB ($tooBig skipped)');
      if (files.isEmpty || !mounted) return;
      final who = _conv?.displayName(_chat.meId) ?? 'this chat';
      final what = files.length == 1 ? 'this file' : '${files.length} files';
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Send $what to $who?', style: TextStyle(fontSize: 16.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in files)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Row(children: [
                    Icon(Icons.insert_drive_file,
                        size: 18.sp, color: colors.primaryNew),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text('${f.name} · ${formatBytes(f.size)}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Send')),
          ],
        ),
      );
      if (ok != true) return;
      for (final f in files) {
        _sendFile(OutgoingMedia(
          localPath: f.path!,
          kind: 'file',
          mimeType: mimeForPath(f.name),
          fileName: f.name,
          sizeBytes: f.size,
        ));
      }
    } catch (e) {
      debugPrint('chat: file pick failed: $e');
      _snack('Could not use this file');
    }
  }

  // ------------------------------------------------------------ voice notes
  // Tap the mic: records hands-free with delete / pause / send buttons.
  // Hold the mic: records while held, release sends, slide left cancels.

  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _recLocked = false; // tap mode (hands-free)
  bool _recPaused = false;
  bool _recCancel = false; // hold mode: slid left
  Future<bool>? _recStarting;
  final _recWatch = Stopwatch();
  Duration _recElapsed = Duration.zero;
  Timer? _recTimer;
  String? _recPath;
  static const _maxVoice = Duration(minutes: 15);

  Future<bool> _startRecording({required bool locked}) async {
    if (_recording) return false;
    // First time: the permission dialog interrupts, so just ask
    if (!await _recorder.hasPermission()) {
      _snack('Microphone permission is needed for voice notes');
      return false;
    }
    _recPath = await _tempPath('m4a');
    await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 44100,
            numChannels: 1),
        path: _recPath!);
    HapticFeedback.mediumImpact();
    _recWatch
      ..reset()
      ..start();
    setState(() {
      _recording = true;
      _recLocked = locked;
      _recPaused = false;
      _recCancel = false;
      _recElapsed = Duration.zero;
    });
    _recTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() => _recElapsed = _recWatch.elapsed);
      if (_recElapsed >= _maxVoice) _stopRecording(send: true);
    });
    return true;
  }

  Future<void> _togglePause() async {
    if (!_recording) return;
    if (_recPaused) {
      await _recorder.resume();
      _recWatch.start();
    } else {
      await _recorder.pause();
      _recWatch.stop();
    }
    setState(() => _recPaused = !_recPaused);
  }

  Future<void> _stopRecording({required bool send}) async {
    final started = await (_recStarting ?? Future.value(false));
    _recStarting = null;
    if (!started || !_recording) return;
    _recTimer?.cancel();
    _recWatch.stop();
    final elapsed = _recWatch.elapsed;
    final cancelled = _recCancel;
    final path = await _recorder.stop() ?? _recPath;
    if (mounted) {
      setState(() {
        _recording = false;
        _recLocked = false;
        _recPaused = false;
      });
    }
    if (path == null) return;
    final file = File(path);
    if (!send || cancelled || elapsed < const Duration(seconds: 1)) {
      if (await file.exists()) await file.delete();
      if (send && !cancelled) {
        _snack('Too short. Tap or hold the mic to record.');
      }
      return;
    }
    _sendFile(OutgoingMedia(
      localPath: path,
      kind: 'audio',
      mimeType: 'audio/mp4',
      fileName: 'voice-note.m4a',
      sizeBytes: await file.length(),
      durationMs: elapsed.inMilliseconds.clamp(0, _maxVoice.inMilliseconds),
    ));
  }

  Widget _recordingBar() {
    final hint = _recLocked
        ? (_recPaused ? 'Paused' : 'Recording…')
        : (_recCancel ? 'Release to cancel' : '‹  Slide to cancel');
    return Expanded(
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: ChatColors.background,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(children: [
          if (_recLocked)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _stopRecording(send: false),
            )
          else
            SizedBox(width: 8.w),
          Icon(Icons.fiber_manual_record,
              color: _recPaused ? ChatColors.muted : Colors.red, size: 14.sp),
          SizedBox(width: 6.w),
          Text(formatDuration(_recElapsed),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: _recCancel ? Colors.red : ChatColors.muted)),
          ),
          if (_recLocked)
            IconButton(
              tooltip: _recPaused ? 'Resume' : 'Pause',
              icon: Icon(_recPaused ? Icons.mic : Icons.pause,
                  color: _recPaused ? Colors.red : colors.primaryNew),
              onPressed: _togglePause,
            ),
        ]),
      ),
    );
  }

  Widget _micButton() {
    // Tap mode: the mic becomes a send button
    if (_recording && _recLocked) {
      return GestureDetector(
        onTap: () => _stopRecording(send: true),
        child: CircleAvatar(
          radius: 22.r,
          backgroundColor: colors.primaryNew,
          child: const Icon(Icons.send, color: Colors.white, size: 20),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _recStarting = _startRecording(locked: true),
      onLongPressStart: (_) => _recStarting = _startRecording(locked: false),
      onLongPressMoveUpdate: (d) {
        final cancel = d.offsetFromOrigin.dx < -90;
        if (cancel != _recCancel && _recording) {
          if (cancel) HapticFeedback.selectionClick();
          setState(() => _recCancel = cancel);
        }
      },
      onLongPressEnd: (_) => _stopRecording(send: true),
      child: CircleAvatar(
        radius: _recording ? 28.r : 22.r,
        backgroundColor: _recording ? Colors.red : colors.primaryNew,
        child: const Icon(Icons.mic, color: Colors.white, size: 22),
      ),
    );
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showEmoji,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showEmoji) setState(() => _showEmoji = false);
      },
      child: Scaffold(
        backgroundColor: ChatColors.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _chat,
            builder: (context, _) => Column(
              children: [
                _header(),
                Expanded(child: _body()),
                if (_editing != null)
                  _editBar()
                else if (_replyTo != null)
                  _replyBar(),
                if (_chat.leftGroups.contains(_id))
                  _notMemberBar()
                else ...[
                  if (_conv?.isBotChat(_chat.meId) == true)
                    BotReportBar(api: _chat.api),
                  _inputBar(),
                  if (_showEmoji) _emojiPicker(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final me = _chat.meId;
    final c = _conv;
    final other = c?.other(me);
    final typing = _chat.typingIn(_id);
    final sub = typing.isNotEmpty
        ? (c?.isGroup == true ? '${typing.join(', ')} typing…' : 'typing…')
        : (c == null
            ? ''
            : c.isGroup
                ? _memberNames(c)
                : c.isBotChat(me)
                    ? 'Booking reports'
                    : (other == null ? '' : presenceText(other)));
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context)),
            if (c != null)
              GestureDetector(
                  onTap: _openInfo, child: ConversationAvatar(c, radius: 20))
            else
              ChatAvatar(radius: 20),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openInfo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c?.displayName(me) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Archivo',
                            color: const Color(0xFF1A1A2E))),
                    if (sub.isNotEmpty)
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: typing.isNotEmpty
                                  ? colors.secondarynew
                                  : ChatColors.muted)),
                  ],
                ),
              ),
            ),
            IconButton(
                tooltip: 'Search',
                icon: Icon(Icons.search, color: ChatColors.muted),
                onPressed: _openSearch),
            if (!_chat.connected)
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Tooltip(
                  message: 'Connecting…',
                  child: Icon(Icons.cloud_off, size: 20.sp, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
          child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(_error!, textAlign: TextAlign.center)));
    }
    if (!_chat.isLoaded(_id)) {
      return const Center(
          child: CircularProgressIndicator(color: colors.primaryNew));
    }
    final msgs = _chat.messagesFor(_id);
    if (msgs.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
          child: Text('Say hello 👋',
              style: TextStyle(color: ChatColors.muted, fontSize: 14.sp)),
        ),
      );
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        itemCount: msgs.length + (_chat.hasMore(_id) ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == msgs.length) {
            return Padding(
              padding: EdgeInsets.all(12.w),
              child: const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final idx = msgs.length - 1 - i; // reversed
          final m = msgs[idx];
          final prev = idx > 0 ? msgs[idx - 1] : null;
          final newDay = prev == null || !_sameDay(prev.createdAt, m.createdAt);
          final grouped = prev != null &&
              !newDay &&
              prev.senderId == m.senderId &&
              prev.type != 'system';
          return AutoScrollTag(
            key: ValueKey('tag-$i'),
            controller: _scroll,
            index: i,
            highlightColor: colors.primaryNew.withOpacity(0.18),
            child: Column(
              children: [
                if (newDay) _dayChip(m.createdAt),
                m.type == 'system'
                    ? _systemLine(m)
                    : _bubble(m, grouped: grouped),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dayChip(DateTime t) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2)
            ],
          ),
          child: Text(chatDayLabel(t),
              style: TextStyle(fontSize: 12.sp, color: ChatColors.muted)),
        ),
      );

  Widget _bubble(ChatMessage m, {required bool grouped}) {
    final me = _chat.meId;
    final mine = m.senderId == me;
    final c = _conv;
    final senderName = c?.isGroup == true && !mine
        ? c!.members
            .firstWhere((x) => x.id == m.senderId,
                orElse: () => ChatMember(id: '', firstName: '', lastName: ''))
            .name
        : null;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: 0.78.sw),
      margin: EdgeInsets.only(top: grouped ? 2.h : 6.h),
      padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 5.h),
      decoration: BoxDecoration(
        color: mine ? ChatColors.myBubble : ChatColors.theirBubble,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(mine || grouped ? 12.r : 2.r),
          topRight: Radius.circular(!mine || grouped ? 12.r : 2.r),
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (senderName != null && senderName.isNotEmpty && !grouped)
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(senderName,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryNew)),
            ),
          if (m.isForwarded)
            Text('Forwarded',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: ChatColors.muted)),
          if (m.replyTo != null)
            GestureDetector(
              onTap: m.replyTo!.seq == null
                  ? null
                  : () => _jumpTo(m.replyTo!.seq!),
              child: _quote(m.replyTo!),
            ),
          _content(m),
          SizedBox(height: 2.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.isEdited)
                Text('edited  ',
                    style: TextStyle(fontSize: 10.sp, color: ChatColors.muted)),
              Text(DateFormat('h:mm a').format(m.createdAt),
                  style: TextStyle(fontSize: 10.sp, color: ChatColors.muted)),
              if (mine) ...[
                SizedBox(width: 3.w),
                TickIcon(_chat.tickFor(m), size: 15),
              ],
            ],
          ),
        ],
      ),
    );

    // Swipe right to reply (WhatsApp gesture); long-press for actions
    return Dismissible(
      key: ValueKey(m.clientMsgKey ?? m.id),
      direction: m.isDeleted || m.seq == null
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.selectionClick();
        setState(() => _replyTo = m);
        _focus.requestFocus();
        return false;
      },
      background: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Icon(Icons.reply, color: ChatColors.muted, size: 22.sp),
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _actions(m),
        onTap: m.sendState == SendState.failed ? () => _chat.retry(m) : null,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: _withReactions(m, bubble, mine: mine),
        ),
      ),
    );
  }

  Widget _quote(ChatReplyPreview r) {
    final me = _chat.meId;
    final who = r.senderId == me
        ? 'You'
        : (_conv?.members
                .firstWhere((x) => x.id == r.senderId,
                    orElse: () =>
                        ChatMember(id: '', firstName: '', lastName: ''))
                .firstName ??
            '');
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.r),
        border: Border(left: BorderSide(color: colors.primaryNew, width: 3.w)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(who,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryNew)),
          Text(r.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: ChatColors.muted)),
        ],
      ),
    );
  }

  Widget _content(ChatMessage m) {
    if (m.isDeleted) {
      return Text('🚫 This message was deleted',
          style: TextStyle(
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
              color: ChatColors.muted));
    }
    if (m.isMedia && m.attachment != null) {
      final Widget media = switch (m.type) {
        'image' => ChatImageBubble(m),
        'video' => ChatVideoBubble(m),
        'audio' => ChatVoiceBubble(m),
        _ => ChatFileBubble(m),
      };
      final cap = m.caption;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          media,
          if (cap != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: SizedBox(
                width: 230.w,
                child: LinkText(cap,
                    style: TextStyle(
                        fontSize: 15.sp, color: const Color(0xFF1A1A2E))),
              ),
            ),
        ],
      );
    }
    final loc = m.location;
    if (loc != null) {
      return InkWell(
        onTap: () => launchUrl(
            Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}'),
            mode: LaunchMode.externalApplication),
        child: Container(
          width: 220.w,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: colors.primaryNew.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 30.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.label ?? 'Shared location',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.sp)),
                    Text('Tap to open in Maps',
                        style: TextStyle(
                            fontSize: 12.sp, color: colors.primaryNew)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return LinkText(m.body ?? '',
        style: TextStyle(fontSize: 15.sp, color: const Color(0xFF1A1A2E)));
  }

  // -------------------------------------------------------- actions (5b)

  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  /// Bubble + WhatsApp-style reaction pill hanging off its bottom edge
  /// (right side for my messages, left for theirs).
  Widget _withReactions(ChatMessage m, Widget bubble, {required bool mine}) {
    if (m.reactions.isEmpty) return bubble;
    final counts = m.reactionCounts;
    final total = m.reactions.length;
    final pill = GestureDetector(
      onTap: () => _showReactions(m),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ChatColors.background, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(counts.keys.take(3).join(), style: TextStyle(fontSize: 13.sp)),
          if (total > 1) ...[
            SizedBox(width: 3.w),
            Text('$total',
                style: TextStyle(fontSize: 11.sp, color: ChatColors.muted)),
          ],
        ]),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Stack(clipBehavior: Clip.none, children: [
        bubble,
        Positioned(
          bottom: -18.h,
          right: mine ? 10.w : null,
          left: mine ? null : 10.w,
          child: pill,
        ),
      ]),
    );
  }

  /// Who reacted with what; tap my own row to remove it.
  void _showReactions(ChatMessage m) {
    final me = _chat.meId;
    final rows = [...m.reactions]
      ..sort((a, b) => (a.userId == me ? 0 : 1) - (b.userId == me ? 0 : 1));
    String nameOf(String id) {
      if (id == me) return 'You';
      final u = _conv?.members.where((x) => x.id == id);
      return (u != null && u.isNotEmpty) ? u.first.name : 'Someone';
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: EdgeInsets.all(12.h),
            child: Text('Reactions',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
          ),
          for (final r in rows)
            ListTile(
              leading: ChatAvatar(
                  user: r.userId == me
                      ? null
                      : _conv?.members
                          .where((x) => x.id == r.userId)
                          .firstOrNull,
                  fallbackText: r.userId == me ? 'Me' : null,
                  radius: 18),
              title: Text(nameOf(r.userId)),
              subtitle: r.userId == me ? const Text('Tap to remove') : null,
              trailing: Text(r.emoji, style: TextStyle(fontSize: 22.sp)),
              onTap: r.userId == me
                  ? () {
                      Navigator.pop(sheet);
                      _react(m, r.emoji);
                    }
                  : null,
            ),
        ]),
      ),
    );
  }

  void _react(ChatMessage m, String emoji) {
    HapticFeedback.selectionClick();
    _chat.react(m, emoji).catchError((e) => _snack(e.toString()));
  }

  // ------------------------------------------------------------ groups (6)

  Future<void> _openInfo() async {
    final c = _conv;
    if (c == null) return;
    if (!c.isGroup) {
      final other = c.other(_chat.meId);
      // The Reports Bot has no contact page
      if (other == null || c.isBotChat(_chat.meId)) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ContactInfoScreen(conversationId: c.id, user: other)));
      return;
    }
    if (_chat.leftGroups.contains(_id)) return;
    final r = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => GroupInfoScreen(conversationId: c.id)));
    if (r == 'left' && mounted) Navigator.of(context).maybePop();
  }

  /// Scrolls to a message (reply quote / search result) and flashes it.
  /// Older pages are loaded first if needed.
  Future<void> _jumpTo(int seq) async {
    final found = await _chat.loadUntil(_id, seq);
    if (!mounted) return;
    final msgs = _chat.messagesFor(_id);
    final idx = msgs.indexWhere((m) => m.seq == seq);
    if (!found || idx < 0) {
      _snack('That message is no longer available');
      return;
    }
    final i = msgs.length - 1 - idx; // list is reversed
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _scroll.scrollToIndex(i,
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 300));
    _scroll.highlight(i, highlightDuration: const Duration(milliseconds: 1200));
  }

  Future<void> _openSearch() async {
    final c = _conv;
    if (c == null) return;
    final seq = await Navigator.of(context).push<int>(
        MaterialPageRoute(builder: (_) => ChatSearchScreen(conversation: c)));
    if (seq != null) _jumpTo(seq);
  }

  /// Header subtitle for groups: "You, Sara, Ali…"
  String _memberNames(ChatConversation c) {
    final me = _chat.meId;
    final others = c.members.where((m) => m.id != me).map((m) => m.firstName);
    final names = [
      if (c.members.any((m) => m.id == me)) 'You',
      ...others,
    ];
    return names.join(', ');
  }

  Widget _systemLine(ChatMessage m) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.8.sw),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D6),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(m.body ?? '',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12.sp, color: const Color(0xFF5B5B5B))),
        ),
      ),
    );
  }

  Widget _notMemberBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Text(
          "You can't send messages to this group because you're no longer a member.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: ChatColors.muted)),
    );
  }

  /// Message info: read by / delivered to / not yet received.
  Future<void> _messageInfo(ChatMessage m) async {
    try {
      final (read, delivered, pending) = await _chat.api.messageInfo(m.id);
      if (!mounted) return;
      Widget section(
              String title, IconData icon, Color color, List<ChatUser> us) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
              child: Row(children: [
                Icon(icon, size: 18.sp, color: color),
                SizedBox(width: 6.w),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: ChatColors.muted)),
              ]),
            ),
            for (final u in us)
              ListTile(
                  dense: true,
                  leading: ChatAvatar(user: u, radius: 18),
                  title: Text(u.name)),
          ]);
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
        builder: (_) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 0.7.sh),
            child: ListView(shrinkWrap: true, children: [
              Padding(
                padding: EdgeInsets.all(12.h),
                child: Center(
                  child: Text('Message info',
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w700)),
                ),
              ),
              if (read.isNotEmpty)
                section(
                    'Read by', Icons.done_all, const Color(0xFF34B7F1), read),
              if (delivered.isNotEmpty)
                section('Delivered to', Icons.done_all, ChatColors.muted,
                    delivered),
              if (pending.isNotEmpty)
                section(
                    'Not received yet', Icons.done, ChatColors.muted, pending),
              SizedBox(height: 12.h),
            ]),
          ),
        ),
      );
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _startEdit(ChatMessage m) {
    setState(() {
      _editing = m;
      _replyTo = null;
      _showEmoji = false;
    });
    _input.text = m.type == 'text' ? (m.body ?? '') : (m.caption ?? '');
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    _focus.requestFocus();
  }

  Future<void> _confirmDelete(ChatMessage m) async {
    final mine = m.senderId == _chat.meId;
    final forAll = mine && m.canDeleteForEveryoneNow;
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete message?'),
        content: mine && !forAll
            ? Text('Messages can only be deleted for everyone within 1 hour.',
                style: TextStyle(fontSize: 13.sp, color: ChatColors.muted))
            : null,
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, 'me'),
              child: const Text('Delete for me')),
          if (forAll)
            TextButton(
                onPressed: () => Navigator.pop(d, 'all'),
                child: const Text('Delete for everyone',
                    style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (choice == null) return;
    try {
      if (choice == 'all') {
        await _chat.deleteForEveryone(m);
      } else {
        await _chat.deleteForMe(m);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _forward(ChatMessage m) async {
    final picked = await Navigator.of(context).push<List<String>>(
        MaterialPageRoute(builder: (_) => const ForwardPicker()));
    if (picked == null || picked.isEmpty) return;
    try {
      await _chat.forward(m, picked);
      _snack(picked.length == 1
          ? 'Forwarded'
          : 'Forwarded to ${picked.length} chats');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _actions(ChatMessage m) async {
    HapticFeedback.mediumImpact();
    final mine = m.senderId == _chat.meId;
    final sent = m.isSent;
    // Deleted messages: only "delete for me" is left
    if (m.isDeleted) {
      if (sent) await _confirmDelete(m);
      return;
    }
    final myEmoji = _chat.myReaction(m);
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sent)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final e in _quickReactions)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(sheet);
                          _react(m, e);
                        },
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: e == myEmoji
                                ? colors.primaryNew.withOpacity(0.15)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(e, style: TextStyle(fontSize: 26.sp)),
                        ),
                      ),
                  ],
                ),
              ),
            if (sent) const Divider(height: 1),
            if (sent && mine && m.canEditNow)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(m.type == 'text' ? 'Edit' : 'Edit caption'),
                onTap: () {
                  Navigator.pop(sheet);
                  _startEdit(m);
                },
              ),
            if (sent && mine)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Info'),
                onTap: () {
                  Navigator.pop(sheet);
                  _messageInfo(m);
                },
              ),
            if (sent && m.type != 'system')
              ListTile(
                leading: const Icon(Icons.shortcut),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(sheet);
                  _forward(m);
                },
              ),
            if (sent)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheet);
                  _confirmDelete(m);
                },
              ),
            if (m.seq != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => _replyTo = m);
                  _focus.requestFocus();
                },
              ),
            if (m.outgoing != null && m.seq == null)
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel sending'),
                onTap: () {
                  Navigator.pop(sheet);
                  _chat.cancelMedia(m);
                },
              ),
            if (m.type == 'text' || m.caption != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(m.type == 'text' ? 'Copy' : 'Copy caption'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: m.body ?? ''));
                  Navigator.pop(sheet);
                  _snack('Copied');
                },
              ),
            if (m.sendState == SendState.failed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry sending'),
                onTap: () {
                  Navigator.pop(sheet);
                  _chat.retry(m);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _editBar() {
    final m = _editing!;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 4.w, 6.h),
        decoration: BoxDecoration(
          color: ChatColors.background,
          borderRadius: BorderRadius.circular(8.r),
          border:
              Border(left: BorderSide(color: colors.primaryNew, width: 3.w)),
        ),
        child: Row(children: [
          Icon(Icons.edit, size: 18.sp, color: colors.primaryNew),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.type == 'text' ? 'Edit message' : 'Edit caption',
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryNew)),
                Text(m.previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.sp, color: ChatColors.muted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() => _editing = null);
              _input.clear();
            },
          ),
        ]),
      ),
    );
  }

  Widget _replyBar() {
    final r = _replyTo!;
    final who = r.senderId == _chat.meId
        ? 'You'
        : (_conv?.members
                .firstWhere((x) => x.id == r.senderId,
                    orElse: () =>
                        ChatMember(id: '', firstName: '', lastName: ''))
                .firstName ??
            '');
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 4.w, 6.h),
        decoration: BoxDecoration(
          color: ChatColors.background,
          borderRadius: BorderRadius.circular(8.r),
          border:
              Border(left: BorderSide(color: colors.primaryNew, width: 3.w)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Replying to $who',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryNew)),
                  Text(r.previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 13.sp, color: ChatColors.muted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _replyTo = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    final canSend = _input.text.trim().isNotEmpty || _editing != null;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(4.w, 6.h, 6.w, 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_recording) ...[
            _recordingBar(),
            SizedBox(width: 6.w),
            _micButton(),
          ] else ...[
            IconButton(
              icon: Icon(
                  _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: ChatColors.muted),
              onPressed: () {
                if (_showEmoji) {
                  setState(() => _showEmoji = false);
                  _focus.requestFocus();
                } else {
                  FocusScope.of(context).unfocus();
                  setState(() => _showEmoji = true);
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                minLines: 1,
                maxLines: 5,
                maxLength: 4096,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _chat.userTyping(_id),
                decoration: InputDecoration(
                  hintText: 'Message',
                  counterText: '',
                  filled: true,
                  fillColor: ChatColors.background,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: ChatColors.muted),
              onPressed: _attachSheet,
            ),
            if (canSend)
              GestureDetector(
                onTap: _send,
                child: CircleAvatar(
                  radius: 22.r,
                  backgroundColor: colors.primaryNew,
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            else
              _micButton(),
          ],
        ],
      ),
    );
  }

  void _attachSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade600,
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
              title: const Text('My current location'),
              onTap: _shareLocation,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pink.shade400,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo or record a video'),
              onTap: _openCamera,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade400,
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Photos and videos, up to 5'),
              onTap: _openGallery,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade400,
                child: const Icon(Icons.insert_drive_file, color: Colors.white),
              ),
              title: const Text('Document'),
              subtitle: const Text('PDF, Word, Excel… up to 5'),
              onTap: _pickDocument,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPicker() {
    return SizedBox(
      height: 270.h,
      child: EmojiPicker(
        textEditingController: _input,
        onEmojiSelected: (_, __) => _chat.userTyping(_id),
        config: Config(
          height: 270.h,
          checkPlatformCompatibility: true,
          categoryViewConfig: const CategoryViewConfig(
            indicatorColor: colors.primaryNew,
            iconColorSelected: colors.primaryNew,
            backgroundColor: Colors.white,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            backgroundColor: Colors.white,
            buttonColor: Colors.white,
            buttonIconColor: colors.primaryNew,
          ),
        ),
      ),
    );
  }
}
