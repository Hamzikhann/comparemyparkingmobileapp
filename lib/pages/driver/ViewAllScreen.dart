import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/pages/driver/driver_helpers.dart';
import 'package:parkingapp/widgets/TopBar.dart';

/// A plain list of jobs (used when opening jobs from a notification).
class ViewAllScreen extends StatelessWidget {
  final String title;
  final List<Parking> parkings;

  const ViewAllScreen({
    super.key,
    required this.title,
    required this.parkings,
  });

  @override
  Widget build(BuildContext context) {
    final type = title.contains('Completed') ? 'completed' : 'active';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: title,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: parkings.length,
                itemBuilder: (_, index) =>
                    buildDriverSessionCard(context, parkings[index], type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
