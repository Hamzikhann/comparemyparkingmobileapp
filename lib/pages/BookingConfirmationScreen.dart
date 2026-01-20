import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/airport_service_config.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:parkingapp/services/notification_service.dart';

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

  Future<void> _downloadPdf() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }
      }

      // Load logo image
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo at the top
                pw.Center(
                  child: pw.Image(logoImage, width: 150, height: 50),
                ),
                pw.SizedBox(height: 20),

                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1B4D4D'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Booking Confirmation',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        Globals.option?.price ?? '0.00',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Status: Confirmed',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Customer Information
                pw.Text(
                  'Customer Information',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfRow('Name',
                    '${Globals.booking_info_model?.firstName} ${Globals.booking_info_model?.lastName}'),
                _buildPdfRow(
                    'Email', Globals.booking_info_model?.email ?? 'N/A'),
                _buildPdfRow(
                    'Phone', Globals.booking_info_model?.phone ?? 'N/A'),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Booking Details
                pw.Text(
                  'Booking Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfRow('Airport', Globals.selectedAirport),
                _buildPdfRow('Start Date', Globals.startDate),
                _buildPdfRow('End Date', Globals.endDate),
                _buildPdfRow('Vehicle Reg',
                    Globals.booking_info_model?.vehicleRegNo ?? 'N/A'),
                _buildPdfRow('Vehicle',
                    '${Globals.booking_info_model?.carMaker}, ${Globals.booking_info_model?.carModel}'),
                pw.SizedBox(height: 20),

                // Total
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8F9FA'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Paid',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        Globals.option?.price ?? '0.00',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file =
          File('${directory!.path}/booking_confirmation_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      // Show notification
      await NotificationService().showDownloadNotification(
        filePath: file.path,
        title: 'Receipt Downloaded',
        body: 'Receipt downloaded successfully',
      );

      // Auto-open the PDF
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded to: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download PDF: $e")),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
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
                              "Outbound Terminal:\n${Globals.booking_info_model?.outBoundTerminal}",
                              "Outbound Flight:\n${Globals.booking_info_model?.departureFlight}",
                              "Inbound Terminal:\n${Globals.booking_info_model?.inBoundTerminal}",
                              "Inbound Flight:\n${Globals.booking_info_model?.returnFlight}",
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Builder(
                      builder: (context) {
                        final packageType =
                            Globals.option?.type ?? 'meet and greet';
                        final serviceInfo = getAirportServiceInfo(
                          Globals.selectedAirport,
                          packageType,
                        );

                        if (serviceInfo == null) return const SizedBox.shrink();

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Service Information",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E5B5B),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  if (serviceInfo['contact']?['number'] !=
                                      null) ...[
                                    _buildLabelValueRow(
                                        "Service Contact",
                                        serviceInfo['contact']?['number'],
                                        Icons.phone),
                                    SizedBox(height: 8.h),
                                  ],
                                  if (serviceInfo['location']?['address'] !=
                                      null) ...[
                                    _buildLabelValueRow(
                                        "Service Location",
                                        serviceInfo['location']!['address'],
                                        Icons.location_on),
                                    SizedBox(height: 16.h),
                                    const Divider(),
                                    SizedBox(height: 16.h),
                                  ],
                                  if (serviceInfo['arrival_procedure'] !=
                                      null) ...[
                                    Text(
                                      "Arrival Procedure",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      serviceInfo['arrival_procedure'],
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],
                                  if (serviceInfo['departure_procedure'] !=
                                      null) ...[
                                    Text(
                                      "Departure Procedure",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      serviceInfo['departure_procedure'],
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                          ],
                        );
                      },
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
                            onPressed: _downloadPdf,
                            icon:
                                const Icon(Icons.download, color: Colors.white),
                            label: const Text("Download PDF Receipt",
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

  Widget _buildLabelValueRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: const Color(0xFF2E5B5B)),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
