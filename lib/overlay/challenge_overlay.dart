import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// 悬浮窗：显示当前频率剩余时间、剩余总时间、频率灯
class ChallengeOverlay extends StatefulWidget {
  const ChallengeOverlay({super.key});

  @override
  State<ChallengeOverlay> createState() => _ChallengeOverlayState();
}

class _ChallengeOverlayState extends State<ChallengeOverlay>
    with SingleTickerProviderStateMixin {
  int _seconds = 0;
  String _totalText = '00:00';
  Color _color = const Color(0xFFFF5252);
  int _bpm = 80;

  late final AnimationController _lightController;
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    _lightController = AnimationController(vsync: this);
    // 监听游戏页发来的数据
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
    _startLight();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _lightController.dispose();
    super.dispose();
  }

  void _onData(dynamic data) {
    if (data is! Map) return;
    final newBpm = (data['bpm'] as num?)?.toInt() ?? _bpm;
    setState(() {
      _seconds = (data['seconds'] as num?)?.toInt() ?? _seconds;
      _totalText = data['total'] as String? ?? _totalText;
      final colorValue = (data['color'] as num?)?.toInt();
      if (colorValue != null) _color = Color(colorValue);
    });
    if (newBpm != _bpm) {
      _bpm = newBpm;
      _startLight();
    }
  }

  void _startLight() {
    _lightController.stop();
    _lightController.duration =
        Duration(milliseconds: (60000 / _bpm).round());
    _lightController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 频率灯
            AnimatedBuilder(
              animation: _lightController,
              builder: (context, child) => Opacity(
                opacity: 0.1 + 0.9 * _lightController.value,
                child: child,
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 右侧两行文字：当前秒数 + 剩余总时间
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_seconds 秒',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '总 $_totalText',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
