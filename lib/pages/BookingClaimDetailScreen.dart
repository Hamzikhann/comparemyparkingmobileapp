import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/utils/colors.dart';

class BookingClaimDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingClaimDetailScreen({Key? key, required this.bookingData})
      : super(key: key);

  @override
  State<BookingClaimDetailScreen> createState() =>
      _BookingClaimDetailScreenState();
}

class _BookingClaimDetailScreenState extends State<BookingClaimDetailScreen> {
  final GeneralRepository _repository = GeneralRepository();

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  void _handleClaim() async {
    final mappedData = widget.bookingData['mappedData'] ?? {};
    final registration = (widget.bookingData['registration'] ??
            mappedData['vehicleRegistrationNo'] ??
            widget.bookingData['vehicleRegistrationNo'] ??
            '')
        .toString();
    final airport = (widget.bookingData['airport'] ??
            mappedData['airport'] ??
            '')
        .toString();
    final bookingReference = (widget.bookingData['booking_reference'] ??
            widget.bookingData['bookingReference'] ??
            mappedData['referenceNo'] ??
            widget.bookingData['referenceNo'] ??
            '')
        .toString();

    if (registration.isEmpty || airport.isEmpty || bookingReference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Missing required claim information (registration, airport, or reference)')),
      );
      return;
    }

    try {
      await _repository.claimBooking(
        registration: registration,
        airport: airport,
        bookingReference: bookingReference,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking claimed successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      // Error handled by repository
    }
  }

  @override
  Widget build(BuildContext context) {
    final mappedData = widget.bookingData['mappedData'] ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: "Claim Booking",
              showBackButton: true,
              onBackPressed: _onBackPressed,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Customer Information"),
                    SizedBox(height: 16.h),
                    _buildInfoRow(
                        "Customer Name", mappedData['customerName'] ?? "N/A"),
                    SizedBox(height: 16.h),
                    _buildInfoRow("Email", mappedData['email'] ?? "N/A"),
                    SizedBox(height: 24.h),
                    _buildSectionTitle("Booking Details"),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoRow("Reference No",
                                mappedData['referenceNo'] ?? "N/A")),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: _buildInfoRow(
                                "Airport", mappedData['airport'] ?? "N/A")),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoRow("Start Date",
                                mappedData['startDate'] ?? "N/A")),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: _buildInfoRow("Start Time",
                                mappedData['startTime'] ?? "N/A")),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoRow(
                                "End Date", mappedData['endDate'] ?? "N/A")),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: _buildInfoRow(
                                "End Time", mappedData['endTime'] ?? "N/A")),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionTitle("Vehicle Details"),
                    SizedBox(height: 16.h),
                    _buildInfoRow("Registration No",
                        mappedData['vehicleRegistrationNo'] ?? "N/A"),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoRow("Manufacturer",
                                mappedData['vehicleManufacturer'] ?? "N/A")),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: _buildInfoRow(
                                "Model", mappedData['vehicleModel'] ?? "N/A")),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoRow(
                                "Color", mappedData['vehicleColor'] ?? "N/A")),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: _buildInfoRow(
                                "Passengers",
                                mappedData['numberOfPassengers']?.toString() ??
                                    "N/A")),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionTitle("Package Information"),
                    SizedBox(height: 16.h),
                    _buildInfoRow(
                        "Package Name", mappedData['packageName'] ?? "N/A"),
                    SizedBox(height: 16.h),
                    _buildInfoRow("Price", "£${mappedData['price'] ?? "0.00"}"),
                    SizedBox(height: 40.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryNew,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Claim Now",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Archivo',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        fontFamily: 'Archivo',
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Archivo',
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8.h),
        NonEditableTextField(
          hintText: "",
          value: value,
        ),
      ],
    );
  }
}
