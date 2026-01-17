import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';

import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/data/repositories/general_repository.dart'; // Import your repository

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<BookingResponse> _bookingsFuture;
  final GeneralRepository _repository =
      GeneralRepository(); // Initialize your repository

  @override
  void initState() {
    super.initState();
    _bookingsFuture =
        _repository.getBookings(); // Fetch bookings using the repository
  }

  void _onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: "Bookings",
              showBackButton: false,
              onBackPressed: () => _onBackPressed(context),
            ),
            Expanded(
              child: FutureBuilder<BookingResponse>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final reserved = snapshot.data!.reservedParkings;
                    final pending = snapshot.data!.pendingParkings;
                    final completed = snapshot.data!.completedParkings;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSection(
                              "Reserved Session", reserved, Icons.schedule),
                          buildSection("Pending Session", pending, Icons.star),
                          buildSection("Completed Sessions", completed,
                              Icons.check_circle),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  return Center();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSection(String title, List<Parking> parkings, IconData icon) {
    if (parkings.isEmpty) return const SizedBox.shrink();

    String type = 'reserved';
    if (title.contains('Pending')) {
      type = 'pending';
    } else if (title.contains('Completed')) {
      type = 'completed';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...parkings.map((booking) => _buildBookingCard(booking, type)).toList(),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, Parking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Center(
              child: Container(
                width: 60.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Booking Details",
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo',
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "ID: ${booking.id.substring(0, 8).toUpperCase()}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Archivo',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: booking.status.toLowerCase() == 'completed'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showUpdateBooking(context, booking);
                            },
                            child: Row(
                              children: [
                                Text(
                                  "EDIT",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Archivo',
                                    color: booking.status.toLowerCase() ==
                                            'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.edit,
                                    color: booking.status.toLowerCase() ==
                                            'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 16.sp),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Location Section
                    _buildSectionHeader("Location", Icons.location_on),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.flight_takeoff,
                                    color: Color(0xFF4B725D), size: 20.sp),
                              ),
                              SizedBox(width: 16.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.airport,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo',
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    "Terminal: ${booking.registrations.first.inboundTerminal}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: 'Archivo',
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Schedule Section
                    _buildSectionHeader("Timeline", Icons.access_time),
                    SizedBox(height: 16.h),
                    _buildTimelineItem(
                      title: "Drop-off",
                      date: booking.startDate,
                      time: booking.startTime,
                      isFirst: true,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      title: "Pick-up",
                      date: booking.endDate,
                      time: booking.endTime,
                      isFirst: false,
                      isLast: true,
                    ),
                    SizedBox(height: 24.h),

                    // Vehicle Section
                    _buildSectionHeader("Vehicle", Icons.directions_car),
                    SizedBox(height: 16.h),
                    if (booking.vehicles.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.directions_car_filled,
                                  color: Color(0xFF4B725D), size: 24.sp),
                            ),
                            SizedBox(width: 16.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.vehicles.first.vehicleRegistration,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Archivo',
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  "${booking.vehicles.first.vehicleManufacturer} ${booking.vehicles.first.vehicleModel}",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'Archivo',
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B725D),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Archivo',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Color(0xFF4B725D)),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Archivo',
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String time,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: Color(0xFF4B725D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4B725D).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontFamily: 'Archivo',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${_formatDate(date)} at $time",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                      fontFamily: 'Archivo',
                    ),
                  ),
                  if (true) // Just to keep spacing consistent
                    SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // This helper is deprecated by the new UI but kept if needed by other widgets,
    // though effectively unused in the new design.
    // We can just keep it or convert it.
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Parking booking, String type) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.airport,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Archivo',
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.directions_car,
                  color: Color(0xFF4B725D),
                  size: 24.sp,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: Color(0xFF6B6B6B),
                ),
                SizedBox(width: 4.w),
                Text(
                  booking.registrations.first.inboundTerminal,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Archivo',
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16.sp,
                  color: Color(0xFF6B6B6B),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'From ${_formatDate(booking.startDate)} to ${_formatDate(booking.endDate)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: 'Archivo',
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Star rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < 4 ? Icons.star : Icons.star_border,
                      color: Color(0xFFFFC107),
                      size: 20.sp,
                    );
                  }),
                ),
                // Book Again button
                GestureDetector(
                  onTap: () {
                    Globals.detailType = type;
                    GlobalsBookingDetail.bookingdetailuser = booking;
                    Navigator.pushNamed(
                      context,
                      MyRoutes.bookingDetailUser,
                    );
                  },
                  child: Text(
                    'Booked',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                      color: Color(0xFF4B725D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM (EEEE)').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showUpdateBooking(BuildContext screenContext, Parking booking) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime? updateStartDate = DateTime.tryParse(booking.startDate);
    DateTime? updateEndDate = DateTime.tryParse(booking.endDate);
    TimeOfDay _robustTimeParse(String timeStr) {
      try {
        final sanitized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();
        return TimeOfDay.fromDateTime(DateFormat.jm().parse(sanitized));
      } catch (e) {
        try {
          final sanitized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();
          return TimeOfDay.fromDateTime(DateFormat("h:mm a").parse(sanitized));
        } catch (e2) {
          final parts = timeStr.split(RegExp(r'[:\s\u00A0\u202F]'));
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          bool isPm = timeStr.toUpperCase().contains('PM');
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    TimeOfDay updateStartTime = _robustTimeParse(booking.startTime);
    TimeOfDay updateEndTime = _robustTimeParse(booking.endTime);

    Widget _buildNoteText(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF856404))),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF856404)))),
          ],
        ),
      );
    }

    Widget _buildUpdatePicker(BuildContext context, String label,
        DateTime? date, TimeOfDay? time, VoidCallback onTap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null && time != null
                        ? "${DateFormat('dd MMM yyyy').format(date)} at ${time.format(context)}"
                        : "Select Date & Time",
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.calendar_today,
                      size: 20.sp, color: const Color(0xFF4B725D)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    int _calculateAdditionalDays() {
      if (updateStartDate == null || updateEndDate == null) return 0;

      final originalStart = DateTime.parse(booking.startDate);
      final originalEnd = DateTime.parse(booking.endDate);
      final originalDays = originalEnd.difference(originalStart).inDays + 1;

      final newDays = updateEndDate!.difference(updateStartDate!).inDays + 1;

      return (newDays - originalDays).clamp(0, 100);
    }

    double _calculateTotalCost() {
      int extraDays = _calculateAdditionalDays();
      return 20.0 + (extraDays * 15.0);
    }

    Future<void> _handleUpdatePayment(
        String paymentId, double totalCost, StateSetter setState) async {
      final messenger = ScaffoldMessenger.of(this.context);
      final navigator = Navigator.of(this.context);

      try {
        await _repository.updateBooking(
          bookingId: booking.id,
          startDate: _formatDateForApi(updateStartDate!),
          startTime: _formatTimeForApi(updateStartTime),
          endDate: _formatDateForApi(updateEndDate!),
          endTime: _formatTimeForApi(updateEndTime),
          paymentMethod: "card",
          totalPayment: totalCost.toStringAsFixed(2),
          referenceNo: "STRIPE-$paymentId",
        );

        if (!mounted) return;

        // Dismiss both sheets safely
        if (navigator.canPop()) navigator.pop(); // Close update sheet
        if (navigator.canPop()) navigator.pop(); // Close details sheet

        // Show Success Dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4B725D), size: 64.sp),
                SizedBox(height: 16.h),
                Text(
                  "Update Successful",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Your booking has been updated and paid successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Archivo',
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B725D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text("OK",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );

        // Refresh Main Screen Data
        this.setState(() {
          _bookingsFuture = _repository.getBookings();
        });
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text("Update failed: $e")),
        );
      }
    }

    Future<void> _startUpdatePayment(
        double totalCost, StateSetter setState) async {
      final localMessenger = ScaffoldMessenger.of(this.context);
      try {
        final amountInPence = (totalCost).toInt().toString();

        final response = await _repository.createPaymentIntent(
          amount: amountInPence,
          currency: "gbp",
          startDate: _formatDateForApi(updateStartDate!),
          endDate: _formatDateForApi(updateEndDate!),
        );

        final clientSecret = response['paymentIntent']?['client_secret'] ??
            response['clientSecret'];
        if (clientSecret == null)
          throw Exception('Missing client secret in response');

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Parking Pilot',
            style: ThemeMode.system,
            allowsDelayedPaymentMethods: false,
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        if (!mounted) return;

        final paymentId =
            (response['paymentIntent']?['id'] ?? response['paymentId'])
                .toString();

        await _handleUpdatePayment(paymentId, totalCost, setState);
      } catch (e) {
        if (!mounted) return;
        if (e is StripeException) {
          if (e.error.code != FailureCode.Canceled) {
            localMessenger.showSnackBar(SnackBar(
                content: Text("Payment error: ${e.error.localizedMessage}")));
          }
        } else {
          localMessenger.showSnackBar(
              SnackBar(content: Text("Payment failed: ${e.toString()}")));
        }
      }
    }

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) {
          double totalCost = _calculateTotalCost();
          int extraDays = _calculateAdditionalDays();

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                    width: 60.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5.r))),
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Update Booking",
                            style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A2E))),
                        SizedBox(height: 24.h),
                        _buildUpdatePicker(
                          context,
                          "New Drop-off",
                          updateStartDate,
                          updateStartTime,
                          () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: (updateStartDate != null &&
                                      !updateStartDate!.isBefore(today))
                                  ? updateStartDate!
                                  : today,
                              firstDate: today,
                              lastDate: today.add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: const Color(0xFF4B725D),
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: updateStartTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: const Color(0xFF4B725D),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  updateStartDate = date;
                                  updateStartTime = time;
                                });
                              }
                            }
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildUpdatePicker(
                          context,
                          "New Pick-up",
                          updateEndDate,
                          updateEndTime,
                          () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: (updateEndDate != null &&
                                      !updateEndDate!
                                          .isBefore(updateStartDate ?? today))
                                  ? updateEndDate!
                                  : (updateStartDate ?? today),
                              firstDate: updateStartDate ?? today,
                              lastDate: today.add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: const Color(0xFF4B725D),
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: updateEndTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: const Color(0xFF4B725D),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  updateEndDate = date;
                                  updateEndTime = time;
                                });
                              }
                            }
                          },
                        ),
                        SizedBox(height: 30.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Booking Update Charges",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: const Color(0xFF856404))),
                              SizedBox(height: 8.h),
                              _buildNoteText(
                                  "A fixed update fee of £20 applies to every booking modification."),
                              _buildNoteText(
                                  "Each additional day costs an extra £15."),
                              _buildNoteText(
                                  "No refunds are provided for reduced booking days."),
                              const Divider(color: Color(0xFFFFE082)),
                              Text(
                                "Total Update Cost: £20 + (£15 × $extraDays extra days) = £${totalCost.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                    color: const Color(0xFF856404)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _startUpdatePayment(totalCost, setState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B725D),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text(
                              "Pay & Update Booking",
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
