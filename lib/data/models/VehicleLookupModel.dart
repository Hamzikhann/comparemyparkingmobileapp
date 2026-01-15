class VehicleLookupResponse {
  final bool success;
  final VehicleData? data;
  final String? message;

  VehicleLookupResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory VehicleLookupResponse.fromJson(Map<String, dynamic> json) {
    return VehicleLookupResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? VehicleData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class VehicleData {
  final VehicleDescription? vehicleDescription;

  VehicleData({this.vehicleDescription});

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      vehicleDescription: json['vehicleDescription'] != null
          ? VehicleDescription.fromJson(json['vehicleDescription'])
          : null,
    );
  }
}

class VehicleDescription {
  final String? manufacturer;
  final String? model;
  final String? year;
  final String? colour;

  VehicleDescription({
    this.manufacturer,
    this.model,
    this.year,
    this.colour,
  });

  factory VehicleDescription.fromJson(Map<String, dynamic> json) {
    return VehicleDescription(
      manufacturer: json['Manufacturer']?.toString(),
      model: json['Model']?.toString(),
      year: json['Year']?.toString(),
      colour: json['Colour']?.toString(),
    );
  }
}
