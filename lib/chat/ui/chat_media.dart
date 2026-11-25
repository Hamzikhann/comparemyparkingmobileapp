import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parkingapp/chat/web_media.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:parkingapp/chat/chat_api.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

/// Photo, video, voice note and document bubbles + full-screen viewers.

String formatBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Common mime types by extension (documents picked from the phone).
String mimeForPath(String path) {
  final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
  const map = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    '3gp': 'video/3gpp',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'mp3': 'audio/mpeg',
    'ogg': 'audio/ogg',
    'wav': 'audio/wav',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'zip': 'application/zip',
  };
  return map[ext] ?? 'application/octet-stream';
}

/// Progress ring + cancel while my upload runs; retry icon if it failed.
class _UploadOverlay extends StatelessWidget {
  final ChatMessage m;
  const _UploadOverlay(this.m);

  @override
  Widget build(BuildContext context) {
    final f = m.outgoing;
    if (f == null || m.seq != null) return const SizedBox.shrink();
    final chat = ChatService.instance;
    final failed = m.sendState == SendState.failed;
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: failed ? () => chat.retry(m) : () => chat.cancelMedia(m),
          child: Container(
            width: 52.r,
            height: 52.r,
            decoration: const BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle),
            child: Stack(alignment: Alignment.center, children: [
              if (!failed)
                SizedBox(
                  width: 46.r,
                  height: 46.r,
                  child: CircularProgressIndicator(
                    value: f.uploaded
                        ? null
                        : (f.progress > 0 ? f.progress : null),
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              Icon(failed ? Icons.refresh : Icons.close,
                  color: Colors.white, size: 24.sp),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ photo

class ChatImageBubble extends StatelessWidget {
  final ChatMessage m;
  const ChatImageBubble(this.m, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = m.attachment!;
    final local = m.outgoing?.localPath ?? ChatService.instance.localPathFor(a);
    final w = 230.w;
    final h = (w / a.aspectRatio).clamp(120.h, 320.h);
    final Widget img = local != null
        ? localImage(local, fit: BoxFit.cover, width: w, height: h)
        : kIsWeb
            ? ChatWebImage(a.id,
                fit: BoxFit.cover,
                width: w,
                height: h,
                error: Container(
                    width: w,
                    height: h,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey)))
        : CachedNetworkImage(
            imageUrl: a.url,
            cacheKey: a.cacheKey,
            memCacheWidth:
                700, // decode at bubble size: less memory, smoother scrolling
            httpHeaders: ChatApi.authHeaders,
            fit: BoxFit.cover,
            width: w,
            height: h,
            placeholder: (_, __) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (_, __, ___) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.grey)),
          );
    return GestureDetector(
      onTap: m.seq == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChatImageViewer(attachment: a, localPath: local))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Hero(tag: 'img-${m.clientMsgKey ?? a.id}', child: img),
            _UploadOverlay(m),
          ]),
        ),
      ),
    );
  }
}

class ChatImageViewer extends StatelessWidget {
  final ChatAttachment attachment;
  final String? localPath;
  const ChatImageViewer({super.key, required this.attachment, this.localPath});

  @override
  Widget build(BuildContext context) {
    // Web version: server files load through a direct link
    if (kIsWeb && localPath == null) {
      return FutureBuilder<String?>(
        future: ChatService.instance.webLink(attachment.id),
        builder: (context, s) => _view(s.data == null
            ? null
            : NetworkImage(s.data!,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback)),
      );
    }
    return _view(localPath != null
        ? localImageProvider(localPath!)
        : CachedNetworkImageProvider(attachment.url,
            cacheKey: attachment.cacheKey, headers: ChatApi.authHeaders));
  }

  Widget _view(ImageProvider? provider) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0),
      body: provider == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PhotoView(
        imageProvider: provider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

// ------------------------------------------------------------------ video

class ChatVideoBubble extends StatelessWidget {
  final ChatMessage m;
  const ChatVideoBubble(this.m, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = m.attachment!;
    final w = 230.w;
    final h = (w / a.aspectRatio).clamp(130.h, 300.h);
    final local = m.outgoing?.localPath ?? ChatService.instance.localPathFor(a);
    final thumb =
        m.outgoing?.thumbPath ?? ChatService.instance.localThumbFor(a);
    return GestureDetector(
      onTap: m.seq == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChatVideoPlayer(attachment: a, localPath: local))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: w,
          height: h,
          color: const Color(0xFF1F2933),
          child: Stack(children: [
            if (thumb != null)
              Positioned.fill(child: localImage(thumb, fit: BoxFit.cover))
            else if (a.hasThumbnail)
              Positioned.fill(
                child: kIsWeb
                    ? ChatWebImage(a.id, thumb: true, fit: BoxFit.cover)
                    : CachedNetworkImage(
                  imageUrl: a.thumbUrl,
                  cacheKey: '${a.cacheKey}-thumb',
                  httpHeaders: ChatApi.authHeaders,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Center(
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white.withOpacity(0.9), size: 54.sp),
            ),
            Positioned(
              left: 8.w,
              bottom: 6.h,
              child: Row(children: [
                Icon(Icons.videocam, color: Colors.white, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                    [
                      if (a.durationMs != null)
                        formatDuration(Duration(milliseconds: a.durationMs!)),
                      formatBytes(a.sizeBytes),
                    ].join(' · '),
                    style: TextStyle(color: Colors.white, fontSize: 11.sp)),
              ]),
            ),
            _UploadOverlay(m),
          ]),
        ),
      ),
    );
  }
}

class ChatVideoPlayer extends StatefulWidget {
  final ChatAttachment attachment;
  final String? localPath;
  const ChatVideoPlayer({super.key, required this.attachment, this.localPath});

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  // Set straight away on the phone; on web after the direct link arrives
  VideoPlayerController? _ctrl;
  VideoPlayerController get _c => _ctrl!;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.localPath == null) {
      ChatService.instance.webLink(widget.attachment.id).then((url) {
        if (!mounted) return;
        if (url == null) {
          setState(() => _error = 'Could not play this video');
          return;
        }
        setState(() => _start(VideoPlayerController.networkUrl(Uri.parse(url))));
      });
      return;
    }
    _start(widget.localPath != null
        ? localVideo(widget.localPath!)
        : VideoPlayerController.networkUrl(Uri.parse(widget.attachment.url),
            httpHeaders: ChatApi.authHeaders));
  }

  void _start(VideoPlayerController c) {
    _ctrl = c;
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _c.play();
    }).catchError((e) {
      if (mounted) setState(() => _error = 'Could not play this video');
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _ctrl?.value ?? const VideoPlayerValue.uninitialized();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)))
          : !v.isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : GestureDetector(
                  onTap: () => v.isPlaying ? _c.pause() : _c.play(),
                  child: Column(children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: v.aspectRatio,
                          child: Stack(alignment: Alignment.center, children: [
                            VideoPlayer(_c),
                            if (!v.isPlaying)
                              Icon(Icons.play_circle_fill,
                                  color: Colors.white70, size: 64.sp),
                          ]),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Row(children: [
                          Text(formatDuration(v.position),
                              style: const TextStyle(color: Colors.white)),
                          Expanded(
                            child: VideoProgressIndicator(_c,
                                allowScrubbing: true,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 14.h)),
                          ),
                          Text(formatDuration(v.duration),
                              style: const TextStyle(color: Colors.white)),
                        ]),
                      ),
                    ),
                  ]),
                ),
    );
  }
}

// ------------------------------------------------------------- voice note

class ChatVoiceBubble extends StatefulWidget {
  final ChatMessage m;
  const ChatVoiceBubble(this.m, {super.key});

  @override
  State<ChatVoiceBubble> createState() => _ChatVoiceBubbleState();
}

class _ChatVoiceBubbleState extends State<ChatVoiceBubble> {
  static AudioPlayer? _playing; // only one voice note plays at a time
  AudioPlayer? _player;
  final List<StreamSubscription> _subs = [];
  bool _loading = false;
  double? _downloadProgress;
  Duration _pos = Duration.zero;
  Duration? _dur;

  ChatAttachment get _a => widget.m.attachment!;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    if (_playing == _player) _playing = null;
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final p = _player;
    if (p != null) {
      if (p.playing) {
        await p.pause();
      } else {
        if (_playing != null && _playing != p) await _playing!.pause();
        _playing = p;
        if (p.processingState == ProcessingState.completed) {
          await p.seek(Duration.zero);
        }
        p.play();
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final local = widget.m.outgoing?.localPath ??
          (kIsWeb ? ChatService.instance.localPathFor(_a) : null);
      final player = AudioPlayer();
      if (kIsWeb) {
        // Web version: my recording's blob: URL, or the direct link
        final url = local ?? await ChatService.instance.webLink(_a.id);
        if (url == null) throw Exception('no link');
        _dur = await player.setUrl(url);
      } else {
        final path = local ??
            (await ChatService.instance.fileFor(_a,
                    onProgress: (v) => setState(() => _downloadProgress = v)))
                .path;
        _dur = await player.setFilePath(path);
      }
      _subs.add(player.positionStream.listen((d) {
        if (mounted) setState(() => _pos = d);
      }));
      _subs.add(player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          player.pause();
          player.seek(Duration.zero);
        }
        if (mounted) setState(() {});
      }));
      _player = player;
      if (_playing != null) await _playing!.pause();
      _playing = player;
      player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play this voice note')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _dur ??
        (_a.durationMs != null ? Duration(milliseconds: _a.durationMs!) : null);
    final playing = _player?.playing ?? false;
    final int totalMs = total?.inMilliseconds ?? 1;
    final double maxMs = totalMs < 1 ? 1.0 : totalMs.toDouble();
    return SizedBox(
      width: 230.w,
      child: Stack(children: [
        Row(children: [
          SizedBox(
            width: 40.r,
            height: 40.r,
            child: _loading
                ? Padding(
                    padding: EdgeInsets.all(8.r),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, value: _downloadProgress),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                        size: 32.sp, color: colors.primaryNew),
                    onPressed: widget.m.outgoing != null && widget.m.seq == null
                        ? null
                        : _toggle,
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _pos.inMilliseconds.toDouble().clamp(0.0, maxMs),
                    max: maxMs,
                    activeColor: colors.primaryNew,
                    inactiveColor: Colors.black12,
                    onChanged: _player == null
                        ? null
                        : (v) =>
                            _player!.seek(Duration(milliseconds: v.round())),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                    formatDuration(
                        _pos > Duration.zero ? _pos : (total ?? Duration.zero)),
                    style: TextStyle(fontSize: 11.sp, color: ChatColors.muted)),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.mic, color: ChatColors.muted, size: 20.sp),
        ]),
        if (widget.m.outgoing != null && widget.m.seq == null)
          Positioned(
            left: 0,
            top: 0,
            child: _SmallUploadState(widget.m),
          ),
      ]),
    );
  }
}

/// Compact progress/cancel/retry for voice notes and documents.
class _SmallUploadState extends StatelessWidget {
  final ChatMessage m;
  const _SmallUploadState(this.m);

  @override
  Widget build(BuildContext context) {
    final f = m.outgoing!;
    final failed = m.sendState == SendState.failed;
    final chat = ChatService.instance;
    return GestureDetector(
      onTap: failed ? () => chat.retry(m) : () => chat.cancelMedia(m),
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Stack(alignment: Alignment.center, children: [
          if (!failed)
            SizedBox(
              width: 34.r,
              height: 34.r,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value:
                      f.uploaded ? null : (f.progress > 0 ? f.progress : null)),
            ),
          Icon(failed ? Icons.refresh : Icons.close,
              size: 18.sp, color: failed ? Colors.red : ChatColors.muted),
        ]),
      ),
    );
  }
}

// --------------------------------------------------------------- document

class ChatFileBubble extends StatefulWidget {
  final ChatMessage m;
  const ChatFileBubble(this.m, {super.key});

  @override
  State<ChatFileBubble> createState() => _ChatFileBubbleState();
}

class _ChatFileBubbleState extends State<ChatFileBubble> {
  double? _progress;
  CancelToken? _token;

  /// Web version: the browser downloads the file from its direct link.
  Future<void> _openWeb(ChatAttachment a) async {
    if (a.id.isEmpty) return; // still uploading
    final url = await ChatService.instance.webLink(a.id, download: true);
    final ok = url != null &&
        await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download the file')));
    }
  }

  Future<void> _open() async {
    final a = widget.m.attachment!;
    if (kIsWeb) return _openWeb(a);
    if (_token != null) {
      _token!.cancel();
      return;
    }
    try {
      final local = widget.m.outgoing?.localPath;
      String path;
      if (local != null) {
        path = local;
      } else {
        _token = CancelToken();
        setState(() => _progress = 0);
        path = (await ChatService.instance.fileFor(a,
                cancelToken: _token,
                onProgress: (v) => setState(() => _progress = v)))
            .path;
      }
      final r = await OpenFile.open(path, type: a.mimeType);
      if (r.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(r.type == ResultType.noAppToOpen
                ? 'No app on this phone can open this file'
                : 'Could not open the file')));
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Try again.')));
      }
    } finally {
      _token = null;
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final a = m.attachment!;
    final name = a.fileName ?? 'Document';
    final ext =
        name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    final sending = m.outgoing != null && m.seq == null;
    return InkWell(
      onTap: sending ? null : _open,
      child: Container(
        width: 240.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(children: [
          if (sending)
            _SmallUploadState(m)
          else
            SizedBox(
              width: 40.r,
              height: 40.r,
              child: _progress != null
                  ? Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(
                          strokeWidth: 2.5,
                          value: _progress! > 0 ? _progress : null),
                      Icon(Icons.close, size: 16.sp),
                    ])
                  : Icon(Icons.insert_drive_file,
                      color: colors.primaryNew, size: 34.sp),
            ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text('$ext · ${formatBytes(a.sizeBytes)}',
                    style: TextStyle(fontSize: 11.sp, color: ChatColors.muted)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------- send preview page

/// One photo or video picked for sending.
class PreviewItem {
  final String path;
  final bool isVideo;
  final String? thumbPath; // videos: first frame
  String caption = '';
  PreviewItem({required this.path, required this.isVideo, this.thumbPath});
}

/// Full-screen preview of 1–5 photos/videos before sending. Swipe between
/// them, give each its own caption, remove any. Pops with the items to send
/// (captions filled in), or null if cancelled.
class ChatMediaPreview extends StatefulWidget {
  final List<PreviewItem> items;
  final String? title;
  const ChatMediaPreview({super.key, required this.items, this.title});

  @override
  State<ChatMediaPreview> createState() => _ChatMediaPreviewState();
}

class _ChatMediaPreviewState extends State<ChatMediaPreview> {
  late final List<PreviewItem> _items = [...widget.items];
  final _page = PageController();
  final _caption = TextEditingController();
  int _index = 0;
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _show(0);
  }

  @override
  void dispose() {
    _page.dispose();
    _caption.dispose();
    _video?.dispose();
    super.dispose();
  }

  /// Switch to item [i]: save the old caption, load the new one + video.
  void _show(int i) {
    if (_index < _items.length) _items[_index].caption = _caption.text;
    _index = i;
    _caption.text = _items[i].caption;
    _video?.dispose();
    _video = null;
    if (_items[i].isVideo) {
      final c = localVideo(_items[i].path);
      _video = c;
      c.initialize().then((_) {
        if (mounted && _video == c) setState(() {});
      });
    }
    setState(() {});
  }

  void _remove() {
    if (_items.length == 1) return Navigator.pop(context);
    _items.removeAt(_index);
    final next = _index.clamp(0, _items.length - 1);
    _index = _items.length; // don't save the removed item's caption
    _show(next);
    _page.jumpToPage(next);
  }

  void _send() {
    _items[_index].caption = _caption.text;
    Navigator.pop(context, _items);
  }

  Widget _page_(PreviewItem item, int i) {
    if (!item.isVideo) {
      return PhotoView(imageProvider: localImageProvider(item.path));
    }
    final v = _video;
    if (i != _index || v == null || !v.value.isInitialized) {
      return item.thumbPath != null
          ? localImage(item.thumbPath!, fit: BoxFit.contain)
          : const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => v.value.isPlaying ? v.pause() : v.play()),
        child: AspectRatio(
          aspectRatio: v.value.aspectRatio,
          child: Stack(alignment: Alignment.center, children: [
            VideoPlayer(v),
            if (!v.value.isPlaying)
              Icon(Icons.play_circle_fill, color: Colors.white70, size: 64.sp),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.title == null
            ? null
            : Text(widget.title!, style: TextStyle(fontSize: 14.sp)),
        actions: [
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline),
            onPressed: _remove,
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _page,
            itemCount: _items.length,
            onPageChanged: _show,
            itemBuilder: (_, i) => _page_(_items[i], i),
          ),
        ),
        if (_items.length > 1)
          SizedBox(
            height: 62.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              itemCount: _items.length,
              separatorBuilder: (_, __) => SizedBox(width: 6.w),
              itemBuilder: (_, i) {
                final it = _items[i];
                final img = it.isVideo ? it.thumbPath : it.path;
                return GestureDetector(
                  onTap: () => _page.jumpToPage(i),
                  child: Container(
                    width: 50.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: i == _index
                              ? colors.primaryNew
                              : Colors.transparent,
                          width: 2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: Stack(fit: StackFit.expand, children: [
                        img != null
                            ? localImage(img, fit: BoxFit.cover)
                            : Container(color: Colors.white12),
                        if (it.isVideo)
                          Icon(Icons.videocam,
                              color: Colors.white, size: 18.sp),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _caption,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a caption…',
                    hintStyle: const TextStyle(color: Colors.white54),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white12,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.r),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: _send,
                child: Stack(clipBehavior: Clip.none, children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: colors.primaryNew,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                  if (_items.length > 1)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 9.r,
                        backgroundColor: Colors.white,
                        child: Text('${_items.length}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: colors.primaryNew)),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
