import 'package:flutter/material.dart';

import 'database_helper.dart';

class Settings with ChangeNotifier {
  double _fontSize = 20;
  ThemeMode _themeMode = ThemeMode.light;
  bool _useShortNames = true;
  SortType _sortType = SortType.none;

  Settings() {
    _loadSettings();
  }

  double get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;
  bool get useShortNames => _useShortNames;
  SortType get sortType => _sortType;


  Future<void> _loadSettings() async {
    final dbHelper = DatabaseHelper();

    // Загружаем настройки из базы
    final fontSizeStr = await dbHelper.getSetting('font_size');
    final themeModeStr = await dbHelper.getSetting('theme_mode');
    final useShortNamesStr = await dbHelper.getSetting('use_short_names');
    final sortTypeStr = await dbHelper.getSetting('sort_type'); // Новая настройка

    // Обновляем значения
    if (fontSizeStr != null) {
      _fontSize = double.parse(fontSizeStr);
    }

    if (themeModeStr != null) {
      _themeMode = themeModeStr == '1' ? ThemeMode.dark : ThemeMode.light;
    }

    if (useShortNamesStr != null) {
      _useShortNames = useShortNamesStr == '1';
    }

    if (sortTypeStr != null) {
      try {
        _sortType = SortType.values[int.parse(sortTypeStr)];
      } catch (e) {
        _sortType = SortType.none;
        await dbHelper.setSetting('sort_type', _sortType.index.toString());
      }
    } else {
      // Если настройки нет, сохраняем значение по умолчанию
      await dbHelper.setSetting('sort_type', _sortType.index.toString());
    }

    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final dbHelper = DatabaseHelper();
    await dbHelper.setSetting('font_size', size.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final dbHelper = DatabaseHelper();
    await dbHelper.setSetting('theme_mode', mode == ThemeMode.dark ? '1' : '0');
    notifyListeners();
  }

  Future<void> setUseShortNames(bool useShort) async {
    _useShortNames = useShort;
    final dbHelper = DatabaseHelper();
    await dbHelper.setSetting('use_short_names', useShort ? '1' : '0');
    notifyListeners();
  }

  Future<void> setSortType(SortType type) async {
    if (_sortType != type) { // Только если сортировка действительно изменилась
      _sortType = type;
      final dbHelper = DatabaseHelper();
      await dbHelper.setSetting('sort_type', type.index.toString());
      notifyListeners(); // Уведомляем всех слушателей
    }
  }
}

enum SortType {
  none,       // Без сортировки
  name,       // По имени (алфавитный порядок)
  rankId      // По id сана (порядок важности)
}