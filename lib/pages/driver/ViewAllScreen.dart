import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/driver/SessionCard.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart' show TopBar;

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
              title: title,
              onBackPressed: () => Navigator.pop(context),
              onLogoutPressed: () {
                  // Handle logout
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(MyRoutes.loginRoute, (route) => false);
                },
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
                      subTitle: item.registrations.first.inboundFlightNo,
                      date: item.startDate,
                      time: item.startTime,
                      price:
                          "\$Car Maker : ${item.vehicles.first.vehicleManufacturer}",
                      type: type,
                      timeRemaining: item.startTime, // Only for active sessions
                      rate: "\$40/HR",
                      onViewRidePressed: () {
                        Globals.bookingDriverResponse = item;
                        Navigator.pushNamed(
                          context,
                          MyRoutes.bookingDetail,
                        );
                      },
                      onViewLocationPressed: () {
                        // location click
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
