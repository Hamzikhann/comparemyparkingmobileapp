import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/airport_service_config.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/pages/EditProfile.dart';

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
    if (Globals.user == null) {
      setState(() {
        _bookingsFuture = Future.value(BookingResponse(
          reservedParkings: [],
          pendingParkings: [],
          completedParkings: [],
        ));
      });
      return;
    }
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
                                  ? Icon(Icons.check, color: colors.primaryNew)
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime initialDate = today;
    DateTime firstDate = today;

    if (isStart) {
      if (parsedStartDate != null) {
        initialDate = parsedStartDate!;
      }
    } else {
      if (parsedStartDate != null) {
        // Calculate the minimum valid end datetime (Start + 2 hours)
        DateTime minEndDateTime = parsedStartDate!;
        if (parsedStartTime != null) {
          final startDateTime = DateTime(
            parsedStartDate!.year,
            parsedStartDate!.month,
            parsedStartDate!.day,
            parsedStartTime!.hour,
            parsedStartTime!.minute,
          );
          final validEndDateTime = startDateTime.add(const Duration(hours: 2));
          // The first allowable date is the date part of (Start + 2h)
          // This handles the case where Start + 2h pushes into the next day.
          minEndDateTime = DateTime(validEndDateTime.year,
              validEndDateTime.month, validEndDateTime.day);
        }

        firstDate = minEndDateTime;
      }

      if (parsedEndDate != null) {
        initialDate = parsedEndDate!;
      } else {
        initialDate = firstDate;
      }
    }

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;

    final DateTime? date = await _showDatePickerBottomSheet(
      context,
      initialDate,
      firstDate,
    );

    if (date == null) return;

    // Calculate initial time for picker to suggest a valid time
    TimeOfDay initialTime = TimeOfDay.now();
    if (!isStart && parsedStartDate != null && parsedStartTime != null) {
      final startDateTime = DateTime(
        parsedStartDate!.year,
        parsedStartDate!.month,
        parsedStartDate!.day,
        parsedStartTime!.hour,
        parsedStartTime!.minute,
      );
      final targetDateTime = startDateTime.add(const Duration(hours: 2));

      if (date.year == targetDateTime.year &&
          date.month == targetDateTime.month &&
          date.day == targetDateTime.day) {
        initialTime =
            TimeOfDay(hour: targetDateTime.hour, minute: targetDateTime.minute);
      }
    }

    final TimeOfDay? time = await _showTimePickerBottomSheet(
      context,
      initialTime,
    );

    if (time == null) return;

    setState(() {
      if (isStart) {
        parsedStartDate = date;
        parsedStartTime = time;
        if (parsedEndDate != null && parsedStartDate!.isAfter(parsedEndDate!)) {
          parsedEndDate = null;
          parsedEndTime = null;
        }
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
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

    if (parsedEndDate!.isBefore(parsedStartDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('End date must be greater than or equal to start date')),
      );
      return;
    }

    final startDateTime = DateTime(
      parsedStartDate!.year,
      parsedStartDate!.month,
      parsedStartDate!.day,
      parsedStartTime!.hour,
      parsedStartTime!.minute,
    );
    final endDateTime = DateTime(
      parsedEndDate!.year,
      parsedEndDate!.month,
      parsedEndDate!.day,
      parsedEndTime!.hour,
      parsedEndTime!.minute,
    );

    if (parsedStartDate!.isAtSameMomentAs(parsedEndDate!)) {
      final difference = endDateTime.difference(startDateTime);
      if (difference.inHours < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'If start and end dates are the same, time difference must be at least 2 hours')),
        );
        return;
      }
    }

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
      backgroundColor: Colors.white,
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
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Editprofile()),
                        );
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22.r,
                            backgroundImage: (Globals.user?.imageURL != null &&
                                    Globals.user!.imageURL!.isNotEmpty)
                                ? (Globals.user!.imageURL!.startsWith('http')
                                    ? NetworkImage(Globals.user!.imageURL!)
                                    : FileImage(File(Globals.user!.imageURL!))
                                        as ImageProvider)
                                : const AssetImage('assets/images/user.png'),
                          ),
                          SizedBox(width: 10.w),
                          if (Globals.user?.firstName != null &&
                              Globals.user!.firstName.isNotEmpty)
                            Text(
                              Globals.user!.firstName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo',
                                color: colors.primaryNew,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (Globals.user != null)
                      IconButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                              context, MyRoutes.notifications);
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                        icon: Icon(
                          Icons.notifications,
                          color: colors.primaryNew,
                          size: 28.sp,
                        ),
                      ),
                  ],
                ),
              ),

              // Hero section with car
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(left: 20.w, top: 40.h, bottom: 20.h),
                decoration: BoxDecoration(
                  color: colors.primaryNew,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r),
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Where would\nyou like to\nPark?',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Archivo',
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 60.h),
                      ],
                    ),
                    Positioned(
                      right: -30.w,
                      bottom: -70.h,
                      child: Image.asset(
                        'assets/images/car.png',
                        width: 290.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // Three buttons row
              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
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
                                horizontal: 4.w, vertical: 4.h),
                            child: Center(
                              child: Text(
                                selectedAirport ?? 'Select Airport',
                                style: TextStyle(
                                  fontSize: 12.sp,
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
                                      color: colors.primaryNew,
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
                                      color: colors.primaryNew,
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
                              color: colors.primaryNew,
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

              SizedBox(height: 16.h),

              // Promo Code Field
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
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
                child: TextFormField(
                  initialValue: Globals.promoCode,
                  onChanged: (value) {
                    Globals.promoCode = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Promo Code (Optional)',
                    hintStyle: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                    ),
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: colors.primaryNew,
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
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
    final packageType = Globals.option?.type ?? 'meet and greet';
    final serviceInfo = getAirportServiceInfo(
      booking.airport,
      packageType,
    );

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
                              "ID: ${booking.referenceNo?.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 10.sp,
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
                                    color: colors.primaryNew, size: 20.sp),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
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
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Outbound Terminal: ${booking.registrations.first.outboundTerminal}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "Outbound Flight: ${booking.registrations.first.outboundFlightNo}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Inbound Terminal: ${booking.registrations.first.inboundTerminal}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "Inbound Flight: ${booking.registrations.first.inboundFlightNo}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
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
                                  color: colors.primaryNew, size: 24.sp),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
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
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      _buildVehicleBadge(Icons.palette,
                                          booking.vehicles.first.vehicleColour),
                                      SizedBox(width: 8.w),
                                      _buildVehicleBadge(Icons.people,
                                          "${booking.vehicles.first.numberofPassengers} Passengers"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24.h),

                    // Service Information Section
                    if (serviceInfo != null ||
                        (booking.location != null &&
                            booking.location!.isNotEmpty) ||
                        (booking.contactNumber != null &&
                            booking.contactNumber!.isNotEmpty) ||
                        (booking.arrivalProcedure != null &&
                            booking.arrivalProcedure!.isNotEmpty) ||
                        (booking.departureProcedure != null &&
                            booking.departureProcedure!.isNotEmpty)) ...[
                      _buildSectionHeader(
                          "Service Information", Icons.info_outline),
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contact Number Logic
                            Builder(builder: (context) {
                              String? contactNumber = booking.contactNumber;
                              if (contactNumber == null ||
                                  contactNumber.isEmpty) {
                                if (serviceInfo != null &&
                                    serviceInfo['contact'] != null) {
                                  contactNumber =
                                      serviceInfo['contact']['number'];
                                }
                              }

                              if (contactNumber != null &&
                                  contactNumber.isNotEmpty) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            color: colors.primaryNew,
                                            size: 18.sp),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Contact Number",
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontFamily: 'Archivo',
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                contactNumber,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Archivo',
                                                  color: Color(0xFF1A1A2E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }),

                            // Location Logic
                            Builder(builder: (context) {
                              String? locationAddress = booking.location;
                              if (locationAddress == null ||
                                  locationAddress.isEmpty) {
                                if (serviceInfo != null &&
                                    serviceInfo['location'] != null) {
                                  locationAddress =
                                      serviceInfo['location']['address'];
                                }
                              }

                              if (locationAddress != null &&
                                  locationAddress.isNotEmpty) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on,
                                            color: colors.primaryNew,
                                            size: 18.sp),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Service Location",
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontFamily: 'Archivo',
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                locationAddress,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Archivo',
                                                  color: Color(0xFF1A1A2E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 20.h),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }),

                            // Arrival Procedure Logic
                            Builder(builder: (context) {
                              String? arrivalProcedure =
                                  booking.arrivalProcedure;
                              if (arrivalProcedure == null ||
                                  arrivalProcedure.isEmpty) {
                                if (serviceInfo != null) {
                                  arrivalProcedure =
                                      serviceInfo['arrival_procedure'];
                                }
                              }

                              if (arrivalProcedure != null &&
                                  arrivalProcedure.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Arrival Procedure",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Archivo',
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      arrivalProcedure,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }),

                            // Departure Procedure Logic
                            Builder(builder: (context) {
                              String? departureProcedure =
                                  booking.departureProcedure;
                              if (departureProcedure == null ||
                                  departureProcedure.isEmpty) {
                                if (serviceInfo != null) {
                                  departureProcedure =
                                      serviceInfo['departure_procedure'];
                                }
                              }

                              if (departureProcedure != null &&
                                  departureProcedure.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Departure Procedure",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Archivo',
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      departureProcedure,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'Archivo',
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }),
                          ],
                        ),
                      ),
                    ],
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
                    backgroundColor: colors.primaryNew,
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
        Icon(icon, size: 20.sp, color: colors.primaryNew),
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

  Widget _buildVehicleBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.primaryNew.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: colors.primaryNew),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Archivo',
              color: colors.primaryNew,
            ),
          ),
        ],
      ),
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
                    color: colors.primaryNew,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryNew.withOpacity(0.3),
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
                  color: colors.primaryNew,
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
                    final randomRating =
                        (Random(booking.id.hashCode).nextInt(3) + 3);
                    return Icon(
                      index < randomRating ? Icons.star : Icons.star_border,
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
                  },
                  child: Text(
                    'Booked',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                      color: colors.primaryNew,
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
              "No Booking History",
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

  void _showUpdateBooking(BuildContext screenContext, Parking booking) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime? updateStartDate = DateTime.tryParse(booking.startDate);
    DateTime? updateEndDate = DateTime.tryParse(booking.endDate);
    TimeOfDay _robustTimeParse(String timeStr) {
      try {
        // Replace any whitespace/invisible characters with standard space
        final sanitized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();
        return TimeOfDay.fromDateTime(DateFormat.jm().parse(sanitized));
      } catch (e) {
        try {
          final sanitized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();
          return TimeOfDay.fromDateTime(DateFormat("h:mm a").parse(sanitized));
        } catch (e2) {
          // Manual fallback for "h:mm a" or "hh:mm a"
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
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF856404))),
            Expanded(
                child: Text(text,
                    style:
                        TextStyle(fontSize: 12.sp, color: Color(0xFF856404)))),
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
                color: Color(0xFFF8F9FA),
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
                      size: 20.sp, color: colors.primaryNew),
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

      // Compare pure dates to avoid time-of-day math issues
      final oStart =
          DateTime(originalStart.year, originalStart.month, originalStart.day);
      final oEnd =
          DateTime(originalEnd.year, originalEnd.month, originalEnd.day);
      final uStart = DateTime(
          updateStartDate!.year, updateStartDate!.month, updateStartDate!.day);
      final uEnd = DateTime(
          updateEndDate!.year, updateEndDate!.month, updateEndDate!.day);

      int daysBefore = oStart.difference(uStart).inDays;
      int daysAfter = uEnd.difference(oEnd).inDays;

      int extraDays =
          (daysBefore > 0 ? daysBefore : 0) + (daysAfter > 0 ? daysAfter : 0);

      return extraDays.clamp(0, 100);
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
          context: this.context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: colors.primaryNew, size: 64.sp),
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
                      backgroundColor: colors.primaryNew,
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
            response['paymentIntent']?['id'] ?? response['paymentId'];

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
                                color: Color(0xFF1A1A2E))),
                        SizedBox(height: 24.h),
                        _buildUpdatePicker(
                          context,
                          "New Drop-off",
                          updateStartDate,
                          updateStartTime,
                          () async {
                            final date = await _showDatePickerBottomSheet(
                              context,
                              (updateStartDate != null &&
                                      !updateStartDate!.isBefore(today))
                                  ? updateStartDate!
                                  : today,
                              today,
                            );
                            if (date != null) {
                              final time = await _showTimePickerBottomSheet(
                                context,
                                updateStartTime,
                              );
                              if (time != null) {
                                setState(() {
                                  updateStartDate = date;
                                  updateStartTime = time;

                                  // If new start is after current end, adjust end to be start + 2 hours
                                  if (updateEndDate != null) {
                                    DateTime newStartDT = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute);
                                    DateTime currentEndDT = DateTime(
                                        updateEndDate!.year,
                                        updateEndDate!.month,
                                        updateEndDate!.day,
                                        updateEndTime.hour,
                                        updateEndTime.minute);

                                    if (!newStartDT.isBefore(currentEndDT)) {
                                      DateTime newEndDT = newStartDT
                                          .add(const Duration(hours: 2));
                                      updateEndDate = DateTime(newEndDT.year,
                                          newEndDT.month, newEndDT.day);
                                      updateEndTime = TimeOfDay(
                                          hour: newEndDT.hour,
                                          minute: newEndDT.minute);
                                    }
                                  }
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
                            if (updateStartDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select start date first')),
                              );
                              return;
                            }
                            final date = await _showDatePickerBottomSheet(
                              context,
                              (updateEndDate != null &&
                                      !updateEndDate!
                                          .isBefore(updateStartDate!))
                                  ? updateEndDate!
                                  : updateStartDate!,
                              updateStartDate!,
                            );
                            if (date != null) {
                              final time = await _showTimePickerBottomSheet(
                                context,
                                updateEndTime,
                              );
                              if (time != null) {
                                // Validation: End must be at least 2 hours after start
                                DateTime startDT = DateTime(
                                    updateStartDate!.year,
                                    updateStartDate!.month,
                                    updateStartDate!.day,
                                    updateStartTime.hour,
                                    updateStartTime.minute);
                                DateTime endDT = DateTime(date.year, date.month,
                                    date.day, time.hour, time.minute);

                                if (endDT.isBefore(
                                    startDT.add(Duration(hours: 2)))) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'End time must be at least 2 hours after start time')),
                                    );
                                  }
                                  return;
                                }

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
                            color: Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Booking Update Charges",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: Color(0xFF856404))),
                              SizedBox(height: 8.h),
                              _buildNoteText(
                                  "A fixed update fee of £20 applies to every booking modification."),
                              _buildNoteText(
                                  "Each additional day costs an extra £15."),
                              _buildNoteText(
                                  "No refunds are provided for reduced booking days."),
                              Divider(color: Color(0xFFFFE082)),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: colors.primaryNew.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: colors.primaryNew,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: colors.primaryNew,
                                      size: 24.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Update Cost",
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            "£${totalCost.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24.sp,
                                              color: colors.primaryNew,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            "£20 update fee + (£15 × $extraDays extra days)",
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (updateEndDate!.isBefore(updateStartDate!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'End date must be greater than or equal to start date')),
                                );
                                return;
                              }

                              final startDateTime = DateTime(
                                updateStartDate!.year,
                                updateStartDate!.month,
                                updateStartDate!.day,
                                updateStartTime.hour,
                                updateStartTime.minute,
                              );
                              final endDateTime = DateTime(
                                updateEndDate!.year,
                                updateEndDate!.month,
                                updateEndDate!.day,
                                updateEndTime.hour,
                                updateEndTime.minute,
                              );

                              if (updateStartDate!
                                  .isAtSameMomentAs(updateEndDate!)) {
                                final difference =
                                    endDateTime.difference(startDateTime);
                                if (difference.inHours < 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'If start and end dates are the same, time difference must be at least 2 hours')),
                                  );
                                  return;
                                }
                              }
                              _startUpdatePayment(totalCost, setState);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryNew,
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

  Future<DateTime?> _showDatePickerBottomSheet(
      BuildContext context, DateTime initialDate, DateTime firstDate) {
    return showModalBottomSheet<DateTime>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))),
      builder: (context) => Container(
        height: 450.h,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Text("Select Date",
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo')),
            Expanded(
              child: CalendarDatePicker(
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) => Navigator.pop(context, date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> _showTimePickerBottomSheet(
      BuildContext context, TimeOfDay initialTime) async {
    TimeOfDay? selectedTime = initialTime;
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))),
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.red))),
                Text("Select Time",
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Archivo')),
                TextButton(
                    onPressed: () => Navigator.pop(context, selectedTime),
                    child: Text("Done",
                        style: TextStyle(color: colors.secondarynew))),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime:
                    DateTime(2024, 1, 1, initialTime.hour, initialTime.minute),
                onDateTimeChanged: (dateTime) {
                  selectedTime =
                      TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
    return selectedTime;
  }
}
