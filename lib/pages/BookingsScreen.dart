import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
import 'package:parkingapp/pages/ViewallScreen.dart';
import 'package:parkingapp/widgets/SessionCard.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/data/repositories/general_repository.dart'; // Import your repository

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<BookingResponse> _bookingsFuture;
  final GeneralRepository _repository =
      GeneralRepository(); // Initialize your repository

  @override
  void initState() {
    super.initState();
    _bookingsFuture =
        _repository.getBookings(); // Fetch bookings using the repository
  }

  void _onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  void _viewAll(String type, List<Parking> parkings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllScreen(title: type, parkings: parkings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: "Bookings",
              showBackButton: false,
              onBackPressed: () => _onBackPressed(context),
            ),
            Expanded(
              child: FutureBuilder<BookingResponse>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final reserved = snapshot.data!.reservedParkings;
                    final pending = snapshot.data!.pendingParkings;
                    final completed = snapshot.data!.completedParkings;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSection(
                              "Active Session", reserved, Icons.schedule),
                          buildSection("Completed Sessions", completed,
                              Icons.check_circle),
                          buildSection("Reserved Spots", pending, Icons.star),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSection(String title, List<Parking> parkings, IconData icon) {
    if (parkings.isEmpty) return SizedBox();

    final first = parkings.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child:
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold))),
            TextButton(
              onPressed: () => _viewAll(title, parkings),
              child: Text("View all"),
            ),
          ],
        ),
        SessionCard(
          title: "${first.airport} Airport",
          subTitle: "Space 4c",
          date: first.startDate ?? "Date",
          time: "02:00pm",
          price: "\$100",
          icon: Icon(icon, color: Colors.green, size: 30),
        )
      ],
    );
  }
}
