import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'api_exception.dart';

// Dio HTTP 客户端封装
class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
    ));

    // 请求拦截器：自动带上 token 和 base url
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 每次请求都从 storage 读最新的 base url
        final baseUrl = LocalStorage.serverUrl;
        if (baseUrl.isNotEmpty) {
          options.baseUrl = baseUrl;
        }
        // 带上 token
        final token = LocalStorage.authToken;
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 的话清掉本地 token，触发跳登录页
        if (error.response?.statusCode == 401) {
          LocalStorage.clearAuth();
        }
        handler.next(error);
      },
    ));
  }

  // 单例
  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  // 暴露 dio 实例给需要的地方
  Dio get dio => _dio;

  // --- 封装常用方法，统一错误处理 ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
