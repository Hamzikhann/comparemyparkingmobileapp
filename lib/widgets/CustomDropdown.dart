import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String? hint;
  final List<T> items;
  final double? height;
  final Color? borderColor;
  final T? defaultValue;
  final bool? isSearchable;
  final Function(T?) onSelectItem;
  final T? selectedItem;
  final bool useLightBackground;

  const CustomDropdown({
    super.key,
    this.hint,
    required this.items,
    required this.onSelectItem,
    this.height,
    this.borderColor,
    this.defaultValue,
    this.isSearchable,
    this.selectedItem,
    this.useLightBackground = false,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  T? selectedValue;
  final TextEditingController textEditingController = TextEditingController();
  bool isClearedManually = false;

  @override
  void initState() {
    super.initState();
    // Initialize with selectedItem if provided, otherwise with defaultValue
    selectedValue = widget.selectedItem ?? widget.defaultValue;
  }

  @override
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update if selectedItem changed from outside
    if (widget.selectedItem != oldWidget.selectedItem) {
      selectedValue = widget.selectedItem;
      setState(() {});
    }

    // Handle defaultValue changes
    if (widget.defaultValue != oldWidget.defaultValue &&
        widget.selectedItem == null &&
        !isClearedManually) {
      selectedValue = widget.defaultValue;
      setState(() {});
    }

    // Reset if items changed
    if (!listEquals(widget.items, oldWidget.items)) {
      setState(() {
        // Only reset if the selected value is no longer in the items list
        if (selectedValue != null && !widget.items.contains(selectedValue)) {
          selectedValue = null;
          isClearedManually = true;
          widget.onSelectItem(null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height ?? (widget.useLightBackground ? 52.h : null),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(widget.useLightBackground ? 8.r : 10),
        color:
            widget.useLightBackground ? Color(0xFFF5F5F5) : Colors.transparent,
        border: widget.useLightBackground
            ? null
            : Border.all(
                color: selectedValue != null
                    ? Color(0xFF438498)
                    : (widget.borderColor ?? Color(0xFFB5B5C3)),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.useLightBackground ? 16.w : 8.0,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              width: MediaQuery.of(context).size.width -
                  (widget.useLightBackground ? 48 : 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 8,
            ),
            iconStyleData: IconStyleData(
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF414141),
              ),
              iconSize: widget.useLightBackground ? 24.sp : 18,
            ),
            isExpanded: true,
            value: selectedValue,
            hint: Text(
              'Select',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF9E9E9E),
                fontFamily: 'Archivo',
              ),
            ),
            items: widget.items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF414141),
                          fontFamily: 'Archivo',
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                if (selectedValue != value) {
                  selectedValue = value;
                  isClearedManually = false;
                  widget.onSelectItem(selectedValue);
                }
              });
            },
            buttonStyleData: ButtonStyleData(
              height: widget.useLightBackground ? 52.h : 40,
              padding: EdgeInsets.zero,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40,
            ),
            dropdownSearchData: widget.isSearchable == true
                ? DropdownSearchData(
                    searchController: textEditingController,
                    searchInnerWidgetHeight: 50,
                    searchInnerWidget: Container(
                      height: 50,
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        maxLines: 1,
                        controller: textEditingController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: "Search",
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Archivo',
                          ),
                          suffixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Archivo',
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      String itemValue = item.value.toString().toLowerCase();
                      String searchVal = searchValue.toLowerCase();
                      return itemValue.contains(searchVal);
                    },
                  )
                : null,
            onMenuStateChange: (isOpen) {
              if (!isOpen) {
                textEditingController.clear();
              }
            },
          ),
        ),
      ),
    );
  }
}
