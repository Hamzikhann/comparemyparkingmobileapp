import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import '../routes/MyRoutes.dart';
import '../widgets/PrimaryButton.dart';
import '../data/Globals.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/car.png',
                width: 280.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40.h),
              Text(
                'Welcome to Compare My\nAirport Parking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo',
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Compare trusted parking providers and save more on your next trip.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Archivo',
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 60.h),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'LOGIN',
                  onPressed: () {
                    Navigator.pushNamed(context, MyRoutes.loginRoute);
                  },
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Globals.user = null; // Ensure user is null for guest
                    Navigator.pushReplacementNamed(context, MyRoutes.homeRoute);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primaryNew),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'CONTINUE AS A GUEST',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Archivo',
                      color: colors.primaryNew,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, MyRoutes.signUpRoute);
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Archivo',
                        color: colors.primaryNew,
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
