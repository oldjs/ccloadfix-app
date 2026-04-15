import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/channel_provider.dart';
import '../../models/channel.dart';
import '../../widgets/error_view.dart';

class ChannelsPage extends ConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('渠道'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(channelListProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(channelListProvider),
        child: channelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(channelListProvider),
          ),
          data: (channels) {
            if (channels.isEmpty) {
              return Center(
                child: Text('暂无渠道', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: channels.length,
              itemBuilder: (context, index) => _ChannelCard(
                channel: channels[index],
                onToggle: (enabled) async {
                  await ChannelActions.toggleEnabled(channels[index].id, enabled);
                  ref.invalidate(channelListProvider);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// 渠道类型对应的颜色，参考 web 前端
Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'anthropic': return const Color(0xFF8B5CF6); // 紫色
    case 'codex':     return const Color(0xFF059669); // 深绿
    case 'openai':    return const Color(0xFF10B981); // 绿色
    case 'gemini':    return const Color(0xFF2563EB); // 蓝色
    default:          return const Color(0xFF6B7280); // 灰色
  }
}

Color _typeBg(String type) {
  switch (type.toLowerCase()) {
    case 'anthropic': return const Color(0xFFF3E8FF);
    case 'codex':     return const Color(0xFFD1FAE5);
    case 'openai':    return const Color(0xFFD1FAE5);
    case 'gemini':    return const Color(0xFFDBEAFE);
    default:          return const Color(0xFFF3F4F6);
  }
}

// 渠道卡片
class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final ValueChanged<bool> onToggle;

  const _ChannelCard({required this.channel, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDisabled = !channel.enabled;
    final isCooling = channel.isInCooldown;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go('/channels/${channel.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：类型标签 + 名称 + 开关
              Row(
                children: [
                  // 渠道类型标签 — 参考 web 前端配色
                  _TypeBadge(type: channel.channelType),
                  const SizedBox(width: 8),
                  // 渠道名
                  Expanded(
                    child: Text(channel.name, style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? cs.onSurfaceVariant : cs.onSurface,
                    ), overflow: TextOverflow.ellipsis),
                  ),
                  // 禁用/冷却状态
                  if (isDisabled)
                    _StatusChip(label: '已禁用', color: cs.outline)
                  else if (isCooling)
                    _StatusChip(label: '冷却中', color: cs.error),
                  // 启用开关
                  SizedBox(
                    height: 32,
                    child: FittedBox(
                      child: Switch(value: channel.enabled, onChanged: onToggle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 第二行：优先级 + Key/Model 数 + 首个模型名
              Row(
                children: [
                  // 优先级 — 醒目的数字
                  _PriorityBadge(
                    priority: channel.priority,
                    effectivePriority: channel.effectivePriority,
                  ),
                  const SizedBox(width: 10),
                  // Key 数
                  _MetaChip(icon: Icons.key, label: '${channel.keyCount}', cs: cs),
                  const SizedBox(width: 8),
                  // Model 数
                  _MetaChip(icon: Icons.layers_outlined, label: '${channel.models.length}', cs: cs),
                  const SizedBox(width: 8),
                  // URL 数（多 URL 渠道才显示）
                  if (channel.urlCount > 1) ...[
                    _MetaChip(icon: Icons.link, label: '${channel.urlCount}', cs: cs),
                    const SizedBox(width: 8),
                  ],
                  // 首个模型名
                  if (channel.models.isNotEmpty)
                    Expanded(
                      child: Text(
                        channel.models.first.model,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              // 第三行：成功率进度条
              if (channel.successRate != null) ...[
                const SizedBox(height: 10),
                _SuccessRateBar(rate: channel.successRate!, cs: cs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 渠道类型标签 — web 前端同款配色
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    final bg = _typeBg(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
      ),
    );
  }
}

// 优先级徽章
class _PriorityBadge extends StatelessWidget {
  final int priority;
  final double? effectivePriority;
  const _PriorityBadge({required this.priority, this.effectivePriority});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 有效优先级跟基础优先级差异大时高亮
    final hasHealthDiff = effectivePriority != null &&
        (effectivePriority! - priority).abs() > 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('P', style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer, fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
          Text('$priority', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSecondaryContainer,
          )),
          // 有效优先级不同时，显示实际值
          if (hasHealthDiff) ...[
            Icon(Icons.arrow_right_alt, size: 12, color: cs.onSecondaryContainer),
            Text(effectivePriority!.toStringAsFixed(0), style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: effectivePriority! < priority ? cs.error : Colors.green,
            )),
          ],
        ],
      ),
    );
  }
}

// 小指标标签 (Key 数 / Model 数 / URL 数)
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _MetaChip({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// 状态标签 (禁用/冷却)
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// 成功率进度条
class _SuccessRateBar extends StatelessWidget {
  final double rate;
  final ColorScheme cs;
  const _SuccessRateBar({required this.rate, required this.cs});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 0.95 ? Colors.green
        : rate >= 0.8 ? Colors.orange
        : Colors.red;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerHigh,
              color: color,
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(rate * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
