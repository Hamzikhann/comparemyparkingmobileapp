import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/admin/admin_booking_actions.dart';
import 'package:parkingapp/pages/admin/admin_list_parts.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/paged_list.dart';

/// Admin: all bookings, newest first, 20 at a time (infinite scroll),
/// with one-box search and a status filter. Each card has the website's
/// actions: View details, Edit booking, Send email.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _repo = GeneralRepository();
  String _search = '';
  String? _status;
  int _reload = 0; // bump to reload the list after an edit

  static const _statuses = <String?, String>{
    null: 'All',
    'Pending': 'Pending',
    'Inprogress': 'In progress',
    'Started': 'Started',
    'Completed': 'Completed',
    'Claimed': 'Claimed',
  };

  void _open(Parking booking) {
    Globals.detailType = '';
    GlobalsBookingDetail.bookingdetailuser = booking;
    Navigator.pushNamed(context, MyRoutes.bookingDetailUser);
  }

  Future<void> _view(Parking b) async {
    final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => AdminBookingInfoScreen(
                bookingId: b.id, referenceNo: b.referenceNo)));
    if (changed == true && mounted) setState(() => _reload++);
  }

  Future<void> _edit(Parking b) async {
    if (await openAdminBookingEditById(context, b.id) && mounted) {
      setState(() => _reload++);
    }
  }

  void _email(Parking b) => showAdminSendBookingEmail(context,
      bookingId: b.id,
      referenceNo: b.referenceNo ?? '',
      customerEmail:
          b.registrations.isNotEmpty ? b.registrations.first.email : '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminTabTitle('Bookings'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AdminSearchBox(
                hint: 'Reference, name, email, phone or reg',
                onChanged: (t) => setState(() => _search = t),
              ),
            ),
            AdminFilterChips(
              options: _statuses,
              selected: _status,
              onSelected: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PagedList<Parking>(
                key: ValueKey('bookings|$_search|$_status|$_reload'),
                fetch: (offset, limit) => _repo.adminBookingsPage(offset, limit,
                    search: _search, status: _status),
                header: (total) => adminCountHeader(total, 'bookings'),
                emptyText: 'No bookings found',
                itemBuilder: (context, b, _) => _BookingTile(
                  booking: b,
                  onTap: () => _open(b),
                  onView: () => _view(b),
                  onEdit: () => _edit(b),
                  onEmail: () => _email(b),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Parking booking;
  final VoidCallback onTap, onView, onEdit, onEmail;
  const _BookingTile(
      {required this.booking,
      required this.onTap,
      required this.onView,
      required this.onEdit,
      required this.onEmail});

  @override
  Widget build(BuildContext context) {
    final reg = booking.registrations.isNotEmpty ? booking.registrations.first : null;
    final car = booking.vehicles.isNotEmpty ? booking.vehicles.first : null;
    final driver = booking.bookingAssignments.isNotEmpty
        ? booking.bookingAssignments.first.employee
        : null;
    final name = reg == null ? '' : '${reg.firstName} ${reg.lastName}'.trim();
    final muted = TextStyle(color: Colors.grey.shade700, fontSize: 13);

    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(booking.referenceNo ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            adminStatusPill(booking.status),
          ]),
          const SizedBox(height: 6),
          if (name.isNotEmpty)
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '${booking.airport}${booking.packageType.isNotEmpty ? ' · ${booking.packageType}' : ''}',
              style: muted),
          Text(
              '${booking.startDate} ${booking.startTime}  →  ${booking.endDate} ${booking.endTime}',
              style: muted),
          if (car != null && car.vehicleRegistration.isNotEmpty)
            Text('Vehicle: ${car.vehicleRegistration}', style: muted),
          Text(
              driver == null
                  ? 'No driver assigned'
                  : 'Driver: ${driver.firstName} ${driver.lastName}',
              style: muted.copyWith(
                  color: driver == null ? Colors.orange.shade800 : null)),
          const Divider(height: 18),
          Row(children: [
            _action(Icons.visibility_outlined, 'View', onView),
            _action(Icons.edit_outlined, 'Edit', onEdit),
            _action(Icons.mail_outline, 'Email', onEmail),
          ]),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: TextButton.icon(
          style: TextButton.styleFrom(
              foregroundColor: kAdminGreen,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
}
