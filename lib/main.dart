import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_storage.dart';
import 'app.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化本地存储
  await LocalStorage.init();

  runApp(const ProviderScope(child: CcloadfixApp()));
}
