import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class Custombottomnavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Custombottomnavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Shadow color with opacity
            blurRadius: 10.0, // Soften the shadow
            spreadRadius: 0.0, // No expansion
            offset: const Offset(0, -5), // Shadow position (top offset)
            blurStyle: BlurStyle.normal, // Default blur style
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, Icons.home, "Home"),
          _buildNavItem(1, Icons.calendar_today, "Bookings"),
          _buildNavItem(2, Icons.payment, "Payments"),
          _buildNavItem(3, Icons.settings, "Settings"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : Colors.grey,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected ? colors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
