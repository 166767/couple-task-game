import 'package:flutter/foundation.dart';

/// 全局难度显示名称（设置页可自定义，即时生效）
final ValueNotifier<Map<Difficulty, String>> difficultyNames =
    ValueNotifier<Map<Difficulty, String>>({});

/// 任务难度枚举
enum Difficulty {
  /// 简单
  easy,

  /// 普通
  normal,

  /// 困难
  hard,

  /// 极难
  extreme;

  /// 默认中文名（也用于 txt 章节标记，固定不变）
  String get defaultLabel => switch (this) {
        Difficulty.easy => '简单',
        Difficulty.normal => '普通',
        Difficulty.hard => '困难',
        Difficulty.extreme => '极难',
      };

  /// 显示名称（可被用户自定义覆盖，未自定义时用默认名）
  String get label => difficultyNames.value[this] ?? defaultLabel;

  /// 章节标记，如 [简单]（txt 导入固定用默认名，不受自定义影响）
  String get sectionTag => '[$defaultLabel]';

  /// 根据章节标记解析难度，不匹配返回 null
  static Difficulty? fromSectionTag(String line) {
    for (final d in Difficulty.values) {
      if (line == d.sectionTag) {
        return d;
      }
    }
    return null;
  }
}
