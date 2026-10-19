import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/storage_service.dart';

/// 应用入口：先初始化本地存储（首次内置示例任务包），再启动界面
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const TaskAdventureApp());
}

class TaskAdventureApp extends StatelessWidget {
  const TaskAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '任务大冒险',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
