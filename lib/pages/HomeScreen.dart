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
  final List<String> airportOptions = ['STN', 'LTN'];
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
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
              ...airportOptions
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
                      final bookings = snapshot.data!.reservedParkings;
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

  Widget _buildBookingCard(Parking booking) {
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
                'Address',
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
                '400 m away',
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
                  fontSize: 14.sp,
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
                  'Book Again',
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
