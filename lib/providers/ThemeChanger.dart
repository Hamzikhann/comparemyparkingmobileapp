import 'package:flutter/material.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';

class ThemeChanger with ChangeNotifier {
  bool isDark = false;
  var _themeMode = ThemeMode.light;

  ThemeMode get getTheme => _themeMode;

  ThemeChanger() {
    loadTheme();
  }

  void _setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    _setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
    await SharedStorage.saveTheme(isDark);
  }

  Future<void> loadTheme() async {
    isDark = await SharedStorage.loadTheme();
    _setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
