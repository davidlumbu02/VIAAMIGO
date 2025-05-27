// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/sender_preference.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';

/// Contrôleur pour gérer les préférences de l'expéditeur
/// Contrôleur GetX pour gérer l'état des SenderPreferences
class SenderPreferencesController extends GetxController {
  final SenderPreferencesService _preferencesService = SenderPreferencesService();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<SenderPreferences> senderPreferences = const SenderPreferences().obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_authService.firebaseUser, _onUserChanged);

    if (_authService.firebaseUser.value != null) {
      loadSenderPreferences();
    }
  }

  void _onUserChanged(user) async {
    if (user != null) {
      loadSenderPreferences();
    } else {
      senderPreferences.value = const SenderPreferences();
    }
  }

  Future<void> loadSenderPreferences() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final prefs = await _preferencesService.getSenderPreferences(userId);
      senderPreferences.value = prefs;
    } catch (e) {
      error.value = 'Erreur lors du chargement des préférences expéditeur : $e';
      print('Erreur lors du chargement des préférences expéditeur : $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSenderPreferences() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _preferencesService.updateSenderPreferences(
        userId, 
        senderPreferences.value
      );
      print('Préférences expéditeur mises à jour avec succès');
    } catch (e) {
      error.value = 'Erreur lors de la mise à jour des préférences expéditeur : $e';
      print('Erreur lors de la mise à jour des préférences expéditeur : $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateLocally(SenderPreferences updatedPreferences) {
    senderPreferences.value = updatedPreferences;
  }

  Future<void> createEmptySenderPreferencesDoc(String userId) async {
    isLoading.value = true;
    error.value = '';

    try {
      await _preferencesService.createEmptySenderPreferencesDoc(userId);
      
      if (_authService.firebaseUser.value?.uid == userId) {
        await loadSenderPreferences();
      }
      
      print('✅ Préférences expéditeur initialisées pour l\'utilisateur: $userId');
    } catch (e) {
      error.value = 'Erreur lors de l\'initialisation des préférences expéditeur : $e';
      print('❌ Erreur lors de l\'initialisation des préférences expéditeur : $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  List<TimeSlot> getSortedTimeSlots() {
    final dayOrder = {
      'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3, 
      'friday': 4, 'saturday': 5, 'sunday': 6
    };
    
    final slots = List<TimeSlot>.from(senderPreferences.value.preferredPickupTimes);
    slots.sort((a, b) {
      final dayCompare = (dayOrder[a.day] ?? 0).compareTo(dayOrder[b.day] ?? 0);
      if (dayCompare != 0) return dayCompare;
      return a.start.compareTo(b.start);
    });
    
    return slots;
  }
  
  Future<void> addTimeSlot(String day, String start, String end) async {
    if (_authService.firebaseUser.value == null) return;
    
    final newSlot = TimeSlot(
      day: day,
      start: start,
      end: end,
    );
    
    final currentSlots = List<TimeSlot>.from(senderPreferences.value.preferredPickupTimes);
    currentSlots.add(newSlot);
    
    updateLocally(senderPreferences.value.copyWith(
      preferredPickupTimes: currentSlots
    ));
    
    await updateSenderPreferences();
  }
  
  Future<void> removeTimeSlot(TimeSlot slotToRemove) async {
    if (_authService.firebaseUser.value == null) return;
    
    final currentSlots = List<TimeSlot>.from(senderPreferences.value.preferredPickupTimes);
    currentSlots.removeWhere((slot) => 
      slot.day == slotToRemove.day && 
      slot.start == slotToRemove.start && 
      slot.end == slotToRemove.end
    );
    
    updateLocally(senderPreferences.value.copyWith(
      preferredPickupTimes: currentSlots
    ));
    
    await updateSenderPreferences();
  }
  
  Future<void> updatePreference<T>(String field, T value) async {
    SenderPreferences updatedPreferences;
    
    switch (field) {
      case 'preferredDriverRating':
        updatedPreferences = senderPreferences.value.copyWith(
          preferredDriverRating: value as double
        );
        break;
      case 'insuranceDefault':
        updatedPreferences = senderPreferences.value.copyWith(
          insuranceDefault: value as bool
        );
        break;
      case 'notifyOnNearbyDrivers':
        updatedPreferences = senderPreferences.value.copyWith(
          notifyOnNearbyDrivers: value as bool
        );
        break;
      case 'preferredDeliverySpeed':
        updatedPreferences = senderPreferences.value.copyWith(
          preferredDeliverySpeed: value as String
        );
        break;
      case 'maxPricePerKm':
        updatedPreferences = senderPreferences.value.copyWith(
          maxPricePerKm: value as double
        );
        break;
      case 'defaultInsuranceLevel':
        updatedPreferences = senderPreferences.value.copyWith(
          defaultInsuranceLevel: value as String
        );
        break;
      case 'preferredConfirmationMethod':
        updatedPreferences = senderPreferences.value.copyWith(
          preferredConfirmationMethod: value as String
        );
        break;
      case 'flexibleTimingAllowed':
        updatedPreferences = senderPreferences.value.copyWith(
          flexibleTimingAllowed: value as bool
        );
        break;
      default:
        throw ArgumentError('Champ inconnu: $field');
    }
    
    updateLocally(updatedPreferences);
    await updateSenderPreferences();
  }
  /*🟡 Suggestions optionnelles (pas des erreurs) :
Méthode hasSenderPreferences()

Tu pourrais ajouter une méthode Future<bool> dans le contrôleur pour vérifier si le document sender_preferences existe déjà.

C’est utile si tu veux afficher des étapes conditionnelles dans un wizard ou un onboarding.*/
  Future<bool> hasSenderPreferences() async {
  final uid = _authService.firebaseUser.value?.uid;
  if (uid == null) return false;
  final doc = await _preferencesService.firestore
      .collection('users')
      .doc(uid)
      .collection('sender_preferences')
      .doc(uid)
      .get();
  return doc.exists;
}

}
/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/sender_preferences_controller.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';
import 'package:viaamigo/shared/collections/users/subcollection/sender_preference.dart';

void exampleSenderPreferencesUsage() async {
  // ⚙️ Étape 1 : Initialisation du controller
  Get.put(SenderPreferencesController());
  final controller = Get.find<SenderPreferencesController>();

  // 🔐 Récupération de l'utilisateur connecté
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Étape 2 : Charger les préférences existantes ou les créer si manquantes
  final hasPrefs = await controller.hasSenderPreferences();
  if (!hasPrefs) {
    await controller.createEmptySenderPreferencesDoc(userId);
    print('📦 Document des préférences expéditeur initialisé.');
  }

  // 🔄 Étape 3 : Écoute temps réel des préférences (utile en UI dynamique)
  controller.senderPreferences.listen((prefs) {
    print('🔄 Mise à jour live :');
    print('• Note conducteur min : ${prefs.preferredDriverRating}');
    print('• Assurance par défaut : ${prefs.insuranceDefault}');
    print('• Confirmation : ${prefs.preferredConfirmationMethod}');
    print('• Créneaux : ${prefs.preferredPickupTimes.length} définis');
  });

  // ✏️ Étape 4 : Mise à jour complète des préférences
  final fullUpdate = SenderPreferences(
    preferredDriverRating: 4.8,
    insuranceDefault: true,
    notifyOnNearbyDrivers: true,
    preferredPickupTimes: [
      TimeSlot(day: 'monday', start: '09:00', end: '11:00'),
      TimeSlot(day: 'wednesday', start: '14:00', end: '16:00'),
    ],
    preferredDeliverySpeed: 'express',
    maxPricePerKm: 0.6,
    defaultInsuranceLevel: 'premium',
    preferredConfirmationMethod: 'qr',
    flexibleTimingAllowed: false,
  );
  controller.updateLocally(fullUpdate);
  await controller.updateSenderPreferences();
  print('✅ Préférences expéditeur entièrement mises à jour');

  // 🧠 Étape 5 : Mise à jour ciblée d’un champ
  await controller.updatePreference<double>('preferredDriverRating', 4.9);
  await controller.updatePreference<String>('preferredDeliverySpeed', 'economy');
  await controller.updatePreference<bool>('insuranceDefault', false);
  print('🎯 Mise à jour ciblée réussie');

  // 🗓️ Étape 6 : Ajouter un créneau horaire
  await controller.addTimeSlot('friday', '10:00', '12:00');
  print('📅 Créneau ajouté pour vendredi');

  // 🗑️ Étape 7 : Supprimer un créneau horaire
  final toRemove = TimeSlot(day: 'monday', start: '09:00', end: '11:00');
  await controller.removeTimeSlot(toRemove);
  print('🗑️ Créneau supprimé : $toRemove');

  // 🔍 Étape 8 : Lecture locale des créneaux triés
  final sortedSlots = controller.getSortedTimeSlots();
  for (var slot in sortedSlots) {
    print('🔢 ${slot.day}: ${slot.start} - ${slot.end}');
  }

  // 🧾 Étape 9 : Lecture d’un champ local sans accès réseau
  final prefs = controller.senderPreferences.value;
  print('📌 Confirmation préférée : ${prefs.preferredConfirmationMethod}');
  print('💰 Prix max par km : ${prefs.maxPricePerKm}');
  print('📦 Assurance : ${prefs.defaultInsuranceLevel}');
}
*/