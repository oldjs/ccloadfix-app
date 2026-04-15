import 'package:shared_preferences/shared_preferences.dart';

// 本地持久化存储，封装 SharedPreferences
class LocalStorage {
  static SharedPreferences? _prefs;

  // 初始化，app 启动时调一次
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- 服务器地址 ---
  static String get serverUrl => _prefs?.getString('server_url') ?? '';
  static Future<void> setServerUrl(String url) async {
    await _prefs?.setString('server_url', url);
  }

  // --- 登录 token ---
  static String get authToken => _prefs?.getString('auth_token') ?? '';
  static Future<void> setAuthToken(String token) async {
    await _prefs?.setString('auth_token', token);
  }

  // --- 主题模式: system / light / dark ---
  static String get themeMode => _prefs?.getString('theme_mode') ?? 'system';
  static Future<void> setThemeMode(String mode) async {
    await _prefs?.setString('theme_mode', mode);
  }

  // 清除登录态
  static Future<void> clearAuth() async {
    await _prefs?.remove('auth_token');
  }

  // 清除所有数据
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
