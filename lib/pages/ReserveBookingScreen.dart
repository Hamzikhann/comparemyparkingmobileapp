import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/widgets/reserveBooking/CustomTextFeild.dart';

class ReserveBookingScreen extends StatefulWidget {
  const ReserveBookingScreen({Key? key}) : super(key: key);

  @override
  State<ReserveBookingScreen> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<ReserveBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController lineAddressController = TextEditingController();

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
                greeting: "Reserve Booking",
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
                        Text("Parking Application",
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16.h),
                        Text("Name", style: TextStyle(color: colors.textGray)),
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
                        Text("Phone", style: TextStyle(color: colors.textGray)),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (val) => validateRequired(val, "Phone"),
                        ),
                        SizedBox(height: 16.h),
                        Text("Email", style: TextStyle(color: colors.textGray)),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        SizedBox(height: 24.h),
                        Text("Vehicle Information",
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter plate number",
                          controller: licensePlateController,
                          validator: (val) =>
                              validateRequired(val, "License plate"),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter state",
                          controller: stateController,
                          validator: (val) => validateRequired(val, "State"),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter vehicle model",
                          controller: modelController,
                          validator: (val) => validateRequired(val, "Model"),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter vehicle color",
                          controller: colorController,
                          validator: (val) => validateRequired(val, "Color"),
                        ),
                        SizedBox(height: 24.h),
                        Text("Address",
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter address",
                          controller: addressController,
                          validator: (val) => validateRequired(val, "Address"),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter street address",
                          controller: streetController,
                          validator: (val) =>
                              validateRequired(val, "Street address"),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          hintText: "Enter line address",
                          controller: lineAddressController,
                          validator: (val) =>
                              validateRequired(val, "Line address"),
                        ),
                        SizedBox(height: 16.h),
                        Text("State", style: TextStyle(color: colors.textGray)),
                        SizedBox(height: 8.h),
                        CustomDropdown(
                          hint: "---Select State---",
                          items: const [
                            "California",
                            "New York",
                            "Texas",
                            "Florida"
                          ],
                          isSearchable: false,
                          onSelectItem: (item) {
                            // Handle selection
                          },
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
                                    return Color(0xFF201A56);
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
                        CustomButton(
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
