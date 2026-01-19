const Map<String, dynamic> airportServiceConfig = {
  "airport_parking_services": [
    {
      "service_type": "Park & Ride",
      "normalized_type": "park and ride",
      "airport": "Bristol",
      "contact": {"number": "044 7761 226717"},
      "location": {"address": "stable cottage stock lane langford BS40 5EX"},
      "arrival_procedure":
          "Upon your arrival, kindly proceed to the car park reception and present your confirmation. Subsequently, one of our courteous chauffeurs will promptly transport you directly to the airport on the next available shuttle. Please be aware that if you are either ahead of or behind schedule, we will do our best to accommodate your adjusted arrival time; however, we cannot guarantee immediate placement on the next shuttle.\n\nTRANSFERS\nTransfer charges  £7.00 not included each way",
      "departure_procedure":
          "Upon your arrival, kindly proceed to the car park reception and present your confirmation. Subsequently, one of our courteous chauffeurs will promptly transport you directly to the airport on the next available shuttle. Please be aware that if you are either ahead of or behind schedule, we will do our best to accommodate your adjusted arrival time; however, we cannot guarantee immediate placement on the next shuttle.\n\nTRANSFERS\nTransfer charges  £7.00 not included each way"
    },
    {
      "service_type": "Meet & Greet",
      "normalized_type": "meet and greet",
      "airport": "Bristol",
      "contact": {"number": "044 7761 226717"},
      "location": {"address": "BS48 3DY Short Stay Car Park"},
      "arrival_procedure":
          "Please call on driver's number when you are 40 to 45 minutes away from the terminal so that we can dispatch a driver to meet you. Bristol Airport postcode for Sat Nav: BS48 3DY.\n\nAfter Arriving Bristol airport, please follow the signs to 'short stay' Car Park Area. Our Driver will meet you there.\n\nPlease have your booking confirmation and reference number to hand when you call so that we can check all of your details with you. \n\nBristol Airport postcode for Sat Nav: BS48 3DY\n\nAirport Levy Charges (Payable to Airport Barrier) \n\n£ 7 Per Car for Drop Off\n£ 7 Per car will be charged on pick up",
      "departure_procedure":
          "Please call on driver's number when you are 40 to 45 minutes away from the terminal so that we can dispatch a driver to meet you. Bristol Airport postcode for Sat Nav: BS48 3DY.\n\nAfter Arriving Bristol airport, please follow the signs to 'short stay' Car Park Area. Our Driver will meet you there.\n\nPlease have your booking confirmation and reference number to hand when you call so that we can check all of your details with you. \n\nBristol Airport postcode for Sat Nav: BS48 3DY\n\nAirport Levy Charges (Payable to Airport Barrier) \n\n£ 7 Per Car for Drop Off\n£ 7 Per car will be charged on pick up"
    },
    {
      "service_type": "Park & Ride",
      "normalized_type": "park and ride",
      "airport": "Luton",
      "contact": {"number": "447552865549"},
      "location": {"address": "LU2 0HN Burr street Right by the MOT Center"},
      "arrival_procedure":
          "Please call 30 minutes prior to your arrival so that our bus driver can meet you at the parking facility. Airport Levy Charges are not Included; Drop Off: £7 Pick Up : £7",
      "departure_procedure":
          "On your return please call to arrange for the bus to collect you.Airport Levy Charges are not Included; Drop Off: £7 Pick Up : £7"
    },
    {
      "service_type": "Meet & Greet",
      "normalized_type": "meet and greet",
      "airport": "Luton",
      "contact": {"number": "447552865549"},
      "location": {"address": "LU29LY Pickup & Drop OFF Point"},
      "arrival_procedure":
          "Please call on driver's number when you are 40 to 45 minutes away from the terminal so that we can dispatch a driver to meet you. Luton Airport postcode for LU29LY Pickup & Drop OFF Point Luton\n\nAfter Arriving Luton airport, Our Driver will meet you there.\n\nPlease have your booking confirmation and reference number to hand when you call so that we can check all of your details with you. \n\nLuton Airport postcode for LU29LY Pickup & Drop OFF Point Luton\n\nAirport Levy Charges (Payable to Airport Barrier) \n\n£ 7 Per Car for Drop Off\n£ 7 Per car will be charged on pick up",
      "departure_procedure":
          "Please call on driver's number when you are 40 to 45 minutes away from the terminal so that we can dispatch a driver to meet you. Luton Airport postcode for LU29QT Mid Stay Car Park Luton\n\nAfter Arriving Luton airport, Our Driver will meet you there.\n\nPlease have your booking confirmation and reference number to hand when you call so that we can check all of your details with you. \n\nLuton Airport postcode for LU29QT Mid Stay Car Park Luton\n\nAirport Levy Charges (Payable to Airport Barrier) \n\n£ 7 Per Car for Drop Off\n£ 7 Per car will be charged on pick up"
    },
    {
      "service_type": "Park & Ride",
      "normalized_type": "park and ride",
      "airport": "Stansted",
      "contact": {"number": "03300 435 761"},
      "location": {"address": "New Farm Parking, Stansted Road, CM22 6LL"},
      "arrival_procedure":
          "Please proceed to New Farm Parking at the address above. On arrival, present your booking confirmation at the reception. Our shuttle service will transfer you to Stansted Airport terminal. The shuttle runs every 15-20 minutes during peak hours. Please allow extra time during busy periods.\n\nTRANSFERS\nShuttle service included in your booking price.",
      "departure_procedure":
          "On your return to Stansted Airport, please call the contact number to arrange your shuttle pickup from the designated airport shuttle point. The shuttle will bring you back to New Farm Parking where your vehicle will be ready for collection.\n\nPlease allow 15-20 minutes for the shuttle to arrive during normal operating hours."
    },
    {
      "service_type": "Meet & Greet",
      "normalized_type": "meet and greet",
      "airport": "Stansted",
      "contact": {"number": "03300 435 761"},
      "location": {"address": "CM24 1RW Orange Car Park, Stansted Airport"},
      "arrival_procedure":
          "Please call the driver 40-45 minutes before your arrival at Stansted Airport. Our chauffeur will meet you at the Orange Car Park (CM24 1RW). Follow signs for the Orange Car Park at Stansted Airport.\n\nPlease have your booking confirmation and reference number ready when you call. The driver will verify your details and meet you at the designated area.\n\nAirport charges may apply for drop-off at the Orange Car Park.",
      "departure_procedure":
          "On your return to Stansted Airport, please call the contact number 30-40 minutes before you collect your luggage. Our driver will meet you at the Orange Car Park (CM24 1RW) with your vehicle.\n\nPlease have your ID and booking reference ready for verification. Your vehicle will be brought to you at the designated meeting point.\n\nPlease allow some time for the driver to bring your vehicle from the secure parking area."
    }
  ]
};

Map<String, dynamic>? getAirportServiceInfo(
    String airport, String packageType) {
  final services = airportServiceConfig["airport_parking_services"] as List;

  final normalizedPackageType = packageType.toLowerCase();

  try {
    return services.firstWhere(
      (service) =>
          service["airport"].toString().toLowerCase() ==
              airport.toLowerCase() &&
          service["normalized_type"].toString().toLowerCase() ==
              normalizedPackageType,
    ) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}
