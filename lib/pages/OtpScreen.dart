import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../routes/MyRoutes.dart';
import '../utils/colors.dart';
import '../widgets/PrimaryButton.dart';

class OtpScreen extends StatelessWidget {
  final List<TextEditingController> otpControllers = List.generate(
    4,
        (index) => TextEditingController(),
  );

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
              SizedBox(height: 40.h),

              Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 16.w),
                    color: Colors.black,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context,
                          MyRoutes.signUpRoute);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  Spacer(), // Pushes the logo to center

                  // Logo from SVG asset
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    height: 120.h,
                    width: 200.w,
                  ),

                  Spacer(), // Maintains balance in the row
                ],
              ),

              SizedBox(height: 60.h),

              // Title
              Text(
                'Enter verification code',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontFamily: 'Archivo',
                  color: colors.primary,
                ),
              ),

              SizedBox(height: 40.h),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                      (index) => SizedBox(
                    width: 20.w,  // Adjusted width
                    height: 70.h, // Fixed height
                    child: TextField(
                      controller: otpControllers[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'Archivo',
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h), // Reduced padding
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
                          otpControllers[index].clear();
                          return;
                        }
                        if (value.length == 4) {
                          for (int i = 0; i < 4; i++) {
                            otpControllers[i].text = value[i];
                            if (i == 3) FocusScope.of(context).unfocus();
                          }
                          return;
                        }
                        else if (value.length == 1 && index < 3) {
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontFamily: 'Archivo',
                      color: Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Resend OTP logic
                    },
                    child: Text(
                      "Resend",
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontFamily: 'Archivo',
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // Timer
              Text(
                "00:30",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontFamily: 'Archivo',
                  color: colors.primary,
                ),
              ),

              SizedBox(height: 40.h),

              // Next Button
              PrimaryButton(
                text: "Next",
                onPressed: () {
                  // Verify OTP and proceed
                  String otp = otpControllers.map((c) => c.text).join();
                  if (otp.length == 4) {
                    // Verification logic
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}