class SearchResultResponse {
  final String message;
  final List<ParkingOption> data;
  final String? airport;

  SearchResultResponse({
    required this.message,
    required this.data,
    this.airport,
  });

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    String? airportName = json['airport']?.toString();
    List<ParkingOption> resultsList = list
        .map((i) => ParkingOption.fromJson(i, airportContext: airportName))
        .toList();

    return SearchResultResponse(
      message: json['message'] ?? '',
      data: resultsList,
      airport: airportName,
    );
  }
}

class FollowUpPage {
  final String overview;
  final String serviceDetails;
  final String customerExperience;
  final String location;

  FollowUpPage({
    required this.overview,
    required this.serviceDetails,
    required this.customerExperience,
    required this.location,
  });

  factory FollowUpPage.fromJson(Map<String, dynamic> json) {
    return FollowUpPage(
      overview: json['overview']?.toString() ?? '',
      serviceDetails: json['serviceDetails']?.toString() ?? '',
      customerExperience: json['customerExperience']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
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
  final String? image;
  final String? imagenew;
  final String? type;
  final double rating;
  final String ratingText;
  final int reviews;
  final String? frontPageSummary;
  final String? specialLabel;
  final bool isFullyBooked;
  final FollowUpPage? followUpPage;
  final String? productId;
  final String? companyId;
  final String? logoUrl;

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
    this.isFullyBooked = false,
    this.followUpPage,
    this.productId,
    this.companyId,
    this.logoUrl,
  });

  factory ParkingOption.fromJson(Map<String, dynamic> json,
      {String? airportContext}) {
    // 1. Determine Title based on airport
    String finalName = '';
    bool isSpecialAirport = airportContext == 'Stansted' ||
        airportContext == 'Luton' ||
        airportContext == 'Bristol';

    if (isSpecialAirport) {
      finalName =
          json['name']?.toString() ?? json['productName']?.toString() ?? '';
    } else {
      finalName =
          json['productName']?.toString() ?? json['name']?.toString() ?? '';
    }

    // 2. Map Features
    List<String> features = [];
    if (json['features'] != null && json['features'] is List) {
      features = (json['features'] as List).map((e) => e.toString()).toList();
    } else if (json['keyFeatures'] != null && json['keyFeatures'] is List) {
      features =
          (json['keyFeatures'] as List).map((e) => e.toString()).toList();
    }

    // 3. Handle Fully Booked
    bool fullyBooked = json['isFullyBooked'] as bool? ?? false;
    String priceStr = json['price']?.toString() ?? '';
    if (priceStr.toLowerCase().contains('booked')) {
      fullyBooked = true;
    }

    // 4. Follow Up Page
    FollowUpPage? followUp;
    if (json['followUpPage'] != null && json['followUpPage'] is Map) {
      followUp = FollowUpPage.fromJson(json['followUpPage']);
    }

    return ParkingOption(
      name: finalName,
      price: priceStr,
      description: json['description']?.toString() ?? 'No description Added',
      terminalInfo: json['terminalInfo']?.toString(),
      bulletPoints: features,
      hasParkMark: json['hasParkMark'] as bool? ?? false,
      image: json['logoUrl'] ?? json['logo'] ?? json['image'],
      imagenew: json['imagenew']?.toString(),
      type: (json['type'] ?? json['category'])?.toString(),
      rating:
          (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      ratingText: json['ratingText']?.toString() ?? '',
      reviews: (json['reviewCount'] is int) ? json['reviewCount'] as int : 0,
      specialLabel: json['specialLabel']?.toString(),
      frontPageSummary: json['frontPageSummary']?.toString(),
      isFullyBooked: fullyBooked,
      followUpPage: followUp,
      productId: json['productId']?.toString(),
      companyId: json['companyId']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}
