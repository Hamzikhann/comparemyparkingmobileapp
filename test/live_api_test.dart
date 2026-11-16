// Read-only check of the customer models against a running backend (default
// http://localhost:8001). Skips when the backend is not reachable.
//   flutter test test/live_api_test.dart
//   API_BASE=http://host:port flutter test test/live_api_test.dart
// It runs one real search (the backend scrapes, so it can take a minute) and opens
// one package. No sign-up, payment or booking is made.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/models/PackageDetailModel.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';

final base = Platform.environment['API_BASE'] ?? 'http://localhost:8001';

Future<(int, Map<String, dynamic>)> call(String method, String path,
    [Map<String, dynamic>? body]) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final req = await client.openUrl(method, Uri.parse('$base$path'));
    req.headers.set('user-agent', 'Dart/3 (dart:io)'); // backend blocks curl/bot
    req.headers.contentType = ContentType.json;
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close().timeout(const Duration(minutes: 3));
    final text = await res.transform(utf8.decoder).join();
    return (res.statusCode, jsonDecode(text) as Map<String, dynamic>);
  } finally {
    client.close(force: true);
  }
}

Future<bool> backendUp() async {
  try {
    await call('GET', '/api/site-config');
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool up;
  setUpAll(() async => up = await backendUp());

  test('site-config gives active airports and marketing switches', () async {
    if (!up) return markTestSkipped('backend not reachable at $base');
    final (status, json) = await call('GET', '/api/site-config');
    expect(status, 200);
    final config = SiteConfig.fromJson(json);
    // ignore: avoid_print
    print('site-config airports: ${config.airports} | marketing: '
        '"${config.savingsText}", comparison=${config.priceComparison}');
    expect(config.airports, isNotEmpty);
    expect(config.airports.every(isActiveAirportName), isTrue);
  });

  test('search -> package details works with the app models', () async {
    if (!up) return markTestSkipped('backend not reachable at $base');
    final (_, cfgJson) = await call('GET', '/api/site-config');
    final airports = SiteConfig.fromJson(cfgJson).airports;
    final airport = airports.contains('Stansted') ? 'Stansted' : airports.first;

    final start = DateTime.now().add(const Duration(days: 21));
    final end = start.add(const Duration(days: 7));
    String ymd(DateTime d) => d.toIso8601String().substring(0, 10);
    final dates = searchApiDates(ymd(start), ymd(end));

    final (status, json) = await call('POST', '/api/search/v5', {
      'airport': airport,
      'startDate': dates.startDate,
      'endDate': dates.endDate,
      'startTime': formatApiTime(9, 0),
      'endTime': formatApiTime(18, 30),
    });
    expect(status, 200, reason: json['message']?.toString());

    final result = SearchResultResponse.fromJson(json);
    // ignore: avoid_print
    print('search $airport ${dates.startDate}..${dates.endDate}: '
        '${result.data.length} packages, bookable=${result.bookable}, '
        'note=${result.note}');
    if (result.data.isEmpty) {
      return markTestSkipped('search returned no packages (${result.note})');
    }

    for (final p in result.data) {
      expect(p.packageId, isNotNull, reason: 'every package needs packageId');
      expect(p.name, isNot('Parking Package'));
      if (p.isFullyBooked) {
        expect(p.displayPrice, 'Fully Booked');
      } else {
        expect(p.priceValue, greaterThan(0));
        expect(p.displayPrice, startsWith('£'));
      }
    }
    final first = result.data.first;
    // ignore: avoid_print
    print('first: "${first.name}" ${first.displayPrice} packageId=${first.packageId} '
        'brand=${first.originalName} tier=${first.tier} '
        'features=${first.bulletPoints.length}');

    final (dStatus, dJson) = await call(
        'GET', '/api/search/v5/package/${Uri.encodeComponent(first.packageId!)}');
    expect(dStatus, 200, reason: dJson['message']?.toString());
    final detail = PackageDetail.fromJson(dJson);
    expect(detail.packageId, first.packageId);
    // ignore: avoid_print
    print('detail: mode=${detail.mode} overview=${detail.sections.overview.length} chars, '
        'onArrival=${detail.sections.onArrival.isNotEmpty}, '
        'address="${detail.airportInfo?.fullAddress}", '
        'contact="${detail.airportInfo?.contactNumber}", reviews=${detail.reviews.length}');
    if (detail.isLive) {
      expect(first.originalName, isNotNull, reason: 'live packages carry brand');
      expect(first.tier, isNotNull, reason: 'live packages carry tier');
    }
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('payment without packageId is refused by the server (why the app failed)',
      () async {
    if (!up) return markTestSkipped('backend not reachable at $base');
    // No token / user: the server answers before charging anything.
    final (status, json) = await call('POST', '/api/stripe/create-payment-intent', {
      'amount': 38,
      'currency': 'gbp',
      'airport': 'Stansted',
      'startDate': '2030-01-01',
      'endDate': '2030-01-08',
    });
    // ignore: avoid_print
    print('create-payment-intent without packageId -> $status ${json['message']}');
    expect(status, isNot(200));
  });

  test('booking change endpoints exist and need a login', () async {
    if (!up) return markTestSkipped('backend not reachable at $base');
    for (final path in ['/api/booking/change/quote', '/api/booking/change/payment-intent']) {
      final (status, json) = await call('POST', path,
          {'bookingId': 'x', 'startDate': '2030-01-01', 'endDate': '2030-01-08'});
      // ignore: avoid_print
      print('$path without token -> $status ${json['message']}');
      expect(status, isNot(404), reason: 'route must exist');
      expect(status, isNot(200), reason: 'must not answer without a token');
    }
  });
}
