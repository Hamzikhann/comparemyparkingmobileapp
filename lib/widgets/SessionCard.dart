import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String status;
  final String subTitle;
  final String date;
  final String time;
  final String price;
  final Icon? icon;
  final String type; // 'reserved', 'completed', or 'active'
  final String? timeRemaining; // Only for active sessions
  final String? rate;
  final VoidCallback? onTap; // Only for active sessions

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Use the provided onTap callback
      child: _buildCardBasedOnType(),
    );
  }

  Widget _buildCardBasedOnType() {
    switch (type) {
      case 'reserved':
        return _buildReservedCard();
      case 'completed':
        return _buildCompletedCard();
      case 'pending':
        return _buildActiveCard();
      default:
        return _buildReservedCard();
    }
  }

  Widget _buildReservedCard() {
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
                'assets/images/reserve.svg', // Replace with your SVG file path
                height: 24.h, // Adjust the size as needed
                width: 24.w, // Adjust the size as needed
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
                    color: Colors.green),
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
                'assets/images/completed.svg', // Replace with your SVG file path
                height: 24.h, // Adjust the size as needed
                width: 24.w, // Adjust the size as needed
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
                    color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
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
          SizedBox(height: 8.h),
          // Price (left) and Location (right) in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price on left
              SvgPicture.asset(
                'assets/images/pending.svg', // Replace with your SVG file path
                height: 24.h, // Adjust the size as needed
                width: 24.w, // Adjust the size as needed
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
                    color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
