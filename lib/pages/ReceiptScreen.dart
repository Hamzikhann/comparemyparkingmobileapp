import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/models/PaymentResponse.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _receiptKey,
                child: _buildReceiptCard(),
              ),
              SizedBox(height: 30.h),
              _buildActionButtons(context),
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
                      widget.payment.createdAt), // Use payment creation date
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
                _buildInfoRow("Vehicle",
                    "N/A"), // Payment model doesn't have vehicle info
                _buildInfoRow("Duration", _getDurationString()),
              ],
            ),
          ),

          // Total Section
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(20.r)),
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
            onPressed: () {
              // Mock Download behavior
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Receipt downloaded successfully")),
              );
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
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _getDurationString() {
    try {
      final start = DateTime.parse(
          "${widget.payment.booking.startDate} ${widget.payment.booking.startTime}");
      final end = DateTime.parse(
          "${widget.payment.booking.endDate} ${widget.payment.booking.endTime}");
      final days = end.difference(start).inDays;
      if (days == 0) return "1 Day";
      return "$days Days";
    } catch (e) {
      return "N/A";
    }
  }
}
