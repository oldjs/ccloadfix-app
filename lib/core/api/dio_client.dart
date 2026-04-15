import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'api_exception.dart';

// Dio HTTP 客户端封装
class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._() {
    _dio = Dio(BaseOptions(
      // 移动网络下 10s 太紧了，适当放宽
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 15),
    ));

    // 请求拦截器：自动带上 token 和 base url
    // 响应拦截器：解包后端统一的 {success, data, error, count} 外壳
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 每次请求都从 storage 读最新的 base url，去尾部斜杠防止拼接重复
        final baseUrl = LocalStorage.serverUrl.replaceAll(RegExp(r'/+$'), '');
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
      onResponse: (response, handler) {
        final raw = response.data;
        // 后端所有响应都包在 APIResponse{success, data, error, count} 里，这里自动解包
        if (raw is Map<String, dynamic> && raw.containsKey('success')) {
          if (raw['success'] != true) {
            // HTTP 200 但业务层返回了错误（罕见，正常错误走 4xx/5xx）
            handler.reject(DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: raw['error'] ?? '请求失败',
            ));
            return;
          }
          // 解包：provider 直接拿到内层数据，不用再关心外壳
          response.data = raw['data'];
          // 分页 count 存到 extra，需要的 provider 自己取
          if (raw['count'] != null && raw['count'] is int) {
            response.extra = {'totalCount': raw['count']};
          }
        }
        handler.next(response);
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
