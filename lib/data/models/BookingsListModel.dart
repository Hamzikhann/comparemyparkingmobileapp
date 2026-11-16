class BookingResponse {
  final List<Parking> reservedParkings;
  final List<Parking> pendingParkings;
  final List<Parking> completedParkings;

  BookingResponse({
    required this.reservedParkings,
    required this.pendingParkings,
    required this.completedParkings,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      reservedParkings: (json['reservedParkings'] as List?)
              ?.map((data) => Parking.fromJson(data))
              .toList() ??
          [],
      pendingParkings: (json['pendingParkings'] as List?)
              ?.map((data) => Parking.fromJson(data))
              .toList() ??
          [],
      completedParkings: (json['completedParkings'] as List?)
              ?.map((data) => Parking.fromJson(data))
              .toList() ??
          [],
    );
  }
}

class Parking {
  final String id;
  final String? referenceNo;
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

  /// From the included package (e.g. "Meet and Greet").
  final String packageType;

  /// Meet and Greet: the driver collects the car from the customer.
  bool get isMeetAndGreet => packageType
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'\s+'), ' ')
      .contains('meet and greet');
  final List<Registration> registrations;
  final List<Vehicle> vehicles;
  final List<BookingAssignment> bookingAssignments;
  final List<BookingCheckPoint> bookingCheckPoints;
  final String? location;
  final String? contactNumber;
  final String? arrivalProcedure;
  final String? departureProcedure;
  final String? busTrackingUrl;

  Parking({
    required this.id,
    this.referenceNo,
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
    this.packageType = '',
    required this.registrations,
    required this.vehicles,
    required this.bookingAssignments,
    required this.bookingCheckPoints,
    this.location,
    this.contactNumber,
    this.arrivalProcedure,
    this.departureProcedure,
    this.busTrackingUrl,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] ?? '',
      referenceNo: json['referenceNo'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      airport: json['airport'] ?? '',
      promoCode: json['promoCode'],
      status: json['status'] ?? '',
      isActive: json['isActive']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      userId: json['userId'] ?? '',
      guestUserId: json['guestUserId'],
      packageId: json['packageId'] ?? '',
      packageType: (json['package'] is Map)
          ? (json['package']['packageType'] ?? '').toString()
          : '',
      location: json['location'] is Map
          ? json['location']['address']
          : json['location'],
      contactNumber: json['contact'] is Map
          ? json['contact']['number']
          : (json['contact'] ?? json['contactNumber']),
      arrivalProcedure: json['arrivalProcedure'],
      departureProcedure: json['departureProcedure'],
      busTrackingUrl: json['busTrackingLink'] ??
          json['busTrackingUrl'] ??
          json['bus_tracking_url'] ??
          json['bus_tracking'] ??
          json['trackingLink'] ??
          json['tracking_link'] ??
          json['busTracking'],
      registrations: (json['registrations'] as List?)
              ?.map((e) => Registration.fromJson(e))
              .toList() ??
          [],
      vehicles: (json['vehicles'] as List?)
              ?.map((e) => Vehicle.fromJson(e))
              .toList() ??
          [],
      bookingAssignments: (json['bookingAssignments'] as List?)
              ?.map((e) => BookingAssignment.fromJson(e))
              .toList() ??
          [],
      bookingCheckPoints: (json['bookingCheckPoints'] as List?)
              ?.map((e) => BookingCheckPoint.fromJson(e))
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
      id: json['id'] ?? '',
      outboundTerminal: json['outboundTerminal'] ?? '',
      outboundFlightNo: json['outboundFlightNo'] ?? '',
      inboundTerminal: json['inboundTerminal'] ?? '',
      inboundFlightNo: json['inboundFlightNo'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      status: json['status'],
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      bookingId: json['bookingId'] ?? '',
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
      id: json['id'] ?? '',
      vehicleRegistration: json['vehicleRegistration'] ?? '',
      vehicleManufacturer: json['vehicleManufacturer'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColour: json['vehicleColour'] ?? '',
      numberofPassengers: json['numberofPassengers'] ?? '',
      bookingId: json['bookingId'] ?? '',
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
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      bookingId: json['bookingId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employee:
          json['employee'] != null ? Employee.fromJson(json['employee']) : null,
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
  final String? isActive;
  final String? roleId;

  Employee({
    required this.id,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.phoneNo,
    required this.email,
    this.imageURL,
    this.fcmToken,
    this.isActive,
    this.roleId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      email: json['email'] ?? '',
      imageURL: json['imageURL'],
      fcmToken: json['fcmToken'],
      isActive: json['isActive'],
      roleId: json['roleId'],
    );
  }
}

class BookingCheckPoint {
  final String id;
  final String type;
  final String location;
  final String section;
  final String? remarks;
  final String bookingId;
  final String? vehicleId;
  final String employeeId;
  final List<BookingCheckPointImage> bookingCheckPointsImages;

  BookingCheckPoint({
    required this.id,
    required this.type,
    required this.location,
    required this.section,
    this.remarks,
    required this.bookingId,
    this.vehicleId,
    required this.employeeId,
    required this.bookingCheckPointsImages,
  });

  factory BookingCheckPoint.fromJson(Map<String, dynamic> json) {
    return BookingCheckPoint(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      section: json['section'] ?? '',
      remarks: json['remarks'],
      bookingId: json['bookingId'] ?? '',
      vehicleId: json['vehicleId'],
      employeeId: json['employeeId'] ?? '',
      bookingCheckPointsImages: (json['bookingCheckPointsImages'] as List?)
              ?.map((e) => BookingCheckPointImage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BookingCheckPointImage {
  final String id;
  final String imageUrl;
  final String bookingCheckPointId;

  BookingCheckPointImage({
    required this.id,
    required this.imageUrl,
    required this.bookingCheckPointId,
  });

  factory BookingCheckPointImage.fromJson(Map<String, dynamic> json) {
    return BookingCheckPointImage(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      bookingCheckPointId: json['bookingCheckPointId'] ?? '',
    );
  }
}
