import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/admin/admin_list_parts.dart';

/// Admin booking actions, the same as the website admin Bookings page:
/// View details, Edit booking, Send email.

final _repo = GeneralRepository();

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Map<String, dynamic> _first(Map<String, dynamic> b, List<String> keys) {
  for (final k in keys) {
    final v = b[k];
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    if (v is Map) return Map<String, dynamic>.from(v);
  }
  return {};
}

Map<String, dynamic> _reg(Map<String, dynamic> b) =>
    _first(b, ['registrations', 'Registrations', 'registration']);
Map<String, dynamic> _car(Map<String, dynamic> b) =>
    _first(b, ['vehicles', 'Vehicles', 'vehicle']);
Map<String, dynamic> _pkg(Map<String, dynamic> b) =>
    _first(b, ['package', 'Package', 'packages']);

String _s(dynamic v) => v == null ? '' : '$v'.trim();

// ---------------------------------------------------------------- View

class AdminBookingInfoScreen extends StatefulWidget {
  final String bookingId;
  final String? referenceNo;
  const AdminBookingInfoScreen(
      {super.key, required this.bookingId, this.referenceNo});

  @override
  State<AdminBookingInfoScreen> createState() => _AdminBookingInfoScreenState();
}

class _AdminBookingInfoScreenState extends State<AdminBookingInfoScreen> {
  Map<String, dynamic>? _b;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final b = await _repo.adminBookingDetail(widget.bookingId);
      if (mounted) setState(() => _b = b);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _edit() async {
    final b = _b;
    if (b == null) return;
    final saved = await openAdminBookingEdit(context, b);
    if (saved) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final ref = _s(b?['referenceNo']).isNotEmpty
        ? _s(b?['referenceNo'])
        : (widget.referenceNo ?? '');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: Text(ref.isEmpty ? 'Booking details' : 'Booking #$ref'),
          actions: [
            IconButton(
                tooltip: 'Edit booking',
                icon: const Icon(Icons.edit_outlined),
                onPressed: b == null ? null : _edit),
            IconButton(
                tooltip: 'Send email',
                icon: const Icon(Icons.mail_outline),
                onPressed: b == null
                    ? null
                    : () => showAdminSendBookingEmail(context,
                        bookingId: widget.bookingId,
                        referenceNo: ref,
                        customerEmail: _s(_reg(b)['email']))),
          ],
        ),
        body: _error != null
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]),
              ))
            : b == null
                ? const Center(
                    child: CircularProgressIndicator(color: kAdminGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: _sections(b),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _sections(Map<String, dynamic> b) {
    final reg = _reg(b);
    final car = _car(b);
    final pkg = _pkg(b);
    final out = <Widget>[
      _Section(
        icon: Icons.event_note_outlined,
        title: 'Booking information',
        rows: {
          'Reference No': _s(b['referenceNo']),
          'Start': '${_s(b['startDate'])}  ${_s(b['startTime'])}',
          'End': '${_s(b['endDate'])}  ${_s(b['endTime'])}',
          'Airport': _s(b['airport']),
          'Company': _s(pkg['title']),
        },
        trailing: adminStatusPill(_s(b['status'])),
      ),
    ];
    if (reg.isNotEmpty) {
      out.add(_Section(
        icon: Icons.person_outline,
        title: 'Passenger information',
        rows: {
          'Name': '${_s(reg['title'])} ${_s(reg['firstName'])} ${_s(reg['lastName'])}'
              .trim(),
          'Email': _s(reg['email']),
          'Phone': _s(reg['phoneNo']),
          'Outbound terminal': _s(reg['outboundTerminal']),
          'Outbound flight': _s(reg['outboundFlightNo']),
          'Inbound terminal': _s(reg['inboundTerminal']),
          'Inbound flight': _s(reg['inboundFlightNo']),
        },
      ));
    }
    if (car.isNotEmpty) {
      out.add(_Section(
        icon: Icons.directions_car_outlined,
        title: 'Vehicle information',
        rows: {
          'Registration': _s(car['vehicleRegistration']),
          'Manufacturer': _s(car['vehicleManufacturer']),
          'Model': _s(car['vehicleModel']),
          'Colour': _s(car['vehicleColour']),
          'Passengers': _s(car['numberofPassengers']),
          'Type': _s(car['type']),
        },
      ));
    }
    if (pkg.isNotEmpty) {
      List<String> features = [];
      try {
        final raw = pkg['bulletPoints'];
        final list = raw is String ? jsonDecode(raw) : raw;
        if (list is List) features = list.map((e) => '$e').toList();
      } catch (_) {}
      out.add(_Section(
        icon: Icons.inventory_2_outlined,
        title: 'Package information',
        rows: {
          'Package': _s(pkg['title']),
          'Price': _s(pkg['price']).isEmpty ? '' : '£${_s(pkg['price'])}',
          'Description': _s(pkg['description']),
        },
        extra: features.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check,
                                    size: 16, color: kAdminGreen),
                                const SizedBox(width: 6),
                                Expanded(child: Text(f)),
                              ]),
                        ))
                    .toList()),
      ));
    }
    final assignments = b['bookingAssignments'] ?? b['BookingAssignments'];
    if (assignments is List && assignments.isNotEmpty) {
      final a = Map<String, dynamic>.from(assignments.first as Map);
      final e = a['employee'] is Map
          ? Map<String, dynamic>.from(a['employee'] as Map)
          : <String, dynamic>{};
      out.add(_Section(
        icon: Icons.badge_outlined,
        title: 'Driver',
        rows: {
          'Name': '${_s(e['firstName'])} ${_s(e['lastName'])}'.trim(),
          'Phone': _s(e['phoneNo']),
          'Job status': _s(a['status']),
        },
      ));
    }
    return out;
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Map<String, String> rows;
  final Widget? trailing;
  final Widget? extra;
  const _Section(
      {required this.icon,
      required this.title,
      required this.rows,
      this.trailing,
      this.extra});

  @override
  Widget build(BuildContext context) {
    final shown = rows.entries.where((e) => e.value.trim().isNotEmpty);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: kAdminGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15))),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 8),
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 130,
                      child: Text(e.key,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13))),
                  Expanded(
                      child: SelectableText(e.value,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          if (extra != null) extra!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Edit

/// Loads nothing: [booking] is the detail map. Returns true when saved.
Future<bool> openAdminBookingEdit(
    BuildContext context, Map<String, dynamic> booking) async {
  final r = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AdminBookingEditScreen(booking: booking)));
  return r == true;
}

/// Fetches the full booking first, then opens the edit form.
Future<bool> openAdminBookingEditById(
    BuildContext context, String bookingId) async {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: kAdminGreen)));
  Map<String, dynamic>? b;
  String? err;
  try {
    b = await _repo.adminBookingDetail(bookingId);
  } catch (e) {
    err = '$e';
  }
  if (!context.mounted) return false;
  Navigator.pop(context);
  if (b == null) {
    _snack(context, err ?? 'Could not load the booking');
    return false;
  }
  return openAdminBookingEdit(context, b);
}

class AdminBookingEditScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const AdminBookingEditScreen({super.key, required this.booking});

  @override
  State<AdminBookingEditScreen> createState() => _AdminBookingEditScreenState();
}

class _AdminBookingEditScreenState extends State<AdminBookingEditScreen> {
  static const _airports = [
    'Stansted',
    'Luton',
    'Bristol',
    'Heathrow',
    'Gatwick',
    'Manchester',
    'Birmingham',
    'Edinburgh',
    'Glasgow',
  ];
  static const _statuses = [
    'Pending',
    'Confirmed',
    'Inprogress',
    'Completed',
    'Cancelled',
  ];

  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {};
  late String _startDate, _endDate, _startTime, _endTime, _airport, _status;
  bool _saving = false;

  TextEditingController _ctl(String key, dynamic value) =>
      _c[key] = TextEditingController(text: _s(value));

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    final reg = _reg(b);
    final car = _car(b);
    _startDate = _s(b['startDate']);
    _endDate = _s(b['endDate']);
    _startTime = _s(b['startTime']);
    _endTime = _s(b['endTime']);
    _airport = _s(b['airport']);
    _status = _s(b['status']);
    for (final k in [
      'firstName',
      'lastName',
      'email',
      'phoneNo',
      'outboundTerminal',
      'outboundFlightNo',
      'inboundTerminal',
      'inboundFlightNo',
    ]) {
      _ctl(k, reg[k]);
    }
    for (final k in [
      'vehicleRegistration',
      'vehicleManufacturer',
      'vehicleModel',
      'vehicleColour',
      'numberofPassengers',
      'type',
    ]) {
      _ctl(k, car[k]);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Dates are "yyyy-MM-dd" (sometimes with a time part); times "h:mm AM".
  DateTime? _parseDate(String s) => DateTime.tryParse(s.split('T').first);

  TimeOfDay? _parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(s.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h % 24, minute: min);
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickDate(bool start) async {
    final cur = _parseDate(start ? _startDate : _endDate) ?? DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: cur,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d == null) return;
    final v = DateFormat('yyyy-MM-dd').format(d);
    setState(() => start ? _startDate = v : _endDate = v);
  }

  Future<void> _pickTime(bool start) async {
    final cur = _parseTime(start ? _startTime : _endTime) ??
        const TimeOfDay(hour: 12, minute: 0);
    final t = await showTimePicker(context: context, initialTime: cur);
    if (t == null) return;
    setState(() => start ? _startTime = _fmtTime(t) : _endTime = _fmtTime(t));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_startDate.isEmpty || _endDate.isEmpty) {
      _snack(context, 'Start and end dates are required');
      return;
    }
    if (_airport.isEmpty || _status.isEmpty) {
      _snack(context, 'Choose the airport and status');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.adminUpdateBooking({
        'bookingId': _s(widget.booking['id']),
        'startDate': _startDate.split('T').first,
        'endDate': _endDate.split('T').first,
        'startTime': _startTime,
        'endTime': _endTime,
        'airport': _airport,
        'status': _status,
        for (final e in _c.entries) e.key: e.value.text.trim(),
      });
      if (!mounted) return;
      _snack(context, 'Booking updated');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _s(widget.booking['referenceNo']);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(ref.isEmpty ? 'Edit booking' : 'Edit #$ref'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _box('Booking details', [
              _pickerTile('Start date', _startDate, () => _pickDate(true)),
              _pickerTile('Start time', _startTime, () => _pickTime(true)),
              _pickerTile('End date', _endDate, () => _pickDate(false)),
              _pickerTile('End time', _endTime, () => _pickTime(false)),
              _dropdown('Airport', _airport, _airports,
                  (v) => setState(() => _airport = v)),
              _dropdown('Status', _status, _statuses,
                  (v) => setState(() => _status = v)),
            ]),
            _box('Customer details', [
              _field('firstName', 'First name', required: true),
              _field('lastName', 'Last name', required: true),
              _field('email', 'Email',
                  required: true, keyboard: TextInputType.emailAddress),
              _field('phoneNo', 'Phone',
                  required: true, keyboard: TextInputType.phone),
            ]),
            _box('Flight details', [
              _field('outboundTerminal', 'Outbound terminal'),
              _field('outboundFlightNo', 'Outbound flight no'),
              _field('inboundTerminal', 'Inbound terminal'),
              _field('inboundFlightNo', 'Inbound flight no'),
            ]),
            _box('Vehicle details', [
              _field('vehicleRegistration', 'Registration', required: true),
              _field('vehicleManufacturer', 'Manufacturer'),
              _field('vehicleModel', 'Model'),
              _field('vehicleColour', 'Colour'),
              _field('numberofPassengers', 'Passengers',
                  keyboard: TextInputType.number),
              _field('type', 'Type'),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kAdminGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Save changes'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _field(String key, String label,
          {bool required = false, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: _c[key],
          keyboardType: keyboard,
          decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder()),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );

  Widget _pickerTile(String label, String value, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 20)),
            child: Text(value.isEmpty ? '-' : value.split('T').first),
          ),
        ),
      );

  Widget _dropdown(String label, String value, List<String> options,
      ValueChanged<String> onChanged) {
    final all = [...options];
    if (value.isNotEmpty && !all.contains(value)) all.insert(0, value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        isDense: true,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        items: all
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Email

/// "Send booking confirmation email" to the customer or another address.
Future<void> showAdminSendBookingEmail(BuildContext context,
    {required String bookingId,
    String referenceNo = '',
    String customerEmail = ''}) async {
  final other = TextEditingController();
  bool useExisting = true;
  bool sending = false;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Send email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Send the booking confirmation email${referenceNo.isEmpty ? '' : ' for #$referenceNo'}.'),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: useExisting,
              activeColor: kAdminGreen,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Send to the customer\'s email'),
              subtitle: Text(
                  customerEmail.isEmpty ? 'No email found' : customerEmail),
              onChanged: (v) => setD(() => useExisting = v ?? true),
            ),
            if (!useExisting)
              TextField(
                controller: other,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Recipient email',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kAdminGreen),
            onPressed: sending
                ? null
                : () async {
                    final to = other.text.trim();
                    if (!useExisting &&
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(to)) {
                      _snack(context, 'Enter a valid email address');
                      return;
                    }
                    setD(() => sending = true);
                    try {
                      await _repo.adminSendBookingEmail(bookingId,
                          email: useExisting ? '' : to);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) _snack(context, 'Email sent');
                    } catch (e) {
                      setD(() => sending = false);
                      if (context.mounted) _snack(context, '$e');
                    }
                  },
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: const Text('Send'),
          ),
        ],
      ),
    ),
  );
}
