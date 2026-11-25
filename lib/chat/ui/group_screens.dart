
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parkingapp/chat/web_media.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/chat/chat_models.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/chat/ui/chat_widgets.dart';
import 'package:parkingapp/chat/ui/info_screens.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:path_provider/path_provider.dart';

/// Group chats (Phase 6): member picker, new group, group info.

const kMaxGroupMembers = 50; // same as the server

void _snack(BuildContext context, String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

/// Pick a group photo from the gallery, shrunk to a small JPEG.
Future<String?> pickGroupPhoto() async {
  // Web version: the browser picker shrinks it (no compress plugin there)
  if (kIsWeb) {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 80);
    return x?.path;
  }
  final x = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (x == null) return null;
  final out = await FlutterImageCompress.compressAndGetFile(x.path,
      '${(await getTemporaryDirectory()).path}/group_${DateTime.now().microsecondsSinceEpoch}.jpg',
      minWidth: 640, minHeight: 640, quality: 80);
  return out?.path;
}

// ------------------------------------------------------------ staff picker

/// Multi-select staff list. Pops with the chosen users.
class StaffPicker extends StatefulWidget {
  final String title;
  final String actionLabel;
  final Set<String> excludeIds;
  final int maxSelect;
  const StaffPicker({
    super.key,
    required this.title,
    required this.actionLabel,
    this.excludeIds = const {},
    this.maxSelect = kMaxGroupMembers - 1,
  });

  @override
  State<StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<StaffPicker> {
  final _chat = ChatService.instance;
  final Map<String, ChatUser> _picked = {};
  List<ChatUser>? _contacts;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chat.api.contacts().then((c) {
      if (mounted) setState(() => _contacts = c);
    }).catchError((e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  void _toggle(ChatUser u) {
    setState(() {
      if (_picked.containsKey(u.id)) {
        _picked.remove(u.id);
      } else if (_picked.length >= widget.maxSelect) {
        _snack(context, 'You can add up to ${widget.maxSelect} people');
      } else {
        _picked[u.id] = u;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = (_contacts ?? [])
        .where((u) => !widget.excludeIds.contains(u.id))
        .where((u) => _query.isEmpty || u.name.toLowerCase().contains(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: TextStyle(fontSize: 17.sp)),
          Text(_picked.isEmpty ? 'Select people' : '${_picked.length} selected',
              style: TextStyle(fontSize: 12.sp, color: ChatColors.muted)),
        ]),
      ),
      floatingActionButton: _picked.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: colors.primaryNew,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.pop(context, _picked.values.toList()),
              icon: const Icon(Icons.arrow_forward),
              label: Text(widget.actionLabel),
            ),
      body: Column(children: [
        if (_picked.isNotEmpty)
          SizedBox(
            height: 78.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              children: [
                for (final u in _picked.values)
                  GestureDetector(
                    onTap: () => _toggle(u),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(children: [
                        Stack(clipBehavior: Clip.none, children: [
                          ChatAvatar(user: u, radius: 22),
                          Positioned(
                            right: -4,
                            bottom: -2,
                            child: CircleAvatar(
                              radius: 9.r,
                              backgroundColor: Colors.grey.shade600,
                              child: Icon(Icons.close,
                                  size: 12.sp, color: Colors.white),
                            ),
                          ),
                        ]),
                        SizedBox(height: 2.h),
                        Text(u.firstName,
                            style: TextStyle(fontSize: 11.sp),
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search colleagues',
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
          child: _error != null
              ? Center(child: Text(_error!))
              : _contacts == null
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(
                          child: Text('No one else to add',
                              style: TextStyle(color: ChatColors.muted)))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final u = list[i];
                            final on = _picked.containsKey(u.id);
                            return ListTile(
                              leading: ChatAvatar(user: u, showOnline: true),
                              title: Text(u.name),
                              subtitle: u.role == null ? null : Text(u.role!),
                              trailing: Icon(
                                  on
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color:
                                      on ? colors.primaryNew : Colors.black26),
                              onTap: () => _toggle(u),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}

// --------------------------------------------------------------- new group

/// From the New Chat screen: pick members → name + photo → open the group.
Future<void> startNewGroup(BuildContext context) async {
  final members = await Navigator.of(context).push<List<ChatUser>>(
      MaterialPageRoute(
          builder: (_) =>
              const StaffPicker(title: 'New group', actionLabel: 'Next')));
  if (members == null || members.isEmpty || !context.mounted) return;
  final convId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => _GroupDetailsScreen(members)));
  if (convId == null || !context.mounted) return;
  Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId)));
}

class _GroupDetailsScreen extends StatefulWidget {
  final List<ChatUser> members;
  const _GroupDetailsScreen(this.members);

  @override
  State<_GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<_GroupDetailsScreen> {
  final _name = TextEditingController();
  String? _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _name.text.trim();
    if (title.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final c = await ChatService.instance.createGroup(
          title, widget.members.map((u) => u.id).toList(),
          photoPath: _photo);
      if (mounted) Navigator.pop(context, c.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('New group'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            _name.text.trim().isEmpty ? Colors.grey : colors.primaryNew,
        onPressed: _create,
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check, color: Colors.white),
      ),
      body: ListView(padding: EdgeInsets.all(16.w), children: [
        Row(children: [
          GestureDetector(
            onTap: () async {
              final p = await pickGroupPhoto();
              if (p != null) setState(() => _photo = p);
            },
            child: CircleAvatar(
              radius: 30.r,
              backgroundColor: colors.primaryNew.withOpacity(0.12),
              backgroundImage: _photo == null ? null : localImageProvider(_photo!),
              child: _photo == null
                  ? Icon(Icons.add_a_photo, color: colors.primaryNew)
                  : null,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Group name'),
            ),
          ),
        ]),
        SizedBox(height: 16.h),
        Text('Members: ${widget.members.length + 1}',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: ChatColors.muted)),
        SizedBox(height: 8.h),
        Wrap(spacing: 10.w, runSpacing: 10.h, children: [
          for (final u in widget.members)
            Column(children: [
              ChatAvatar(user: u, radius: 22),
              SizedBox(height: 2.h),
              Text(u.firstName, style: TextStyle(fontSize: 11.sp)),
            ]),
        ]),
      ]),
    );
  }
}

// -------------------------------------------------------------- group info

/// Name, photo, members (with admin tools), leave group.
/// Pops with 'left' if I left the group.
class GroupInfoScreen extends StatelessWidget {
  final String conversationId;
  const GroupInfoScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final chat = ChatService.instance;
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final c = chat.conversationById(conversationId);
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text("You're no longer in this group")),
          );
        }
        return _GroupInfoBody(c);
      },
    );
  }
}

class _GroupInfoBody extends StatefulWidget {
  final ChatConversation c;
  const _GroupInfoBody(this.c);

  @override
  State<_GroupInfoBody> createState() => _GroupInfoBodyState();
}

class _GroupInfoBodyState extends State<_GroupInfoBody> {
  final _chat = ChatService.instance;
  bool _busy = false;

  ChatConversation get c => widget.c;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename() async {
    final ctl = TextEditingController(text: c.title ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Group name'),
        content: TextField(
            controller: ctl,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, ctl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == c.title) return;
    await _run(() => _chat.renameGroup(c.id, name));
  }

  Future<void> _photo() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose a new photo'),
            onTap: () => Navigator.pop(s, 'new'),
          ),
          if (c.avatarAttachmentId != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(s, 'remove'),
            ),
        ]),
      ),
    );
    if (choice == 'new') {
      final p = await pickGroupPhoto();
      if (p != null) await _run(() => _chat.setGroupPhoto(c.id, p));
    } else if (choice == 'remove') {
      await _run(() => _chat.removeGroupPhoto(c.id));
    }
  }

  Future<void> _addMembers() async {
    final current = c.members.map((m) => m.id).toSet();
    final room = kMaxGroupMembers - current.length;
    if (room <= 0) {
      return _snack(context, 'This group is full ($kMaxGroupMembers members)');
    }
    final picked = await Navigator.of(context).push<List<ChatUser>>(
        MaterialPageRoute(
            builder: (_) => StaffPicker(
                title: 'Add members',
                actionLabel: 'Add',
                excludeIds: current,
                maxSelect: room)));
    if (picked == null || picked.isEmpty) return;
    await _run(() => _chat.addMembers(c.id, picked.map((u) => u.id).toList()));
  }

  Future<void> _memberActions(ChatMember m) async {
    final isAdmin = m.memberRole == 'admin';
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text('Message ${m.firstName}'),
            onTap: () => Navigator.pop(s, 'message'),
          ),
          if (c.amAdmin)
            ListTile(
              leading: Icon(isAdmin
                  ? Icons.remove_moderator_outlined
                  : Icons.admin_panel_settings_outlined),
              title: Text(isAdmin ? 'Dismiss as admin' : 'Make group admin'),
              onTap: () => Navigator.pop(s, isAdmin ? 'member' : 'admin'),
            ),
          if (c.amAdmin)
            ListTile(
              leading:
                  const Icon(Icons.person_remove_outlined, color: Colors.red),
              title: Text('Remove ${m.firstName}',
                  style: const TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(s, 'remove'),
            ),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'message':
        final conv = await _chat.openDirect(m);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: conv.id)));
      case 'admin':
      case 'member':
        await _run(() => _chat.setMemberRole(c.id, m.id, choice));
      case 'remove':
        final ok =
            await _confirm('Remove ${m.name} from "${c.title}"?', 'Remove');
        if (ok) await _run(() => _chat.removeMember(c.id, m.id));
    }
  }

  Future<bool> _confirm(String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: Text(action, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ) ==
      true;

  Future<void> _leave() async {
    final soleAdmin = c.amAdmin &&
        c.members.where((m) => m.memberRole == 'admin').length == 1 &&
        c.members.length > 1;
    final ok = await _confirm(
        soleAdmin
            ? 'Leave "${c.title}"? You are the only admin, so the longest-standing member will become admin.'
            : 'Leave "${c.title}"?',
        'Leave');
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await _chat.leaveGroup(c.id);
      if (mounted) Navigator.pop(context, 'left');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _chat.meId;
    final members = [...c.members]..sort((a, b) {
        if (a.id == me) return -1;
        if (b.id == me) return 1;
        if (a.memberRole != b.memberRole)
          return a.memberRole == 'admin' ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return Scaffold(
      backgroundColor: ChatColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Group info'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(color: colors.primaryNew))
            : null,
      ),
      body: ListView(children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(children: [
            GestureDetector(
              onTap: c.amAdmin ? _photo : null,
              child: Stack(children: [
                ConversationAvatar(c, radius: 48),
                if (c.amAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15.r,
                      backgroundColor: colors.primaryNew,
                      child: Icon(Icons.camera_alt,
                          size: 16.sp, color: Colors.white),
                    ),
                  ),
              ]),
            ),
            SizedBox(height: 10.h),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(c.title ?? 'Group',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20.sp, fontWeight: FontWeight.w700)),
              ),
              if (c.amAdmin)
                IconButton(
                    icon:
                        Icon(Icons.edit, size: 18.sp, color: ChatColors.muted),
                    onPressed: _rename),
            ]),
            Text('Group · ${c.members.length} members',
                style: TextStyle(color: ChatColors.muted)),
          ]),
        ),
        SizedBox(height: 10.h),
        Container(
          color: Colors.white,
          child: Column(children: [SharedMediaTile(c), MuteTile(c)]),
        ),
        SizedBox(height: 10.h),
        Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
              child: Row(children: [
                Text('${c.members.length} members',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: ChatColors.muted)),
              ]),
            ),
            if (c.amAdmin)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primaryNew,
                  child: const Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text('Add members'),
                onTap: _addMembers,
              ),
            for (final m in members)
              ListTile(
                leading: ChatAvatar(user: m, showOnline: true),
                title: Text(m.id == me ? 'You' : m.name),
                subtitle: Text(m.id == me ? (m.role ?? '') : presenceText(m)),
                trailing: m.memberRole == 'admin'
                    ? Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: colors.primaryNew.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text('Group admin',
                            style: TextStyle(
                                fontSize: 11.sp, color: colors.primaryNew)),
                      )
                    : null,
                onTap: m.id == me ? null : () => _memberActions(m),
              ),
          ]),
        ),
        SizedBox(height: 10.h),
        Container(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('Leave group', style: TextStyle(color: Colors.red)),
            onTap: _busy ? null : _leave,
          ),
        ),
        SizedBox(height: 30.h),
      ]),
    );
  }
}
