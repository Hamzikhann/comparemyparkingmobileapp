import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/PrimaryButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/widgets/reserveBooking/CustomTextFeild.dart';

class ReserveBookingScreen extends StatefulWidget {
  final ParkingOption bookingData;

  const ReserveBookingScreen({super.key, required this.bookingData});

  @override
  State<ReserveBookingScreen> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<ReserveBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Flight Details
  final TextEditingController departureFlightController =
      TextEditingController();
  final TextEditingController returnFlightController = TextEditingController();

  // User Details
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Vehicle Details
  final TextEditingController vehicleRegNoController = TextEditingController();
  final TextEditingController carMakerController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController numPassengersController = TextEditingController();

  bool agreedToTerms = false;

  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    } else if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
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
                greeting: "Registration",
                showBackButton: true,
                onBackPressed: () => _onBackPressed(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Flight Details",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown(
                                hint: "Outbound Terminal",
                                height: 45.h,
                                items: const [
                                  "California",
                                  "New York",
                                  "Texas",
                                  "Florida"
                                ],
                                isSearchable: false,
                                onSelectItem: (item) {},
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomDropdown(
                                hint: "Inbound Terminal",
                                height: 45.h,
                                items: const [
                                  "California",
                                  "New York",
                                  "Texas",
                                  "Florida"
                                ],
                                isSearchable: false,
                                onSelectItem: (item) {},
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text("Departure Flight",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo')),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text("Return Flight",
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
                              child: CustomTextField(
                                hintText: "",
                                controller: departureFlightController,
                                validator: (val) =>
                                    validateRequired(val, "Departure Flight"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: returnFlightController,
                                validator: (val) =>
                                    validateRequired(val, "Return Flight"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("User Details",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 16.h),
                        CustomDropdown(
                          hint: "Title",
                          height: 45.h,
                          items: const ["Mr", "Mrs", "Others"],
                          isSearchable: false,
                          onSelectItem: (item) {},
                        ),
                        SizedBox(height: 16.h),
                        Text("Name",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: "First",
                                controller: firstNameController,
                                validator: (val) =>
                                    validateRequired(val, "First name"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "Last",
                                controller: lastNameController,
                                validator: (val) =>
                                    validateRequired(val, "Last name"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("Phone",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (val) => validateRequired(val, "Phone"),
                        ),
                        SizedBox(height: 16.h),
                        Text("Email",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        SizedBox(height: 24.h),
                        Text("Vehicle Detail",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 24.h),
                        Text("Vehicle Registration No",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "",
                          controller: vehicleRegNoController,
                          validator: (val) =>
                              validateRequired(val, "Vehicle Registration No"),
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
                              child: CustomTextField(
                                hintText: "",
                                controller: carMakerController,
                                validator: (val) =>
                                    validateRequired(val, "Car Maker"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: carModelController,
                                validator: (val) =>
                                    validateRequired(val, "Car Model"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("No of Passengers",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "",
                          controller: numPassengersController,
                          validator: (val) =>
                              validateRequired(val, "No of Passengers"),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Checkbox(
                              value: agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreedToTerms = value ?? false;
                                });
                              },
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return const Color(0xFF201A56);
                                  }
                                  return Colors.grey.shade300;
                                },
                              ),
                              checkColor: Colors.white,
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "I agree to ",
                                  children: [
                                    TextSpan(
                                      text: "terms & conditions",
                                      style: TextStyle(
                                          color: colors.primary,
                                          decoration: TextDecoration.underline),
                                    ),
                                    const TextSpan(text: "."),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        PrimaryButton(
                          text: "Send Now",
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (agreedToTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Form Submitted!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please accept terms & conditions')),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
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
