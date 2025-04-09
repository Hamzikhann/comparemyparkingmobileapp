import 'package:flutter/material.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
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
    return Scaffold(
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
                  return SessionCard(
                    title: "${item.airport} Airport",
                    subTitle: "Space 4c",
                    date: item.startDate ?? '',
                    time: "02:00pm",
                    price: "\$100",
                    icon: Icon(Icons.airport_shuttle, color: Colors.blue),
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
