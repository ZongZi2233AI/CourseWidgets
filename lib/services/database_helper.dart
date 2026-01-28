import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/course_event.dart';
import 'html_to_ics_converter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init();

  /// 初始化数据库工厂（Windows平台需要）
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Web平台不支持sqflite_ffi
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 初始化FFI数据库工厂
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Web平台使用内存数据库
    if (kIsWeb) {
      _database = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: _createDB);
      return _database!;
    }
    
    // 确保已初始化
    await initialize();
    
    _database = await _initDB('schedule.db');
    
    // 确保所有表都存在（检查并创建缺失的表）
    if (_database != null) {
      await _ensureTablesExist(_database!);
    }
    
    return _database!;
  }

  /// 确保所有必要的表都存在
  Future<void> _ensureTablesExist(Database db) async {
    // 检查 courses 表是否有 teacher 字段
    try {
      final result = await db.rawQuery('PRAGMA table_info(courses)');
      final hasTeacherField = result.any((column) => column['name'] == 'teacher');
      
      if (!hasTeacherField) {
        // 添加 teacher 字段
        await db.execute('ALTER TABLE courses ADD COLUMN teacher TEXT');
        debugPrint('✅ 已添加 teacher 字段到 courses 表');
      }
    } catch (e) {
      debugPrint('检查 teacher 字段失败: $e');
    }
    
    // 检查并创建历史记录表
    final historyTableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='schedule_history'"
    );
    if (historyTableExists.isEmpty) {
      await _createScheduleHistoryTable(db);
    }
    
    // 检查并创建配置表
    final configTableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='schedule_config'"
    );
    if (configTableExists.isEmpty) {
      await _createScheduleConfigTable(db);
    }
  }

  Future<Database> _initDB(String filePath) async {
    // 使用应用数据目录作为数据库路径，确保跨平台兼容性
    String dbDir;
    String dbPath;
    
    try {
      if (Platform.isWindows) {
        // Windows: 使用应用数据目录
        final appData = Platform.environment['APPDATA'] ?? '.';
        dbDir = appData;
        dbPath = join(dbDir, 'CourseWidgets', filePath);
        
        // 确保目录存在
        final dbFile = File(dbPath);
        if (!await dbFile.parent.exists()) {
          await dbFile.parent.create(recursive: true);
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动端使用默认路径
        return await openDatabase(
          join(await getDatabasesPath(), filePath),
          version: 1,
          onCreate: _createDB,
        );
      } else {
        // 其他平台使用当前目录的临时目录
        dbDir = '.';
        dbPath = join(dbDir, filePath);
      }
    } catch (e) {
      // 如果失败，使用当前目录
      dbDir = '.';
      dbPath = join(dbDir, filePath);
    }
    
    return await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE courses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      location TEXT,
      teacher TEXT,
      startTime INTEGER NOT NULL,
      endTime INTEGER NOT NULL
    )
    ''');
    
    // 创建历史记录表
    await _createScheduleHistoryTable(db);
    
    // 创建配置表
    await _createScheduleConfigTable(db);
  }

  /// 批量插入课程
  Future<void> insertCourses(List<CourseEvent> courses) async {
    final db = await database;
    
    // 先清空旧数据
    await db.delete('courses');
    
    final batch = db.batch();
    
    for (var course in courses) {
      batch.insert('courses', course.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  /// 删除指定课程
  Future<void> deleteCourses(List<CourseEvent> courses) async {
    final db = await database;
    
    for (var course in courses) {
      await db.delete(
        'courses',
        where: 'startTime = ? AND endTime = ? AND name = ?',
        whereArgs: [course.startTime, course.endTime, course.name],
      );
    }
  }

  /// 获取所有课程
  Future<List<CourseEvent>> getAllCourses() async {
    final db = await database;
    final result = await db.query('courses', orderBy: 'startTime ASC');
    return result.map((e) => CourseEvent.fromMap(e)).toList();
  }

  /// 获取指定日期的课程
  Future<List<CourseEvent>> getCoursesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    
    final result = await db.query(
      'courses',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'startTime ASC',
    );
    
    return result.map((e) => CourseEvent.fromMap(e)).toList();
  }

  /// 获取指定周次的课程
  Future<List<CourseEvent>> getCoursesByWeek(int week, DateTime startDate) async {
    final weekStart = startDate.add(Duration(days: (week - 1) * 7));
    final weekEnd = weekStart.add(Duration(days: 7));
    
    final db = await database;
    final result = await db.query(
      'courses',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [weekStart.millisecondsSinceEpoch, weekEnd.millisecondsSinceEpoch],
      orderBy: 'startTime ASC',
    );
    
    return result.map((e) => CourseEvent.fromMap(e)).toList();
  }

  /// 获取所有可用周次
  Future<List<int>> getAvailableWeeks(DateTime startDate) async {
    final courses = await getAllCourses();
    final weeks = <int>{};
    
    for (var course in courses) {
      final week = course.getWeekNumber(startDate);
      if (week > 0) {
        weeks.add(week);
      }
    }
    
    return weeks.toList()..sort();
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('courses');
  }

  /// [v2.2.9] 删除单节课程（根据开始时间）
  Future<void> deleteCourse(int startTime) async {
    final db = await database;
    await db.delete(
      'courses',
      where: 'startTime = ?',
      whereArgs: [startTime],
    );
  }

  /// [v2.2.9] 删除所有同名课程
  Future<void> deleteAllCoursesWithName(String courseName) async {
    final db = await database;
    await db.delete(
      'courses',
      where: 'name = ?',
      whereArgs: [courseName],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ==================== 课程表历史记录管理 ====================

  /// 创建课程表历史记录表
  Future<void> _createScheduleHistoryTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS schedule_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      source_type TEXT NOT NULL, -- 'ics' 或 'html'
      source_data TEXT, -- 原始数据（ICS内容或HTML JSON）
      course_data TEXT NOT NULL, -- 课程数据（JSON格式）
      created_at INTEGER NOT NULL,
      is_active INTEGER DEFAULT 0,
      semester TEXT, -- 学期信息
      config_data TEXT -- 课时配置数据（JSON格式）
    )
    ''');
  }

  /// 创建课时配置表
  Future<void> _createScheduleConfigTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS schedule_config (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      config_data TEXT NOT NULL,
      is_default INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL
    )
    ''');
  }

  /// 保存新的课程表历史记录
  Future<int> saveScheduleHistory({
    required String name,
    required String sourceType,
    required String sourceData,
    required String courseData,
    required String semester,
  }) async {
    final db = await database;
    
    // 如果是新导入，先将所有现有记录设为非激活
    if (sourceType == 'ics' || sourceType == 'html') {
      await db.update(
        'schedule_history',
        {'is_active': 0},
      );
    }

    return await db.insert('schedule_history', {
      'name': name,
      'source_type': sourceType,
      'source_data': sourceData,
      'course_data': courseData,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'is_active': 1,
      'semester': semester,
    });
  }

  /// 获取所有课程表历史记录
  Future<List<Map<String, dynamic>>> getAllScheduleHistory() async {
    final db = await database;
    final result = await db.query(
      'schedule_history',
      orderBy: 'created_at DESC',
    );
    return result;
  }

  /// 获取当前激活的课程表
  Future<Map<String, dynamic>?> getActiveSchedule() async {
    final db = await database;
    final result = await db.query(
      'schedule_history',
      where: 'is_active = 1',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// 切换到指定的历史记录
  Future<bool> switchToSchedule(int id) async {
    final db = await database;
    
    // 先将所有记录设为非激活
    await db.update(
      'schedule_history',
      {'is_active': 0},
    );
    
    // 激活指定记录
    final result = await db.update(
      'schedule_history',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  }

  /// 删除课程表历史记录
  Future<bool> deleteScheduleHistory(int id) async {
    final db = await database;
    final result = await db.delete(
      'schedule_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  /// 获取指定历史记录的课程数据
  Future<List<Map<String, dynamic>>> getScheduleCourses(int id) async {
    final db = await database;
    final result = await db.query(
      'schedule_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return [];
    
    final courseDataStr = result.first['course_data'] as String;
    final courseData = jsonDecode(courseDataStr) as List;
    return courseData.cast<Map<String, dynamic>>();
  }

  /// 导出指定历史记录为ICS文件内容
  Future<String?> exportScheduleToIcs(int id) async {
    final db = await database;
    final result = await db.query(
      'schedule_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final sourceType = result.first['source_type'] as String;
    
    if (sourceType == 'ics') {
      // 如果是ICS导入的，直接返回原始数据
      return result.first['source_data'] as String;
    } else if (sourceType == 'html') {
      // 如果是HTML导入的，需要重新生成ICS
      final courseDataStr = result.first['course_data'] as String;
      final courseData = jsonDecode(courseDataStr) as List<dynamic>;
      
      // 使用HTML转换器重新生成ICS
      final courses = HtmlImportService.restoreCourseData(
        courseData.cast<Map<String, dynamic>>()
      );
      final config = ScheduleConfig();
      return IcsGenerator.generate(courses, config);
    }
    
    return null;
  }

  /// 清理旧的历史记录（保留最近50条）
  Future<void> cleanupOldHistory() async {
    final db = await database;
    final result = await db.query(
      'schedule_history',
      orderBy: 'created_at DESC',
      limit: 1,
      offset: 49,
    );
    
    if (result.isNotEmpty) {
      final oldestTime = result.first['created_at'] as int;
      await db.delete(
        'schedule_history',
        where: 'created_at <= ?',
        whereArgs: [oldestTime],
      );
    }
  }
}
