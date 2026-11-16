import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/models/PackageDetailModel.dart';

/// Airport service info (address, contact, arrival / return steps) as the admin panel
/// has it. Filled from GET /api/search/v5/package/:id when a package is opened, and
/// used only where a booking itself has no such info. Replaces the old hardcoded
/// airport_service_config.dart.
class AirportServices {
  static final Map<String, Map<String, dynamic>> _byKey = {};

  static void remember(PackageDetail detail) {
    if (!detail.isLive || detail.airport.isEmpty) return;
    final info = detail.airportInfo;
    final s = detail.sections;
    if (info == null && s.onArrival.isEmpty && s.onReturn.isEmpty) return;
    _byKey[serviceKey(detail.airport, detail.type ?? '')] = {
      'contact': {'number': info?.contactNumber ?? ''},
      'location': {'address': info?.fullAddress ?? ''},
      'arrival_procedure': s.onArrival,
      'departure_procedure': s.onReturn,
    };
  }

  static Map<String, dynamic>? lookup(String airport, String packageType) =>
      _byKey[serviceKey(airport, packageType)];

  static void clear() => _byKey.clear();
}

/// Same shape the screens used before: {contact: {number}, location: {address},
/// arrival_procedure, departure_procedure}; null when nothing is known.
Map<String, dynamic>? getAirportServiceInfo(String airport, String packageType) =>
    AirportServices.lookup(airport, packageType);
