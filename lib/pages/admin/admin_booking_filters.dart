import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/pages/admin/admin_list_parts.dart';

/// The website admin Bookings filters, plus the date the booking was created.
/// Values are what POST /booking/list expects; empty ones are not sent.
class AdminBookingFilters {
  String referenceNo = '';
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String vehicleReg = '';
  DateTime? startDate; // booking starts on/after
  DateTime? endDate; // booking ends on/before
  TimeOfDay? startTime; // starts at/after
  TimeOfDay? endTime; // ends at/before
  String? service; // "Meet and Greet" / "Park and Ride"
  String? month; // "January"...
  int? year;
  String? airport;
  String? company;
  DateTime? createdFrom;
  DateTime? createdTo;

  AdminBookingFilters();

  AdminBookingFilters copy() => AdminBookingFilters()
    ..referenceNo = referenceNo
    ..firstName = firstName
    ..lastName = lastName
    ..email = email
    ..phone = phone
    ..vehicleReg = vehicleReg
    ..startDate = startDate
    ..endDate = endDate
    ..startTime = startTime
    ..endTime = endTime
    ..service = service
    ..month = month
    ..year = year
    ..airport = airport
    ..company = company
    ..createdFrom = createdFrom
    ..createdTo = createdTo;

  static final _ymd = DateFormat('yyyy-MM-dd');
  static String _hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toParams() => {
        'referenceNo': referenceNo.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'vehicleReg': vehicleReg.trim(),
        if (startDate != null) 'startDate': _ymd.format(startDate!),
        if (endDate != null) 'endDate': _ymd.format(endDate!),
        if (startTime != null) 'startTime': _hm(startTime!),
        if (endTime != null) 'endTime': _hm(endTime!),
        'service': service,
        'month': month,
        'year': year,
        'airport': airport,
        'company': company,
        // Whole days in the viewer's own timezone, sent as exact moments
        if (createdFrom != null)
          'createdFrom':
              DateTime(createdFrom!.year, createdFrom!.month, createdFrom!.day)
                  .toUtc()
                  .toIso8601String(),
        if (createdTo != null)
          'createdTo': DateTime(
                  createdTo!.year, createdTo!.month, createdTo!.day, 23, 59, 59)
              .toUtc()
              .toIso8601String(),
      };

  int get activeCount =>
      [
        referenceNo.trim(),
        firstName.trim(),
        lastName.trim(),
        email.trim(),
        phone.trim(),
        vehicleReg.trim(),
      ].where((s) => s.isNotEmpty).length +
      [
        startDate,
        endDate,
        startTime,
        endTime,
        month,
        year,
        airport,
        company,
        service,
        createdFrom,
        createdTo
      ].where((v) => v != null).length;

  /// Stable text for the list key, so the list reloads when filters change.
  String get key => toParams().toString();
}

const _airports = [
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

const _services = ['Meet and Greet', 'Park and Ride'];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Opens the filters sheet. Returns the new filters, or null if closed.
Future<AdminBookingFilters?> showAdminBookingFilters(BuildContext context,
    {required AdminBookingFilters current, required List<String> companies}) {
  return showModalBottomSheet<AdminBookingFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _FiltersSheet(current: current.copy(), companies: companies),
  );
}

class _FiltersSheet extends StatefulWidget {
  final AdminBookingFilters current;
  final List<String> companies;
  const _FiltersSheet({required this.current, required this.companies});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late AdminBookingFilters f = widget.current;
  int _resets = 0;
  static final _show = DateFormat('dd/MM/yyyy');

  Future<DateTime?> _pick(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );

  @override
  Widget build(BuildContext context) {
    final years = List.generate(10, (i) => DateTime.now().year - 5 + i);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(children: [
                const Expanded(
                    child: Text('Filters',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => setState(() {
                    f = AdminBookingFilters();
                    _resets++; // rebuild the text boxes empty
                  }),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reset all'),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _heading('Quick search'),
                  _text('Booking reference', f.referenceNo,
                      (v) => f.referenceNo = v),
                  _text('First name', f.firstName, (v) => f.firstName = v),
                  _text('Last name', f.lastName, (v) => f.lastName = v),
                  _text('Email', f.email, (v) => f.email = v,
                      keyboard: TextInputType.emailAddress),
                  _text('Phone', f.phone, (v) => f.phone = v,
                      keyboard: TextInputType.phone),
                  _text('Vehicle registration', f.vehicleReg,
                      (v) => f.vehicleReg = v),
                  _heading('Booking dates'),
                  _date('Start date (from)', f.startDate,
                      (d) => setState(() => f.startDate = d)),
                  _date('End date (to)', f.endDate,
                      (d) => setState(() => f.endDate = d)),
                  Row(children: [
                    Expanded(
                        child: _time('Start time (from)', f.startTime,
                            (t) => setState(() => f.startTime = t))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _time('End time (to)', f.endTime,
                            (t) => setState(() => f.endTime = t))),
                  ]),
                  Row(children: [
                    Expanded(
                        child: _drop<String>('Month', f.month, _months,
                            (v) => setState(() => f.month = v))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _drop<int>('Year', f.year, years,
                            (v) => setState(() => f.year = v))),
                  ]),
                  _heading('Created on'),
                  _date('Created from', f.createdFrom,
                      (d) => setState(() => f.createdFrom = d)),
                  _date('Created to', f.createdTo,
                      (d) => setState(() => f.createdTo = d)),
                  _heading('Location, service and company'),
                  _drop<String>('Airport', f.airport, _airports,
                      (v) => setState(() => f.airport = v)),
                  _drop<String>('Service', f.service, _services,
                      (v) => setState(() => f.service = v)),
                  _drop<String>('Company', f.company, widget.companies,
                      (v) => setState(() => f.company = v)),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: kAdminGreen,
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.pop(context, f),
                  child: const Text('Apply filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
      );

  Widget _text(String label, String value, ValueChanged<String> onChanged,
          {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          key: ValueKey('$label|$_resets'),
          initialValue: value,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder()),
        ),
      );

  Widget _date(String label, DateTime? value, ValueChanged<DateTime?> onSet) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () async {
            final d = await _pick(value);
            if (d != null) onSet(d);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: value == null
                  ? const Icon(Icons.calendar_today_outlined, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onSet(null)),
            ),
            child: Text(value == null ? 'Any' : _show.format(value),
                style: TextStyle(
                    color: value == null ? Colors.grey.shade600 : null)),
          ),
        ),
      );

  Widget _time(
          String label, TimeOfDay? value, ValueChanged<TimeOfDay?> onSet) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () async {
            final t = await showTimePicker(
                context: context,
                initialTime: value ?? const TimeOfDay(hour: 9, minute: 0));
            if (t != null) onSet(t);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: value == null
                  ? const Icon(Icons.schedule, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onSet(null)),
            ),
            child: Text(value == null ? 'Any' : value.format(context),
                style: TextStyle(
                    color: value == null ? Colors.grey.shade600 : null)),
          ),
        ),
      );

  Widget _drop<T>(String label, T? value, List<T> options,
          ValueChanged<T?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<T?>(
          key: ValueKey('$label|$value'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder()),
          items: [
            DropdownMenuItem<T?>(value: null, child: const Text('Any')),
            ...options.map((o) => DropdownMenuItem<T?>(
                value: o, child: Text('$o', overflow: TextOverflow.ellipsis))),
          ],
          onChanged: onChanged,
        ),
      );
}
