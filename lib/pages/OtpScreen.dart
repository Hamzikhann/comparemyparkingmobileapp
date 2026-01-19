import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import '../routes/MyRoutes.dart';
import '../utils/colors.dart';
import '../widgets/PrimaryButton.dart';

class OtpScreen extends StatefulWidget {
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  Timer? _timer;
  int _remainingSeconds = 120;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 120;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> forgotPassword(String email) async {
    await GeneralRepository().forgotPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: 24.w),
                      color: Colors.black,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, MyRoutes.signUpRoute);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Spacer(),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80.h,
                      width: 200.w,
                      fit: BoxFit.contain,
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 60.h),
                Text(
                  'Enter verification code',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Archivo',
                    color: colors.primary,
                  ),
                ),
                SizedBox(height: 40.h),

                // OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50.w,
                      height: 50.h,
                      child: TextField(
                        controller: otpControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style:
                            TextStyle(fontSize: 16.sp, fontFamily: 'Archivo'),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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
                          if (value.isNotEmpty &&
                              !RegExp(r'^[0-9]$').hasMatch(value)) {
                            otpControllers[index].clear();
                            return;
                          }
                          if (value.length == 6) {
                            for (int i = 0; i < 6; i++) {
                              otpControllers[i].text = value[i];
                              if (i == 5) FocusScope.of(context).unfocus();
                            }
                            return;
                          } else if (value.length == 1 && index < 5) {
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

                // Resend code
                if (_remainingSeconds == 0)
                  GestureDetector(
                    onTap: () {
                      forgotPassword(Globals.emailReset);
                      _startTimer();
                    },
                    child: Text(
                      "Resend",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Archivo',
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'Archivo',
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Resend",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Archivo',
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 20.h),

                // Timer
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontFamily: 'Archivo',
                    color: colors.primary,
                  ),
                ),

                SizedBox(height: 40.h),

                // Next Button with bottom padding
                Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: PrimaryButton(
                    text: "Proceed",
                    onPressed: () {
                      String otp = otpControllers.map((c) => c.text).join();
                      if (otp.trim().length == 6 &&
                          otp.trim() == Globals.otp.trim()) {
                        resetPassword(
                            Globals.passwordReset, Globals.confirmPassword);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid OTP. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> resetPassword(String password, String confirmPassword) async {
    GeneralRepository().resetPassword(password, confirmPassword).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password updated successfully! Login Now"),
          duration: Duration(seconds: 2),
        ),
      );

      SharedStorage.removeFromSharedPreferences();
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, MyRoutes.loginRoute);
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }
}
