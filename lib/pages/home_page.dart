import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/difficulty.dart';
import '../models/task_pack.dart';
import '../services/storage_service.dart';
import 'game_page.dart';
import 'settings_page.dart';
import 'task_manager_page.dart';
import 'task_pack_editor_page.dart';

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

  /// 启动时依次弹出：年龄确认公告 → 开源公告（各自判断"不再提示"）
  Future<void> _showNoticeIfNeeded() async {
    // 1. 年龄确认（未勾选"不再提示"才弹）
    if (!await _storage.getNoticeNoMore() && mounted) {
      await showNoticeDialog(context, _storage);
    }
    if (!mounted) return;
    // 2. 开源公告（未勾选"不再提示"才弹）
    if (!await _storage.getOpenSourceNoMore() && mounted) {
      await showOpenSourceDialog(context, _storage);
    }
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
      appBar: AppBar(
        title: const Text('任务大冒险'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              '本软件完全开源，任何收费售卖均为盗卖诈骗',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ),
      ),
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
            // 制作任务包按钮
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TaskPackEditorPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('制作任务包'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
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

/// 公告弹窗：年满 18 周岁确认 + "不再提示"复选框
Future<void> showNoticeDialog(
  BuildContext context,
  StorageService storage,
) async {
  var noMore = false;
  // 'adult' = 已满18周岁；'exit' = 未满18周岁，退出应用
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false, // 必须选择其中一个按钮
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('年龄确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('你是否已经年满18周岁且具有清晰的自我判断能力？'),
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
            onPressed: () => Navigator.of(dialogContext).pop('exit'),
            child: const Text('我未年满18周岁，退出'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('adult'),
            child: const Text('我已年满18周岁'),
          ),
        ],
      );
    },
  );

  if (result == 'adult') {
    // 已满18周岁：勾选"不再提示"才记住，下次不再弹
    if (noMore) {
      await storage.setNoticeNoMore(true);
    }
  } else if (result == 'exit') {
    // 未满18周岁：退出应用；不记住"不再提示"，下次启动仍会再次确认
    SystemNavigator.pop();
  }
}

/// 开源公告弹窗：开源声明 + GitHub 地址 + 作者信息 + "不再提示"复选框
Future<void> showOpenSourceDialog(
  BuildContext context,
  StorageService storage,
) async {
  var noMore = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('开源声明'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本应用为纯开源项目，源代码已完全公开，可自由查看与学习。'),
            const SizedBox(height: 8),
            const Text('任何以付费、售卖本应用或其资源的行为均属盗用盈利，请勿上当受骗。'),
            const SizedBox(height: 12),
            const Text('作者：小弈'),
            const Text('联系邮箱：2700899650@qq.com'),
            const Text('开源地址：https://github.com/166767/couple-task-game'),
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
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确认'),
          ),
        ],
      );
    },
  );

  // 勾选"不再提示"才记住
  if (noMore) {
    await storage.setOpenSourceNoMore(true);
  }
}
