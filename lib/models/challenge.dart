import 'package:flutter/material.dart';

/// 频率挑战的灯颜色列表（颜色多一些，供用户自定义选择）
class ChallengeColors {
  ChallengeColors._();

  static const List<Color> all = [
    Color(0xFFFF5252), // 红
    Color(0xFFFF9800), // 橙
    Color(0xFFFFEB3B), // 黄
    Color(0xFF69F0AE), // 绿
    Color(0xFF00E5FF), // 青
    Color(0xFF448AFF), // 蓝
    Color(0xFFB388FF), // 紫
    Color(0xFFFF1493), // 粉
    Color(0xFFFFFFFF), // 白
    Color(0xFFFFC107), // 琥珀
  ];
}

/// 频率档位（预设）
class FrequencyPreset {
  final String name;
  final int bpm;

  const FrequencyPreset({required this.name, required this.bpm});
}

/// 默认频率档位（BPM = 每分钟闪烁次数，类似节拍器）
class FrequencyPresets {
  FrequencyPresets._();

  static const List<FrequencyPreset> all = [
    FrequencyPreset(name: '散步', bpm: 40),
    FrequencyPreset(name: '慢速', bpm: 60),
    FrequencyPreset(name: '中速', bpm: 80),
    FrequencyPreset(name: '快速', bpm: 100),
    FrequencyPreset(name: '高速', bpm: 120),
    FrequencyPreset(name: '冲刺', bpm: 150),
  ];

  /// 自定义 BPM 范围
  static const int minBpm = 30;
  static const int maxBpm = 300;
}

/// 挑战模型：名称 + 灯颜色 + 频率(BPM) + 时长(秒)
class Challenge {
  final String name;

  /// 颜色索引，指向 ChallengeColors.all
  final int colorIndex;

  /// 频率：每分钟闪烁次数（BPM）
  final int bpm;

  /// 时长（秒）
  final int seconds;

  Challenge({
    required this.name,
    required this.colorIndex,
    required this.bpm,
    required this.seconds,
  });

  /// 灯颜色
  Color get color =>
      ChallengeColors.all[colorIndex % ChallengeColors.all.length];

  Map<String, dynamic> toJson() => {
        'name': name,
        'colorIndex': colorIndex,
        'bpm': bpm,
        'seconds': seconds,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        name: json['name'] as String,
        colorIndex: json['colorIndex'] as int,
        bpm: json['bpm'] as int,
        seconds: json['seconds'] as int,
      );
}
