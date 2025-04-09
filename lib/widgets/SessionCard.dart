import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String date;
  final String time;
  final String price;
  final Icon? icon;
  final String type; // 'reserved', 'completed', or 'active'
  final String? timeRemaining; // Only for active sessions
  final String? rate; // Only for active sessions

  const SessionCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.price,
    this.icon,
    required this.type,
    this.timeRemaining,
    this.rate,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'reserved':
        return _buildReservedCard();
      case 'completed':
        return _buildCompletedCard();
      case 'active':
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reserved Spots",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View all",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                "$title Parking",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 28.w),
            child: Text(
              subTitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Completed Sessions",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View all",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            date,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 28.w),
            child: Text(
              subTitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 28.w),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              price,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
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
            Text(
              rate ?? "\$40/HR",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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
              "Time Remaining",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            Text(
              timeRemaining ?? "1 hr:30min",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}