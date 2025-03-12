import 'package:flutter/material.dart';

class Settings with ChangeNotifier {
  double _fontSize = 20;
  ThemeMode _themeMode = ThemeMode.light;

  double get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}