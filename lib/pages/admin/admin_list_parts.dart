import 'dart:async';

import 'package:flutter/material.dart';

/// Shared bits for the admin list screens: search box, filter chips, header.

const Color kAdminGreen = Color(0xFF4B725D);

/// Search box that reports the text 400 ms after the user stops typing.
class AdminSearchBox extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const AdminSearchBox({super.key, required this.hint, required this.onChanged});

  @override
  State<AdminSearchBox> createState() => _AdminSearchBoxState();
}

class _AdminSearchBoxState extends State<AdminSearchBox> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => widget.onChanged(text.trim()));
    setState(() {}); // show/hide the clear button
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F7F6),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

/// Horizontal row of single-choice chips. Value null = "All".
class AdminFilterChips extends StatelessWidget {
  final Map<String?, String> options; // value -> label
  final String? selected;
  final ValueChanged<String?> onSelected;
  const AdminFilterChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: options.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected == e.key,
                    selectedColor: kAdminGreen.withValues(alpha: 0.15),
                    onSelected: (_) => onSelected(e.key),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// "1,240 bookings" line above a list.
Widget adminCountHeader(int total, String noun) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('${_thousands(total)} $noun',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    );

String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

/// Small coloured status pill.
Widget adminStatusPill(String status) {
  final s = status.toLowerCase();
  final color = s == 'completed'
      ? Colors.green
      : (s == 'inprogress' || s == 'started')
          ? Colors.orange
          : s == 'pending'
              ? Colors.blueGrey
              : s == 'claimed'
                  ? Colors.indigo
                  : Colors.grey;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12)),
    child: Text(status.isEmpty ? '-' : status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

/// Card shell used by all admin list rows.
class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AdminCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

/// Screen title used when a list is a bottom-nav tab (no back button).
Widget adminTabTitle(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    );
