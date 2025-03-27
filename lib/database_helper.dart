import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // Например, "1.2.3"
  }

  Future<int> convertVersionToNumber() async {
    String version = await _getAppVersion();
    final parts = version.split('.'); // Разделяем на мажорную, минорную и патч-версии
    final major = int.parse(parts[0]);
    final minor = int.parse(parts[1]);
    final patch = int.parse(parts[2]);
    return major * 10000 + minor * 100 + patch; // Преобразуем в число
  }

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  int _dbVersion = 1;
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Получаем путь к базе данных
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    _dbVersion = await convertVersionToNumber();

    // Открываем базу данных
    final db = await openDatabase(
      path,
      version: _dbVersion, // Версия базы данных
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создаем таблицы, если они не существуют
    await _createTablesIfNotExist(db);
  }

  Future<void> _createTablesIfNotExist(Database db) async {
    // Создаем таблицу settings, если она не существует
    await db.execute(
      '''
        CREATE TABLE IF NOT EXISTS settings(
          name TEXT PRIMARY KEY,
          description TEXT,
          value TEXT
        );
      '''
    );

    // Добавляем настройки по умолчанию, если их нет
    await _insertDefaultSettings(db);

    // Создаем таблицу name_lists, если она не существует
    await db.execute(
      '''
        CREATE TABLE IF NOT EXISTS name_lists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          type INTEGER NOT NULL
        );
      '''
    );

    // Создаем таблицу names, если она не существует
    await db.execute(
      '''
        CREATE TABLE IF NOT EXISTS names(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name_list_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          status_id INTEGER,
          rank_id INTEGER,
          gender INTEGER NOT NULL DEFAULT 1,
          end_date TEXT,
          death_date TEXT,
          FOREIGN KEY (name_list_id) REFERENCES name_lists(id) ON DELETE CASCADE
        );
      '''
    );

    await db.execute(
      '''
        INSERT OR IGNORE INTO name_lists (title, type)
        SELECT '', 0
        WHERE NOT EXISTS (SELECT 1 FROM name_lists WHERE type = 0);
      '''
    );

    await db.execute(
        '''
        INSERT OR IGNORE INTO name_lists (title, type)
        SELECT '', 1
        WHERE NOT EXISTS (SELECT 1 FROM name_lists WHERE type = 1);
      '''
    );
  }
  // Добавьте эти методы в класс DatabaseHelper
  Future<void> checkAndRemoveExpiredNames() async {
    final db = await database;
    final now = DateTime.now().toIso8601String().split('T')[0]; // Текущая дата в формате YYYY-MM-DD

    // Находим имена с истекшей датой поминовения
    final expiredNames = await db.query(
      'names',
      where: 'end_date IS NOT NULL AND end_date <= ?',
      whereArgs: [now],
    );

    // Удаляем каждое просроченное имя
    for (final name in expiredNames) {
      final nameId = name['id'] as int;
      final nameListId = name['name_list_id'] as int;

      await db.delete('names', where: 'id = ?', whereArgs: [nameId]);

      // Проверяем, остались ли имена в списке
      final remainingNames = await db.query(
        'names',
        where: 'name_list_id = ?',
        whereArgs: [nameListId],
      );

      if (remainingNames.isEmpty) {
        await db.delete('name_lists', where: 'id = ?', whereArgs: [nameListId]);
      }
    }
  }

  Future<void> updateNameEndDate(int nameId, String? endDate) async {
    final db = await database;
    await db.update(
      'names',
      {'end_date': endDate},
      where: 'id = ?',
      whereArgs: [nameId],
    );
  }

  Future<void> _insertDefaultSettings(Database db) async {
    // Проверяем, есть ли уже настройки, и добавляем только если их нет
    final existingSettings = await db.query('settings');
    if (existingSettings.isEmpty) {
      await db.insert('settings', {
        'name': 'font_size',
        'description': 'Размер шрифта имен',
        'value': '20.0',
      });

      await db.insert('settings', {
        'name': 'theme_mode',
        'description': 'Тема приложения',
        'value': '0',
      });

      await db.insert('settings', {
        'name': 'use_short_names',
        'description': 'Использовать сокращенные префиксы имен',
        'value': '1',
      });
    }
  }

// Получение значения настройки
  Future<String?> getSetting(String name) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  // Установка значения настройки
  Future<void> setSetting(String name, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'name': name,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Загрузка списков
  Future<List<Map<String, dynamic>>> loadNameLists() async {
    final db = await database;
    return await db.query('name_lists');
  }

  // Загрузка имен по списку
  Future<List<Map<String, dynamic>>> loadNames(int nameListId) async {
    final db = await database;
    return await db.query(
      'names',
      where: 'name_list_id = ?',
      whereArgs: [nameListId],
    );
  }

  // Добавление списка
  Future<int> addNameList(String title, int type) async {
    final db = await database;
    return await db.insert('name_lists', {'title': title, 'type': type});
  }

  // Добавление имени
  Future<int> addName(int nameListId, String name, int gender, int? statusId, int? rankId, String? endDate, String? deathDate) async {
    final db = await database;
    return await db.insert('names', {
      'name_list_id': nameListId,
      'name': name,
      'gender': gender,
      'status_id': statusId,
      'rank_id': rankId,
      'end_date': endDate,
      'death_date': deathDate,
    });
  }

  // Удаление списка
  Future<void> deleteNameList(int id) async {
    final db = await database;
    await db.delete('name_lists', where: 'id = ?', whereArgs: [id]);
  }

  // Удаление имени
  Future<void> deleteName(int id) async {
    final db = await database;
    await db.delete('names', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateName(int nameId, String newName, int gender, int? statusId, int? rankId, String? endDate, String? deathDate) async {
    final db = await database;
    await db.update(
      'names',
      {
        'name': newName,
        'gender': gender,
        'status_id': statusId,
        'rank_id': rankId,
        'end_date': endDate,
        'death_date': deathDate,
      },
      where: 'id = ?',
      whereArgs: [nameId],
    );
  }

  Future<void> checkAndUpdateNewlyDepartedStatus() async {
    final db = await database;
    final now = DateTime.now();

    // Находим имена со статусом новопреставленного (13 или 16)
    final newlyDepartedNames = await db.query(
      'names',
      where: 'status_id IN (?, ?) AND death_date IS NOT NULL',
      whereArgs: [13, 16],
    );

    for (final name in newlyDepartedNames) {
      final deathDate = DateTime.parse(name['death_date'] as String);
      final daysPassed = now.difference(deathDate).inDays;

      if (daysPassed > 40) {
        // Обновляем статус на "Приснопоминаемый" (14 или 17);
        await db.update(
          'names',
          {
            'status_id': null,
            'death_date': null
          },
          where: 'id = ?',
          whereArgs: [name['id']],
        );
      }
    }
  }

  Future<void> updateNameListTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'name_lists',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 10000) { //версия 1.0.0
    }
    if (oldVersion <= 20000) { //версия 2.0.0
    }
  }
}
