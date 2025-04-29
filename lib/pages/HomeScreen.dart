import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/IconDropDown.dart';
import 'package:parkingapp/widgets/InputBox.dart';
import 'package:parkingapp/widgets/SessionCard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedAirport;
  final List<String> airportOptions = ['STN'];
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
        _bookingsFuture = _repository.getBookings()
          .then((value) {
            debugPrint('Bookings loaded successfully: ${value.reservedParkings.length} items');
            return value;
          })
          .catchError((error) {
            debugPrint('Error loading bookings: $error');
            throw error;
          });
      });
    } catch (e) {
      debugPrint('Exception in _loadBookings: $e');
      setState(() {
        _bookingsFuture = Future.error(e);
      });
    }
  }

  void _retryLoading() {
    _loadBookings();
  }

  void _parseAndStoreDates() {
    if (selectedDateRange != null && checkInTime != null && checkOutTime != null) {
      try {
        final dateParts = selectedDateRange!.split(' - ');
        final startDateStr = dateParts[0];
        final endDateStr = dateParts.length > 1 ? dateParts[1] : dateParts[0];
        
        parsedStartDate = DateFormat('MMM d').parse(startDateStr);
        parsedEndDate = DateFormat('MMM d').parse(endDateStr);
        parsedStartTime = _parseTimeString(checkInTime!);
        parsedEndTime = _parseTimeString(checkOutTime!);
        
        final now = DateTime.now();
        parsedStartDate = DateTime(now.year, parsedStartDate!.month, parsedStartDate!.day);
        parsedEndDate = DateTime(now.year, parsedEndDate!.month, parsedEndDate!.day);
        
        if (parsedEndDate!.isBefore(parsedStartDate!)) {
          parsedEndDate = DateTime(now.year + 1, parsedEndDate!.month, parsedEndDate!.day);
        }
      } catch (e) {
        debugPrint('Error parsing dates: $e');
      }
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final format = DateFormat('hh:mm a');
      final dateTime = format.parse(timeStr);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return TimeOfDay.now();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF201A56),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Airport Parking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          backgroundImage: AssetImage('assets/images/male.png'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi,${Globals.user?.firstName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    IconDropdown(
                      hint: "Select an airport",
                      icon: Icons.flight,
                      items: airportOptions,
                      value: selectedAirport,
                      onChanged: (value) {
                        setState(() {
                          selectedAirport = value;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    InputBox(
                      hint: "Check In - Check Out",
                      icon: Icons.calendar_month,
                      inputType: InputType.date,
                      onValueChanged: (value) {
                        setState(() {
                          selectedDateRange = value;
                          Globals.selectedDateRange = value;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: InputBox(
                            hint: "Check in",
                            icon: Icons.access_time,
                            inputType: InputType.time,
                            onValueChanged: (value) {
                              setState(() {
                                checkInTime = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InputBox(
                            hint: "Check out",
                            icon: Icons.access_time,
                            inputType: InputType.time,
                            onValueChanged: (value) {
                              setState(() {
                                checkOutTime = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    CustomButton(
                      text: "Reserve",
                      onPressed: () {
                        if (selectedAirport == null || 
                            selectedDateRange == null || 
                            checkInTime == null || 
                            checkOutTime == null) {
                              Globals.startDate = "";
                            Globals.endDate = "";
                            Globals.startTime = "";
                            Globals.endTime = "";
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select all fields')),
                          );
                        } else {
                          _parseAndStoreDates();
                          
                          if (parsedStartDate == null || parsedEndDate == null || 
                              parsedStartTime == null || parsedEndTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid date/time format')),
                            );
                            return;
                          }
                          else{
                            Globals.startDate = _formatDateForApi(parsedStartDate!);
                            Globals.endDate = _formatDateForApi(parsedEndDate!);
                            Globals.startTime = _formatTimeForApi(parsedStartTime!);
                            Globals.endTime = _formatTimeForApi(parsedEndTime!);
                          }
                          
                          Navigator.pushNamed(
                            context, 
                            MyRoutes.packagesScreen,
                          );
                        }
                      },
                    ),
                    SizedBox(height: 24.h),
                    Text("Reserve Booking",
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12.h),

                    FutureBuilder<BookingResponse>(
                      future: _bookingsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingState();
                        }
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          final reserved = snapshot.data!.reservedParkings;
                          if (reserved.isEmpty) {
                            return _noBookingCard();
                          }
                          final first = reserved.first;
                          return SessionCard(
                            title: "${first.airport} Airport",
                            status: first.status,
                            subTitle: first.registrations.isNotEmpty 
                              ? first.registrations.first.inboundTerminal 
                              : 'No flight number',
                            date: first.startDate,
                            time: first.startTime,
                            price: "100",
                            type: "reserved",
                            timeRemaining: "01 hr:30min",
                            rate: "/HR",
                            onTap: () {
                              Globals.detailType = "reserved";
                              GlobalsBookingDetail.bookingdetailuser = first;
                                    Navigator.pushNamed(
                                      context,
                                      MyRoutes.bookingDetailUser,
                                    );
                            },
                          );
                        }
                        return _noBookingCard();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: CircularProgressIndicator(),
      ),
    );
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.gray,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              "No current bookings",
              style: TextStyle(color: colors.textFieldBorder),
            ),
            SizedBox(height: 8.h),
            Text(
              "Tap 'Reserve' to book parking",
              style: TextStyle(color: colors.textFieldBorder, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}