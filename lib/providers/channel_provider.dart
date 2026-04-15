import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/channel.dart';

// 渠道列表
final channelListProvider = FutureProvider<List<Channel>>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.channels);
  final list = response.data as List;
  return list.map((e) => Channel.fromJson(e)).toList();
});

// 单个渠道详情
final channelDetailProvider = FutureProvider.family<Channel, int>((ref, id) async {
  final response = await DioClient.instance.get(ApiEndpoints.channel(id));
  return Channel.fromJson(response.data);
});

// 渠道操作
class ChannelActions {
  // 切换启用/禁用
  static Future<void> toggleEnabled(int id, bool enabled) async {
    await DioClient.instance.put(
      ApiEndpoints.channel(id),
      data: {'enabled': enabled},
    );
  }

  // 批量更新优先级
  static Future<void> batchUpdatePriority(List<Map<String, dynamic>> updates) async {
    await DioClient.instance.post(
      ApiEndpoints.channelsBatchPriority,
      data: {'updates': updates},
    );
  }

  // 批量启用/禁用
  static Future<void> batchToggleEnabled(List<int> channelIds, bool enabled) async {
    await DioClient.instance.post(
      ApiEndpoints.channelsBatchEnabled,
      data: {'channel_ids': channelIds, 'enabled': enabled},
    );
  }

  // 设置冷却
  static Future<void> setCooldown(int id, int durationMs) async {
    await DioClient.instance.post(
      ApiEndpoints.channelCooldown(id),
      data: {'duration_ms': durationMs},
    );
  }

  // 清除冷却
  static Future<void> clearCooldown(int id) async {
    await DioClient.instance.delete(ApiEndpoints.channelCooldown(id));
  }

  // 测试渠道
  static Future<ChannelTestResult> testChannel(int id, {String? model, int? keyIndex}) async {
    final data = <String, dynamic>{};
    if (model != null) data['model'] = model;
    if (keyIndex != null) data['key_index'] = keyIndex;

    final response = await DioClient.instance.post(
      ApiEndpoints.channelTest(id),
      data: data,
    );
    return ChannelTestResult.fromJson(response.data);
  }

  // 更新优先级
  static Future<void> updatePriority(int id, int priority) async {
    await DioClient.instance.put(
      ApiEndpoints.channel(id),
      data: {'priority': priority},
    );
  }
}
