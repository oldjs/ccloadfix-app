import 'package:flutter/material.dart';

// 占位，Step 7 填充
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: const Center(child: Text('SettingsPage placeholder')),
    );
  }
}
