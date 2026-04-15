// 请求日志条目
class LogEntry {
  final int id;
  final int time;
  final String model;
  final String? actualModel;
  final int channelId;
  final String channelName;
  final int statusCode;
  final String? message;
  final double duration;
  final bool isStreaming;
  final double? firstByteTime;
  final String? apiKeyUsed;
  final String? apiKeyHash;
  final int? authTokenId;
  final String? clientIp;
  final String? baseUrl;
  final String? serviceTier;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadInputTokens;
  final int cache5mInputTokens;
  final int cache1hInputTokens;
  final double cost;

  LogEntry({
    required this.id,
    required this.time,
    required this.model,
    this.actualModel,
    required this.channelId,
    required this.channelName,
    required this.statusCode,
    this.message,
    required this.duration,
    required this.isStreaming,
    this.firstByteTime,
    this.apiKeyUsed,
    this.apiKeyHash,
    this.authTokenId,
    this.clientIp,
    this.baseUrl,
    this.serviceTier,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadInputTokens,
    required this.cache5mInputTokens,
    required this.cache1hInputTokens,
    required this.cost,
  });

  // 是否成功
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  // 格式化时间
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time * 1000);

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? 0,
      time: json['time'] ?? 0,
      model: json['model'] ?? '',
      actualModel: json['actual_model'],
      channelId: json['channel_id'] ?? 0,
      channelName: json['channel_name'] ?? '',
      statusCode: json['status_code'] ?? 0,
      message: json['message'],
      duration: (json['duration'] ?? 0).toDouble(),
      isStreaming: json['is_streaming'] ?? false,
      firstByteTime: json['first_byte_time']?.toDouble(),
      apiKeyUsed: json['api_key_used'],
      apiKeyHash: json['api_key_hash'],
      authTokenId: json['auth_token_id'],
      clientIp: json['client_ip'],
      baseUrl: json['base_url'],
      serviceTier: json['service_tier'],
      inputTokens: json['input_tokens'] ?? 0,
      outputTokens: json['output_tokens'] ?? 0,
      cacheReadInputTokens: json['cache_read_input_tokens'] ?? 0,
      cache5mInputTokens: json['cache_5m_input_tokens'] ?? 0,
      cache1hInputTokens: json['cache_1h_input_tokens'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
    );
  }
}

// 日志查询结果
class LogQueryResult {
  final List<LogEntry> data;
  final int total;

  LogQueryResult({required this.data, required this.total});

  factory LogQueryResult.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List?) ?? [];
    return LogQueryResult(
      data: list.map((e) => LogEntry.fromJson(e)).toList(),
      total: json['total'] ?? 0,
    );
  }
}
