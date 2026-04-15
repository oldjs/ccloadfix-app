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
      totalRequests: json['total_requests'] ?? 0,
      successRequests: json['success_requests'] ?? 0,
      errorRequests: json['error_requests'] ?? 0,
      range: json['range'] ?? 'today',
      durationSeconds: (json['duration_seconds'] ?? 0).toInt(),
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
      totalRequests: json['total_requests'] ?? 0,
      successRequests: json['success_requests'] ?? 0,
      errorRequests: json['error_requests'] ?? 0,
      totalInputTokens: json['total_input_tokens'] ?? 0,
      totalOutputTokens: json['total_output_tokens'] ?? 0,
      totalCacheReadTokens: json['total_cache_read_tokens'] ?? 0,
      totalCacheCreationTokens: json['total_cache_creation_tokens'] ?? 0,
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

// 活跃请求
class ActiveRequest {
  final String id;
  final int channelId;
  final String channelName;
  final String model;
  final int? authTokenId;
  final int startedAt;
  final int elapsedMs;
  final bool isStreaming;
  final String baseUrl;
  final String requestPath;

  ActiveRequest({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.model,
    this.authTokenId,
    required this.startedAt,
    required this.elapsedMs,
    required this.isStreaming,
    required this.baseUrl,
    required this.requestPath,
  });

  factory ActiveRequest.fromJson(Map<String, dynamic> json) {
    return ActiveRequest(
      id: json['id'] ?? '',
      channelId: json['channel_id'] ?? 0,
      channelName: json['channel_name'] ?? '',
      model: json['model'] ?? '',
      authTokenId: json['auth_token_id'],
      startedAt: json['started_at'] ?? 0,
      elapsedMs: json['elapsed_ms'] ?? 0,
      isStreaming: json['is_streaming'] ?? false,
      baseUrl: json['base_url'] ?? '',
      requestPath: json['request_path'] ?? '',
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
