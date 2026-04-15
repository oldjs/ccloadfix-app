import '../core/utils/safe_parse.dart';

// API 访问 Token
class AuthToken {
  final int id;
  final String? token;
  final String description;
  final String? createdAt;
  final int? expiresAt;
  final int? lastUsedAt;
  final bool isActive;
  final int successCount;
  final int failureCount;
  final double streamAvgTtfb;
  final double nonStreamAvgRt;
  final int streamCount;
  final int nonStreamCount;
  final int promptTokensTotal;
  final int completionTokensTotal;
  final int cacheReadTokensTotal;
  final int cacheCreationTokensTotal;
  final double totalCostUsd;
  final double? costUsedUsd;
  final double? costLimitUsd;
  final double peakRpm;
  final double avgRpm;
  final double recentRpm;
  final List<String>? allowedModels;

  AuthToken({
    required this.id,
    this.token,
    required this.description,
    this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
    required this.isActive,
    required this.successCount,
    required this.failureCount,
    required this.streamAvgTtfb,
    required this.nonStreamAvgRt,
    required this.streamCount,
    required this.nonStreamCount,
    required this.promptTokensTotal,
    required this.completionTokensTotal,
    required this.cacheReadTokensTotal,
    required this.cacheCreationTokensTotal,
    required this.totalCostUsd,
    this.costUsedUsd,
    this.costLimitUsd,
    required this.peakRpm,
    required this.avgRpm,
    required this.recentRpm,
    this.allowedModels,
  });

  int get totalRequests => successCount + failureCount;
  double get successRate => totalRequests > 0 ? successCount / totalRequests : 0;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      id: safeInt(json['id']),
      token: json['token'],
      description: json['description'] ?? '',
      createdAt: json['created_at']?.toString(),
      expiresAt: safeIntOrNull(json['expires_at']),
      lastUsedAt: safeIntOrNull(json['last_used_at']),
      isActive: json['is_active'] ?? false,
      successCount: safeInt(json['success_count']),
      failureCount: safeInt(json['failure_count']),
      streamAvgTtfb: (json['stream_avg_ttfb'] ?? 0).toDouble(),
      nonStreamAvgRt: (json['non_stream_avg_rt'] ?? 0).toDouble(),
      streamCount: safeInt(json['stream_count']),
      nonStreamCount: safeInt(json['non_stream_count']),
      promptTokensTotal: safeInt(json['prompt_tokens_total']),
      completionTokensTotal: safeInt(json['completion_tokens_total']),
      cacheReadTokensTotal: safeInt(json['cache_read_tokens_total']),
      cacheCreationTokensTotal: safeInt(json['cache_creation_tokens_total']),
      totalCostUsd: (json['total_cost_usd'] ?? 0).toDouble(),
      costUsedUsd: json['cost_used_usd']?.toDouble(),
      costLimitUsd: json['cost_limit_usd']?.toDouble(),
      peakRpm: (json['peak_rpm'] ?? 0).toDouble(),
      avgRpm: (json['avg_rpm'] ?? 0).toDouble(),
      recentRpm: (json['recent_rpm'] ?? 0).toDouble(),
      allowedModels: (json['allowed_models'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
