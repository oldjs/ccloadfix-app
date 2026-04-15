import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/error_view.dart';
import '../../models/summary.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _range = 'today';

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(summaryProvider(_range));
    final activeAsync = ref.watch(activeRequestsProvider);
    final versionAsync = ref.watch(versionProvider);
    final cooldownAsync = ref.watch(cooldownStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('仪表盘'),
        actions: [
          // 时间范围选择
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (v) => setState(() => _range = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'today', child: Text('今天')),
              PopupMenuItem(value: 'this_week', child: Text('本周')),
              PopupMenuItem(value: 'this_month', child: Text('本月')),
            ],
          ),
          // 手动刷新
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorView(message: err.toString(), onRetry: _refresh),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 核心指标卡片
              _buildSummaryCards(summary, colorScheme),
              const SizedBox(height: 16),

              // RPM 统计
              if (summary.rpmStats != null) ...[
                _buildSectionTitle(context, 'RPM / QPS'),
                const SizedBox(height: 8),
                _buildRpmCards(summary.rpmStats!),
                const SizedBox(height: 16),
              ],

              // 活跃请求
              _buildSectionTitle(context, '活跃请求'),
              const SizedBox(height: 8),
              activeAsync.when(
                loading: () => const Card(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )),
                error: (err, _) => Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('加载失败: $err'),
                )),
                data: (requests) => _buildActiveRequests(requests, colorScheme),
              ),
              const SizedBox(height: 16),

              // 按类型统计
              if (summary.byType.isNotEmpty) ...[
                _buildSectionTitle(context, '按渠道类型'),
                const SizedBox(height: 8),
                ...summary.byType.entries.map((e) => _buildTypeSummaryCard(e.key, e.value, colorScheme)),
              ],
              const SizedBox(height: 16),

              // 冷却状态 + 版本信息
              Row(
                children: [
                  Expanded(child: cooldownAsync.when(
                    loading: () => const StatCard(title: '冷却中', value: '...', icon: Icons.ac_unit),
                    error: (e, _) => const StatCard(title: '冷却中', value: '-', icon: Icons.ac_unit),
                    data: (stats) => StatCard(
                      title: '冷却中',
                      value: '${stats['channel_cooldowns']}',
                      icon: Icons.ac_unit,
                      iconColor: (stats['channel_cooldowns'] ?? 0) > 0 ? colorScheme.error : null,
                      subtitle: 'Key: ${stats['key_cooldowns']}',
                    ),
                  )),
                  Expanded(child: versionAsync.when(
                    loading: () => const StatCard(title: '版本', value: '...', icon: Icons.info_outline),
                    error: (e, _) => const StatCard(title: '版本', value: '-', icon: Icons.info_outline),
                    data: (version) => StatCard(
                      title: '版本',
                      value: version.version,
                      icon: version.hasUpdate ? Icons.system_update : Icons.check_circle_outline,
                      iconColor: version.hasUpdate ? colorScheme.error : Colors.green,
                      subtitle: version.hasUpdate ? '新版本: ${version.latestVersion}' : '已是最新',
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(summaryProvider(_range));
    ref.invalidate(activeRequestsProvider);
    ref.invalidate(versionProvider);
    ref.invalidate(cooldownStatsProvider);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ));
  }

  // 核心指标：总请求/成功/失败/成功率
  Widget _buildSummaryCards(Summary summary, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: StatCard(
              title: '总请求',
              value: _formatNumber(summary.totalRequests),
              icon: Icons.send,
            )),
            Expanded(child: StatCard(
              title: '成功',
              value: _formatNumber(summary.successRequests),
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: StatCard(
              title: '失败',
              value: _formatNumber(summary.errorRequests),
              icon: Icons.error_outline,
              iconColor: summary.errorRequests > 0 ? colorScheme.error : null,
            )),
            Expanded(child: StatCard(
              title: '成功率',
              value: '${(summary.successRate * 100).toStringAsFixed(1)}%',
              icon: Icons.percent,
              iconColor: summary.successRate >= 0.95 ? Colors.green : colorScheme.error,
            )),
          ],
        ),
      ],
    );
  }

  // RPM 卡片
  Widget _buildRpmCards(RpmStats rpm) {
    return Row(
      children: [
        Expanded(child: StatCard(
          title: '峰值 RPM',
          value: rpm.peakRpm.toStringAsFixed(1),
          icon: Icons.speed,
          subtitle: 'QPS: ${rpm.peakQps.toStringAsFixed(2)}',
        )),
        Expanded(child: StatCard(
          title: '平均 RPM',
          value: rpm.avgRpm.toStringAsFixed(1),
          icon: Icons.trending_flat,
          subtitle: '实时: ${rpm.recentRpm.toStringAsFixed(1)}',
        )),
      ],
    );
  }

  // 活跃请求列表
  Widget _buildActiveRequests(List<dynamic> requests, ColorScheme colorScheme) {
    if (requests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('当前无活跃请求', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 8),
                Text('${requests.length} 个活跃请求', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ...requests.take(10).map((req) => ListTile(
            dense: true,
            leading: Icon(
              req.isStreaming ? Icons.stream : Icons.http,
              size: 20,
              color: colorScheme.primary,
            ),
            title: Text(req.model, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text(req.channelName, style: const TextStyle(fontSize: 12)),
            trailing: Text('${(req.elapsedMs / 1000).toStringAsFixed(1)}s',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          )),
        ],
      ),
    );
  }

  // 按类型统计卡片
  Widget _buildTypeSummaryCard(String type, TypeSummary data, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(type.toUpperCase(), style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  )),
                ),
                const Spacer(),
                Text('\$${data.totalCost.toStringAsFixed(4)}', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat('请求', '${data.totalRequests}'),
                _buildMiniStat('成功', '${data.successRequests}'),
                _buildMiniStat('失败', '${data.errorRequests}'),
                _buildMiniStat('Input', _formatTokens(data.totalInputTokens)),
                _buildMiniStat('Output', _formatTokens(data.totalOutputTokens)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // 格式化数字
  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // 格式化 token 数
  String _formatTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
