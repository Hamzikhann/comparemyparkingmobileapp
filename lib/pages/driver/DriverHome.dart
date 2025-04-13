import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';

class Driverhome extends StatefulWidget {
  const Driverhome({Key? key}) : super(key: key);

  @override
  State<Driverhome> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<Driverhome> {



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
                onLogoutPressed: () {
                  // Handle logout
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Replaced with non-editable version
                      NonEditableTextField(
                        hintText: "",
                        value: Globals.user?.firstName,
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
                              hintText: "0",
                              
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: NonEditableTextField(
                              hintText: "0",
                              
                            ),
                          ),
                        ],
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
