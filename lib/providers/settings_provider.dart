import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/setting.dart';

// 设置列表
final settingsProvider = FutureProvider<List<Setting>>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.settings);
  final list = response.data as List;
  return list.map((e) => Setting.fromJson(e)).toList();
});

// 设置操作
class SettingsActions {
  // 更新设置
  static Future<void> update(String key, String value) async {
    await DioClient.instance.put(ApiEndpoints.setting(key), data: {'value': value});
  }

  // 重置设置
  static Future<void> reset(String key) async {
    await DioClient.instance.post(ApiEndpoints.settingReset(key));
  }
}
