// ignore_for_file: unused_catch_stack

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // We can track selected method if we implement multiple real gateways.
  // For now, only Card (Stripe) is functional based on existing code.

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handlePayment(
      String paymentIntentId, String paymentMethod) async {
    try {
      final result = await GeneralRepository().bookParking(
        // Booking
        startDate: Globals.startDate,
        startTime: Globals.startTime,
        endDate: Globals.endDate,
        endTime: Globals.endTime,
        airport: Globals.selectedAirport,

        // Flight
        outboundTerminal: Globals.booking_info_model?.outBoundTerminal ?? "",
        inboundTerminal: Globals.booking_info_model?.inBoundTerminal ?? "",
        outboundFlightNo: "00000",
        inboundFlightNo: "00000",

        // Customer
        title: Globals.booking_info_model?.title ?? "",
        firstName: Globals.booking_info_model?.firstName ?? "",
        lastName: Globals.booking_info_model?.lastName ?? "",
        email: Globals.booking_info_model?.email ?? "",
        phoneNo: Globals.booking_info_model?.phone ?? "",

        // Vehicle
        vehicleRegistrationNo: Globals.booking_info_model?.vehicleRegNo ?? "",
        vehicleManufacturer: Globals.booking_info_model?.carMaker ?? "",
        vehicleYear: Globals.booking_info_model?.carModel ?? "",
        vehicleModel: Globals.booking_info_model?.carModel ?? "",
        vehicleColor: Globals.booking_info_model?.carColor ?? "",
        type: Globals.booking_info_model?.type ?? "",
        numberOfPassengers: Globals.booking_info_model?.noOfPassengers ?? "1",

        // Package
        userId: Globals.user?.id ?? "",
        name: Globals.option?.name ?? "",
        price: Globals.option?.price ?? "",
        description: Globals.option?.description ??
            Globals.option?.frontPageSummary ??
            "",
        bulletPoints: List<String>.from(Globals.option?.bulletPoints ?? []),
        totalPayment: Globals.option?.price ?? "",
        packageType: Globals.option?.type ?? "",

        // Payment
        referenceNo: "STRIPE-$paymentIntentId",
        paymentMethod: paymentMethod,
        paymentMethodDisplay:
            paymentMethod == 'apple_pay' ? "Apple Pay" : "Credit / Debit Card",
        paymentStatus: "completed",
        paymentDate: DateTime.now().toIso8601String(),
        transactionId: paymentIntentId,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        MyRoutes.bookingConfirmation,
        (_) => false,
        arguments: result,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  Future<void> startStripePayment(String method) async {
    try {
      final rawAmount =
          (Globals.option?.price ?? "0").replaceAll(RegExp(r'[^\d.]'), '');
      final amountInPence = (double.tryParse(rawAmount)!).toInt().toString();

      debugPrint('Creating payment intent for amount: $amountInPence pence');

      final response = await GeneralRepository().createPaymentIntent(
          amount: amountInPence,
          currency: "gbp",
          startDate: Globals.startDate,
          endDate: Globals.endDate);

      final clientSecret = response['paymentIntent']?['client_secret'] ??
          response['clientSecret'];
      if (clientSecret == null)
        throw Exception('Missing client secret in response');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Parking Pilot',
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'GB',
            cartItems: [], // Can be empty, Stripe uses total from Intent
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'GB',
            testEnv: true, // Set to false for production
            currencyCode: 'GBP',
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      final paymentId =
          response['paymentIntent']?['id'] ?? response['paymentId'];

      await _handlePayment(paymentId, method);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User cancelled, do nothing
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Payment error: ${e.error.localizedMessage}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Payment',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Booking Summary Wrapper
                    _buildBookingSummaryCard(),

                    SizedBox(height: 24.h),

                    Text("Payment Method",
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Archivo')),
                    SizedBox(height: 12.h),

                    // Layout: Row with Payment Methods (Left) and Order Summary (Right) for Tablet/Web?
                    // But for Mobile, usually stacked. Design shows possibly side-by-side or stacked.
                    // Given standard mobile width, I will stack them but style them distinctively.
                    // Actually design shows separate "Choose Payment Method" box and "Order Summary" box side-by-side?
                    // If it's mobile, they should be stacked. Let's stack them nicely.

                    _buildPaymentMethodsSection(),

                    SizedBox(height: 24.h),

                    _buildOrderSummaryCard(),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Booking Summary",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo')),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryLabel("Flight Details"),
                    _buildSummaryText(
                        "Outbound: ${Globals.booking_info_model?.outBoundTerminal ?? 'N/A'}"),
                    _buildSummaryText(
                        "Inbound: ${Globals.booking_info_model?.inBoundTerminal ?? 'N/A'}"),
                    SizedBox(height: 8.h),
                    _buildSummaryLabel("Vehicle Details"),
                    _buildSummaryText(
                        "Registration: ${Globals.booking_info_model?.vehicleRegNo ?? 'N/A'}"),
                    _buildSummaryText(
                        "Type: ${Globals.booking_info_model?.type ?? 'N/A'}"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryLabel("Parking Period"),
                    _buildSummaryText(
                        "From: ${Globals.startDate} at ${Globals.startTime}"),
                    _buildSummaryText(
                        "To: ${Globals.endDate} at ${Globals.endTime}"),
                    _buildSummaryText("Airport: ${Globals.selectedAirport}"),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Color(0xFFF8FDF8), // Light greenish bg
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Payment Method",
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo')),
          SizedBox(height: 16.h),
          _buildPaymentOption(
              icon: Icons.credit_card,
              label: "Credit/Debit Card",
              subLabel: "Pay with Visa, Mastercard, or Amex",
              value: 'card',
              color: Color(0xFF4285F4),
              textColor: Colors.white),
          SizedBox(height: 12.h),
          _buildPaymentOption(
              icon: Icons.phone_iphone,
              label: "Apple Pay",
              subLabel: "Pay securely with Apple Pay",
              value: 'apple_pay',
              color: Colors.black,
              textColor: Colors.white,
              isComingSoon: false),
          SizedBox(height: 12.h),
          _buildPaymentOption(
              icon: Icons.money,
              label: "Klarna",
              subLabel: "Pay in installments",
              value: 'klarna',
              color: Color(0xFFFFB3C7),
              textColor: Colors.black,
              isComingSoon: true),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      {required IconData icon,
      required String label,
      required String subLabel,
      required String value,
      required Color color,
      required Color textColor,
      bool isComingSoon = false}) {
    // Only 'card' is interactive for now
    return GestureDetector(
      onTap: () {
        if (!isComingSoon) {
          startStripePayment(value); // Pass the selected method
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          fontFamily: 'Archivo')),
                  Text(subLabel,
                      style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 10.sp,
                          fontFamily: 'Archivo')),
                ],
              ),
            ),
            if (isComingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4.r)),
                child: Text("Coming Soon",
                    style: TextStyle(color: textColor, fontSize: 9.sp)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    double price = double.tryParse(
            (Globals.option?.price ?? "0").replaceAll(RegExp(r'[^\d.]'), '')) ??
        0.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Color(0xFFF8FDF8),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Summary",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo')),
          SizedBox(height: 12.h),
          Text(Globals.option?.name ?? "Parking Service",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  fontFamily: 'Archivo')),
          Text("Parking Type: ${Globals.option?.type ?? 'Meet and Greet'}",
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                  fontFamily: 'Archivo')),
          SizedBox(height: 12.h),
          _buildSummaryRow(
              "Check-in", "${Globals.startDate} - ${Globals.startTime}"),
          _buildSummaryRow(
              "Check-out", "${Globals.endDate} - ${Globals.endTime}"),
          SizedBox(height: 16.h),
          Divider(),
          SizedBox(height: 8.h),
          _buildPriceRow("Subtotal", "£${price.toStringAsFixed(2)}"),
          _buildPriceRow("Booking Fee", "£0.00"),
          _buildPriceRow("Taxes & Fees", "£0.00"),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Amount",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6F56),
                      fontSize: 14.sp,
                      fontFamily: 'Archivo')),
              Text("£${price.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6F56),
                      fontSize: 14.sp,
                      fontFamily: 'Archivo')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(text,
          style: TextStyle(
              color: Color(0xFF2E5B5B),
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
              fontFamily: 'Archivo')),
    );
  }

  Widget _buildSummaryText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(text,
          style: TextStyle(
              fontSize: 11.sp, color: Colors.black87, fontFamily: 'Archivo')),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(Icons.check, size: 12.sp, color: Colors.green),
          SizedBox(width: 4.w),
          Text("$label: ",
              style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Archivo')),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 11.sp, fontFamily: 'Archivo'))),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Archivo')),
          Text(price,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo')),
        ],
      ),
    );
  }
}
