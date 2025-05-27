// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/settings.dart'; // Importation du modèle et service

/// Contrôleur pour gérer l'état et les opérations liées aux paramètres utilisateur
/// Utilise GetX pour la gestion d'état réactive
class UserSettingsController extends GetxController {
  // Services injectés
  final UserSettingsService _settingsService = Get.find<UserSettingsService>();
  
  // Variables observables
  final Rx<UserSettings> settings = Rx<UserSettings>(UserSettings(
    themeMode: 'system',
    language: 'fr',
    notificationsEnabled: true,
    preferredRole: 'expediteur',
    searchRadiusKm: 10,
  ));
  
  // États de chargement et d'erreur
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  // Identifiant de l'utilisateur courant (à définir lors du chargement)
  final RxString currentUserId = ''.obs;
  
  // Observables spécifiques pour certains paramètres fréquemment utilisés
  String get themeMode => settings.value.themeMode;
  String get language => settings.value.language;
  String get preferredRole => settings.value.preferredRole;
  bool get notificationsEnabled => settings.value.notificationsEnabled;
  
  /// Charge les paramètres utilisateur depuis Firestore
  Future<void> loadUserSettings(String userId) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    currentUserId.value = userId;
    isLoading.value = true;
    error.value = '';
    
    try {
      // Vérifier si les paramètres existent
      final exists = await _settingsService.settingsExist(userId);
      
      if (exists) {
        // Charger les paramètres existants
        settings.value = await _settingsService.getUserSettings(userId);
      } else {
        // Créer des paramètres par défaut si nécessaire
        await _settingsService.createEmptySettingsDoc(userId);
        settings.value = _settingsService.getDefaultSettings();
      }
    } catch (e) {
      error.value = e.toString();
      print('Error loading user settings: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Configure un Stream pour écouter les changements de paramètres en temps réel
  void setupSettingsListener(String userId) {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    currentUserId.value = userId;
    
    // Démarrer l'écoute des changements
    _settingsService.getUserSettingsStream(userId)
      .listen(
        (updatedSettings) {
          settings.value = updatedSettings;
        },
        onError: (e) {
          error.value = e.toString();
          print('Error in settings stream: $e');
        }
      );
  }
  
  /// Met à jour un paramètre spécifique
  Future<void> updateSetting(String userId, String key, dynamic value) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      // Créer un nouvel objet avec la valeur mise à jour
      final updatedSettings = _createUpdatedSettings(key, value);
      
      // Mettre à jour dans Firestore
      await _settingsService.updateUserSettings(userId, updatedSettings);
      
      // Mettre à jour localement
      settings.value = updatedSettings;
    } catch (e) {
      error.value = e.toString();
      print('Error updating setting $key: $e');
      // Afficher un message d'erreur
      Get.snackbar(
        'Error', 
        'Unable to update settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Crée un nouvel objet de paramètres avec une valeur mise à jour
  UserSettings _createUpdatedSettings(String key, dynamic value) {
    switch (key) {
      case 'themeMode':
        return settings.value.copyWith(themeMode: value as String);
      case 'language':
        return settings.value.copyWith(language: value as String);
      case 'notificationsEnabled':
        return settings.value.copyWith(notificationsEnabled: value as bool);
      case 'preferredRole':
        return settings.value.copyWith(preferredRole: value as String);
      case 'searchRadiusKm':
        return settings.value.copyWith(searchRadiusKm: value as int);
      case 'experimentalFeatures':
        return settings.value.copyWith(experimentalFeatures: value as Map<String, bool>);
      case 'privacySettings':
        return settings.value.copyWith(privacySettings: value as Map<String, dynamic>);
      case 'notificationPreferences':
        return settings.value.copyWith(notificationPreferences: value as Map<String, dynamic>);
      default:
        throw ArgumentError('Invalid setting key: $key');
    }
  }
  
  /// Met à jour plusieurs paramètres à la fois
  Future<void> updateMultipleSettings(String userId, Map<String, dynamic> updates) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      // Créer un nouvel objet avec toutes les valeurs mises à jour
      var updatedSettings = settings.value;
      
      // Appliquer chaque mise à jour
      updates.forEach((key, value) {
        updatedSettings = _createUpdatedSettings(key, value);
      });
      
      // Mettre à jour dans Firestore
      await _settingsService.updateUserSettings(userId, updatedSettings);
      
      // Mettre à jour localement
      settings.value = updatedSettings;
    } catch (e) {
      error.value = e.toString();
      print('Error updating multiple settings: $e');
      Get.snackbar(
        'Error', 
        'Unable to update settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Active ou désactive une fonctionnalité expérimentale
  Future<void> toggleExperimentalFeature(String userId, String featureName, bool enabled) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    // Créer une copie des fonctionnalités expérimentales actuelles
    final features = Map<String, bool>.from(settings.value.experimentalFeatures);
    
    // Mettre à jour la fonctionnalité spécifique
    features[featureName] = enabled;
    
    // Mettre à jour tous les paramètres
    await updateSetting(userId, 'experimentalFeatures', features);
  }
  
  /// Change le thème de l'application
  Future<void> changeTheme(String userId, String newThemeMode) async {
    await updateSetting(userId, 'themeMode', newThemeMode);
    
    // Mettre à jour le thème de l'application
    switch (newThemeMode) {
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'system':
      default:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }
  
  /// Change la langue de l'application
  Future<void> changeLanguage(String userId, String newLanguage) async {
    await updateSetting(userId, 'language', newLanguage);
    
    // Mettre à jour la langue de l'application
    final currentLocale = Get.locale;
    final targetLocale = Locale(newLanguage);
    
    if (currentLocale?.languageCode != targetLocale.languageCode) {
      Get.updateLocale(targetLocale);
    }
  }
  
  /// Met à jour un paramètre de confidentialité
  Future<void> updatePrivacySetting(String userId, String privacyKey, dynamic value) async {
    final privacySettings = Map<String, dynamic>.from(settings.value.privacySettings);
    privacySettings[privacyKey] = value;
    await updateSetting(userId, 'privacySettings', privacySettings);
  }
  
  /// Met à jour une préférence de notification
  Future<void> updateNotificationPreference(String userId, String prefKey, dynamic value) async {
    final notifPreferences = Map<String, dynamic>.from(settings.value.notificationPreferences);
    notifPreferences[prefKey] = value;
    await updateSetting(userId, 'notificationPreferences', notifPreferences);
  }
  
  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<void> resetToDefaults(String userId) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      // Obtenir les paramètres par défaut
      final defaultSettings = _settingsService.getDefaultSettings();
      
      // Mettre à jour dans Firestore
      await _settingsService.updateUserSettings(userId, defaultSettings);
      
      // Mettre à jour localement
      settings.value = defaultSettings;
      
      Get.snackbar(
        'Success', 
        'Settings have been reset to defaults',
        snackPosition: SnackPosition.BOTTOM
      );
    } catch (e) {
      error.value = e.toString();
      print('Error resetting settings: $e');
      Get.snackbar(
        'Error', 
        'Unable to reset settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Initialise les paramètres par défaut pour un nouvel utilisateur
  Future<void> initializeUserSettings(String userId) async {
    if (userId.isEmpty) {
      error.value = 'User ID cannot be empty';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      await _settingsService.createEmptySettingsDoc(userId);
      settings.value = _settingsService.getDefaultSettings();
    } catch (e) {
      error.value = e.toString();
      print('Error initializing user settings: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Vérifie si une fonctionnalité expérimentale est activée
  bool isFeatureEnabled(String featureName) {
    return settings.value.experimentalFeatures[featureName] ?? false;
  }
  
  /// Obtient un paramètre de confidentialité spécifique
  dynamic getPrivacySetting(String key, {dynamic defaultValue}) {
    return settings.value.privacySettings[key] ?? defaultValue;
  }
  
  /// Obtient une préférence de notification spécifique
  dynamic getNotificationPreference(String key, {dynamic defaultValue}) {
    return settings.value.notificationPreferences[key] ?? defaultValue;
  }
}

/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/collections/users/subcollection/settings.dart'; // Model & Service
import 'package:viaamigo/shared/controllers/user_settings_controller.dart';     // Controller

void exampleSettingsUsage() async {
  // ⚙️ Initialisation (à faire une fois dans le Binding principal)
  Get.put<UserSettingsService>(UserSettingsService()); // d’abord le service
  Get.put<UserSettingsController>(UserSettingsController()); // puis le controller

  final settingsController = Get.find<UserSettingsController>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Charger les paramètres utilisateur
  await settingsController.loadUserSettings(userId);

  // 📡 Activer l'écoute des paramètres en temps réel
  settingsController.setupSettingsListener(userId);

  // 🔁 Modifier un seul paramètre : exemple - changer la langue
  await settingsController.updateSetting(userId, 'language', 'en');

  // 🌗 Changer le thème
  await settingsController.changeTheme(userId, 'dark');

  // 🗺️ Changer le rôle préféré
  await settingsController.updateSetting(userId, 'preferredRole', 'driver');

  // 🔕 Activer/désactiver les notifications
  await settingsController.updateSetting(userId, 'notificationsEnabled', false);

  // 🧪 Activer une fonctionnalité expérimentale
  await settingsController.toggleExperimentalFeature(userId, 'featureB', true);

  // 🛡️ Modifier un paramètre de confidentialité
  await settingsController.updatePrivacySetting(userId, 'showOnlineStatus', false);

  // 🔔 Modifier une préférence de notification
  await settingsController.updateNotificationPreference(userId, 'messages', false);

  // ✏️ Mettre à jour plusieurs paramètres à la fois
  await settingsController.updateMultipleSettings(userId, {
    'themeMode': 'light',
    'language': 'fr',
    'searchRadiusKm': 25,
  });

  // 🔄 Réinitialiser tous les paramètres à leurs valeurs par défaut
  await settingsController.resetToDefaults(userId);

  // 📄 Créer un document de paramètres si inexistant (ex: à l’inscription)
  await settingsController.initializeUserSettings(userId);

  // 🔍 Vérifier si une fonctionnalité expérimentale est active
  final bool isEnabled = settingsController.isFeatureEnabled('featureA');

  // 🔍 Lire un paramètre de confidentialité
  final showOnline = settingsController.getPrivacySetting('showOnlineStatus', defaultValue: true);

  // 🔍 Lire une préférence de notification
  final notifMessages = settingsController.getNotificationPreference('messages', defaultValue: true);
}
*/