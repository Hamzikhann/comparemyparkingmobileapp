import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/CheckPointRequestModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
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
  List<File> startImages = [];
  TextEditingController dropoffController = TextEditingController();
  TextEditingController sectionEndController = TextEditingController();
  TextEditingController pickupController = TextEditingController();
  TextEditingController sectionStartController = TextEditingController();
 late String type;
  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _showStartPopup() async {
    String text = "Start";
    if(type == "pickup"){
      text = "Start";
    }
    else{
      text = "End";
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage(ImageSource source) async {
              final XFile? pickedFile = await _picker.pickImage(source: source);
              if (pickedFile != null) {
                setState(() => startImages.add(File(pickedFile.path)));
              }
            }

            return AlertDialog(
              title: Text(text),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pickupController,
                      decoration: InputDecoration(labelText: 'Location'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: sectionStartController,
                      decoration: InputDecoration(labelText: 'Section'),
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
                        children: startImages.map((file) {
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
                    _handleSubmitCheckpoint(
                      pickupController.text,
                      sectionStartController.text,
                      type,
                      startImages,
                    );
                  },
                  child: Text(text),
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
                            onPressed: () {
                              type = "pickup";
                              // Convert endDate to DateTime (update format if needed)
                            final startDateString = Globals.bookingDriverResponse?.startDate;
                            if (startDateString != null) {
                              final startDate = DateTime.tryParse(startDateString);

                              if (startDate != null) {
                                final now = DateTime.now();
                                final isSameDate =
                                    startDate.year == now.year &&
                                    startDate.month == now.month &&
                                    startDate.day == now.day;

                                if (isSameDate) {
                                  _showStartPopup(); // ✅ open popup
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("This booking is start on ${Globals.bookingDriverResponse?.startDate}")),
                                  );
                                }
                              }
                            }
                            },
                            child: Text("Start Booking"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                            type = "pickup";

                            // Convert endDate to DateTime (update format if needed)
                            final endDateString = Globals.bookingDriverResponse?.endDate;
                            if (endDateString != null) {
                              final endDate = DateTime.tryParse(endDateString);

                              if (endDate != null) {
                                final now = DateTime.now();
                                final isSameDate =
                                    endDate.year == now.year &&
                                    endDate.month == now.month &&
                                    endDate.day == now.day;

                                if (isSameDate) {
                                  _showStartPopup(); // ✅ open popup
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("This booking is end on ${Globals.bookingDriverResponse?.startDate}")),
                                  );
                                }
                              }
                            }
                          },

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
  Future<void> _handleSubmitCheckpoint(
      String location, String section, String type, List<File>? images) async {
    final checkpointRequest = CheckpointRequestModel(
      bookingId: Globals.bookingDriverResponse!.registrations.first.bookingId,
      location: location,
      section: section,
      type: type,
    );

    try {
      final checkpointResponse = await GeneralRepository().submitCheckpoint(
        checkpointRequest,
        images,
      );

      if (checkpointResponse != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/success.svg',
                  height: 80,
                  width: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Booking has been successfully submitted.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, MyRoutes.driverhome, (_) => false);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      } else {
        debugPrint("❌ Checkpoint Submission Failed");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checkpoint submission failed")),
        );
      }
    } catch (e) {
      debugPrint("❌ Checkpoint Submission Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkpoint submission failed: $e')),
      );
    }
  }

}
