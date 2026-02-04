import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/airport_service_config.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Bookingdetailuser extends StatefulWidget {
  const Bookingdetailuser({Key? key}) : super(key: key);

  @override
  State<Bookingdetailuser> createState() => BookingdetailuserState();
}

class BookingdetailuserState extends State<Bookingdetailuser> {
  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = "+44 7508 866707";
    print("phoneNumber: $phoneNumber");
    final message = Uri.encodeComponent("Hello, I need help with my booking.");
    final url = Uri.parse(
        "https://api.whatsapp.com/send?phone=$phoneNumber&text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          padding: EdgeInsets.all(8),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkPoints = (GlobalsBookingDetail
                .bookingdetailuser?.bookingCheckPoints.isNotEmpty ??
            false)
        ? GlobalsBookingDetail.bookingdetailuser!.bookingCheckPoints.first
            .bookingCheckPointsImages
        : [];
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
                greeting: "Booking Detail",
                showBackButton: true,
                onBackPressed: () => _onBackPressed(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking Information",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24.h),
                      Text("Customer Name",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.firstName} ${GlobalsBookingDetail.bookingdetailuser?.registrations.first.lastName}",
                      ),
                      SizedBox(height: 24.h),
                      Text("Contact Number",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.phoneNo}",
                      ),
                      SizedBox(height: 24.h),
                      Text("Car Details:",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      Text("Car Registration No",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${GlobalsBookingDetail.bookingdetailuser?.vehicles.first.vehicleRegistration}",
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Maker",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.vehicles.first.vehicleManufacturer}",
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
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.vehicles.first.vehicleModel}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Car Color",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.vehicles.first.vehicleColour}",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Passengers",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.vehicles.first.numberofPassengers}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Text("Flight Details:",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      Text("Out Bound Terminal",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.outboundTerminal}",
                      ),
                      SizedBox(height: 16.h),
                      Text("In Bound Terminal",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      NonEditableTextField(
                        hintText: "",
                        value:
                            "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.inboundTerminal}",
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Out Bound Flight",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.outboundFlightNo}",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("In Bound Flight",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                NonEditableTextField(
                                  hintText:
                                      "${GlobalsBookingDetail.bookingdetailuser?.registrations.first.inboundFlightNo}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      /// ✅ Checkpoint Images
                      if (checkPoints.isNotEmpty) ...[
                        Text("Booking Checkpoints:",
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: checkPoints
                              .map((url) => GestureDetector(
                                    onTap: () => _showImageDialog(
                                        "https://stanstedairportparking247.com/${url.imageUrl}"),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        "https://stanstedairportparking247.com/${url.imageUrl}",
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        SizedBox(height: 24.h),
                      ],

                      /// ✅ WhatsApp + Location Button for Reserved bookings
                      if (Globals.detailType == "reserved") ...[
                        GestureDetector(
                          onTap: _launchWhatsApp,
                          child: Row(
                            children: [
                              Icon(Icons.support,
                                  color: Colors.green, size: 28.sp),
                              SizedBox(width: 10.w),
                              Text(
                                "Need help? Chat with us on WhatsApp",
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.blue),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 16.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                LocationPermission permission =
                                    await Geolocator.checkPermission();

                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                }

                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Location permission is permanently denied. Please enable it in settings."),
                                      action: SnackBarAction(
                                        label: "Open Settings",
                                        onPressed: () {
                                          openAppSettings();
                                        },
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (permission == LocationPermission.always ||
                                    permission ==
                                        LocationPermission.whileInUse) {
                                  bool isLocationEnabled = await Geolocator
                                      .isLocationServiceEnabled();
                                  if (!isLocationEnabled) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Please enable location services.")),
                                    );
                                    return;
                                  }

                                  Position position =
                                      await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high);
                                  postLocation(
                                      GlobalsBookingDetail.bookingdetailuser!
                                          .registrations.first.bookingId,
                                      position.latitude.toString(),
                                      position.longitude.toString());
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Location permission is required.")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                backgroundColor: colors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                "Share Location",
                                style: TextStyle(
                                    fontSize: 16.sp, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
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

  Future<void> postLocation(
      String bookingID, String latitude, String longitude) async {
    GeneralRepository()
        .postLocation(bookingID, latitude, longitude)
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Location shared. The driver will reach the location soon.")),
      );
    });
  }
}
