class BookingAdminResponse {
  final List<Parking> reservedParkings;
  final List<Parking> completedParkings;
  final List<Parking> pendingParkings;
  final List<Parking> allBookings;

  BookingAdminResponse({
    required this.reservedParkings,
    required this.completedParkings,
    required this.pendingParkings,
    required this.allBookings,
  });

  factory BookingAdminResponse.fromJson(Map<String, dynamic> json) {
    return BookingAdminResponse(
      reservedParkings: (json['data']['reservedParkings'] as List)
          .map((e) => Parking.fromJson(e))
          .toList(),
      completedParkings: (json['data']['completedParkings'] as List)
          .map((e) => Parking.fromJson(e))
          .toList(),
      pendingParkings: (json['data']['pendingParkings'] as List)
          .map((e) => Parking.fromJson(e))
          .toList(),
      allBookings: (json['data']['allBookings'] as List)
          .map((e) => Parking.fromJson(e))
          .toList(),
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
  final double? longitude;
  final double? latitude;
  final String status;
  final String userId;
  final String? guestUserId;
  final String packageId;
  final List<Registration> registrations;
  final List<Vehicle> vehicles;
  final List<BookingAssignment> bookingAssignments;

  Parking({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.airport,
    this.promoCode,
    this.longitude,
    this.latitude,
    required this.status,
    required this.userId,
    this.guestUserId,
    required this.packageId,
    required this.registrations,
    required this.vehicles,
    required this.bookingAssignments,
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
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      status: json['status'] as String? ?? '',
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
      bookingAssignments: (json['bookingAssignments'] as List?)
              ?.map((data) => BookingAssignment.fromJson(data))
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
  final String bookingId;

  Vehicle({
    required this.id,
    required this.vehicleRegistration,
    required this.vehicleManufacturer,
    required this.vehicleModel,
    required this.vehicleColour,
    required this.numberofPassengers,
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
      bookingId: json['bookingId'] as String? ?? '',
    );
  }
}

class BookingAssignment {
  final String id;
  final String status;
  final String bookingId;
  final String employeeId;
  final Employee? employee;

  BookingAssignment({
    required this.id,
    required this.status,
    required this.bookingId,
    required this.employeeId,
    this.employee,
  });

  factory BookingAssignment.fromJson(Map<String, dynamic> json) {
    return BookingAssignment(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'])
          : null,
    );
  }
}

class Employee {
  final String id;
  final String title;
  final String firstName;
  final String lastName;
  final String phoneNo;
  final String email;
  final String? imageURL;
  final String? fcmToken;
  final String isActive;
  final String roleId;

  Employee({
    required this.id,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.phoneNo,
    required this.email,
    this.imageURL,
    this.fcmToken,
    required this.isActive,
    required this.roleId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNo: json['phoneNo'] as String? ?? '',
      email: json['email'] as String? ?? '',
      imageURL: json['imageURL'] as String?,
      fcmToken: json['fcmToken'] as String?,
      isActive: json['isActive'] as String? ?? '',
      roleId: json['roleId'] as String? ?? '',
    );
  }
}