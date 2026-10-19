import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/task.dart';
import '../models/task_pack.dart';
import '../theme.dart';

/// 游戏页：大字显示任务，单任务倒计时 + 进度条，总时长倒计时
class GamePage extends StatefulWidget {
  final Difficulty difficulty;
  final int totalMinutes;
  final TaskPack pack;

  const GamePage({
    super.key,
    required this.difficulty,
    required this.totalMinutes,
    required this.pack,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Random _random = Random();

  Timer? _timer;
  int _totalSeconds = 0;
  int _taskRemaining = 0;
  Task? _currentTask;

  /// 本轮已抽取任务索引集合（索引相对当前难度列表）
  final Set<int> _used = {};

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalMinutes * 60;
    _drawNextTask();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 每秒回调
  void _tick() {
    setState(() {
      _totalSeconds--;
      if (_totalSeconds < 0) _totalSeconds = 0;
      _taskRemaining--;
    });

    // 总时长归零优先
    if (_totalSeconds <= 0) {
      _finish();
      return;
    }
    // 单任务归零 → 自动抽下一个
    if (_taskRemaining <= 0) {
      _drawNextTask();
    }
  }

  /// 总时长结束：弹"时间到"，确定后返回主页
  Future<void> _finish() async {
    _timer?.cancel();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('时间到'),
        content: const Text('本次游戏已结束。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 随机抽取下一个任务（本轮已抽过的不再出现）
  void _drawNextTask() {
    final list = widget.pack.tasksOf(widget.difficulty);
    final available = <int>[
      for (var i = 0; i < list.length; i++)
        if (!_used.contains(i)) i,
    ];

    if (available.isEmpty) {
      // 该难度任务全部抽完：暂停并弹提示，确定后重置重新洗牌继续
      _timer?.cancel();
      _showExhausted();
      return;
    }

    final idx = available[_random.nextInt(available.length)];
    _used.add(idx);
    setState(() {
      _currentTask = list[idx];
      _taskRemaining = list[idx].seconds;
    });
  }

  /// 该难度任务已抽完：弹提示，确定后重置本轮集合并继续
  Future<void> _showExhausted() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('该难度任务已抽完'),
        content: const Text('将重新洗牌，继续抽取任务。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    _used.clear(); // 重置本轮已抽取集合
    _drawNextTask();
    if (_totalSeconds > 0) {
      _startTimer();
    }
  }

  /// 跳过：立即随机抽取下一个任务
  void _skip() {
    _drawNextTask();
  }

  /// 剩余总时长文本，格式 分:秒
  String get _totalTimeText {
    final m = _totalSeconds ~/ 60;
    final s = _totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    final progress = (task == null || task.seconds <= 0)
        ? 0.0
        : (_taskRemaining / task.seconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.difficulty.label} · 剩余 $_totalTimeText'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 任务内容大字显示
            Expanded(
              child: Center(
                child: Text(
                  task?.content ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 倒计时数字
            Text(
              '$_taskRemaining',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            // 倒计时进度条（满 -> 空）
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 32),
            // 跳过按钮
            FilledButton.icon(
              onPressed: _skip,
              icon: const Icon(Icons.skip_next),
              label: const Text('跳过'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
