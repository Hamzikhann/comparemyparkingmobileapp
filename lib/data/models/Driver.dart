class Driver {
  final String id;
  final String? name;
  final String? contact;
  final String? email;
  final String? licenseNumber;
  final String? expiryDate;

  Driver({
    required this.id,
    this.name,
    this.contact,
    this.email,
    this.licenseNumber,
    this.expiryDate,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      contact: json['contact'],
      email: json['email'],
      licenseNumber: json['licenseNumber'],
      expiryDate: json['expiryDate'],
    );
  }
}
