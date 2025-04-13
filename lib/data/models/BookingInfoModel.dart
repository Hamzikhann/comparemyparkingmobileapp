// booking_info_model.dart
class BookingInfoModel {
  final String outBoundTerminal;
  final String inBoundTerminal;
  final String departureFlight;
  final String returnFlight;
  final String title;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String vehicleRegNo;
  final String carMaker;
  final String carModel;
  final String carColor;
  final String noOfPassengers;

  BookingInfoModel({
    required this.outBoundTerminal,
    required this.inBoundTerminal,
    required this.departureFlight,
    required this.returnFlight,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.vehicleRegNo,
    required this.carMaker,
    required this.carModel,
    required this.carColor,
    required this.noOfPassengers,
  });

  Map<String, dynamic> toJson() => {
        'outBoundTerminal': outBoundTerminal,
        'inBoundTerminal': inBoundTerminal,
        'departureFlight': departureFlight,
        'returnFlight': returnFlight,
        'title': title,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'vehicleRegNo': vehicleRegNo,
        'carMaker': carMaker,
        'carModel': carModel,
        'carColor': carColor,
        'noOfPassengers': noOfPassengers,
      };

  factory BookingInfoModel.fromJson(Map<String, dynamic> json) {
    return BookingInfoModel(
      outBoundTerminal: json['outBoundTerminal'],
      inBoundTerminal: json['inBoundTerminal'],
      departureFlight: json['departureFlight'],
      returnFlight: json['returnFlight'],
      title: json['title'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      vehicleRegNo: json['vehicleRegNo'],
      carMaker: json['carMaker'],
      carModel: json['carModel'],
      carColor: json['carColor'],
      noOfPassengers: json['noOfPassengers'],
    );
  }
}