import 'package:flutter/material.dart';

/// 一套配色主题
class AppTheme {
  final String id;
  final String name;

  /// 深色背景
  final Color background;

  /// 表面色（卡片、弹窗）
  final Color surface;

  /// 强调色（高饱和）
  final Color accent;

  const AppTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.accent,
  });
}

/// 全部可选主题
class AppThemes {
  AppThemes._();

  static const List<AppTheme> all = [
    AppTheme(
      id: 'pink',
      name: '暗夜粉',
      background: Color(0xFF16161A),
      surface: Color(0xFF202027),
      accent: Color(0xFFFF1493),
    ),
    AppTheme(
      id: 'gold',
      name: '鎏金黑',
      background: Color(0xFF0D0D0F),
      surface: Color(0xFF1A1A1E),
      accent: Color(0xFFFFC107),
    ),
    AppTheme(
      id: 'cyan',
      name: '深海青',
      background: Color(0xFF0F141A),
      surface: Color(0xFF1A2129),
      accent: Color(0xFF00E5FF),
    ),
    AppTheme(
      id: 'violet',
      name: '暗夜紫',
      background: Color(0xFF14121A),
      surface: Color(0xFF1E1A26),
      accent: Color(0xFFB388FF),
    ),
    AppTheme(
      id: 'green',
      name: '森林绿',
      background: Color(0xFF0F1A14),
      surface: Color(0xFF17241C),
      accent: Color(0xFF00E676),
    ),
    AppTheme(
      id: 'orange',
      name: '落日橙',
      background: Color(0xFF1A1010),
      surface: Color(0xFF241715),
      accent: Color(0xFFFF6D00),
    ),
  ];

  /// 按 id 查找主题，找不到回退到第一套
  static AppTheme byId(String? id) {
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }
}

/// 根据主题构建 ThemeData（深色 + 强调色）
ThemeData buildAppTheme(AppTheme theme) {
  final base = ColorScheme.fromSeed(
    seedColor: theme.accent,
    brightness: Brightness.dark,
    // vibrant 变体让强调色更鲜艳、饱和度更高
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  // 覆盖 primary 为精确的强调色
  final colorScheme = base.copyWith(primary: theme.accent);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: theme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: theme.background,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: theme.surface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: theme.surface,
    ),
  );
}
