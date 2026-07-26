import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/storage_helper.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  late final Dio _dio;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Interceptor — tambah token otomatis ke setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }
          return handler.next(options);
        },
        onError: (e, handler) => handler.next(e),
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (o) => print('[EduLiving] $o'),
    ));
  }

  // Expose dio untuk provider yang butuh akses langsung
  Dio get dio => _dio;

  // ── GET ──────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return _handle(res);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── POST ─────────────────────────────────────────────
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data, FormData? formData}) async {
    try {
      final res = await _dio.post(path, data: formData ?? data);
      return _handle(res);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── PUT (support FormData dengan _method spoofing untuk Laravel) ──
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    FormData? formData,
  }) async {
    try {
      if (formData != null) {
        formData.fields.add(const MapEntry('_method', 'PUT'));
        final res = await _dio.post(path, data: formData);
        return _handle(res);
      }
      final res = await _dio.put(path, data: data);
      return _handle(res);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── PATCH ────────────────────────────────────────────
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.patch(path, data: data);
      return _handle(res);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── PATCH ────────────────────────────────────────────
  // Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) async {
  //   try {
  //     final res = await _dio.patch(path, data: data);
  //     return _handle(res);
  //   } on DioException catch (e) {
  //     throw _error(e);
  //   }
  // }

  // ── DELETE ───────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      final res = await _dio.delete(path, data: data);
      return _handle(res);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  Map<String, dynamic> _handle(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  ApiException _error(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Koneksi timeout. Periksa internet Anda.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final body = e.response?.data;
        String msg = 'Terjadi kesalahan.';
        Map<String, dynamic>? errs;

        if (body is Map<String, dynamic> && body.containsKey('message')) {
          msg = body['message'].toString();
          errs = body['errors'] is Map<String, dynamic> ? body['errors'] : null;
        } else if (code == 401) {
          msg = 'Email/password salah atau sesi telah habis.';
        } else if (code == 403) {
          msg = 'Akses ditolak.';
        } else if (code == 404) {
          msg = 'Endpoint atau data tidak ditemukan (404).';
        } else if (code == 422) {
          msg = 'Data tidak valid.';
        } else if (code != null && code >= 500) {
          msg = 'Terjadi kesalahan pada server ($code).';
        }

        return ApiException(message: msg, statusCode: code, errors: errs);
      default:
        return ApiException(message: 'Terjadi kesalahan yang tidak diketahui.');
    }
  }
}
