// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/driver_preference.dart';
import 'package:viaamigo/shared/services/auth_service.dart';

/// Contrôleur pour gérer les préférences du conducteur
class DriverPreferencesController extends GetxController {
  // Services injectés
  final DriverPreferencesService _preferencesService = DriverPreferencesService();
  final AuthService _authService = Get.find<AuthService>();

  // Variables observables
  final Rx<DriverPreferences?> driverPreferences = Rx<DriverPreferences?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'authentification
    ever(_authService.firebaseUser, _onUserChanged);

    // Si l'utilisateur est connecté, charger ses préférences
    if (_authService.firebaseUser.value != null) {
      loadDriverPreferences();
    }
  }

  // Méthode pour réagir aux changements d'utilisateur
  void _onUserChanged(user) async {
    if (user != null) {
      loadDriverPreferences();
    } else {
      // Réinitialiser les préférences quand l'utilisateur est déconnecté
      driverPreferences.value = null;
    }
  }

  // Méthode pour charger les préférences du conducteur
  Future<void> loadDriverPreferences() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Vérifier si les préférences existent déjà pour l'utilisateur
      final preferences = await _preferencesService.getDriverPreferences(userId);
      
      // Si les préférences existent, on les charge, sinon on crée des préférences par défaut
      if (preferences != null) {
        driverPreferences.value = preferences;
      } else {
        await _preferencesService.createEmptyDriverPreferencesDoc(userId);
        driverPreferences.value = await _preferencesService.getDriverPreferences(userId);
      }
    } catch (e) {
      error.value = 'Error loading driver preferences: $e';
      print('Error loading driver preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour mettre à jour les préférences du conducteur
  Future<void> updateDriverPreferences(DriverPreferences preferences) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _preferencesService.updateDriverPreferences(userId, preferences);
      driverPreferences.value = preferences; // Mettre à jour localement après la mise à jour
      print('Driver preferences updated successfully');
    } catch (e) {
      error.value = 'Error updating driver preferences: $e';
      print('Error updating driver preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour initialiser les préférences par défaut si l'utilisateur n'en a pas
  Future<void> initializeDefaultPreferences() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _preferencesService.createEmptyDriverPreferencesDoc(userId);
      driverPreferences.value = await _preferencesService.getDriverPreferences(userId);
    } catch (e) {
      error.value = 'Error initializing default driver preferences: $e';
      print('Error initializing default driver preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour vérifier si un conducteur a des préférences
  Future<bool> hasDriverPreferences() async {
    if (_authService.firebaseUser.value == null) return false;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final preferences = await _preferencesService.getDriverPreferences(userId);
      return preferences != null;
    } catch (e) {
      print('Error checking if driver preferences exist: $e');
      return false;
    }
  }
  
  // Méthode pour initialiser des préférences par défaut pour un utilisateur spécifique (utile pour l'inscription)
  Future<void> createEmptyDriverPreferencesDoc(String userId) async {
    isLoading.value = true;
    error.value = '';

    try {
      await _preferencesService.createEmptyDriverPreferencesDoc(userId);
      print('✅ Préférences conducteur initialisées pour l\'utilisateur: $userId');
    } catch (e) {
      error.value = 'Error initializing default driver preferences: $e';
      print('❌ Erreur lors de l\'initialisation des préférences conducteur: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/driver_preferences_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/driver_preference.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';

void exampleDriverPreferencesUsage() async {
  // ⚙️ Étape 1 : Initialiser le controller (ex. dans Bindings globaux)
  Get.put(DriverPreferencesController());

  final controller = Get.find<DriverPreferencesController>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Étape 2 : Charger les préférences du conducteur
  await controller.loadDriverPreferences();

  // ❓ Étape 3 : Vérifier si l'utilisateur a déjà des préférences
  final alreadyHasPrefs = await controller.hasDriverPreferences();
  if (!alreadyHasPrefs) {
    // 🧱 Si non : créer un document Firestore avec des préférences MVP réalistes
    await controller.createEmptyDriverPreferencesDoc(userId);
    print('📄 Document de préférences initialisé pour $userId');
  }

  // 🔁 Étape 4 : Écouter les préférences en temps réel (utile en UI reactive)
  controller.driverPreferences.listen((prefs) {
    if (prefs != null) {
      print('🔄 Préférences mises à jour en direct :');
      print('• Détour max : ${prefs.maxDetourKm} km');
      print('• Jours actifs : ${prefs.availableDays.join(', ')}');
      print('• Créneaux horaires :');
      for (final slot in prefs.availableTimeSlots) {
        print('  > ${slot.day}: ${slot.start} - ${slot.end}');
      }
    }
  });

  // ✏️ Étape 5 : Modifier partiellement une seule propriété (ex: prix minimum)
  final current = controller.driverPreferences.value;
  if (current != null) {
    final updated = current.copyWith(minimumPricePerKm: 0.45);
    await controller.updateDriverPreferences(updated);
    print('✅ Prix minimum mis à jour à 0.45 \$ / km');
  }

  // 🔁 Étape 6 : Modifier complètement toutes les préférences (ex: onboarding)
  final fullUpdate = DriverPreferences(
    maxDetourKm: 20,
    preferredParcelSizes: ['medium', 'large'],
    avoidHighways: true,
    preferredPaymentMethods: ['card', 'wallet'],
    autoAcceptMatches: true,
    minimumPricePerKm: 0.35,
    availableDays: ['monday', 'friday'],
    availableTimeSlots: [
      TimeSlot(day: 'monday', start: '10:00', end: '16:00'),
      TimeSlot(day: 'friday', start: '09:00', end: '14:00'),
    ],
    packageTypesAccepted: ['fragile'],
    acceptsUrgentDeliveries: false,
    advancePickupAllowed: false,
    automaticMatchingEnabled: true,
  );

  await controller.updateDriverPreferences(fullUpdate);
  print('🚗 Toutes les préférences conducteur ont été remplacées');

  // 🔍 Étape 7 : Accéder à une info précise localement (ex: types de colis acceptés)
  final prefs = controller.driverPreferences.value;
  if (prefs != null && prefs.packageTypesAccepted.contains('fragile')) {
    print('📦 Ce conducteur accepte les colis fragiles');
  }
}
// */