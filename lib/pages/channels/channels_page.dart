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
              padding: const EdgeInsets.all(12),
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

// 渠道卡片
class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final ValueChanged<bool> onToggle;

  const _ChannelCard({required this.channel, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 状态颜色
    Color statusColor;
    if (!channel.enabled) {
      statusColor = colorScheme.outline;
    } else if (channel.isInCooldown) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/channels/${channel.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：状态灯 + 名称 + 开关
              Row(
                children: [
                  // 状态指示灯
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 渠道名
                  Expanded(
                    child: Text(channel.name, style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ), overflow: TextOverflow.ellipsis),
                  ),
                  // 启用开关
                  Switch(
                    value: channel.enabled,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 第二行：标签信息
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(context, channel.channelType.toUpperCase(), colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                  _buildTag(context, 'P:${channel.priority}', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                  _buildTag(context, '${channel.keyCount} Key', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                  _buildTag(context, '${channel.models.length} Model', colorScheme.surfaceContainerHigh, colorScheme.onSurface),
                  if (channel.isInCooldown)
                    _buildTag(context, '冷却中', colorScheme.errorContainer, colorScheme.onErrorContainer),
                ],
              ),
              // 第三行：成功率
              if (channel.successRate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: channel.successRate!,
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          color: channel.successRate! >= 0.95 ? Colors.green : Colors.orange,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(channel.successRate! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
