import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class Forgotpassword extends StatelessWidget {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60.h),

                // Back button and logo row
                Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: 24.w),
                      color: Colors.black,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, MyRoutes.loginRoute);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Spacer(), // Pushes the logo to center

                    // Logo from SVG asset
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 80.h,
                      width: 200.w,
                    ),

                    Spacer(), // Maintains balance in the row
                  ],
                ),

                SizedBox(
                    height: 100
                        .h), // Reduced from 150.h to account for the row height

                // Phone Input
                CustomTextField(
                  hintText: "Phone number",
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 40.h),

                // Password Input
                CustomTextField(
                  hintText: "Password",
                  controller: passwordController,
                  obscureText: true,
                ),

                SizedBox(height: 40.h),

                // Confirm Password Input
                CustomTextField(
                  hintText: "Confirm Password",
                  controller: confirmPasswordController,
                  obscureText: true,
                ),

                SizedBox(height: 60.h),

                // Forgot Password Button
                PrimaryButton(
                  text:
                      "Reset Password", // Changed from "Forgot Password" to be more action-oriented
                  onPressed: () {
                    // Handle password reset
                  },
                ),

                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
