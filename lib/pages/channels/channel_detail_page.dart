import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/channel_provider.dart';
import '../../models/channel.dart';
import '../../widgets/error_view.dart';
import '../../core/api/api_exception.dart';

class ChannelDetailPage extends ConsumerStatefulWidget {
  final int channelId;
  const ChannelDetailPage({super.key, required this.channelId});

  @override
  ConsumerState<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends ConsumerState<ChannelDetailPage> {
  bool _isTesting = false;
  ChannelTestResult? _testResult;

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(channelDetailProvider(widget.channelId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('渠道 #${widget.channelId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(channelDetailProvider(widget.channelId)),
          ),
        ],
      ),
      body: channelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(channelDetailProvider(widget.channelId)),
        ),
        data: (channel) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(channelDetailProvider(widget.channelId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 基本信息卡片
              _buildInfoCard(channel, colorScheme),
              const SizedBox(height: 12),

              // 优先级调整
              _buildPriorityCard(channel, colorScheme),
              const SizedBox(height: 12),

              // 模型列表
              _buildModelsCard(channel, colorScheme),
              const SizedBox(height: 12),

              // URL 状态
              if (channel.urlStats != null && channel.urlStats!.isNotEmpty) ...[
                _buildUrlStatsCard(channel.urlStats!, colorScheme),
                const SizedBox(height: 12),
              ],

              // Key 冷却状态
              if (channel.keyCooldowns != null && channel.keyCooldowns!.isNotEmpty) ...[
                _buildKeyCooldownCard(channel.keyCooldowns!, colorScheme),
                const SizedBox(height: 12),
              ],

              // 操作区
              _buildActionsCard(channel, colorScheme),
              const SizedBox(height: 12),

              // 测试结果
              if (_testResult != null) ...[
                _buildTestResultCard(_testResult!, colorScheme),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 基本信息
  Widget _buildInfoCard(Channel channel, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名称 + 启用开关
            Row(
              children: [
                Expanded(
                  child: Text(channel.name, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                  )),
                ),
                Switch(
                  value: channel.enabled,
                  onChanged: (v) async {
                    await ChannelActions.toggleEnabled(channel.id, v);
                    ref.invalidate(channelDetailProvider(widget.channelId));
                    ref.invalidate(channelListProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('类型', channel.channelType.toUpperCase()),
            _infoRow('Key 策略', channel.keyStrategy),
            _infoRow('Key 数量', '${channel.keyCount}'),
            _infoRow('URL 数量', '${channel.urlCount}'),
            if (channel.dailyCostLimit != null)
              _infoRow('日成本限额', '\$${channel.dailyCostLimit!.toStringAsFixed(2)}'),
            if (channel.effectivePriority != null)
              _infoRow('有效优先级', channel.effectivePriority!.toStringAsFixed(1)),
            if (channel.successRate != null)
              _infoRow('成功率', '${(channel.successRate! * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(
              fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // 优先级调整
  Widget _buildPriorityCard(Channel channel, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('优先级', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filled(
                  onPressed: channel.priority <= 0 ? null : () => _updatePriority(channel, channel.priority - 1),
                  icon: const Icon(Icons.remove, size: 18),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Text('${channel.priority}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: () => _updatePriority(channel, channel.priority + 1),
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                const Spacer(),
                // 快捷设置
                ...[1, 5, 10, 20].map((p) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ActionChip(
                    label: Text('$p', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _updatePriority(channel, p),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: channel.priority == p ? colorScheme.primaryContainer : null,
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePriority(Channel channel, int newPriority) async {
    try {
      await ChannelActions.updatePriority(channel.id, newPriority);
      ref.invalidate(channelDetailProvider(widget.channelId));
      ref.invalidate(channelListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // 模型列表
  Widget _buildModelsCard(Channel channel, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型 (${channel.models.length})', style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            if (channel.models.isEmpty)
              Text('无模型', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: channel.models.map((m) => Chip(
                  label: Text(
                    m.redirectModel.isNotEmpty ? '${m.model} -> ${m.redirectModel}' : m.model,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // URL 健康状态
  Widget _buildUrlStatsCard(List<UrlStat> urlStats, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL 状态 (${urlStats.length})', style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            ...urlStats.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        stat.cooledDown ? Icons.pause_circle : Icons.check_circle,
                        size: 14,
                        color: stat.cooledDown ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(stat.url, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Text('延迟: ${stat.latencyMs.toStringAsFixed(0)}ms', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Text('成功: ${stat.requests}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                      const SizedBox(width: 12),
                      Text('失败: ${stat.failures}', style: TextStyle(
                        fontSize: 11, color: stat.failures > 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Key 冷却
  Widget _buildKeyCooldownCard(List<KeyCooldown> cooldowns, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Key 冷却状态', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...cooldowns.map((kc) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                kc.isInCooldown ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: kc.isInCooldown ? Colors.orange : Colors.green,
                size: 20,
              ),
              title: Text('Key #${kc.keyIndex}', style: const TextStyle(fontSize: 13)),
              trailing: kc.isInCooldown
                  ? Text('${(kc.cooldownRemainingMs / 1000).toStringAsFixed(0)}s',
                      style: TextStyle(fontSize: 12, color: colorScheme.error))
                  : Text('正常', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            )),
          ],
        ),
      ),
    );
  }

  // 操作区
  Widget _buildActionsCard(Channel channel, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('操作', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 测试渠道
                FilledButton.tonalIcon(
                  onPressed: _isTesting ? null : () => _testChannel(channel),
                  icon: _isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow, size: 18),
                  label: const Text('测试'),
                ),
                // 冷却操作
                if (channel.isInCooldown)
                  FilledButton.tonalIcon(
                    onPressed: () => _clearCooldown(channel),
                    icon: const Icon(Icons.play_circle, size: 18),
                    label: const Text('清除冷却'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _showCooldownDialog(channel),
                    icon: const Icon(Icons.ac_unit, size: 18),
                    label: const Text('设置冷却'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 测试渠道
  Future<void> _testChannel(Channel channel) async {
    setState(() { _isTesting = true; _testResult = null; });
    try {
      // 取第一个模型来测试
      final model = channel.models.isNotEmpty ? channel.models.first.model : null;
      final result = await ChannelActions.testChannel(channel.id, model: model);
      setState(() { _testResult = result; });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      setState(() { _isTesting = false; });
    }
  }

  // 清除冷却
  Future<void> _clearCooldown(Channel channel) async {
    try {
      await ChannelActions.clearCooldown(channel.id);
      ref.invalidate(channelDetailProvider(widget.channelId));
      ref.invalidate(channelListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除冷却')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // 冷却时长选择弹窗
  void _showCooldownDialog(Channel channel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置冷却时长'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[
              ('1 分钟', 60000),
              ('5 分钟', 300000),
              ('30 分钟', 1800000),
              ('1 小时', 3600000),
            ].map((item) => ListTile(
              title: Text(item.$1),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ChannelActions.setCooldown(channel.id, item.$2);
                  ref.invalidate(channelDetailProvider(widget.channelId));
                  ref.invalidate(channelListProvider);
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  // 测试结果卡片
  Widget _buildTestResultCard(ChannelTestResult result, ColorScheme colorScheme) {
    return Card(
      color: result.success ? Colors.green.withValues(alpha: 0.08) : colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(result.message, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result.success ? Colors.green : colorScheme.error,
                )),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('状态码', '${result.statusCode}'),
            _infoRow('耗时', '${result.durationMs}ms'),
            if (result.firstByteDurationMs != null)
              _infoRow('首字节', '${result.firstByteDurationMs}ms'),
            if (result.costUsd != null)
              _infoRow('费用', '\$${result.costUsd!.toStringAsFixed(6)}'),
            _infoRow('使用 Key', '#${result.testedKeyIndex} / ${result.totalKeys}'),
            if (result.responseText != null && result.responseText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.responseText!.length > 200
                      ? '${result.responseText!.substring(0, 200)}...'
                      : result.responseText!,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
