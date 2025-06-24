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
  // Controllers for email OTP (6 digits)
  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  // Controllers for phone OTP (6 digits)
  final List<TextEditingController> phoneOtpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  Timer? _timer;
  int _remainingSeconds = 120;
  bool _emailVerified = false;
  bool _phoneVerified = false;
  String? _emailOtp;
  String? _phoneOtp;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Send both verification requests when screen loads
    _sendEmailVerification();
    _sendPhoneVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in emailOtpControllers) {
      controller.dispose();
    }
    for (var controller in phoneOtpControllers) {
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

  Future<void> _sendEmailVerification() async {
    try {
      final response = await GeneralRepository().verifyEmail(Globals.userSignup!.email);
      setState(() {
        _emailOtp = response.otp;
      });
      Alertify.showAlert(
        duration: 1,
        alertKey: 'reset',
        message: 'Email OTP sent successfully',
        type: AlertType.success,
      );
    } catch (e) {
      Alertify.showAlert(
        duration: 2,
        alertKey: 'error',
        message: 'Failed to send email OTP: ${e.toString()}',
        type: AlertType.error,
      );
    }
  }

  Future<void> _sendPhoneVerification() async {
    try {
      final response = await GeneralRepository().verifyPhone(Globals.userSignup!.phone);
      setState(() {
        _phoneOtp = response.otp;
      });
      Alertify.showAlert(
        duration: 1,
        alertKey: 'reset',
        message: 'Phone OTP sent successfully',
        type: AlertType.success,
      );
    } catch (e) {
      Alertify.showAlert(
        duration: 2,
        alertKey: 'error',
        message: 'Failed to send phone OTP: ${e.toString()}',
        type: AlertType.error,
      );
    }
  }

  void _verifyEmailOtp() {
    final enteredOtp = emailOtpControllers.map((c) => c.text).join();
    if (enteredOtp.length == 6 && enteredOtp == _emailOtp) {
      setState(() {
        _emailVerified = true;
      });
      Alertify.showAlert(
        duration: 1,
        alertKey: 'success',
        message: 'Email verified successfully',
        type: AlertType.success,
      );
    } else {
      Alertify.showAlert(
        duration: 2,
        alertKey: 'error',
        message: 'Invalid email OTP',
        type: AlertType.error,
      );
    }
  }

  void _verifyPhoneOtp() {
    final enteredOtp = phoneOtpControllers.map((c) => c.text).join();
    if (enteredOtp.length == 6 && enteredOtp == _phoneOtp) {
      setState(() {
        _phoneVerified = true;
      });
      Alertify.showAlert(
        duration: 1,
        alertKey: 'success',
        message: 'Phone verified successfully',
        type: AlertType.success,
      );
    } else {
      Alertify.showAlert(
        duration: 2,
        alertKey: 'error',
        message: 'Invalid phone OTP',
        type: AlertType.error,
      );
    }
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
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
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
                
                // Email Verification Section
                Text(
                  'Email Verification',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Archivo',
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Enter verification code sent to ${Globals.userSignup!.email}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20.h),
                
                // Email OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 40.w,
                      height: 50.h,
                      child: TextField(
                        controller: emailOtpControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_emailVerified,
                        style: TextStyle(fontSize: 16.sp, fontFamily: 'Archivo'),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _emailVerified ? Colors.green : colors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _emailVerified ? Colors.green : colors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _emailVerified ? Colors.green : colors.primary),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
                            emailOtpControllers[index].clear();
                            return;
                          }
                          if (value.length == 6) {
                            for (int i = 0; i < 6; i++) {
                              emailOtpControllers[i].text = value[i];
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
                SizedBox(height: 10.h),
                if (!_emailVerified)
                  ElevatedButton(
                    onPressed: _verifyEmailOtp,
                    child: Text('Verify Email',style: TextStyle(color: colors.grayNavLight),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                    ),
                  ),
                SizedBox(height: 30.h),
                
                // Phone Verification Section
                Text(
                  'Phone Verification',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Archivo',
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Enter verification code sent to ${Globals.userSignup!.phone}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20.h),
                
                // Phone OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 40.w,
                      height: 50.h,
                      child: TextField(
                        controller: phoneOtpControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_phoneVerified,
                        style: TextStyle(fontSize: 16.sp, fontFamily: 'Archivo'),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _phoneVerified ? Colors.green : colors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _phoneVerified ? Colors.green : colors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _phoneVerified ? Colors.green : colors.primary),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
                            phoneOtpControllers[index].clear();
                            return;
                          }
                          if (value.length == 6) {
                            for (int i = 0; i < 6; i++) {
                              phoneOtpControllers[i].text = value[i];
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
                SizedBox(height: 10.h),
                if (!_phoneVerified)
                  ElevatedButton(
                    onPressed: _verifyPhoneOtp,
                    child: Text('Verify Phone',style: TextStyle(color: colors.grayNavLight)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                    ),
                  ),
                SizedBox(height: 20.h),

                // Resend code
                if (_remainingSeconds == 0)
                  Column(
                    children: [
                      if (!_emailVerified)
                        GestureDetector(
                          onTap: () {
                            _sendEmailVerification();
                            _startTimer();
                          },
                          child: Text(
                            "Resend Email OTP",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'Archivo',
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (!_phoneVerified)
                        GestureDetector(
                          onTap: () {
                            _sendPhoneVerification();
                            _startTimer();
                          },
                          child: Text(
                            "Resend Phone OTP",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'Archivo',
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Text(
                    "Resend OTP available in ${_formatTime(_remainingSeconds)}",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                      color: Colors.grey,
                    ),
                  ),

                SizedBox(height: 40.h),
                const CustomAlert(alertKey: 'reset'),
                const CustomAlert(alertKey: 'signup'),
                const CustomAlert(alertKey: 'success'),
                const CustomAlert(alertKey: 'error'),
                
                // Next Button
                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: PrimaryButton(
                        text: "Proceed",
                        onPressed: () {
                          if(_emailVerified && _phoneVerified){
                              registerUser(
                                Globals.userSignup!.title,
                                Globals.userSignup!.firstName,
                                Globals.userSignup!.lastName,
                                Globals.userSignup!.email,
                                Globals.userSignup!.phone,
                                Globals.userSignup!.password,
                                Globals.userSignup!.password,
                              );
                          }
                          else{

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

  Future<void> registerUser(
    String title,
    String firstName,
    String lastName,
    String email,
    String phoneNo,
    String password,
    String confirmPassword,
  ) async {
    try {
      final value = await GeneralRepository().signup(
        title: title,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNo: phoneNo,
        password: password,
        confirmPassword: confirmPassword,
      );
      
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
    } catch (e) {
      Alertify.showAlert(
        duration: 2,
        alertKey: 'error',
        message: 'Signup failed: ${e.toString()}',
        type: AlertType.error,
      );
    }
  }
}
