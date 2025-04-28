import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/api_files.dart';
import 'package:parkingapp/data/api/api_service.dart';
import 'package:parkingapp/data/models/BookingAdminModel.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
import 'package:parkingapp/data/models/CheckPointRequestModel.dart';
import 'package:parkingapp/data/models/CheckPointsModel.dart';
import 'package:parkingapp/data/models/OtpModel.dart';
import 'package:parkingapp/data/models/PaymentResponse.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';

class GeneralRepository {
  APIService server = APIService();

  Future<UserModel> signin(String email, String password) async {
    Completer<UserModel> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.signin,
      requestMethod: RequestMethod.post,
      requestData: {
        "email": email,
        "password": password,
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        final userData = res['data']['user'];
        final token = res['token']; // token is fetched correctly
        final combinedJson = {
          'user': userData,
          'token': token,
        };

        UserModel user = UserModel.fromJson(combinedJson);
        SharedStorage.saveUser(user); // Should work now
        completer.complete(user);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'login',
          message: errorMessage,
          duration: 10,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<Otpmodel> forgotPassword(String email) async {
    Completer<Otpmodel> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.forgotPassword,
      requestMethod: RequestMethod.post,
      requestData: {
        "email": email,
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        final userData = res['data'];
        Otpmodel user = Otpmodel.fromJson(userData);
        completer.complete(user);
      },
      onError: (String errorMessage) {
        print(errorMessage);
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'reset',
          message: errorMessage,
          duration: 10,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

Future<String> resetPassword(String password, String confirmPassword) async {
    Completer<String> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.resetPassword,
      requestMethod: RequestMethod.post,
      requestData: {
        "password": password,
        "confirmPassword": confirmPassword,
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        final message = res['message'] ?? 'Location posted successfully';
      completer.complete(message);
      },
      onError: (String errorMessage) {
        print(errorMessage);
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'reset',
          message: errorMessage,
          duration: 10,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }
  Future<UserModel> signup({
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
    required String password,
    required String confirmPassword,
  }) async {
    Completer<UserModel> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.signup, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      requestData: {
        "title": title,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNo": phoneNo,
        "password": password,
        "confirmPassword": confirmPassword,
      },
      onLoad: () {
        EasyLoading.show(status: "Creating account...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        // Assuming the response structure is the same as signin
        final userData = res['data']['user'];
        final token = res['token'];
        final combinedJson = {
          'user': userData,
          'token': token,
        };

        UserModel user = UserModel.fromJson(combinedJson);
        completer.complete(user);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'signup',
          message: errorMessage,
          duration: 10,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<BookingResponse> getBookings() async {
    Completer<BookingResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint:
          ApiFiles.bookingsList, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final bookingsData =
            res['data']; // Access the 'data' field from the response
        BookingResponse response = BookingResponse.fromJson(bookingsData);
        completer.complete(response);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<BookingDriverResponse> getBookingsForDriver() async {
    Completer<BookingDriverResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint:
          ApiFiles.bookingsList, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final bookingsData =
            res['data']; // Access the 'data' field from the response
        BookingDriverResponse response =
            BookingDriverResponse.fromJson(bookingsData);
        completer.complete(response);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }
  Future<BookingAdminResponse> getBookingsForAdmin() async {
    Completer<BookingAdminResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint:
          ApiFiles.bookingsList, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final bookingsData =
            res['data']; // Access the 'data' field from the response
        BookingAdminResponse response =
            BookingAdminResponse.fromJson(bookingsData);
        completer.complete(response);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<PaymentResponse> getPaymentHistory() async {
    Completer<PaymentResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.paymentHistoryList, // Define this endpoint
      requestMethod:
          RequestMethod.post, // Or GET if that's what your API expects
      onLoad: () {
        EasyLoading.show(status: "Loading payments...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        try {
          final paymentData = res['data']; // Access the 'data' field
          PaymentResponse response = PaymentResponse.fromJson({
            'message': res['message'] ?? 'Payments Retrieved',
            'data': paymentData,
          });
          completer.complete(response);
        } catch (e) {
          completer.completeError("Error parsing payment data: $e");
        }
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<SearchResultResponse> searchParking({
    required String startDate,
    required String endDate,
    required String airport,
    required String startTime,
    required String endTime,
  }) async {
    final completer = Completer<SearchResultResponse>();

    try {
      // Validate input parameters
      if (startDate.isEmpty ||
          endDate.isEmpty ||
          airport.isEmpty ||
          startTime.isEmpty ||
          endTime.isEmpty) {
        throw Exception('All parameters are required');
      }

      debugPrint('''Making search request with:
      Start Date: $startDate
      End Date: $endDate
      Airport: $airport
      Start Time: $startTime
      End Time: $endTime
    ''');

      server.makeApiRequest(
        apiEndpoint: ApiFiles.searchParking,
        requestMethod: RequestMethod.post,
        requestData: {
          "startDate": startDate,
          "endDate": endDate,
          "airport": airport,
          "startTime": startTime,
          "endTime": endTime,
        },
        onLoad: () {
          EasyLoading.show(
            status: "Searching parking options...",
            maskType: EasyLoadingMaskType.black,
          );
        },
        onSuccess: (Map<String, dynamic> response) {
          try {
            debugPrint('API Response: $response');

            // Validate response structure
            if (response['data'] == null) {
              throw Exception('Invalid API response structure');
            }

            final result = SearchResultResponse.fromJson(response);

            if (result.data.isEmpty) {
              EasyLoading.showInfo('No parking options available');
            } else {
              EasyLoading.dismiss();
            }

            completer.complete(result);
          } catch (e) {
            EasyLoading.dismiss();
            debugPrint('Response parsing error: $e');
            completer.completeError('Failed to process parking options: $e');
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          debugPrint('API Error: $errorMessage');

          // Enhance error message for common cases
          final enhancedError = errorMessage.contains('timeout')
              ? 'Request timed out. Please check your connection'
              : errorMessage.contains('404')
                  ? 'Service not available'
                  : errorMessage;

          completer.completeError(enhancedError);
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Search parking error: $e');
      completer.completeError(e.toString());
    }

    return completer.future;
  }

  Future<BookingResponse> bookParking({
    required String startDate,
    required String endDate,
    required String airport,
    required String startTime,
    required String endTime,
    required String outboundTerminal,
    required String outboundFlightNo,
    required String inboundTerminal,
    required String inboundFlightNo,
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
    required String vehicleRegistrationNo,
    required String vehicleManufacturer,
    required String vehicleModel,
    required String vehicleColor,
    required String numberOfPassengers,
    required String userId,
    required String name,
    required String price,
    required String description,
    required List<String> bulletPoints,
    required String totalPrice,
    required String referenceNo,
  }) async {
    Completer<BookingResponse> completer = Completer();

    try {
      // Validate input parameters
      if (startDate.isEmpty ||
          endDate.isEmpty ||
          airport.isEmpty ||
          startTime.isEmpty ||
          endTime.isEmpty ||
          outboundTerminal.isEmpty ||
          outboundFlightNo.isEmpty ||
          inboundTerminal.isEmpty ||
          inboundFlightNo.isEmpty ||
          title.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          email.isEmpty ||
          phoneNo.isEmpty ||
          vehicleRegistrationNo.isEmpty ||
          vehicleManufacturer.isEmpty ||
          vehicleModel.isEmpty ||
          vehicleColor.isEmpty ||
          numberOfPassengers.isEmpty ||
          userId.isEmpty ||
          name.isEmpty ||
          price.isEmpty ||
          description.isEmpty ||
          bulletPoints.isEmpty ||
          totalPrice.isEmpty ||
          referenceNo.isEmpty) {
        throw Exception('All parameters are required');
      }
      server.makeApiRequest(
        apiEndpoint:
            ApiFiles.bookParking, // Ensure this endpoint is defined in ApiFiles
        requestMethod: RequestMethod.post,

        requestData: {
          "startDate": startDate,
          "endDate": endDate,
          "airport": airport,
          "startTime": startTime,
          "endTime": endTime,
          "outboundTerminal": outboundTerminal,
          "outboundFlightNo": outboundFlightNo,
          "inboundTerminal": inboundTerminal,
          "inboundFlightNo": inboundFlightNo,
          "title": title,
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "phoneNo": phoneNo,
          "vehicleRegistrationNo": vehicleRegistrationNo,
          "vehicleManufacturer": vehicleManufacturer,
          "vehicleModel": vehicleModel,
          "vehicleColor": vehicleColor,
          "numberOfPassengers": numberOfPassengers,
          "userId": userId,
          "name": name,
          "price": price,
          "description": description,
          "bulletPoints": bulletPoints,
          "totalPayment": totalPrice,
          "referenceNo": referenceNo,
        },
        onLoad: () {
          EasyLoading.show(status: "Booking parking...");
        },
        onSuccess: (Map<String, dynamic> response) {
          EasyLoading.dismiss();

          try {
            // Check if the response contains necessary data
            if (response.isEmpty) {
              throw Exception('Booking response is empty or invalid');
            }

            final bookingData = response;
            BookingResponse bookingResponse =
                BookingResponse.fromJson(bookingData);

            completer.complete(bookingResponse);
          } catch (e) {
            EasyLoading.dismiss();
            debugPrint('Error processing booking response: $e');
            completer.completeError('Error processing booking response: $e');
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          debugPrint('API Error: $errorMessage');
          completer.completeError(errorMessage);
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Booking error: $e');
      completer.completeError(e.toString());
    }

    return completer.future;
  }

Future<CheckpointResponseModel> submitCheckpoint(
    CheckpointRequestModel model, List<File>? pictures) async {
  Completer<CheckpointResponseModel> completer = Completer();

  try {
    EasyLoading.show(status: "Submitting checkpoint...");
    
    // Debug prints
    debugPrint("Booking ID: ${model.bookingId}");
    debugPrint("Location: ${model.location}");
    debugPrint("Section: ${model.section}");
    debugPrint("Type: ${model.type}");
    debugPrint("Number of pictures: ${pictures?.length ?? 0}");

    if (pictures != null && pictures.isNotEmpty) {
      // Multipart request with images
      server.makeMultipartRequest(
        apiEndpoint: ApiFiles.createCheckpoint,
        requestMethod: RequestMethod.post,
        fields: {
          "bookingId": model.bookingId,
          "location": model.location,
          "section": model.section,
          "type": model.type,
          
        },
        files: pictures.map((file) => MultipartFileInfo(
          file: file,
          fieldName: "pictures", // Some APIs expect array notation
        )).toList(),
        onSuccess: (Map<String, dynamic> response) {
          EasyLoading.dismiss();
          debugPrint("API Response: $response");
          try {
            final checkpointResponse = CheckpointResponseModel.fromJson(
                response['response'] ?? response); // Try both options
            completer.complete(checkpointResponse);
          } catch (e) {
            debugPrint("Parsing error: $e");
            completer.completeError("Parsing error: $e");
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          debugPrint("API Error: $errorMessage");
          completer.completeError("API Error: $errorMessage");
        },
      );
    } else {
      // Simple request without files
      server.makeApiRequest(
        apiEndpoint: ApiFiles.createCheckpoint,
        requestMethod: RequestMethod.post,
        requestData: {
          "bookingId": model.bookingId,
          "location": model.location,
          "section": model.section,
          "type": model.type,
        },
        onLoad: () => EasyLoading.show(status: "Submitting checkpoint..."),
        onSuccess: (Map<String, dynamic> response) {
          EasyLoading.dismiss();
          debugPrint("API Response: $response");
          try {
            final checkpointResponse = CheckpointResponseModel.fromJson(
                response['response'] ?? response);
            completer.complete(checkpointResponse);
          } catch (e) {
            completer.completeError("Parsing error: $e");
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          debugPrint("API Error: $errorMessage");
          completer.completeError("API Error: $errorMessage");
        },
      );
    }
  } catch (e) {
    EasyLoading.dismiss();
    debugPrint("Exception in submitCheckpoint: $e");
    completer.completeError("Exception: $e");
  }

  return completer.future;
}

Future<Map<String, dynamic>> createPaymentIntent({
  required String amount,
  required String currency,
}) async {
  final url = Uri.parse('http://137.184.9.55:8000/api/stripe/create-payment-intent');

  final token = Globals.user?.token ?? '';
  print("Calling payment intent API with amount=$amount, currency=$currency, token=$token");

  // Convert amount to integer
  final amountInt = int.tryParse(amount) ?? 0;
  if (amountInt <= 0) {
    throw Exception('Invalid amount: $amount');
  }

  final response = await http.post(
    url,
    body: jsonEncode({  // Use jsonEncode for proper JSON formatting
      'amount': amountInt,  // Send as integer
      'currency': currency.toLowerCase(),  // Ensure lowercase currency
    }),
    headers: {
      'access-token': token,
      'Content-Type': 'application/json',  // Add content-type header
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to create payment intent: ${response.statusCode} ${response.body}');
  }
}

Future<String> postLocation(String bookingID, String latitude, String longitude) async {
  Completer<String> completer = Completer();

  server.makeApiRequest(
    apiEndpoint: ApiFiles.postLocation,
    requestMethod: RequestMethod.post,
    requestData: {
      "bookingId": bookingID,
      "longitude": longitude,
      "latitude": latitude,
    },
    onLoad: () {
      EasyLoading.show(status: "Loading...");
    },
    onSuccess: (Map<String, dynamic> res) {
      EasyLoading.dismiss();
      final message = res['message'] ?? 'Location posted successfully';
      completer.complete(message);
    },
    onError: (String errorMessage) {
      EasyLoading.dismiss();
      Alertify.showAlert(
        alertKey: 'postLocation',
        message: errorMessage,
        duration: 10,
        type: AlertType.error,
      );
      completer.completeError(errorMessage);
    },
  );

  return completer.future;
}


Future<Map<String, String>> getLocationCoordinates(String bookingID) async {
  Completer<Map<String, String>> completer = Completer();

  server.makeApiRequest(
    apiEndpoint: ApiFiles.getLocationDetails, // replace with actual endpoint
    requestMethod: RequestMethod.post,
    requestData: {
      "bookingId": bookingID,
    },
    onLoad: () {
      EasyLoading.show(status: "Loading...");
    },
    onSuccess: (Map<String, dynamic> res) {
      EasyLoading.dismiss();
      final data = res['data'];
      final longitude = data['longitude'] ?? '';
      final latitude = data['latitude'] ?? '';

      completer.complete({
        'longitude': longitude,
        'latitude': latitude,
      });
    },
    onError: (String errorMessage) {
      EasyLoading.dismiss();
      Alertify.showAlert(
        alertKey: 'getLocation',
        message: errorMessage,
        duration: 10,
        type: AlertType.error,
      );
      completer.completeError(errorMessage);
    },
  );

  return completer.future;
}

Future<Map<String, dynamic>> getEmployeesWithBookings() async {
  Completer<Map<String, dynamic>> completer = Completer();

  server.makeApiRequest(
    apiEndpoint: ApiFiles.getDrivers,
    requestMethod: RequestMethod.post,
    onLoad: () {
      EasyLoading.show(status: "Loading employees...");
    },
    onSuccess: (Map<String, dynamic> response) {
      EasyLoading.dismiss();
      try {
        // Validate response structure
        if (response['data'] == null) {
          throw Exception('Invalid API response structure');
        }

        completer.complete(response);
      } catch (e) {
        completer.completeError('Failed to process employees data: $e');
      }
    },
    onError: (String errorMessage) {
      EasyLoading.dismiss();
      completer.completeError(errorMessage);
    },
  );

  return completer.future;
}
}


