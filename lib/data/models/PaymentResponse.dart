class PaymentResponse {
  final String message;
  final List<Payment> payments;

  PaymentResponse({
    required this.message,
    required this.payments,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      message: json['message'] as String? ?? '',
      payments: (json['data'] as List?)
              ?.map((data) => Payment.fromJson(data))
              .toList() ??
          [],
    );
  }
}

class Payment {
  final String id;
  final String registrationMethod;
  final String paymentMethod;
  final String totalPayment;
  final String referenceNo;
  final String isActive;
  final String createdAt;
  final String updatedAt;
  final String bookingId;
  final Booking booking;

  Payment({
    required this.id,
    required this.registrationMethod,
    required this.paymentMethod,
    required this.totalPayment,
    required this.referenceNo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.bookingId,
    required this.booking,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      registrationMethod: json['registrationMethod'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      totalPayment: json['totalPayment'] as String? ?? '',
      referenceNo: json['referenceNo'] as String? ?? '',
      isActive: json['isActive'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      booking: Booking.fromJson(json['booking'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Booking {
  final String id;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String airport;
  final String? promoCode;
  final String status;
  final String isActive;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final String? guestUserId;
  final String packageId;

  Booking({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.airport,
    this.promoCode,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.guestUserId,
    required this.packageId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      airport: json['airport'] as String? ?? '',
      promoCode: json['promoCode'] as String?,
      status: json['status'] as String? ?? '',
      isActive: json['isActive'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      guestUserId: json['guestUserId'] as String?,
      packageId: json['packageId'] as String? ?? '',
    );
  }
}