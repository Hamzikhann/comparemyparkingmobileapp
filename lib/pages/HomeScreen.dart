import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import '../widgets/Custombottomnavbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Custombottomnavbar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Bar - No Padding
              Container(
                height: 170.h, // Increased height
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
                  mainAxisAlignment: MainAxisAlignment.start,
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
                          backgroundImage: AssetImage('assets/images/user.png'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// Everything below with padding
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    /// Airport Selection
                    _inputBox(
                      hint: "Select an airport",
                      icon: Icons.flight,
                    ),

                    SizedBox(height: 16.h),

                    /// Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: _inputBox(
                            hint: "Check In",
                            icon: Icons.calendar_month,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _inputBox(
                            hint: "Check Out",
                            icon: Icons.calendar_month,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    /// Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton("Check in", Icons.access_time),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _actionButton("Check Out", Icons.access_time),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    /// Reserve Button
                    CustomButton(
                      text: "Reserve",
                      onPressed: () {},
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

  /// Reusable Input Box
  Widget _inputBox({required String hint, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: colors.textGray, fontSize: 14.sp),
            ),
          ),
          Icon(icon, size: 18.sp),
        ],
      ),
    );
  }

  /// Reusable Outlined Action Button
  Widget _actionButton(String text, IconData icon) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 18.sp, color: Colors.black),
      label: Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 14.sp),
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
