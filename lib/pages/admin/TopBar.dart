import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopBar extends StatelessWidget {
  final String title;
  final String? leftSideText; // Text to show on left when back button is hidden
  final VoidCallback onBackPressed;
  final bool showBackButton;
  final VoidCallback onLogoutPressed;
  final bool showPayments;
  final VoidCallback? onPaymentPressed;

  const TopBar({
    super.key,
    required this.title,
    required this.onLogoutPressed,
    required this.onBackPressed,
    this.showBackButton = true,
    this.showPayments = false,
    this.onPaymentPressed,
    this.leftSideText, // New parameter for left side text
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
              // Left side - Back button or text
              if (showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  onPressed: onBackPressed,
                )
              else if (leftSideText != null)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Text(
                    leftSideText!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                )
              else
                SizedBox(width: 48.w), // Empty space when no back button or text

              // Center - Title
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),

              // Right side - Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment icon
                  if (showPayments)
                    IconButton(
                      icon: Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      onPressed: onPaymentPressed,
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