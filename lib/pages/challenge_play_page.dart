import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../models/challenge.dart';
import '../services/storage_service.dart';

/// 开始挑战页：中央灯按频率闪烁，跟着节奏做动作
class ChallengePlayPage extends StatefulWidget {
  /// 总时长（分钟）
  final int totalMinutes;

  const ChallengePlayPage({super.key, required this.totalMinutes});

  @override
  State<ChallengePlayPage> createState() => _ChallengePlayPageState();
}

class _ChallengePlayPageState extends State<ChallengePlayPage>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final Random _random = Random();

  List<Challenge> _challenges = [];
  Challenge? _current;
  int _remaining = 0; // 当前挑战剩余秒
  int _totalSeconds = 0; // 总时长剩余秒
  Timer? _timer;
  bool _paused = false;

  /// 灯闪烁动画控制器
  late final AnimationController _lightController;

  /// 本轮已抽取挑战索引集合
  final Set<int> _used = {};

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalMinutes * 60;
    _lightController = AnimationController(vsync: this);
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lightController.dispose();
    FlutterOverlayWindow.closeOverlay(); // 退出时关闭悬浮窗
    super.dispose();
  }

  Future<void> _load() async {
    final challenges = await _storage.getChallenges();
    if (!mounted) return;
    if (challenges.isEmpty) {
      _showEmpty();
      return;
    }
    setState(() => _challenges = challenges);
    _drawNext();
    _setupOverlay(); // 启动悬浮窗
  }

  /// 挑战为空时提示
  Future<void> _showEmpty() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('暂无挑战'),
        content: const Text('请先到「自定义挑战」里添加挑战。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// 随机抽取下一个挑战
  void _drawNext() {
    final available = <int>[
      for (var i = 0; i < _challenges.length; i++)
        if (!_used.contains(i)) i,
    ];
    if (available.isEmpty) {
      _used.clear();
      _drawNext();
      return;
    }
    final idx = available[_random.nextInt(available.length)];
    _used.add(idx);
    final c = _challenges[idx];
    setState(() {
      _current = c;
      _remaining = c.seconds;
    });
    _startLight(c.bpm);
    _startTimer();
    _updateOverlay();
  }

  /// 启动灯闪烁（周期 = 60/BPM 秒）
  void _startLight(int bpm) {
    _lightController.stop();
    _lightController.duration =
        Duration(milliseconds: (60000 / bpm).round());
    _lightController.repeat(reverse: true);
  }

  /// 启动倒计时（每秒 tick）
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      _remaining--;
      _totalSeconds--;
      if (_totalSeconds < 0) _totalSeconds = 0;
    });
    // 总时长归零优先
    if (_totalSeconds <= 0) {
      _finish();
      return;
    }
    // 单挑战归零 → 抽下一个
    if (_remaining <= 0) {
      _drawNext();
    } else {
      _updateOverlay();
    }
  }

  /// 总时长结束：弹"挑战结束"，点返回回主页
  Future<void> _finish() async {
    _timer?.cancel();
    _lightController.stop();
    await FlutterOverlayWindow.closeOverlay(); // 关闭悬浮窗
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('挑战结束'),
        content: const Text('本次频率挑战已完成。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// 暂停 / 继续
  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
      _lightController.stop();
    } else {
      _startTimer();
      _lightController.repeat(reverse: true);
    }
  }

  /// 跳过
  void _skip() {
    _drawNext();
  }

  /// 剩余总时长文本，格式 分:秒
  String get _totalTimeText {
    final m = _totalSeconds ~/ 60;
    final s = _totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ===== 悬浮窗 =====

  /// 请求权限并显示悬浮窗
  Future<void> _setupOverlay() async {
    try {
      var granted = await FlutterOverlayWindow.isPermissionGranted();
      if (!granted) {
        await FlutterOverlayWindow.requestPermission();
        granted = await FlutterOverlayWindow.isPermissionGranted();
      }
      if (!granted) return; // 用户拒绝，不显示悬浮窗
      await FlutterOverlayWindow.showOverlay(
        height: 110,
        width: 340,
        alignment: OverlayAlignment.topCenter,
        enableDrag: true,
        // 指定初始 y 坐标，避免插件默认的负状态栏高度偏移导致悬浮窗在屏幕外
        startPosition: const OverlayPosition(0, 100),
        overlayTitle: '频率挑战',
        overlayContent: '正在进行挑战',
      );
      _updateOverlay();
    } catch (e) {
      debugPrint('悬浮窗启动失败: $e');
    }
  }

  /// 同步数据到悬浮窗
  void _updateOverlay() {
    final c = _current;
    if (c == null) return;
    FlutterOverlayWindow.shareData({
      'seconds': _remaining,
      'total': _totalTimeText,
      'color': c.color.toARGB32(),
      'bpm': c.bpm,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _current;
    return Scaffold(
      appBar: AppBar(
        title: Text(c == null ? '开始挑战' : '${c.name} · ${c.bpm} 次/分钟'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            // 中央灯（脉冲闪烁）
            AnimatedBuilder(
              animation: _lightController,
              builder: (context, child) {
                final v = _lightController.value;
                return Transform.scale(
                  scale: 0.85 + 0.15 * v,
                  child: Opacity(
                    opacity: 0.08 + 0.92 * v,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: c?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (c?.color ?? Colors.grey).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // 当前挑战倒计时
            Text(
              '$_remaining',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 剩余总时长
            Text(
              '剩余总时长 $_totalTimeText',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(),
            // 暂停/继续 + 跳过
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_paused ? '继续' : '暂停'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _paused ? null : _skip,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('跳过'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
