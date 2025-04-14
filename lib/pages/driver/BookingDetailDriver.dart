import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';

class Bookingdetaildriver extends StatefulWidget {
  const Bookingdetaildriver({Key? key}) : super(key: key);

  @override
  State<Bookingdetaildriver> createState() => BookingdetaildriverState();
}

class BookingdetaildriverState extends State<Bookingdetaildriver> {
  final ImagePicker _picker = ImagePicker();

  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _showStartPopup() async {
    DateTime? selectedStartDate;
    TimeOfDay? selectedStartTime;
    TextEditingController pickupController = TextEditingController();
    List<File> localStartImages = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _selectDate() async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => selectedStartDate = picked);
              }
            }

            Future<void> _selectTime() async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => selectedStartTime = picked);
              }
            }

            Future<void> _pickImage(ImageSource source) async {
              final XFile? pickedFile = await _picker.pickImage(source: source);
              if (pickedFile != null) {
                setState(() => localStartImages.add(File(pickedFile.path)));
              }
            }

            return AlertDialog(
              title: Text('Start'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pickupController,
                      decoration: InputDecoration(labelText: 'Pickup Location'),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectDate,
                          child: Text('Pick Date'),
                        ),
                        SizedBox(width: 10),
                        Text(selectedStartDate != null
                            ? "${selectedStartDate!.toLocal()}".split(' ')[0]
                            : "No date"),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectTime,
                          child: Text('Pick Time'),
                        ),
                        SizedBox(width: 10),
                        Text(selectedStartTime != null
                            ? selectedStartTime!.format(context)
                            : "No time"),
                      ],
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: CircleAvatar(child: Icon(Icons.photo_library)),
                        ),
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.camera),
                          child: CircleAvatar(child: Icon(Icons.camera_alt)),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: localStartImages.map((file) {
                          return Padding(
                            padding: EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save data or pass it upward
                    Navigator.pop(context);
                  },
                  child: Text("Start"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEndPopup() async {
    DateTime? selectedEndDate;
    TimeOfDay? selectedEndTime;
    TextEditingController dropoffController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _selectDate() async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => selectedEndDate = picked);
              }
            }

            Future<void> _selectTime() async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => selectedEndTime = picked);
              }
            }

            return AlertDialog(
              title: Text('End'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dropoffController,
                      decoration: InputDecoration(labelText: 'Dropoff Location'),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectDate,
                          child: Text('Drop Off Date'),
                        ),
                        SizedBox(width: 10),
                        Text(selectedEndDate != null
                            ? "${selectedEndDate!.toLocal()}".split(' ')[0]
                            : "No date"),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectTime,
                          child: Text('Drop Off Time'),
                        ),
                        SizedBox(width: 10),
                        Text(selectedEndTime != null
                            ? selectedEndTime!.format(context)
                            : "No time"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save data or pass it upward
                    Navigator.pop(context);
                  },
                  child: Text("End"),
                ),
              ],
            );
          },
        );
      },
    );
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
                title: "Booking Detail",
                showBackButton: true,
                onLogoutPressed: () {
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(MyRoutes.loginRoute, (route) => false);
                },
                onBackPressed: () => _onBackPressed(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking Information", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24.h),
                      Text("Customer Name", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value: "${Globals.bookingDriverResponse?.registrations.first.firstName} ${Globals.bookingDriverResponse?.registrations.first.lastName}",
                      ),
                      SizedBox(height: 24.h),
                      Text("Contact Number", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value: "${Globals.bookingDriverResponse?.registrations.first.phoneNo}",
                      ),
                      SizedBox(height: 24.h),
                      Text("Car Details:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      Text("Car Registration No", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value: "${Globals.bookingDriverResponse?.vehicles.first.vehicleRegistration}",
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Maker", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText: "${Globals.bookingDriverResponse?.vehicles.first.vehicleManufacturer}",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Model", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText: "${Globals.bookingDriverResponse?.vehicles.first.vehicleColour}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Text("Flight Details:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      Text("Out Bound Terminal", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value: "${Globals.bookingDriverResponse?.registrations.first.outboundTerminal}",
                      ),
                      SizedBox(height: 16.h),
                      Text("In Bound Terminal", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value: "${Globals.bookingDriverResponse?.registrations.first.inboundTerminal}",
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Out Bound Flight", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText: "${Globals.bookingDriverResponse?.registrations.first.outboundFlightNo}",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("In Bound Flight", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText: "${Globals.bookingDriverResponse?.registrations.first.inboundFlightNo}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _showStartPopup,
                            child: Text("Start Booking"),
                          ),
                          ElevatedButton(
                            onPressed: _showEndPopup,
                            child: Text("End Booking"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
