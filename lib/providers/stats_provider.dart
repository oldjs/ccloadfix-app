import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/stats.dart';

// 统计数据
final statsProvider = FutureProvider.family<StatsResponse, String>((ref, range) async {
  final response = await DioClient.instance.get(
    ApiEndpoints.stats,
    queryParameters: {'range': range},
  );
  return StatsResponse.fromJson(response.data);
});

// 指标时间线
final metricsProvider = FutureProvider.family<List<MetricBucket>, String>((ref, range) async {
  final response = await DioClient.instance.get(
    ApiEndpoints.metrics,
    queryParameters: {'range': range, 'bucket_min': 5},
  );
  final list = response.data as List;
  return list.map((e) => MetricBucket.fromJson(e)).toList();
});
