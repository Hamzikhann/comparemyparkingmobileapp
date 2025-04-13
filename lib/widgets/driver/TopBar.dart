import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onLogoutPressed;

  const TopBar({
    super.key,
    required this.title,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
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
          SizedBox(height: 25.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title text (left-aligned)
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              
              // Logout button (right-aligned)
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 24.sp,
                ),
                onPressed: onLogoutPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}