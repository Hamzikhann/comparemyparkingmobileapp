class Booking {
  final String airport;
  final String startDate;
  final String endDate;
  final String status;

  Booking({
    required this.airport,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      airport: json['airport'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
