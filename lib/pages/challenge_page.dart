import 'package:flutter/material.dart';

import 'challenge_editor_page.dart';
import 'challenge_play_page.dart';

/// 频率挑战主页：两个入口（开始挑战 + 自定义挑战）
class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('频率挑战')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            const Text(
              '跟着灯的节奏，完成对应挑战',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            // 开始挑战（主入口）
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChallengePlayPage()),
              ),
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text('开始挑战'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            // 自定义挑战
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChallengeEditorPage()),
              ),
              icon: const Icon(Icons.tune),
              label: const Text('自定义挑战'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
