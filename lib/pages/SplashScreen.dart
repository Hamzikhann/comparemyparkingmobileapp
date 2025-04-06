import 'package:flutter/material.dart';
import 'dart:async'; // Import Future.delayed
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/pages/IntroScreen.dart'; // Import the IntroScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to IntroScreen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Background Image (Anchored to Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/background.svg', // Ensure correct path
              width: double.infinity,
              height: 250.h,
              fit: BoxFit.cover,
            ),
          ),

          /// Center content (Logo + Text)
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Logo
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 100.h,
                ),

                SizedBox(height: 15.h),

                /// Text (Smaller, positioned below logo)
                Text(
                  'Your no.1 parking assistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Archivo', // Ensure Archivo font is in assets/fonts
                    fontSize: 8.sp, // Adjusted text size
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
