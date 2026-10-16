import 'package:dio/dio.dart';

import '../core.dart';

final class ApiClient {
  final Dio _dio;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  Future<Response<Map<String, dynamic>>> get({
    required String path,
    Map<String, dynamic>? queryParamters,
  }) async {
    try {
      return await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParamters,
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Response<dynamic>> getDynamic({
    required String path,
    Map<String, dynamic>? queryParamters,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: queryParamters,
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Response<Map<String, dynamic>>> post({
    required String path,
    Object? data,
  }) async {
    try {
      return await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  /// Send files (multipart/form-data), e.g. a profile photo.
  Future<Response<Map<String, dynamic>>> postForm({
    required String path,
    required FormData data,
  }) async {
    try {
      return await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(
          headers: _authHeaders,
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Map<String, String> get _authHeaders {
    final token = AuthPreferences.token;

    if (token == null) return {};

    return {'Authorization': 'Bearer $token'};
  }

  ApiException _handleDioException(DioException error) {
    final response = error.response;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      return ApiException(
        status: data['status'] as int? ?? response.statusCode ?? 500,
        error: data['message'] as String? ?? 'Something went wrong.',
        message: data['error'] as String? ?? 'ApiError',
      );
    }

    return ApiException(
      status: response?.statusCode ?? 500,
      message: error.message ?? 'Something went wrong.',
      error: error.type.name,
    );
  }
}
