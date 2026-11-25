import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parkingapp/web/web_frame.dart';
import 'package:parkingapp/web/web_driver_pages.dart';
import 'package:parkingapp/web/web_staff_shell.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chats_screen.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/SettingsScreen.dart';
import 'package:parkingapp/services/job_push.dart';
import 'package:parkingapp/pages/driver/DriverHome.dart';
import 'package:parkingapp/pages/driver/DriverJobsScreen.dart';
import 'package:parkingapp/pages/driver/NotificationsScreenDriver.dart';
import 'package:parkingapp/widgets/CustomBottomNavBar.dart';

/// Main shell for employees (drivers), with the same bottom navigation
/// style as the customer/admin [MainScreen].
class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  static const int _jobsTab = 1;
  static const int _chatsTab = 2;
  static const int _notificationsTab = 3;

  static const List<NavBarItem> _items = [
    NavBarItem(label: "Home", svgPath: "assets/images/home.svg"),
    NavBarItem(label: "Jobs", svgPath: "assets/images/bookings.svg"),
    NavBarItem(label: "Chats", icon: Icons.chat_bubble_outline),
    NavBarItem(label: "Notifications", icon: Icons.notifications_outlined),
    NavBarItem(label: "Settings", svgPath: "assets/images/settings.svg"),
  ];

  int _currentIndex = 0;
  bool _jobsShowCompleted = false;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    jobPushTick.addListener(_onJobPush);
    ChatService.instance.start(); // live chat connection + unread badge
    // Web: wide windows switch to the sidebar layout (after this frame)
    if (kIsWeb) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => webShellActive.value = true);
    }
  }

  @override
  void dispose() {
    jobPushTick.removeListener(_onJobPush);
    if (kIsWeb) {
      WebStaffShell.reset();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => webShellActive.value = false);
    }
    super.dispose();
  }

  void _select(int index) {
    // Leaving the Notifications tab: items may have been read
    if (_currentIndex == _notificationsTab) _loadUnread();
    setState(() {
      if (index == _jobsTab) _jobsShowCompleted = false;
      _currentIndex = index;
    });
  }

  // A job push arrived while the app is open: reload tabs + badge
  void _onJobPush() {
    if (!mounted) return;
    setState(() {});
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final res = await GeneralRepository().getNotifications(silent: true);
      if (!mounted) return;
      setState(() =>
          _unread = res.notifications.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Widget _screenFor(int index) {
    switch (index) {
      case 1:
        return DriverJobsScreen(showCompleted: _jobsShowCompleted);
      case _chatsTab:
        return const ChatsScreen();
      case _notificationsTab:
        return const NotificationsScreenDriver(showBackButton: false);
      case 4:
        return SettingsScreen();
      case 0:
      default:
        return Driverhome(
          onViewAllJobs: (completed) => setState(() {
            _jobsShowCompleted = completed;
            _currentIndex = _jobsTab;
          }),
        );
    }
  }

  /// Web desktop layout: own Home and Jobs pages (null = use the phone screen).
  Widget? _desktopScreenFor(int index) {
    switch (index) {
      case 0:
        return WebDriverDashboard(
          unreadNotifications: _unread,
          onOpenJobs: (completed) => setState(() {
            _jobsShowCompleted = completed;
            _currentIndex = _jobsTab;
          }),
          onOpenTab: _select,
          onOpenChat: (id) {
            WebStaffShell.selectChat(id);
            _select(_chatsTab);
          },
        );
      case _jobsTab:
        return WebDriverJobs(showCompleted: _jobsShowCompleted);
      case _notificationsTab:
        return WebDriverNotifications(onUnreadChanged: _loadUnread);
      case 4:
        return const WebDriverSettings();
      default:
        return null;
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you really want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Web, wide window: sidebar + content layout (phone: unchanged below)
    if (kIsWeb && WebFrame.isDesktop(context)) {
      return ListenableBuilder(
        listenable: ChatService.instance,
        builder: (context, _) => WebStaffShell(
          items: _items,
          currentIndex: _currentIndex,
          badges: {
            _chatsTab: ChatService.instance.totalUnread,
            _notificationsTab: _unread,
          },
          onSelect: _select,
          page: _desktopScreenFor(_currentIndex) ?? _screenFor(_currentIndex),
          fullPage: _desktopScreenFor(_currentIndex) != null,
          pageKey: ValueKey(
              '${_currentIndex}_${_jobsShowCompleted}_${jobPushTick.value}'),
          chatsIndex: _chatsTab,
        ),
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        // New key on each job push rebuilds the tab so it reloads its data
        body: KeyedSubtree(
          key: ValueKey('${_currentIndex}_${jobPushTick.value}'),
          child: _screenFor(_currentIndex),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: ChatService.instance,
          builder: (context, _) => Custombottomnavbar(
            items: _items,
            currentIndex: _currentIndex,
            badges: {
              _chatsTab: ChatService.instance.totalUnread,
              _notificationsTab: _unread,
            },
            onTap: _select,
          ),
        ),
      ),
    );
  }
}
