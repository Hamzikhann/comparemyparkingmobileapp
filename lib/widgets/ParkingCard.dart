import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParkingCard extends StatelessWidget {
  final String title;
  final String distance;
  final String rate;

  const ParkingCard({
    super.key,
    required this.title,
    required this.distance,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Icon(Icons.local_parking, size: 40.r),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text("Distance: $distance"),
              ],
            ),
            Spacer(),
            Text(rate, style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
