import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';

class NonEditableTextField extends StatelessWidget {
  final String hintText;
  final String? value;  // Made optional by removing 'required'
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const NonEditableTextField({
    Key? key,
    required this.hintText,
    this.value,  // No longer required
    this.textStyle,
    this.hintStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12.h,
        horizontal: 10.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: colors.textFieldBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : hintText,
              style: value?.isNotEmpty == true
                  ? textStyle ?? TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Archivo',
                    )
                  : hintStyle ?? TextStyle(
                      color: colors.textGray,
                      fontFamily: 'Archivo',
                      fontSize: 14.sp,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}