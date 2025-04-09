import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
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
          borderRadius: BorderRadius.circular(8.r), // 8.r for light curve
          borderSide: BorderSide(
            color: colors.textFieldBorder, // Default border color
            width: 1.0, // 1dp width
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: colors.greenBorderspinner, // Border color when focused
            width: 1.0, // 1dp width
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: colors.textFieldBorder, // Default border color
            width: 1.0, // 1dp width
          ),
        ),
      ),
    );
  }
}
