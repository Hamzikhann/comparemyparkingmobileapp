import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/pages/ViewallScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:intl/intl.dart';
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

  void _viewAll(String type, List<Parking> parkings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllScreen(title: type, parkings: parkings),
      ),
    );
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
    if (parkings.isEmpty) return SizedBox();

    final first = parkings.first;

    String type = 'reserved';
    if (title.contains('Pending')) {
      type = 'pending';
    } else if (title.contains('Completed')) {
      type = 'completed';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookingCard(first, type),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, Parking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Archivo',
                              color: booking.status.toLowerCase() == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
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
                Text(
                  'From ${booking.startTime} to ${booking.endTime}, ${_formatDate(booking.startDate)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Archivo',
                    color: Color(0xFF6B6B6B),
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
}
