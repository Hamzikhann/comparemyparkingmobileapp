import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/PrimaryButton.dart';


class OtpScreen2 extends StatefulWidget {


  @override
  State<OtpScreen2> createState() => _OtpScreen2State();
}

class _OtpScreen2State extends State<OtpScreen2> {
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
    forgotPassword(Globals.userSignup!.email);
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
    GeneralRepository().verifyEmail(Globals.userSignup!.email).then((value) {
      Alertify.showAlert(
        duration: 1,
        alertKey: 'reset',
        message: 'OTP Screen',
        type: AlertType.success,
        onClose: () {
          Globals.otp = value.otp;
        },
      );
    });
  }

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
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 24.w),
                    color: Colors.black,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, MyRoutes.signUpRoute);
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
                      style: TextStyle(fontSize: 16.sp, fontFamily: 'Archivo'),
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
                        if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
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
                    forgotPassword(Globals.userSignup!.email);
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
              const CustomAlert(alertKey: 'reset'),
              const CustomAlert(alertKey: 'signup'),
              // Next Button
              PrimaryButton(
                text: "Proceed",
                onPressed: () {
                  String otp = otpControllers.map((c) => c.text).join();
                  if (otp.trim().length == 6 && otp.trim() == Globals.otp.trim()) {
                    // Verified successfully
                    // Proceed to next screen or show success message
                    registerUser(Globals.userSignup!.title,Globals.userSignup!.firstName,Globals.userSignup!.lastName,Globals.userSignup!.email,Globals.userSignup!.phone,Globals.userSignup!.password,Globals.userSignup!.password);

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
            ],
          ),
        ),
      ),
    );
  }
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
          Navigator.pushReplacementNamed(context, MyRoutes.mainPage);
        },
      );
    });
  }


}
