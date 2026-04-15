import 'package:flutter/material.dart';

// 占位，Step 5 填充
class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日志')),
      body: const Center(child: Text('LogsPage placeholder')),
    );
  }
}
