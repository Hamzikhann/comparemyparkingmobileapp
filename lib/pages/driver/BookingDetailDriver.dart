import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- New import

class Bookingdetaildriver extends StatefulWidget {
  const Bookingdetaildriver({Key? key}) : super(key: key);

  @override
  State<Bookingdetaildriver> createState() => BookingdetaildriverState();
}

class BookingdetaildriverState extends State<Bookingdetaildriver> {
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show Bottom Sheet to Choose Image Source (Camera or Gallery)
  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Request permission and pick image
  Future<void> _pickImage(ImageSource source) async {
    final permissionStatus = Platform.isIOS
        ? await Permission.photos.request()
        : await Permission.storage.request();
    final cameraStatus = await Permission.camera.request();

    if (permissionStatus.isGranted || cameraStatus.isGranted) {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permission denied. Please enable it in settings."),
        ),
      );
    }
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
                  // Handle logout
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(MyRoutes.loginRoute, (route) => false);
                },
                onBackPressed: () => _onBackPressed(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Booking Information",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Archivo',
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Customer Name
                      Text("Customer Name",
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Archivo')),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${Globals.bookingDriverResponse?.registrations.first.firstName} ${Globals.bookingDriverResponse?.registrations.first.lastName}",
                      ),
                      SizedBox(height: 24.h),

                      // Contact Number
                      Text("Contact Number",
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Archivo')),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${Globals.bookingDriverResponse?.registrations.first.phoneNo}",
                      ),
                      SizedBox(height: 24.h),

                      // Car Details
                      Text(
                        "Car Details:",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Archivo',
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Car Registration No
                      Text("Car Registration No",
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Archivo')),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${Globals.bookingDriverResponse?.vehicles.first.vehicleRegistration}",
                      ),
                      SizedBox(height: 16.h),

                      // Car Maker & Model
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Maker",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Archivo')),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${Globals.bookingDriverResponse?.vehicles.first.vehicleManufacturer}",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Model",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Archivo')),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${Globals.bookingDriverResponse?.vehicles.first.vehicleColour}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Upload Photos
                      Text(
                        "Upload Photos",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Archivo',
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Images Preview
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourceActionSheet,
                              child: Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Icon(Icons.add_a_photo,
                                    size: 30, color: Colors.grey),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            ..._selectedImages.asMap().entries.map(
                              (entry) {
                                int index = entry.key;
                                File file = entry.value;

                                return Stack(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(right: 10.w),
                                      width: 80.w,
                                      height: 80.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: FileImage(file),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close,
                                              size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Deliver Button
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Delivering...')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40.w, vertical: 14.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            "Deliver Now",
                            style:
                                TextStyle(fontSize: 16.sp, color: Colors.white),
                          ),
                        ),
                      ),
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
