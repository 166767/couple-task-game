import 'dart:async';

import 'package:flutter/material.dart';

import 'models/difficulty.dart';
import 'overlay/challenge_overlay.dart';
import 'pages/splash_page.dart';
import 'services/storage_service.dart';
import 'theme.dart';

/// 全局主题状态：设置页切换主题时更新，MaterialApp 即时响应
final ValueNotifier<AppTheme> themeNotifier =
    ValueNotifier<AppTheme>(AppThemes.all.first);

/// 应用入口：先初始化本地存储（首次内置示例任务包），再启动界面。
/// 初始化异常或超时都不会阻塞启动，避免因存储插件问题导致黑屏。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  try {
    await storage.init().timeout(const Duration(seconds: 5));
    // 读取已保存的主题
    final themeId = await storage.getThemeId();
    themeNotifier.value = AppThemes.byId(themeId);
    // 读取自定义难度名称
    final names = await storage.getDifficultyNames();
    difficultyNames.value = {
      for (final d in Difficulty.values) d: names[d.name] ?? d.defaultLabel,
    };
  } catch (e) {
    // 初始化失败不阻塞启动：进入主页后若任务包为空，会提示"请先导入任务包"
    debugPrint('存储初始化失败（继续启动）: $e');
  }
  runApp(const TaskAdventureApp());
}

/// 悬浮窗入口（由 flutter_overlay_window 在独立引擎中调用）
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChallengeOverlay(),
  ));
}

class TaskAdventureApp extends StatelessWidget {
  const TaskAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听主题切换，动态重建 MaterialApp
    return ValueListenableBuilder<AppTheme>(
      valueListenable: themeNotifier,
      builder: (context, theme, _) {
        return MaterialApp(
          title: '任务大冒险',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(theme),
          home: const SplashPage(),
        );
      },
    );
  }
}
