import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 0.0,
            offset: const Offset(0, -5),
            blurStyle: BlurStyle.normal,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, "assets/images/home.svg", "Home"),
          _buildNavItem(1, "assets/images/bookings.svg", "Bookings"),
          _buildNavItem(2, "assets/images/wallets.svg", "Payments"),
          _buildNavItem(3, "assets/images/settings.svg", "Settings"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String svgIconPath, String label) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.transparent,
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgIconPath,
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    isSelected ? Colors.white : colors.textGray,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}