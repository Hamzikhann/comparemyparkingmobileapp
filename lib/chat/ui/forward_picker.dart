import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/utils/colors.dart';

/// Pick up to 5 chats (or staff without a chat yet) to forward a message to.
/// Pops with the chosen conversation ids.
class ForwardPicker extends StatefulWidget {
  final String? excludeId;
  const ForwardPicker({super.key, this.excludeId});

  @override
  State<ForwardPicker> createState() => _ForwardPickerState();
}

class _ForwardPickerState extends State<ForwardPicker> {
  static const _max = 5;
  final _chat = ChatService.instance;
  final _search = TextEditingController();
  final Set<String> _convIds = {}; // existing chats
  final Map<String, ChatUser> _users = {}; // staff with no chat yet
  List<ChatUser> _contacts = [];
  bool _sending = false;

  int get _count => _convIds.length + _users.length;

  @override
  void initState() {
    super.initState();
    _chat.api.contacts().then((c) {
      if (mounted) setState(() => _contacts = c);
    }).catchError((_) {});
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(bool selected, VoidCallback add, VoidCallback remove) {
    if (selected) {
      setState(remove);
    } else if (_count >= _max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You can forward to at most $_max chats at a time')));
    } else {
      setState(add);
    }
  }

  Future<void> _done() async {
    setState(() => _sending = true);
    try {
      final ids = [..._convIds];
      for (final u in _users.values) {
        ids.add((await _chat.openDirect(u)).id); // creates the chat if needed
      }
      if (mounted) Navigator.pop(context, ids);
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _chat.meId;
    final q = _search.text.trim().toLowerCase();
    final chats = _chat.conversations
        .where((c) => c.id != widget.excludeId)
        .where((c) => q.isEmpty || c.displayName(me).toLowerCase().contains(q))
        .toList();
    // Staff I don't have a 1-to-1 chat with yet
    final withChat = {
      for (final c in _chat.conversations)
        if (!c.isGroup) c.other(me)?.id
    };
    final others = _contacts
        .where((u) => !withChat.contains(u.id))
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_count == 0 ? 'Forward to…' : '$_count selected'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      floatingActionButton: _count == 0
          ? null
          : FloatingActionButton(
              backgroundColor: colors.primaryNew,
              onPressed: _sending ? null : _done,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white),
            ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: ChatColors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.r),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView(children: [
            if (chats.isNotEmpty) _header('Recent chats'),
            for (final c in chats)
              _tile(
                avatar: ConversationAvatar(c),
                name: c.displayName(me),
                selected: _convIds.contains(c.id),
                onTap: (sel) => _toggle(
                    sel, () => _convIds.add(c.id), () => _convIds.remove(c.id)),
              ),
            if (others.isNotEmpty) _header('Other staff'),
            for (final u in others)
              _tile(
                avatar: ChatAvatar(user: u),
                name: u.name,
                selected: _users.containsKey(u.id),
                onTap: (sel) => _toggle(
                    sel, () => _users[u.id] = u, () => _users.remove(u.id)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _header(String t) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
        child: Text(t,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: ChatColors.muted)),
      );

  Widget _tile({
    required Widget avatar,
    required String name,
    required bool selected,
    required void Function(bool selected) onTap,
  }) =>
      ListTile(
        leading: avatar,
        title: Text(name),
        trailing: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? colors.primaryNew : Colors.black26),
        onTap: () => onTap(selected),
      );
}
