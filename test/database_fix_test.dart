import 'package:flutter_test/flutter_test.dart';
import 'package:coursewidgets/services/database_helper.dart';
import 'package:coursewidgets/models/schedule_config.dart';

void main() {
  group('数据库修复测试', () {
    test('数据库表创建测试', () async {
      // 初始化数据库
      await DatabaseHelper.initialize();
      
      // 获取数据库实例，触发表创建
      final db = await DatabaseHelper.instance.database;
      
      // 检查表是否存在
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('courses', 'schedule_history', 'schedule_config')"
      );
      
      print('已创建的表: ${tables.map((t) => t['name']).toList()}');
      
      // 验证所有表都存在
      expect(tables.length, greaterThanOrEqualTo(3));
      
      // 关闭数据库
      await DatabaseHelper.instance.close();
    });

    test('周次解析测试', () {
      // 测试周次字符串解析
      String validWeeksStr = '11100000000000000'; // 第1-3周
      
      List<int> weeks = [];
      for (int i = 0; i < validWeeksStr.length; i++) {
        if (validWeeksStr[i] == '1') {
          weeks.add(i + 1);
        }
      }
      
      if (weeks.isEmpty) {
        weeks = [1];
      }
      
      print('周次字符串: $validWeeksStr');
      print('解析结果: $weeks');
      
      expect(weeks, [1, 2, 3]);
    });

    test('空周次字符串测试', () {
      String emptyWeeksStr = '';
      
      List<int> weeks = [];
      for (int i = 0; i < emptyWeeksStr.length; i++) {
        if (emptyWeeksStr[i] == '1') {
          weeks.add(i + 1);
        }
      }
      
      if (weeks.isEmpty) {
        weeks = [1];
      }
      
      print('空周次字符串: "$emptyWeeksStr"');
      print('解析结果: $weeks');
      
      expect(weeks, [1]);
    });

    test('配置保存和读取测试', () async {
      await DatabaseHelper.initialize();
      final db = await DatabaseHelper.instance.database;
      
      // 创建测试配置
      final config = ScheduleConfigModel.defaultConfig();
      final configJson = config.toJson();
      
      // 插入配置
      final id = await db.insert('schedule_config', {
        'name': '测试配置',
        'config_data': configJson.toString(),
        'is_default': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      expect(id, greaterThan(0));
      
      // 读取配置
      final result = await db.query(
        'schedule_config',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      expect(result.length, 1);
      expect(result.first['name'], '测试配置');
      
      await DatabaseHelper.instance.close();
    });
  });
}
