//ThemeMode và thông báo khi theme thay đổi
// ThemeProvider lưu trữ _themeMode (ThemeMode.system, light, hoặc dark).
// setThemeMode cập nhật theme và thông báo cho các widget lắng nghe (như MaterialApp).
//
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//
// class ThemeProvider with ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.system;
//
//   ThemeMode get themeMode => _themeMode;
//
//   void setThemeMode(ThemeMode mode) {
//     _themeMode = mode;
//     notifyListeners();
//   }
// }
//

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const _themeKey = 'theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == themeString,
      );
      notifyListeners();
    }
  }
}