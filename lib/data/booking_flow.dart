// Customer booking helpers that follow the website's search -> book journey
// (airportparking-frontend-next). Plain Dart, no Flutter, so they can be unit tested.

/// Airports we take bookings for. Used only until GET /api/site-config answers,
/// and to drop closed airports that are still switched on in admin
/// (same list as the website's src/data/activeAirports.js).
const List<String> kActiveAirports = [
  'Bristol',
  'Glasgow',
  'Luton',
  'Manchester',
  'Stansted',
];

/// True when an airport name from the API ("London Stansted", ...) is one we serve.
bool isActiveAirportName(String name) {
  final n = name.toLowerCase();
  return kActiveAirports.any((a) => n.contains(a.toLowerCase()));
}

/// What the admin panel controls for the public site (GET /api/site-config).
class SiteConfig {
  final List<String> airports;
  final String savingsText;
  final bool priceComparison;

  const SiteConfig({
    required this.airports,
    required this.savingsText,
    required this.priceComparison,
  });

  static const SiteConfig defaults = SiteConfig(
    airports: kActiveAirports,
    savingsText: 'Save upto 75%',
    priceComparison: true,
  );

  factory SiteConfig.fromJson(Map<String, dynamic>? json) {
    final data = json?['data'] is Map ? json!['data'] as Map : const {};
    final names = (data['airports'] is List ? data['airports'] as List : const [])
        .map((a) => a is Map ? a['name']?.toString() ?? '' : a.toString())
        .where((n) => n.isNotEmpty && isActiveAirportName(n))
        .toList();
    final marketing =
        data['marketing'] is Map ? data['marketing'] as Map : const {};
    return SiteConfig(
      airports: names.isNotEmpty ? names : defaults.airports,
      savingsText: marketing['savingsText']?.toString() ?? defaults.savingsText,
      priceComparison: marketing['priceComparison'] is bool
          ? marketing['priceComparison'] as bool
          : defaults.priceComparison,
    );
  }
}

/// Dates sent to the search API. Like the website, a search whose check-in is today
/// asks the API for the next day (both dates move together, so the length of stay is
/// unchanged). The booking itself keeps the real dates.
({String startDate, String endDate}) searchApiDates(
    String startDate, String endDate,
    {DateTime? now}) {
  final start = DateTime.tryParse(startDate);
  final end = DateTime.tryParse(endDate);
  final today = now ?? DateTime.now();
  if (start == null ||
      end == null ||
      start.year != today.year ||
      start.month != today.month ||
      start.day != today.day) {
    return (startDate: startDate, endDate: endDate);
  }
  return (
    startDate: _ymd(start.add(const Duration(days: 1))),
    endDate: _ymd(end.add(const Duration(days: 1))),
  );
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Time in the website's format, "hh:mm a" (e.g. "02:30 PM").
String formatApiTime(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'AM' : 'PM';
  return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
}

/// Number from a price such as 38.69, "38.69" or "£38.69"; 0 when there is none.
double parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  final clean = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(clean) ?? 0;
}

String formatPrice(double value) => '£${value.toStringAsFixed(2)}';

/// The website's "Price Comparison" block: three comparison sites at 15%, 20% and 25%
/// above our price (src/components/PackageCard.jsx).
class ComparisonPrice {
  final String name;
  final String logoAsset;
  final double price;
  final double savings;
  const ComparisonPrice(this.name, this.logoAsset, this.price, this.savings);
}

List<ComparisonPrice> comparisonPrices(double ourPrice) {
  const sites = [
    ('Compare The Airport Parking', 'assets/images/compare.jpeg'),
    ('Compare Parking Prices', 'assets/images/payel.jpeg'),
    ('Parking 4 less', 'assets/images/owl.jpeg'),
  ];
  return [
    for (var i = 0; i < sites.length; i++)
      () {
        final higher = ourPrice * (1.15 + i * 0.05);
        final rounded = double.parse(higher.toStringAsFixed(2));
        return ComparisonPrice(sites[i].$1, sites[i].$2, rounded,
            double.parse((higher - ourPrice).toStringAsFixed(2)));
      }(),
  ];
}

/// Body of POST /api/stripe/create-payment-intent, as the website sends it
/// (payment/page.jsx). The server charges the price of [packageId] from its own
/// search results and checks the airport and length of stay against that search.
Map<String, dynamic> paymentIntentPayload({
  required String packageId,
  required double amount,
  required String currency,
  required String paymentMethod,
  required String startDate,
  required String startTime,
  required String endDate,
  required String endTime,
  required String airport,
  String? userId,
  String? email,
  String? firstName,
  String? lastName,
}) {
  final name = [firstName, lastName]
      .where((s) => s != null && s.trim().isNotEmpty)
      .map((s) => s!.trim())
      .join(' ');
  return {
    'packageId': packageId,
    'amount': amount, // pounds, e.g. 38.69
    'currency': currency.toLowerCase(),
    'payment_method': paymentMethod,
    'test_mode': false,
    'startDate': startDate,
    'startTime': startTime,
    'endDate': endDate,
    'endTime': endTime,
    'airport': airport,
    'userId': userId,
    'customer': {
      'email': email,
      if (name.isNotEmpty) 'name': name,
    },
  };
}

/// Changing a booking's dates (backend booking.controller.js bookingChangeQuote):
/// the customer already paid for the original stay, so they pay the change fee
/// (£20) every time, plus £15 for each day the new stay is LONGER than the original.
/// Moving the same-length stay, or making it shorter, costs the change fee only.
/// Both values are set per airport in admin; the server's amount is what is charged.
const double kBookingChangeFee = 20;
const double kExtraDayCharge = 15;

int bookingChangeExtraDays(DateTime oldStart, DateTime oldEnd, DateTime newStart,
    DateTime newEnd) {
  int days(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
  final extra = days(newStart, newEnd) - days(oldStart, oldEnd);
  return extra > 0 ? extra : 0;
}

double bookingChangeCost(int extraDays,
        {double changeFee = kBookingChangeFee,
        double extraDayCharge = kExtraDayCharge}) =>
    double.parse((changeFee + extraDays * extraDayCharge).toStringAsFixed(2));

/// Key used to match an airport + package type ("Meet & Greet", "meet_and_greet", ...).
String serviceKey(String airport, String packageType) {
  // Separators first ("meet_and_greet" -> "meet and greet"), then drop the word "and"
  final type = packageType
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]+'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty && w != 'and')
      .join();
  return '${airport.toLowerCase().trim()}|$type';
}
