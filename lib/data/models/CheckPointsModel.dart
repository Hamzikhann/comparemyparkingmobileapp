class CheckpointResponseModel {
  final int id;
  final String location;
  final String type;
  final String section;
  final String bookingId;
  final String employeeId;
  final String updatedAt;
  final String createdAt;

  CheckpointResponseModel({
    required this.id,
    required this.location,
    required this.type,
    required this.section,
    required this.bookingId,
    required this.employeeId,
    required this.updatedAt,
    required this.createdAt,
  });

  factory CheckpointResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckpointResponseModel(
      id: json['id'],
      location: json['location'],
      type: json['type'],
      section: json['section'],
      bookingId: json['bookingId'],
      employeeId: json['employeeId'],
      updatedAt: json['updatedAt'],
      createdAt: json['createdAt'],
    );
  }
}
