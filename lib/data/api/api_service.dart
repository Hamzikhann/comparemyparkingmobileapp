import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/api.dart';
import 'package:dio/dio.dart';
import 'package:parkingapp/providers/OfflineNotifier.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class APIService {
  final API api = API();

  Future<void> makeApiRequest({
    required String apiEndpoint,
    required RequestMethod requestMethod,
    Map<String, dynamic>? requestData,
    required void Function() onLoad,
    required void Function(Map<String, dynamic> res) onSuccess,
    required void Function(String errorMessage) onError,
  }) async {
    try {
      onLoad.call(); // Call onLoad callback if provided

      late Response response;
      if (requestMethod == RequestMethod.get) {
        response = await api.sendRequest.get(
          apiEndpoint,
          options: Options(headers: {
            'authorization': 'Bearer ${Globals.user?.token ?? ''}'
          }), // Add token to headers
        );
      } else if (requestMethod == RequestMethod.post) {
        response = await api.sendRequest.post(
          apiEndpoint,
          data: requestData,
          options: Options(headers: {
            'authorization': 'Bearer ${Globals.user?.token ?? ''}'
          }), // Add token to headers
        );
      }

      // Check if the 'title' field is present in the response
      if (response.data.containsKey('title')) {
        // If 'title' exists, treat it as an error response
        String errorMessage = response.data['message'];
        onError.call(errorMessage); // Call onError callback
      } else {
        // If 'title' doesn't exist, treat it as a success response
        Map<String, dynamic> responseData = response.data;
        onSuccess.call(responseData); // Pass data to onSuccess callback
      }
    } on DioException catch (e) {
      if (!offlineNotifier.getOfflineStatus()) {
        try {
          if (e.response?.statusCode == 404) {
            onError.call(e.message.toString()); // Call onError callback
          } else if (e.type == DioExceptionType.badResponse &&
              (e.response?.statusCode == 401 ||
                  e.response?.statusCode == 403)) {
            onError.call("Unauthorized: ${e.response!.data["message"]}");
          } else if (e.response != null) {
            Map<String, dynamic> errorData = e.response?.data["error"];
            String errorMessage = errorData["errorMessage"];
            onError.call(errorMessage); // Call onError callback
          } else {
            onError.call(e.error.toString()); // Call onError callback
          }
        } catch (e) {
          onError.call(
              'Something Went Wrong: ${e.toString()}'); // Call onError callback
        }
      } else {
        EasyLoading.dismiss();
      }
    } catch (e) {
      onError.call(
          'Something Went Wrong: ${e.toString()}'); // Call onError callback
    }
  }
}

enum RequestMethod { get, post }
