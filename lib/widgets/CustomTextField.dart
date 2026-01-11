import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final String? labelText;
  final bool useLightBackground;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.labelText,
    this.useLightBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: 'Archivo',
                color: Color(0xFF414141),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Archivo',
            color: Color(0xFF414141),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: useLightBackground ? 16.h : 12.h,
              horizontal: useLightBackground ? 16.w : 0,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Color(0xFF9E9E9E),
              fontFamily: 'Archivo',
              fontSize: 14.sp,
            ),
            filled: useLightBackground,
            fillColor: useLightBackground ? Color(0xFFF5F5F5) : null,
            suffixIcon: suffixIcon,
            border: useLightBackground
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  )
                : UnderlineInputBorder(),
            enabledBorder: useLightBackground
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  )
                : UnderlineInputBorder(),
            focusedBorder: useLightBackground
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  )
                : UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF201A56)),
                  ),
            errorBorder: useLightBackground
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  )
                : UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
            focusedErrorBorder: useLightBackground
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.red),
                  )
                : UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
          ),
        ),
      ],
    );
  }
}
