import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/task.dart';
import '../models/task_pack.dart';
import '../services/storage_service.dart';

/// 任务包编辑器：新建或编辑任务包
class TaskPackEditorPage extends StatefulWidget {
  /// 为 null 表示新建；非 null 表示编辑现有任务包
  final TaskPack? pack;

  const TaskPackEditorPage({super.key, this.pack});

  @override
  State<TaskPackEditorPage> createState() => _TaskPackEditorPageState();
}

/// 任务草稿（编辑器内的可变结构）
class _TaskDraft {
  String content;
  int seconds;
  Difficulty difficulty;

  _TaskDraft({
    required this.content,
    required this.seconds,
    required this.difficulty,
  });
}

class _TaskPackEditorPageState extends State<TaskPackEditorPage> {
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  final List<_TaskDraft> _tasks = [];

  bool get _isNew => widget.pack == null;

  @override
  void initState() {
    super.initState();
    final pack = widget.pack;
    if (pack != null) {
      _nameController.text = pack.name;
      for (final d in Difficulty.values) {
        for (final t in pack.tasksOf(d)) {
          _tasks.add(_TaskDraft(
            content: t.content,
            seconds: t.seconds,
            difficulty: t.difficulty,
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 添加/编辑任务（弹出对话框）
  Future<void> _showTaskDialog({int? editIndex}) async {
    final isEdit = editIndex != null;
    final result = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(initial: isEdit ? _tasks[editIndex] : null),
    );
    if (result == null) return;

    setState(() {
      if (isEdit) {
        _tasks[editIndex] = result;
      } else {
        _tasks.add(result);
      }
    });
  }

  void _deleteTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

  /// 保存：新建或更新任务包
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('请输入任务包名称');
      return;
    }
    if (_tasks.isEmpty) {
      _toast('请至少添加一个任务');
      return;
    }

    final map = <Difficulty, List<Task>>{
      for (final d in Difficulty.values) d: <Task>[],
    };
    for (final td in _tasks) {
      map[td.difficulty]!.add(Task(
            content: td.content,
            seconds: td.seconds,
            difficulty: td.difficulty,
          ));
    }
    final pack = TaskPack(name: name, tasks: map);

    final packs = await _storage.loadTaskPacks();
    final oldName = widget.pack?.name;

    if (_isNew) {
      if (packs.any((p) => p.name == name)) {
        _toast('已存在同名任务包');
        return;
      }
      packs.add(pack);
    } else {
      // 编辑：重名检查（排除自己）
      if (packs.any((p) => p.name == name && p.name != oldName)) {
        _toast('已存在同名任务包');
        return;
      }
      final index = packs.indexWhere((p) => p.name == oldName);
      if (index >= 0) {
        packs[index] = pack;
      } else {
        packs.add(pack);
      }
      // 名称变化且为使用中时，同步更新使用中标识
      if (oldName != name) {
        final current = await _storage.getCurrentPackName();
        if (current == oldName) {
          await _storage.setCurrentPackName(name);
        }
      }
    }

    await _storage.saveTaskPacks(packs);
    if (mounted) Navigator.of(context).pop();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建任务包' : '编辑任务包'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '保存',
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '任务包名称',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('还没有任务，点击右下角添加'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final td = _tasks[index];
                      return Card(
                        child: ListTile(
                          leading: Chip(
                            label: Text(td.difficulty.label),
                            visualDensity: VisualDensity.compact,
                          ),
                          title: Text(td.content),
                          subtitle: Text('${td.seconds} 秒'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: '编辑',
                                onPressed: () =>
                                    _showTaskDialog(editIndex: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: '删除',
                                onPressed: () => _deleteTask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        tooltip: '添加任务',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 添加/编辑任务对话框：自管理 TextEditingController 生命周期
class _TaskDialog extends StatefulWidget {
  final _TaskDraft? initial;

  const _TaskDialog({this.initial});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _content =
      TextEditingController(text: widget.initial?.content ?? '');
  late final TextEditingController _seconds =
      TextEditingController(text: widget.initial?.seconds.toString() ?? '30');
  late Difficulty _difficulty =
      widget.initial?.difficulty ?? Difficulty.easy;
  String? _error;

  @override
  void dispose() {
    _content.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _content.text.trim();
    final seconds = int.tryParse(_seconds.text.trim());
    if (content.isEmpty) {
      setState(() => _error = '任务内容不能为空');
      return;
    }
    if (seconds == null || seconds <= 0) {
      setState(() => _error = '时长必须是大于 0 的秒数');
      return;
    }
    Navigator.of(context).pop(_TaskDraft(
          content: content,
          seconds: seconds,
          difficulty: _difficulty,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '添加任务' : '编辑任务'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _content,
            autofocus: true,
            decoration: const InputDecoration(labelText: '任务内容'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _seconds,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '时长',
              suffixText: '秒',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                for (final d in Difficulty.values)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: _difficulty == d,
                    onSelected: (_) => setState(() => _difficulty = d),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
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
