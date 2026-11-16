import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/chat/ui/info_screens.dart';
import 'package:parkingapp/chat/ui/new_chat_screen.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';

/// Chats tab: conversations with last message, time, ticks and unread badges.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _chat = ChatService.instance;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chat.start();
    _chat.refreshConversations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _showArchived = false;
  bool get _isAdmin =>
      (Globals.user?.roleTitle ?? '').toLowerCase() == 'administrator';

  void _open(ChatConversation c) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id)));
  }

  /// Long-press a chat: pin, mute, archive.
  Future<void> _chatActions(ChatConversation c) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: EdgeInsets.all(12.h),
            child: Text(c.displayName(_chat.meId),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
          ),
          if (!c.isArchived)
            ListTile(
              leading:
                  Icon(c.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(c.isPinned ? 'Unpin' : 'Pin to top'),
              onTap: () => Navigator.pop(s, c.isPinned ? 'unpin' : 'pin'),
            ),
          ListTile(
            leading: Icon(c.isMuted ? Icons.volume_up : Icons.volume_off),
            title:
                Text(c.isMuted ? 'Unmute notifications' : 'Mute notifications'),
            onTap: () => Navigator.pop(s, c.isMuted ? 'unmute' : 'mute'),
          ),
          ListTile(
            leading: Icon(c.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined),
            title: Text(c.isArchived ? 'Unarchive' : 'Archive'),
            onTap: () =>
                Navigator.pop(s, c.isArchived ? 'unarchive' : 'archive'),
          ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      switch (choice) {
        case 'pin':
          if (_chat.conversations.where((x) => x.isPinned).length >=
              ChatService.maxPins) {
            _snack('You can pin up to ${ChatService.maxPins} chats');
            return;
          }
          await _chat.setPinned(c, true);
        case 'unpin':
          await _chat.setPinned(c, false);
        case 'mute':
          final m = await pickMuteDuration(context);
          if (m != null) await _chat.setMute(c, m);
        case 'unmute':
          await _chat.setMute(c, 'off');
        case 'archive':
          await _chat.setArchived(c, true);
          _snack('Chat archived');
        case 'unarchive':
          await _chat.setArchived(c, false);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primaryNew,
        tooltip: 'New chat',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
                greeting: "Chats", showBackButton: false, onBackPressed: () {}),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colors.textField,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _chat,
                builder: (context, _) {
                  if (_chat.loadingConversations) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: colors.primaryNew));
                  }
                  final me = _chat.meId;
                  final archived =
                      _chat.conversations.where((c) => c.isArchived).toList();
                  final list = _chat.conversations
                      .where((c) => c.isArchived == _showArchived)
                      .where((c) =>
                          _query.isEmpty ||
                          c.displayName(me).toLowerCase().contains(_query) ||
                          (c.lastMessage?.preview ?? '')
                              .toLowerCase()
                              .contains(_query))
                      .toList();
                  final header = <Widget>[
                    if (_showArchived)
                      ListTile(
                        leading: const Icon(Icons.arrow_back),
                        title: const Text('Archived chats',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () => setState(() => _showArchived = false),
                      )
                    else if (archived.isNotEmpty)
                      ListTile(
                        leading: SizedBox(
                            width: 48.r,
                            child: Icon(Icons.archive_outlined,
                                color: ChatColors.muted)),
                        title: const Text('Archived',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text('${archived.length}',
                            style: TextStyle(color: ChatColors.muted)),
                        onTap: () => setState(() => _showArchived = true),
                      ),
                    if (_isAdmin && !_showArchived)
                      ListTile(
                        leading: SizedBox(
                            width: 48.r,
                            child: Icon(Icons.admin_panel_settings_outlined,
                                color: ChatColors.muted)),
                        title: const Text('All groups (administrator)',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AllGroupsScreen())),
                      ),
                  ];
                  if (list.isEmpty && header.isEmpty) return _empty();
                  return RefreshIndicator(
                    color: colors.primaryNew,
                    onRefresh: _chat.refreshConversations,
                    child: ListView.separated(
                      padding: EdgeInsets.only(bottom: 80.h),
                      itemCount: header.length + list.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, indent: 80.w, color: Colors.grey[200]),
                      itemBuilder: (_, i) => i < header.length
                          ? header[i]
                          : _tile(list[i - header.length], me),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        SizedBox(height: 120.h),
        Icon(Icons.forum_outlined, size: 64.sp, color: Colors.grey[400]),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            _query.isEmpty ? 'No chats yet' : 'No chats found',
            style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Archivo'),
          ),
        ),
        if (_query.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Center(
              child: Text('Tap the chat button to message a colleague',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
            ),
          ),
      ],
    );
  }

  Widget _tile(ChatConversation c, String me) {
    final last = c.lastMessage;
    final typing = _chat.typingIn(c.id);
    final mine = last != null && last.senderId == me;
    final unread = c.unreadCount > 0;

    Widget subtitle;
    if (typing.isNotEmpty) {
      subtitle = Text(c.isGroup ? '${typing.first} is typing…' : 'typing…',
          style: TextStyle(color: colors.secondarynew, fontSize: 13.sp));
    } else {
      // tick for my last message (from the matching loaded message if any)
      Tick? tick;
      if (mine && last.seq != null) {
        tick = _chat.tickFor(ChatMessage(
            id: '',
            seq: last.seq,
            conversationId: c.id,
            senderId: me,
            type: last.type,
            body: null,
            createdAt: DateTime.now()));
      }
      subtitle = Row(
        children: [
          if (tick != null) ...[TickIcon(tick, size: 15), SizedBox(width: 3.w)],
          Expanded(
            child: Text(
              last?.preview ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: unread ? Colors.black87 : ChatColors.muted,
                  fontSize: 13.sp,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
        ],
      );
    }

    return ListTile(
      onTap: () => _open(c),
      onLongPress: () => _chatActions(c),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: ConversationAvatar(c, showOnline: !c.isGroup),
      title: Row(
        children: [
          Expanded(
            child: Text(c.displayName(me),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Archivo',
                    color: const Color(0xFF1A1A2E))),
          ),
          Text(chatListTime(c.lastMessageAt),
              style: TextStyle(
                  fontSize: 11.sp,
                  color: unread ? ChatColors.unread : ChatColors.muted,
                  fontWeight: unread ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 3.h),
        child: Row(
          children: [
            Expanded(child: subtitle),
            if (c.isMuted)
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Icon(Icons.volume_off,
                    size: 16.sp, color: ChatColors.muted),
              ),
            if (c.isPinned)
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child:
                    Icon(Icons.push_pin, size: 15.sp, color: ChatColors.muted),
              ),
            if (unread)
              Container(
                margin: EdgeInsets.only(left: 6.w),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: c.isMuted ? Colors.grey : ChatColors.unread,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
