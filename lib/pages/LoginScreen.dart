import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Add this

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Form(
              // 👈 Wrap with Form
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60.h),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 80.h,
                      width: 200.w,
                    ),
                  ),
                  SizedBox(height: 150.h),

                  // Email Input
                  CustomTextField(
                    hintText: "Email",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter email";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 40.h),

                  // Password Input
                  CustomTextField(
                    hintText: "Password",
                    controller: passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter password";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 40.h),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, MyRoutes.forgot);
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Archivo',
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),
                  const CustomAlert(alertKey: 'login'),

                  // Login Button
                  PrimaryButton(
                    text: "Login",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        signin(emailController.text.trim(),
                            passwordController.text.trim());
                      }
                    },
                  ),

                  SizedBox(height: 50.h),

                  // OR Sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("or ",
                          style: TextStyle(
                              fontSize: 14.sp, fontFamily: 'Archivo')),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                              context, MyRoutes.signUpRoute);
                        },
                        child: Text(
                          "Signup",
                          style: TextStyle(
                            fontSize: 14.sp,
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
        ),
      ),
    );
  }

  Future<void> signin(String userName, String password) async {
    GeneralRepository().signin(userName, password).then((value) {
      Alertify.showAlert(
        duration: 1,
        alertKey: 'login',
        message: 'Login successfully!',
        type: AlertType.success,
        onClose: () {
          Globals.user = value;
          SharedStorage.saveUser(value);
          emailController.clear();
          passwordController.clear();
          Navigator.pushReplacementNamed(context, MyRoutes.mainPage);
        },
      );
    });
  }
}
