import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/utils/colors.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),

              // Logo from SVG asset
              Center(
                child: SvgPicture.asset(
                  'assets/images/logo.svg', // Make sure this path matches your actual SVG file location
                  height: 120.h,
                  width: 200.w,
                ),
              ),

              SizedBox(height: 150.h),

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

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context,
                        MyRoutes.forgot);
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontFamily: 'Archivo',
                      color: colors.primary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 60.h),

              // Login Button
              PrimaryButton(
                text: "Login",
                onPressed: () {
                  // Handle login
                  Navigator.pushReplacementNamed(context,
                      MyRoutes.otp);
                },
              ),

              SizedBox(height: 50.h),

              // OR Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "or ",
                    style: TextStyle(fontSize: 8.sp,fontFamily: 'Archivo'),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to signup
                      Navigator.pushReplacementNamed(context,
                          MyRoutes.signUpRoute);
                    },
                    child: Text(
                      "Signup",
                      style: TextStyle(
                        fontSize: 8.sp,
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
    );
  }
}