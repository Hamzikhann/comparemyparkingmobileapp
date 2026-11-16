import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

/// Job card for the employee (driver) screens.
/// Styled to match the customer booking cards.
class SessionCard extends StatelessWidget {
  final String title;
  final String status;
  final String subTitle;
  final String date;
  final String time;

  /// Car maker (shown next to the car icon).
  final String price;
  final Icon? icon;
  final String type; // 'active', 'completed'
  final String? timeRemaining;
  final String? rate;
  final VoidCallback? onViewRidePressed;
  final VoidCallback? onViewLocationPressed;

  static const Color _titleColor = Color(0xFF1A1A2E);
  static const Color _mutedColor = Color(0xFF6B6B6B);

  const SessionCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.icon,
    required this.type,
    this.timeRemaining,
    this.rate,
    this.onViewRidePressed,
    this.onViewLocationPressed,
  });

  bool get _isCompleted => type == 'completed';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewRidePressed,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Archivo',
                      color: _titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusChip(),
              ],
            ),
            SizedBox(height: 8.h),
            _infoRow(Icons.flight, subTitle),
            SizedBox(height: 4.h),
            _infoRow(Icons.access_time, "$date  •  $time"),
            SizedBox(height: 4.h),
            _infoRow(Icons.directions_car, price),
            if (!_isCompleted) ...[
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewRidePressed,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        side: const BorderSide(color: colors.primaryNew),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'View Job',
                        style: TextStyle(
                          color: colors.primaryNew,
                          fontSize: 13.sp,
                          fontFamily: 'Archivo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (onViewLocationPressed != null) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onViewLocationPressed,
                      icon: Icon(Icons.location_on,
                          size: 16.sp, color: Colors.white),
                      label: Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontFamily: 'Archivo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryNew,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: _mutedColor),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              fontFamily: 'Archivo',
              color: _mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    final label = _isCompleted
        ? 'Completed'
        : (status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Active');
    final fg = _isCompleted ? colors.secondarynew : colors.primaryNew;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
