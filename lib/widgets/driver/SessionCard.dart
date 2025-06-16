import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parkingapp/utils/colors.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String status;
  final String subTitle;
  final String date;
  final String time;
  final String price;
  final Icon? icon;
  final String type; // 'active', 'completed'
  final String? timeRemaining;
  final String? rate;
  final VoidCallback? onViewRidePressed;
  final VoidCallback? onViewLocationPressed;

  const SessionCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.icon,
    required this.type,
    this.timeRemaining,
    this.rate,
    this.onViewRidePressed,
    this.onViewLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'completed':
        return _buildCompletedCard();
      case 'active':
      default:
        return _buildActiveCard();
    }
  }

  Widget _buildActiveCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location and price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              // Price
              Text(
                price,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Date and time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewRidePressed,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: colors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'View Ride',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewLocationPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'View Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          // Price (left) and Location (right) in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price on left
              SvgPicture.asset(
                'assets/images/completed.svg',
                height: 24.h,
                width: 24.w,
              ),
              // Location on right
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey, size: 20.sp),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subTitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Time remaining in same row - left and right aligned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
