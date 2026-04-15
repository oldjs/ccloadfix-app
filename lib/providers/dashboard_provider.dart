import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/summary.dart';

// 仪表盘摘要
final summaryProvider = FutureProvider.family<Summary, String>((ref, range) async {
  final response = await DioClient.instance.get(
    ApiEndpoints.publicSummary,
    queryParameters: {'range': range},
  );
  return Summary.fromJson(response.data);
});

// 活跃请求（解包后 response.data 直接就是列表）
final activeRequestsProvider = FutureProvider<List<ActiveRequest>>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.activeRequests);
  final list = (response.data as List?) ?? [];
  return list.map((e) => ActiveRequest.fromJson(e as Map<String, dynamic>)).toList();
});

// 版本信息
final versionProvider = FutureProvider<VersionInfo>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.publicVersion);
  return VersionInfo.fromJson(response.data);
});

// 冷却统计
final cooldownStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.cooldownStats);
  final data = response.data as Map<String, dynamic>;
  return {
    'channel_cooldowns': data['channel_cooldowns'] ?? 0,
    'key_cooldowns': data['key_cooldowns'] ?? 0,
  };
});
