import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class Forgotpassword extends StatefulWidget {
  const Forgotpassword({super.key});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordPageState();
}

class _ForgotpasswordPageState extends State<Forgotpassword> {
  final TextEditingController emailController = TextEditingController();
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
                        Navigator.pop(context);
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
                  hintText: "Email",
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
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
                const CustomAlert(alertKey: 'reset'),
                // Forgot Password Button
                PrimaryButton(
                  text:
                      "Reset Password", // Changed from "Forgot Password" to be more action-oriented
                  onPressed: () {
                    // Handle password reset
                    forgotPassword(emailController.text.toString());
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

  Future<void> forgotPassword(String userName) async {
    GeneralRepository().forgotPassword(userName).then((value) {
      Alertify.showAlert(
        duration: 1,
        alertKey: 'reset',
        message: 'Navigate to OTP Screen',
        type: AlertType.success,
        onClose: () {
          Globals.otp = value.otp;
          Globals.emailReset = emailController.text.toString();
          Globals.passwordReset = passwordController.text.toString();
          Globals.confirmPassword = passwordController.text.toString();
          Navigator.pushReplacementNamed(context, MyRoutes.otp);
        },
      );
    });
  }
}
