import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class Signupscreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  late final String? decision;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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

                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 80.h,
                      width: 200.w,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Mr / Mrs dropdown
                  CustomDropdown(
                    hint: "Title",
                    items: const ["Mr", "Mrs", "Do not want to Specify"],
                    isSearchable: false,
                    onSelectItem: (item) {
                      decision = item;
                    },
                  ),

                  SizedBox(height: 10.h),

                  // First Name
                  CustomTextField(
                    hintText: "First Name",
                    controller: firstNameController,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter first name';
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
                      if (value == null || value.isEmpty)
                        return 'Enter last name';
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
                      if (value == null || value.isEmpty) return 'Enter email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Enter valid email';
                      return null;
                    },
                  ),

                  SizedBox(height: 10.h),

                  // Phone number
                  CustomTextField(
                    hintText: "Phone number",
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter phone number';
                      if (value.length < 10) return 'Enter valid phone number';
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
                      if (value == null || value.isEmpty)
                        return 'Enter password';
                      if (value.length < 8)
                        return 'Password must be at least 8 characters';
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
                      if (value == null || value.isEmpty)
                        return 'Re-enter password';
                      if (value != passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Signup Button
                  PrimaryButton(
                    text: "Signup",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // All fields valid, navigate
                        Navigator.pushReplacementNamed(context, MyRoutes.otp);
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
}
