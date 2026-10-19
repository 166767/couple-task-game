import 'package:flutter/material.dart';

import '../main.dart';
import '../services/storage_service.dart';
import '../theme.dart';

/// 设置页：主题配色切换 + 震动开关
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();

  String? _currentThemeId;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final themeId = await _storage.getThemeId();
    final vibration = await _storage.getVibrationEnabled();
    if (mounted) {
      setState(() {
        _currentThemeId = themeId;
        _vibration = vibration;
      });
    }
  }

  /// 切换主题：即时生效 + 持久化
  Future<void> _selectTheme(AppTheme theme) async {
    themeNotifier.value = theme;
    await _storage.setThemeId(theme.id);
    if (mounted) {
      setState(() => _currentThemeId = theme.id);
    }
  }

  /// 切换震动开关
  Future<void> _toggleVibration(bool value) async {
    await _storage.setVibrationEnabled(value);
    if (mounted) {
      setState(() => _vibration = value);
    }
  }

  /// 查看开源声明与公告（常驻入口，不受"不再提示"影响）
  void _showNotice() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('开源声明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本应用为纯开源项目，源代码已完全公开，可自由查看与学习。'),
            SizedBox(height: 8),
            Text('任何以付费、售卖本应用或其资源的行为均属盗用盈利，请勿上当受骗。'),
            SizedBox(height: 12),
            Text('作者：小弈'),
            Text('联系邮箱：2700899650@qq.com'),
            Text('开源地址：https://github.com/166767/couple-task-game'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '主题配色',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final theme in AppThemes.all) _buildThemeTile(theme),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text('震动反馈'),
            subtitle: const Text('任务切换与倒计时结束时震动'),
            value: _vibration,
            onChanged: _toggleVibration,
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('开源声明与公告'),
            subtitle: const Text('查看作者、联系方式与防诈骗提示'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showNotice,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(AppTheme theme) {
    final selected = theme.id == _currentThemeId;
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _colorDot(theme.background),
          _colorDot(theme.surface),
          _colorDot(theme.accent),
        ],
      ),
      title: Text(theme.name),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.accent)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () => _selectTheme(theme),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}
