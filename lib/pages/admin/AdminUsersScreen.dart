import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/admin/admin_list_parts.dart';
import 'package:parkingapp/widgets/paged_list.dart';
import 'package:url_launcher/url_launcher.dart';

/// Admin: all users, newest first, 20 at a time (infinite scroll), with
/// search and a role filter. Same actions as the website Users page:
/// View, Edit (title/name/phone), Deactivate employee, Add employee.
class AdminUsersScreen extends StatefulWidget {
  /// Shown as a bottom-nav tab (title, no app bar / back button).
  final bool asTab;
  const AdminUsersScreen({super.key, this.asTab = false});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = GeneralRepository();
  String _search = '';
  String? _role;
  int _reload = 0;

  static const _roles = <String?, String>{
    null: 'All',
    'User': 'Customers',
    'GuestUser': 'Guest customers',
    'Employee': 'Employees',
    'Administrator': 'Admins',
  };

  void _refresh() => setState(() => _reload++);

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final canPop = !widget.asTab;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: canPop
          ? AppBar(
              title: const Text('Users'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0)
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAdminGreen,
        foregroundColor: Colors.white,
        onPressed: _createEmployee,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add employee'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!canPop) adminTabTitle('Users'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AdminSearchBox(
                hint: 'Name, email or phone',
                onChanged: (t) => setState(() => _search = t),
              ),
            ),
            AdminFilterChips(
              options: _roles,
              selected: _role,
              onSelected: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PagedList<Map<String, dynamic>>(
                key: ValueKey('users|$_search|$_role|$_reload'),
                fetch: (offset, limit) => _repo.adminUsersPage(offset, limit,
                    search: _search, role: _role),
                header: (total) => adminCountHeader(total, 'users'),
                emptyText: 'No users found',
                itemBuilder: (context, u, _) => _UserTile(
                  user: u,
                  onTap: () => _showDetails(u),
                  onAction: (a) => _action(a, u),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _action(String action, Map<String, dynamic> u) {
    switch (action) {
      case 'view':
        _showDetails(u);
        break;
      case 'edit':
        _edit(u);
        break;
      case 'deactivate':
        _deactivate(u);
        break;
    }
  }

  // ---------- View

  void _showDetails(Map<String, dynamic> u) {
    final email = '${u['email'] ?? ''}';
    final phone = '${u['phoneNo'] ?? ''}';
    final joined = DateTime.tryParse('${u['createdAt'] ?? ''}')?.toLocal();
    final lastLogin = DateTime.tryParse('${u['lastLogin'] ?? ''}')?.toLocal();
    final active = _isActive(u);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fullName(u),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${_roleLabel(u)} · ${active ? 'Active' : 'Inactive'}',
                  style: TextStyle(color: Colors.grey.shade700)),
              if (joined != null)
                Text('Joined ${DateFormat('d MMM yyyy').format(joined)}',
                    style: TextStyle(color: Colors.grey.shade700)),
              if (lastLogin != null)
                Text(
                    'Last login ${DateFormat('d MMM yyyy, h:mm a').format(lastLogin)}',
                    style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              if (email.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: Text(email),
                  onTap: () => launchUrl(Uri.parse('mailto:$email')),
                ),
              if (phone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(phone),
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _edit(u);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                if (_canDeactivate(u)) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deactivate(u);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Deactivate'),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Edit (title, name, phone: what the backend allows)

  Future<void> _edit(Map<String, dynamic> u) async {
    const titles = ['Mr', 'Mrs', 'Ms', 'Miss'];
    String title = titles.contains(u['title']) ? '${u['title']}' : 'Mr';
    final first = TextEditingController(text: '${u['firstName'] ?? ''}');
    final last = TextEditingController(text: '${u['lastName'] ?? ''}');
    final phone = TextEditingController(text: '${u['phoneNo'] ?? ''}');
    bool saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit user'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: title,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                items: titles
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => title = v ?? title,
              ),
              const SizedBox(height: 10),
              _input(first, 'First name'),
              _input(last, 'Last name'),
              _input(phone, 'Phone', keyboard: TextInputType.phone),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Email: ${u['email'] ?? '-'}\nRole: ${_roleLabel(u)}\nEmail, role and status can\'t be changed here.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAdminGreen),
              onPressed: saving
                  ? null
                  : () async {
                      if (first.text.trim().isEmpty ||
                          last.text.trim().isEmpty ||
                          phone.text.trim().isEmpty) {
                        _snack('First name, last name and phone are required.');
                        return;
                      }
                      setD(() => saving = true);
                      try {
                        await _repo.adminUpdateUser({
                          'userId': '${u['id']}',
                          'title': title,
                          'firstName': first.text.trim(),
                          'lastName': last.text.trim(),
                          'phoneNo': phone.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setD(() => saving = false);
                        _snack('$e');
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      _snack('User updated');
      _refresh();
    }
  }

  // ---------- Deactivate (employees only, as on the website)

  Future<void> _deactivate(Map<String, dynamic> u) async {
    if (!_canDeactivate(u)) {
      _snack(!_isActive(u)
          ? 'Re-activating accounts isn\'t available yet.'
          : 'Only employee accounts can be deactivated.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate employee?'),
        content: Text(
            '${_fullName(u)} will be logged out of the app and their upcoming jobs released.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final msg = await _repo.adminDeactivateEmployee('${u['id']}');
      if (!mounted) return;
      _snack(msg);
      _refresh();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  // ---------- Create employee

  Future<void> _createEmployee() async {
    final created = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const _CreateEmployeeScreen()));
    if (created == true && mounted) _refresh();
  }
}

Widget _input(TextEditingController c, String label,
        {TextInputType? keyboard}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
            labelText: label, isDense: true, border: const OutlineInputBorder()),
      ),
    );

bool _isActive(Map<String, dynamic> u) => '${u['isActive'] ?? 'Y'}' == 'Y';

String _roleTitle(Map<String, dynamic> u) =>
    u['role'] is Map ? '${u['role']['title'] ?? ''}' : '';

bool _canDeactivate(Map<String, dynamic> u) =>
    _isActive(u) && _roleTitle(u) == 'Employee';

String _fullName(Map<String, dynamic> u) {
  final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
  return name.isEmpty ? '(no name)' : name;
}

String _roleLabel(Map<String, dynamic> u) {
  final role = _roleTitle(u);
  switch (role) {
    case 'User':
      return 'Customer';
    case 'GuestUser':
      return 'Guest customer';
    case 'Administrator':
      return 'Admin';
    default:
      return role.isEmpty ? '-' : role;
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  const _UserTile(
      {required this.user, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final name = _fullName(user);
    final active = _isActive(user);
    return AdminCard(
      onTap: onTap,
      child: Row(children: [
        CircleAvatar(
          backgroundColor: kAdminGreen.withValues(alpha: 0.12),
          foregroundColor: kAdminGreen,
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${user['email'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              Text(
                  '${_roleLabel(user)}${active ? '' : ' · Inactive'}',
                  style: TextStyle(
                      color: active ? Colors.grey.shade600 : Colors.red,
                      fontSize: 12)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: onAction,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('View details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit user')),
            if (_canDeactivate(user))
              const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate',
                      style: TextStyle(color: Colors.red))),
          ],
        ),
      ]),
    );
  }
}

/// Create Employee form, as on the website. Shows the login details to
/// send to the employee after saving (the password isn't shown again).
class _CreateEmployeeScreen extends StatefulWidget {
  const _CreateEmployeeScreen();

  @override
  State<_CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<_CreateEmployeeScreen> {
  final _repo = GeneralRepository();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String _title = 'Mr';
  bool _show = false;
  bool _saving = false;
  bool _createdAny = false;
  String? _error;
  String? _credentials; // after saving

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  String _generate() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%';
    final r = Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String? _validate() {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      return 'First and last name are required.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      return 'Enter a valid email address.';
    }
    if (_phone.text.trim().isEmpty) return 'Phone number is required.';
    if (_pass.text.length < 8 || _pass.text.length > 16) {
      return 'Password must be 8 to 16 characters.';
    }
    if (_pass.text != _confirm.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) return setState(() => _error = problem);
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await _repo.adminCreateEmployee({
        'title': _title,
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'email': _email.text.trim(),
        'phoneNo': _phone.text.trim(),
        'password': _pass.text,
        'confirmPassword': _confirm.text,
      });
      _createdAny = true;
      setState(() => _credentials =
          'Hi ${_first.text.trim()} ${_last.text.trim()}, your Compare My Parking staff app login:\n'
          'Email: ${_email.text.trim().toLowerCase()}\nPassword: ${_pass.text}');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _another() {
    for (final c in [_first, _last, _email, _phone, _pass, _confirm]) {
      c.clear();
    }
    setState(() {
      _credentials = null;
      _title = 'Mr';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _createdAny);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: Text(_credentials == null ? 'Add employee' : 'Employee created'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: _credentials != null ? _done() : _formFields(),
        ),
      ),
    );
  }

  List<Widget> _done() => [
        const Text(
            'Send these login details to the employee. The password is not shown again after you leave this screen.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F7F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300)),
          child: SelectableText(_credentials!),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: kAdminGreen,
              minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _credentials!));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login details copied')));
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy details'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _another,
          child: const Text('Create another'),
        ),
      ];

  List<Widget> _formFields() => [
        DropdownButtonFormField<String>(
          initialValue: _title,
          decoration: const InputDecoration(
              labelText: 'Title', isDense: true, border: OutlineInputBorder()),
          items: const ['Mr', 'Mrs', 'Ms', 'Miss']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => _title = v ?? _title,
        ),
        const SizedBox(height: 10),
        _input(_first, 'First name'),
        _input(_last, 'Last name'),
        _input(_email, 'Email', keyboard: TextInputType.emailAddress),
        _input(_phone, 'Phone', keyboard: TextInputType.phone),
        Row(children: [
          const Expanded(
              child: Text('Password (8–16 characters)',
                  style: TextStyle(fontWeight: FontWeight.w500))),
          TextButton.icon(
            onPressed: () {
              final p = _generate();
              setState(() {
                _pass.text = p;
                _confirm.text = p;
                _show = true;
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Generate'),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _pass,
            obscureText: !_show,
            decoration: InputDecoration(
              labelText: 'Password',
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _confirm,
            obscureText: !_show,
            decoration: const InputDecoration(
                labelText: 'Confirm password',
                isDense: true,
                border: OutlineInputBorder()),
          ),
        ),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: kAdminGreen,
              minimumSize: const Size.fromHeight(48)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create employee'),
        ),
      ];
}
