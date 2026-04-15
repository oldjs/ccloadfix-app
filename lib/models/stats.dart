import 'summary.dart';

// 渠道+模型维度统计
class ChannelStats {
  final int channelId;
  final String channelName;
  final int channelPriority;
  final String model;
  final int success;
  final int error;
  final int total;
  final double avgFirstByteTime;
  final double avgDuration;
  final double peakRpm;
  final double avgRpm;
  final double recentRpm;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheReadTokens;
  final int totalCacheCreationTokens;
  final double totalCost;

  ChannelStats({
    required this.channelId,
    required this.channelName,
    required this.channelPriority,
    required this.model,
    required this.success,
    required this.error,
    required this.total,
    required this.avgFirstByteTime,
    required this.avgDuration,
    required this.peakRpm,
    required this.avgRpm,
    required this.recentRpm,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCacheReadTokens,
    required this.totalCacheCreationTokens,
    required this.totalCost,
  });

  double get successRate => total > 0 ? success / total : 0;

  factory ChannelStats.fromJson(Map<String, dynamic> json) {
    return ChannelStats(
      channelId: json['channel_id'] ?? 0,
      channelName: json['channel_name'] ?? '',
      channelPriority: json['channel_priority'] ?? 0,
      model: json['model'] ?? '',
      success: json['success'] ?? 0,
      error: json['error'] ?? 0,
      total: json['total'] ?? 0,
      avgFirstByteTime: (json['avg_first_byte_time_seconds'] ?? 0).toDouble(),
      avgDuration: (json['avg_duration_seconds'] ?? 0).toDouble(),
      peakRpm: (json['peak_rpm'] ?? 0).toDouble(),
      avgRpm: (json['avg_rpm'] ?? 0).toDouble(),
      recentRpm: (json['recent_rpm'] ?? 0).toDouble(),
      totalInputTokens: json['total_input_tokens'] ?? 0,
      totalOutputTokens: json['total_output_tokens'] ?? 0,
      totalCacheReadTokens: json['total_cache_read_input_tokens'] ?? 0,
      totalCacheCreationTokens: json['total_cache_creation_input_tokens'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }
}

// 统计接口响应
class StatsResponse {
  final List<ChannelStats> stats;
  final int durationSeconds;
  final RpmStats? rpmStats;
  final bool isToday;

  StatsResponse({
    required this.stats,
    required this.durationSeconds,
    this.rpmStats,
    required this.isToday,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['stats'] as List?) ?? [];
    return StatsResponse(
      stats: list.map((e) => ChannelStats.fromJson(e)).toList(),
      durationSeconds: json['duration_seconds'] ?? 0,
      rpmStats: json['rpm_stats'] != null ? RpmStats.fromJson(json['rpm_stats']) : null,
      isToday: json['is_today'] ?? false,
    );
  }
}

// 时间桶指标
class MetricBucket {
  final int ts;
  final int success;
  final int error;
  final double avgFirstByteTime;
  final double avgDuration;
  final double totalCost;
  final int inputTokens;
  final int outputTokens;

  MetricBucket({
    required this.ts,
    required this.success,
    required this.error,
    required this.avgFirstByteTime,
    required this.avgDuration,
    required this.totalCost,
    required this.inputTokens,
    required this.outputTokens,
  });

  int get total => success + error;
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ts * 1000);

  factory MetricBucket.fromJson(Map<String, dynamic> json) {
    return MetricBucket(
      ts: json['ts'] ?? 0,
      success: json['success'] ?? 0,
      error: json['error'] ?? 0,
      avgFirstByteTime: (json['avg_first_byte_time_seconds'] ?? 0).toDouble(),
      avgDuration: (json['avg_duration_seconds'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      inputTokens: json['input_tokens'] ?? 0,
      outputTokens: json['output_tokens'] ?? 0,
    );
  }
}
