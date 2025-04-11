// Create a new file: lib/data/models/search_result_model.dart
class SearchResultResponse {
  final String message;
  final SearchResultData data;

  SearchResultResponse({
    required this.message,
    required this.data,
  });

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) {
    return SearchResultResponse(
      message: json['message'],
      data: SearchResultData.fromJson(json['data']),
    );
  }
}

class SearchResultData {
  final String searchUrl;
  final List<ParkingOption> results;

  SearchResultData({
    required this.searchUrl,
    required this.results,
  });

  factory SearchResultData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;
    List<ParkingOption> resultsList = list.map((i) => ParkingOption.fromJson(i)).toList();
    
    return SearchResultData(
      searchUrl: json['searchUrl'],
      results: resultsList,
    );
  }
}

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
      name: json['name'],
      price: json['price'],
      description: json['description'],
      terminalInfo: json['terminalInfo'],
      bulletPoints: List<String>.from(json['bulletPoints']),
      hasParkMark: json['hasParkMark'],
    );
  }
}