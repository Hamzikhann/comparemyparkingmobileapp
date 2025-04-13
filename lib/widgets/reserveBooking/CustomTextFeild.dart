import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final String? defaultValue;  // Only add this new parameter

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.defaultValue,  // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set default value if provided and controller is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (defaultValue != null && controller.text.isEmpty) {
        controller.text = defaultValue!;
      }
    });

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator, // Keep validation as is
      style: TextStyle(
        fontSize: 14.sp,
        fontFamily: 'Archivo',
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 10.h,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.textGray,
          fontFamily: 'Archivo',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: colors.textFieldBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: colors.greenBorderspinner,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: colors.textFieldBorder,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}