class BookingDriverResponse {
  final List<Parking> assignedAssignments;
  final List<Parking> completedAssignmnets;

  BookingDriverResponse({
    required this.assignedAssignments,
    required this.completedAssignmnets,
  });

  factory BookingDriverResponse.fromJson(Map<String, dynamic> json) {
    return BookingDriverResponse(
      assignedAssignments: (json['assignedAssignmnets'] as List?)
              ?.map((data) => Parking.fromJson(data))
              .toList() ??
          [],
      completedAssignmnets: (json['completedAssignmnets'] as List?)
              ?.map((data) => Parking.fromJson(data))
              .toList() ??
          [],
    );
  }
}

class Parking {
  final String id;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String airport;
  final String? promoCode;
  final String status;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String userId;
  final String? guestUserId;
  final String packageId;
  final List<Registration> registrations;
  final List<Vehicle> vehicles;

  Parking({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.airport,
    this.promoCode,
    required this.status,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.userId,
    this.guestUserId,
    required this.packageId,
    required this.registrations,
    required this.vehicles,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      airport: json['airport'] as String? ?? '',
      promoCode: json['promoCode'] as String?,
      status: json['status'] as String? ?? '',
      isActive: json['isActive']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      userId: json['userId'] as String? ?? '',
      guestUserId: json['guestUserId'] as String?,
      packageId: json['packageId'] as String? ?? '',
      registrations: (json['registrations'] as List?)
              ?.map((data) => Registration.fromJson(data))
              .toList() ??
          [],
      vehicles: (json['vehicles'] as List?)
              ?.map((data) => Vehicle.fromJson(data))
              .toList() ??
          [],
    );
  }
}

class Registration {
  final String id;
  final String outboundTerminal;
  final String outboundFlightNo;
  final String inboundTerminal;
  final String inboundFlightNo;
  final String title;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNo;
  final String? status;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String bookingId;

  Registration({
    required this.id,
    required this.outboundTerminal,
    required this.outboundFlightNo,
    required this.inboundTerminal,
    required this.inboundFlightNo,
    required this.title,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNo,
    this.status,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.bookingId,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] as String? ?? '',
      outboundTerminal: json['outboundTerminal'] as String? ?? '',
      outboundFlightNo: json['outboundFlightNo'] as String? ?? '',
      inboundTerminal: json['inboundTerminal'] as String? ?? '',
      inboundFlightNo: json['inboundFlightNo'] as String? ?? '',
      title: json['title'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNo: json['phoneNo'] as String? ?? '',
      status: json['status'] as String?,
      isActive: json['isActive']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      bookingId: json['bookingId'] as String? ?? '',
    );
  }
}

class Vehicle {
  final String id;
  final String vehicleRegistration;
  final String vehicleManufacturer;
  final String vehicleModel;
  final String vehicleColour;
  final String numberofPassengers;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String bookingId;

  Vehicle({
    required this.id,
    required this.vehicleRegistration,
    required this.vehicleManufacturer,
    required this.vehicleModel,
    required this.vehicleColour,
    required this.numberofPassengers,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.bookingId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? '',
      vehicleRegistration: json['vehicleRegistration'] as String? ?? '',
      vehicleManufacturer: json['vehicleManufacturer'] as String? ?? '',
      vehicleModel: json['vehicleModel'] as String? ?? '',
      vehicleColour: json['vehicleColour'] as String? ?? '',
      numberofPassengers: json['numberofPassengers'] as String? ?? '',
      isActive: json['isActive']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      bookingId: json['bookingId'] as String? ?? '',
    );
  }
}
