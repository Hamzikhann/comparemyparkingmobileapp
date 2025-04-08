import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import '../routes/MyRoutes.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class Signupscreen extends StatelessWidget {
  late final String? decision;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
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

                // Logo from SVG asset
                Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg', // Make sure this path matches your actual SVG file location
                    height: 80.h,
                    width: 200.w,
                  ),
                ),

                SizedBox(height: 20.h),
                //Mr Mrs
                CustomDropdown(
                  hint: "Title",
                  items: const ["Mr", "Mrs", "Do not want to Specify"],
                  isSearchable: false,
                  onSelectItem: (item) {
                    decision = item;
                  },
                ),

                SizedBox(height: 10.h),
                //FirstName input
                CustomTextField(
                  hintText: "First Name",
                  controller: firstNameController,
                  keyboardType: TextInputType.name,
                ),

                SizedBox(height: 10.h),
                //LastName input
                CustomTextField(
                  hintText: "Last Name",
                  controller: lastNameController,
                  keyboardType: TextInputType.name,
                ),

                SizedBox(height: 10.h),
                //Email input
                CustomTextField(
                  hintText: "Email",
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 10.h),
                // Phone Input
                CustomTextField(
                  hintText: "Phone number",
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 10.h),

                // Password Input
                CustomTextField(
                  hintText: "Password",
                  controller: passwordController,
                  obscureText: true,
                ),

                SizedBox(height: 10.h),

                // Password Input
                CustomTextField(
                  hintText: " Confirm Password",
                  controller: confirmPasswordController,
                  obscureText: true,
                ),

                SizedBox(height: 20.h),

                // Signup Button
                PrimaryButton(
                  text: "Signup",
                  onPressed: () {
                    // Handle Signup
                    Navigator.pushReplacementNamed(context, MyRoutes.otp);
                  },
                ),

                SizedBox(height: 50.h),

                // OR Sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?  ",
                      style: TextStyle(fontSize: 14.sp, fontFamily: 'Archivo'),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to signup
                        Navigator.pushReplacementNamed(
                            context, MyRoutes.loginRoute);
                      },
                      child: Text(
                        "Login",
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
    );
  }
}
