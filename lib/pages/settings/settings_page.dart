import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/setting.dart';
import '../../widgets/error_view.dart';
import '../../core/api/api_exception.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(settingsProvider)),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.invalidate(settingsProvider)),
        data: (settings) {
          if (settings.isEmpty) {
            return Center(child: Text('暂无设置项', style: TextStyle(color: colorScheme.onSurfaceVariant)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(settingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: settings.length,
              itemBuilder: (context, index) => _SettingItem(
                setting: settings[index],
                ref: ref,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 设置项卡片
class _SettingItem extends StatelessWidget {
  final Setting setting;
  final WidgetRef ref;

  const _SettingItem({required this.setting, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Row(
          children: [
            Text(setting.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            if (setting.isModified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('已修改', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(setting.description, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('当前: ', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                Text(setting.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                if (setting.isModified) ...[
                  Text(' (默认: ${setting.defaultValue})',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditDialog(context),
              tooltip: '编辑',
            ),
            // 重置
            if (setting.isModified)
              IconButton(
                icon: Icon(Icons.restore, size: 20, color: colorScheme.error),
                onPressed: () => _confirmReset(context),
                tooltip: '恢复默认',
              ),
          ],
        ),
      ),
    );
  }

  // 编辑弹窗
  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: setting.value);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(setting.key),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(setting.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '值 (${setting.valueType})',
                hintText: '默认: ${setting.defaultValue}',
              ),
              keyboardType: setting.valueType == 'int' ? TextInputType.number : TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) return;
              try {
                await SettingsActions.update(setting.key, newValue);
                ref.invalidate(settingsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('设置已保存，服务将自动重启')),
                  );
                }
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 重置确认
  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认值'),
        content: Text('将 ${setting.key} 恢复为默认值 "${setting.defaultValue}"？\n\n服务将自动重启。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              try {
                await SettingsActions.reset(setting.key);
                ref.invalidate(settingsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已恢复默认值，服务将自动重启')),
                  );
                }
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
