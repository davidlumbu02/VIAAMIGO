// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔒 Stockage sécurisé

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // 🔒 Stocker le token

  // ✅ Écoute Firebase et met à jour le token automatiquement
  void autoRefreshToken() {
    _firebaseAuth.idTokenChanges().listen((User? user) async {
      if (user != null) {
        String? token = await user.getIdToken(true); // 🔄 Rafraîchir le token
        if (token != null) {
          await _storage.write(key: "firebase_token", value: token); // 🔒 Stocke le token
          print("🆕 Nouveau token Firebase : $token");
        }
      }
    });
  }

  // ✅ Récupérer le token stocké
  Future<String?> getToken() async {
    return await _storage.read(key: "firebase_token");
  }

  // ✅ Connexion avec email et mot de passe
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      autoRefreshToken(); // 🔄 Lancer le rafraîchissement après connexion
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ✅ Déconnexion
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _storage.delete(key: "firebase_token"); // 🔄 Supprimer le token stocké
    } catch (e) {
      throw Exception("La déconnexion a échoué. Veuillez réessayer.");
    }
  }

  // ✅ Connexion via Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _firebaseAuth.signInWithCredential(credential);
        autoRefreshToken(); // 🔄 Lancer le rafraîchissement après connexion
      } else {
        throw Exception("Connexion Google annulée.");
      }
    } catch (e) {
      throw Exception("Connexion Google échouée : $e");
    }
  }

  // ✅ Connexion via Apple (iOS/macOS)
  Future<void> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _firebaseAuth.signInWithCredential(credential);
      autoRefreshToken(); // 🔄 Lancer le rafraîchissement après connexion
    } catch (e) {
      throw Exception("Connexion Apple échouée : $e");
    }
  }

  // ✅ Connexion via Microsoft (Outlook)
  Future<void> signInWithMicrosoft() async {
    try {
      final OAuthProvider microsoftProvider = OAuthProvider("microsoft.com");
      await _firebaseAuth.signInWithProvider(microsoftProvider);
      autoRefreshToken(); // 🔄 Lancer le rafraîchissement après connexion
    } catch (e) {
      throw Exception("Connexion Microsoft échouée : $e");
    }
  }

  // 🔥 Gestion des erreurs FirebaseAuth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé pour cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'email-already-in-use':
        return "L'email est déjà utilisé.";
      case 'weak-password':
        return "Le mot de passe est trop faible.";
      case 'invalid-email':
        return "L'adresse email est invalide.";
      default:
        return "Une erreur s'est produite. Veuillez réessayer.";
    }
  }
}
