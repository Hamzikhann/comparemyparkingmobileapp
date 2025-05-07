import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/pages/ViewallScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
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
      backgroundColor: Colors.white,
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
                              "Reserved Session", reserved, Icons.schedule),
                              buildSection("Pending Session", pending, Icons.star),
                          buildSection("Completed Sessions", completed,
                              Icons.check_circle),
                          
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  return Center();
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

  String type = 'reserved';
  if (title.contains('Pending')) {
    type = 'pending';
  } else if (title.contains('Completed')) {
    type = 'completed';
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
              child:
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold,color: colors.textFieldBorder,fontSize: 16.sp))),
          TextButton(
            onPressed: () => _viewAll(title, parkings),
            child: Text("View all",
            style: TextStyle(
            color: colors.primary, // Change this to your desired color
          ),),
          ),
        ],
      ),
      SessionCard(
        title: "${first.airport} Airport",
        status: first.status,
        subTitle: first.registrations.first.inboundTerminal,
        date: first.startDate,
        time: first.startTime,
        price: "\$100",
        type: type,
        timeRemaining: "01 hr:30min", // Only for active sessions
        rate: "\$40/HR",
        onTap: () {
          Globals.detailType = type;
          GlobalsBookingDetail.bookingdetailuser = parkings.first;
                Navigator.pushNamed(
                  context,
                  MyRoutes.bookingDetailUser,
                );
        }, // Only for active sessions
      )
    ],
  );
}
}
