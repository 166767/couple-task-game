import 'package:flutter_test/flutter_test.dart';

import 'package:couple_task_game/models/difficulty.dart';
import 'package:couple_task_game/services/txt_parser.dart';

/// TXT 解析器单元测试（验收标准第 2 步）
void main() {
  group('TxtParser', () {
    test('正确解析各难度、时长与默认时长', () {
      const content = '''
[简单]
牵手一分钟|60
对视十秒|10
[困难]
唱一首情歌|3分钟
裸任务
''';
      final pack = TxtParser.parse('测试包', content);

      expect(pack.name, '测试包');
      expect(pack.tasksOf(Difficulty.easy).length, 2);
      expect(pack.tasksOf(Difficulty.easy)[0].seconds, 60);
      expect(pack.tasksOf(Difficulty.easy)[1].seconds, 10);
      expect(pack.tasksOf(Difficulty.hard).length, 2);
      // "3分钟" 应换算为 180 秒
      expect(pack.tasksOf(Difficulty.hard)[0].seconds, 180);
      // 不写时长 → 默认 30 秒
      expect(pack.tasksOf(Difficulty.hard)[1].seconds, 30);
    });

    test('任务位于难度标记之前时抛异常', () {
      expect(
        () => TxtParser.parse('x', '随便一行|10'),
        throwsFormatException,
      );
    });

    test('时长格式错误时抛异常', () {
      expect(
        () => TxtParser.parse('x', '[简单]\n任务|abc'),
        throwsFormatException,
      );
    });

    test('空内容抛异常', () {
      expect(
        () => TxtParser.parse('x', ''),
        throwsFormatException,
      );
    });
  });
}
