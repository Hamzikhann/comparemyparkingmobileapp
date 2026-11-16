import 'package:parkingapp/data/booking_flow.dart';

/// Response of POST /api/search/v5.
class SearchResultResponse {
  final String message;
  final List<ParkingOption> data;
  final String? airport;

  /// Server note when there is nothing to show (e.g. "This airport is not available").
  final String? note;

  /// False for display-only airports: their packages show as "Fully Booked".
  final bool bookable;

  /// Promo code result, when one was entered and accepted.
  final PromoCodeDetails? promoCodeDetails;

  SearchResultResponse({
    required this.message,
    required this.data,
    this.airport,
    this.note,
    this.bookable = true,
    this.promoCodeDetails,
  });

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return SearchResultResponse(
      message: json['message']?.toString() ?? '',
      data: list
          .whereType<Map>()
          .map((i) => ParkingOption.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      airport: json['airport']?.toString(),
      note: json['note']?.toString(),
      bookable: json['bookable'] is bool ? json['bookable'] as bool : true,
      promoCodeDetails: json['promoCodeDetails'] is Map
          ? PromoCodeDetails.fromJson(
              Map<String, dynamic>.from(json['promoCodeDetails']))
          : null,
    );
  }
}

class PromoCodeDetails {
  final String code;
  final String discountType;
  final double? discountPercentage;
  final double? discountAmount;

  PromoCodeDetails({
    required this.code,
    required this.discountType,
    this.discountPercentage,
    this.discountAmount,
  });

  factory PromoCodeDetails.fromJson(Map<String, dynamic> json) {
    double? num_(dynamic v) => v == null ? null : parsePrice(v);
    return PromoCodeDetails(
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      discountPercentage: num_(json['discountPercentage']),
      discountAmount: num_(json['discountAmount']),
    );
  }

  /// "SUMMER10 applied (10% off)" / "SUMMER10 applied (£5.00 off)"
  String get label {
    if (discountType == 'percentage' && discountPercentage != null) {
      return '$code applied (${_trim(discountPercentage!)}% off)';
    }
    if (discountAmount != null) {
      return '$code applied (${formatPrice(discountAmount!)} off)';
    }
    return '$code applied';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
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

/// One package from the search. Field rules follow the website's src/utils/packages.js.
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

  /// Id of this package in the server's search results. Payment is charged from it.
  final String? packageId;

  /// Our brand and tier (live airports), sent with the booking for brand-specific emails.
  final String? originalName;
  final String? tier;

  /// Price before our discount (live) or the provider's price (display airports).
  final double originalPrice;
  final double priceDiscount;
  final bool bookable;
  final int viewingCount;

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
    this.packageId,
    this.originalName,
    this.tier,
    this.originalPrice = 0,
    this.priceDiscount = 0,
    this.bookable = true,
    this.viewingCount = 0,
  });

  /// Number to charge / show: our price when bookable, otherwise the provider's.
  double get priceValue => bookable ? parsePrice(price) : originalPrice;

  /// "£38.69", or "Fully Booked".
  String get displayPrice {
    if (isFullyBooked) return 'Fully Booked';
    final v = priceValue;
    return v > 0 ? formatPrice(v) : price;
  }

  /// Short text for cards: the tier summary, else the description.
  String get summary =>
      (frontPageSummary?.trim().isNotEmpty ?? false)
          ? frontPageSummary!.trim()
          : description;

  /// Best image: our tier image, else the provider logo (empty when there is none).
  String get imageUrl => [imagenew, image, logoUrl]
      .firstWhere((u) => u != null && u.trim().isNotEmpty, orElse: () => '')!;

  factory ParkingOption.fromJson(Map<String, dynamic> json) {
    final bookable = json['bookable'] is bool ? json['bookable'] as bool : true;
    final priceStr = json['price']?.toString() ?? '';

    final fullyBooked = !bookable ||
        json['isFullyBooked'] == true ||
        RegExp(r'fully booked|sorry', caseSensitive: false).hasMatch(priceStr);

    FollowUpPage? followUp;
    if (json['followUpPage'] is Map) {
      followUp =
          FollowUpPage.fromJson(Map<String, dynamic>.from(json['followUpPage']));
    }

    final rating = json['rating'] is num
        ? (json['rating'] as num).toDouble()
        : double.tryParse(json['rating']?.toString() ?? '') ?? 0.0;

    return ParkingOption(
      name: _firstText([json['name'], json['productName']]) ?? 'Parking Package',
      price: priceStr,
      description: json['description']?.toString() ?? '',
      terminalInfo: json['terminalInfo']?.toString(),
      bulletPoints: _features(json),
      hasParkMark: json['hasParkMark'] as bool? ?? false,
      image: _firstText([json['logoUrl'], json['logo'], json['image']]),
      imagenew: _firstText([json['imagenew']]),
      type: (json['type'] ?? json['category'])?.toString(),
      rating: rating,
      ratingText: json['ratingText']?.toString() ?? '',
      reviews: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      specialLabel: json['specialLabel']?.toString(),
      frontPageSummary: json['frontPageSummary']?.toString(),
      isFullyBooked: fullyBooked,
      followUpPage: followUp,
      productId: json['productId']?.toString(),
      companyId: json['companyId']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      packageId: json['packageId']?.toString(),
      originalName: _firstText([json['originalName']]),
      tier: _firstText([json['tier']]),
      originalPrice: parsePrice(json['originalPrice']),
      priceDiscount: parsePrice(json['priceDiscount']),
      bookable: bookable,
      viewingCount: int.tryParse(json['viewingCount']?.toString() ?? '') ?? 0,
    );
  }

  static String? _firstText(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  /// keyFeatures first, then features; drops empty entries (website getPackageFeatures).
  static List<String> _features(Map<String, dynamic> json) {
    for (final list in [json['keyFeatures'], json['features']]) {
      if (list is List) {
        final valid = list
            .whereType<String>()
            .where((f) => f.trim().isNotEmpty && f != '[Circular]')
            .toList();
        if (valid.isNotEmpty) return valid;
      }
    }
    return [];
  }
}
