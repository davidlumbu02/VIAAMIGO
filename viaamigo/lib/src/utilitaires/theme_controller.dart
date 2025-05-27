import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final fontScale = 1.0.obs;

  static const _themeKey = 'selectedThemeMode';
  static const _fontScaleKey = 'selectedFontScale';

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> _saveFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }

    final scale = prefs.getDouble(_fontScaleKey);
    if (scale != null) {
      fontScale.value = scale.clamp(1.0, 1.5);
    }
  }

  void setLightMode() {
    themeMode.value = ThemeMode.light;
    _saveThemeMode(ThemeMode.light);
  }

  void setDarkMode() {
    themeMode.value = ThemeMode.dark;
    _saveThemeMode(ThemeMode.dark);
  }

  void setSystemMode() {
    themeMode.value = ThemeMode.system;
    _saveThemeMode(ThemeMode.system);
  }

  void setFontScale(double scale) {
    fontScale.value = scale.clamp(1.0, 1.5);
    _saveFontScale(fontScale.value);
  }

  void resetFontScale() {
    fontScale.value = 1.0;
    _saveFontScale(1.0);
  }
}
/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final themeMode = ThemeMode.system.obs;

  static const _themeKey = 'selectedThemeMode';

  /// Sauvegarde le thème
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name); // Sauvegarde en string
  }

  /// Récupère le thème au lancement
  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Fonctions publiques
  void setLightMode() {
    themeMode.value = ThemeMode.light;
    _saveThemeMode(ThemeMode.light);
  }

  void setDarkMode() {
    themeMode.value = ThemeMode.dark;
    _saveThemeMode(ThemeMode.dark);
  }

  void setSystemMode() {
    themeMode.value = ThemeMode.system;
    _saveThemeMode(ThemeMode.system);
  }
}
*/