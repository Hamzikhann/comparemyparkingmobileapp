import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/api_files.dart';
import 'package:parkingapp/data/api/api_service.dart';
import 'package:parkingapp/data/models/BookingAdminModel.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart';
import 'package:parkingapp/data/models/CheckPointRequestModel.dart';
import 'package:parkingapp/data/models/CheckPointsModel.dart';
import 'package:parkingapp/data/models/NotificationModel.dart';
import 'package:parkingapp/data/models/OtpModel.dart';
import 'package:parkingapp/data/models/OtpModelSignup.dart';
import 'package:parkingapp/data/models/PaymentResponse.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:parkingapp/data/models/UserUpdateModel.dart';
import 'package:parkingapp/data/models/VehicleLookupModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/routes/MyRoutes.dart';

class GeneralRepository {
  APIService server = APIService();

  Future<UserModel> signin(String email, String password) async {
    Completer<UserModel> completer = Completer();
    String? fcmToken = "";
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
    }

    server.makeApiRequest(
      apiEndpoint: ApiFiles.signin,
      requestMethod: RequestMethod.post,
      requestData: {
        "email": email,
        "password": password,
        "fcmToken": fcmToken ?? "",
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

  Future<OtpmodelSignup> verifyEmail(String email) async {
    Completer<OtpmodelSignup> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.verifyEmail,
      requestMethod: RequestMethod.post,
      requestData: {
        "email": email,
        "phoneNo": "",
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        final userData = res['data'];
        OtpmodelSignup user = OtpmodelSignup.fromJson(userData);
        completer.complete(user);
      },
      onError: (String errorMessage) {
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

  Future<OtpmodelSignup> verifyPhone(String phone) async {
    Completer<OtpmodelSignup> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.verifyEmail,
      requestMethod: RequestMethod.post,
      requestData: {
        "email": "",
        "phoneNo": phone,
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();

        final userData = res['data'];
        OtpmodelSignup user = OtpmodelSignup.fromJson(userData);
        completer.complete(user);
      },
      onError: (String errorMessage) {
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
    String? fcmToken = "";
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
    }

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
        "fcmToken": fcmToken ?? "",
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

  Future<UserModel> signupv2({
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
    required String password,
    required String confirmPassword,
  }) async {
    Completer<UserModel> completer = Completer();
    String? fcmToken = "";
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
    }

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
        "roleId": 'RmFBM1Z3UCtvNEJYNXZ2bXcxT00yUT09',
        "fcmToken": fcmToken ?? "",
      },
      onLoad: () {
        EasyLoading.show(status: "Add driver...");
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
        print(errorMessage);
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

  Future<UserUpdateResponse> updateDriver({
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
    required String userId,
  }) async {
    Completer<UserUpdateResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint:
          ApiFiles.updateDriver, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      requestData: {
        "title": title,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNo": phoneNo,
        "userId": userId,
      },
      onLoad: () {
        EasyLoading.show(status: "Update driver...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final response = UserUpdateResponse.fromJson(res);
        completer.complete(response);
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

  Future<Map<String, dynamic>?> updateProfileImage(
      String userId, File image) async {
    Completer<Map<String, dynamic>?> completer = Completer();
    server.makeMultipartRequest(
      apiEndpoint: ApiFiles.updateProfileImage,
      requestMethod: RequestMethod.post,
      fields: {"userId": userId},
      files: [MultipartFileInfo(file: image, fieldName: "image")],
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete(res);
      },
      onError: (String errorMessage) {
        print(errorMessage);
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'editProfile',
          message: errorMessage,
          duration: 10,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  Future<void> updateProfileInfo(Map<String, dynamic> data) async {
    Completer<void> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.updateProfileInfo,
      requestMethod: RequestMethod.post,
      requestData: data,
      onLoad: () {
        EasyLoading.show(status: "Updating profile...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete();
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'editProfile',
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
        Globals.reservedParkings = response.assignedAssignments;
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
      apiEndpoint: ApiFiles.bookingsList,
      requestMethod: RequestMethod.post,
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        try {
          // The response already contains the 'message' and 'data' fields
          BookingAdminResponse response = BookingAdminResponse.fromJson(res);
          completer.complete(response);
        } catch (e) {
          completer.completeError("Failed to parse response: ${e.toString()}");
        }
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
      final apiEndpoint;
      if (airport == 'Stansted' || airport == 'Luton' || airport == 'Bristol') {
        apiEndpoint = ApiFiles.searchParking;
      } else {
        apiEndpoint = ApiFiles.searchParking2;
      }
      print(apiEndpoint);

      server.makeApiRequest(
        apiEndpoint: apiEndpoint,
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
            status: "",
            maskType: EasyLoadingMaskType.black,
            indicator: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/load.gif',
                  width: 150.w,
                ),
                SizedBox(height: 12.h),
                Text(
                  "Finding Your Trusted CarParking",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  "Trusted by over 2 million satisfied customers",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  "Searching multiple providers for the best deals...",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        onSuccess: (Map<String, dynamic> response) {
          final status = response['status']?.toString().toLowerCase();
          final jobId = response['jobId']?.toString() ?? '';
          final message = response['message']?.toString().toLowerCase() ?? '';

          // If we have a jobId AND (it's a known background status OR the message indicates background processing)
          if (jobId.isNotEmpty &&
              (status == 'processing' ||
                  status == 'queued' ||
                  status == 'pending' ||
                  status == 'started' ||
                  message.contains('background') ||
                  message.contains('process'))) {
            print("Background search detected. JobId: $jobId");
            _pollSearchStatus(jobId, completer);
            return; // ✅ Ensure we return here to wait for polling
          }
          try {
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

            if (!completer.isCompleted) completer.complete(result);
          } catch (e) {
            EasyLoading.dismiss();

            if (!completer.isCompleted)
              completer.completeError('Failed to process parking options: $e');
          }
        },
        onError: (String errorMessage) {
          print("Initial search error: $errorMessage. Retrying...");
          // If it's the first attempt, we could retry once automatically
          // For now, let's just make it more resilient in polling
          EasyLoading.dismiss();

          final enhancedError = errorMessage.contains('timeout')
              ? 'Search is taking longer than expected. Please try again.'
              : errorMessage;

          if (!completer.isCompleted) completer.completeError(enhancedError);
        },
      );
    } catch (e) {
      print("Search exception: $e");
      EasyLoading.dismiss();
      if (!completer.isCompleted) completer.completeError(e.toString());
    }

    return completer.future;
  }

  void _pollSearchStatus(
      String jobId, Completer<SearchResultResponse> completer) {
    server.makeApiRequest(
      apiEndpoint: "${ApiFiles.searchStatus}/$jobId",
      requestMethod: RequestMethod.post,
      onLoad: () {
        // We can keep the loading status or update it
        // EasyLoading.show(
        //   status: "Processing search results...",
        //   maskType: EasyLoadingMaskType.black,
        // );
      },
      onSuccess: (Map<String, dynamic> response) {
        final status = response['status']?.toString().toLowerCase();
        final message = response['message']?.toString().toLowerCase() ?? '';

        // Check for progress percentage
        dynamic progressData = response['progress'] ?? response['percentage'];
        int percent = 0;
        if (progressData != null) {
          if (progressData is Map) {
            percent =
                int.tryParse(progressData['percent']?.toString() ?? '0') ?? 0;
          } else {
            percent = int.tryParse(progressData.toString()) ?? 0;
          }
        }

        if (status == 'processing' ||
            status == 'queued' ||
            status == 'pending' ||
            status == 'started' ||
            (percent > 0 && percent < 100) ||
            message.contains('background') ||
            message.contains('process')) {
          String statusText = percent > 0
              ? "Searching multiple providers for the best deals... $percent%"
              : "Searching multiple providers for the best deals...";

          EasyLoading.show(
            status: "",
            maskType: EasyLoadingMaskType.black,
            indicator: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/load.gif',
                  width: 100.w,
                ),
                SizedBox(height: 12.h),
                Text(
                  "Finding Your Trusted CarParking",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  "Trusted by over 2 million satisfied customers",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'Archivo',
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );

          // Poll again after 25 seconds
          Future.delayed(const Duration(seconds: 25), () {
            _pollSearchStatus(jobId, completer);
          });
        } else if (status == 'completed' ||
            status == 'success' ||
            percent == 100 ||
            response['data'] != null) {
          print("Polling: Search completed or 100%!");
          try {
            final result = SearchResultResponse.fromJson(response);
            if (result.data.isEmpty &&
                (status != 'completed' && percent < 100)) {
              // If data is empty but not officially complete, poll again just in case
              Future.delayed(const Duration(seconds: 10), () {
                _pollSearchStatus(jobId, completer);
              });
              return;
            }

            if (result.data.isEmpty) {
              EasyLoading.showInfo('No parking options available');
            } else {
              EasyLoading.dismiss();
            }
            if (!completer.isCompleted) completer.complete(result);
          } catch (e) {
            // If parsing fails but it's 100%, maybe data is coming late?
            if (percent == 100 || status == 'completed') {
              EasyLoading.dismiss();
              if (!completer.isCompleted)
                completer
                    .completeError('Failed to process parking options: $e');
            } else {
              // Retry polling if parsing fails but not yet 100%
              Future.delayed(const Duration(seconds: 10), () {
                _pollSearchStatus(jobId, completer);
              });
            }
          }
        } else {
          EasyLoading.dismiss();
          if (!completer.isCompleted)
            completer.completeError(
                response['message'] ?? 'Search failed or was cancelled');
        }
      },
      onError: (String errorMessage) {
        print("Polling error: $errorMessage. Retrying in 5 seconds...");
        // Keep the loader visible even on error
        EasyLoading.show(
          status: "",
          maskType: EasyLoadingMaskType.black,
          indicator: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/load.gif',
                width: 100.w,
              ),
              SizedBox(height: 12.h),
              Text(
                "Finding Your Trusted CarParking",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo',
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                "Trusted by over 2 million satisfied customers",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: 'Archivo',
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                "Waiting for results...",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: 'Archivo',
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        Future.delayed(const Duration(seconds: 5), () {
          _pollSearchStatus(jobId, completer);
        });
      },
    );
  }

  Future<Map<String, dynamic>> bookParking({
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    required String airport,
    required String outboundTerminal,
    required String inboundTerminal,
    required String outboundFlightNo,
    required String inboundFlightNo,
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
    required String vehicleRegistrationNo,
    required String vehicleManufacturer,
    required String vehicleYear,
    required String vehicleModel,
    required String vehicleColor,
    required String type,
    required String numberOfPassengers,
    required String userId,
    required String name,
    required String price,
    required String description,
    required List<String> bulletPoints,
    required String totalPayment,
    required String packageType,
    required String referenceNo,
    required String paymentMethod,
    required String paymentMethodDisplay,
    required String paymentStatus,
    required String paymentDate,
    required String transactionId,
  }) async {
    Completer<Map<String, dynamic>> completer = Completer();

    try {
      server.makeApiRequest(
        apiEndpoint: ApiFiles.bookParking,
        requestMethod: RequestMethod.post,
        requestData: {
          // Booking
          "startDate": startDate,
          "startTime": startTime,
          "endDate": endDate,
          "endTime": endTime,
          "airport": airport,

          // Flight
          "outboundTerminal": outboundTerminal,
          "inboundTerminal": inboundTerminal,
          "outboundFlightNo": outboundFlightNo,
          "inboundFlightNo": inboundFlightNo,

          // Customer
          "title": title,
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "phoneNo": phoneNo,

          // Vehicle
          "vehicleRegistrationNo": vehicleRegistrationNo,
          "vehicleManufacturer": vehicleManufacturer,
          "vehicleYear": vehicleYear,
          "vehicleModel": vehicleModel,
          "vehicleColor": vehicleColor,
          "type": type,
          "numberOfPassengers": numberOfPassengers,

          // Package
          "userId": userId,
          "name": name,
          "price": price,
          "description": description,
          "bulletPoints": bulletPoints,
          "totalPayment": totalPayment,
          "packageType": packageType,

          // Payment
          "referenceNo": referenceNo,
          "paymentMethod": paymentMethod,
          "paymentMethodDisplay": paymentMethodDisplay,
          "paymentStatus": paymentStatus,
          "paymentDate": paymentDate,
          "transactionId": transactionId,
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

            completer.complete(response);
          } catch (e) {
            EasyLoading.dismiss();

            completer.completeError('Error processing booking response: $e');
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          completer.completeError(errorMessage);
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      completer.completeError(e.toString());
    }

    return completer.future;
  }

  Future<Map<String, dynamic>> updateBooking({
    required String bookingId,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    required String paymentMethod,
    required String totalPayment,
    required String referenceNo,
  }) async {
    Completer<Map<String, dynamic>> completer = Completer();

    try {
      server.makeApiRequest(
        apiEndpoint: ApiFiles.updateBooking,
        requestMethod: RequestMethod.post,
        requestData: {
          "bookingId": bookingId,
          "startDate": startDate,
          "startTime": startTime,
          "endDate": endDate,
          "endTime": endTime,
          "paymentMethod": paymentMethod,
          "totalPayment": totalPayment,
          "referenceNo": referenceNo,
        },
        onLoad: () {
          EasyLoading.show(status: "Updating booking...");
        },
        onSuccess: (Map<String, dynamic> response) {
          EasyLoading.dismiss();
          try {
            completer.complete(response);
          } catch (e) {
            completer.completeError('Error processing update response: $e');
          }
        },
        onError: (String errorMessage) {
          EasyLoading.dismiss();
          completer.completeError(errorMessage);
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      completer.completeError(e.toString());
    }

    return completer.future;
  }

  Future<VehicleLookupResponse> lookupVehicle(String registrationNumber) async {
    Completer<VehicleLookupResponse> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.vehicleLookup,
      requestMethod: RequestMethod.post,
      requestData: {
        "registrationNumber": registrationNumber,
      },
      onLoad: () {
        EasyLoading.show(status: "Looking up vehicle...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        VehicleLookupResponse response = VehicleLookupResponse.fromJson(res);
        completer.complete(response);
      },
      onError: (String errorMessage) {
        print(errorMessage);
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  Future<CheckpointResponseModel> submitCheckpoint(
    BuildContext context,
    CheckpointRequestModel model,
    List<File>? pictures,
  ) async {
    Completer<CheckpointResponseModel> completer = Completer();

    try {
      EasyLoading.show(status: "Submitting checkpoint...");

      List<File> compressedPictures = [];

      if (pictures != null && pictures.isNotEmpty) {
        for (var file in pictures) {
          final targetPath = '${file.path}_compressed.jpg';

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,
          );

          if (compressedFile != null) {
            compressedPictures
                .add(File(compressedFile.path)); // ✅ convert XFile to File
          } else {
            compressedPictures.add(file); // fallback to original
          }
        }

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
          files: compressedPictures
              .map((file) => MultipartFileInfo(
                    file: file,
                    fieldName: "pictures",
                  ))
              .toList(),
          onSuccess: (Map<String, dynamic> response) {
            EasyLoading.dismiss();
            try {
              final checkpointResponse = CheckpointResponseModel.fromJson(
                  response['response'] ?? response);

              // Show success dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.all(24),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/success.svg',
                        height: 80,
                        width: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Success!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Booking has been successfully submitted.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(
                              context, MyRoutes.driverhome, (_) => false);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              );

              completer.complete(checkpointResponse);
            } catch (e) {
              completer.completeError("Parsing error: $e");
            }
          },
          onError: (String errorMessage) {
            EasyLoading.dismiss();
            completer.completeError("API Error: $errorMessage");
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one picture.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      completer.completeError("Exception: $e");
    }

    return completer.future;
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
      'http://test.thefutureinno.com/stripe/create-payment-intent',
    );

    final token = Globals.user?.token ?? '';

    // Convert amount to integer (smallest unit e.g. pence)
    final amountInt = int.tryParse(amount) ?? 0;
    if (amountInt <= 0) {
      throw Exception('Invalid amount: $amount');
    }

    try {
      // HttpClient to bypass SSL issue
      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.postUrl(url);
      request.headers.set('content-type', 'application/json');
      request.headers.set('access-token', token);

      final body = jsonEncode({
        "amount": amountInt, // e.g. 3869
        "currency": currency.toLowerCase(), // gbp
        "payment_method": "card",
        "test_mode": false,

        "startDate": startDate,
        "startTime": Globals.startTime,
        "endDate": endDate,
        "endTime": Globals.endTime,

        "airport": Globals.selectedAirport,
        "userId": Globals.user?.id,

        "customer": {
          "email": Globals.booking_info_model?.email,
          "name":
              "${Globals.booking_info_model?.firstName} ${Globals.booking_info_model?.lastName}"
        }
      });

      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to create payment intent: ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Payment Intent Error: $e');
    }
  }

  Future<String> postLocation(
      String bookingID, String latitude, String longitude) async {
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

  Future<String> assignDriver(String bookingID, String userId) async {
    Completer<String> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.assignDriver,
      requestMethod: RequestMethod.post,
      requestData: {
        "bookingId": bookingID,
        "userId": userId,
      },
      onLoad: () {
        EasyLoading.show(status: "Loading...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final message = res['message'] ?? ' Driver Assign successfully';
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

  Future<NotificationResponse> getNotifications() async {
    Completer<NotificationResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.getNotifications,
      requestMethod: RequestMethod.post,
      requestData: {
        "userId": Globals.user?.id ?? "",
      },
      onLoad: () {
        EasyLoading.show(status: "Loading notifications...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        try {
          final response = NotificationResponse.fromJson(res);
          completer.complete(response);
        } catch (e) {
          completer.completeError("Failed to parse notifications: $e");
        }
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<String> markNotificationsAsRead(List<String> notificationIds) async {
    Completer<String> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.markNotificationsAsRead,
      requestMethod: RequestMethod.post,
      requestData: {
        "notificationIds": notificationIds,
      },
      onLoad: () {
        EasyLoading.show(status: "Updating notifications...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final message = res['message'] ?? 'Notifications marked as read';
        completer.complete(message);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  Future<String> clearAllNotifications(List<String> notificationIds) async {
    Completer<String> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.clearAllNotifications,
      requestMethod: RequestMethod.post,
      requestData: {
        "notificationIds": notificationIds,
      },
      onLoad: () {
        EasyLoading.show(status: "Clearing notifications...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        final message = res['message'] ?? 'All notifications cleared';
        completer.complete(message);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }
}
