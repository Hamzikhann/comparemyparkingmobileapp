import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class BookingCard extends StatelessWidget {
  final String title;
  final int available;
  final bool isHighlighted;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.title,
    required this.available,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isHighlighted ? Color(0xFF221B58) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Archivo',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Available ${available.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: isHighlighted ? Colors.white : Colors.black,
                    fontSize: 12.sp,
                    fontFamily: 'Archivo',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "View All",
                  style: TextStyle(
                    color: isHighlighted ? colors.primary : colors.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
