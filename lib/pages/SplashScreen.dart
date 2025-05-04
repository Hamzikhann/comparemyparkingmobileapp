import 'package:flutter/material.dart';
import 'dart:async'; // Import Future.delayed
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/IntroScreen.dart';
import 'package:parkingapp/pages/MainScreen.dart';
import 'package:parkingapp/pages/admin/AdminHome.dart';
import 'package:parkingapp/pages/driver/DriverHome.dart';
// Import the MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp(); // Move the async logic to a separate method
  }

  Future<void> _initializeApp() async {
    // Load user data asynchronously
    await SharedStorage.loadUser();

    // Navigate to the appropriate screen after a delay
    Future.delayed(Duration(seconds: 5), () {
      if (Globals.user != null) {
        if (Globals.roleTitle == "Employee") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Driverhome()),
          );
        } else if(Globals.roleTitle == "Administrator"){
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Adminhome()),
          );
        }else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } else {
        if (Globals.roleTitle == "Employee") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Driverhome()),
          );
        } 
        else if(Globals.roleTitle == "Administrator"){
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Adminhome()),
          );
        }
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => IntroScreen()),
          );
        }
      }
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
                    fontFamily:
                        'Archivo', // Ensure Archivo font is in assets/fonts
                    fontSize: 16.sp, // Adjusted text size
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
