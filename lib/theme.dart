import 'package:flutter/material.dart';

/// 全局配色：深灰偏黑背景 + 高饱和艳粉强调
class AppColors {
  AppColors._();

  /// 高饱和艳粉（强调色）
  static const Color accent = Color(0xFFFF1493);

  /// 深灰偏黑背景
  static const Color background = Color(0xFF16161A);

  /// 深灰表面色（卡片、弹窗）
  static const Color surface = Color(0xFF202027);
}

/// 构建应用主题（深色 + 艳粉）
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      // vibrant 变体让粉色更鲜艳、饱和度更高
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
    ),
  );
}
