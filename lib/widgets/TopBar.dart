import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopBar extends StatelessWidget {
  final String greeting;
  final VoidCallback onBackPressed;
  final bool showBackButton;

  const TopBar({
    super.key,
    required this.greeting,
    required this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
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
                      color: Colors.white,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),

              // Avatar (right-aligned)
              Align(
                alignment: Alignment.centerRight,
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/male.png'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
