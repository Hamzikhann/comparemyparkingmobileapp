import 'dart:io';

class CheckpointRequestModel {
  final String bookingId;
  final String location;
  final String section;
  final String type; // "pickup" or "dropoff"
  final List<File>? pictures;

  CheckpointRequestModel({
    required this.bookingId,
    required this.location,
    required this.section,
    required this.type,
    this.pictures,
  });
}
