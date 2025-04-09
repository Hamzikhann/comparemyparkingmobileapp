import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/IconDropDown.dart';
import 'package:parkingapp/widgets/InputBox.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedAirport;
  final List<String> airportOptions = ['LHR', 'STN', 'LGW'];

  String? selectedDateRange;
  String? checkInTime;
  String? checkOutTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Bar
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
                    SizedBox(height: 30.h),
                    Text(
                      'Airport Parking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi, John!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          backgroundImage:
                              AssetImage('assets/images/user.png'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// Content Below
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    /// Airport Dropdown
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

                    /// Date Input
                    InputBox(
                      hint: "Check In - Check Out",
                      icon: Icons.calendar_month,
                      inputType: InputType.date,
                      onValueChanged: (value) {
                        setState(() {
                          selectedDateRange = value;
                        });
                      },
                    ),

                    SizedBox(height: 16.h),

                    /// Time Inputs
                    Row(
                      children: [
                        Expanded(
                          child: InputBox(
                            hint: "Check in",
                            icon: Icons.access_time,
                            inputType: InputType.time,
                            onValueChanged: (value) {
                              setState(() {
                                checkInTime = value; // Handle Check-in time separately
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
                                checkOutTime = value; // Handle Check-out time separately
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    /// Reserve Button
                    CustomButton(
                      text: "Reserve",
                      onPressed: () {
                        Navigator.pushNamed(context, MyRoutes.reserveBooking);
                      },
                    ),

                    SizedBox(height: 24.h),

                    /// Reservation Info
                    Text("Reserve Booking",
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold)),

                    SizedBox(height: 12.h),

                    _bookingCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reserve Booking Card
  Widget _bookingCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Birmingham Airport",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("\$5",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          Text("per hour", style: TextStyle(fontSize: 10.sp)),

          SizedBox(height: 12.h),

          /// Location Details
          Row(
            children: [
              const Icon(Icons.home, size: 16),
              SizedBox(width: 6.w),
              const Text("House No 23"),
              const Spacer(),
              const Icon(Icons.route, size: 16),
              SizedBox(width: 6.w),
              const Text("1.3 Km"),
            ],
          ),
        ],
      ),
    );
  }
}
