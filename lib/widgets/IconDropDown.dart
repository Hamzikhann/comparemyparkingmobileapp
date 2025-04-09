import 'package:flutter/material.dart';
import 'package:parkingapp/utils/colors.dart';

class IconDropdown extends StatelessWidget {
  final String hint;
  final IconData icon;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;

  const IconDropdown({
    super.key,
    required this.hint,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textFieldBorder),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          icon: Icon(Icons.keyboard_arrow_down),
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
