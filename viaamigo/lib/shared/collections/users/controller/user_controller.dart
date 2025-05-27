// 📁 lib/shared/controllers/user_controller.dart

// ignore_for_file: avoid_print
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:viaamigo/shared/collections/users/model/user_model.dart';
import 'package:viaamigo/shared/collections/users/services/user_service.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/badges_controller.dart';
//import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/devices_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/document_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/driver_preference_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/sender_preference_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/settings_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/travel_patterns_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/user_devices_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/vehicule_controller.dart';

/// 🎛️ Contrôleur GetX pour la gestion centralisée de l'utilisateur connecté
class UserController extends GetxController {
  final UserService _userService = UserService();

  /// Utilisateur actuel (observable)
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  /// Chargement des données utilisateur
  final RxBool isLoading = false.obs;

  /// Dernière erreur (si présente)
  final RxString error = ''.obs;

  /// 🔁 Initialisation automatique à la connexion
  @override
  void onInit() {
    super.onInit();
    injectAllControllers(); // Injecter tous les contrôleurs nécessaires
    _loadCurrentUser();
  }

  void reset() {
  currentUser.value = null;
  error.value = '';
  isLoading.value = false;
}

  //✅ permanent: true garantit que les contrôleurs ne sont pas supprimés trop tôt (ex. après /signup).
void injectAllControllers() {
  if (!Get.isRegistered<UserSettingsController>()) {
    Get.put(UserSettingsController(), permanent: true);
  }
  if (!Get.isRegistered<VehicleController>()) {
    Get.put(VehicleController(), permanent: true);
  }
  if (!Get.isRegistered<TravelPatternController>()) {
    Get.put(TravelPatternController(), permanent: true);
  }
  if (!Get.isRegistered<DriverPreferencesController>()) {
    Get.put(DriverPreferencesController(), permanent: true);
  }
  if (!Get.isRegistered<SenderPreferencesController>()) {
    Get.put(SenderPreferencesController(), permanent: true);
  }
  if (!Get.isRegistered<UserDocumentsController>()) {
    Get.put(UserDocumentsController(), permanent: true);
  }
  if (!Get.isRegistered<UserDevicesController>()) {
    Get.put(UserDevicesController(), permanent: true);
  }
  if (!Get.isRegistered<UserBadgesController>()) {
    Get.put(UserBadgesController(), permanent: true);
  }
}


  /// 📦 Charge les données de l'utilisateur actuellement connecté
  Future<void> _loadCurrentUser() async {
    isLoading.value = true;
    error.value = '';

    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
      } else {
        error.value = 'Utilisateur non trouvé';
      }
    } catch (e) {
      error.value = 'Erreur de chargement: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔁 Rafraîchit les données utilisateur (ex: après mise à jour distante)
  Future<void> refreshUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final updated = await _userService.getUserById(uid);
      if (updated != null) currentUser.value = updated;
    }
  }

  /// 🧠 Met à jour un ou plusieurs champs spécifiques
  Future<void> updateFields(Map<String, dynamic> fields) async {
    try {
      if (currentUser.value != null) {
        await _userService.updateFields(currentUser.value!.uid, fields);
        await refreshUser();
      }
    } catch (e) {
      error.value = 'Erreur de mise à jour: $e';
    }
  }

  /// 📍 Met à jour la position GPS
  Future<void> updateLocation(double lat, double lng) async {
    if (currentUser.value == null) return;
    await _userService.updateLocation(currentUser.value!.uid, lat, lng);
    await refreshUser();
  }

  /// ✅ Changer le statut de l’utilisateur (ex: actif/inactif/suspendu)
  Future<void> setStatus(String newStatus) async {
    if (currentUser.value == null) return;
    await _userService.updateStatus(currentUser.value!.uid, newStatus);
    await refreshUser();
  }

  /// 💳 Modifie le solde du portefeuille
  Future<void> adjustWallet(double amount, {bool isCredit = true}) async {
    if (currentUser.value == null) return;
    await _userService.updateWalletBalance(
      currentUser.value!.uid,
      amount,
      isIncrement: isCredit,
    );
    await refreshUser();
  }

  /// 🚫 Bloque un autre utilisateur
  Future<void> blockUser(String targetUid) async {
    if (currentUser.value == null) return;
    await _userService.blockUser(currentUser.value!.uid, targetUid);
    await refreshUser();
  }

  /// ✅ Débloque un utilisateur
  Future<void> unblockUser(String targetUid) async {
    if (currentUser.value == null) return;
    await _userService.unblockUser(currentUser.value!.uid, targetUid);
    await refreshUser();
  }

  /// 🧾 Récupère les transactions liées à l’utilisateur
  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (currentUser.value == null) return [];
    return await _userService.getUserTransactions(currentUser.value!.uid);
  }

  /// 📡 Écoute les transactions en temps réel
  Stream<List<Map<String, dynamic>>> get transactionsStream {
    if (currentUser.value == null) return const Stream.empty();
    return _userService.getUserTransactionsStream(currentUser.value!.uid);
  }

  /// 🗑 Supprime l’utilisateur actuel de Firestore
  Future<void> deleteUser() async {
    if (currentUser.value == null) return;
    await _userService.deleteUser(currentUser.value!.uid);
    currentUser.value = null;
  }


  /// 🔄 Charge les données Firestore de l'utilisateur actuellement connecté
Future<void> fetchUserData() async {
  try {
    // Récupère l'UID de l'utilisateur connecté via Firebase Auth
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      print('❌ Aucun utilisateur connecté.');
      return;
    }

    // Utilise le service pour récupérer le document utilisateur depuis Firestore
    final user = await _userService.getUserById(uid);

    // Si trouvé, met à jour le champ réactif (observable) `currentUser`
    if (user != null) {
      currentUser.value = user;
      print('✅ Données utilisateur chargées : ${user.email}');
    } else {
      print('⚠️ Aucun document utilisateur trouvé pour UID: $uid');
    }
  } catch (e) {
    print('❌ fetchUserData: $e');
    rethrow;
  }
}
/// 🔍 Accès direct à un utilisateur spécifique via son UID
Future<UserModel?> getUserById(String uid) async {
  return await _userService.getUserById(uid);
}

/// ✅ Vérifie si un document utilisateur existe déjà dans Firestore
Future<bool> userExists(String uid) async {
  return await _userService.userExists(uid);
}

/// 🆕 Crée un nouvel utilisateur dans Firestore à partir de données de base
Future<void> createNewUser({
  required String uid,
  required String firstName,
  required String lastName,
  required String email,
  String? phone,
  String? profilePicture,
  required String role,
  String? provider,
  bool emailVerified = false,
  bool phoneVerified = true,
   String? language,
}) async {
  await _userService.createNewUser(
    uid: uid,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    profilePicture: profilePicture,
    role: role,
    provider: provider,
    emailVerified: emailVerified,
    phoneVerified: phoneVerified,
    language: language
  );
}
/// 🧱 Crée ou met à jour un utilisateur Firestore depuis le contrôleur
Future<void> createOrUpdateUser(UserModel user) async {
  await _userService.createOrUpdateUser(user);
  currentUser.value = user;
}
Future<void> initializeUserStructure(String uid) async {
  try {
    final settingsController = Get.find<UserSettingsController>();
    await settingsController.initializeUserSettings(uid);
    print("✅ Settings initialized");
  } catch (e) {
    print("⚠️ Failed to initialize settings: $e");
  }

  try {
    final vehicleController = Get.find<VehicleController>();
    await vehicleController.initializeEmptyVehicle(uid);
    print("✅ Vehicle initialized");
  } catch (e) {
    print("⚠️ Failed to initialize vehicle: $e");
  }

  try {
    final travelPatternController = Get.find<TravelPatternController>();
    await travelPatternController.createEmptyTravelPatternsDoc(uid);
    print("✅ Travel patterns initialized");
  } catch (e) {
    print("⚠️ Failed to initialize travel patterns: $e");
  }

  try {
    final driverPreferencesController = Get.find<DriverPreferencesController>();
    await driverPreferencesController.createEmptyDriverPreferencesDoc(uid);
    print("✅ Driver preferences initialized");
  } catch (e) {
    print("⚠️ Failed to initialize driver preferences: $e");
  }

  try {
    final senderPreferencesController = Get.find<SenderPreferencesController>();
    await senderPreferencesController.createEmptySenderPreferencesDoc(uid);
    print("✅ Sender preferences initialized");
  } catch (e) {
    print("⚠️ Failed to initialize sender preferences: $e");
  }

  try {
    final documentsController = Get.find<UserDocumentsController>();
    await documentsController.createEmptyUserDocument(uid);
    print("✅ Documents initialized");
  } catch (e) {
    print("⚠️ Failed to initialize documents: $e");
  }

  try {
    final devicesController = Get.find<UserDevicesController>();
    await devicesController.createEmptyDeviceDoc(uid);
    print("✅ Devices initialized");
  } catch (e) {
    print("⚠️ Failed to initialize devices: $e");
  }

  try {
    final badgesController = Get.find<UserBadgesController>();
    await badgesController.createEmptyBadgeDoc(uid);
    print("✅ Badges initialized");
  } catch (e) {
    print("⚠️ Failed to initialize badges: $e");
  }

  print("🎉 All user structure initializations attempted for UID: $uid");
}

}
/*
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/model/user_model.dart';
import 'package:viaamigo/shared/collections/users/model/driver_preference_model.dart';
import 'package:viaamigo/shared/collections/users/model/sender_preference_model.dart';
import 'package:viaamigo/shared/collections/users/subcollection/sender_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/settings.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/badges_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/devices_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/document_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/driver_preference_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/sender_preference_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/travel_patterns_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/settings_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/vehicule_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/vehicules.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/services/user_service.dart';

class UserController extends GetxController {
  // Services
  final UserService _userService = Get.find<UserService>();
  final AuthService _authService = Get.find<AuthService>();
  final String uid = Get.find<AuthService>().firebaseUser.value?.uid ?? '';

  // Variables observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<UserSettings?> userSettings = Rx<UserSettings?>(null);
  final Rx<DriverPreferences?> driverPreferences = Rx<DriverPreferences?>(null);
 
  final RxList<Vehicle> _userVehicles = <Vehicle>[].obs;
  
  // Contrôleurs
  final VehicleController vehicleController = Get.find<VehicleController>();
  final settingsController = Get.find<UserSettingsController>();
  final travelPatternController = Get.find<TravelPatternController>();
  final documentsController = Get.find<UserDocumentsController>();
  final devicesController = Get.find<UserDevicesController>();
  final badgesController = Get.find<UserBadgesController>();
  final driverPreferencesController = Get.find<DriverPreferencesController>();
  final senderPreferencesController = Get.find<SenderPreferencesController>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ Écouter automatiquement les changements d'authentification (connexion, déconnexion, validation email)
    ever(_authService.firebaseUser, _onAuthChanged);

    // Charger les données utilisateur si déjà connecté
    if (_authService.firebaseUser.value != null) {
      fetchUserData();
    }
  }

  // 🎯 Détecter les changements de statut utilisateur
  void _onAuthChanged(user) async {
    if (user == null) {
      // ❌ Déconnecté : réinitialiser toutes les données locales
      currentUser.value = null;
      userSettings.value = null;
      driverPreferences.value = null;
      senderPreferences.value = null;
      _userVehicles.clear();
    } else {
      // ✅ Connecté : charger les données depuis Firestore
      await fetchUserData();

      // 📬 Détecter si l'utilisateur vient de valider son email
      if (user.emailVerified && currentUser.value != null && !currentUser.value!.emailVerified) {
        try {
          await _userService.createOrUpdateUser(
            currentUser.value!.copyWith(emailVerified: true),
          );
          print('✅ Email verification detected and updated in Firestore');
        } catch (e) {
          print('❌ Failed to update email verification status: $e');
        }
      }
    }
  }

  // 🚀 Charger toutes les données utilisateur depuis Firestore
  Future<void> fetchUserData() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      currentUser.value = await _userService.getUserById(uid);

      // Charger les paramètres utilisateur
      await settingsController.loadUserSettings(uid);
      
      // Initialiser et charger les habitudes de déplacement
      travelPatternController.initialize(uid);
      
      // Charger les documents utilisateur
      await documentsController.loadUserDocuments();
      
      // Charger les appareils utilisateur
      await devicesController.loadUserDevices();
      
      // Charger les badges utilisateur
      await badgesController.loadUserBadges();

      // Charger les préférences selon le rôle
      if (currentUser.value?.role == 'driver' || currentUser.value?.role == 'both') {
        await driverPreferencesController.loadDriverPreferences();
        driverPreferences.value = driverPreferencesController.driverPreferences.value as DriverPreferences?;
      }

      if (currentUser.value?.role == 'sender' || currentUser.value?.role == 'both') {
        await senderPreferencesController.loadSenderPreferences(uid);
        senderPreferences.value = await _userService.getSenderPreferences(uid);
      }

      // Charger les véhicules utilisateur
      //_userVehicles.value = await vehicleController.getUserVehicles(uid);
    } catch (e) {
      error.value = e.toString();
      print('Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 📝 Mettre à jour les informations du profil utilisateur
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    if (currentUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final updatedUser = currentUser.value!.copyWith(
        firstName: firstName ?? currentUser.value!.firstName,
        lastName: lastName ?? currentUser.value!.lastName,
        phone: phone ?? currentUser.value!.phone,
      );

      await _userService.createOrUpdateUser(updatedUser);
      currentUser.value = updatedUser;

      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // 📍 Mettre à jour la localisation de l'utilisateur
  Future<void> updateUserLocation(double latitude, double longitude) async {
    if (currentUser.value == null) return;

    try {
      await _userService.updateLocation(currentUser.value!.uid, latitude, longitude);
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Initialise toutes les sous-collections pour un nouvel utilisateur
  Future<void> initializeUserStructure(String uid) async {
    isLoading.value = true;
    
    try {
      // 🚗 Initialiser les véhicules
      await vehicleController.initializeEmptyVehicle(uid);
      
      // ⚙️ Initialiser les paramètres utilisateur
      await settingsController.initializeUserSettings(uid);
      await settingsController.loadUserSettings(uid);
      
      // 🗺️ Initialiser les habitudes de déplacement
      await _initializeTravelPatterns(uid);
      
      // 📋 Initialiser les préférences conducteur si applicable
      if (currentUser.value?.role == 'driver' || currentUser.value?.role == 'both') {
        await _initializeDriverPreferences(uid);
      }
      
      // 📦 Initialiser les préférences expéditeur si applicable
      if (currentUser.value?.role == 'sender' || currentUser.value?.role == 'both') {
        await _initializeSenderPreferences(uid);
      }
      
      // 📱 Initialiser les appareils
      await _initializeDevices(uid);
      
      // 📄 Initialiser les documents
      await _initializeDocuments(uid);
      
      // 🏅 Initialiser les badges
      await _initializeBadges(uid);
      
      Get.snackbar('Success', 'User structure initialized successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize user structure: ${e.toString()}');
      print('Error initializing user structure: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Méthode privée pour initialiser les patterns de déplacement
  Future<void> _initializeTravelPatterns(String uid) async {
    try {
      // Initialiser le contrôleur avec l'ID utilisateur
      travelPatternController.initialize(uid);
      
      // Créer un document vide si nécessaire
      await travelPatternController.createEmptyTravelPatternsDoc(uid);
      
      print('✅ Document travel pattern initialisé pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du document travel pattern: $e');
      rethrow;
    }
  }
  
  /// Méthode privée pour initialiser les préférences conducteur
  Future<void> _initializeDriverPreferences(String uid) async {
    try {
      await driverPreferencesController.createEmptyDriverPreferencesDoc(uid);
      print('✅ Préférences conducteur initialisées pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des préférences conducteur: $e');
      rethrow;
    }
  }
  
  /// Méthode privée pour initialiser les préférences expéditeur
  Future<void> _initializeSenderPreferences(String uid) async {
    try {
      await senderPreferencesController.createEmptySenderPreferencesDoc(uid);
      print('✅ Préférences expéditeur initialisées pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des préférences expéditeur: $e');
      rethrow;
    }
  }
  
  /// Méthode privée pour initialiser les documents utilisateur
  Future<void> _initializeDocuments(String uid) async {
    try {
      await documentsController.createEmptyUserDocument(uid);
      print('✅ Documents utilisateur initialisés pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des documents utilisateur: $e');
      rethrow;
    }
  }
  
  /// Méthode privée pour initialiser les appareils utilisateur
  Future<void> _initializeDevices(String uid) async {
    try {
      await devicesController.createEmptyDeviceDoc(uid);
      print('✅ Appareils utilisateur initialisés pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des appareils utilisateur: $e');
      rethrow;
    }
  }
  
  /// Méthode privée pour initialiser les badges utilisateur
  Future<void> _initializeBadges(String uid) async {
    try {
      await badgesController.createEmptyBadgeDoc(uid);
      print('✅ Badges utilisateur initialisés pour l\'utilisateur: $uid');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des badges utilisateur: $e');
      rethrow;
    }
  }
}
*/