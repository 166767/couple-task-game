import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../services/storage_service.dart';

/// 自定义挑战页：增删改挑战
class ChallengeEditorPage extends StatefulWidget {
  const ChallengeEditorPage({super.key});

  @override
  State<ChallengeEditorPage> createState() => _ChallengeEditorPageState();
}

class _ChallengeEditorPageState extends State<ChallengeEditorPage> {
  final StorageService _storage = StorageService();
  List<Challenge> _challenges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenges = await _storage.getChallenges();
    if (mounted) setState(() => _challenges = challenges);
  }

  /// 添加/编辑挑战
  Future<void> _showDialog({int? editIndex}) async {
    final isEdit = editIndex != null;
    final result = await showDialog<Challenge>(
      context: context,
      builder: (_) =>
          _ChallengeDialog(initial: isEdit ? _challenges[editIndex] : null),
    );
    if (result == null) return;

    final list = [..._challenges];
    if (isEdit) {
      list[editIndex] = result;
    } else {
      list.add(result);
    }
    await _storage.setChallenges(list);
    await _load();
  }

  void _delete(int index) {
    setState(() => _challenges.removeAt(index));
    _storage.setChallenges(_challenges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自定义挑战')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        tooltip: '添加挑战',
        child: const Icon(Icons.add),
      ),
      body: _challenges.isEmpty
          ? const Center(child: Text('还没有挑战，点击右下角添加'))
          : ListView.builder(
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final c = _challenges[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text('${c.bpm} 次/分钟 · ${c.seconds} 秒'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: '编辑',
                          onPressed: () => _showDialog(editIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: '删除',
                          onPressed: () => _delete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 挑战编辑对话框：自管理 controller 生命周期
class _ChallengeDialog extends StatefulWidget {
  final Challenge? initial;

  const _ChallengeDialog({this.initial});

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _bpm =
      TextEditingController(text: widget.initial?.bpm.toString() ?? '80');
  late final TextEditingController _seconds =
      TextEditingController(text: widget.initial?.seconds.toString() ?? '30');
  late int _colorIndex = widget.initial?.colorIndex ?? 0;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _bpm.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final bpm = int.tryParse(_bpm.text.trim());
    final seconds = int.tryParse(_seconds.text.trim());
    if (name.isEmpty) {
      setState(() => _error = '请输入挑战名称');
      return;
    }
    if (bpm == null || bpm < FrequencyPresets.minBpm || bpm > FrequencyPresets.maxBpm) {
      setState(() => _error = '频率需在 ${FrequencyPresets.minBpm}~${FrequencyPresets.maxBpm} 之间');
      return;
    }
    if (seconds == null || seconds < 5 || seconds > 300) {
      setState(() => _error = '时长需在 5~300 秒之间');
      return;
    }
    Navigator.of(context).pop(Challenge(
          name: name,
          colorIndex: _colorIndex,
          bpm: bpm,
          seconds: seconds,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '添加挑战' : '编辑挑战'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '挑战名称'),
            ),
            const SizedBox(height: 16),
            // 灯颜色选择
            const Text('灯颜色', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < ChallengeColors.all.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ChallengeColors.all[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorIndex == i
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24,
                          width: _colorIndex == i ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 频率档位快捷选择
            const Text('频率档位（次/分钟）', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in FrequencyPresets.all)
                  ChoiceChip(
                    label: Text('${p.name} ${p.bpm}'),
                    selected: _bpm.text == p.bpm.toString(),
                    onSelected: (_) =>
                        setState(() => _bpm.text = p.bpm.toString()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 频率 + 时长输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bpm,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '频率',
                      suffixText: '次/分',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _seconds,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '时长',
                      suffixText: '秒',
                    ),
                  ),
                ),
              ],
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
