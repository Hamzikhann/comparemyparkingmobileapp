import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingAdminModel.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/admin/DriverListScreen.dart';
import 'package:parkingapp/pages/admin/PaymentsScreen.dart';
import 'package:parkingapp/pages/admin/ViewAllScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/BookingCard.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';
import 'package:url_launcher/url_launcher.dart';

class Adminhome extends StatefulWidget {
  const Adminhome({Key? key}) : super(key: key);

  @override
  State<Adminhome> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState  extends State<Adminhome>{
  late Future<BookingAdminResponse> _bookingsFuture;
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
      _bookingsFuture = _repository.getBookingsForAdmin();
      await _bookingsFuture;
       await fetchDrivers();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: ${e.toString()}";
        print(_errorMessage = "Failed to load data: ${e.toString()}");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
  }
  Future<void> fetchDrivers() async {
    try {
      final response = await GeneralRepository().getEmployeesWithBookings();
      final employeesData = response['data'] as List;
        Globals.drivers = employeesData.map((json) => Driver.fromJson(json)).toList();
     
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load drivers: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit; // If true, allow back navigation; if false, prevent it
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                title: '',
                leftSideText: "AirPort Parking",
                showBackButton: false,
                showPayments: true,
                onPaymentPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentScreenAdmin()));
                },
                onBackPressed: () {},
                onLogoutPressed: () {
                  // Handle logout
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      MyRoutes.loginRoute, (route) => false);
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
                        : FutureBuilder<BookingAdminResponse>(
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
                                final pending = snapshot.data!.pendingParkings;
                                for (var booking in snapshot.data!.reservedParkings) {
                                  if (booking.bookingAssignments.isEmpty) {
                                    pending.add(booking);
                                  }
                                }
                              
                                final reserved =
                                    snapshot.data!.reservedParkings;
                                final completed =
                                    snapshot.data!.completedParkings;

                                return SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 16.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Assigned Driver",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Archivo',
                                        ),
                                      ),
                                      SizedBox(height: 16.h),

                                      // First card (Total Booking)
                                      BookingCard(
                                        title: "Total Booking",
                                        available: reserved.length +
                                            pending.length +
                                            completed
                                                .length, // or your total count
                                        isHighlighted: true,
                                        onTap: () {
                                          // navigate to Total Booking details
                                        },
                                      ),
                                      SizedBox(height: 12.h),

                                      // Accept Booking
                                      BookingCard(
                                        title: "Assigned Booking",
                                        available: reserved.length - pending.length,
                                        onTap: () {
                                          // navigate to Accept Booking details
                                          _viewAll("Accept Booking", reserved);
                                        },
                                      ),
                                      SizedBox(height: 12.h),

                                      // Pending Booking
                                      BookingCard(
                                        title: "Un-Assigned Booking",
                                        available: pending.length,
                                        onTap: () {
                                          // navigate to Pending Booking details
                                          _viewAll("Pending Booking", pending);
                                        },
                                      ),
                                      SizedBox(height: 12.h),

                                      // Reserved Booking
                                      BookingCard(
                                        title: "Completed Booking",
                                        available: completed.length,
                                        onTap: () {
                                          // navigate to Reserved Booking details
                                          _viewAll(
                                              "Completed Booking", completed);
                                        },
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
                                      buildSection(
                                        "Un-Assigned Session",
                                        pending,
                                        Icons.schedule,
                                        "Not Assigned",
                                      ),
                                      buildSection(
                                        "Assigned Session",
                                        reserved,
                                        Icons.schedule,
                                        reserved.isNotEmpty &&
                                                reserved.first.bookingAssignments.isNotEmpty &&
                                                reserved.first.bookingAssignments.first.employee?.firstName != null
                                            ? reserved.first.bookingAssignments.first.employee!.firstName
                                            : 'Assigned',
                                      ),
                                      buildSection(
                                        "Completed Sessions",
                                        completed,
                                        Icons.check_circle,
                                        completed.isNotEmpty &&
                                                completed.first.bookingAssignments.isNotEmpty &&
                                                completed.first.bookingAssignments.first.employee?.firstName != null
                                            ? completed.first.bookingAssignments.first.employee!.firstName
                                            : 'Assigned',
                                      ),

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

  Widget buildSection(
      String title, List<Parking> parkings, IconData icon, String assigned) {
    if (parkings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textFieldBorder,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "No ${title.toLowerCase()} available",
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
        ],
      );
    }

    bool isUnAssigned = title.contains('Un-Assigned');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textFieldBorder,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildInfoRow(
                  Icons.person,
                  parkings.first.registrations.first.firstName,
                  Icons.directions_car,
                  parkings.first.vehicles.first.vehicleManufacturer),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.flight_takeoff, parkings.first.airport,
                  Icons.home, "Delivery Address"),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.access_time, parkings.first.startTime,
                  Icons.calendar_today, parkings.first.startDate),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.assignment_ind, assigned, Icons.pending,
                  parkings.first.status),
              if (isUnAssigned) ...[
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () {
                    _openAssignDriverBottomSheet(parkings.first);
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Assigned Driver",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildInfoRow(IconData leftIcon, String leftText, IconData rightIcon,
      String? rightText) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(leftIcon, size: 18.sp, color: Colors.black),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  leftText,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(rightIcon, size: 18.sp, color: Colors.black),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  rightText ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAssignDriverBottomSheet(Parking parkings) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    isScrollControlled: true,
    builder: (context) {
      String? selectedDriverId;
      bool isLoading = false; // Changed to store driver ID instead of name

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Assign Driver",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select Driver",
                  ),
                  value: selectedDriverId,
                  items: Globals.drivers.map((driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(driver.name), // Using driver.name from your Driver model
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDriverId = value;
                    });
                  },
                ),
                SizedBox(height: 12.h),

                // New Driver Text
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DriverListScreen()),
                    ).then((_) {
                      // Refresh drivers list after returning from AddEdit screen
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "+ Add New Driver",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLoading ? Colors.grey : colors.primary,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (selectedDriverId != null) {
                                  setState(() => isLoading = true);
                                  try {
                                    // Call the API to assign driver
                                    await assignDriver(
                                      parkings.registrations.first.bookingId,
                                      selectedDriverId!,
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to assign driver: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => isLoading = false);
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Please select a driver"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Apply",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          );
        },
      );
    },
  );
}
Future<void> assignDriver(String bookingID, String userID) async {
    GeneralRepository().assignDriver(bookingID, userID).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Driver Assign Successfull!")),
                
      );
      Navigator.pop(context);
      _loadData();
    });
  }

  void _viewAll(String type, List<Parking> parkings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllScreen(title: type, parkings: parkings),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    // Ensure the return type is Future<bool>
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exit"),
          content: Text("Are you sure you want to exit?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't exit
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Exit
              },
              child: Text("Exit"),
            ),
          ],
        );
      },
    );

    // Return the result or false if the result is null (dialog dismissed)
    return result ?? false;
  }

  Future<void> getLocation(String bookingID) async {
    try {
      final value = await GeneralRepository().getLocationCoordinates(bookingID);
      final longitude = value['longitude'];
      final latitude = value['latitude'];

      if (longitude == null ||
          longitude.isEmpty ||
          latitude == null ||
          latitude.isEmpty) {
        print("No location found.");
        return;
      }

      final googleMapsUrl = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
      final appleMapsUrl =
          Uri.parse("http://maps.apple.com/?q=$latitude,$longitude");

      if (Platform.isAndroid) {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          print("Could not open Google Maps on Android.");
        }
      } else if (Platform.isIOS) {
        // Try Google Maps first on iOS
        final iosGoogleMapsUrl =
            Uri.parse("comgooglemaps://?q=$latitude,$longitude");

        if (await canLaunchUrl(iosGoogleMapsUrl)) {
          await launchUrl(iosGoogleMapsUrl);
        } else {
          // Fallback to Apple Maps
          if (await canLaunchUrl(appleMapsUrl)) {
            await launchUrl(appleMapsUrl);
          } else {
            print("Could not open any maps on iOS.");
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
