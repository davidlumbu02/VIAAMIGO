// ignore_for_file: avoid_print, unused_import
//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // 📌 Permet de manipuler les données JSON
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // 📌 Pour effectuer les requêtes HTTP
import 'package:viaamigo/src/fonctionnalites/auth/controllers/auth.dart'; // 📌 Importer Auth pour récupérer le token Firebase

// 🔹 Classe pour gérer les interactions avec l'API utilisateur
class UserService {
  // 📌 URL de base de l'API backend
  // final String baseUrl = 'http://10.0.2.2:3000/api/users'; // Pour un émulateur Android
  final String baseUrl = 'http://10.0.0.248:3000/api/users'; // 📌 Remplacez par l'IP de votre machine

  // ✅ Fonction pour récupérer automatiquement le token Firebase
  Future<String?> _getToken() async {
    return await Auth().getToken(); // 🔑 Récupérer le token Firebase stocké
  }

  // ✅ Enregistrer un utilisateur dans le backend
  Future<String> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 📌 Effectuer une requête POST vers l'endpoint d'enregistrement
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      // 📌 Vérifier si l'utilisateur a été créé avec succès
      if (response.statusCode == 201) {
        return '✅ Utilisateur créé avec succès.';
      } else {
        // 📌 Lire et afficher l'erreur retournée par le serveur
        final responseData = jsonDecode(response.body);
        final error = responseData['message'] ?? 'Erreur inconnue';
        return '❌ Erreur : $error';
      }
    } catch (e) {
      return '❌ Erreur réseau : $e';
    }
  }

  // ✅ Connexion d'un utilisateur et récupération du token
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // 📌 Effectuer une requête POST vers l'endpoint de connexion
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // 📌 Vérifier si la connexion a réussi
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final customToken = result['token'];

        // 🔑 Convertir le Custom Token en ID Token Firebase
        final idToken = await loginWithCustomToken(customToken);
        result['idToken'] = idToken; // 📌 Ajouter l'ID Token au résultat

        return result;
      } else {
        // 📌 Lire l'erreur retournée par le serveur
        final responseData = jsonDecode(response.body);
        final error = responseData['message'] ?? 'Erreur inconnue';
        throw Exception('❌ Erreur : $error');
      }
    } catch (e) {
      throw Exception('❌ Erreur réseau : $e');
    }
  }

  // ✅ Fonction générique pour envoyer des requêtes protégées avec le token Firebase
  Future<http.Response> _makeAuthenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("🚨 Aucun token disponible, l'utilisateur doit se reconnecter.");
    }

    Uri url = Uri.parse('$baseUrl/$endpoint');

    // 📌 Définition des en-têtes avec le token Firebase
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    print("🔐 Envoi de la requête $method à $url avec token...");

    // 📌 Gestion des différentes méthodes HTTP
    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception("🚨 Méthode HTTP non supportée : $method");
    }
  }

  // ✅ Récupérer les données de l'utilisateur connecté
  Future<Map<String, dynamic>> fetchUserData() async {
    final response = await _makeAuthenticatedRequest(endpoint: "profile", method: "GET");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Erreur : ${response.statusCode} - ${response.body}");
    }
  }

  // ✅ Mettre à jour le profil utilisateur
  Future<String> updateUserProfile(Map<String, dynamic> data) async {
    final response = await _makeAuthenticatedRequest(endpoint: "update-profile", method: "PUT", body: data);

    if (response.statusCode == 200) {
      return "✅ Profil mis à jour !";
    } else {
      throw Exception("❌ Erreur mise à jour : ${response.statusCode} - ${response.body}");
    }
  }

  // ✅ Déconnexion de l'utilisateur
  Future<String> logoutUser() async {
    String? token = await _getToken();
    if (token == null) return "🚨 Aucun token disponible.";

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return '✅ Déconnexion réussie.';
    } else {
      final responseData = jsonDecode(response.body);
      final error = responseData['message'] ?? 'Erreur inconnue';
      return '❌ Erreur : $error';
    }
  }

  // ✅ Convertir un Custom Token en ID Token Firebase
  Future<String> loginWithCustomToken(String customToken) async {
    try {
      // 📌 Connexion avec le Custom Token
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      // 📌 Récupérer l'ID Token Firebase
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('❌ ID Token est null. Impossible de continuer.');
      }

      print('🆕 ID Token récupéré : $idToken');
      return idToken;
    } catch (e) {
      print('❌ Erreur Custom Token : $e');
      throw Exception('❌ Erreur lors de la connexion.');
    }
  }
}



/*

Voici un exemple de fichier JSON qui pourrait être décodé par la méthode jsonDecode(response.body) dans ton code :

Exemple de fichier JSON

{
  "status": "error",
  "message": "Nom d'utilisateur déjà utilisé",
  "code": 400,
  "details": {
    "field": "username",
    "issue": "already_exists"
  }
}
Explication
status : Indique l'état de la réponse (par exemple, "error", "success").
message : Fournit un message d'erreur ou de succès lisible.
code : Indique le code HTTP ou un code d'erreur interne.
details : Fournit des informations supplémentaires, comme le champ qui a causé l'erreur et le problème spécifique.
 */


/*
Requête HTTP envoyée :


POST /api/users/register HTTP/1.1
Host: 10.0.2.2:3000
Content-Type: application/json

{
  "name": "David",
  "email": "david@example.com",
  "password": "password123"
} 


Backend reçoit les données :

Ces données arrivent dans :

req.body = {
  name: "David",
  email: "david@example.com",
  password: "password123"
};


*/