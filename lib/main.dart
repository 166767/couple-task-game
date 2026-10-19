import 'dart:async';

import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/storage_service.dart';
import 'theme.dart';

/// 应用入口：先初始化本地存储（首次内置示例任务包），再启动界面。
/// 初始化异常或超时都不会阻塞启动，避免因存储插件问题导致黑屏。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService().init().timeout(const Duration(seconds: 5));
  } catch (e) {
    // 初始化失败不阻塞启动：进入主页后若任务包为空，会提示"请先导入任务包"
    debugPrint('存储初始化失败（继续启动）: $e');
  }
  runApp(const TaskAdventureApp());
}

class TaskAdventureApp extends StatelessWidget {
  const TaskAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '任务大冒险',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashPage(),
    );
  }
}
