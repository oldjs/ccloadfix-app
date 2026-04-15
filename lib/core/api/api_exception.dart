import 'package:dio/dio.dart';

// 统一 API 异常，把 Dio 的各种错误转成人话
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  // 从 DioException 转换
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('连接超时，请检查网络', statusCode: null);

      case DioExceptionType.connectionError:
        return ApiException('无法连接服务器，请检查地址是否正确', statusCode: null);

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        // 尝试从响应体拿错误信息
        String msg = '请求失败';
        if (data is Map) {
          msg = data['error']?.toString() ?? data['message']?.toString() ?? msg;
        }

        // 常见状态码的友好提示
        switch (statusCode) {
          case 401:
            msg = '认证失败，请重新登录';
          case 403:
            msg = '没有权限执行此操作';
          case 404:
            msg = '请求的资源不存在';
          case 500:
            msg = '服务器内部错误: $msg';
          case 503:
            msg = '服务暂时不可用';
        }
        return ApiException(msg, statusCode: statusCode);

      case DioExceptionType.cancel:
        return ApiException('请求已取消');

      default:
        return ApiException('网络错误: ${e.message}');
    }
  }

  @override
  String toString() => message;
}
