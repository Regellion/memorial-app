import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
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

    // Открываем базу данных
    final db = await openDatabase(
      path,
      version: 1, // Версия базы данных
      onCreate: _onCreate,
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
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fontSize REAL,
          themeMode INTEGER
        );
      '''
    );

    await db.execute(
      '''
        INSERT OR IGNORE INTO settings (id, fontSize, themeMode) 
        VALUES (1, 20.0, 0);
      '''
    );

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
          name_lists_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          FOREIGN KEY (name_lists_id) REFERENCES name_lists(id) ON DELETE CASCADE
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

  //todo рефакторинг
  // Загрузка настроек
  Future<Map<String, dynamic>> loadSettings() async {
    final db = await database;
    final settings = await db.query('settings', limit: 1);
    return settings.isNotEmpty ? settings.first : {};
  }

  // Сохранение настроек
  Future<void> saveSettings(double fontSize, int themeMode) async {
    final db = await database;
    await db.update(
      'settings',
      {'fontSize': fontSize, 'themeMode': themeMode},
      where: 'id = ?',
      whereArgs: [1],
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
      where: 'name_lists_id = ?',
      whereArgs: [nameListId],
    );
  }

  // Добавление списка
  Future<int> addNameList(String title, int type) async {
    final db = await database;
    return await db.insert('name_lists', {'title': title, 'type': type});
  }

  // Добавление имени
  Future<void> addName(int nameListId, String name) async {
    final db = await database;
    await db.insert('names', {'name_lists_id': nameListId, 'name': name});
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

  Future<void> updateName(int id, String newName) async {
    final db = await database;
    await db.update(
      'names',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
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
}
