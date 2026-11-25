// Web only (staff desktop version), wide windows: sidebar + content layout for
// the employee shell. The phone app never builds these widgets.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/chat/ui/chats_screen.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/main.dart' show appRoutes, navigatorKey;
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomBottomNavBar.dart' show NavBarItem;

const _pageBg = Color(0xFFF3F5F4);
const _line = Color(0xFFE1E6E3);

class WebStaffShell extends StatelessWidget {
  const WebStaffShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.badges,
    required this.onSelect,
    required this.page,
    required this.pageKey,
    required this.chatsIndex,
    this.fullPage = false,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final Map<int, int> badges;
  final ValueChanged<int> onSelect;

  /// Screen for the current tab (not used for the Chats tab).
  final Widget page;

  /// New key = tab reloads (tab switch, job push).
  final Key pageKey;
  final int chatsIndex;

  /// [page] is a desktop page (fills the area); otherwise it's a phone
  /// screen shown in a centred card.
  final bool fullPage;

  /// Logout: forget the open chat.
  static void reset() => _ChatsPane._selected.value = null;

  /// Opens a chat in the Chats tab's right-hand pane.
  static void selectChat(String conversationId) =>
      _ChatsPane._selected.value = conversationId;

  @override
  Widget build(BuildContext context) {
    final chats = currentIndex == chatsIndex;
    return Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          _Sidebar(
              items: items,
              currentIndex: currentIndex,
              badges: badges,
              onSelect: onSelect),
          Expanded(
            child: chats
                ? const _ChatsPane()
                : WebPaneNavigator(
                    key: pageKey,
                    home: page,
                    homeMaxWidth: fullPage ? null : 820,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tracks the pages in a pane's stack (count + top page's route name).
class _DepthObserver extends NavigatorObserver {
  _DepthObserver(this.onChange);
  final VoidCallback onChange;
  final List<Route> _stack = [];

  int get depth => _stack.length;
  String? get topName => _stack.isEmpty ? null : _stack.last.settings.name;

  @override
  void didPush(Route route, Route? previousRoute) {
    _stack.add(route);
    onChange();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _stack.remove(route);
    onChange();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _stack.remove(route);
    onChange();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        _stack[i] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    }
    onChange();
  }
}

/// A page stack inside one pane: pages opened from here (job details, edit
/// profile, chat info...) stay inside the pane, beside the sidebar.
class WebPaneNavigator extends StatefulWidget {
  const WebPaneNavigator({
    super.key,
    required this.home,
    this.homeMaxWidth,
    this.pagesInCard = true,
  });

  final Widget home;

  /// First page: null = fills the pane (no card), else a white card this wide
  /// at most (double.infinity = full width card).
  final double? homeMaxWidth;

  /// Pages opened on top: a centred 820px white card (phone screens).
  final bool pagesInCard;

  /// Start-of-app pages (login, other shells): always full window.
  static const _rootRoutes = {
    '/',
    '/selection',
    '/login',
    '/signUp',
    '/driverhome',
    '/main',
    '/adminHome',
    '/home',
  };

  /// Pages with their own desktop layout: fill the pane (no card).
  static const _fullPageRoutes = {'/bookingDetail'};

  @override
  State<WebPaneNavigator> createState() => _WebPaneNavigatorState();
}

class _WebPaneNavigatorState extends State<WebPaneNavigator> {
  late final _DepthObserver _observer = _DepthObserver(_changed);

  void _changed() {
    if (!mounted) return;
    // Pushes can happen while building: update after this frame then
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  Route<dynamic>? _route(RouteSettings s) {
    final name = s.name ?? '';
    if (WebPaneNavigator._rootRoutes.contains(name)) {
      // e.g. log out: leave the shell, open it on the app's main navigator
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(name, (_) => false,
            arguments: s.arguments);
      });
      return PageRouteBuilder(
          settings: s, pageBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    final builder = appRoutes[name];
    if (builder == null) return null;
    return MaterialPageRoute(settings: s, builder: builder);
  }

  @override
  Widget build(BuildContext context) {
    final onTop = _observer.depth > 1;
    final fullPage =
        WebPaneNavigator._fullPageRoutes.contains(_observer.topName);
    final double? maxWidth = onTop
        ? (widget.pagesInCard && !fullPage ? 820 : null)
        : widget.homeMaxWidth;
    final card = maxWidth != null;
    // Same widgets whether or not it's a card, so the page stack is kept
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Padding(
          padding: card
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
              : EdgeInsets.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: card ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(card ? 14 : 0),
              border: Border.all(
                  color: card ? _line : Colors.transparent,
                  width: card ? 1 : 0),
              boxShadow: [
                if (card)
                  const BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 18,
                      offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(card ? 14 : 0),
              // Screens read MediaQuery for their width: give them the pane's
              child: LayoutBuilder(
                builder: (context, box) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: box.biggest),
                  child: Navigator(
                    observers: [_observer],
                    onGenerateInitialRoutes: (_, __) =>
                        [MaterialPageRoute(builder: (_) => widget.home)],
                    onGenerateRoute: _route,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ chats

/// Chat list on the left, the open chat on the right.
class _ChatsPane extends StatelessWidget {
  const _ChatsPane();

  // Chat open on the right (kept while switching tabs)
  static final ValueNotifier<String?> _selected = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    // Pages opened from the list (new chat, all groups) show in a card
    return WebPaneNavigator(
      homeMaxWidth: double.infinity,
      // A page stack builds its first page once: listen for the selection
      home: ValueListenableBuilder<String?>(
        valueListenable: _selected,
        builder: (context, selected, _) => Row(
          children: [
            SizedBox(
              width: 380,
              child: ChatsScreen(
                selectedId: selected,
                onOpen: (id) => _selected.value = id,
              ),
            ),
            const VerticalDivider(width: 1, color: _line),
            Expanded(
              child: selected == null
                  ? const _NoChat()
                  : WebPaneNavigator(
                      key: ValueKey(selected),
                      pagesInCard: false,
                      home: ChatScreen(conversationId: selected, embedded: true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoChat extends StatelessWidget {
  const _NoChat();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF7F9F8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Color(0xFFB5C2BB)),
            SizedBox(height: 12),
            Text('Select a chat to start messaging',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7A72))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sidebar

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.currentIndex,
    required this.badges,
    required this.onSelect,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final Map<int, int> badges;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final user = Globals.user;
    final name =
        user == null ? '' : '${user.firstName} ${user.lastName}'.trim();
    return Container(
      width: 248,
      color: colors.primaryNew,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Image.asset('assets/images/logoApp.png',
                        width: 28, height: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Parking Pilot',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text('Staff',
                            style: TextStyle(
                                color: Color(0xB3FFFFFF), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < items.length; i++)
              _NavTile(
                item: items[i],
                selected: i == currentIndex,
                badge: badges[i] ?? 0,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            const Divider(color: Color(0x26FFFFFF), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.secondarynew,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                        Text(user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xB3FFFFFF), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : const Color(0xCCFFFFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? const Color(0x24FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0x14FFFFFF),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: item.svgPath != null
                      ? SvgPicture.asset(item.svgPath!,
                          colorFilter: ColorFilter.mode(fg, BlendMode.srcIn))
                      : Icon(item.icon, color: fg, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.label,
                      style: TextStyle(
                          color: fg,
                          fontSize: 14.5,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500)),
                ),
                if (badge > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
