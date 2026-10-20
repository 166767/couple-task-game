import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/challenge.dart';
import '../models/task_pack.dart';
import 'txt_parser.dart';

/// 本地存储服务：所有任务包、当前使用任务包、公告"不再提示"
///
/// 全部使用 shared_preferences 保存到本地，不联网。
class StorageService {
  static const String _kTaskPacks = 'task_packs';
  static const String _kCurrentPackName = 'current_pack_name';
  static const String _kNoticeNoMore = 'notice_no_more';
  static const String _kOpenSourceNoMore = 'open_source_no_more';
  static const String _kThemeId = 'theme_id';
  static const String _kVibrationEnabled = 'vibration_enabled';
  static const String _kPinnedPacks = 'pinned_packs';
  static const String _kDifficultyNames = 'difficulty_names';
  static const String _kChallenges = 'challenges';
  static const String _kInitialized = 'initialized';

  /// 内置示例任务包内容（首次启动自动内置）
  static const String samplePackContent = '''
[简单]
牵手一分钟|60
对视十秒|10
说一句情话|20
[普通]
互相喂一口吃的|90
背对方走十步|60
[困难]
唱一首情歌|180
公主抱十秒|30
[极难]
给对方洗一次脚|300
完成一件对方指定的事|120
''';

  /// 首次启动初始化：内置"示例任务包"并设为使用中
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_kInitialized) ?? false;
    if (initialized) {
      return;
    }

    final sample = TxtParser.parse('示例任务包', samplePackContent);
    await _saveTaskPacks(prefs, [sample]);
    await _setCurrentPackName(prefs, sample.name);
    await prefs.setBool(_kInitialized, true);
  }

  /// 读取所有任务包
  Future<List<TaskPack>> loadTaskPacks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTaskPacks);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list) TaskPack.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// 保存所有任务包
  Future<void> saveTaskPacks(List<TaskPack> packs) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveTaskPacks(prefs, packs);
  }

  Future<void> _saveTaskPacks(
    SharedPreferences prefs,
    List<TaskPack> packs,
  ) async {
    final list = [for (final p in packs) p.toJson()];
    await prefs.setString(_kTaskPacks, jsonEncode(list));
  }

  /// 读取当前使用中的任务包名称（null 表示无）
  Future<String?> getCurrentPackName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentPackName);
  }

  /// 设置当前使用中的任务包名称
  Future<void> setCurrentPackName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    await _setCurrentPackName(prefs, name);
  }

  Future<void> _setCurrentPackName(SharedPreferences prefs, String? name) async {
    if (name == null) {
      await prefs.remove(_kCurrentPackName);
    } else {
      await prefs.setString(_kCurrentPackName, name);
    }
  }

  /// 读取公告"不再提示"布尔值
  Future<bool> getNoticeNoMore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNoticeNoMore) ?? false;
  }

  /// 设置公告"不再提示"布尔值
  Future<void> setNoticeNoMore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNoticeNoMore, value);
  }

  /// 读取开源公告"不再提示"布尔值
  Future<bool> getOpenSourceNoMore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOpenSourceNoMore) ?? false;
  }

  /// 设置开源公告"不再提示"布尔值
  Future<void> setOpenSourceNoMore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOpenSourceNoMore, value);
  }

  /// 读取当前主题 id（null 表示使用默认第一套）
  Future<String?> getThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeId);
  }

  /// 设置当前主题 id
  Future<void> setThemeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeId, id);
  }

  /// 读取震动开关（默认开启）
  Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kVibrationEnabled) ?? true;
  }

  /// 设置震动开关
  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrationEnabled, value);
  }

  /// 读取置顶任务包名称列表
  Future<List<String>> getPinnedPacks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPinnedPacks);
    if (raw == null || raw.isEmpty) return [];
    return [for (final e in jsonDecode(raw) as List<dynamic>) e as String];
  }

  /// 保存置顶任务包名称列表
  Future<void> setPinnedPacks(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinnedPacks, jsonEncode(names));
  }

  /// 读取自定义难度名称（Map<难度枚举名, 自定义名称>）
  Future<Map<String, String>> getDifficultyNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDifficultyNames);
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  /// 保存自定义难度名称
  Future<void> setDifficultyNames(Map<String, String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDifficultyNames, jsonEncode(names));
  }

  /// 读取所有挑战
  Future<List<Challenge>> getChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kChallenges);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list) Challenge.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// 保存所有挑战
  Future<void> setChallenges(List<Challenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final c in challenges) c.toJson()];
    await prefs.setString(_kChallenges, jsonEncode(list));
  }
}
