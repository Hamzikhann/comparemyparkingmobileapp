import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedAirport;
  final List<String> airportOptions = [
    'Stansted',
    'Bristol',
    'Luton',
    'Birmingham',
    'Manchester',
    'Gatwick',
    'Heathrow',
    'Liverpool',
    'Southend'
  ];
  String? selectedDateRange;
  String? checkInTime;
  String? checkOutTime;
  DateTime? parsedStartDate;
  DateTime? parsedEndDate;
  TimeOfDay? parsedStartTime;
  TimeOfDay? parsedEndTime;
  Future<BookingResponse>? _bookingsFuture;
  final GeneralRepository _repository = GeneralRepository();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    try {
      setState(() {
        _bookingsFuture = _repository.getBookings().then((value) {
          GlobalsBookingDetail.reservedParkings = value.reservedParkings;
          return value;
        }).catchError((error) {
          throw error;
        });
      });
    } catch (e) {
      setState(() {
        _bookingsFuture = Future.error(e);
      });
    }
  }

  void _retryLoading() {
    _loadBookings();
  }

  void _showAirportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Airport',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo',
                ),
              ),
              SizedBox(height: 20.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: airportOptions
                        .map((airport) => ListTile(
                              title: Text(
                                airport,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'Archivo',
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedAirport = airport;
                                });
                                Navigator.pop(context);
                              },
                              trailing: selectedAirport == airport
                                  ? Icon(Icons.check, color: Color(0xFF4B725D))
                                  : null,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateAndTime({required bool isStart}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4B725D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4B725D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      if (isStart) {
        parsedStartDate = date;
        parsedStartTime = time;
      } else {
        parsedEndDate = date;
        parsedEndTime = time;
      }
    });
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

  void _handleSearch() {
    if (selectedAirport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an airport')),
      );
      return;
    }

    if (parsedStartDate == null || parsedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Check In date and time')),
      );
      return;
    }

    if (parsedEndDate == null || parsedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Check Out date and time')),
      );
      return;
    }

    // Logic to enforce End > Start if needed, but not strictly requested.

    Globals.startDate = _formatDateForApi(parsedStartDate!);
    Globals.endDate = _formatDateForApi(parsedEndDate!);
    Globals.startTime = _formatTimeForApi(parsedStartTime!);
    Globals.endTime = _formatTimeForApi(parsedEndTime!);
    Globals.selectedAirport = selectedAirport!;

    Navigator.pushNamed(
      context,
      MyRoutes.packagesScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile and notification
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundImage: AssetImage('assets/images/profilee.png'),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, MyRoutes.notifications);
                      },
                      icon: Icon(
                        Icons.notifications,
                        color: Color(0xFF4B725D),
                        size: 28.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Hero section with car
              Container(
                padding: EdgeInsets.all(0.w),
                decoration: BoxDecoration(
                  color: Color(0x0D214D53), // #214D530D
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car image
                    Image.asset(
                      'assets/images/home_image.png',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // Three buttons row
              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F3F5),
                  borderRadius: BorderRadius.circular(50.r),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Select Airport
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: _showAirportDialog,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50.r),
                            bottomLeft: Radius.circular(50.r),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                            child: Center(
                              child: Text(
                                selectedAirport ?? 'Select Airport',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontFamily: 'Archivo',
                                  color: selectedAirport != null
                                      ? Color(0xFF1A1A2E)
                                      : Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      VerticalDivider(
                        color: Color(0xFFD1D5DB),
                        thickness: 1,
                        indent: 12.h,
                        endIndent: 12.h,
                        width: 1,
                      ),

                      // Check In
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _pickDateAndTime(isStart: true),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 16.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  parsedStartDate != null
                                      ? DateFormat('dd MMM')
                                          .format(parsedStartDate!)
                                      : 'Check In',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontFamily: 'Archivo',
                                    color: parsedStartDate != null
                                        ? Color(0xFF1A1A2E)
                                        : Color(0xFF6B6B6B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (parsedStartTime != null)
                                  Text(
                                    parsedStartTime!.format(context),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontFamily: 'Archivo',
                                      color: Color(0xFF4B725D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      VerticalDivider(
                        color: Color(0xFFD1D5DB),
                        thickness: 1,
                        indent: 12.h,
                        endIndent: 12.h,
                        width: 1,
                      ),

                      // Check Out
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _pickDateAndTime(isStart: false),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 16.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  parsedEndDate != null
                                      ? DateFormat('dd MMM')
                                          .format(parsedEndDate!)
                                      : 'Check Out',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontFamily: 'Archivo',
                                    color: parsedEndDate != null
                                        ? Color(0xFF1A1A2E)
                                        : Color(0xFF6B6B6B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (parsedEndTime != null)
                                  Text(
                                    parsedEndTime!.format(context),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontFamily: 'Archivo',
                                      color: Color(0xFF4B725D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Search Button
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: InkWell(
                          onTap: _handleSearch,
                          customBorder: CircleBorder(),
                          child: Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Color(0xFF4B725D),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Booking History Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'See your Booking History',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontFamily: 'Archivo',
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Booking cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: FutureBuilder<BookingResponse>(
                  future: _bookingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    if (snapshot.hasData) {
                      final bookings = snapshot.data!.completedParkings;
                      if (bookings.isEmpty) {
                        return _noBookingCard();
                      }
                      return Column(
                        children: bookings.map((booking) {
                          return _buildBookingCard(booking);
                        }).toList(),
                      );
                    }
                    return _noBookingCard();
                  },
                ),
              ),

              SizedBox(height: 80.h), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
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

  Widget _buildBookingCard(Parking booking) {
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
                      index < 3 ? Icons.star : Icons.star_border,
                      color: Color(0xFFFFC107),
                      size: 20.sp,
                    );
                  }),
                ),
                // Book Again button
                GestureDetector(
                  onTap: () {
                    Globals.detailType = "reserved";
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

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            'Failed to load bookings',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: TextStyle(color: Colors.red),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _retryLoading,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noBookingCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48.sp,
              color: Color(0xFF6B6B6B),
            ),
            SizedBox(height: 16.h),
            Text(
              "No current bookings",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Archivo',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Book your parking space now",
              style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 14.sp,
                fontFamily: 'Archivo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
