import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/driver/ViewAllScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/driver/SessionCard.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';

class Driverhome extends StatefulWidget {
  const Driverhome({Key? key}) : super(key: key);

  @override
  State<Driverhome> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<Driverhome> {
  late Future<BookingDriverResponse> _bookingsFuture;
  final GeneralRepository _repository = GeneralRepository();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _bookingsFuture = _repository.getBookingsForDriver();
      await _bookingsFuture;
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed(context);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                title: "Driver",
                showBackButton: false,
                onBackPressed: () {},
                onLogoutPressed: () {
                  // Handle logout
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(MyRoutes.loginRoute, (route) => false);
                },
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_errorMessage!),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : FutureBuilder<BookingDriverResponse>(
                            future: _bookingsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center();
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Error: ${snapshot.error}"),
                                      SizedBox(height: 16.h),
                                      ElevatedButton(
                                        onPressed: _loadData,
                                        child: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (snapshot.hasData) {
                                final reserved =
                                    snapshot.data!.assignedAssignments;
                                final completed =
                                    snapshot.data!.completedAssignmnets;

                                return SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 16.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Driver Info",
                                          style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Archivo')),
                                      SizedBox(height: 24.h),
                                      Text("Driver Name",
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Archivo')),
                                      SizedBox(height: 8.h),
                                      NonEditableTextField(
                                        hintText: "",
                                        value:
                                            "${Globals.user?.firstName ?? ''} ${Globals.user?.lastName ?? ''}",
                                      ),
                                      SizedBox(height: 16.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text("Active",
                                                style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Archivo')),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text("Completed",
                                                style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Archivo')),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: NonEditableTextField(
                                              hintText: "${reserved.length}",
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: NonEditableTextField(
                                              hintText: "${completed.length}",
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16.h),

                                      /// 🔄 TASK LIST ROW WITH REFRESH
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Task List",
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Archivo',
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _loadData,
                                            child: Text(
                                              "Refresh",
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: colors.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24.h),

                                      buildSection("Active Session", reserved,
                                          Icons.schedule),
                                      buildSection("Completed Sessions",
                                          completed, Icons.check_circle),
                                    ],
                                  ),
                                );
                              } else {
                                return const Center(
                                    child: Text("No data available."));
                              }
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, List<Parking> parkings, IconData icon) {
    if (parkings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textFieldBorder,
                  fontSize: 16.sp)),
          SizedBox(height: 8.h),
          Text("No ${title.toLowerCase()} available",
              style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 16.h),
        ],
      );
    }

    String type = title.contains('Completed') ? 'completed' : 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textFieldBorder,
                  fontSize: 16.sp,
                ),
              ),
            ),
            if (parkings.length > 1)
              TextButton(
                onPressed: () => _viewAll(title, parkings),
                child: Text(
                  "View all",
                  style: TextStyle(color: colors.primary),
                ),
              ),
          ],
        ),
        ...List.generate(
          1, // or change to parkings.length to show all
          (index) {
            final parking = parkings[index];
            return SessionCard(
              title: "${parking.airport} Airport",
              status: parking.status,
              subTitle: parking.registrations.isNotEmpty
                  ? parking.registrations.first.inboundFlightNo
                  : "No flight number",
              date: parking.startDate,
              time: parking.startTime,
              price:
                  "\Car Maker: ${parking.vehicles.first.vehicleManufacturer}",
              type: type,
              timeRemaining: parking.startTime,
              rate: "aa",
              onViewRidePressed: () {
                Globals.bookingDriverResponse = parking;
                Navigator.pushNamed(
                  context,
                  MyRoutes.bookingDetail,
                );
              },
              onViewLocationPressed: () {
                // location click
              },
            );
          },
        ),
      ],
    );
  }

  void _viewAll(String type, List<Parking> parkings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllScreen(title: type, parkings: parkings),
      ),
    );
  }
}
