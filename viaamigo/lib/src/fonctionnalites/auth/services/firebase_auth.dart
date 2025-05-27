// 📦 Imports nécessaires pour Firebase Auth et les connexions sociales
// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';

// 🔐 Référence à Firebase Auth
final FirebaseAuth _auth = FirebaseAuth.instance;

// ✅ Inscription avec email et mot de passe
Future<UserCredential?> signUpWithEmailPassword({
  required String email,
  required String password,
}) async {
  try {
    // Crée un nouvel utilisateur Firebase
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Remplit les champs dans le SignupController
    signupController.updateField('email', email);
    signupController.updateField('provider', 'email');
    signupController.updateField('emailVerified', false);

    // Redirection vers la page nom + prénom
    Get.toNamed('/signup/name');
    return userCredential;
  } catch (e) {
    print('Erreur inscription email: $e');
    return null;
  }
}

// ✅ Connexion via Google
Future<UserCredential?> signInWithGoogle() async {
  try {
    // 1. Authentifie l'utilisateur avec Google
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // Annulation utilisateur

    // 2. Récupère les jetons d'identification Google
    final googleAuth = await googleUser.authentication;

    // 3. Crée les identifiants Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Se connecte à Firebase avec les identifiants
    final userCredential = await _auth.signInWithCredential(credential);

    // 5. Préremplit les données et gère le routage
    _handleSocialAuth(userCredential, provider: 'google');
    return userCredential;
  } catch (e) {
    print('Erreur Google sign-in: $e');
    return null;
  }
}

// ✅ Connexion via Apple
Future<UserCredential?> signInWithApple() async {
  try {
    // 1. Récupère les identifiants Apple
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // 2. Crée un identifiant OAuth pour Firebase
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // 3. Se connecte à Firebase avec ces identifiants
    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // 4. Gère l'inscription ou la connexion
    _handleSocialAuth(userCredential, provider: 'apple');
    return userCredential;
  } catch (e) {
    print('Erreur Apple sign-in: $e');
    return null;
  }
}

/* ✅ Connexion via Facebook (optionnel)
Future<UserCredential?> signInWithFacebook() async {
  try {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;

    final credential = FacebookAuthProvider.credential(result.accessToken!.token);
    final userCredential = await _auth.signInWithCredential(credential);

    _handleSocialAuth(userCredential, provider: 'facebook');
    return userCredential;
  } catch (e) {
    print('Erreur Facebook sign-in: $e');
    return null;
  }
}*/

// 🔄 Fonction partagée pour traiter les données sociales et router
void _handleSocialAuth(UserCredential userCredential, {required String provider}) {
  final user = userCredential.user;
  if (user == null) return;

  final names = user.displayName?.split(' ') ?? [];
  final firstName = names.isNotEmpty ? names.first : '';
  final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

  signupController.updateField('firstName', firstName);
  signupController.updateField('lastName', lastName);
  signupController.updateField('email', user.email);
  signupController.updateField('profilePicture', user.photoURL);
  signupController.updateField('provider', provider);
  signupController.updateField('emailVerified', user.emailVerified);

  final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
  if (isNew) {
    Get.toNamed('/signup/name');
  } else {
    Get.offAllNamed('/dashboard');
  }
}
