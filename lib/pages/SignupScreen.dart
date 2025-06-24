import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/SignupModel.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTitle;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Variables for phone number handling
  PhoneNumber? phoneNumber;
  String completePhoneNumber = '';

  // Method to show the exit confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit'),
            content: const Text('Are you sure you want to exit without completing the signup?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Stay on the current screen
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Exit the screen
                },
                child: const Text('Exit'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WillPopScope(
          onWillPop: _showExitConfirmationDialog,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80.h,
                        width: 200.w,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Title Dropdown
                    CustomDropdown(
                      hint: "Title",
                      items: const ["Mr", "Mrs", "Do not want to Specify"],
                      isSearchable: false,
                      onSelectItem: (item) {
                        setState(() {
                          selectedTitle = item;
                        });
                      },
                    ),

                    SizedBox(height: 10.h),

                    // First Name
                    CustomTextField(
                      hintText: "First Name",
                      controller: firstNameController,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    // Last Name
                    CustomTextField(
                      hintText: "Last Name",
                      controller: lastNameController,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    // Email
                    CustomTextField(
                      hintText: "Email",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
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

                    SizedBox(height: 10.h),

                    // Phone Number with Country Code
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.w),
                      child: IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 15.h,
                            horizontal: 10.w,
                          ),
                        ),
                        initialCountryCode: 'US', // Default country
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
                    ),

                    SizedBox(height: 10.h),

                    // Password
                    CustomTextField(
                      hintText: "Password",
                      controller: passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    // Confirm Password
                    CustomTextField(
                      hintText: "Confirm Password",
                      controller: confirmPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20.h),
                    const CustomAlert(alertKey: 'signup'),

                    // Sign Up Button
                    PrimaryButton(
                      text: "Signup",
                      onPressed: () {
                        if (_formKey.currentState!.validate() && selectedTitle != null) {
                          if (phoneNumber == null) {
                            Alertify.showAlert(
                              alertKey: 'signup',
                              message: 'Please enter a valid phone number',
                              type: AlertType.error,
                            );
                            return;
                          }
                          
                          Globals.userSignup = UserSignup(
                            title: selectedTitle!,
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: completePhoneNumber,
                            password: passwordController.text.trim(),
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
                    ),

                    SizedBox(height: 50.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?  ",
                          style:
                              TextStyle(fontSize: 14.sp, fontFamily: 'Archivo'),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, MyRoutes.loginRoute);
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: colors.primary,
                              fontFamily: 'Archivo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}