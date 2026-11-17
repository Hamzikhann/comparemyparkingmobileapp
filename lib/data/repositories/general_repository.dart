import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/config.dart';
import 'package:parkingapp/data/api/api_files.dart';
import 'package:parkingapp/services/push_token.dart';
import 'package:parkingapp/widgets/paged_list.dart';
import 'package:parkingapp/data/models/BookingsListModel.dart' as booking_list;
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
import 'package:parkingapp/data/models/PackageDetailModel.dart';
import 'package:parkingapp/data/airport_services.dart';
import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:parkingapp/data/models/UserUpdateModel.dart';
import 'package:parkingapp/data/models/VehicleLookupModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/data/models/DashboardDataModel.dart';
import 'package:parkingapp/data/models/AdminDashboardModel.dart';
import 'package:parkingapp/routes/MyRoutes.dart';

/// A payment that could not be started; [message] is safe to show to the customer.
class PaymentIntentException implements Exception {
  final String message;
  PaymentIntentException(this.message);
  @override
  String toString() => message;
}

class GeneralRepository {
  Timer? _searchTimer;
  // Use ValueNotifier to update UI without calling EasyLoading.show repeatedly
  final ValueNotifier<int> _searchProgressNotifier = ValueNotifier<int>(0);

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

  /// Checkout sign-up without a password (POST /api/auth/v1/signup), as on the website:
  /// creates a customer account, or logs in an existing customer with that email.
  /// That route accepts only these fields (no password, no fcmToken).
  Future<UserModel> signupGuest({
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNo,
  }) async {
    Completer<UserModel> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.guestSignup,
      requestMethod: RequestMethod.post,
      requestData: {
        "title": title,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNo": phoneNo,
      },
      onLoad: () {
        EasyLoading.show(status: "Saving your details...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        try {
          final data = res['data'];
          final userData =
              data is Map && data['user'] != null ? data['user'] : data;
          completer.complete(
              UserModel.fromJson({'user': userData, 'token': res['token']}));
        } catch (e) {
          completer.completeError('Could not read your account: $e');
        }
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
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
        print(errorMessage);

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
        print(errorMessage);
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
      // Admins: the list is paged, ask for the newest 500. Customers and
      // employees get their own full list and must not be sent paging fields.
      requestData: Globals.roleTitle == "Administrator"
          ? const {"limit": 500, "offset": 0}
          : null,
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

  /// [showLoader] false when the screen shows its own spinner.
  Future<BookingDriverResponse> getBookingsForDriver(
      {bool showLoader = true}) async {
    Completer<BookingDriverResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint:
          ApiFiles.bookingsList, // Make sure you have this endpoint defined
      requestMethod: RequestMethod.post,
      onLoad: () {
        if (showLoader) EasyLoading.show(status: "Loading...");
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
      // Admin list is paged on the backend: take the newest 500 (its maximum)
      requestData: const {"limit": 500, "offset": 0},
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
    String? promoCode,
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
      final apiEndpoint = ApiFiles.searchParking;
      // Same-day searches ask the API for the next day, as the website does
      final apiDates = searchApiDates(startDate, endDate);

      Map<String, dynamic> requestData = {
        "startDate": apiDates.startDate,
        "endDate": apiDates.endDate,
        "airport": airport,
        "startTime": startTime,
        "endTime": endTime,
      };

      if (promoCode != null && promoCode.isNotEmpty) {
        requestData["promoCode"] = promoCode;
      }

      server.makeApiRequest(
        apiEndpoint: apiEndpoint,
        requestMethod: RequestMethod.post,
        requestData: requestData,
        onLoad: () {
          // Initialize loader settings
          EasyLoading.instance.dismissOnTap = false;
          _searchTimer?.cancel();
          _searchProgressNotifier.value = 10;

          // Show loader ONCE with the notifier widget
          EasyLoading.show(
            status: "",
            maskType: EasyLoadingMaskType.black,
            indicator:
                _SearchLoaderWidget(progressNotifier: _searchProgressNotifier),
          );

          // Start dummy progress timer
          _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            int current = _searchProgressNotifier.value;
            current += (Random().nextInt(2) + 2); // Increment by 2 or 3
            if (current > 90) current = 90; // Cap at 90 until done
            _searchProgressNotifier.value = current;
          });
        },
        // v5 always answers with the results (no background job any more)
        onSuccess: (Map<String, dynamic> response) {
          try {
            if (response['data'] is! List) {
              throw Exception(response['message']?.toString() ??
                  'Invalid search response');
            }
            _finalizeSearch(completer, SearchResultResponse.fromJson(response));
          } catch (e) {
            _handleSearchError(completer, e.toString());
          }
        },
        onError: (String errorMessage) {
          _handleSearchError(completer, errorMessage);
        },
      );
    } catch (e) {
      print("Search exception: $e");
      _handleSearchError(completer, e.toString());
    }

    return completer.future;
  }

  void _finalizeSearch(
      Completer<SearchResultResponse> completer, SearchResultResponse result) {
    _searchTimer?.cancel();
    _searchProgressNotifier.value = 100;

    // Show 100% for a brief moment
    Future.delayed(const Duration(milliseconds: 500), () {
      EasyLoading.dismiss();
      EasyLoading.instance.dismissOnTap = true; // Reset

      if (result.data.isEmpty) {
        // The server says why when it knows (e.g. "This airport is not available")
        EasyLoading.showInfo(result.note?.isNotEmpty == true
            ? result.note!
            : 'No parking options available');
      }

      if (!completer.isCompleted) completer.complete(result);
    });
  }

  /// GET /api/site-config: airport list + marketing switches. Never throws; falls back
  /// to the built-in active airports when the server can't be reached.
  Future<SiteConfig> getSiteConfig() async {
    final completer = Completer<SiteConfig>();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.siteConfig,
      requestMethod: RequestMethod.get,
      onLoad: () {},
      onSuccess: (res) => completer.complete(SiteConfig.fromJson(res)),
      onError: (_) => completer.complete(SiteConfig.defaults),
    );
    return completer.future;
  }

  /// GET /api/search/v5/package/:packageId: full content of one searched package.
  /// Also remembers the airport service info for the booking screens.
  Future<PackageDetail> getPackageDetails(String packageId) async {
    final completer = Completer<PackageDetail>();
    server.makeApiRequest(
      apiEndpoint:
          '${ApiFiles.packageDetails}/${Uri.encodeComponent(packageId)}',
      requestMethod: RequestMethod.get,
      onLoad: () {},
      onSuccess: (res) {
        try {
          final detail = PackageDetail.fromJson(res);
          AirportServices.remember(detail);
          completer.complete(detail);
        } catch (e) {
          completer.completeError(e.toString());
        }
      },
      onError: (msg) => completer.completeError(msg),
    );
    return completer.future;
  }

  void _handleSearchError(
      Completer<SearchResultResponse> completer, String error) {
    _searchTimer?.cancel();
    EasyLoading.dismiss();
    EasyLoading.instance.dismissOnTap = true;
    if (!completer.isCompleted) completer.completeError(error);
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
    String? brandName,
    String? tierKey,
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
          // Our brand and tier (live airports), for brand-specific email content
          if (brandName != null && brandName.isNotEmpty) "brandName": brandName,
          if (tierKey != null && tierKey.isNotEmpty) "tierKey": tierKey,

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

  /// The server charges the price of [packageId] from its own search results; [amount]
  /// (pounds, e.g. 38.69) is only compared with it, as on the website.
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String packageId,
    required String currency,
    required String startDate,
    required String endDate,
    String paymentMethodType = 'card',
  }) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/stripe/create-payment-intent',
    );

    final token = Globals.user?.token ?? '';

    if (packageId.isEmpty) {
      throw PaymentIntentException(
          'Your search has expired. Please search again.');
    }
    if (amount <= 0) {
      throw PaymentIntentException('This parking is not available to book.');
    }

    try {
      // HttpClient to bypass SSL issue
      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.postUrl(url);
      request.headers.set('content-type', 'application/json');
      request.headers.set('access-token', token);

      final body = jsonEncode(paymentIntentPayload(
        packageId: packageId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethodType,
        startDate: startDate,
        startTime: Globals.startTime,
        endDate: endDate,
        endTime: Globals.endTime,
        airport: Globals.selectedAirport,
        userId: Globals.user?.id,
        email: Globals.booking_info_model?.email,
        firstName: Globals.booking_info_model?.firstName,
        lastName: Globals.booking_info_model?.lastName,
      ));

      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      // Show the server's reason, e.g. "Your search has expired. Please search again..."
      String message = 'Could not start the payment (${response.statusCode}).';
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw PaymentIntentException(message);
    } on PaymentIntentException {
      rethrow;
    } catch (e) {
      throw PaymentIntentException('Could not start the payment: $e');
    }
  }

  /// Stripe payment for changing an existing booking's dates. The server works out
  /// the amount (change fee + extra days, set per airport) and returns it in
  /// `data.amount`; /booking/update then checks this payment with Stripe.
  Future<Map<String, dynamic>> createBookingChangePaymentIntent({
    required String bookingId,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.bookingChangePaymentIntent,
      requestMethod: RequestMethod.post,
      requestData: {
        "bookingId": bookingId,
        "startDate": startDate,
        "startTime": startTime,
        "endDate": endDate,
        "endTime": endTime,
      },
      onLoad: () => EasyLoading.show(status: "Preparing payment..."),
      onSuccess: (Map<String, dynamic> response) {
        EasyLoading.dismiss();
        if (!completer.isCompleted) completer.complete(response);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        if (!completer.isCompleted) {
          completer.completeError(PaymentIntentException(errorMessage));
        }
      },
    );
    return completer.future;
  }

  Future<Map<String, dynamic>> verifyPayment(String paymentIntentId) async {
    Completer<Map<String, dynamic>> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.verifyPayment,
      requestMethod: RequestMethod.post,
      requestData: {
        "paymentIntentId": paymentIntentId,
      },
      onLoad: () {
        EasyLoading.show(status: "Verifying payment...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete(res);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
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

  /// Simple POST returning the server's message. Errors complete with the
  /// server message (callers show it).
  Future<String> _postForMessage(String endpoint, Map<String, dynamic> data,
      {String loading = "Please wait...", bool silent = false}) {
    final completer = Completer<String>();
    server.makeApiRequest(
      apiEndpoint: endpoint,
      requestMethod: RequestMethod.post,
      requestData: data,
      onLoad: () {
        if (!silent) EasyLoading.show(status: loading);
      },
      onSuccess: (Map<String, dynamic> res) {
        if (!silent) EasyLoading.dismiss();
        completer.complete((res['message'] ?? 'Done').toString());
      },
      onError: (String errorMessage) {
        if (!silent) EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  /// Clears this phone's push token on the server (no more pushes after logout).
  /// Sends the token so the server only clears it if it is still this phone's.
  Future<String> logoutOnServer() async {
    final token = await PushToken.current();
    return _postForMessage(
        ApiFiles.logout, {if (token != null) "fcmToken": token},
        silent: true);
  }

  /// POST without the spinner/alert handling; completes with the full reply or
  /// fails with the server's message (the reset screen shows it).
  Future<Map<String, dynamic>> _postQuiet(
      String endpoint, Map<String, dynamic> data) {
    final completer = Completer<Map<String, dynamic>>();
    server.makeApiRequest(
      apiEndpoint: endpoint,
      requestMethod: RequestMethod.post,
      requestData: data,
      onLoad: () {},
      onSuccess: (Map<String, dynamic> res) => completer.complete(res),
      onError: (String errorMessage) => completer.completeError(errorMessage),
    );
    // Offline: the API service reports nothing, so don't wait forever
    return completer.future.timeout(const Duration(seconds: 30),
        onTimeout: () =>
            throw 'No connection. Please check your internet and try again.');
  }

  // ---------- Admin paged lists ----------

  Map<String, dynamic> _pageBody(int offset, int limit,
      [Map<String, dynamic> extra = const {}]) {
    final body = <String, dynamic>{"limit": limit, "offset": offset};
    extra.forEach((k, v) {
      if (v != null && v.toString().trim().isNotEmpty) body[k] = v;
    });
    return body;
  }

  PageResult<T> _toPage<T>(
      Map<String, dynamic> res, T Function(Map<String, dynamic>) parse) {
    final data = res['data'];
    final rows = (data is Map && data['rows'] is List)
        ? data['rows'] as List
        : const [];
    final items =
        rows.map((e) => parse(Map<String, dynamic>.from(e as Map))).toList();
    final total = (data is Map && data['total'] is num)
        ? (data['total'] as num).toInt()
        : items.length;
    return PageResult<T>(items, total);
  }

  /// Bookings, newest first. [status]: e.g. "Pending", "Inprogress", "Completed".
  /// [filters]: the website's filters (referenceNo, firstName, lastName, email,
  /// phone, vehicleReg, startDate, endDate, month, year, airport, company,
  /// createdFrom, createdTo). Empty values are left out.
  Future<PageResult<booking_list.Parking>> adminBookingsPage(
      int offset, int limit,
      {String? search,
      String? status,
      Map<String, dynamic> filters = const {}}) async {
    final res = await _postQuiet(
        ApiFiles.bookingsList,
        _pageBody(
            offset, limit, {"search": search, "status": status, ...filters}));
    return _toPage(res, booking_list.Parking.fromJson);
  }

  /// Company (package) names for the bookings filter.
  Future<List<String>> adminBookingCompanies() async {
    final res = await _postQuiet(ApiFiles.bookingsList,
        {"limit": 1, "offset": 0, "includeFilterOptions": true});
    final data = res['data'];
    final opts = data is Map ? data['filterOptions'] : null;
    final list = opts is Map ? opts['companies'] : null;
    return list is List ? list.map((e) => '$e').toList() : <String>[];
  }

  /// Payments, newest first, with their booking and customer.
  Future<PageResult<Map<String, dynamic>>> adminPaymentsPage(
      int offset, int limit,
      {String? search, String? startDate, String? endDate}) async {
    final res = await _postQuiet(
        ApiFiles.adminPaymentsList,
        _pageBody(offset, limit,
            {"search": search, "startDate": startDate, "endDate": endDate}));
    return _toPage(res, (m) => m);
  }

  /// Users, newest first. [role]: "User", "GuestUser", "Employee", "Administrator".
  Future<PageResult<Map<String, dynamic>>> adminUsersPage(int offset, int limit,
      {String? search, String? role}) async {
    final res = await _postQuiet(ApiFiles.adminUsersList,
        _pageBody(offset, limit, {"search": search, "role": role}));
    return _toPage(res, (m) => m);
  }

  // ---------- Admin actions (same endpoints as the website admin) ----------

  /// Full booking: registrations, vehicles, package, driver assignment.
  Future<Map<String, dynamic>> adminBookingDetail(String bookingId) async {
    final res =
        await _postQuiet(ApiFiles.bookingDetail, {"bookingId": bookingId});
    final data = res['data'];
    if (data is! Map) throw 'Booking not found';
    return Map<String, dynamic>.from(data);
  }

  /// Edit a booking: dates/times, airport, status, customer, flights, vehicle.
  Future<void> adminUpdateBooking(Map<String, dynamic> data) async {
    await _postQuiet(ApiFiles.adminBookingUpdate, data);
  }

  /// Re-send the booking confirmation email. [email] empty = customer's own.
  Future<void> adminSendBookingEmail(String bookingId, {String email = ''}) async {
    final res = await _postQuiet(
        ApiFiles.adminBookingEmail, {"id": bookingId, "useremail": email});
    if (res['success'] == false) {
      throw '${res['error'] ?? res['message'] ?? 'Email not sent'}';
    }
  }

  /// Create an employee (driver) account. Returns the server message.
  Future<void> adminCreateEmployee(Map<String, dynamic> data) async {
    await _postQuiet(ApiFiles.adminUserCreate, {...data, "roleTitle": "Employee"});
  }

  /// Change a user's title, name and phone.
  Future<void> adminUpdateUser(Map<String, dynamic> data) async {
    await _postQuiet(ApiFiles.adminUserUpdate, data);
  }

  /// Deactivate an employee: logged out, upcoming jobs released.
  Future<String> adminDeactivateEmployee(String userId) async {
    final res =
        await _postQuiet(ApiFiles.adminUserDeactivate, {"userId": userId});
    return '${res['message'] ?? 'Employee deactivated'}';
  }

  /// Forgot password (app): emails a 6-digit code. Returns the server message.
  Future<String> sendPasswordResetCode(String email) async {
    final res = await _postQuiet(ApiFiles.resetCodeSend, {"email": email});
    return (res['message'] ?? 'Code sent').toString();
  }

  /// Checks the emailed code; returns a short-lived reset token.
  Future<String> verifyPasswordResetCode(String email, String otp) async {
    final res = await _postQuiet(
        ApiFiles.resetCodeVerify, {"email": email, "otp": otp});
    final token = res['data']?['resetToken']?.toString() ?? '';
    if (token.isEmpty) throw 'Something went wrong. Please try again.';
    return token;
  }

  /// Saves the new password and returns the logged-in user (as login does).
  Future<UserModel> resetPasswordWithCode(
      String resetToken, String password) async {
    final res = await _postQuiet(ApiFiles.resetCodeNewPassword, {
      "resetToken": resetToken,
      "password": password,
      "confirmPassword": password,
    });
    final user =
        UserModel.fromJson({'user': res['data']['user'], 'token': res['token']});
    await SharedStorage.saveUser(user);
    return user;
  }

  /// Saves this phone's push token for the logged-in user.
  Future<String> saveFcmToken(String token) =>
      _postForMessage(ApiFiles.saveFcmToken, {"fcmToken": token}, silent: true);

  Future<String> changePassword(
          String oldPassword, String password, String confirmation) =>
      _postForMessage(
          ApiFiles.changePassword,
          {
            "oldPassword": oldPassword,
            "password": password,
            "passwordConfirmation": confirmation,
          },
          loading: "Updating password...");

  /// Admin: deactivate an employee (releases their not-started jobs).
  Future<String> deactivateEmployee(String userId) => _postForMessage(
      ApiFiles.deactivateEmployee, {"userId": userId},
      loading: "Deactivating...");

  /// Admin: move an assignment to another employee.
  Future<String> reassignDriver(String assignmentId, String newEmployeeId) =>
      _postForMessage(ApiFiles.reassignDriver,
          {"assignmentId": assignmentId, "newEmployeeId": newEmployeeId},
          loading: "Reassigning...");

  /// [silent]: no loading spinner (used for the unread badge).
  Future<NotificationResponse> getNotifications({bool silent = false}) async {
    Completer<NotificationResponse> completer = Completer();

    server.makeApiRequest(
      apiEndpoint: ApiFiles.getNotifications,
      requestMethod: RequestMethod.post,
      requestData: {
        "userId": Globals.user?.id ?? "",
      },
      onLoad: () {
        if (!silent) EasyLoading.show(status: "Loading notifications...");
      },
      onSuccess: (Map<String, dynamic> res) {
        if (!silent) EasyLoading.dismiss();
        try {
          final response = NotificationResponse.fromJson(res);
          completer.complete(response);
        } catch (e) {
          completer.completeError("Failed to parse notifications: $e");
        }
      },
      onError: (String errorMessage) {
        if (!silent) EasyLoading.dismiss();
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

  Future<DashboardDataResponse> getDashboardData(String filter) async {
    Completer<DashboardDataResponse> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: "${ApiFiles.dashboardData}?filter=$filter",
      requestMethod: RequestMethod.get,
      onLoad: () {
        EasyLoading.show(status: "Loading dashboard data...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete(DashboardDataResponse.fromJson(res));
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  Future<AdminDashboardResponse> getMainDashboardData() async {
    Completer<AdminDashboardResponse> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.mainDashboardData,
      requestMethod: RequestMethod.post,
      onLoad: () {}, // Handled by AdminHome locally
      onSuccess: (Map<String, dynamic> res) {
        completer.complete(AdminDashboardResponse.fromJson(res));
      },
      onError: (String errorMessage) {
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  Future<Map<String, dynamic>> searchByRegistration(
      String registration, String airport) async {
    Completer<Map<String, dynamic>> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.searchByRegistration,
      requestMethod: RequestMethod.post,
      requestData: {
        "registration": registration,
        "airport": airport,
      },
      onLoad: () {
        EasyLoading.show(status: "Searching...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete(res);
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'search_reg',
          message: errorMessage,
          duration: 3,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }

  Future<void> claimBooking({
    required String registration,
    required String airport,
    required String bookingReference,
  }) async {
    Completer<void> completer = Completer();
    server.makeApiRequest(
      apiEndpoint: ApiFiles.claimBooking,
      requestMethod: RequestMethod.post,
      requestData: {
        "registration": registration,
        "airport": airport,
        "booking_reference": bookingReference,
      },
      onLoad: () {
        EasyLoading.show(status: "Claiming...");
      },
      onSuccess: (Map<String, dynamic> res) {
        EasyLoading.dismiss();
        completer.complete();
      },
      onError: (String errorMessage) {
        EasyLoading.dismiss();
        Alertify.showAlert(
          alertKey: 'claim_booking',
          message: errorMessage,
          duration: 3,
          type: AlertType.error,
        );
        completer.completeError(errorMessage);
      },
    );
    return completer.future;
  }
}

class _SearchLoaderWidget extends StatelessWidget {
  final ValueNotifier<int> progressNotifier;

  const _SearchLoaderWidget({Key? key, required this.progressNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: progressNotifier,
        builder: (context, percent, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$percent%",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo',
                  color: colors.primaryNew,
                ),
              ),
              SizedBox(height: 20.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150.w,
                    height: 150.w,
                    child: CircularProgressIndicator(
                      value: percent / 100.0,
                      strokeWidth: 6.w,
                      color: colors.primaryNew,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  Container(
                    width: 110.w, // Ensure it fits inside the ring
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/load.gif',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
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
          );
        },
      ),
    );
  }
}
