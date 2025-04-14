import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:parkingapp/data/api/api_files.dart';
import 'package:parkingapp/data/api/api_service.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
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
            if (response['data'] == null ||
                response['data']['results'] == null) {
              throw Exception('Invalid API response structure');
            }

            final result = SearchResultResponse.fromJson(response);

            if (result.data.results.isEmpty) {
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
          bulletPoints.isEmpty || totalPrice.isEmpty || referenceNo.isEmpty) {
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
}
