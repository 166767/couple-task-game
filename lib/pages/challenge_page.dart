import 'package:flutter/material.dart';

import '../models/challenge.dart';
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
            // 开始挑战（主入口）：先选总时长
            FilledButton.icon(
              onPressed: () async {
                final minutes = await showDialog<int>(
                  context: context,
                  builder: (_) => const _DurationDialog(),
                );
                if (minutes == null || !context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChallengePlayPage(totalMinutes: minutes),
                  ),
                );
              },
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

/// 总时长选择对话框：4 个难度 + 自定义分钟
class _DurationDialog extends StatefulWidget {
  const _DurationDialog();

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  final TextEditingController _minutes =
      TextEditingController(text: '15');
  String? _error;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    final minutes = int.tryParse(_minutes.text.trim());
    if (minutes == null ||
        minutes < ChallengeDurations.minMinutes ||
        minutes > ChallengeDurations.maxMinutes) {
      setState(() => _error =
          '时长需在 ${ChallengeDurations.minMinutes}~${ChallengeDurations.maxMinutes} 分钟之间');
      return;
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择总时长'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in ChallengeDurations.presets)
                ChoiceChip(
                  label: Text('${d.name} ${d.minutes}分'),
                  selected: _minutes.text == d.minutes.toString(),
                  onSelected: (_) =>
                      setState(() => _minutes.text = d.minutes.toString()),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '自定义时长',
              suffixText: '分钟',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
