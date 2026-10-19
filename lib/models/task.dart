import 'difficulty.dart';

/// 任务模型：一条文本 + 一个时长（秒）+ 一个所属难度
class Task {
  /// 任务文字
  final String content;

  /// 时长（秒）
  final int seconds;

  /// 所属难度
  final Difficulty difficulty;

  Task({
    required this.content,
    required this.seconds,
    required this.difficulty,
  });

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'content': content,
        'seconds': seconds,
        'difficulty': difficulty.name,
      };

  /// 从 JSON 反序列化
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        content: json['content'] as String,
        seconds: json['seconds'] as int,
        difficulty: Difficulty.values.byName(json['difficulty'] as String),
      );
}
