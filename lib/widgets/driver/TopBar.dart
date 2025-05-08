import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final bool showBackButton;
  final VoidCallback onLogoutPressed;
  final VoidCallback?
      onNotificationPressed; // New callback for notification icon

  const TopBar({
    super.key,
    required this.title,
    required this.onLogoutPressed,
    required this.onBackPressed,
    this.showBackButton = true,
    this.onNotificationPressed, // Optional parameter
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
              // Back button and title
              Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      onPressed: onBackPressed,
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),

              // Notification and logout buttons
              Row(
                children: [
                  // Notification icon
                  if (onNotificationPressed != null)
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      onPressed: onNotificationPressed,
                    ),

                  // Logout button
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
        ],
      ),
    );
  }
}
