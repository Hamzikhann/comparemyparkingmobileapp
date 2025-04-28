import 'Booking.dart';

class Payment {
  final String id;
  final String paymentMethod;
  final String totalPayment;
  final String referenceNo;
  final Booking booking;

  Payment({
    required this.id,
    required this.paymentMethod,
    required this.totalPayment,
    required this.referenceNo,
    required this.booking,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentMethod: json['paymentMethod'],
      totalPayment: json['totalPayment'],
      referenceNo: json['referenceNo'],
      booking: Booking.fromJson(json['booking']),
    );
  }
}