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

  Widget _buildBookingCard(Parking booking, String type) {
    return Container(
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
