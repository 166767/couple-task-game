import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/task_pack.dart';
import '../services/storage_service.dart';
import 'game_page.dart';
import 'task_manager_page.dart';

/// 主页：选择难度、总时长，进入任务管理页或开始游戏
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();

  Difficulty _difficulty = Difficulty.easy; // 默认选中"简单"
  int _totalMinutes = 10; // 默认 10 分钟

  @override
  void initState() {
    super.initState();
    // 进入主页自动弹公告（首帧渲染后弹出）
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNoticeIfNeeded());
  }

  /// 若未勾选"不再提示"，则弹出公告
  Future<void> _showNoticeIfNeeded() async {
    final noMore = await _storage.getNoticeNoMore();
    if (noMore || !mounted) {
      return;
    }
    await showNoticeDialog(context, _storage);
  }

  /// 点击"开始"：做校验后进入游戏页
  Future<void> _onStart() async {
    final packs = await _storage.loadTaskPacks();
    final currentName = await _storage.getCurrentPackName();
    final current = _findByName(packs, currentName);

    if (!mounted) return;

    if (current == null || current.isEmpty) {
      _showToast('请先导入任务包');
      return;
    }
    if (current.tasksOf(_difficulty).isEmpty) {
      _showToast('该难度暂无任务');
      return;
    }

    // 进入游戏页，传入所选难度与总时长
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePage(
          difficulty: _difficulty,
          totalMinutes: _totalMinutes,
          pack: current,
        ),
      ),
    );
  }

  /// 按名称查找任务包
  TaskPack? _findByName(List<TaskPack> packs, String? name) {
    for (final p in packs) {
      if (p.name == name) {
        return p;
      }
    }
    return null;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务大冒险')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 难度选择
            const Text(
              '选择难度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final d in Difficulty.values)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: _difficulty == d,
                    onSelected: (_) => setState(() => _difficulty = d),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            // 总时长调节
            Text(
              '总游戏时长：$_totalMinutes 分钟',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _totalMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_totalMinutes 分钟',
              onChanged: (v) => setState(() => _totalMinutes = v.round()),
            ),
            const Spacer(),
            // 任务管理按钮
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaskManagerPage()),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('任务管理'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            // 开始按钮
            FilledButton.icon(
              onPressed: _onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 公告弹窗：默认文案 + "不再提示"复选框 + "确定"按钮
Future<void> showNoticeDialog(
  BuildContext context,
  StorageService storage,
) async {
  var noMore = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('公告'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('欢迎使用情侣任务大冒险，本 App 仅供情侣间游戏娱乐。'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: noMore,
                      onChanged: (v) => setState(() => noMore = v ?? false),
                    ),
                    const Text('不再提示'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  // 勾选了"不再提示"则持久化保存
  if (noMore) {
    await storage.setNoticeNoMore(true);
  }
}
