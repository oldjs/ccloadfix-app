import 'package:flutter/material.dart';

// 占位，Step 4 填充
class ChannelDetailPage extends StatelessWidget {
  final int channelId;
  const ChannelDetailPage({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('渠道 #$channelId')),
      body: const Center(child: Text('ChannelDetailPage placeholder')),
    );
  }
}
