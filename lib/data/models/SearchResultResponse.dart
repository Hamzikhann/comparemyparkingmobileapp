// Create a new file: lib/data/models/search_result_model.dart
class SearchResultResponse {
  final String message;
  final List<ParkingOption> data; // Changed from SearchResultData to List<ParkingOption>

  SearchResultResponse({
    required this.message,
    required this.data,
  });

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<ParkingOption> resultsList = list.map((i) => ParkingOption.fromJson(i)).toList();
    
    return SearchResultResponse(
      message: json['message'],
      data: resultsList,
    );
  }
}

// Remove the SearchResultData class as it's no longer needed

class ParkingOption {
  final String name;
  final String price;
  final String description;
  final String? terminalInfo;
  final List<String> bulletPoints;
  final bool hasParkMark;

  ParkingOption({
    required this.name,
    required this.price,
    required this.description,
    this.terminalInfo,
    required this.bulletPoints,
    required this.hasParkMark,
  });

  factory ParkingOption.fromJson(Map<String, dynamic> json) {
    return ParkingOption(
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      description: json['description'],
      terminalInfo: json['terminalInfo'],
      bulletPoints: List<String>.from(json['bulletPoints']),
      hasParkMark: json['hasParkMark'],
    );
  }
}