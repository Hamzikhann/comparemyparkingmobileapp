import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

enum InputType { date, time }

class InputBox extends StatefulWidget {
  final String hint;
  final IconData icon;
  final InputType inputType;
  final void Function(String) onValueChanged;

  const InputBox({
    super.key,
    required this.hint,
    required this.icon,
    required this.inputType,
    required this.onValueChanged,
  });

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  String displayText = "";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText.isNotEmpty ? displayText : widget.hint,
                style: TextStyle(
                  color: displayText.isNotEmpty ? Colors.black : Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(widget.icon, size: 18.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (widget.inputType == InputType.date) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (range != null) {
        final formatted =
            "${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd').format(range.end)}";
        setState(() {
          displayText = formatted;
        });
        widget.onValueChanged(formatted);
      }
    } else if (widget.inputType == InputType.time) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final formatted = time.format(context);
        setState(() {
          displayText = formatted;
        });
        widget.onValueChanged(formatted);
      }
    }
  }
}
