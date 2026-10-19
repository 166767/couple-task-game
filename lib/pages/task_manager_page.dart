import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/task_pack.dart';
import '../services/storage_service.dart';
import '../services/txt_parser.dart';

/// 任务管理页：列表展示、导入、重命名、删除、设为使用中
class TaskManagerPage extends StatefulWidget {
  const TaskManagerPage({super.key});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> {
  final StorageService _storage = StorageService();

  List<TaskPack> _packs = [];
  String? _currentName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 读取任务包列表与当前使用包
  Future<void> _load() async {
    final packs = await _storage.loadTaskPacks();
    final current = await _storage.getCurrentPackName();
    if (mounted) {
      setState(() {
        _packs = packs;
        _currentName = current;
      });
    }
  }

  /// 导入 TXT 任务包
  Future<void> _import() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (file == null) {
      return; // 用户取消
    }

    try {
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);

      // 文件名去掉 .txt 作为任务包名
      final name = file.name.replaceAll(
        RegExp(r'\.txt$', caseSensitive: false),
        '',
      );
      final pack = TxtParser.parse(name, content);

      if (_packs.any((p) => p.name == pack.name)) {
        _toast('已存在同名任务包');
        return;
      }

      await _storage.saveTaskPacks([..._packs, pack]);
      await _load();
      _toast('导入成功');
    } catch (_) {
      _toast('文件格式错误');
    }
  }

  /// 点击任务包 → 设为"使用中"
  Future<void> _setCurrent(TaskPack pack) async {
    await _storage.setCurrentPackName(pack.name);
    await _load();
  }

  /// 重命名任务包
  Future<void> _rename(TaskPack pack) async {
    final controller = TextEditingController(text: pack.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名任务包'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '任务包名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.isEmpty || newName == pack.name) {
      return;
    }
    if (_packs.any((p) => p.name == newName)) {
      _toast('已存在同名任务包');
      return;
    }

    final newList = [
      for (final p in _packs)
        p.name == pack.name ? TaskPack(name: newName, tasks: p.tasks) : p,
    ];
    await _storage.saveTaskPacks(newList);
    // 若重命名的是当前使用包，同步更新使用中标识
    if (_currentName == pack.name) {
      await _storage.setCurrentPackName(newName);
    }
    await _load();
  }

  /// 删除任务包
  Future<void> _delete(TaskPack pack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除任务包'),
        content: Text('确定删除「${pack.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final newList = [
      for (final p in _packs)
        if (p.name != pack.name) p,
    ];
    await _storage.saveTaskPacks(newList);
    // 若删除的是当前使用包，清空使用中状态
    if (_currentName == pack.name) {
      await _storage.setCurrentPackName(null);
    }
    await _load();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// 生成任务数量摘要，如"简单 3 · 普通 2"
  String _summary(TaskPack pack) {
    final parts = <String>[];
    for (final d in Difficulty.values) {
      final count = pack.tasksOf(d).length;
      if (count > 0) {
        parts.add('${d.label} $count');
      }
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.file_upload),
        label: const Text('导入任务包'),
      ),
      body: _packs.isEmpty
          ? const Center(child: Text('暂无任务包，请点击右下角导入'))
          : ListView.builder(
              itemCount: _packs.length,
              itemBuilder: (context, index) {
                final pack = _packs[index];
                final inUse = pack.name == _currentName;
                return Card(
                  color: inUse ? Colors.pink.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      inUse ? Icons.check_circle : Icons.inventory_2,
                      color: inUse ? Colors.pink : null,
                    ),
                    title: Text(pack.name),
                    subtitle: Text(_summary(pack)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inUse)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text('使用中'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'rename') _rename(pack);
                            if (v == 'delete') _delete(pack);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('重命名')),
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _setCurrent(pack),
                  ),
                );
              },
            ),
    );
  }
}
