import 'package:flutter/material.dart';
import 'database_helper.dart';

class Settings with ChangeNotifier {
  double _fontSize = 20;
  ThemeMode _themeMode = ThemeMode.light;

  Settings() {
    _loadSettings();
  }

  double get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadSettings() async {
    final dbHelper = DatabaseHelper();
    final settings = await dbHelper.loadSettings();

    if (settings.isNotEmpty) {
      _fontSize = settings['fontSize'] as double;
      _themeMode = settings['themeMode'] == 0 ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  //todo рефакторинг
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final dbHelper = DatabaseHelper();
    await dbHelper.saveSettings(_fontSize, _themeMode == ThemeMode.light ? 0 : 1);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final dbHelper = DatabaseHelper();
    await dbHelper.saveSettings(_fontSize, _themeMode == ThemeMode.light ? 0 : 1);
    notifyListeners();
  }
}