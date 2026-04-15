import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/log_entry.dart';

// 日志查询参数
class LogQuery {
  final String range;
  final int limit;
  final int offset;
  final int? channelId;
  final String? model;
  final int? statusCode;
  final String? channelType;

  const LogQuery({
    this.range = 'today',
    this.limit = 50,
    this.offset = 0,
    this.channelId,
    this.model,
    this.statusCode,
    this.channelType,
  });

  // 生成查询参数 map
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'range': range,
      'limit': limit,
      'offset': offset,
    };
    if (channelId != null) params['channel_id'] = channelId;
    if (model != null && model!.isNotEmpty) params['model'] = model;
    if (statusCode != null) params['status_code'] = statusCode;
    if (channelType != null && channelType!.isNotEmpty) params['channel_type'] = channelType;
    return params;
  }

  // 复制并修改
  LogQuery copyWith({
    String? range,
    int? limit,
    int? offset,
    int? channelId,
    String? model,
    int? statusCode,
    String? channelType,
    bool clearChannelId = false,
    bool clearModel = false,
    bool clearStatusCode = false,
    bool clearChannelType = false,
  }) {
    return LogQuery(
      range: range ?? this.range,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      channelId: clearChannelId ? null : (channelId ?? this.channelId),
      model: clearModel ? null : (model ?? this.model),
      statusCode: clearStatusCode ? null : (statusCode ?? this.statusCode),
      channelType: clearChannelType ? null : (channelType ?? this.channelType),
    );
  }
}

// 日志查询状态
class LogQueryNotifier extends Notifier<LogQuery> {
  @override
  LogQuery build() => const LogQuery();

  void update(LogQuery query) {
    state = query;
  }
}

final logQueryProvider = NotifierProvider<LogQueryNotifier, LogQuery>(LogQueryNotifier.new);

// 日志数据 provider（解包后 response.data 是日志数组，count 在 extra 里）
final logListProvider = FutureProvider<LogQueryResult>((ref) async {
  final query = ref.watch(logQueryProvider);
  final response = await DioClient.instance.get(
    ApiEndpoints.logs,
    queryParameters: query.toQueryParams(),
  );
  final list = (response.data as List?) ?? [];
  final total = (response.extra['totalCount'] as int?) ?? list.length;
  return LogQueryResult(
    data: list.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList(),
    total: total,
  );
});

// 可用模型列表（用于筛选下拉）
final availableModelsProvider = FutureProvider<List<String>>((ref) async {
  final response = await DioClient.instance.get(
    ApiEndpoints.models,
    queryParameters: {'range': 'today'},
  );
  final list = response.data as List;
  return list.map((e) => e['model'].toString()).toList();
});
