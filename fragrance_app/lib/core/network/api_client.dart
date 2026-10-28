import 'dart:async';

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

    final status = response?.statusCode;

    // The saved sign-in is no longer accepted (expired, or the database was
    // set up again): forget it, so the app asks the customer to sign in again.
    if (status == 401 && AuthPreferences.token != null) {
      unawaited(AuthPreferences.clear());
      return const ApiException(
        status: 401,
        error: 'UnauthorizedError',
        message: 'Your sign-in has expired. Please sign in again.',
      );
    }

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      // "message" is the readable sentence; "error" is a short code.
      return ApiException(
        status: data['status'] as int? ?? status ?? 500,
        error: data['error'] as String? ?? 'ApiError',
        message: data['message'] as String? ?? 'Something went wrong.',
      );
    }

    return ApiException(
      status: response?.statusCode ?? 500,
      message: error.message ?? 'Something went wrong.',
      error: error.type.name,
    );
  }
}
