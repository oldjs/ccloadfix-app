import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';

// 登录状态枚举
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, bool? isLoading, String? error}) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 启动时检查本地 token
    final token = LocalStorage.authToken;
    final serverUrl = LocalStorage.serverUrl;
    if (token.isNotEmpty && serverUrl.isNotEmpty) {
      return const AuthState(status: AuthStatus.authenticated);
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  // 登录
  Future<bool> login(String serverUrl, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 先存 server url，dio 拦截器会用
      await LocalStorage.setServerUrl(serverUrl.trimRight());

      final response = await DioClient.instance.post(
        ApiEndpoints.login,
        data: {'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;

      // 存 token
      await LocalStorage.setAuthToken(token);
      state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '登录失败: $e');
      return false;
    }
  }

  // 登出
  Future<void> logout() async {
    try {
      await DioClient.instance.post(ApiEndpoints.logout);
    } catch (_) {
      // 登出失败也无所谓，本地清掉就行
    }
    await LocalStorage.clearAuth();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 全局 provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
