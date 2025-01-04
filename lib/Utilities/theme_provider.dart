import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    // Load the saved theme mode when the provider is initialized
    _loadThemePreference();
  }

  void setLightMode() {
    _isDarkMode = false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    // Save the new theme preference in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.white,
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.black,
          );
  }
}
