import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/log_provider.dart';
import '../../models/log_entry.dart';
import '../../widgets/error_view.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(logQueryProvider);
    final logsAsync = ref.watch(logListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: Badge(
              isLabelVisible: _hasFilter(query),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context, ref, query),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(logListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // 时间范围 tab
          _buildRangeSelector(context, ref, query, colorScheme),
          // 日志列表
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(logListProvider),
              ),
              data: (result) {
                if (result.data.isEmpty) {
                  return Center(
                    child: Text('暂无日志', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  );
                }
                return Column(
                  children: [
                    // 总数提示
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('共 ${result.total} 条', style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant,
                          )),
                          const Spacer(),
                          Text('显示 ${result.data.length} 条', style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant,
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ref.invalidate(logListProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: result.data.length + 1,
                          itemBuilder: (context, index) {
                            // 末尾加载更多
                            if (index == result.data.length) {
                              if (result.data.length < result.total) {
                                return _buildLoadMore(ref, query, result.data.length);
                              }
                              return const SizedBox(height: 32);
                            }
                            return _LogItem(log: result.data[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasFilter(LogQuery query) {
    return query.channelId != null || query.model != null ||
           query.statusCode != null || query.channelType != null;
  }

  // 时间范围选择
  Widget _buildRangeSelector(BuildContext context, WidgetRef ref, LogQuery query, ColorScheme colorScheme) {
    const ranges = [
      ('today', '今天'),
      ('this_week', '本周'),
      ('this_month', '本月'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SegmentedButton<String>(
        segments: ranges.map((r) => ButtonSegment(value: r.$1, label: Text(r.$2))).toList(),
        selected: {query.range},
        onSelectionChanged: (s) {
          ref.read(logQueryProvider.notifier).update(query.copyWith(range: s.first, offset: 0));
        },
        showSelectedIcon: false,
        style: ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  // 加载更多
  Widget _buildLoadMore(WidgetRef ref, LogQuery query, int currentCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: FilledButton.tonal(
          onPressed: () {
            ref.read(logQueryProvider.notifier).update(query.copyWith(
              offset: 0,
              limit: currentCount + 50,
            ));
          },
          child: const Text('加载更多'),
        ),
      ),
    );
  }

  // 筛选弹出面板
  void _showFilterSheet(BuildContext context, WidgetRef ref, LogQuery query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(query: query, ref: ref),
    );
  }
}

// 筛选面板
class _FilterSheet extends StatefulWidget {
  final LogQuery query;
  final WidgetRef ref;

  const _FilterSheet({required this.query, required this.ref});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _model;
  late int? _statusCode;
  late String? _channelType;

  @override
  void initState() {
    super.initState();
    _model = widget.query.model;
    _statusCode = widget.query.statusCode;
    _channelType = widget.query.channelType;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('筛选', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // 状态码筛选
          Text('状态码', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 200, 400, 429, 500, 502, 503].map((code) {
              final label = code == null ? '全部' : '$code';
              return ChoiceChip(
                label: Text(label),
                selected: _statusCode == code,
                onSelected: (_) => setState(() => _statusCode = code),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 渠道类型筛选
          Text('渠道类型', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 'anthropic', 'openai', 'gemini', 'codex'].map((type) {
              final label = type == null ? '全部' : type.toUpperCase();
              return ChoiceChip(
                label: Text(label),
                selected: _channelType == type,
                onSelected: (_) => setState(() => _channelType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _model = null;
                      _statusCode = null;
                      _channelType = null;
                    });
                  },
                  child: const Text('重置'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.ref.read(logQueryProvider.notifier).update(widget.query.copyWith(
                      model: _model,
                      statusCode: _statusCode,
                      channelType: _channelType,
                      clearModel: _model == null,
                      clearStatusCode: _statusCode == null,
                      clearChannelType: _channelType == null,
                      offset: 0,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('应用'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 单条日志
class _LogItem extends StatelessWidget {
  final LogEntry log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm:ss').format(log.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：时间 + 模型 + 状态码
              Row(
                children: [
                  Text(timeStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(log.model, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  ),
                  _buildStatusBadge(colorScheme),
                ],
              ),
              const SizedBox(height: 4),
              // 第二行：渠道 + 耗时 + 费用
              Row(
                children: [
                  Icon(Icons.dns_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(log.channelName, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${log.duration.toStringAsFixed(2)}s', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  if (log.cost > 0) ...[
                    const SizedBox(width: 12),
                    Text('\$${log.cost.toStringAsFixed(4)}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                  const Spacer(),
                  if (log.isStreaming)
                    Icon(Icons.stream, size: 14, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme colorScheme) {
    Color bg;
    Color fg;
    if (log.isSuccess) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
    } else if (log.statusCode == 429) {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange;
    } else {
      bg = colorScheme.errorContainer;
      fg = colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text('${log.statusCode}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  // 日志详情弹窗
  void _showDetail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.dateTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // 标题
            Row(
              children: [
                Expanded(child: Text(log.model, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                _buildStatusBadge(colorScheme),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('时间', dateStr),
            _detailRow('渠道', '${log.channelName} (#${log.channelId})'),
            _detailRow('耗时', '${log.duration.toStringAsFixed(3)}s'),
            if (log.firstByteTime != null) _detailRow('首字节', '${log.firstByteTime!.toStringAsFixed(3)}s'),
            _detailRow('流式', log.isStreaming ? '是' : '否'),
            if (log.actualModel != null) _detailRow('实际模型', log.actualModel!),
            if (log.baseUrl != null) _detailRow('Base URL', log.baseUrl!),
            if (log.clientIp != null) _detailRow('客户端 IP', log.clientIp!),
            if (log.serviceTier != null) _detailRow('服务层级', log.serviceTier!),
            if (log.apiKeyUsed != null) _detailRow('API Key', log.apiKeyUsed!),
            if (log.authTokenId != null) _detailRow('Token ID', '#${log.authTokenId}'),
            const Divider(height: 24),
            // Token 统计
            _detailRow('Input Tokens', '${log.inputTokens}'),
            _detailRow('Output Tokens', '${log.outputTokens}'),
            if (log.cacheReadInputTokens > 0) _detailRow('Cache Read', '${log.cacheReadInputTokens}'),
            if (log.cache5mInputTokens > 0) _detailRow('Cache 5m', '${log.cache5mInputTokens}'),
            if (log.cache1hInputTokens > 0) _detailRow('Cache 1h', '${log.cache1hInputTokens}'),
            _detailRow('费用', '\$${log.cost.toStringAsFixed(6)}'),
            if (log.message != null && log.message!.isNotEmpty) ...[
              const Divider(height: 24),
              Text('消息', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(log.message!, style: const TextStyle(fontSize: 12)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
