import '../models/difficulty.dart';
import '../models/task.dart';
import '../models/task_pack.dart';

/// TXT 任务包解析器
///
/// 格式规则：
/// - 用 [简单] [普通] [困难] [极难] 四节标记分区，顺序不限、可缺省
/// - 每行一个任务，格式 `任务内容|时长`
/// - 时长：纯数字=秒；`30秒`、`2分钟` 自动换算成秒；不写默认 30 秒
/// - 空行自动忽略
class TxtParser {
  /// 默认单任务时长（秒）
  static const int defaultSeconds = 30;

  /// 解析 TXT 内容，[name] 为任务包名；格式错误抛出 [FormatException]
  static TaskPack parse(String name, String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final tasks = <Difficulty, List<Task>>{};

    Difficulty? current;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue; // 空行忽略
      }

      // 章节标记
      final section = Difficulty.fromSectionTag(line);
      if (section != null) {
        current = section;
        tasks.putIfAbsent(section, () => []);
        continue;
      }

      // 任务行：必须位于某个章节之下
      if (current == null) {
        throw FormatException('任务必须位于难度标记之后');
      }

      final task = _parseTaskLine(line, current);
      tasks[current]!.add(task);
    }

    if (tasks.isEmpty) {
      throw FormatException('文件为空或未包含任何难度标记');
    }

    return TaskPack(name: name, tasks: tasks);
  }

  /// 解析单行任务：内容|时长
  static Task _parseTaskLine(String line, Difficulty difficulty) {
    final pipeIndex = line.indexOf('|');
    String content;
    String? durationStr;
    if (pipeIndex < 0) {
      content = line;
      durationStr = null;
    } else {
      content = line.substring(0, pipeIndex);
      durationStr = line.substring(pipeIndex + 1);
    }

    content = content.trim();
    if (content.isEmpty) {
      throw FormatException('任务内容不能为空');
    }

    final seconds = durationStr == null
        ? defaultSeconds
        : _parseDuration(durationStr.trim());

    return Task(content: content, seconds: seconds, difficulty: difficulty);
  }

  /// 解析时长：纯数字=秒；`30秒`；`2分钟`
  static int _parseDuration(String s) {
    if (s.isEmpty) {
      return defaultSeconds;
    }
    // 纯数字
    if (RegExp(r'^\d+$').hasMatch(s)) {
      return int.parse(s);
    }
    // 带单位
    final match = RegExp(r'^(\d+)\s*(秒|分钟)$').firstMatch(s);
    if (match == null) {
      throw FormatException('时长格式错误: $s');
    }
    final value = int.parse(match.group(1)!);
    final unit = match.group(2)!;
    return unit == '分钟' ? value * 60 : value;
  }

  /// 将任务包序列化为 TXT 字符串（格式与导入一致，便于导出分享）
  static String encode(TaskPack pack) {
    final buffer = StringBuffer();
    for (final d in Difficulty.values) {
      final tasks = pack.tasksOf(d);
      if (tasks.isEmpty) continue;
      buffer.writeln(d.sectionTag);
      for (final t in tasks) {
        buffer.writeln('${t.content}|${t.seconds}');
      }
      buffer.writeln();
    }
    return '${buffer.toString().trimRight()}\n';
  }
}
