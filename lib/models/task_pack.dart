import 'difficulty.dart';
import 'task.dart';

/// 任务包模型：名称 + 四个难度的任务列表
class TaskPack {
  /// 任务包名称
  final String name;

  /// 各难度对应的任务列表
  final Map<Difficulty, List<Task>> tasks;

  TaskPack({required this.name, required this.tasks});

  /// 获取指定难度的任务列表
  List<Task> tasksOf(Difficulty difficulty) => tasks[difficulty] ?? const [];

  /// 任务包是否为空（四个难度都没有任务）
  bool get isEmpty {
    for (final d in Difficulty.values) {
      if (tasksOf(d).isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'tasks': [
          for (final entry in tasks.entries)
            for (final t in entry.value) t.toJson(),
        ],
      };

  /// 从 JSON 反序列化
  factory TaskPack.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final map = <Difficulty, List<Task>>{
      for (final d in Difficulty.values) d: <Task>[],
    };
    final rawTasks = json['tasks'] as List<dynamic>? ?? const [];
    for (final raw in rawTasks) {
      final task = Task.fromJson(raw as Map<String, dynamic>);
      map[task.difficulty]!.add(task);
    }
    return TaskPack(name: name, tasks: map);
  }
}
