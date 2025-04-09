import 'dart:async';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:parkingapp/data/api/api_files.dart';
import 'package:parkingapp/data/api/api_service.dart';
import 'package:parkingapp/data/models/BookingsListModeldart';
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
}
