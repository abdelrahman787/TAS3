import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final Dio dio;

  ApiClient() : dio = Dio(BaseOptions(
          baseUrl: AppConstants.backendUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ));
}
