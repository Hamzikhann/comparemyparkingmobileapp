import 'dart:async'; // Import the async library for Timer
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/ThemeChanger.dart';
import 'package:provider/provider.dart';

class CustomAlert extends StatefulWidget {
  final String alertKey;

  const CustomAlert({super.key, required this.alertKey});

  @override
  _AlertWidgetState createState() => _AlertWidgetState();
}

class _AlertWidgetState extends State<CustomAlert> {
  bool _isVisible = false;
  double _height = 0.0; // Track height for animation
  Timer? _timer; // Timer variable to manage the auto-hide

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.watch<AlertNotifier>();
    // Check if the alert is visible
    if (notifier.isVisible(widget.alertKey)) {
      _showAlert(notifier);
    } else if (_isVisible) {
      _hideAlert(notifier); // Only hide if it is currently visible
    }
  }

  void _showAlert(AlertNotifier notifier) {
    // Cancel the existing timer if it's active
    _timer?.cancel();

    // Set the state to make the alert visible
    setState(() {
      _isVisible = true;
      _height = 50.0; // Set height to 50 when visible
    });

    // Start a new timer to auto-hide the alert after the specified duration
    final duration = notifier.getDuration(widget.alertKey);
    _timer = Timer(Duration(seconds: duration), () {
      _hideAlert(notifier);
    });
  }

  void _hideAlert(AlertNotifier notifier) {
    if (!_isVisible) return; // Avoid hiding if already hidden

    // Cancel the timer if it's active
    _timer?.cancel();

    // Update visibility state
    setState(() {
      _height = 0.0; // Set height to 0 when hiding
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      // Update visibility after the animation duration.
      if (mounted) {
        notifier.hideAlert(widget.alertKey);
        setState(() {
          _isVisible = false; // Update visibility state after hiding
        });
      }
    });
  }

  @override
  void dispose() {
    // Ensure the timer is canceled when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: _height, // Animate height
      child: _isVisible
          ? _buildAlertContent(
              context.read<AlertNotifier>().getMessage(widget.alertKey),
              context.read<AlertNotifier>().getType(widget.alertKey),
              context.read<AlertNotifier>(),
            )
          : const SizedBox.shrink(), // Return empty box if not visible
    );
  }

  Widget _buildAlertContent(
      String message, AlertType type, AlertNotifier notifier) {
    IconData iconData;
    Color background;
    Color borderColor;

    switch (type) {
      case AlertType.success:
        iconData = Icons.check_circle_outline;
        background = context.watch<ThemeChanger>().isDark
            ? Colors.green[700]!.withValues(alpha: 0.2)
            : Colors.green[100]!;
        borderColor = Colors.green[700]!;
        break;
      case AlertType.error:
        iconData = Icons.error_outline;
        background = context.watch<ThemeChanger>().isDark
            ? Colors.red[700]!.withValues(alpha: 0.2)
            : Colors.red[100]!;
        borderColor = Colors.red[700]!;
        break;
      case AlertType.warning:
        iconData = Icons.warning_amber_outlined;
        background = context.watch<ThemeChanger>().isDark
            ? Colors.amber[700]!.withValues(alpha: 0.2)
            : Colors.amber[100]!;
        borderColor = Colors.amber[700]!;
        break;
      case AlertType.info:
        iconData = Icons.info_outline;
        background = context.watch<ThemeChanger>().isDark
            ? Colors.blue[700]!.withValues(alpha: 0.2)
            : Colors.blue[100]!;
        borderColor = Colors.blue[700]!;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.only(left: 10),
      margin: const EdgeInsets.all(5),
      child: _height > 25
          ? Row(
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    EasyLoading.showToast(message);
                  },
                  child: Icon(
                    iconData,
                    color: borderColor,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                  ),
                  color: borderColor,
                  onPressed: () {
                    _hideAlert(notifier);
                  },
                ),
              ],
            )
          : Container(),
    );
  }
}
