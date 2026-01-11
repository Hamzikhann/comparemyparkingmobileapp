import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class TopBar extends StatelessWidget {
  final String greeting;
  final VoidCallback onBackPressed;
  final bool showBackButton;
  final Color? textColor;

  const TopBar({
    super.key,
    required this.greeting,
    required this.onBackPressed,
    this.showBackButton = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: Colors.white,
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
          Stack(
            alignment: Alignment.center,
            children: [
              // Back button (left-aligned when visible)
              if (showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: textColor ?? Colors.black,
                      size: 24.sp,
                    ),
                    onPressed: onBackPressed,
                  ),
                ),

              // Centered title text
              Align(
                alignment: Alignment.center,
                child: Text(
                  greeting,
                  style: TextStyle(
                    color: textColor ?? Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
