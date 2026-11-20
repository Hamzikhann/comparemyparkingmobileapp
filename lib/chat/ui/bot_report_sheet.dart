import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/chat/chat_api.dart';
import 'package:parkingapp/utils/colors.dart';

/// "Request report" button shown above the composer in the admin's chat with
/// the Reports Bot. The request and the bot's replies (and later the file)
/// arrive as normal chat messages.
class BotReportBar extends StatelessWidget {
  final ChatApi api;
  const BotReportBar({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primaryNew,
            side: BorderSide(color: colors.primaryNew),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
          ),
          icon: const Icon(Icons.summarize_outlined),
          label: Text('Request report',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
            builder: (_) => _ReportForm(api: api),
          ),
        ),
      ),
    );
  }
}

class _ReportForm extends StatefulWidget {
  final ChatApi api;
  const _ReportForm({required this.api});

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  static const _formats = [('pdf', 'PDF'), ('xlsx', 'Excel'), ('csv', 'CSV')];
  static final _api = DateFormat('yyyy-MM-dd');
  static final _show = DateFormat('dd MMM yyyy');

  List<(int, String)>? _airports;
  String? _loadError;
  int? _airportId;
  DateTime? _from;
  DateTime? _to;
  String _format = 'xlsx';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() => _loadError = null);
    try {
      final list = await widget.api.botAirports();
      if (!mounted) return;
      setState(() {
        _airports = list;
        if (list.length == 1) _airportId = list.first.$1;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _pick(bool from) async {
    final now = DateTime.now();
    final initial = (from ? _from : _to) ?? _from ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: from ? 'From date' : 'To date',
    );
    if (d == null || !mounted) return;
    setState(() {
      if (from) {
        _from = d;
        if (_to != null && _to!.isBefore(d)) _to = d;
      } else {
        _to = d;
        if (_from != null && _from!.isAfter(d)) _from = d;
      }
    });
  }

  bool get _ready =>
      _airportId != null && _from != null && _to != null && !_sending;

  Future<void> _submit() async {
    final airport = _airports!.firstWhere((a) => a.$1 == _airportId);
    setState(() => _sending = true);
    try {
      await widget.api.botReportRequest(
        airportId: airport.$1,
        airportName: airport.$2,
        fromDate: _api.format(_from!),
        toDate: _api.format(_to!),
        format: _format,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(top: 14.h, bottom: 6.h),
        child: Text(t,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
      );

  Widget _dateBox(String hint, DateTime? value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 18.sp, color: Colors.grey[600]),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(value == null ? hint : _show.format(value),
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: value == null ? Colors.grey[500] : Colors.black87)),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final airports = _airports;
    return Padding(
      padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request a booking report',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),
            Text(
                'Large reports can take a few minutes. The bot sends the file to this chat when it is ready.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
            _label('Airport'),
            if (_loadError != null)
              Row(children: [
                Expanded(
                    child: Text(_loadError!,
                        style: TextStyle(color: Colors.red, fontSize: 13.sp))),
                TextButton(onPressed: _loadAirports, child: const Text('Retry')),
              ])
            else if (airports == null)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                initialValue: _airportId,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Choose airport',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                items: [
                  for (final a in airports)
                    DropdownMenuItem(value: a.$1, child: Text(a.$2)),
                ],
                onChanged: (v) => setState(() => _airportId = v),
              ),
            _label('Dates'),
            Row(children: [
              Expanded(child: _dateBox('From', _from, () => _pick(true))),
              SizedBox(width: 10.w),
              Expanded(child: _dateBox('To', _to, () => _pick(false))),
            ]),
            _label('File type'),
            Wrap(spacing: 8.w, children: [
              for (final f in _formats)
                ChoiceChip(
                  label: Text(f.$2),
                  selected: _format == f.$1,
                  selectedColor: colors.primaryNew.withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => _format = f.$1),
                ),
            ]),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryNew,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                onPressed: _ready ? _submit : null,
                child: _sending
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Send request',
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
