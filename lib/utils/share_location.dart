import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';

/// Customer shares their current GPS position as the Meet and Greet pickup
/// point, so the assigned driver can navigate to them.
Future<void> shareMyPickupLocation(
    BuildContext context, String bookingId) async {
  void snack(String m) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Share pickup location'),
      content: const Text(
          'Your current location will be shared with your driver so they can '
          'meet you to collect your car. Make sure you are at the pickup point.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Share')),
      ],
    ),
  );
  if (confirm != true) return;

  if (!await Geolocator.isLocationServiceEnabled()) {
    snack('Please turn on location services and try again.');
    return;
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    snack('Location permission is needed to share your pickup location.');
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    return;
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    final message = await GeneralRepository().postLocation(
        bookingId, pos.latitude.toString(), pos.longitude.toString());
    snack(message);
  } catch (e) {
    // postLocation already shows server errors as an alert
    if (e is! String) snack('Could not get your location. Please try again.');
  }
}
