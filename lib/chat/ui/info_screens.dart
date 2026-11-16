import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/chat/chat_api.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_media.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/chat/ui/group_screens.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phase 7a screens: contact info, shared media, in-chat search, mute
/// options, and the administrator's "All groups" list.

void _snack(BuildContext context, String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

/// Mute for 8 hours / 1 week / always. Returns '8h' | '1w' | 'always'.
Future<String?> pickMuteDuration(BuildContext context) => showDialog<String>(
      context: context,
      builder: (d) => SimpleDialog(
        title: const Text('Mute notifications for…'),
        children: [
          for (final o in const [
            ('8h', '8 hours'),
            ('1w', '1 week'),
            ('always', 'Always'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(d, o.$1),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Text(o.$2, style: TextStyle(fontSize: 15.sp)),
              ),
            ),
        ],
      ),
    );

/// "Mute notifications" switch for the info screens.
class MuteTile extends StatelessWidget {
  final ChatConversation c;
  const MuteTile(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final chat = ChatService.instance;
    final until = c.mutedUntil;
    final forever = until != null &&
        until.isAfter(DateTime.now().add(const Duration(days: 3650)));
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_off_outlined),
      title: const Text('Mute notifications'),
      subtitle: c.isMuted
          ? Text(forever
              ? 'Always'
              : 'Until ${DateFormat('d MMM, HH:mm').format(until!)}')
          : null,
      activeColor: colors.primaryNew,
      value: c.isMuted,
      onChanged: (on) async {
        try {
          if (on) {
            final m = await pickMuteDuration(context);
            if (m != null) await chat.setMute(c, m);
          } else {
            await chat.setMute(c, 'off');
          }
        } catch (e) {
          if (context.mounted) _snack(context, e.toString());
        }
      },
    );
  }
}

// ----------------------------------------------------------- shared media

/// "Media" and "Docs" tabs of a chat (newest first, loads more on scroll).
class SharedMediaScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const SharedMediaScreen(
      {super.key, required this.conversationId, required this.title});

  @override
  State<SharedMediaScreen> createState() => _SharedMediaScreenState();
}

class _SharedMediaScreenState extends State<SharedMediaScreen> {
  final _chat = ChatService.instance;
  final Map<String, List<ChatMessage>> _items = {'media': [], 'docs': []};
  final Map<String, bool> _more = {'media': true, 'docs': true};
  final Map<String, bool> _loading = {'media': false, 'docs': false};

  @override
  void initState() {
    super.initState();
    _load('media');
    _load('docs');
  }

  Future<void> _load(String kind) async {
    if (_loading[kind]! || !_more[kind]!) return;
    _loading[kind] = true;
    try {
      final list = _items[kind]!;
      final (page, more) = await _chat.api.sharedMedia(
          widget.conversationId, kind,
          beforeSeq: list.isEmpty ? null : list.last.seq);
      if (!mounted) return;
      setState(() {
        list.addAll(page);
        _more[kind] = more;
      });
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      _loading[kind] = false;
    }
  }

  Widget _grid() {
    final list = _items['media']!;
    if (list.isEmpty) {
      return _emptyText(_more['media']! ? null : 'No photos or videos yet');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) _load('media');
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(2.w),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final m = list[i];
          final a = m.attachment!;
          final isVideo = m.type == 'video';
          final url = isVideo ? (a.hasThumbnail ? a.thumbUrl : null) : a.url;
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => isVideo
                        ? ChatVideoPlayer(
                            attachment: a, localPath: _chat.localPathFor(a))
                        : ChatImageViewer(
                            attachment: a, localPath: _chat.localPathFor(a)))),
            child: Stack(fit: StackFit.expand, children: [
              Container(color: const Color(0xFF1F2933)),
              if (url != null)
                CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: isVideo ? '${a.cacheKey}-thumb' : a.cacheKey,
                  httpHeaders: ChatApi.authHeaders,
                  memCacheWidth: 300, // small decode: smooth grids
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (isVideo)
                Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white70, size: 30.sp)),
            ]),
          );
        },
      ),
    );
  }

  Widget _docs() {
    final list = _items['docs']!;
    if (list.isEmpty) {
      return _emptyText(
          _more['docs']! ? null : 'No documents or voice notes yet');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) _load('docs');
        return false;
      },
      child: ListView.separated(
        padding: EdgeInsets.all(12.w),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) {
          final m = list[i];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('d MMM yyyy, HH:mm').format(m.createdAt),
                    style: TextStyle(fontSize: 11.sp, color: ChatColors.muted)),
                SizedBox(height: 4.h),
                m.type == 'audio' ? ChatVoiceBubble(m) : ChatFileBubble(m),
              ]);
        },
      ),
    );
  }

  Widget _emptyText(String? text) => Center(
      child: text == null
          ? const CircularProgressIndicator()
          : Text(text, style: TextStyle(color: ChatColors.muted)));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          title: Text(widget.title),
          bottom: const TabBar(
            labelColor: colors.primaryNew,
            indicatorColor: colors.primaryNew,
            tabs: [Tab(text: 'Media'), Tab(text: 'Docs')],
          ),
        ),
        body: TabBarView(children: [_grid(), _docs()]),
      ),
    );
  }
}

/// Info-screen row that opens the shared media screen.
class SharedMediaTile extends StatelessWidget {
  final ChatConversation c;
  const SharedMediaTile(this.c, {super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.perm_media_outlined),
        title: const Text('Media, links and docs'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SharedMediaScreen(
                    conversationId: c.id,
                    title: c.displayName(ChatService.instance.meId)))),
      );
}

// ----------------------------------------------------------- contact info

/// Tap a 1-to-1 chat header: who they are, contact details, shared media.
class ContactInfoScreen extends StatefulWidget {
  final String conversationId;
  final ChatUser user;
  const ContactInfoScreen(
      {super.key, required this.conversationId, required this.user});

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  final _chat = ChatService.instance;
  Map<String, dynamic>? _info;

  @override
  void initState() {
    super.initState();
    _chat.api.contactInfo(widget.user.id).then((i) {
      if (mounted) setState(() => _info = i);
    }).catchError((e) {
      if (mounted) _snack(context, e.toString());
    });
  }

  Widget _section(List<Widget> children) => Container(
        margin: EdgeInsets.only(top: 10.h),
        color: Colors.white,
        child: Column(children: children),
      );

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final email = _info?['email']?.toString();
    final phone = _info?['phone']?.toString();
    final groups = ((_info?['commonGroups'] as List?) ?? [])
        .map((g) => Map<String, dynamic>.from(g))
        .toList();
    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) {
        final c = _chat.conversationById(widget.conversationId);
        return Scaffold(
          backgroundColor: ChatColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0.5,
            title: const Text('Contact info'),
          ),
          body: ListView(children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(children: [
                ChatAvatar(user: u, radius: 48),
                SizedBox(height: 10.h),
                Text(u.name,
                    style: TextStyle(
                        fontSize: 20.sp, fontWeight: FontWeight.w700)),
                if ((u.role ?? _info?['role']) != null)
                  Text('${u.role ?? _info?['role']}',
                      style: TextStyle(color: ChatColors.muted)),
                SizedBox(height: 4.h),
                Text(presenceText(u),
                    style: TextStyle(fontSize: 12.sp, color: ChatColors.muted)),
              ]),
            ),
            if (email != null || phone != null)
              _section([
                if (phone != null && phone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(phone),
                    subtitle: const Text('Phone'),
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                  ),
                if (email != null && email.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(email),
                    subtitle: const Text('Email'),
                    onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
                  ),
              ]),
            if (c != null) _section([SharedMediaTile(c), MuteTile(c)]),
            if (groups.isNotEmpty)
              _section([
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${groups.length} group(s) in common',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ChatColors.muted)),
                  ),
                ),
                for (final g in groups)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryNew.withOpacity(0.12),
                      child: const Icon(Icons.group, color: colors.primaryNew),
                    ),
                    title: Text('${g['title'] ?? 'Group'}'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                conversationId: g['id'].toString()))),
                  ),
              ]),
            SizedBox(height: 30.h),
          ]),
        );
      },
    );
  }
}

// ------------------------------------------------------- in-chat search

/// Search this chat's messages. Pops with the seq of the tapped result.
class ChatSearchScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatSearchScreen({super.key, required this.conversation});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _chat = ChatService.instance;
  final _q = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>>? _results;
  bool _busy = false;
  String _last = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(v.trim()));
  }

  Future<void> _run(String q) async {
    if (q == _last) return;
    _last = q;
    if (q.length < 2) {
      setState(() => _results = null);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _chat.api.search(widget.conversation.id, q);
      if (mounted && q == _last) setState(() => _results = r);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _who(String? id) {
    if (id == _chat.meId) return 'You';
    for (final m in widget.conversation.members) {
      if (m.id == id) return m.firstName;
    }
    return '';
  }

  /// The text with the search term in bold.
  Widget _highlight(String text, String q) {
    final lower = text.toLowerCase();
    final i = lower.indexOf(q.toLowerCase());
    if (i < 0) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    final start = i > 40 ? i - 30 : 0;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: (start > 0 ? '…' : '') + text.substring(start, i)),
        TextSpan(
            text: text.substring(i, i + q.length),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: colors.primaryNew)),
        TextSpan(text: text.substring(i + q.length)),
      ]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _results;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: TextField(
          controller: _q,
          autofocus: true,
          onChanged: _changed,
          decoration: const InputDecoration(
              hintText: 'Search messages…', border: InputBorder.none),
        ),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(color: colors.primaryNew))
            : null,
      ),
      body: r == null
          ? Center(
              child: Text('Type at least 2 letters',
                  style: TextStyle(color: ChatColors.muted)))
          : r.isEmpty
              ? Center(
                  child: Text('No messages found',
                      style: TextStyle(color: ChatColors.muted)))
              : ListView.separated(
                  itemCount: r.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final x = r[i];
                    final at =
                        DateTime.tryParse('${x['createdAt']}')?.toLocal();
                    return ListTile(
                      title: Row(children: [
                        Expanded(
                          child: Text(_who(x['senderId']?.toString()),
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700)),
                        ),
                        if (at != null)
                          Text(DateFormat('d MMM yyyy').format(at),
                              style: TextStyle(
                                  fontSize: 11.sp, color: ChatColors.muted)),
                      ]),
                      subtitle: _highlight('${x['text']}', _last),
                      onTap: () =>
                          Navigator.pop(context, int.tryParse('${x['seq']}')),
                    );
                  },
                ),
    );
  }
}

// ------------------------------------------------- administrator: groups

/// Every group in the company; an Administrator can join any as admin.
class AllGroupsScreen extends StatefulWidget {
  const AllGroupsScreen({super.key});

  @override
  State<AllGroupsScreen> createState() => _AllGroupsScreenState();
}

class _AllGroupsScreenState extends State<AllGroupsScreen> {
  final _chat = ChatService.instance;
  List<Map<String, dynamic>>? _groups;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await _chat.api.allGroups();
      if (mounted) setState(() => _groups = g);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    }
  }

  Future<void> _open(Map<String, dynamic> g) async {
    final id = g['id'].toString();
    if (g['isMember'] != true) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Join "${g['title']}"?'),
          content: const Text(
              'You will join as a group admin. Members will see "joined as administrator".'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Join')),
          ],
        ),
      );
      if (ok != true) return;
      setState(() => _busyId = id);
      try {
        await _chat.api.adminJoin(id);
        await _chat.reloadConversation(id);
      } catch (e) {
        if (mounted) _snack(context, e.toString());
        return;
      } finally {
        if (mounted) setState(() => _busyId = null);
      }
    }
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => GroupInfoScreen(conversationId: id)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final g = _groups;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('All groups'),
      ),
      body: g == null
          ? const Center(child: CircularProgressIndicator())
          : g.isEmpty
              ? Center(
                  child: Text('No groups yet',
                      style: TextStyle(color: ChatColors.muted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: g.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final x = g[i];
                      final member = x['isMember'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryNew.withOpacity(0.12),
                          child:
                              const Icon(Icons.group, color: colors.primaryNew),
                        ),
                        title: Text('${x['title'] ?? 'Group'}'),
                        subtitle: Text(
                            '${x['memberCount']} members${member ? ' · you are a member' : ''}'),
                        trailing: _busyId == x['id']
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(member ? 'Manage' : 'Join',
                                style: const TextStyle(
                                    color: colors.primaryNew,
                                    fontWeight: FontWeight.w600)),
                        onTap: () => _open(x),
                      );
                    },
                  ),
                ),
    );
  }
}
