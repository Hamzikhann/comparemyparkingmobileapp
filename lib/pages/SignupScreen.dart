import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/SignupModel.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTitle;
  bool _agreedToTerms = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables for phone number handling
  PhoneNumber? phoneNumber;
  String completePhoneNumber = '';

  // Method to show the exit confirmation dialog

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Back Button
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Welcome Heading
                  Text(
                    'Welcome to\nCompare my\nparking',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontFamily: 'Archivo',
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Subtitle
                  Text(
                    'Please complete your profile to create\nParkir.in account',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                      color: Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Title Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Archivo',
                          color: Color(0xFF414141),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      CustomDropdown(
                        hint: "Mr",
                        items: const ["Mr", "Mrs", "Do not want to Specify"],
                        isSearchable: false,
                        useLightBackground: true,
                        onSelectItem: (item) {
                          setState(() {
                            selectedTitle = item;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Full Name
                  CustomTextField(
                    labelText: 'Full Name',
                    hintText: "Ali Malik",
                    controller: fullNameController,
                    keyboardType: TextInputType.name,
                    useLightBackground: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 12.h),

                  // Phone Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Archivo',
                          color: Color(0xFF414141),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          hintText: '+6289876543210',
                          hintStyle: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontFamily: 'Archivo',
                            fontSize: 14.sp,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.red.shade300),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 16.w,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Archivo',
                          color: Color(0xFF414141),
                        ),
                        initialCountryCode: 'US',
                        onChanged: (PhoneNumber number) {
                          phoneNumber = number;
                          completePhoneNumber = number.completeNumber;
                        },
                        validator: (value) {
                          if (value == null || value.number.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.number.length < 6) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Email
                  CustomTextField(
                    labelText: 'Email',
                    hintText: "email@email.com",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    useLightBackground: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 30.h),

                  // Terms and Conditions Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: Color(0xFF4B725D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreedToTerms = !_agreedToTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Archivo',
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(text: 'I agree to '),
                                TextSpan(
                                  text: 'Terms and condition',
                                  style: TextStyle(
                                    color: Color(0xFF4B725D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Alert notification
                  const CustomAlert(alertKey: 'signup'),

                  // Sign Up Button
                  Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B725D),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!_agreedToTerms) {
                            Alertify.showAlert(
                              alertKey: 'signup',
                              message: 'Please agree to Terms and Conditions',
                              type: AlertType.error,
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate() &&
                              selectedTitle != null) {
                            if (phoneNumber == null) {
                              Alertify.showAlert(
                                alertKey: 'signup',
                                message: 'Please enter a valid phone number',
                                type: AlertType.error,
                              );
                              return;
                            }

                            // Split full name into first and last name
                            List<String> nameParts =
                                fullNameController.text.trim().split(' ');
                            String firstName =
                                nameParts.isNotEmpty ? nameParts[0] : '';
                            String lastName = nameParts.length > 1
                                ? nameParts.sublist(1).join(' ')
                                : '';

                            Globals.userSignup = UserSignup(
                              title: selectedTitle!,
                              firstName: firstName,
                              lastName: lastName,
                              email: emailController.text.trim(),
                              phone: completePhoneNumber,
                              password:
                                  "defaultPassword123", // Since password field is removed
                            ) as UserSignup?;
                            Navigator.pushReplacementNamed(
                                context, MyRoutes.otpsignup);
                          } else if (selectedTitle == null) {
                            Alertify.showAlert(
                              alertKey: 'signup',
                              message: 'Please select a title',
                              type: AlertType.error,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: 'Archivo',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
