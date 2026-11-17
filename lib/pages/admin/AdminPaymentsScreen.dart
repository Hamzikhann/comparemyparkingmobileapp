import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/admin/admin_list_parts.dart';
import 'package:parkingapp/widgets/paged_list.dart';

/// Admin: all payments, newest first, 20 at a time (infinite scroll), with
/// search and an optional date range.
class AdminPaymentsScreen extends StatefulWidget {
  /// true when opened as its own page (shows a back button)
  final bool standalone;
  const AdminPaymentsScreen({super.key, this.standalone = false});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _repo = GeneralRepository();
  final _day = DateFormat('yyyy-MM-dd');
  String _search = '';
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  String get _rangeLabel => _range == null
      ? 'All dates'
      : _range!.start == _range!.end
          ? _day.format(_range!.start)
          : '${_day.format(_range!.start)} → ${_day.format(_range!.end)}';

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.standalone) adminTabTitle('Payments'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: AdminSearchBox(
            hint: 'Reference, customer, email or reg',
            onChanged: (t) => setState(() => _search = t),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            TextButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(_rangeLabel),
            ),
            if (_range != null)
              IconButton(
                tooltip: 'Clear dates',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _range = null),
              ),
          ]),
        ),
        Expanded(
          child: PagedList<Map<String, dynamic>>(
            key: ValueKey('payments|$_search|$_rangeLabel'),
            fetch: (offset, limit) => _repo.adminPaymentsPage(offset, limit,
                search: _search,
                startDate: _range == null ? null : _day.format(_range!.start),
                endDate: _range == null ? null : _day.format(_range!.end)),
            header: (total) => adminCountHeader(total, 'payments'),
            emptyText: 'No payments found',
            itemBuilder: (context, p, _) => _PaymentTile(payment: p),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.standalone
          ? AppBar(
              title: const Text('Payments'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0)
          : null,
      body: SafeArea(child: body),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final booking = payment['booking'] is Map
        ? Map<String, dynamic>.from(payment['booking'])
        : <String, dynamic>{};
    final regs = booking['registrations'];
    final reg = regs is List && regs.isNotEmpty ? Map<String, dynamic>.from(regs.first) : null;
    final name = reg == null
        ? ''
        : '${reg['firstName'] ?? ''} ${reg['lastName'] ?? ''}'.trim();
    final amount = double.tryParse('${payment['totalPayment'] ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), ''));
    final paidAt = DateTime.tryParse('${payment['createdAt'] ?? ''}')?.toLocal();
    final muted = TextStyle(color: Colors.grey.shade700, fontSize: 13);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(amount == null ? '£${payment['totalPayment'] ?? '-'}' : '£${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: kAdminGreen)),
            ),
            adminStatusPill('${booking['status'] ?? ''}'),
          ]),
          const SizedBox(height: 6),
          if (name.isNotEmpty)
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Booking ${booking['referenceNo'] ?? '-'} · ${booking['airport'] ?? ''}',
              style: muted),
          Text('${booking['startDate'] ?? ''} → ${booking['endDate'] ?? ''}',
              style: muted),
          const SizedBox(height: 4),
          Text(
              '${payment['paymentMethod'] ?? ''}${paidAt == null ? '' : ' · paid ${DateFormat('d MMM yyyy, h:mm a').format(paidAt)}'}',
              style: muted.copyWith(fontSize: 12)),
          if ('${payment['referenceNo'] ?? ''}'.isNotEmpty)
            Text('Ref: ${payment['referenceNo']}',
                style: muted.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
