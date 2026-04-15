import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/stats_provider.dart';
import '../../models/stats.dart';
import '../../widgets/error_view.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  String _range = 'today';
  // 图表展示维度
  _ChartMode _chartMode = _ChartMode.requests;

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(metricsProvider(_range));
    final statsAsync = ref.watch(statsProvider(_range));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (v) => setState(() => _range = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'today', child: Text('今天')),
              PopupMenuItem(value: 'this_week', child: Text('本周')),
              PopupMenuItem(value: 'this_month', child: Text('本月')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(metricsProvider(_range));
              ref.invalidate(statsProvider(_range));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(metricsProvider(_range));
          ref.invalidate(statsProvider(_range));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 图表维度切换
            SegmentedButton<_ChartMode>(
              segments: const [
                ButtonSegment(value: _ChartMode.requests, label: Text('请求量')),
                ButtonSegment(value: _ChartMode.latency, label: Text('延迟')),
                ButtonSegment(value: _ChartMode.cost, label: Text('费用')),
                ButtonSegment(value: _ChartMode.tokens, label: Text('Token')),
              ],
              selected: {_chartMode},
              onSelectionChanged: (s) => setState(() => _chartMode = s.first),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 16),

            // 时间线图表
            metricsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SizedBox(
                height: 200,
                child: ErrorView(message: err.toString()),
              ),
              data: (metrics) => _buildChart(metrics, colorScheme),
            ),
            const SizedBox(height: 24),

            // 渠道+模型统计表格
            Text('渠道统计', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(message: err.toString()),
              data: (statsResp) => _buildStatsTable(statsResp, colorScheme),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 时间线图表
  Widget _buildChart(List<MetricBucket> metrics, ColorScheme colorScheme) {
    if (metrics.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('暂无数据', style: TextStyle(color: colorScheme.onSurfaceVariant))),
      );
    }

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: _buildLineChart(metrics, colorScheme),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<MetricBucket> metrics, ColorScheme colorScheme) {
    // 根据维度取 Y 值
    List<FlSpot> primarySpots = [];
    List<FlSpot> secondarySpots = [];
    String yLabel = '';

    for (int i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      switch (_chartMode) {
        case _ChartMode.requests:
          primarySpots.add(FlSpot(i.toDouble(), m.success.toDouble()));
          secondarySpots.add(FlSpot(i.toDouble(), m.error.toDouble()));
          yLabel = '请求数';
        case _ChartMode.latency:
          primarySpots.add(FlSpot(i.toDouble(), m.avgDuration));
          secondarySpots.add(FlSpot(i.toDouble(), m.avgFirstByteTime));
          yLabel = '秒';
        case _ChartMode.cost:
          primarySpots.add(FlSpot(i.toDouble(), m.totalCost));
          yLabel = 'USD';
        case _ChartMode.tokens:
          primarySpots.add(FlSpot(i.toDouble(), m.inputTokens.toDouble()));
          secondarySpots.add(FlSpot(i.toDouble(), m.outputTokens.toDouble()));
          yLabel = 'Tokens';
      }
    }

    final lines = <LineChartBarData>[
      LineChartBarData(
        spots: primarySpots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: colorScheme.primary,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    ];

    // 第二条线（如果有）
    if (secondarySpots.isNotEmpty) {
      lines.add(LineChartBarData(
        spots: secondarySpots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: _chartMode == _ChartMode.requests ? colorScheme.error : Colors.orange,
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lines,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(primarySpots),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (metrics.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= metrics.length) return const SizedBox.shrink();
                final dt = metrics[idx].dateTime;
                return Text(
                  DateFormat('HH:mm').format(dt),
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(yLabel, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(_formatAxisValue(value), style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final dt = idx < metrics.length ? metrics[idx].dateTime : DateTime.now();
                final timeStr = DateFormat('HH:mm').format(dt);
                return LineTooltipItem(
                  '$timeStr\n${_formatAxisValue(spot.y)}',
                  TextStyle(fontSize: 11, color: spot.bar.color),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // 计算 Y 轴间隔
  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) return 1;
    return (maxY / 4).ceilToDouble().clamp(1, double.infinity);
  }

  // 格式化轴上的数值
  String _formatAxisValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value >= 1) return value.toStringAsFixed(1);
    if (value > 0) return value.toStringAsFixed(3);
    return '0';
  }

  // 渠道统计表格
  Widget _buildStatsTable(StatsResponse resp, ColorScheme colorScheme) {
    if (resp.stats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('暂无统计数据', style: TextStyle(color: colorScheme.onSurfaceVariant))),
        ),
      );
    }

    // 按渠道分组
    final grouped = <String, List<ChannelStats>>{};
    for (final s in resp.stats) {
      grouped.putIfAbsent(s.channelName, () => []).add(s);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final channelName = entry.key;
        final models = entry.value;
        // 汇总
        final totalReqs = models.fold(0, (sum, s) => sum + s.total);
        final totalSuccess = models.fold(0, (sum, s) => sum + s.success);
        final totalCost = models.fold(0.0, (sum, s) => sum + s.totalCost);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(channelName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '请求: $totalReqs | 成功率: ${totalReqs > 0 ? (totalSuccess / totalReqs * 100).toStringAsFixed(1) : 0}% | 费用: \$${totalCost.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
            children: models.map((s) => _buildModelRow(s, colorScheme)).toList(),
          ),
        );
      }).toList(),
    );
  }

  // 模型行
  Widget _buildModelRow(ChannelStats s, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模型名
          Text(s.model, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          // 指标
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _miniStat('请求', '${s.total}'),
              _miniStat('成功率', '${(s.successRate * 100).toStringAsFixed(1)}%'),
              _miniStat('平均耗时', '${s.avgDuration.toStringAsFixed(2)}s'),
              _miniStat('TTFB', '${s.avgFirstByteTime.toStringAsFixed(2)}s'),
              _miniStat('费用', '\$${s.totalCost.toStringAsFixed(4)}'),
              _miniStat('RPM', s.recentRpm.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

enum _ChartMode { requests, latency, cost, tokens }
