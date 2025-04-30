import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/api/api.dart';
import 'package:parkingapp/providers/OfflineNotifier.dart';

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
      onLoad.call();
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

      if (response.data.containsKey('title')) {
        onError.call(response.data['message']);
      } else {
        onSuccess.call(response.data);
      }
    } on DioException catch (e) {
      _handleError(e, onError);
    } catch (e) {
      onError.call('Something Went Wrong: ${e.toString()}');
    }
  }

  /// 📷 Multipart Upload Request
  Future<void> makeMultipartRequest({
  required String apiEndpoint,
  required RequestMethod requestMethod,
  required Map<String, String> fields,
  required List<MultipartFileInfo> files,
  required void Function(Map<String, dynamic> res) onSuccess,
  required void Function(String errorMessage) onError,
}) async {
  try {
    final headers = {
      'access-token': Globals.user?.token ?? '',
      // ❌ Don't set Content-Type manually — Dio sets it for multipart!
    };

    // 🔧 Step 1: Build a map of fieldName => List<MultipartFile>
    final Map<String, List<MultipartFile>> fileMap = {};

    for (final fileInfo in files) {
      final multipartFile = await MultipartFile.fromFile(
        fileInfo.file.path,
        filename: fileInfo.file.path.split('/').last,
      );

      fileMap.putIfAbsent(fileInfo.fieldName, () => []).add(multipartFile);
    }

    // 🔧 Step 2: Merge fields and files
    final formData = FormData.fromMap({
      ...fields,
      ...fileMap,
    });


    final response = await api.sendRequest.post(
      apiEndpoint,
      data: formData,
      options: Options(headers: headers),
    );

    if (response.data.containsKey('title')) {
      onError.call(response.data['message']);
    } else {
      onSuccess.call(response.data);
    }
  } on DioException catch (e) {
    _handleError(e, onError);
  } catch (e) {
    onError.call('Something Went Wrong: ${e.toString()}');
  }
}



  void _handleError(DioException e, void Function(String) onError) {
    if (!offlineNotifier.getOfflineStatus()) {
      try {
        if (e.response?.statusCode == 404) {
          onError.call(e.message.toString());
        } else if (e.type == DioExceptionType.badResponse &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          onError.call("Unauthorized: ${e.response?.data["message"]}");
        } else if (e.response != null &&
            e.response?.data is Map &&
            e.response?.data["error"] is Map) {
          String errorMessage = e.response?.data["error"]["errorMessage"];
          onError.call(errorMessage);
        } else {
          onError.call(e.message ?? e.toString());
        }
      } catch (e) {
        onError.call('Something Went Wrong: ${e.toString()}');
      }
    } else {
      EasyLoading.dismiss();
    }
  }
}

enum RequestMethod { get, post }

/// 📦 Helper for file uploads
class MultipartFileInfo {
  final File file;
  final String fieldName;

  MultipartFileInfo({
    required this.file,
    required this.fieldName,
  });
}
