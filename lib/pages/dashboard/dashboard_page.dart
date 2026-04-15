import 'package:flutter/material.dart';

// 占位，Step 3 填充
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仪表盘')),
      body: const Center(child: Text('DashboardPage placeholder')),
    );
  }
}
