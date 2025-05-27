import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde le token Firebase localement
Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('authToken', token); // Sauvegarde le token sous la clé 'authToken'
}

/// Récupère le token Firebase localement
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken'); // Retourne le token si disponible
}

/// Supprime le token Firebase
Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('authToken'); // Supprime le token sauvegardé
}

