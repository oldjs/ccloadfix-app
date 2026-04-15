import '../core/utils/safe_parse.dart';

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
      id: safeInt(json['id']),
      name: json['name'] ?? '',
      channelType: json['channel_type'] ?? '',
      url: json['url'] ?? '',
      priority: safeInt(json['priority']),
      enabled: json['enabled'] ?? false,
      models: (json['models'] as List?)?.map((e) => ChannelModel.fromJson(e)).toList() ?? [],
      dailyCostLimit: json['daily_cost_limit']?.toDouble(),
      keyStrategy: json['key_strategy'] ?? 'sequential',
      cooldownUntil: json['cooldown_until']?.toString(),
      cooldownRemainingMs: safeIntOrNull(json['cooldown_remaining_ms']),
      keyCooldowns: (json['key_cooldowns'] as List?)?.map((e) => KeyCooldown.fromJson(e)).toList(),
      effectivePriority: json['effective_priority']?.toDouble(),
      successRate: json['success_rate']?.toDouble(),
      urlStats: (json['url_stats'] as List?)?.map((e) => UrlStat.fromJson(e)).toList(),
      keyCount: safeInt(json['key_count']),
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
      keyIndex: safeInt(json['key_index']),
      cooldownUntil: json['cooldown_until']?.toString(),
      cooldownRemainingMs: safeInt(json['cooldown_remaining_ms']),
    );
  }
}

// URL 统计 — 字段名对齐后端 url_selector.go 的 URLStat struct
class UrlStat {
  final String url;
  final double latencyMs;          // 选择器使用的有效延迟
  final int requests;              // 后端字段名 "requests"，代表成功次数
  final int failures;              // 后端字段名 "failures"
  final bool cooledDown;           // 后端字段名 "cooled_down"
  final int cooldownRemainMs;      // 后端字段名 "cooldown_remain_ms"
  final double weight;             // 动态选择权重

  UrlStat({
    required this.url,
    required this.latencyMs,
    required this.requests,
    required this.failures,
    required this.cooledDown,
    required this.cooldownRemainMs,
    required this.weight,
  });

  factory UrlStat.fromJson(Map<String, dynamic> json) {
    return UrlStat(
      url: json['url'] ?? '',
      latencyMs: (json['latency_ms'] ?? 0).toDouble(),
      requests: safeInt(json['requests']),
      failures: safeInt(json['failures']),
      cooledDown: json['cooled_down'] ?? false,
      cooldownRemainMs: safeInt(json['cooldown_remain_ms']),
      weight: (json['weight'] ?? 0).toDouble(),
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
      statusCode: safeInt(json['status_code']),
      message: json['error']?.toString() ?? '',
      responseText: json['response_text'],
      durationMs: safeInt(json['duration_ms']),
      firstByteDurationMs: safeIntOrNull(json['first_byte_duration_ms']),
      costUsd: json['cost_usd']?.toDouble(),
      testedKeyIndex: safeInt(json['tested_key_index']),
      totalKeys: safeInt(json['total_keys']),
    );
  }
}
