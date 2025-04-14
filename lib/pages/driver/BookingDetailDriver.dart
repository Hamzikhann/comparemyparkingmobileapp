import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';

class Bookingdetaildriver extends StatefulWidget {
  const Bookingdetaildriver({Key? key}) : super(key: key);

  @override
  State<Bookingdetaildriver> createState() => BookingdetaildriverState();
}

class BookingdetaildriverState extends State<Bookingdetaildriver> {
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
                title: "Booking Detail",
                showBackButton: true,
                onLogoutPressed: () {},
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
                      Text(
                        "Car Details:",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Archivo',
                        ),
                      ),
                      SizedBox(height: 16.h),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text("Car Maker",
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Archivo')),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text("Car Model",
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
                              hintText:
                                  "${Globals.bookingDriverResponse?.vehicles.first.vehicleManufacturer}",
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: NonEditableTextField(
                              hintText:
                                  "${Globals.bookingDriverResponse?.vehicles.first.vehicleColour}",
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
