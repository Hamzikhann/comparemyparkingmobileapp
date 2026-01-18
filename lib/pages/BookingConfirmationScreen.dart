import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingResult;

  const BookingConfirmationScreen({Key? key, this.bookingResult})
      : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _captureAndShareReceipt() async {
    try {
      // Small delay to ensure the UI has finished painting and avoids '!debugNeedsPaint' assertion
      await Future.delayed(const Duration(milliseconds: 300));

      final RenderRepaintBoundary? boundary = _receiptKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find render object for receipt");
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/parking_receipt.png');
      await file.writeAsBytes(pngBytes);

      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Parking Booking Confirmation',
        subject: 'My Parking Receipt',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint("Error sharing receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to share receipt: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Map<String, dynamic>? bookingData = widget.bookingResult ?? args;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, MyRoutes.mainPage, (_) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: RepaintBoundary(
              key: _receiptKey,
              child: Container(
                color: Colors.white, // Ensure background is captured
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.check, color: Colors.green, size: 40.sp),
                    ),
                    SizedBox(height: 20.h),

                    // Title
                    Text(
                      "Booking Confirmed!",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Subtitle
                    Text(
                      "Your payment has been successfully done. These rules and regulations for the use of ${Globals.selectedAirport} Parking Area.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // Booking Logo & Confirmation Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png', height: 40.h),
                          SizedBox(height: 16.h),
                          Text(
                            "Booking Confirmation",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E5B5B),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Reference: ",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13.sp),
                                ),
                                TextSpan(
                                  text: bookingData?['referenceNo'] ??
                                      "No Reference Number",
                                  style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Status: Confirmed",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Payment Summary
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D4D), // Dark teal
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Payment Summary",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Total payment Paid",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "${Globals.option?.price ?? '0.00'}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "Payment Method",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.sp),
                          ),
                          Text(
                            "Credit Card",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Reference: ${bookingData?['referenceNo'] ?? 'No Reference Number'}",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Info Rows
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            "Customer Information",
                            [
                              "Full Name:\n${Globals.booking_info_model?.firstName} ${Globals.booking_info_model?.lastName}",
                              "Email Address:\n${Globals.booking_info_model?.email}",
                              "Phone:\n${Globals.booking_info_model?.phone}",
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildInfoCard(
                            "Flight Details",
                            [
                              "Outbound Flight:\n${Globals.booking_info_model?.outBoundTerminal}",
                              "Inbound Flight:\n${Globals.booking_info_model?.inBoundTerminal}",
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            "Vehicle Details",
                            [
                              "Registration:\n${Globals.booking_info_model?.vehicleRegNo}",
                              "Make & Model:\n${Globals.booking_info_model?.carMaker}, ${Globals.booking_info_model?.carModel}",
                              "Color:\n${Globals.booking_info_model?.carColor}",
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildInfoCard(
                            "Booking Period",
                            [
                              "Start Date:\n${Globals.startDate}",
                              "End Date:\n${Globals.endDate}",
                              "Airport:\n${Globals.selectedAirport}",
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Important Info Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Important information & Next Steps",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Next Steps Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStepCard(
                            "Check Your Email",
                            "Your payment has been successfully done.",
                            const Color(0xFFF1F8F6)),
                        _buildStepCard(
                            "Bring Your Documents",
                            "Your payment has been successfully done.",
                            const Color(0xFFE8F5F9)),
                        _buildStepCard(
                            "Security & Safety",
                            "Your payment has been successfully done.",
                            const Color(0xFFF7F2FA)),
                        _buildStepCard(
                            "Arrival Instructions",
                            "Your payment has been successfully done.",
                            const Color(0xFFFEFBEA)),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Download Document Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.download_for_offline_outlined,
                                  color: Colors.teal, size: 24.sp),
                              SizedBox(width: 12.w),
                              Text(
                                "Download Document",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E5B5B),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 36.w, top: 4.h, bottom: 16.h),
                            child: Text(
                              "Your payment has been successfully done. These rules and regulations.",
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _captureAndShareReceipt,
                            icon:
                                const Icon(Icons.download, color: Colors.white),
                            label: const Text("Get PDF Receipt",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF234D4D),
                              minimumSize: Size(double.infinity, 50.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E5B5B),
            ),
          ),
          SizedBox(height: 8.h),
          ...details.map((detail) {
            var parts = detail.split('\n');
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parts[0],
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                  Text(
                    parts.length > 1 ? parts[1] : "",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStepCard(String title, String subtitle, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E5B5B),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10.sp, color: Colors.grey[700], height: 1.3),
          ),
        ],
      ),
    );
  }
}
