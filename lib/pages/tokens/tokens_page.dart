import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/token_provider.dart';
import '../../models/auth_token.dart';
import '../../widgets/error_view.dart';
import '../../core/api/api_exception.dart';

class TokensPage extends ConsumerWidget {
  const TokensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(tokenListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Token'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(tokenListProvider)),
        ],
      ),
      // 新建 Token
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tokensAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.invalidate(tokenListProvider)),
        data: (tokens) {
          if (tokens.isEmpty) {
            return Center(child: Text('暂无 Token', style: TextStyle(color: colorScheme.onSurfaceVariant)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tokenListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tokens.length,
              itemBuilder: (context, index) => _TokenCard(token: tokens[index], ref: ref),
            ),
          );
        },
      ),
    );
  }

  // 创建 Token 弹窗
  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建 API Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述', hintText: '如：测试用'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              decoration: const InputDecoration(labelText: '费用限额 (USD)', hintText: '留空表示无限制'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final desc = descController.text.trim();
              if (desc.isEmpty) return;

              try {
                final costLimit = costController.text.isNotEmpty ? double.tryParse(costController.text) : null;
                final result = await TokenActions.create(description: desc, costLimitUsd: costLimit);
                ref.invalidate(tokenListProvider);
                if (ctx.mounted) Navigator.pop(ctx);

                // 弹出 token 值让用户复制
                if (result.token != null && context.mounted) {
                  _showTokenValue(context, result.token!);
                }
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  // 显示新创建的 token 值
  void _showTokenValue(BuildContext context, String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Token 已创建'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请立即复制，此 Token 值不会再次显示：', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(token, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy),
            label: const Text('复制并关闭'),
          ),
        ],
      ),
    );
  }
}

// Token 卡片
class _TokenCard extends StatelessWidget {
  final AuthToken token;
  final WidgetRef ref;

  const _TokenCard({required this.token, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述 + 启用开关
            Row(
              children: [
                // 状态指示灯
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: token.isActive ? Colors.green : colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(token.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                ),
                // 启停开关
                Switch(
                  value: token.isActive,
                  onChanged: (v) async {
                    try {
                      await TokenActions.update(token.id, isActive: v);
                      ref.invalidate(tokenListProvider);
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 指标行
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _stat('请求', '${token.totalRequests}'),
                _stat('成功率', '${(token.successRate * 100).toStringAsFixed(1)}%'),
                _stat('费用', '\$${token.totalCostUsd.toStringAsFixed(4)}'),
                if (token.costLimitUsd != null)
                  _stat('限额', '\$${token.costLimitUsd!.toStringAsFixed(2)}'),
                _stat('RPM', token.recentRpm.toStringAsFixed(1)),
              ],
            ),
            // 模型限制
            if (token.allowedModels != null && token.allowedModels!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: token.allowedModels!.map((m) => Chip(
                  label: Text(m, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
            const SizedBox(height: 4),
            // 删除按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: Icon(Icons.delete_outline, size: 16, color: colorScheme.error),
                label: Text('删除', style: TextStyle(fontSize: 12, color: colorScheme.error)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 Token "${token.description}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              try {
                await TokenActions.delete(token.id);
                ref.invalidate(tokenListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
