// 📦 Firebase & GetX imports
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/user_devices_controller.dart';
// NOUVEAU: Import du NavigationController
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:viaamigo/shared/widgets/app_shell.dart'; // NOUVEAU: Import de AppShell

/// 🔐 Authentification centralisée avec GetX + Firebase
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔁 Stream utilisateur
  late final Rx<User?> firebaseUser;

  /// 👤 Utilisateur connecté
  User? get currentUser => _auth.currentUser;
  
  /// 🔍 Vérifie si un utilisateur est connecté
  bool isLoggedIn() => _auth.currentUser != null && !_auth.currentUser!.isAnonymous;
  bool _hasHandledAuth = false; // ✅ pour éviter les redirections multiples

  @override
  void onInit() {
    super.onInit();
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleAuthChanges);
    // 🔄 Active l'écoute du token FCM ici
    listenToTokenRefresh();
  }

  /// 🔐 Récupère l'UID de l'utilisateur de façon sécurisée avec try/catch
  String? tryGetUid() {
    try {
      final uid = firebaseUser.value?.uid;
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
      return null; // UID absent ou vide
    } catch (e) {
      print('⚠️ Erreur lors de la récupération de l\'UID : $e');
      return null;
    }
  }

  /// 🔐 Récupère l'UID de l'utilisateur connecté, de façon asynchrone et sécurisée // 🔐 Recharge Firebase pour s'assurer que l'utilisateur est bien synchronisé
  Future<String?> getUidAsync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // pour s'assurer que les données sont fraîches
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.uid.isNotEmpty) {
        return refreshedUser.uid;
      }
      return null;
    } catch (e) {
      print('⚠️ Erreur dans getUidAsync : $e');
      return null;
    }
  }
  /// 🔍 Récupère les informations techniques de l'appareil actuel
  /// Utilisé pour enregistrer les détails du device dans Firestore
  Future<Map<String, String>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform(); // version + build
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'model': '${androidInfo.brand} ${androidInfo.model}',         // Exemple : Samsung SM-A515F
        'osVersion': 'Android ${androidInfo.version.release}',        // Exemple : Android 13
        'appVersion': appVersion,                                     // Exemple : 1.0.0+5
        'deviceName': androidInfo.device                              // Nom système de l'appareil
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'model': iosInfo.utsname.machine,                             // Exemple : iPhone14,3
        'osVersion': '${iosInfo.systemName} ${iosInfo.systemVersion}',// Exemple : iOS 16.4
        'appVersion': appVersion,
        'deviceName': iosInfo.name                                    // Exemple : "iPhone de David"
      };
    } else {
      return {
        'model': 'Unknown',
        'osVersion': 'Unknown',
        'appVersion': appVersion,
        'deviceName': 'Unknown Device',
      };
    }
  }

  /// 🔄 Met à jour le token FCM dans Firestore
  /// 🔄 Enregistre le token FCM et les infos du device dans Firestore
  /// ⚠️ Marque tous les autres appareils comme inactifs (`isCurrentDevice: false`)
  Future<void> updateFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('❌ Impossible de récupérer le token FCM');
        return;
      }

      // 📲 Récupération des infos de l'appareil actuel
      final deviceInfo = await _getDeviceInfo();

      final devicesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices');

      // ❌ Désactive tous les autres appareils de l'utilisateur
      final devicesSnapshot = await devicesRef.get();
      for (final doc in devicesSnapshot.docs) {
        await doc.reference.update({'isCurrentDevice': false});
      }

      // ✅ Enregistre ou met à jour l'appareil courant
      await devicesRef.doc(token).set({
        'fcmToken': token,
        'platform': GetPlatform.isAndroid
            ? 'android'
            : GetPlatform.isIOS
                ? 'ios'
                : 'unknown',
        'model': deviceInfo['model'],
        'osVersion': deviceInfo['osVersion'],
        'appVersion': deviceInfo['appVersion'],
        'lastUsedAt': FieldValue.serverTimestamp(),
        'isCurrentDevice': true,
        'deviceName': deviceInfo['deviceName'],
      }, SetOptions(merge: true));

      print('✅ Token FCM mis à jour : $token');
    } catch (e) {
      print('❌ updateFcmToken error: $e');
    }
  }

  /// 🔄 Écoute les changements de token FCM et met à jour Firestore automatiquement
  /// 🛰 Écoute les changements automatiques de token FCM (ex: après réinstallation)
  /// Met à jour Firestore en conséquence, en désactivant les anciens tokens
  void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        final deviceInfo = await _getDeviceInfo();

        final devicesRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('devices');

        // ❌ Met à jour tous les anciens tokens comme inactifs
        final devicesSnapshot = await devicesRef.get();
        for (final doc in devicesSnapshot.docs) {
          await doc.reference.update({'isCurrentDevice': false});
        }

        // ✅ Enregistre le nouveau token actif avec les infos de l'appareil
        await devicesRef.doc(newToken).set({
          'fcmToken': newToken,
          'platform': GetPlatform.isAndroid
              ? 'android'
              : GetPlatform.isIOS
                  ? 'ios'
                  : 'unknown',
          'model': deviceInfo['model'],
          'osVersion': deviceInfo['osVersion'],
          'appVersion': deviceInfo['appVersion'],
          'lastUsedAt': FieldValue.serverTimestamp(),
          'isCurrentDevice': true,
          'deviceName': deviceInfo['deviceName'],
        }, SetOptions(merge: true));

        print('🔄 Token FCM mis à jour automatiquement : $newToken');
      } catch (e) {
        print('❌ Erreur lors de l ecoute des mises à jour de token FCM : $e');
      }
    });
  }

  /// Gestion des changements d'authentification
  void _handleAuthChanges(User? user) async {
  await Future.delayed(const Duration(milliseconds: 100));

  try {
    final userController = Get.find<UserController>();
    final signupController = Get.find<SignupController>();

    if (user == null) {
      _hasHandledAuth = false; // Réinitialiser
      signupController.resetAll();
      userController.reset();
      Get.offAllNamed('/welcomePage');
      return;
    }

    if (_hasHandledAuth) {
      print("⏩ Redirection déjà effectuée, on ne fait rien.");
      return;
    }
    _hasHandledAuth = true; // ✅ Empêche redirection multiple

    if (user.isAnonymous) {
      Get.offAll(() => AppShell());
      Get.find<NavigationController>().goToTab(0);
      return;
    }

    userController.reset();
    await userController.fetchUserData();

    await updateFcmToken();
    await Get.find<UserDevicesController>().setCurrentDeviceOnly();

    // ✅ Laisse l'utilisateur où il est (pas de redirection automatique)
    print('✅ Auth initialisée, pas de redirection imposée.');

  } catch (e, stack) {
    print('❌ Erreur dans _handleAuthChanges : $e');
    print('🧵 Stack: $stack');
    Get.offAllNamed('/welcomePage');
  }
}

  /*void _handleAuthChanges(User? user) async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final userController = Get.find<UserController>();
      final signupController = Get.find<SignupController>();

      // Si l'utilisateur est déconnecté
      if (user == null) {
        signupController.resetAll();
        userController.reset();
        
        // MODIFIÉ: Utiliser la route standard sans NavigationController
        Get.offAllNamed('/welcomePage');
        return;
      }

      // Si l'utilisateur est anonyme
      if (user.isAnonymous) {
        // MODIFIÉ: Utiliser AppShell avec NavigationController
        Get.offAll(() => AppShell());
        Get.find<NavigationController>().goToTab(0);
        return;
      }

      // On charge juste les données sans redirection
      userController.reset();
      await userController.fetchUserData();

      await updateFcmToken();
      await Get.find<UserDevicesController>().setCurrentDeviceOnly();

      // ✅ Reste sur la route actuelle. Ne fais rien.
      // L'utilisateur choisit manuellement son flow (signup ou dashboard)

    } catch (e, stack) {
      print('❌ Erreur dans _handleAuthChanges : $e');
      print('🧵 Stack: $stack');
      Get.offAllNamed('/welcomePage');
    }
  }*/

  /// ✅ Création avec email/mot de passe
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await sendEmailVerification();
      _handleCreate(userCredential, provider: 'email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 🔐 Connexion email/password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _handleCreate(userCredential, provider: 'email');
      
      // NOUVEAU: Redirection vers AppShell après connexion réussie
      Get.offAll(() => AppShell());
      Get.find<NavigationController>().goToTab(0);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 📩 Envoie email vérification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      Get.snackbar('Verification', 'A verification email has been sent.');
    } catch (_) {
      Get.snackbar('Error', 'Could not send verification email.');
    }
  }

  /// 🔐 Connexion Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _handleCreate(userCredential, provider: 'google');
      
      // NOUVEAU: Redirection vers AppShell après connexion réussie
      Get.offAll(() => AppShell());
      Get.find<NavigationController>().goToTab(0);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 🔐 Connexion Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      _handleCreate(userCredential, provider: 'apple');
      
      // NOUVEAU: Redirection vers AppShell après connexion réussie
      Get.offAll(() => AppShell());
      Get.find<NavigationController>().goToTab(0);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }
  
  /// 👻 Connexion anonyme
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      // NOUVEAU: Redirection vers AppShell après connexion anonyme
      Get.offAll(() => AppShell());
      Get.find<NavigationController>().goToTab(0);
      
      return credential;
    } catch (_) {
      Get.snackbar('Error', 'Anonymous login failed');
      return null;
    }
  }

  /// 📱 Auth par numéro
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// 🔗 Lien avec Google
  Future<UserCredential?> linkGoogleProvider() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.currentUser?.linkWithCredential(credential);
    } catch (_) {
      Get.snackbar('Error', 'Could not link Google account.');
      return null;
    }
  }

  /// 🔄 Rafraîchit les données utilisateur
  Future<void> refreshUserData() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        Get.find<SignupController>().updateField('emailVerified', user.emailVerified);
      }
    } catch (e) {
      print('Refresh error: $e');
    }
  }

  /// 👤 MAJ du profil
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);

      final signupController = Get.find<SignupController>();
      signupController.updateField('firstName', displayName?.split(' ').first ?? '');
      signupController.updateField('lastName', displayName?.split(' ').skip(1).join(' ') ?? '');
      signupController.updateField('profilePicture', photoURL);

      Get.snackbar('Success', 'Profile updated');
    } catch (_) {
      Get.snackbar('Error', 'Profile update failed');
    }
  }

  /// 🗑️ Suppression du compte
  Future<bool> deleteAccount({required String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (user.providerData.any((p) => p.providerId == 'password') && password != null) {
        final credentials = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credentials);
      }

      await user.delete();
      Get.offAllNamed('/welcomePage');
      return true;
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete account.');
      return false;
    }
  }

  /// 🚪 Déconnexion complète de l'utilisateur
  /// Cette méthode gère la déconnexion Firebase + des fournisseurs externes (Google, Facebook, etc.)
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;

      // 🔍 Aucun utilisateur connecté
      if (user == null) {
        Get.snackbar('Erreur', 'Aucun utilisateur connecté');
        return;
      }

      // 🧩 Liste des fournisseurs utilisés (ex: google.com, apple.com, password)
      final providers = user.providerData.map((p) => p.providerId).toList();

      // 👻 Si utilisateur anonyme, afficher un message spécifique
      if (user.isAnonymous) {
        Get.snackbar('Anonyme', 'Votre session anonyme a été fermée.');
      }

      // ✅ Déconnexion Firebase
      await _auth.signOut();

      // 🔌 Déconnexion Google (si utilisé comme fournisseur)
      if (providers.contains('google.com')) {
        await GoogleSignIn().signOut();
      }

      // 🔌 Déconnexion Apple : rien à faire ici car Apple ne fournit pas de méthode logout

      // ✅ Réinitialiser les données d'inscription
      if (Get.isRegistered<SignupController>()) {
        Get.find<SignupController>().resetAll();
      }

      // ✅ Réinitialiser les données utilisateur
      if (Get.isRegistered<UserController>()) {
        Get.find<UserController>().reset();
      }

      // ✅ Redirection vers la page d'accueil
      Get.offAllNamed('/welcomePage');
    } catch (e) {
      // ❌ En cas d'échec
      Get.snackbar('Erreur', 'Déconnexion échouée');
      print('❌ SignOut Error: $e');
    }
  }

  /// 💬 Remplit les données dans le controller global
  void _handleCreate(UserCredential userCredential, {required String provider}) {
    final user = userCredential.user;
    if (user == null) return;

    final nameParts = user.displayName?.split(' ') ?? [];
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // 🧠 Mets à jour les champs dans le signupController
    final signupController = Get.find<SignupController>();
    signupController.updateField('firstName', firstName);
    signupController.updateField('lastName', lastName);
    signupController.updateField('email', user.email);
    signupController.updateField('profilePicture', user.photoURL);
    signupController.updateField('provider', provider);
    signupController.updateField('emailVerified', user.emailVerified);

    // ✅ 🔥 Mets à jour Firestore via UserController
    final userController = Get.find<UserController>();

    // Mise à jour seulement si différent
    if (user.photoURL != null &&
        userController.currentUser.value?.profilePicture != user.photoURL) {
      userController.updateFields({
        'firstName': firstName,
        'lastName': lastName,
        'profilePicture': user.photoURL,
        'email': user.email ?? '',
        'emailVerified': user.emailVerified,
        'provider': provider,
      });
    }
  }
}

/// 📦 Classe utilitaire pour messages d'erreurs Firebase
class AuthFailure {
  static String errorMessageFromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-verification-code':
        return 'The SMS code entered is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid or expired.';
      case 'session-expired':
        return 'The verification session has expired.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
}
/*import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/user_devices_controller.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



/// 🔐 Authentification centralisée avec GetX + Firebase
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔁 Stream utilisateur
   late final Rx<User?> firebaseUser;

  /// 👤 Utilisateur connecté
  User? get currentUser => _auth.currentUser;

@override
  void onInit() {
  super.onInit();
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleAuthChanges);
     // 🔄 Active l’écoute du token FCM ici
  listenToTokenRefresh();
  }

  /// 🔐 Récupère l'UID de l'utilisateur de façon sécurisée avec try/catch
String? tryGetUid() {
  try {
    final uid = firebaseUser.value?.uid;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    return null; // UID absent ou vide
  } catch (e) {
    print('⚠️ Erreur lors de la récupération de l\'UID : $e');
    return null;
  }
}

/// 🔐 Récupère l'UID de l'utilisateur connecté, de façon asynchrone et sécurisée // 🔐 Recharge Firebase pour s’assurer que l’utilisateur est bien synchronisé
Future<String?> getUidAsync() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // pour s'assurer que les données sont fraîches
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.uid.isNotEmpty) {
      return refreshedUser.uid;
    }
    return null;
  } catch (e) {
    print('⚠️ Erreur dans getUidAsync : $e');
    return null;
  }
}
/// 🔍 Récupère les informations techniques de l'appareil actuel
/// Utilisé pour enregistrer les détails du device dans Firestore
Future<Map<String, String>> _getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final packageInfo = await PackageInfo.fromPlatform(); // version + build
  final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return {
      'model': '${androidInfo.brand} ${androidInfo.model}',         // Exemple : Samsung SM-A515F
      'osVersion': 'Android ${androidInfo.version.release}',        // Exemple : Android 13
      'appVersion': appVersion,                                     // Exemple : 1.0.0+5
      'deviceName': androidInfo.device                              // Nom système de l'appareil
    };
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return {
      'model': iosInfo.utsname.machine,                             // Exemple : iPhone14,3
      'osVersion': '${iosInfo.systemName} ${iosInfo.systemVersion}',// Exemple : iOS 16.4
      'appVersion': appVersion,
      'deviceName': iosInfo.name                                    // Exemple : "iPhone de David"
    };
  } else {
    return {
      'model': 'Unknown',
      'osVersion': 'Unknown',
      'appVersion': appVersion,
      'deviceName': 'Unknown Device',
    };
  }
}


/// 🔄 Met à jour le token FCM dans Firestore
/// 🔄 Enregistre le token FCM et les infos du device dans Firestore
/// ⚠️ Marque tous les autres appareils comme inactifs (`isCurrentDevice: false`)
Future<void> updateFcmToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print('❌ Impossible de récupérer le token FCM');
      return;
    }

    // 📲 Récupération des infos de l'appareil actuel
    final deviceInfo = await _getDeviceInfo();

    final devicesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices');

    // ❌ Désactive tous les autres appareils de l'utilisateur
    final devicesSnapshot = await devicesRef.get();
    for (final doc in devicesSnapshot.docs) {
      await doc.reference.update({'isCurrentDevice': false});
    }

    // ✅ Enregistre ou met à jour l'appareil courant
    await devicesRef.doc(token).set({
      'fcmToken': token,
      'platform': GetPlatform.isAndroid
          ? 'android'
          : GetPlatform.isIOS
              ? 'ios'
              : 'unknown',
      'model': deviceInfo['model'],
      'osVersion': deviceInfo['osVersion'],
      'appVersion': deviceInfo['appVersion'],
      'lastUsedAt': FieldValue.serverTimestamp(),
      'isCurrentDevice': true,
      'deviceName': deviceInfo['deviceName'],
    }, SetOptions(merge: true));

    print('✅ Token FCM mis à jour : $token');
  } catch (e) {
    print('❌ updateFcmToken error: $e');
  }
}


/// 🔄 Écoute les changements de token FCM et met à jour Firestore automatiquement
/// 🛰 Écoute les changements automatiques de token FCM (ex: après réinstallation)
/// Met à jour Firestore en conséquence, en désactivant les anciens tokens
void listenToTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final deviceInfo = await _getDeviceInfo();

      final devicesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices');

      // ❌ Met à jour tous les anciens tokens comme inactifs
      final devicesSnapshot = await devicesRef.get();
      for (final doc in devicesSnapshot.docs) {
        await doc.reference.update({'isCurrentDevice': false});
      }

      // ✅ Enregistre le nouveau token actif avec les infos de l'appareil
      await devicesRef.doc(newToken).set({
        'fcmToken': newToken,
        'platform': GetPlatform.isAndroid
            ? 'android'
            : GetPlatform.isIOS
                ? 'ios'
                : 'unknown',
        'model': deviceInfo['model'],
        'osVersion': deviceInfo['osVersion'],
        'appVersion': deviceInfo['appVersion'],
        'lastUsedAt': FieldValue.serverTimestamp(),
        'isCurrentDevice': true,
        'deviceName': deviceInfo['deviceName'],
      }, SetOptions(merge: true));

      print('🔄 Token FCM mis à jour automatiquement : $newToken');
    } catch (e) {
      print('❌ Erreur lors de l’écoute des mises à jour de token FCM : $e');
    }
  });
}


void _handleAuthChanges(User? user) async {
  await Future.delayed(const Duration(milliseconds: 100));

  try {
    final userController = Get.find<UserController>();
    final signupController = Get.find<SignupController>();

    if (user == null) {
      signupController.resetAll();
      userController.reset();
      Get.offAllNamed('/welcomePage');
      return;
    }

    if (user.isAnonymous) {
      Get.offAllNamed('/dashboard');
      return;
    }

    // On charge juste les données sans redirection
    userController.reset();
    await userController.fetchUserData();

    await updateFcmToken();
    await Get.find<UserDevicesController>().setCurrentDeviceOnly();

    // ✅ Reste sur la route actuelle. Ne fais rien.
    // L'utilisateur choisit manuellement son flow (signup ou dashboard)

  } catch (e, stack) {
    print('❌ Erreur dans _handleAuthChanges : $e');
    print('🧵 Stack: $stack');
    Get.offAllNamed('/welcomePage');
  }
}



  /// ✅ Création avec email/mot de passe
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await sendEmailVerification();
      _handleCreate(userCredential, provider: 'email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 🔐 Connexion email/password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _handleCreate(userCredential, provider: 'email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 📩 Envoie email vérification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      Get.snackbar('Verification', 'A verification email has been sent.');
    } catch (_) {
      Get.snackbar('Error', 'Could not send verification email.');
    }
  }

  /// 🔐 Connexion Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _handleCreate(userCredential, provider: 'google');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }

  /// 🔐 Connexion Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      _handleCreate(userCredential, provider: 'apple');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', AuthFailure.errorMessageFromCode(e.code));
      return null;
    }
  }
  

  /// 👻 Connexion anonyme
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (_) {
      Get.snackbar('Error', 'Anonymous login failed');
      return null;
    }
  }

  /// 📱 Auth par numéro
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// 🔗 Lien avec Google
  Future<UserCredential?> linkGoogleProvider() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.currentUser?.linkWithCredential(credential);
    } catch (_) {
      Get.snackbar('Error', 'Could not link Google account.');
      return null;
    }
  }

  /// 🔄 Rafraîchit les données utilisateur
  Future<void> refreshUserData() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        signupController.updateField('emailVerified', user.emailVerified);
      }
    } catch (e) {
      print('Refresh error: $e');
    }
  }

  /// 📊 Journalisation simple
  //void _logAuthEvent(String event, {Map<String, dynamic>? params}) {
   // print('AuthEvent: $event ${params ?? ''}');
 // }

  /// 👤 MAJ du profil
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);

      signupController.updateField('firstName', displayName?.split(' ').first ?? '');
      signupController.updateField('lastName', displayName?.split(' ').skip(1).join(' ') ?? '');
      signupController.updateField('profilePicture', photoURL);

      Get.snackbar('Success', 'Profile updated');
    } catch (_) {
      Get.snackbar('Error', 'Profile update failed');
    }
  }

  /// 🗑️ Suppression du compte
  Future<bool> deleteAccount({required String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (user.providerData.any((p) => p.providerId == 'password') && password != null) {
        final credentials = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credentials);
      }

      await user.delete();
      Get.offAllNamed('/welcomePage');
      return true;
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete account.');
      return false;
    }
  }

/// 🚪 Déconnexion complète de l'utilisateur
/// Cette méthode gère la déconnexion Firebase + des fournisseurs externes (Google, Facebook, etc.)
/// 🚪 Déconnexion sécurisée de l'utilisateur
Future<void> signOut() async {
  try {
    final user = _auth.currentUser;

    // 🔍 Aucun utilisateur connecté
    if (user == null) {
      Get.snackbar('Erreur', 'Aucun utilisateur connecté');
      return;
    }

    // 🧩 Liste des fournisseurs utilisés (ex: google.com, apple.com, password)
    final providers = user.providerData.map((p) => p.providerId).toList();

    // 👻 Si utilisateur anonyme, afficher un message spécifique
    if (user.isAnonymous) {
      Get.snackbar('Anonyme', 'Votre session anonyme a été fermée.');
    }

    // ✅ Déconnexion Firebase
    await _auth.signOut();

    // 🔌 Déconnexion Google (si utilisé comme fournisseur)
    if (providers.contains('google.com')) {
      await GoogleSignIn().signOut();
    }

    // 🔌 Déconnexion Apple : rien à faire ici car Apple ne fournit pas de méthode logout

    // ✅ Réinitialiser les données d'inscription
    if (Get.isRegistered<SignupController>()) {
      Get.find<SignupController>().resetAll();
    }

    // ✅ Réinitialiser les données utilisateur (évite que la photo, email, etc. persistent)
    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().reset(); // ← Très important pour purger les infos
    }

    // ✅ Redirection vers la page d’accueil
    Get.offAllNamed('/welcomePage');
  } catch (e) {
    // ❌ En cas d’échec
    Get.snackbar('Erreur', 'Déconnexion échouée');
    print('❌ SignOut Error: $e');
  }
}


  /// 💬 Remplit les données dans le controller global
  void _handleCreate(UserCredential userCredential, {required String provider}) {
  final user = userCredential.user;
  if (user == null) return;

  final nameParts = user.displayName?.split(' ') ?? [];
  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  // 🧠 Mets à jour les champs dans le signupController (local temporaire)
  signupController.updateField('firstName', firstName);
  signupController.updateField('lastName', lastName);
  signupController.updateField('email', user.email);
  signupController.updateField('profilePicture', user.photoURL);
  signupController.updateField('provider', provider);
  signupController.updateField('emailVerified', user.emailVerified);

  // ✅ 🔥 Mets à jour Firestore via UserController pour synchroniser la photo et infos
  final userController = Get.find<UserController>();

  // BONUS : mise à jour seulement si différent
  if (user.photoURL != null &&
      userController.currentUser.value?.profilePicture != user.photoURL) {
    userController.updateFields({
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': user.photoURL,
      'email': user.email ?? '',
      'emailVerified': user.emailVerified,
      'provider': provider,
    });
  }
}

  /*void _handleCreate(UserCredential userCredential, {required String provider}) {
    final user = userCredential.user;
    if (user == null) return;

    final nameParts = user.displayName?.split(' ') ?? [];
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    signupController.updateField('firstName', firstName);
    signupController.updateField('lastName', lastName);
    signupController.updateField('email', user.email);
    signupController.updateField('profilePicture', user.photoURL);
    signupController.updateField('provider', provider);
    signupController.updateField('emailVerified', user.emailVerified);
  }*/
}

/// 📦 Classe utilitaire pour messages d’erreurs Firebase
class AuthFailure {
  static String errorMessageFromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-verification-code':
        return 'The SMS code entered is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid or expired.';
      case 'session-expired':
        return 'The verification session has expired.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
}
*/
/*void _handleAuthChanges(User? user) async {
  await Future.delayed(const Duration(milliseconds: 100));

  try {
    final signupController = Get.find<SignupController>();
    final userController = Get.find<UserController>();

    if (user == null) {
      signupController.resetAll();
      userController.reset();
      Get.offAllNamed('/welcomePage');
      return;
    }

    if (user.isAnonymous) {
      print('👻 Utilisateur anonyme');
      Get.offAllNamed('/dashboard');
      return;
    }

    userController.reset();
    await userController.fetchUserData();

    await updateFcmToken();
    await Get.find<UserDevicesController>().setCurrentDeviceOnly();

    final isSignupComplete = signupController.isComplete;
    final isPasswordLogin = user.providerData.any((p) => p.providerId == 'password');

    if (!user.emailVerified && isPasswordLogin) {
      print('🔔 Redirection vers vérification email');
      Get.offAllNamed('/signup/verify');
    } else if (!isSignupComplete) {
      print('📄 Signup incomplet → reprise à ${signupController.currentStepRoute.value}');
      Get.offAllNamed(signupController.currentStepRoute.value); // ✅ Dynamique
    } else {
      print('✅ Redirection dashboard');
      Get.offAllNamed('/dashboard');
    }

  } catch (e, stack) {
    print('❌ Erreur dans _handleAuthChanges : $e');
    print('🧵 Stack: $stack');
    Get.offAllNamed('/welcomePage');
  }
}*/



/*
void _handleAuthChanges(User? user) {
  Future.delayed(const Duration(milliseconds: 100), () {
    try {
      if (user == null) {
        Get.offAllNamed('/welcomePage');
      } else if (!user.emailVerified &&
          user.providerData.any((p) => p.providerId == 'password')) {
        Get.offAllNamed('/signup/verify');
      } else {
        // ✅ Double sécurité : s'assurer que UID n'est pas null
        if (user.uid.isNotEmpty) {
          Get.offAllNamed('/dashboard');
        } else {
          print('⚠️ UID utilisateur est vide, redirection annulée');
        }
      }
    } catch (e, stack) {
      print('❌ Erreur dans _handleAuthChanges : $e');
      print('🧵 Stack: $stack');
      Get.offAllNamed('/welcomePage');
    }
  });
}*/


  /*/ 🎯 Redirection auto selon statut utilisateur
  void _handleAuthChanges(User? user) {
    if (user == null) {
      Get.offAllNamed('/welcomePage');
    } else if (!user.emailVerified &&
        user.providerData.any((p) => p.providerId == 'password')) {
      Get.offAllNamed('/verify-email');
    } else {
      Get.offAllNamed('/dashboard');
    }
  }*/
