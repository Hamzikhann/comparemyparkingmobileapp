import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/chat/ui/group_screens.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';

/// Pick a colleague (employees + admins) to start or continue a 1-to-1 chat.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _chat = ChatService.instance;
  List<ChatUser>? _contacts;
  String? _error;
  String _query = '';
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await _chat.api.contacts();
      if (mounted) setState(() => _contacts = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _open(ChatUser u) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final c = await _chat.openDirect(u);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _opening = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = (_contacts ?? [])
        .where((u) => _query.isEmpty || u.name.toLowerCase().contains(_query))
        .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
                greeting: "New Chat",
                onBackPressed: () => Navigator.pop(context)),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: TextField(
                autofocus: false,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search colleagues',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colors.textField,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: colors.primaryNew,
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
              title: const Text('New group',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => startNewGroup(context),
            ),
            const Divider(height: 1),
            if (_opening)
              const LinearProgressIndicator(color: colors.primaryNew),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _contacts == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: colors.primaryNew))
                      : list.isEmpty
                          ? Center(
                              child: Text('No colleagues found',
                                  style: TextStyle(color: Colors.grey[600])))
                          : ListenableBuilder(
                              listenable: _chat,
                              builder: (_, __) => ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final u = list[i];
                                  final status = presenceText(u);
                                  return ListTile(
                                    onTap: () => _open(u),
                                    leading:
                                        ChatAvatar(user: u, showOnline: true),
                                    title: Text(u.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp)),
                                    subtitle: Text(
                                      [
                                        if ((u.role ?? '').isNotEmpty)
                                          u.role == 'Administrator'
                                              ? 'Admin'
                                              : 'Driver',
                                        if (status.isNotEmpty) status,
                                      ].join(' · '),
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          color: ChatColors.muted),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
