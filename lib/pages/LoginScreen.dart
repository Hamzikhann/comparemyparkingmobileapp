import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Do you really want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // Car image at the top - aligned to right with no padding
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/images/car.png',
                    height: 200.h,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                SizedBox(height: 30.h),
                // Rest of the content with padding
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Login heading
                        Text(
                          'Login to\nyour account',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontFamily: 'Archivo',
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        // Email field
                        CustomTextField(
                          labelText: 'Email',
                          hintText: "example@gamil.com",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          useLightBackground: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter email";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        // Password field
                        CustomTextField(
                          labelText: 'Password',
                          hintText: "••••••••••",
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          useLightBackground: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Color(0xFF414141),
                              size: 22.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter password";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 80.h),
                        // Sign up link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "I don't have account ",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: 'Archivo',
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, MyRoutes.signUpRoute);
                                },
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: colors.secondarynew,
                                    fontFamily: 'Archivo',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Alert notification
                        const CustomAlert(alertKey: 'login'),
                        // Login button
                        Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Color(0xFF4B725D),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  signin(emailController.text.trim(),
                                      passwordController.text.trim());
                                }
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Center(
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontFamily: 'Archivo',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
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
          if (Globals.user?.roleTitle == "Employee") {
            Navigator.pushReplacementNamed(context, MyRoutes.driverhome);
          } else if (Globals.user?.roleTitle == "Administrator") {
            Navigator.pushReplacementNamed(context, MyRoutes.adminHome);
          } else {
            Navigator.pushReplacementNamed(context, MyRoutes.mainPage);
          }
        },
      );
    });
  }
}
