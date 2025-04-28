class Driver {
  final String id;
  final String? title;
  final String firstName;
  final String lastName;
  final String? phoneNo;
  final String email;
  final String? imageURL;
  final List<BookingAssignment> bookingAssignments;

  Driver({
    required this.id,
    this.title,
    required this.firstName,
    required this.lastName,
    this.phoneNo,
    required this.email,
    this.imageURL,
    required this.bookingAssignments,
  });

  String get name => '$firstName $lastName';

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      title: json['title'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNo: json['phoneNo'],
      email: json['email'],
      imageURL: json['imageURL'],
      bookingAssignments: List<BookingAssignment>.from(
        json['bookingAssignments'].map((x) => BookingAssignment.fromJson(x)),
      ),
    );
  }
}

class BookingAssignment {
  final String id;
  final String status;
  final String bookingId;

  BookingAssignment({
    required this.id,
    required this.status,
    required this.bookingId,
  });

  factory BookingAssignment.fromJson(Map<String, dynamic> json) {
    return BookingAssignment(
      id: json['id'],
      status: json['status'],
      bookingId: json['bookingId'],
    );
  }
}