import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/web/web_notify.dart';

/// True while the employee shell is on screen. In a wide window the shell then
/// uses the whole window (sidebar layout).
final ValueNotifier<bool> webShellActive = ValueNotifier<bool>(false);

/// Web only (staff desktop version).
///
/// - Shell on screen, wide window: the app fills the window (sidebar layout).
/// - Otherwise, wide window (login, forgot password...): brand panel on the
///   left, the phone-width app in a card on the right.
/// - Narrow window: the phone-width app as a centred column.
///
/// Sizes (.w/.h/.sp) always scale from a phone-width column, so text and
/// spacing keep their phone size. ScreenUtilInit sizes from the whole browser
/// window, so on web ScreenUtil is configured here instead.
class WebFrame extends StatelessWidget {
  const WebFrame({super.key, required this.builder});

  final WidgetBuilder builder;

  static const double maxWidth = 430;
  static const double desktopMinWidth = 1000;
  static const Size designSize = Size(375, 812);

  /// Desktop (sidebar) layout fits this window.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMinWidth;

  /// A page inside the sidebar layout (its own MediaQuery is the pane's size,
  /// so this checks the browser window instead).
  static bool inDesktopShell(BuildContext context) {
    if (!webShellActive.value) return false;
    final view = View.of(context);
    return view.physicalSize.width / view.devicePixelRatio >= desktopMinWidth;
  }

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.of(context); // rebuilds when the window resizes
    return ValueListenableBuilder<bool>(
      valueListenable: webShellActive,
      builder: (context, shell, _) {
        final size = window.size;
        final wideWindow = size.width >= desktopMinWidth;
        final full = shell && wideWindow; // sidebar layout
        final branded = !shell && wideWindow; // login etc.

        final brandWidth = branded ? math.max(0.0, size.width - 560) : 0.0;
        final colWidth = math.min(size.width, maxWidth);
        final appWidth = full ? size.width : colWidth;
        final appHeight = full
            ? size.height
            : branded
                ? math.min(size.height - 48, 860.0)
                : size.height;

        final column = window.copyWith(size: Size(colWidth, appHeight));
        ScreenUtil.configure(
          data: column,
          designSize: designSize,
          splitScreenMode: true,
          minTextAdapt: true,
        );
        final app =
            MediaQuery(data: full ? window : column, child: builder(context));
        final radius = BorderRadius.circular(branded ? 20 : 0);

        // Same widgets in every mode, so switching keeps the app's state
        return Listener(
          // Browsers allow the notification prompt + sound only after a click
          onPointerDown: (_) => webUnlockAlerts(),
          // Above MaterialApp there is no text direction yet (Row/Text need it)
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: const Color(0xFFE8ECEA),
              child: Row(
                children: [
                  SizedBox(
                    width: brandWidth,
                    child: brandWidth > 0 ? const _BrandPanel() : null,
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: appWidth,
                        height: appHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            boxShadow: [
                              if (branded)
                                const BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 30,
                                    offset: Offset(0, 10)),
                            ],
                          ),
                          child: ClipRRect(borderRadius: radius, child: app),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Left side of the login page on wide windows.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    // Short window: headline only (no feature list)
    final compact = MediaQuery.of(context).size.height < 720;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryNew, Color(0xFF2E6560), colors.secondarynew],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Image.asset('assets/images/logoApp.png',
                    width: 32, height: 32),
              ),
              const SizedBox(width: 14),
              const Text('Parking Pilot',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Staff portal',
                    style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 15,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Your jobs, customers and team chat in one place.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.2,
                        fontWeight: FontWeight.w700)),
                if (!compact) ...const [
                  SizedBox(height: 36),
                  _Feature(Icons.work_outline, 'Jobs at a glance',
                      'See upcoming and completed jobs with customer, flight and vehicle details.'),
                  _Feature(Icons.forum_outlined, 'Team chat',
                      'Message colleagues and groups, and share photos, files and voice notes.'),
                  _Feature(
                      Icons.notifications_active_outlined,
                      'Instant alerts',
                      'Get notified on your desktop when a job is assigned or a message arrives.'),
                ],
              ],
            ),
          ),
          const Spacer(),
          Text('© ${DateTime.now().year} Compare My Airport Parking',
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        color: Color(0xCCFFFFFF), fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
