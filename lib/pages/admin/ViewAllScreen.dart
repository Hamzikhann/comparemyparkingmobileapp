import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingAdminModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/admin/DriverListScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';

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
    String type = 'Accept';
    if (title.contains('Pending')) {
      type = 'pending';
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
                    child: buildParkingCard(
                      context,
                      item,
                      item.bookingAssignments.isNotEmpty &&
                      item.bookingAssignments.first.employee?.firstName != null
                  ? item.bookingAssignments.first.employee!.firstName
                  : 'Un-Assigned',
                      showAssignDriver: type == 'pending', // showAssignDriver true only if pending
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



  Widget buildParkingCard(BuildContext context, Parking parking, String assigned, {bool showAssignDriver = false}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person, parking.registrations.first.firstName, Icons.directions_car, parking.vehicles.first.vehicleManufacturer),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.flight_takeoff, parking.airport, Icons.home, "Delivery Address"),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.access_time, parking.startTime, Icons.calendar_today, parking.startDate),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.assignment_ind, assigned, Icons.pending, parking.status),

          if (showAssignDriver) ...[
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                _openAssignDriverBottomSheet(context, parking);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
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
    );
  }

  Widget _buildInfoRow(IconData leftIcon, String leftText, IconData rightIcon, String? rightText) {
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

  void _openAssignDriverBottomSheet(BuildContext context, Parking parking) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String? selectedDriverId;
        bool isLoading = false;
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
                      child: Text(driver.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDriverId = value;
                      });
                    },
                  ),
                  SizedBox(height: 12.h),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DriverListScreen()),
                      ).then((_) {
                        
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
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                          ),
                          onPressed: isLoading
                            ? null
                            : () async {
                                if (selectedDriverId != null) {
                                  setState(() => isLoading = true);
                                  try {
                                    // Call the API to assign driver
                                    await assignDriver(context,
                                      parking.registrations.first.bookingId,
                                      selectedDriverId!,
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to assign driver: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
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
  Future<void> assignDriver(BuildContext context,String bookingID, String userID) async {
    GeneralRepository().assignDriver(bookingID, userID).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Driver Assign Successfull!")),
                
      );
      Navigator.pop(context);
      Navigator.of(context).pushNamedAndRemoveUntil(MyRoutes.adminHome, (route) => false);
      
    });
  }
}