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
      final headers = {
        'access-token': Globals.user?.token ?? '',
      };

      if (requestMethod == RequestMethod.get) {
        response = await api.sendRequest.get(
          apiEndpoint,
          options: Options(headers: headers),
        );
      } else if (requestMethod == RequestMethod.post) {
        response = await api.sendRequest.post(
          apiEndpoint,
          data: requestData,
          options: Options(headers: headers),
        );
      }

      // Check if the 'title' field is present in the response
      if (response.data.containsKey('title')) {
        String errorMessage = response.data['message'];
        onError.call(errorMessage);
      } else {
        Map<String, dynamic> responseData = response.data;
        onSuccess.call(responseData);
      }
    } on DioException catch (e) {
      if (!offlineNotifier.getOfflineStatus()) {
        try {
          if (e.response?.statusCode == 404) {
            onError.call(e.message.toString());
          } else if (e.type == DioExceptionType.badResponse &&
              (e.response?.statusCode == 401 ||
                  e.response?.statusCode == 403)) {
            onError.call("Unauthorized: ${e.response!.data["message"]}");
          } else if (e.response != null) {
            Map<String, dynamic> errorData = e.response?.data["error"];
            String errorMessage = errorData["errorMessage"];
            onError.call(errorMessage);
          } else {
            onError.call(e.error.toString());
          }
        } catch (e) {
          onError.call('Something Went Wrong: ${e.toString()}');
        }
      } else {
        EasyLoading.dismiss();
      }
    } catch (e) {
      onError.call('Something Went Wrong: ${e.toString()}');
    }
  }
}

enum RequestMethod { get, post }
