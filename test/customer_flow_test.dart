// Customer search -> book journey, checked against the shapes the backend sends
// (parkpilotNode utils/search/packages.js, search.v5.new.controller.js) and what the
// website does (airportparking-frontend-next). Run: flutter test test/customer_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/data/airport_services.dart';
import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/models/PackageDetailModel.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';

// A live-airport search answer (buildLivePackages)
final liveSearch = <String, dynamic>{
  'message': 'search result',
  'airport': 'Stansted',
  'mode': 'live',
  'bookable': true,
  'priceCut': {'percentage': 10, 'applied': true},
  'promoCodeDetails': {
    'code': 'SAVE10',
    'discountType': 'percentage',
    'discountPercentage': 10,
    'savings': 4.3,
  },
  'cached': false,
  'data': [
    {
      'id': 1,
      'packageId': 'abc123-0',
      'productName': 'Swift Meet & Greet',
      'customTitle': 'Swift Meet & Greet',
      'name': 'Swift Meet & Greet',
      'originalName': 'SwiftPark',
      'type': 'meet_and_greet',
      'tier': 'premium',
      'logoUrl': 'https://img/tier.png',
      'imagenew': 'https://img/tier.png',
      'keyFeatures': ['Meet at terminal', '', '[Circular]', 'CCTV'],
      'features': ['Meet at terminal', 'CCTV'],
      'rating': 4.6,
      'ratingText': '4.6 out of 5',
      'reviewCount': 120,
      'frontPageSummary': 'Hand your keys over at the terminal.',
      'originalPrice': 48.0,
      'price': 38.69,
      'priceAfterCut': 38.69,
      'priceDiscount': 9.31,
      'isFullyBooked': false,
      'bookable': true,
    },
  ],
};

// A display-airport answer (buildDisplayPackages): not bookable, price "Fully Booked"
final displaySearch = <String, dynamic>{
  'message': 'search result',
  'airport': 'Manchester',
  'mode': 'display',
  'bookable': false,
  'data': [
    {
      'id': 1,
      'packageId': 'def456-0',
      'productName': 'Provider Park & Ride',
      'type': 'park_and_ride',
      'logo': 'https://img/provider.png',
      'features': ['Shuttle'],
      'rating': '4.1',
      'reviewCount': 12,
      'price': 'Fully Booked',
      'originalPrice': 31.5,
      'isFullyBooked': true,
      'bookable': false,
    },
  ],
};

void main() {
  group('Search results (POST /api/search/v5)', () {
    test('live package keeps packageId, brand and tier for payment/booking', () {
      final r = SearchResultResponse.fromJson(liveSearch);
      final p = r.data.single;
      expect(p.packageId, 'abc123-0');
      expect(p.originalName, 'SwiftPark');
      expect(p.tier, 'premium');
      expect(p.name, 'Swift Meet & Greet');
      expect(p.bookable, isTrue);
      expect(p.isFullyBooked, isFalse);
      expect(p.priceValue, 38.69);
      expect(p.displayPrice, '£38.69');
      expect(p.originalPrice, 48.0);
      expect(p.priceDiscount, 9.31);
      expect(p.imageUrl, 'https://img/tier.png');
      expect(p.summary, 'Hand your keys over at the terminal.');
      expect(p.reviews, 120);
    });

    test('features come from keyFeatures first and drop empty / [Circular]', () {
      final p = SearchResultResponse.fromJson(liveSearch).data.single;
      expect(p.bulletPoints, ['Meet at terminal', 'CCTV']);
    });

    test('display airport package is Fully Booked (no "£Fully Booked")', () {
      final r = SearchResultResponse.fromJson(displaySearch);
      final p = r.data.single;
      expect(r.bookable, isFalse);
      expect(p.isFullyBooked, isTrue);
      expect(p.displayPrice, 'Fully Booked');
      expect(p.priceValue, 31.5); // provider price, as the website's getPriceValue
      expect(p.name, 'Provider Park & Ride'); // productName when there is no name
      expect(p.imageUrl, 'https://img/provider.png');
      expect(p.rating, 4.1); // rating sent as a string
    });

    test('name rule no longer depends on a hardcoded airport list', () {
      final p = ParkingOption.fromJson({'name': 'Our Brand', 'productName': 'X'});
      expect(p.name, 'Our Brand');
      expect(ParkingOption.fromJson({}).name, 'Parking Package');
    });

    test('"Sorry" / "Fully booked" price text means not bookable', () {
      expect(ParkingOption.fromJson({'price': 'Sorry, sold out'}).isFullyBooked,
          isTrue);
      expect(ParkingOption.fromJson({'price': '25'}).isFullyBooked, isFalse);
    });

    test('promo code result and server note are read', () {
      final r = SearchResultResponse.fromJson(liveSearch);
      expect(r.promoCodeDetails!.label, 'SAVE10 applied (10% off)');
      final empty = SearchResultResponse.fromJson({
        'message': 'search result',
        'data': [],
        'note': 'This airport is not available',
        'bookable': false,
      });
      expect(empty.data, isEmpty);
      expect(empty.note, 'This airport is not available');
      final fixed = PromoCodeDetails.fromJson(
          {'code': 'FIVE', 'discountType': 'fixed', 'discountAmount': 5});
      expect(fixed.label, 'FIVE applied (£5.00 off)');
    });
  });

  group('Payment (POST /api/stripe/create-payment-intent)', () {
    test('sends packageId and the price in pounds, like the website', () {
      final body = paymentIntentPayload(
        packageId: 'abc123-0',
        amount: 38.69,
        currency: 'GBP',
        paymentMethod: 'card',
        startDate: '2026-12-01',
        startTime: '09:00 AM',
        endDate: '2026-12-08',
        endTime: '06:30 PM',
        airport: 'Stansted',
        userId: 'enc-user',
        email: 'a@b.com',
        firstName: 'Ali',
        lastName: 'Khan',
      );
      expect(body['packageId'], 'abc123-0');
      expect(body['amount'], 38.69); // not 38 "pence" any more
      expect(body['currency'], 'gbp');
      expect(body['airport'], 'Stansted');
      expect(body['customer'], {'email': 'a@b.com', 'name': 'Ali Khan'});
    });

    test('no "null null" customer name when names are missing', () {
      final body = paymentIntentPayload(
        packageId: 'p',
        amount: 1,
        currency: 'gbp',
        paymentMethod: 'card',
        startDate: '',
        startTime: '',
        endDate: '',
        endTime: '',
        airport: '',
      );
      expect((body['customer'] as Map).containsKey('name'), isFalse);
    });
  });

  group('Search dates and times', () {
    final now = DateTime(2026, 11, 16, 10, 0);

    test('check-in today asks the API for the next day (stay length kept)', () {
      final d = searchApiDates('2026-11-16', '2026-11-20', now: now);
      expect(d.startDate, '2026-11-17');
      expect(d.endDate, '2026-11-21');
    });

    test('future check-in is sent unchanged', () {
      final d = searchApiDates('2026-11-17', '2026-11-20', now: now);
      expect(d.startDate, '2026-11-17');
      expect(d.endDate, '2026-11-20');
    });

    test('month end rolls over', () {
      final d = searchApiDates('2026-11-30', '2026-12-31',
          now: DateTime(2026, 11, 30, 8));
      expect(d.startDate, '2026-12-01');
      expect(d.endDate, '2027-01-01');
    });

    test('times use the website format "hh:mm a"', () {
      expect(formatApiTime(0, 5), '12:05 AM');
      expect(formatApiTime(9, 0), '09:00 AM');
      expect(formatApiTime(12, 30), '12:30 PM'); // was "0:30 PM" in Bookings
      expect(formatApiTime(23, 59), '11:59 PM');
    });
  });

  group('Site config (GET /api/site-config)', () {
    test('airports come from admin, closed ones are dropped', () {
      final c = SiteConfig.fromJson({
        'data': {
          'airports': [
            {'name': 'Glasgow', 'code': 'GLA'},
            {'name': 'Heathrow', 'code': 'LHR'},
            {'name': 'Stansted', 'code': 'STN'},
          ],
          'marketing': {'savingsText': 'Save 50%', 'priceComparison': false},
        }
      });
      expect(c.airports, ['Glasgow', 'Stansted']);
      expect(c.savingsText, 'Save 50%');
      expect(c.priceComparison, isFalse);
    });

    test('falls back to the 5 active airports when the server sends none', () {
      final c = SiteConfig.fromJson({'data': {}});
      expect(c.airports,
          ['Bristol', 'Glasgow', 'Luton', 'Manchester', 'Stansted']);
      expect(c.airports, isNot(contains('Heathrow')));
      expect(c.savingsText, 'Save upto 75%');
      expect(c.priceComparison, isTrue);
    });
  });

  group('Package details (GET /api/search/v5/package/:id)', () {
    final liveDetail = {
      'message': 'Package details',
      'data': {
        'packageId': 'abc123-0',
        'mode': 'live',
        'airport': 'Stansted',
        'type': 'meet_and_greet',
        'features': ['Meet at terminal'],
        'sections': {
          'overview': 'Overview text',
          'serviceDetails': null,
          'onArrival': 'Call 30 minutes before.',
          'onReturn': 'Call when you land.',
        },
        'airportInfo': {
          'address': 'Orange Car Park, Stansted',
          'postalCode': 'CM24 1RW',
          'contactNumber': '07000 000000',
          'contactEmail': null,
        },
        'reviews': [],
      }
    };

    test('sections and airport info are read', () {
      final d = PackageDetail.fromJson(liveDetail);
      expect(d.isLive, isTrue);
      expect(d.sections.overview, 'Overview text');
      expect(d.sections.serviceDetails, '');
      expect(d.sections.onArrival, 'Call 30 minutes before.');
      expect(d.airportInfo!.fullAddress, 'Orange Car Park, Stansted, CM24 1RW');
      expect(d.airportInfo!.contactNumber, '07000 000000');
    });

    test('display airport reviews use the website fields', () {
      final d = PackageDetail.fromJson({
        'data': {
          'packageId': 'def456-0',
          'mode': 'display',
          'airport': 'Manchester',
          'sections': {'overview': 'x'},
          'airportInfo': null,
          'reviews': [
            {'user': 'Sam', 'comment': 'Great', 'rating': '4.5 out of 5', 'date': 'Oct'},
            {'comment': 'OK', 'rating': 3},
          ],
        }
      });
      expect(d.isLive, isFalse);
      expect(d.airportInfo, isNull);
      expect(d.reviews.first.author, 'Sam');
      expect(d.reviews.first.text, 'Great');
      expect(d.reviews.first.rating, 4.5);
      expect(d.reviews.last.author, '');
      expect(d.reviews.last.rating, 3);
    });

    test('opened package fills the booking screens\' airport info (no hardcoded file)',
        () {
      AirportServices.clear();
      expect(getAirportServiceInfo('Stansted', 'Meet & Greet'), isNull);
      AirportServices.remember(PackageDetail.fromJson(liveDetail));
      // Booking screens pass types like "Meet & Greet" / "meet and greet"
      for (final t in ['Meet & Greet', 'meet and greet', 'meet_and_greet']) {
        final info = getAirportServiceInfo('Stansted', t);
        expect(info, isNotNull, reason: t);
        expect(info!['contact']['number'], '07000 000000');
        expect(info['location']['address'], 'Orange Car Park, Stansted, CM24 1RW');
        expect(info['arrival_procedure'], 'Call 30 minutes before.');
        expect(info['departure_procedure'], 'Call when you land.');
      }
      expect(getAirportServiceInfo('Stansted', 'Park & Ride'), isNull);
    });
  });

  group('Booking date change (same rule as backend bookingChangeQuote)', () {
    final oStart = DateTime(2026, 12, 1), oEnd = DateTime(2026, 12, 8); // 7 days

    test('shorter stay pays the change fee only (£20)', () {
      final extra = bookingChangeExtraDays(
          oStart, oEnd, DateTime(2026, 12, 2), DateTime(2026, 12, 5));
      expect(extra, 0);
      expect(bookingChangeCost(extra), 20.0);
    });

    test('same length moved to other dates pays £20 (moving is not extra days)',
        () {
      final extra = bookingChangeExtraDays(
          oStart, oEnd, DateTime(2026, 12, 10), DateTime(2026, 12, 17));
      expect(extra, 0);
      expect(bookingChangeCost(extra), 20.0);
    });

    test('longer stay pays £20 + £15 per extra day', () {
      final extra = bookingChangeExtraDays(
          oStart, oEnd, DateTime(2026, 11, 30), DateTime(2026, 12, 10));
      expect(extra, 3); // 10 days vs 7
      expect(bookingChangeCost(extra), 65.0);
    });

    test('times of day do not change the day count', () {
      expect(
          bookingChangeExtraDays(DateTime(2026, 12, 1, 23), DateTime(2026, 12, 8, 1),
              DateTime(2026, 12, 1, 1), DateTime(2026, 12, 9, 23)),
          1);
    });

    test('admin fees per airport are used when given', () {
      expect(bookingChangeCost(2, changeFee: 25, extraDayCharge: 12.5), 50.0);
    });
  });

  group('Price comparison (website PackageCard)', () {
    test('three sites at +15%, +20%, +25%', () {
      final c = comparisonPrices(40);
      expect(c.map((x) => x.price), [46.0, 48.0, 50.0]);
      expect(c.map((x) => x.savings), [6.0, 8.0, 10.0]);
    });
  });
}
