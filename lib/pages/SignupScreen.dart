import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 80.h,
                      width: 200.w,
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

                  // Phone Number
                  CustomTextField(
                    hintText: "Phone number",
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Phone number must be at least 10 digits';
                      }
                      return null;
                    },
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
                        registerUser(selectedTitle!,firstNameController.text,lastNameController.text,emailController.text,phoneController.text,passwordController.text,confirmPasswordController.text);
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
    );
  }
  // In your signup screen or provider
Future<void> registerUser(String title,
   String firstName,
   String lastName,
   String email,
   String phoneNo,
   String password,
   String confirmPassword) async {
    GeneralRepository().signup(
      title: title,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNo: phoneNo,
      password: password,
      confirmPassword: confirmPassword,
    ).then((value) {
      Alertify.showAlert(
        duration: 1,
        alertKey: 'signup',
        message: 'Signup successfully!',
        type: AlertType.success,
        onClose: () {
          Globals.user = value;
          SharedStorage.saveUser(value);
          emailController.clear();
          passwordController.clear();
          Navigator.pushReplacementNamed(context, MyRoutes.mainPage);
        },
      );
    });
 
}
}
