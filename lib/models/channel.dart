// 渠道数据模型
class Channel {
  final int id;
  final String name;
  final String channelType;
  final String url;
  final int priority;
  final bool enabled;
  final List<ChannelModel> models;
  final double? dailyCostLimit;
  final String keyStrategy;
  final String? cooldownUntil;
  final int? cooldownRemainingMs;
  final List<KeyCooldown>? keyCooldowns;
  final double? effectivePriority;
  final double? successRate;
  final List<UrlStat>? urlStats;
  final int keyCount;
  final String? createdAt;
  final String? updatedAt;

  Channel({
    required this.id,
    required this.name,
    required this.channelType,
    required this.url,
    required this.priority,
    required this.enabled,
    required this.models,
    this.dailyCostLimit,
    required this.keyStrategy,
    this.cooldownUntil,
    this.cooldownRemainingMs,
    this.keyCooldowns,
    this.effectivePriority,
    this.successRate,
    this.urlStats,
    required this.keyCount,
    this.createdAt,
    this.updatedAt,
  });

  // 是否在冷却中
  bool get isInCooldown => (cooldownRemainingMs ?? 0) > 0;

  // 有几个 URL
  int get urlCount => url.split('\n').where((u) => u.trim().isNotEmpty).length;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      channelType: json['channel_type'] ?? '',
      url: json['url'] ?? '',
      priority: json['priority'] ?? 0,
      enabled: json['enabled'] ?? false,
      models: (json['models'] as List?)?.map((e) => ChannelModel.fromJson(e)).toList() ?? [],
      dailyCostLimit: json['daily_cost_limit']?.toDouble(),
      keyStrategy: json['key_strategy'] ?? 'sequential',
      cooldownUntil: json['cooldown_until']?.toString(),
      cooldownRemainingMs: json['cooldown_remaining_ms'],
      keyCooldowns: (json['key_cooldowns'] as List?)?.map((e) => KeyCooldown.fromJson(e)).toList(),
      effectivePriority: json['effective_priority']?.toDouble(),
      successRate: json['success_rate']?.toDouble(),
      urlStats: (json['url_stats'] as List?)?.map((e) => UrlStat.fromJson(e)).toList(),
      keyCount: json['key_count'] ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

// 渠道模型映射
class ChannelModel {
  final String model;
  final String redirectModel;

  ChannelModel({required this.model, required this.redirectModel});

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      model: json['model'] ?? '',
      redirectModel: json['redirect_model'] ?? '',
    );
  }
}

// Key 冷却状态
class KeyCooldown {
  final int keyIndex;
  final String? cooldownUntil;
  final int cooldownRemainingMs;

  KeyCooldown({
    required this.keyIndex,
    this.cooldownUntil,
    required this.cooldownRemainingMs,
  });

  bool get isInCooldown => cooldownRemainingMs > 0;

  factory KeyCooldown.fromJson(Map<String, dynamic> json) {
    return KeyCooldown(
      keyIndex: json['key_index'] ?? 0,
      cooldownUntil: json['cooldown_until']?.toString(),
      cooldownRemainingMs: json['cooldown_remaining_ms'] ?? 0,
    );
  }
}

// URL 统计
class UrlStat {
  final String url;
  final int latencyMs;
  final int failureCount;
  final int successCount;
  final bool? isInCooldown;
  final String? cooldownUntil;
  final int? cooldownRemainingMs;

  UrlStat({
    required this.url,
    required this.latencyMs,
    required this.failureCount,
    required this.successCount,
    this.isInCooldown,
    this.cooldownUntil,
    this.cooldownRemainingMs,
  });

  factory UrlStat.fromJson(Map<String, dynamic> json) {
    return UrlStat(
      url: json['url'] ?? '',
      latencyMs: json['latency_ms'] ?? 0,
      failureCount: json['failure_count'] ?? 0,
      successCount: json['success_count'] ?? 0,
      isInCooldown: json['is_in_cooldown'],
      cooldownUntil: json['cooldown_until']?.toString(),
      cooldownRemainingMs: json['cooldown_remaining_ms'],
    );
  }
}

// 渠道测试结果
class ChannelTestResult {
  final bool success;
  final int statusCode;
  final String message;
  final String? responseText;
  final int durationMs;
  final int? firstByteDurationMs;
  final double? costUsd;
  final int testedKeyIndex;
  final int totalKeys;

  ChannelTestResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.responseText,
    required this.durationMs,
    this.firstByteDurationMs,
    this.costUsd,
    required this.testedKeyIndex,
    required this.totalKeys,
  });

  factory ChannelTestResult.fromJson(Map<String, dynamic> json) {
    return ChannelTestResult(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      responseText: json['response_text'],
      durationMs: json['duration_ms'] ?? 0,
      firstByteDurationMs: json['first_byte_duration_ms'],
      costUsd: json['cost_usd']?.toDouble(),
      testedKeyIndex: json['tested_key_index'] ?? 0,
      totalKeys: json['total_keys'] ?? 0,
    );
  }
}
