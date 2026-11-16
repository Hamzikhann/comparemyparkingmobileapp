/// Response data of GET /api/search/v5/package/:packageId
/// (backend utils/search/packages.js buildPackageDetail). Live airports carry the
/// admin-edited content and the airport service info; display airports carry reviews.
class PackageDetail {
  final String packageId;
  final String mode;
  final String airport;
  final String? type;
  final List<String> features;
  final PackageSections sections;
  final AirportInfo? airportInfo;
  final List<PackageReview> reviews;

  PackageDetail({
    required this.packageId,
    required this.mode,
    required this.airport,
    this.type,
    required this.features,
    required this.sections,
    this.airportInfo,
    required this.reviews,
  });

  bool get isLive => mode == 'live';

  factory PackageDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;
    return PackageDetail(
      packageId: data['packageId']?.toString() ?? '',
      mode: data['mode']?.toString() ?? '',
      airport: data['airport']?.toString() ?? '',
      type: data['type']?.toString(),
      features: (data['features'] is List ? data['features'] as List : const [])
          .whereType<String>()
          .where((f) => f.trim().isNotEmpty)
          .toList(),
      sections: PackageSections.fromJson(
          data['sections'] is Map ? Map<String, dynamic>.from(data['sections']) : {}),
      airportInfo: data['airportInfo'] is Map
          ? AirportInfo.fromJson(Map<String, dynamic>.from(data['airportInfo']))
          : null,
      reviews: (data['reviews'] is List ? data['reviews'] as List : const [])
          .whereType<Map>()
          .map((r) => PackageReview.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}

class PackageSections {
  final String overview;
  final String serviceDetails;
  final String customerExperience;
  final String location;
  final String onArrival;
  final String onReturn;

  PackageSections({
    this.overview = '',
    this.serviceDetails = '',
    this.customerExperience = '',
    this.location = '',
    this.onArrival = '',
    this.onReturn = '',
  });

  factory PackageSections.fromJson(Map<String, dynamic> json) {
    String s(String k) => json[k]?.toString().trim() ?? '';
    return PackageSections(
      overview: s('overview'),
      serviceDetails: s('serviceDetails'),
      customerExperience: s('customerExperience'),
      location: s('location'),
      onArrival: s('onArrival'),
      onReturn: s('onReturn'),
    );
  }
}

class AirportInfo {
  final String address;
  final String postalCode;
  final String contactNumber;
  final String contactEmail;
  final String extraInstructions;

  AirportInfo({
    this.address = '',
    this.postalCode = '',
    this.contactNumber = '',
    this.contactEmail = '',
    this.extraInstructions = '',
  });

  /// "address, postcode" without repeating a postcode already in the address.
  String get fullAddress {
    if (postalCode.isEmpty || address.contains(postalCode)) return address;
    return address.isEmpty ? postalCode : '$address, $postalCode';
  }

  factory AirportInfo.fromJson(Map<String, dynamic> json) {
    String s(String k) => json[k]?.toString().trim() ?? '';
    return AirportInfo(
      address: s('address'),
      postalCode: s('postalCode'),
      contactNumber: s('contactNumber'),
      contactEmail: s('contactEmail'),
      extraInstructions: s('extraInstructions'),
    );
  }
}

class PackageReview {
  final String author;
  final String text;
  final double rating;
  final String date;

  PackageReview(
      {this.author = '', this.text = '', this.rating = 0, this.date = ''});

  factory PackageReview.fromJson(Map<String, dynamic> json) {
    String first(List<String> keys) {
      for (final k in keys) {
        final v = json[k]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    return PackageReview(
      author: first(['user', 'author', 'name']),
      text: first(['comment', 'text', 'review']),
      rating: _rating(json['rating']),
      date: first(['date']),
    );
  }

  /// 4.5, "4.5", "4.5 out of 5" -> 4.5 (website reviewRating).
  static double _rating(dynamic v) {
    if (v is num) return v.toDouble();
    final m = RegExp(r'(\d+(\.\d+)?)').firstMatch(v?.toString() ?? '');
    return m == null ? 0 : double.parse(m.group(1)!);
  }
}
