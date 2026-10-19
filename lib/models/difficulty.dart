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

  /// 中文名称
  String get label => switch (this) {
        Difficulty.easy => '简单',
        Difficulty.normal => '普通',
        Difficulty.hard => '困难',
        Difficulty.extreme => '极难',
      };

  /// 章节标记，如 [简单]
  String get sectionTag => '[$label]';

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
