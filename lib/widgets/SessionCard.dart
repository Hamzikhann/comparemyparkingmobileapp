import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String date;
  final String time;
  final String price;
  final Widget icon;

  const SessionCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.r,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          icon,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subTitle),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date),
                    Text(time),
                    Text(price),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
