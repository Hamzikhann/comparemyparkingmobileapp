import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/utils/colors.dart';

/// One tab in [Custombottomnavbar]. Give either an [svgPath] or an [icon].
class NavBarItem {
  final String label;
  final String? svgPath;
  final IconData? icon;

  const NavBarItem({required this.label, this.svgPath, this.icon})
      : assert(svgPath != null || icon != null);
}

class Custombottomnavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Tabs to show. Defaults to the customer/admin tabs.
  final List<NavBarItem> items;

  /// Optional unread counts by tab index (shown as a red badge).
  final Map<int, int> badges;

  static const List<NavBarItem> customerItems = [
    NavBarItem(label: "Home", svgPath: "assets/images/home.svg"),
    NavBarItem(label: "Bookings", svgPath: "assets/images/bookings.svg"),
    NavBarItem(label: "Payments", svgPath: "assets/images/wallets.svg"),
    NavBarItem(label: "Settings", svgPath: "assets/images/settings.svg"),
  ];

  const Custombottomnavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = customerItems,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        top: false,
        child: Container(
          height: 70.h,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 8.h,
          ),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) _buildNavItem(i, items[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavBarItem item) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Colors.white : colors.textGray;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: (badges[index] ?? 0) > 0,
              label: Text((badges[index] ?? 0) > 99 ? '99+' : '${badges[index]}'),
              child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primaryNew : Colors.transparent,
              ),
              child: Center(
                child: item.svgPath != null
                    ? SvgPicture.asset(
                        item.svgPath!,
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    : Icon(item.icon, size: 24.sp, color: color),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
