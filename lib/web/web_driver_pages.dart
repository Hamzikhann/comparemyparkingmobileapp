// Web only (staff desktop version), wide windows: desktop versions of the
// employee Home and Jobs tabs. Same data and actions as the phone screens
// (getBookingsForDriver, openDriverBooking, openBookingLocation).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart' show ConversationAvatar;
import 'package:parkingapp/chat/web_media.dart' show localImageProvider;
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/NotificationModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/ChangePasswordScreen.dart';
import 'package:parkingapp/pages/EditProfile.dart';
import 'package:parkingapp/pages/driver/driver_helpers.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/services/auth_actions.dart';
import 'package:parkingapp/utils/colors.dart';

// Job detail, Notifications and Settings pages
part 'web_driver_more.dart';

const _ink = Color(0xFF1B2B2E);
const _muted = Color(0xFF6B7A72);
const _line = Color(0xFFE1E6E3);

// ------------------------------------------------------------ data

/// Loads the employee's jobs; shared by the desktop Home and Jobs pages.
mixin _JobsLoader<T extends StatefulWidget> on State<T> {
  bool loading = true;
  String? error;
  List<Parking> active = [];
  List<Parking> completed = [];

  Future<void> loadJobs() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await GeneralRepository().getBookingsForDriver(showLoader: false);
      if (!mounted) return;
      setState(() {
        active = r.assignedAssignments;
        completed = r.completedAssignmnets;
      });
    } catch (e) {
      if (mounted) setState(() => error = 'Could not load jobs. $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

String _date(String s) {
  final d = DateTime.tryParse(s);
  return d == null ? s : DateFormat('EEE d MMM yyyy').format(d);
}

String _customer(Parking p) {
  if (p.registrations.isEmpty) return '-';
  final r = p.registrations.first;
  final n = '${r.firstName} ${r.lastName}'.trim();
  return n.isEmpty ? '-' : n;
}

String _vehicle(Parking p) {
  if (p.vehicles.isEmpty) return '-';
  final v = p.vehicles.first;
  return [v.vehicleManufacturer, v.vehicleModel]
      .where((x) => x.trim().isNotEmpty)
      .join(' ');
}

String _reg(Parking p) =>
    p.vehicles.isEmpty ? '' : p.vehicles.first.vehicleRegistration.toUpperCase();

String _flight(Parking p) {
  if (p.registrations.isEmpty) return '-';
  final r = p.registrations.first;
  final f = [r.outboundFlightNo, r.inboundFlightNo]
      .where((x) => x.trim().isNotEmpty)
      .join(' / ');
  return f.isEmpty ? '-' : f;
}

// ------------------------------------------------------------ page frame

/// Grey page with a title row; the content scrolls below it.
class WebPage extends StatelessWidget {
  const WebPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Shows a back arrow before the title.
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F5F4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 2),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: _line)),
                      icon: const Icon(Icons.arrow_back, color: _ink),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style:
                                const TextStyle(fontSize: 14, color: _muted)),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// White rounded panel with an optional title row.
class WebPanel extends StatelessWidget {
  const WebPanel(
      {super.key, this.title, this.action, required this.child, this.padding});

  final String? title;
  final Widget? action;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title!,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

Widget _refreshButton(bool loading, VoidCallback onTap) => OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.primaryNew))
          : const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primaryNew,
        side: const BorderSide(color: _line),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

Widget _errorBox(String text, VoidCallback retry) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: retry,
            style: FilledButton.styleFrom(backgroundColor: colors.primaryNew),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

Widget _empty(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFB5C2BB)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: _muted, fontSize: 14)),
        ],
      ),
    );

// ------------------------------------------------------------ chips

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.p);
  final Parking p;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = p.isCompleted
        ? ('Completed', const Color(0xFF2E7D4F), const Color(0xFFE3F3E9))
        : p.isStarted
            ? ('In progress', const Color(0xFF9A6200), const Color(0xFFFFF1D6))
            : ('Not started', const Color(0xFF2F5D8A), const Color(0xFFE4EEF8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip(this.p);
  final Parking p;

  @override
  Widget build(BuildContext context) {
    final label = p.packageType.trim().isEmpty ? 'Parking' : p.packageType;
    return Text(label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 13,
            color: p.isMeetAndGreet ? colors.secondarynew : _muted,
            fontWeight: p.isMeetAndGreet ? FontWeight.w600 : FontWeight.w400));
  }
}

// ------------------------------------------------------------ job table

class _JobTable extends StatelessWidget {
  const _JobTable({required this.jobs, this.compact = false});

  final List<Parking> jobs;

  /// Dashboard: fewer columns.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final wide = !compact && box.maxWidth >= 1050;
      final cols = <(String, int)>[
        ('Customer', 3),
        ('Airport', 2),
        ('Drop-off', 3),
        if (wide) ('Return', 3),
        if (!compact) ('Flight', 2),
        ('Vehicle', 3),
        if (!compact) ('Service', 2),
        ('Status', 2),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF7F9F8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                for (final c in cols)
                  Expanded(
                    flex: c.$2,
                    child: Text(c.$1.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11.5,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w600,
                            color: _muted)),
                  ),
                const SizedBox(width: 92),
              ],
            ),
          ),
          for (int i = 0; i < jobs.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _line),
            _JobRow(p: jobs[i], wide: wide, compact: compact),
          ],
        ],
      );
    });
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.p, required this.wide, required this.compact});

  final Parking p;
  final bool wide;
  final bool compact;

  Widget _two(String a, String b, int flex) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, color: _ink, fontWeight: FontWeight.w500)),
              if (b.isNotEmpty)
                Text(b,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: _muted)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final phone =
        p.registrations.isEmpty ? '' : p.registrations.first.phoneNo;
    final terminal =
        p.registrations.isEmpty ? '' : p.registrations.first.outboundTerminal;
    return InkWell(
      onTap: () => openDriverBooking(context, p),
      hoverColor: const Color(0xFFF3F7F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _two(_customer(p), phone, 3),
            _two(p.airport, terminal.isEmpty ? '' : 'Terminal $terminal', 2),
            _two(_date(p.startDate), p.startTime, 3),
            if (wide) _two(_date(p.endDate), p.endTime, 3),
            if (!compact) _two(_flight(p), '', 2),
            _two(_vehicle(p).isEmpty ? '-' : _vehicle(p), _reg(p), 3),
            if (!compact)
              Expanded(
                  flex: 2,
                  child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ServiceChip(p))),
            Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.centerLeft, child: _StatusChip(p))),
            SizedBox(
              width: 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (p.isMeetAndGreet && p.registrations.isNotEmpty)
                    IconButton(
                      tooltip: 'Pickup location',
                      icon: const Icon(Icons.place_outlined,
                          size: 20, color: colors.secondarynew),
                      onPressed: () => openBookingLocation(
                          context, p.registrations.first.bookingId),
                    ),
                  IconButton(
                    tooltip: 'Open job',
                    icon: const Icon(Icons.chevron_right, color: _muted),
                    onPressed: () => openDriverBooking(context, p),
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

// ------------------------------------------------------------ dashboard

class WebDriverDashboard extends StatefulWidget {
  const WebDriverDashboard({
    super.key,
    required this.unreadNotifications,
    required this.onOpenJobs,
    required this.onOpenTab,
    required this.onOpenChat,
  });

  final int unreadNotifications;
  final void Function(bool completed) onOpenJobs;
  final void Function(int tab) onOpenTab;
  final void Function(String conversationId) onOpenChat;

  static const chatsTab = 2;
  static const notificationsTab = 3;

  @override
  State<WebDriverDashboard> createState() => _WebDriverDashboardState();
}

class _WebDriverDashboardState extends State<WebDriverDashboard>
    with _JobsLoader {
  @override
  void initState() {
    super.initState();
    loadJobs();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    final first = Globals.user?.firstName ?? '';
    return WebPage(
      title: first.isEmpty ? _greeting : '$_greeting, $first',
      subtitle: DateFormat('EEEE d MMMM yyyy').format(DateTime.now()),
      actions: [_refreshButton(loading, loadJobs)],
      child: error != null && active.isEmpty && completed.isEmpty
          ? _errorBox(error!, loadJobs)
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ListenableBuilder(
                  listenable: ChatService.instance,
                  builder: (context, _) => Row(
                    children: [
                      _StatTile(
                          label: 'Active jobs',
                          value: active.length,
                          icon: Icons.schedule,
                          tint: colors.primaryNew,
                          onTap: () => widget.onOpenJobs(false)),
                      _StatTile(
                          label: 'Completed jobs',
                          value: completed.length,
                          icon: Icons.check_circle_outline,
                          tint: const Color(0xFF2E7D4F),
                          onTap: () => widget.onOpenJobs(true)),
                      _StatTile(
                          label: 'Unread messages',
                          value: ChatService.instance.totalUnread,
                          icon: Icons.chat_bubble_outline,
                          tint: const Color(0xFF2F5D8A),
                          onTap: () =>
                              widget.onOpenTab(WebDriverDashboard.chatsTab)),
                      _StatTile(
                          label: 'New notifications',
                          value: widget.unreadNotifications,
                          icon: Icons.notifications_none,
                          tint: const Color(0xFF9A6200),
                          onTap: () => widget
                              .onOpenTab(WebDriverDashboard.notificationsTab),
                          last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          WebPanel(
                            title: 'Upcoming jobs',
                            action: _viewAll(() => widget.onOpenJobs(false)),
                            child: loading && active.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(36),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: colors.primaryNew)))
                                : active.isEmpty
                                    ? _empty(Icons.event_available,
                                        'No active jobs right now')
                                    : _JobTable(
                                        jobs: active.take(6).toList(),
                                        compact: true),
                          ),
                          const SizedBox(height: 22),
                          WebPanel(
                            title: 'Recently completed',
                            action: _viewAll(() => widget.onOpenJobs(true)),
                            child: completed.isEmpty
                                ? _empty(Icons.task_alt, 'No completed jobs yet')
                                : _JobTable(
                                    jobs: completed.take(4).toList(),
                                    compact: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      flex: 2,
                      child: WebPanel(
                        title: 'Recent chats',
                        action: _viewAll(() =>
                            widget.onOpenTab(WebDriverDashboard.chatsTab)),
                        child: _RecentChats(onOpen: widget.onOpenChat),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _viewAll(VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: colors.secondarynew),
        child: const Text('View all'),
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.last = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: last ? 0 : 18),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _line)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: tint.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: tint),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$value',
                            style: const TextStyle(
                                fontSize: 26,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        const SizedBox(height: 2),
                        Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 13, color: _muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentChats extends StatelessWidget {
  const _RecentChats({required this.onOpen});
  final void Function(String conversationId) onOpen;

  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('d MMM').format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final chat = ChatService.instance;
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final list = chat.conversations
            .where((c) => !c.isArchived)
            .take(6)
            .toList(growable: false);
        if (list.isEmpty) {
          return _empty(Icons.forum_outlined, 'No chats yet');
        }
        return Column(
          children: [
            for (final ChatConversation c in list)
              InkWell(
                onTap: () => onOpen(c.id),
                hoverColor: const Color(0xFFF3F7F5),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      ConversationAvatar(c, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.displayName(chat.meId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _ink,
                                    fontWeight: c.unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                            Text(c.lastMessage?.preview ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.5, color: _muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_ago(c.lastMessageAt),
                              style: const TextStyle(
                                  fontSize: 11.5, color: _muted)),
                          if (c.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(
                                  color: colors.secondarynew,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('${c.unreadCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------ jobs

class WebDriverJobs extends StatefulWidget {
  const WebDriverJobs({super.key, this.showCompleted = false});
  final bool showCompleted;

  @override
  State<WebDriverJobs> createState() => _WebDriverJobsState();
}

class _WebDriverJobsState extends State<WebDriverJobs> with _JobsLoader {
  late bool _completed = widget.showCompleted;
  final _search = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    loadJobs();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Parking p) {
    if (_q.isEmpty) return true;
    final hay = [
      _customer(p),
      p.airport,
      _flight(p),
      _vehicle(p),
      _reg(p),
      p.startDate,
      if (p.registrations.isNotEmpty) p.registrations.first.phoneNo,
    ].join(' ').toLowerCase();
    return hay.contains(_q);
  }

  @override
  Widget build(BuildContext context) {
    final list = (_completed ? completed : active).where(_matches).toList();
    return WebPage(
      title: 'Jobs',
      subtitle: '${active.length} active · ${completed.length} completed',
      actions: [_refreshButton(loading, loadJobs)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                      value: false, label: Text('Active (${active.length})')),
                  ButtonSegment(
                      value: true,
                      label: Text('Completed (${completed.length})')),
                ],
                selected: {_completed},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _completed = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: colors.primaryNew,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: _ink,
                  side: const BorderSide(color: _line),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search customer, flight, vehicle…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: error != null && active.isEmpty && completed.isEmpty
                ? _errorBox(error!, loadJobs)
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: WebPanel(
                      child: loading && list.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: colors.primaryNew)))
                          : list.isEmpty
                              ? _empty(
                                  Icons.event_busy,
                                  _q.isNotEmpty
                                      ? 'No jobs match "$_q"'
                                      : (_completed
                                          ? 'No completed jobs'
                                          : 'No active jobs'))
                              : _JobTable(jobs: list),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
