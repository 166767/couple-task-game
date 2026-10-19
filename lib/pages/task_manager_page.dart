import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/difficulty.dart';
import '../models/task_pack.dart';
import '../services/storage_service.dart';
import '../services/txt_parser.dart';
import '../theme.dart';
import 'task_pack_editor_page.dart';

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
      final content = _decodeText(bytes);

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
    } catch (e) {
      // 显示具体错误，便于定位是编码问题还是格式问题
      final detail = e is FormatException ? e.message : e.toString();
      _toast('文件格式错误：$detail');
    }
  }

  /// 点击任务包 → 设为"使用中"
  Future<void> _setCurrent(TaskPack pack) async {
    await _storage.setCurrentPackName(pack.name);
    await _load();
  }

  /// 重命名任务包
  Future<void> _rename(TaskPack pack) async {
    // 用自管理 controller 生命周期的对话框，避免在关闭动画结束前提前 dispose
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initialName: pack.name),
    );

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

  /// 解码导入文件内容：自动识别 UTF-8 / UTF-16 / GBK 编码并剥离 BOM
  String _decodeText(List<int> bytes) {
    // UTF-8 BOM
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    // UTF-16 LE BOM
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16Le(bytes.sublist(2));
    }
    // UTF-16 BE BOM
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16Be(bytes.sublist(2));
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // UTF-8 失败，回退到 GBK（Windows 记事本默认 ANSI 编码）
      return gbk.decode(bytes);
    }
  }

  /// UTF-16 小端解码
  String _decodeUtf16Le(List<int> bytes) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(units);
  }

  /// UTF-16 大端解码
  String _decodeUtf16Be(List<int> bytes) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }

  /// 编辑任务包（跳转到编辑器）
  Future<void> _edit(TaskPack pack) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskPackEditorPage(pack: pack)),
    );
    await _load(); // 返回后刷新
  }

  /// 导出任务包：生成 txt 并调起系统分享
  Future<void> _export(TaskPack pack) async {
    try {
      final content = TxtParser.encode(pack);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${pack.name}.txt');
      await file.writeAsString(content, encoding: utf8);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: '任务包分享',
        text: '分享任务包「${pack.name}」',
      ));
    } catch (e) {
      _toast('导出失败：$e');
    }
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
                  color: inUse ? AppColors.accent.withValues(alpha: 0.18) : null,
                  child: ListTile(
                    leading: Icon(
                      inUse ? Icons.check_circle : Icons.inventory_2,
                      color: inUse ? AppColors.accent : null,
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
                            if (v == 'edit') _edit(pack);
                            if (v == 'rename') _rename(pack);
                            if (v == 'export') _export(pack);
                            if (v == 'delete') _delete(pack);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑任务')),
                            PopupMenuItem(value: 'rename', child: Text('重命名')),
                            PopupMenuItem(value: 'export', child: Text('导出分享')),
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

/// 重命名对话框：自管理 TextEditingController 生命周期，
/// 随对话框 widget 树一起销毁，避免提前 dispose 引发的异常
class _RenameDialog extends StatefulWidget {
  final String initialName;

  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名任务包'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '任务包名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
