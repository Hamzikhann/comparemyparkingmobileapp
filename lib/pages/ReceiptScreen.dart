import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/models/PaymentResponse.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:parkingapp/services/notification_service.dart';

class ReceiptScreen extends StatefulWidget {
  final Payment payment;

  const ReceiptScreen({super.key, required this.payment});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Transaction Details",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Archivo',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Colors.black, size: 24.sp),
            onPressed: () => _captureAndSharePng(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            20.h + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(key: _receiptKey, child: _buildReceiptCard()),
              SizedBox(height: 30.h),
              _buildActionButtons(context),
              SizedBox(height: 20.h), // Extra spacing for small screens
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo at the top
          Container(
            padding: EdgeInsets.all(16.w),
            child: Image.asset('assets/images/logo.png', height: 40.h),
          ),

          // Top Section: status and Amount
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Color(0xFF4B725D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 32.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Payment Success",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Archivo',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _formatDate(
                    widget.payment.createdAt,
                  ), // Use payment creation date
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                    fontFamily: 'Archivo',
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  "£${widget.payment.totalPayment}", // Use real payment amount
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                  ),
                ),
              ],
            ),
          ),

          // Ticket Sawtooth divider (Visual trick or just a dashed line)
          _buildDashedDivider(),

          // Details Section
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                _buildInfoRow2("Reference ID", widget.payment.referenceNo),
                _buildInfoRow("Payment Method", widget.payment.paymentMethod),
                _buildInfoRow("Status", "Completed", color: Colors.green),
                Divider(height: 32.h, color: Colors.grey[200]),
                _buildInfoRow("Service", "Car Parking"),
                _buildInfoRow("Airport", widget.payment.booking.airport),
                _buildInfoRow(
                  "Vehicle",
                  "N/A",
                ), // Payment model doesn't have vehicle info
                _buildInfoRow("Duration", _getDurationString()),
              ],
            ),
          ),

          // Total Section
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Paid",
                  style: TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Archivo',
                  ),
                ),
                Text(
                  "£${widget.payment.totalPayment}",
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Container(
      color: Colors.transparent,
      child: Container(
        height: 20.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 14.sp,
              fontFamily: 'Archivo',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Color(0xFF1A1A2E),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Archivo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow2(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 14.sp,
              fontFamily: 'Archivo',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Color(0xFF1A1A2E),
              fontSize: 6.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Archivo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _downloadPdf(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF4B725D),
              side: BorderSide(color: Color(0xFF4B725D)),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  "Download PDF",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Archivo',
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _captureAndSharePng(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B725D),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, size: 20.sp, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  "Share",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Archivo',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary = _receiptKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/receipt.png');
      await file.writeAsBytes(pngBytes);

      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Parking Receipt',
        subject: 'Parking Receipt',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint("Error sharing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to share receipt image: $e")),
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _getDurationString() {
    try {
      final start = DateTime.parse(
        "${widget.payment.booking.startDate} ${widget.payment.booking.startTime}",
      );
      final end = DateTime.parse(
        "${widget.payment.booking.endDate} ${widget.payment.booking.endTime}",
      );
      final days = end.difference(start).inDays;
      if (days == 0) return "1 Day";
      return "$days Days";
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {

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
                pw.Center(child: pw.Image(logoImage, width: 150, height: 50)),
                pw.SizedBox(height: 20),

                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#4B725D'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '£${widget.payment.totalPayment}',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _formatDate(widget.payment.createdAt),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Details
                pw.Text(
                  'Transaction Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfRow('Reference ID', widget.payment.referenceNo),
                _buildPdfRow('Payment Method', widget.payment.paymentMethod),
                _buildPdfRow('Status', 'Completed'),
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
                _buildPdfRow('Service', 'Car Parking'),
                _buildPdfRow('Airport', widget.payment.booking.airport),
                _buildPdfRow('Duration', _getDurationString()),
                _buildPdfRow('Start Date', widget.payment.booking.startDate),
                _buildPdfRow('End Date', widget.payment.booking.endDate),
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
                        '£${widget.payment.totalPayment}',
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
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/receipt_$timestamp.pdf');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to download PDF: $e")));
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
}
