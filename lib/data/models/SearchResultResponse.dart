// Create a new file: lib/data/models/search_result_model.dart
class SearchResultResponse {
  final String message;
  final List<ParkingOption>
      data; // Changed from SearchResultData to List<ParkingOption>

  SearchResultResponse({
    required this.message,
    required this.data,
  });

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<ParkingOption> resultsList =
        list.map((i) => ParkingOption.fromJson(i)).toList();

    return SearchResultResponse(
      message: json['message'] ?? '',
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
  final String? image;
  final String? imagenew;
  final String? type;
  final double rating;
  final String ratingText;
  final int reviews;
  final String? frontPageSummary;
  final String? specialLabel;

  ParkingOption({
    required this.name,
    required this.price,
    required this.description,
    this.terminalInfo,
    required this.bulletPoints,
    required this.hasParkMark,
    this.image,
    this.imagenew,
    this.type,
    this.rating = 0.0,
    this.ratingText = '',
    this.reviews = 0,
    this.specialLabel,
    this.frontPageSummary,
  });

  factory ParkingOption.fromJson(Map<String, dynamic> json) {
    return ParkingOption(
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      terminalInfo: json['terminalInfo']?.toString(),
      bulletPoints: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasParkMark: json['hasParkMark'] as bool? ?? false,
      image: json['image']?.toString(),
      imagenew: json['imagenew']?.toString(),
      type: json['type']?.toString(),
      rating:
          (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      ratingText: json['ratingText']?.toString() ?? '',
      reviews: (json['reviewCount'] is int) ? json['reviewCount'] as int : 0,
      specialLabel: json['specialLabel']?.toString(),
      frontPageSummary: json['frontPageSummary']?.toString(),
    );
  }
}
