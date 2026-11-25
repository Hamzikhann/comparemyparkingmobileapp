// Web only (staff desktop version): desktop Job detail, Notifications and
// Settings. Part of web_driver_pages.dart (shares its helpers and imports).
part of 'web_driver_pages.dart';

// ------------------------------------------------------------ shared bits

/// Label + value pairs in [columns] columns.
class _InfoGrid extends StatelessWidget {
  const _InfoGrid(this.items, {this.columns = 2});
  final List<(String, String)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += columns) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = i; j < i + columns; j++)
              Expanded(
                child: j < items.length
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[j].$1.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    letterSpacing: .6,
                                    fontWeight: FontWeight.w600,
                                    color: _muted)),
                            const SizedBox(height: 5),
                            SelectableText(
                                items[j].$2.trim().isEmpty ? '-' : items[j].$2,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: _ink,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

ButtonStyle _outlined() => OutlinedButton.styleFrom(
      foregroundColor: colors.primaryNew,
      side: const BorderSide(color: _line),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

ButtonStyle _filled(Color c) => FilledButton.styleFrom(
      backgroundColor: c,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

// ------------------------------------------------------------ job detail

/// Desktop job detail. State and actions stay in Bookingdetaildriver.
class WebJobDetail extends StatelessWidget {
  const WebJobDetail({
    super.key,
    required this.job,
    required this.submitting,
    required this.onBack,
    required this.onAction,
    required this.onWhatsApp,
  });

  final Parking job;
  final bool submitting;
  final VoidCallback onBack;

  /// Start or End job (checks the date, then the checkpoint dialog).
  final VoidCallback onAction;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final reg = job.registrations.isEmpty ? null : job.registrations.first;
    final car = job.vehicles.isEmpty ? null : job.vehicles.first;
    final isEnd = job.isStarted;
    final service =
        job.packageType.trim().isEmpty ? 'Parking' : job.packageType;

    final String bannerText;
    final Color bannerColor;
    final IconData bannerIcon;
    if (job.isCompleted) {
      bannerText = 'Job completed';
      bannerColor = const Color(0xFF2E7D4F);
      bannerIcon = Icons.check_circle;
    } else if (job.isStarted) {
      bannerText = 'Car collected: end the job when it is returned';
      bannerColor = const Color(0xFF9A6200);
      bannerIcon = Icons.directions_car;
    } else {
      bannerText = 'Not started: start the job when you collect the car';
      bannerColor = const Color(0xFF2F5D8A);
      bannerIcon = Icons.schedule;
    }

    return WebPage(
      title: _customer(job),
      subtitle: '${job.airport} Airport · $service',
      onBack: onBack,
      actions: [
        if (job.isMeetAndGreet && reg != null) ...[
          OutlinedButton.icon(
            onPressed: () => openBookingLocation(context, reg.bookingId),
            icon: const Icon(Icons.place_outlined, size: 18),
            label: const Text('Pickup location'),
            style: _outlined(),
          ),
          const SizedBox(width: 10),
        ],
        if ((reg?.phoneNo ?? '').isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('WhatsApp'),
            style: _outlined(),
          ),
          const SizedBox(width: 10),
        ],
        if (!job.isCompleted)
          FilledButton.icon(
            onPressed: submitting ? null : onAction,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(isEnd ? Icons.flag : Icons.play_arrow, size: 18),
            label: Text(isEnd ? 'End job' : 'Start job'),
            style: _filled(isEnd ? colors.secondarynew : colors.primaryNew),
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bannerColor.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                Icon(bannerIcon, color: bannerColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(bannerText,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: bannerColor)),
                ),
                _StatusChip(job),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    WebPanel(
                      title: 'Booking',
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _InfoGrid([
                        ('Drop-off', '${_date(job.startDate)}  ${job.startTime}'),
                        ('Return', '${_date(job.endDate)}  ${job.endTime}'),
                        ('Airport', job.airport),
                        ('Service', service),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    WebPanel(
                      title: 'Flights',
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _InfoGrid([
                        ('Outbound flight', reg?.outboundFlightNo ?? ''),
                        ('Outbound terminal', reg?.outboundTerminal ?? ''),
                        ('Inbound flight', reg?.inboundFlightNo ?? ''),
                        ('Inbound terminal', reg?.inboundTerminal ?? ''),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    WebPanel(
                      title: 'Customer',
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _InfoGrid([
                        ('Name', _customer(job)),
                        ('Phone', reg?.phoneNo ?? ''),
                        ('Email', reg?.email ?? ''),
                      ], columns: 1),
                    ),
                    const SizedBox(height: 22),
                    WebPanel(
                      title: 'Vehicle',
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _InfoGrid([
                        ('Registration', _reg(job)),
                        ('Colour', car?.vehicleColour ?? ''),
                        ('Make', car?.vehicleManufacturer ?? ''),
                        ('Model', car?.vehicleModel ?? ''),
                        ('Passengers', car?.numberofPassengers ?? ''),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ notifications

class WebDriverNotifications extends StatefulWidget {
  const WebDriverNotifications({super.key, this.onUnreadChanged});

  /// Read state changed: refresh the sidebar badge.
  final VoidCallback? onUnreadChanged;

  @override
  State<WebDriverNotifications> createState() =>
      _WebDriverNotificationsState();
}

class _WebDriverNotificationsState extends State<WebDriverNotifications> {
  final _repo = GeneralRepository();
  List<NotificationModel> _items = [];
  bool _loading = true;
  String? _error;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _repo.getNotifications(silent: true);
      if (mounted) setState(() => _items = r.notifications);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load notifications. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  void _markLocal(Set<String> ids) {
    if (!mounted) return;
    setState(() {
      _items = [
        for (final n in _items)
          ids.contains(n.id) ? n.copyWith(isRead: true) : n
      ];
    });
    widget.onUnreadChanged?.call();
  }

  Future<void> _markAllRead() async {
    final ids = _items.where((n) => !n.isRead).map((n) => n.id).toList();
    if (ids.isEmpty) return;
    try {
      await _repo.markNotificationsAsRead(ids);
      _markLocal(ids.toSet());
    } catch (e) {
      _snack('Could not mark as read: $e');
    }
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This removes every notification from your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.primaryNew),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Clear all')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final msg =
          await _repo.clearAllNotifications(_items.map((n) => n.id).toList());
      if (!mounted) return;
      setState(() => _items = []);
      widget.onUnreadChanged?.call();
      _snack(msg);
    } catch (e) {
      _snack('Could not clear notifications: $e');
    }
  }

  /// Same as the phone screen: mark read, then open the job it is about.
  Future<void> _open(NotificationModel n) async {
    try {
      if (!n.isRead) {
        await _repo.markNotificationsAsRead([n.id]);
        _markLocal({n.id});
      }
      if (n.bookingId.isEmpty) {
        _snack('This notification is not linked to a job');
        return;
      }
      final res = await _repo.getBookingsForDriver(showLoader: false);
      final match = [...res.assignedAssignments, ...res.completedAssignmnets]
          .where((p) => p.id == n.bookingId)
          .toList();
      if (!mounted) return;
      if (match.isNotEmpty) {
        openDriverBooking(context, match.first);
      } else {
        _snack('This job is no longer assigned to you');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  String _when(String s) {
    final d = DateTime.tryParse(s)?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat('d MMM yyyy, HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;
    final list =
        _unreadOnly ? _items.where((n) => !n.isRead).toList() : _items;
    return WebPage(
      title: 'Notifications',
      subtitle: unread == 0 ? 'All caught up' : '$unread unread',
      actions: [
        if (unread > 0) ...[
          OutlinedButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all as read'),
            style: _outlined(),
          ),
          const SizedBox(width: 10),
        ],
        if (_items.isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Clear all'),
            style: _outlined(),
          ),
          const SizedBox(width: 10),
        ],
        _refreshButton(_loading, _load),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: false, label: Text('All (${_items.length})')),
              ButtonSegment(value: true, label: Text('Unread ($unread)')),
            ],
            selected: {_unreadOnly},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _unreadOnly = s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              selectedBackgroundColor: colors.primaryNew,
              selectedForegroundColor: Colors.white,
              foregroundColor: _ink,
              side: const BorderSide(color: _line),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _error != null && _items.isEmpty
                ? _errorBox(_error!, _load)
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: WebPanel(
                      child: _loading && _items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: colors.primaryNew)))
                          : list.isEmpty
                              ? _empty(
                                  Icons.notifications_none,
                                  _unreadOnly
                                      ? 'No unread notifications'
                                      : 'No notifications')
                              : Column(
                                  children: [
                                    for (int i = 0; i < list.length; i++) ...[
                                      if (i > 0)
                                        const Divider(height: 1, color: _line),
                                      _row(list[i]),
                                    ],
                                  ],
                                ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(NotificationModel n) {
    final linked = n.bookingId.isNotEmpty;
    final tint = n.isRead ? _muted : colors.primaryNew;
    return InkWell(
      onTap: () => _open(n),
      hoverColor: const Color(0xFFF3F7F5),
      child: Container(
        color: n.isRead ? null : colors.primaryNew.withValues(alpha: .04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  linked ? Icons.work_outline : Icons.notifications_none,
                  size: 20,
                  color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          fontSize: 14.5,
                          color: _ink,
                          fontWeight:
                              n.isRead ? FontWeight.w500 : FontWeight.w700)),
                  if ((n.body ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.body!,
                        style: const TextStyle(fontSize: 13.5, color: _muted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_when(n.createdAt),
                    style: const TextStyle(fontSize: 12, color: _muted)),
                if (!n.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        color: colors.primaryNew, shape: BoxShape.circle),
                  ),
              ],
            ),
            if (linked)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 8),
                child: Icon(Icons.chevron_right, color: _muted),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ settings

/// Shows a phone screen (edit profile, change password) in a dialog; its own
/// back arrow / success pop closes the dialog.
Future<T?> _screenDialog<T>(BuildContext context, Widget screen) {
  return showDialog<T>(
    context: context,
    builder: (c) {
      final h = MediaQuery.of(c).size.height;
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 480,
          height: (h - 80).clamp(420.0, 760.0),
          child: LayoutBuilder(
            builder: (c, box) => MediaQuery(
              data: MediaQuery.of(c).copyWith(size: box.biggest),
              child: screen,
            ),
          ),
        ),
      );
    },
  );
}

class WebDriverSettings extends StatefulWidget {
  const WebDriverSettings({super.key});

  @override
  State<WebDriverSettings> createState() => _WebDriverSettingsState();
}

class _WebDriverSettingsState extends State<WebDriverSettings> {
  Future<void> _editProfile() async {
    await _screenDialog(context, Editprofile());
    if (mounted) setState(() {}); // name / photo may have changed
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true && mounted) await logoutAndGoToLogin(context);
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFF3F7F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? _muted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          color: color ?? _ink,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12.5, color: _muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color ?? _muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Globals.user;
    final name = u == null ? '' : '${u.firstName} ${u.lastName}'.trim();
    final img = u?.imageURL ?? '';
    final ImageProvider? photo = img.isEmpty
        ? null
        : (img.startsWith('http')
            ? CachedNetworkImageProvider(img)
            : localImageProvider(img));
    return WebPage(
      title: 'Settings',
      subtitle: 'Your profile and account',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: WebPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colors.secondarynew,
                        backgroundImage: photo,
                        child: photo != null
                            ? null
                            : Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 14),
                      Text(name.isEmpty ? 'Employee' : name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      const SizedBox(height: 4),
                      const Text('Employee',
                          style: TextStyle(fontSize: 13, color: _muted)),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: _line),
                      const SizedBox(height: 20),
                      _InfoGrid([
                        ('Email', u?.email ?? ''),
                        ('Phone', u?.phoneNo ?? ''),
                      ], columns: 1),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit profile'),
                          style: _filled(colors.primaryNew),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    WebPanel(
                      title: 'Security',
                      child: _tile(
                          Icons.lock_outline,
                          'Change password',
                          'Update the password you sign in with',
                          () => _screenDialog(
                              context, const ChangePasswordScreen())),
                    ),
                    const SizedBox(height: 22),
                    WebPanel(
                      title: 'Help',
                      child: Column(
                        children: [
                          _tile(
                              Icons.description_outlined,
                              'Terms and conditions',
                              'How the service works',
                              () => Navigator.pushNamed(
                                  context, MyRoutes.termsAndCondition)),
                          const Divider(height: 1, color: _line),
                          _tile(
                              Icons.help_outline,
                              'Help center',
                              'Contact support',
                              () => Navigator.pushNamed(
                                  context, MyRoutes.supportRoute)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    WebPanel(
                      child: _tile(Icons.logout, 'Log out',
                          'Sign out of the staff app', _logout,
                          color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
