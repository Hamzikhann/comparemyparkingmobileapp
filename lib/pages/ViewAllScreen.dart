import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/SessionCard.dart';
import 'package:parkingapp/widgets/TopBar.dart';

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
    // Determine the type based on the title
    String type = 'reserved';
    if (title.contains('Active')) {
      type = 'active';
    } else if (title.contains('Completed')) {
      type = 'completed';
    }

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
                padding: EdgeInsets.all(16),
                itemCount: parkings.length,
                itemBuilder: (_, index) {
                  final item = parkings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SessionCard(
                      title: "${item.airport} Airport",
                      status: item.status,
                      subTitle: item.registrations.first.inboundTerminal,
                      date: item.startDate,
                      time: item.startTime,
                      price: "\$100",
                      type: type,
                      timeRemaining: "0thr:30min", // Only for active sessions
                      rate: "\$40/HR",
                      onTap: () {
                        Globals.detailType = type;
                        GlobalsBookingDetail.bookingdetailuser = item;
                        Navigator.pushNamed(
                          context,
                          MyRoutes.bookingDetailUser,
                        );
                      }, // Only for active sessions
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}