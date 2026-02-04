import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:parkingapp/services/notification_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/airport_service_config.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';

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
  final GeneralRepository _repository = GeneralRepository();

  // Filter & Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedAirport;
  DateTime? _filterStartDate;
  TimeOfDay? _filterStartTime;
  DateTime? _filterEndDate;
  TimeOfDay? _filterEndTime;
  DateTime? _filterCreatedAtStartDate;
  DateTime? _filterCreatedAtEndDate;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _repository.getBookings();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    // Extract all unique airports for filter
                    final allParkings = [
                      ...snapshot.data!.reservedParkings,
                      ...snapshot.data!.pendingParkings,
                      ...snapshot.data!.completedParkings
                    ];
                    final List<String> airports = allParkings
                        .map((e) => e.airport)
                        .toSet()
                        .toList()
                        .where((e) => e.isNotEmpty)
                        .toList();
                    airports.sort();

                    // Apply filters
                    final reserved =
                        _applyFilters(snapshot.data!.reservedParkings);
                    final pending =
                        _applyFilters(snapshot.data!.pendingParkings);
                    final completed =
                        _applyFilters(snapshot.data!.completedParkings);

                    final bool isListEmpty = reserved.isEmpty &&
                        pending.isEmpty &&
                        completed.isEmpty;

                    return Column(
                      children: [
                        if (Globals.user?.roleTitle.toLowerCase() ==
                            'administrator')
                          _buildSearchBar(context, airports),
                        Expanded(
                          child: isListEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy,
                                          size: 64.sp, color: Colors.grey[400]),
                                      SizedBox(height: 16.h),
                                      Text(
                                        "No bookings found",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                          fontFamily: 'Archivo',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildSection("Reserved Session", reserved,
                                          Icons.schedule),
                                      buildSection("Pending Session", pending,
                                          Icons.star),
                                      buildSection("Completed Sessions",
                                          completed, Icons.check_circle),
                                    ],
                                  ),
                                ),
                        ),
                        if (Globals.user?.roleTitle.toLowerCase() ==
                                'administrator' &&
                            !isListEmpty)
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -4),
                                )
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final allFiltered = [
                                    ...reserved,
                                    ...pending,
                                    ...completed
                                  ];
                                  _exportToCsv(context, allFiltered);
                                },
                                icon: const Icon(Icons.download,
                                    color: Colors.white),
                                label: Text("Export Data (CSV)",
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Archivo')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B725D),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  return const Center(child: CircularProgressIndicator());
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
                              "ID: ${booking.id.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontFamily: 'Archivo',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (Globals.user?.roleTitle.toLowerCase() !=
                            'administrator')
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

                    SizedBox(height: 40.h),

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
                                  color: colors.secondarynew, size: 24.sp),
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
                    SizedBox(height: 32.h),

                    // Arrival/Departure Procedures if available
                    if (serviceInfo != null) ...[
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
                            if (serviceInfo['contact']?['number'] != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.phone,
                                      color: Color(0xFF4B725D), size: 18.sp),
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
                                          serviceInfo['contact']!['number'],
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
                            if (serviceInfo['location']?['address'] !=
                                null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on,
                                      color: Color(0xFF4B725D), size: 18.sp),
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
                                          serviceInfo['location']!['address'],
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
                            if (serviceInfo['arrival_procedure'] != null) ...[
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
                                serviceInfo['arrival_procedure'],
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontFamily: 'Archivo',
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 20.h),
                            ],
                            if (serviceInfo['departure_procedure'] != null) ...[
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
                                serviceInfo['departure_procedure'],
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontFamily: 'Archivo',
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
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

  Widget _buildVehicleBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.secondarynew.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: colors.secondarynew),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Archivo',
              color: colors.secondarynew,
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
                Row(
                  children: List.generate(5, (index) {
                    final randomRating =
                        (Random(booking.id.hashCode).nextInt(3) + 2);
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
                    Globals.detailType = type;
                    GlobalsBookingDetail.bookingdetailuser = booking;
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
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4B725D).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFF4B725D),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: const Color(0xFF4B725D),
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
                                              color: const Color(0xFF4B725D),
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
                        style: TextStyle(color: Color(0xFF4B725D)))),
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
  // --- Search & Filter Helper Methods ---

  Widget _buildSearchBar(BuildContext context, List<String> airports) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      key: const ValueKey('searchBarContainer'),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search Name, Email, ID, Airport...",
                  hintStyle:
                      TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context, airports),
            child: Container(
              width: 50.h,
              height: 50.h,
              decoration: BoxDecoration(
                color: const Color(0xFF4B725D),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.tune, color: Colors.white, size: 24.sp),
            ),
          ),
        ],
      ),
    );
  }

  List<Parking> _applyFilters(List<Parking> bookings) {
    return bookings.where((booking) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final reg = booking.registrations.isNotEmpty
            ? booking.registrations.first
            : null;
        final name =
            reg != null ? "${reg.firstName} ${reg.lastName}".toLowerCase() : "";
        final email = reg != null ? reg.email.toLowerCase() : "";
        final airport = booking.airport.toLowerCase();
        final id = booking.id.toString().toLowerCase();

        final matchesSearch = name.contains(query) ||
            email.contains(query) ||
            airport.contains(query) ||
            id.contains(query);

        if (!matchesSearch) return false;
      }

      // 2. Airport Filter
      if (_selectedAirport != null && _selectedAirport!.isNotEmpty) {
        if (booking.airport != _selectedAirport) return false;
      }

      // 3. Date Range Filter (Using Booking Start Date/Time)
      if (_filterStartDate != null) {
        try {
          // Parse booking start
          final bStartDate = DateTime.parse(booking.startDate);
          final bStartTime = _robustTimeParse(booking.startTime);
          final bStartDateTime = DateTime(bStartDate.year, bStartDate.month,
              bStartDate.day, bStartTime.hour, bStartTime.minute);

          // Construct filter start constraint
          final fStart = _filterStartDate!;
          final fStartTime =
              _filterStartTime ?? const TimeOfDay(hour: 0, minute: 0);
          final fStartDateTime = DateTime(fStart.year, fStart.month, fStart.day,
              fStartTime.hour, fStartTime.minute);

          if (bStartDateTime.isBefore(fStartDateTime)) return false;

          // Construct filter end constraint
          if (_filterEndDate != null) {
            final fEnd = _filterEndDate!;
            final fEndTime =
                _filterEndTime ?? const TimeOfDay(hour: 23, minute: 59);
            final fEndDateTime = DateTime(fEnd.year, fEnd.month, fEnd.day,
                fEndTime.hour, fEndTime.minute);
            if (bStartDateTime.isAfter(fEndDateTime)) return false;
          }
        } catch (e) {
          // If parsing fails, ignore date filter for this item or hide it.
          // Let's assume inclusive if parsing fails for safety, or false.
          // Choosing false to be safe.
          return false;
        }
      }

      // 4. Created At Date Filter
      if (_filterCreatedAtStartDate != null ||
          _filterCreatedAtEndDate != null) {
        try {
          if (booking.createdAt != null) {
            // Parse the createdAt timestamp
            final createdAt = DateTime.parse(booking.createdAt!);

            // Check if createdAt is after or equal to start date
            if (_filterCreatedAtStartDate != null) {
              final startDateTime = DateTime(
                _filterCreatedAtStartDate!.year,
                _filterCreatedAtStartDate!.month,
                _filterCreatedAtStartDate!.day,
                0,
                0,
              );
              if (createdAt.isBefore(startDateTime)) return false;
            }

            // Check if createdAt is before or equal to end date
            if (_filterCreatedAtEndDate != null) {
              final endDateTime = DateTime(
                _filterCreatedAtEndDate!.year,
                _filterCreatedAtEndDate!.month,
                _filterCreatedAtEndDate!.day,
                23,
                59,
                59,
              );
              if (createdAt.isAfter(endDateTime)) return false;
            }
          } else {
            // If booking doesn't have createdAt and filter is set, exclude it
            return false;
          }
        } catch (e) {
          // If parsing fails, exclude this booking
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet(BuildContext context, List<String> airports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Use a local "dirty" flag or just rely on the temp vars.
          // Since StatefulBuilder rebuilds its child, we need to initialize variables ONLY ONCE?
          // No, Builder runs once. But if we call setSheetState, it reruns.
          // So we must initialize OUTSIDE builder? No, showModalBottomSheet builder runs once.
          // Warning: If I define vars inside builder, they reset on setSheetState.
          // FIX: The StatefulBuilder's builder is called whenever setSheetState is called.
          // So I CANNOT define init vars inside.
          // I should wrap the CONTENT in a StatefulWidget or use a class.
          // OR: Initialize them *outside* the StatefulBuilder?
          // Actually, passing a separate widget class is cleaner, but inline:
          return _FilterSheetContent(
            airports: airports,
            initialAirport: _selectedAirport,
            initialStartDate: _filterStartDate,
            initialStartTime: _filterStartTime,
            initialEndDate: _filterEndDate,
            initialEndTime: _filterEndTime,
            initialCreatedAtStartDate: _filterCreatedAtStartDate,
            initialCreatedAtEndDate: _filterCreatedAtEndDate,
            onApply: (airport, sDate, sTime, eDate, eTime, createdStart,
                createdEnd) {
              setState(() {
                _selectedAirport = airport;
                _filterStartDate = sDate;
                _filterStartTime = sTime;
                _filterEndDate = eDate;
                _filterEndTime = eTime;
                _filterCreatedAtStartDate = createdStart;
                _filterCreatedAtEndDate = createdEnd;
              });
              Navigator.pop(sheetContext);
            },
          );
        },
      ),
    );
  }

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

  Future<void> _exportToCsv(BuildContext context, List<Parking> data) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          if (!await Permission.manageExternalStorage.isGranted) {
            await Permission.manageExternalStorage.request();
          }
        } else {
          if (!await Permission.storage.request().isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Storage permission denied")));
            return;
          }
        }
      }

      String csvContent =
          "Booking ID,Airport,Start Date,End Date,Customer Name,Email,Phone,Vehicle Reg,Vehicle Color,Passengers,Outbound Terminal,Outbound Flight,Inbound Terminal,Inbound Flight,Status\n";
      for (var p in data) {
        final reg = p.registrations.isNotEmpty ? p.registrations.first : null;
        final vehicle = p.vehicles.isNotEmpty ? p.vehicles.first : null;

        final id = _escapeCsv(p.id);
        final airport = _escapeCsv(p.airport);
        final start = _escapeCsv("${p.startDate} ${p.startTime}");
        final end = _escapeCsv("${p.endDate} ${p.endTime}");
        final name =
            _escapeCsv(reg != null ? "${reg.firstName} ${reg.lastName}" : "");
        final email = _escapeCsv(reg?.email);
        final phone = _escapeCsv(reg?.phoneNo);
        final vReg = _escapeCsv(vehicle?.vehicleRegistration);
        final vColor = _escapeCsv(vehicle?.vehicleColour);
        final passengers = _escapeCsv(vehicle?.numberofPassengers);
        final outTerm = _escapeCsv(reg?.outboundTerminal);
        final outFlight = _escapeCsv(reg?.outboundFlightNo);
        final inTerm = _escapeCsv(reg?.inboundTerminal);
        final inFlight = _escapeCsv(reg?.inboundFlightNo);
        final status = _escapeCsv(p.status);

        csvContent +=
            "$id,$airport,$start,$end,$name,$email,$phone,$vReg,$vColor,$passengers,$outTerm,$outFlight,$inTerm,$inFlight,$status\n";
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists())
          directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory!.path}/booking_export_$timestamp.csv');
      await file.writeAsString(csvContent);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Exported to ${file.path}")));
      }

      try {
        await NotificationService().showDownloadNotification(
            filePath: file.path,
            title: 'Data Exported',
            body: 'Bookings exported successfully');
      } catch (e) {
        debugPrint(e.toString());
      }

      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Export Failed: $e")));
    }
  }

  String _escapeCsv(String? val) {
    if (val == null) return "";
    String s = val.replaceAll('"', '""');
    if (s.contains(',') || s.contains('\n') || s.contains('"')) {
      return '"$s"';
    }
    return s;
  }
}

class _FilterSheetContent extends StatefulWidget {
  final List<String> airports;
  final String? initialAirport;
  final DateTime? initialStartDate;
  final TimeOfDay? initialStartTime;
  final DateTime? initialEndDate;
  final TimeOfDay? initialEndTime;
  final DateTime? initialCreatedAtStartDate;
  final DateTime? initialCreatedAtEndDate;
  final Function(String?, DateTime?, TimeOfDay?, DateTime?, TimeOfDay?,
      DateTime?, DateTime?) onApply;

  const _FilterSheetContent({
    required this.airports,
    this.initialAirport,
    this.initialStartDate,
    this.initialStartTime,
    this.initialEndDate,
    this.initialEndTime,
    this.initialCreatedAtStartDate,
    this.initialCreatedAtEndDate,
    required this.onApply,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  String? _selectedAirport;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _createdAtStartDate;
  DateTime? _createdAtEndDate;

  @override
  void initState() {
    super.initState();
    _selectedAirport = widget.initialAirport;
    _startDate = widget.initialStartDate;
    _startTime = widget.initialStartTime;
    _endDate = widget.initialEndDate;
    _endTime = widget.initialEndTime;
    _createdAtStartDate = widget.initialCreatedAtStartDate;
    _createdAtEndDate = widget.initialCreatedAtEndDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final initial =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SizedBox(
        height: 400,
        child: CalendarDatePicker(
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          onDateChanged: (val) => Navigator.pop(ctx, val),
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  Future<void> _pickCreatedAtDate(bool isStart) async {
    final initial = isStart
        ? (_createdAtStartDate ?? DateTime.now())
        : (_createdAtEndDate ?? DateTime.now());
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SizedBox(
        height: 400,
        child: CalendarDatePicker(
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          onDateChanged: (val) => Navigator.pop(ctx, val),
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart)
          _createdAtStartDate = picked;
        else
          _createdAtEndDate = picked;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    // Simple time picker dialog or re-use existing one if accessible.
    // Since existing one is in private State, I'll allow using system picker here for simplicity within this extracted widget
    // OR re-implement the Cupertino one briefly.

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4B725D)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filter Bookings",
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Archivo',
                        color: const Color(0xFF1A1A2E))),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAirport = null;
                      _startDate = null;
                      _startTime = null;
                      _endDate = null;
                      _endTime = null;
                      _createdAtStartDate = null;
                      _createdAtEndDate = null;
                    });
                  },
                  child: Text("Clear All",
                      style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                )
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Airport",
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    value: _selectedAirport,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text("All Airports")),
                      ...widget.airports.map(
                          (a) => DropdownMenuItem(value: a, child: Text(a))),
                    ],
                    onChanged: (val) => setState(() => _selectedAirport = val),
                  ),
                  SizedBox(height: 24.h),
                  Text("Start Date & Time",
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerBox(
                            _startDate != null
                                ? DateFormat('dd MMM yyyy').format(_startDate!)
                                : "Select Date",
                            Icons.calendar_today,
                            () => _pickDate(true)),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPickerBox(
                            _startTime != null
                                ? _startTime!.format(context)
                                : "Select Time",
                            Icons.access_time,
                            () => _pickTime(true)),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text("End Date & Time",
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerBox(
                            _endDate != null
                                ? DateFormat('dd MMM yyyy').format(_endDate!)
                                : "Select Date",
                            Icons.calendar_today,
                            () => _pickDate(false)),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPickerBox(
                            _endTime != null
                                ? _endTime!.format(context)
                                : "Select Time",
                            Icons.access_time,
                            () => _pickTime(false)),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Divider(color: Colors.grey[300], thickness: 1),
                  SizedBox(height: 24.h),
                  Text("Created At Date",
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerBox(
                            _createdAtStartDate != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(_createdAtStartDate!)
                                : "Start Date",
                            Icons.calendar_today,
                            () => _pickCreatedAtDate(true)),
                      ),
                    ],
                  ),
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
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(
                    _selectedAirport,
                    _startDate,
                    _startTime,
                    _endDate,
                    _endTime,
                    _createdAtStartDate,
                    _createdAtEndDate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B725D),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text("Apply Filters",
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerBox(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: const Color(0xFF4B725D)),
            SizedBox(width: 8.w),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A2E)),
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
