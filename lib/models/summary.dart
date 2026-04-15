import '../core/utils/safe_parse.dart';

// 仪表盘摘要数据
class Summary {
  final int totalRequests;
  final int successRequests;
  final int errorRequests;
  final String range;
  final int durationSeconds;
  final RpmStats? rpmStats;
  final bool isToday;
  final Map<String, TypeSummary> byType;

  Summary({
    required this.totalRequests,
    required this.successRequests,
    required this.errorRequests,
    required this.range,
    required this.durationSeconds,
    this.rpmStats,
    required this.isToday,
    required this.byType,
  });

  // 成功率
  double get successRate => totalRequests > 0 ? successRequests / totalRequests : 0;

  factory Summary.fromJson(Map<String, dynamic> json) {
    // 解析 by_type
    final byTypeMap = <String, TypeSummary>{};
    if (json['by_type'] != null) {
      (json['by_type'] as Map<String, dynamic>).forEach((key, value) {
        byTypeMap[key] = TypeSummary.fromJson(value);
      });
    }

    return Summary(
      totalRequests: safeInt(json['total_requests']),
      successRequests: safeInt(json['success_requests']),
      errorRequests: safeInt(json['error_requests']),
      range: json['range'] ?? 'today',
      durationSeconds: safeInt(json['duration_seconds']),
      rpmStats: json['rpm_stats'] != null ? RpmStats.fromJson(json['rpm_stats']) : null,
      isToday: json['is_today'] ?? false,
      byType: byTypeMap,
    );
  }
}

// 按渠道类型的统计
class TypeSummary {
  final String channelType;
  final int totalRequests;
  final int successRequests;
  final int errorRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheReadTokens;
  final int totalCacheCreationTokens;
  final double totalCost;

  TypeSummary({
    required this.channelType,
    required this.totalRequests,
    required this.successRequests,
    required this.errorRequests,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCacheReadTokens,
    required this.totalCacheCreationTokens,
    required this.totalCost,
  });

  factory TypeSummary.fromJson(Map<String, dynamic> json) {
    return TypeSummary(
      channelType: json['channel_type'] ?? '',
      totalRequests: safeInt(json['total_requests']),
      successRequests: safeInt(json['success_requests']),
      errorRequests: safeInt(json['error_requests']),
      totalInputTokens: safeInt(json['total_input_tokens']),
      totalOutputTokens: safeInt(json['total_output_tokens']),
      totalCacheReadTokens: safeInt(json['total_cache_read_tokens']),
      totalCacheCreationTokens: safeInt(json['total_cache_creation_tokens']),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }
}

// RPM 统计
class RpmStats {
  final double peakRpm;
  final double peakQps;
  final double avgRpm;
  final double avgQps;
  final double recentRpm;
  final double recentQps;

  RpmStats({
    required this.peakRpm,
    required this.peakQps,
    required this.avgRpm,
    required this.avgQps,
    required this.recentRpm,
    required this.recentQps,
  });

  factory RpmStats.fromJson(Map<String, dynamic> json) {
    return RpmStats(
      peakRpm: (json['peak_rpm'] ?? 0).toDouble(),
      peakQps: (json['peak_qps'] ?? 0).toDouble(),
      avgRpm: (json['avg_rpm'] ?? 0).toDouble(),
      avgQps: (json['avg_qps'] ?? 0).toDouble(),
      recentRpm: (json['recent_rpm'] ?? 0).toDouble(),
      recentQps: (json['recent_qps'] ?? 0).toDouble(),
    );
  }
}

// 活跃请求 — 字段名对齐后端 active_requests.go 的 ActiveRequest struct
class ActiveRequest {
  final String id;
  final int channelId;
  final String channelName;
  final String channelType;
  final String model;
  final int? tokenId;        // 后端字段名 "token_id"
  final int startTime;       // 后端字段名 "start_time"，Unix 毫秒
  final bool isStreaming;
  final String baseUrl;
  final String clientIp;

  ActiveRequest({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelType,
    required this.model,
    this.tokenId,
    required this.startTime,
    required this.isStreaming,
    required this.baseUrl,
    required this.clientIp,
  });

  // 已经过去多少毫秒（实时算，不依赖后端字段）
  int get elapsedMs => DateTime.now().millisecondsSinceEpoch - startTime;

  factory ActiveRequest.fromJson(Map<String, dynamic> json) {
    return ActiveRequest(
      id: json['id']?.toString() ?? '',
      channelId: safeInt(json['channel_id']),
      channelName: json['channel_name'] ?? '',
      channelType: json['channel_type'] ?? '',
      model: json['model'] ?? '',
      tokenId: safeIntOrNull(json['token_id']),
      startTime: safeInt(json['start_time']),
      isStreaming: json['is_streaming'] ?? false,
      baseUrl: json['base_url'] ?? '',
      clientIp: json['client_ip'] ?? '',
    );
  }
}

// 版本信息
class VersionInfo {
  final String version;
  final bool hasUpdate;
  final String latestVersion;
  final String releaseUrl;

  VersionInfo({
    required this.version,
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] ?? '',
      hasUpdate: json['has_update'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      releaseUrl: json['release_url'] ?? '',
    );
  }
}
