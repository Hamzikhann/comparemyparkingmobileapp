import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:parkingapp/data/api/config.dart';

class API {
  final Dio _dio = Dio();
  final String env = 'dev';
  final bool logger = false;
  API() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    if (logger) _dio.interceptors.add(PrettyDioLogger());
  }

  Dio get sendRequest => _dio;
}
