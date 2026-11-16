import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/driver/SessionCard.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared helpers for the employee (driver) screens.

/// Opens the booking detail screen for [parking].
void openDriverBooking(BuildContext context, Parking parking) {
  Globals.bookingDriverResponse = parking;
  Navigator.pushNamed(context, MyRoutes.bookingDetail);
}

/// Builds the job card used on the driver Home and Jobs tabs.
Widget buildDriverSessionCard(
    BuildContext context, Parking parking, String type) {
  final flightNo = parking.registrations.isNotEmpty
      ? parking.registrations.first.inboundFlightNo
      : '';
  final carMaker = parking.vehicles.isNotEmpty
      ? parking.vehicles.first.vehicleManufacturer
      : '';
  return SessionCard(
    title: "${parking.airport} Airport",
    status: parking.jobStatus.isNotEmpty ? parking.jobStatus : parking.status,
    subTitle: flightNo.isNotEmpty ? "Flight $flightNo" : "No flight number",
    date: parking.startDate,
    time: parking.startTime,
    price: carMaker.isNotEmpty ? carMaker : "-",
    type: type,
    timeRemaining: parking.startTime,
    onViewRidePressed: () => openDriverBooking(context, parking),
    // Customer pickup location only exists for Meet and Greet bookings
    onViewLocationPressed: !parking.isMeetAndGreet
        ? null
        : () {
            if (parking.registrations.isEmpty) {
              _snack(context, "No location found.");
              return;
            }
            openBookingLocation(
                context, parking.registrations.first.bookingId);
          },
  );
}

/// Looks up the parked car's saved location and opens it in a maps app.
Future<void> openBookingLocation(BuildContext context, String bookingID) async {
  try {
    final value = await GeneralRepository().getLocationCoordinates(bookingID);
    final longitude = value['longitude'];
    final latitude = value['latitude'];

    if (longitude == null ||
        longitude.isEmpty ||
        latitude == null ||
        latitude.isEmpty) {
      if (context.mounted) {
        _snack(context, "The customer hasn't shared their pickup location yet.");
      }
      return;
    }

    final googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    final appleMapsUrl =
        Uri.parse("http://maps.apple.com/?q=$latitude,$longitude");

    if (Platform.isAndroid) {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
        return;
      }
    } else if (Platform.isIOS) {
      final iosGoogleMapsUrl =
          Uri.parse("comgooglemaps://?q=$latitude,$longitude");
      if (await canLaunchUrl(iosGoogleMapsUrl)) {
        await launchUrl(iosGoogleMapsUrl);
        return;
      }
      if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
        return;
      }
    }
    if (context.mounted) _snack(context, "Could not open maps.");
  } catch (e) {
    debugPrint("Location error: $e");
    if (context.mounted) _snack(context, "Could not load location.");
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
