import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:parkingapp/chat/chat_service.dart';
import 'package:video_player/video_player.dart';

/// Helpers so chat media works in both places:
/// - phone: just-picked / recorded media is a file path;
/// - web (staff desktop version): it's a browser blob: URL, and files from
///   the server load through a short-lived direct link (the browser's
///   <img>/<video>/<audio> can't send the login header).

ImageProvider localImageProvider(String path) =>
    kIsWeb ? NetworkImage(path) : FileImage(File(path)) as ImageProvider;

Widget localImage(String path,
        {BoxFit? fit, double? width, double? height}) =>
    kIsWeb
        ? Image.network(path, fit: fit, width: width, height: height)
        : Image.file(File(path), fit: fit, width: width, height: height);

VideoPlayerController localVideo(String path) => kIsWeb
    ? VideoPlayerController.networkUrl(Uri.parse(path))
    : VideoPlayerController.file(File(path));

Future<int> localLength(String path) =>
    kIsWeb ? XFile(path).length() : File(path).length();

Future<Uint8List> localBytes(String path) =>
    kIsWeb ? XFile(path).readAsBytes() : File(path).readAsBytes();

/// Web only: a chat attachment image loaded through its direct link.
class ChatWebImage extends StatelessWidget {
  final String attachmentId;
  final bool thumb;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? error;

  const ChatWebImage(this.attachmentId,
      {super.key,
      this.thumb = false,
      this.fit,
      this.width,
      this.height,
      this.error});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ChatService.instance.webLink(attachmentId, thumb: thumb),
      builder: (context, s) {
        final url = s.data;
        if (url == null) {
          return s.connectionState == ConnectionState.done
              ? (error ?? const SizedBox.shrink())
              : SizedBox(width: width, height: height);
        }
        return Image.network(
          url,
          fit: fit,
          width: width,
          height: height,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
