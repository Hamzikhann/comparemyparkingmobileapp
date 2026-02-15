import 'package:flutter/material.dart';
import 'dart:async'; // Import Future.delayed
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/IntroScreen.dart';
import 'package:parkingapp/pages/MainScreen.dart';
import 'package:parkingapp/pages/driver/DriverHome.dart';
import 'package:parkingapp/utils/colors.dart';
// Import the MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _initializeApp(); // Move the async logic to a separate method
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Load user data asynchronously
    await SharedStorage.loadUser();

    // Navigate to the appropriate screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (Globals.user != null) {
        if (Globals.roleTitle == "Employee") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Driverhome()),
          );
        } else if (Globals.roleTitle == "Administrator") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
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
        } else if (Globals.roleTitle == "Administrator") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
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
          /// Logo in center
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/logo.png',
              height: 120.h,
              width: 250.w,
              fit: BoxFit.contain,
            ),
          ),

          /// Texts at bottom with animation
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Secure Parking',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.secondarynew,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Easy Booking',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.secondarynew,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Trusted seller',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.secondarynew,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Over 2m+ satisfied users',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.secondarynew,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
