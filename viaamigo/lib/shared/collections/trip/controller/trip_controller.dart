// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/trip/service/trip_service.dart';

class TripController extends GetxController {
  final TripService _tripService = TripService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variables observables principales
  Rx<TripModel?> currentTrip = Rx<TripModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;
  RxString errorMessage = ''.obs;
  RxInt currentStep = 0.obs;
  RxBool autoSave = true.obs;
  
  // État du formulaire - Validation des champs
  final RxBool originValid = false.obs;
  final RxBool destinationValid = false.obs;
  final RxBool departureTimeValid = false.obs;
  final RxBool vehicleTypeValid = false.obs;
  final RxBool vehicleCapacityValid = false.obs;
  final RxBool acceptedParcelTypesValid = false.obs;
  final RxBool handlingCapabilitiesValid = false.obs;
  
  // Mode local vs Firestore
  final RxBool isLocalMode = true.obs;
  final RxString localDraftId = ''.obs;
  Timer? _localSaveTimer;
  static const String LOCAL_DRAFT_KEY = 'viaamigo_local_trip_draft';
  
  // Navigation et modals
  final _justNavigatedToPublisher = false.obs;
  final _modalAlreadyShown = false.obs;
  
  // Liste des erreurs de validation
  RxList<String> validationErrorsList = <String>[].obs;
  
  // Listes observables pour l'interface
  RxList<String> acceptedParcelTypesList = <String>[].obs;
  RxList<Map<String, dynamic>> waypointsList = <Map<String, dynamic>>[].obs;
  
  // Getters utiles
  bool get isReadyToPublish => currentTrip.value?.isReadyToPublish() ?? false;
  bool get isDraft => currentTrip.value?.status == 'available';
  String get displayStatus => currentTrip.value?.displayStatus ?? 'Inconnu';
  
  // Navigation vers le publisher
  void onNavigateToPublisher() {
    print("TripController: onNavigateToPublisher called");
    _justNavigatedToPublisher.value = true;
    _modalAlreadyShown.value = false;
  }
  /// 🆕 Helper pour updateVehicleInfo - utilisé par PublishTripPage
  Future<void> updateVehicleInfo(String key, dynamic value) async {
    if (currentTrip.value == null) return;
    
    final updatedInfo = Map<String, dynamic>.from(currentTrip.value!.vehicleInfo);
    updatedInfo[key] = value;
    
    currentTrip.value = currentTrip.value!.copyWith(vehicleInfo: updatedInfo);
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Initialise un nouveau trip ou récupère un brouillon existant
  Future<void> initTrip({String? existingTripId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      
      if (existingTripId != null) {
        // Charger un trip existant depuis Firestore
        print('🔄 Chargement trip existant: $existingTripId');
        isLocalMode.value = false;
        currentTrip.value = await _tripService.getTripById(existingTripId);
        autoSave.value = true;
        
        // Synchroniser les observables
        _syncObservables();
      } else {
        // Logique de brouillon local
        await _initializeLocalDraft(user);
      }
      
      currentStep.value = currentTrip.value?.navigation_step ?? 0;
      validateFields();
      
    } catch (e) {
      errorMessage.value = 'Erreur: ${e.toString()}';
      print('❌ Erreur initTrip: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Initialise un brouillon local ou le charge depuis le stockage
  Future<void> _initializeLocalDraft(User user) async {
    final existingDraft = await _loadLocalDraft();
    
    if (existingDraft != null && _isRecentDraft(existingDraft)) {
      print('📂 Reprise brouillon local');
      isLocalMode.value = true;
      currentTrip.value = existingDraft;
      currentStep.value = existingDraft.navigation_step;
      localDraftId.value = existingDraft.tripId ?? _generateLocalId();
      autoSave.value = false;
      _startLocalAutoSave();
    } else {
      print('🆕 Création nouveau brouillon local');
      await _createNewLocalDraft(user);
    }
  }
  
  /// Crée un nouveau brouillon local
  Future<void> _createNewLocalDraft(User user) async {
    isLocalMode.value = true;
    localDraftId.value = _generateLocalId();
    autoSave.value = false;
    
    final emptyTrip = TripModel.empty(user.uid);
    
    currentTrip.value = emptyTrip;
    currentStep.value = 0;
    
    validateFields();
    _startLocalAutoSave();
    
    await _saveLocalDraft();
  }
  
  /// Valide l'état des champs
/// Valide l'état des champs
void validateFields() {
  print("🧪 validateFields() appelé");

  if (currentTrip.value == null) {
    print("⚠️ Aucun trip à valider (currentTrip=null)");
    return;
  }

  print("➡️ Validation des champs principaux...");
  originValid.value = currentTrip.value!.originAddress.isNotEmpty;
  print("   - originValid: ${originValid.value}");

  destinationValid.value = currentTrip.value!.destinationAddress.isNotEmpty;
  print("   - destinationValid: ${destinationValid.value}");

  departureTimeValid.value = currentTrip.value!.departureTime.isAfter(DateTime.now());
  print("   - departureTimeValid: ${departureTimeValid.value}");

  // Tu peux réactiver les autres validations si besoin
  // vehicleTypeValid.value = currentTrip.value!.vehicleType.isNotEmpty;
  // vehicleCapacityValid.value = currentTrip.value!.vehicleCapacity.isNotEmpty;
  // acceptedParcelTypesValid.value = currentTrip.value!.acceptedParcelTypes.isNotEmpty;
  // handlingCapabilitiesValid.value = currentTrip.value!.handlingCapabilities.isNotEmpty;

  // Synchroniser les observables
  _syncObservables();

  // Valider le modèle complet
  bool isModelValid = currentTrip.value!.validate();
  validationErrorsList.value = List<String>.from(currentTrip.value!.validationErrors);

  print("➡️ Résultat validate() du modèle: $isModelValid");
  if (validationErrorsList.isNotEmpty) {
    print("❌ Erreurs de validation trouvées:");
    for (var err in validationErrorsList) {
      print("   - $err");
    }
  } else {
    print("✅ Aucun problème de validation");
  }
}

  
  /// Synchronise les observables avec le modèle
  void _syncObservables() {
    if (currentTrip.value == null) return;
    
    acceptedParcelTypesList.value = List<String>.from(currentTrip.value!.acceptedParcelTypes);
    waypointsList.value = currentTrip.value!.waypoints != null 
        ? List<Map<String, dynamic>>.from(currentTrip.value!.waypoints!)
        : <Map<String, dynamic>>[];
  }
  
  /// Sauvegarde le trip
  Future<void> saveTrip() async {
    if (currentTrip.value == null) return;
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
      return;
    }
    
    isSaving.value = true;
    
    try {
      currentTrip.value!.updatedAt = DateTime.now();
      currentTrip.value!.navigation_step = currentStep.value;
      
      await _tripService.updateTrip(currentTrip.value!);
      validateFields();
    } catch (e) {
      errorMessage.value = 'Erreur lors de la sauvegarde: ${e.toString()}';
    } finally {
      isSaving.value = false;
    }
  }
  
/// Publie le trip
Future<bool> publishTrip() async {
  print("🚀 Début publishTrip");   // <== Début

  if (currentTrip.value == null) {
    print("❌ Aucun currentTrip trouvé, abort publication");
    return false;
  }
  
  // Transition vers Firestore si en mode local
  if (isLocalMode.value) {
    print('📦 Mode local détecté → transition vers Firestore...');
    await _transitionToFirestore();
    
    try {
      await _clearLocalDraft();
      await _forceCompleteReset();
      print('✅ Publication terminée via transition Firestore');
      return true;
    } catch (resetError) {
      print('⚠️ Erreur lors du reset après transition: $resetError');
      return true;
    }
  }
  
  // Vérification des validations
  print("🧪 Validation des champs du trip...");
  if (!currentTrip.value!.validate()) {
    validationErrorsList.value = List<String>.from(currentTrip.value!.validationErrors);
    errorMessage.value = 'Erreurs de validation:\n${validationErrorsList.join('\n')}';
    print("❌ Erreurs de validation: ${validationErrorsList.join(', ')}");
    return false;
  }
  
  isSaving.value = true;
  print("💾 Sauvegarde vers Firestore en cours...");

  try {
    await _tripService.publishTrip(currentTrip.value!);
    print("✅ publishTrip dans TripService réussi");

    currentTrip.value!.status = 'available';
    
    try {
      await _clearLocalDraft();
      await _forceCompleteReset();
      print('🧹 Reset exécuté après publication réussie');
    } catch (resetError) {
      print('⚠️ Erreur lors du reset (mais publication réussie): $resetError');
    }
    return true;
  } catch (e) {
    errorMessage.value = 'Erreur lors de la publication: ${e.toString()}';
    print("❌ Exception publishTrip: $e");
    return false;
  } finally {
    isSaving.value = false;
    print("🏁 Fin publishTrip (isSaving=false)");
  }
}
  /// Met à jour un champ spécifique
  Future<void> updateField(String fieldName, dynamic value) async {
    if (currentTrip.value == null) return;
    
    switch (fieldName) {
      case 'originAddress':
        currentTrip.value = currentTrip.value!.copyWith(originAddress: value);
        originValid.value = value.toString().isNotEmpty;
        break;
      case 'destinationAddress':
        currentTrip.value = currentTrip.value!.copyWith(destinationAddress: value);
        destinationValid.value = value.toString().isNotEmpty;
        break;
      case 'departureTime':
        currentTrip.value = currentTrip.value!.copyWith(departureTime: value);
        departureTimeValid.value = (value as DateTime).isAfter(DateTime.now());
        break;
      /*case 'arrivalTime':
        currentTrip.value = currentTrip.value!.copyWith(arrivalTime: value);
        break;*/
        case 'arrivalTime':
        if (value != null && currentTrip.value!.departureTime != null) {
          if ((value as DateTime).isBefore(currentTrip.value!.departureTime)) {
            errorMessage.value = 'Arrival time must be after departure time';
            return;
          }
        }
        currentTrip.value = currentTrip.value!.copyWith(arrivalTime: value);
        break;
      case 'vehicleType':
        currentTrip.value = currentTrip.value!.copyWith(vehicleType: value);
        vehicleTypeValid.value = value.toString().isNotEmpty;
        break;
      case 'vehicleCapacity':
        currentTrip.value = currentTrip.value!.copyWith(vehicleCapacity: value);
        vehicleCapacityValid.value = (value as Map<String, dynamic>).isNotEmpty;
        break;
      case 'vehicleInfo':
        currentTrip.value = currentTrip.value!.copyWith(vehicleInfo: value);
        break;
      case 'acceptedParcelTypes':
        currentTrip.value = currentTrip.value!.copyWith(acceptedParcelTypes: value);
        acceptedParcelTypesValid.value = (value as List<String>).isNotEmpty;
        break;
      case 'handlingCapabilities':
        currentTrip.value = currentTrip.value!.copyWith(handlingCapabilities: value);
        handlingCapabilitiesValid.value = (value as Map<String, dynamic>).isNotEmpty;
        break;
      case 'isRecurring':
        currentTrip.value = currentTrip.value!.copyWith(isRecurring: value);
        break;
      case 'schedule':
        currentTrip.value = currentTrip.value!.copyWith(schedule: value);
        break;
      case 'notificationSettings':
        currentTrip.value = currentTrip.value!.copyWith(notificationSettings: value);
        break;
      case 'status':
        currentTrip.value = currentTrip.value!.copyWith(status: value);
        break;
      case 'g':
        currentTrip.value = currentTrip.value!.copyWith(g: value);
        break;
        case 'waypoints':
        currentTrip.value = currentTrip.value!.copyWith(waypoints: value);
        break;
      case 'navigation_step':
        currentTrip.value = currentTrip.value!.copyWith(navigation_step: value);
        currentStep.value = value;
        break;
    }
    
    _syncObservables();
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else {
      if (autoSave.value) {
        await saveTrip();
      }
    }
  }
  
  /// Définit l'adresse d'origine avec coordonnées
  Future<void> setOriginAddress(String address, double lat, double lng) async {
    if (currentTrip.value == null) return;
    
    final point = GeoFirePoint(GeoPoint(lat, lng));
    
    currentTrip.value = currentTrip.value!.copyWith(
      originAddress: address,
      origin: point
    );
    
    originValid.value = address.isNotEmpty;
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Définit l'adresse de destination avec coordonnées
  Future<void> setDestinationAddress(String address, double lat, double lng) async {
    if (currentTrip.value == null) return;
    
    final point = GeoFirePoint(GeoPoint(lat, lng));
    
    currentTrip.value = currentTrip.value!.copyWith(
      destinationAddress: address,
      destination: point
    );
    
    destinationValid.value = address.isNotEmpty;
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Met à jour les capacités du véhicule
  Future<void> updateVehicleCapacity(double maxWeight, double maxVolume, int maxParcels) async {
    if (currentTrip.value == null) return;
    
    /*final newCapacity = {
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'maxParcels': maxParcels,
    };*/
    
    currentTrip.value!.updateVehicleCapacity(maxWeight, maxVolume, maxParcels);
    vehicleCapacityValid.value = true;
    
    _syncObservables();
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Ajoute un point d'arrêt
  Future<void> addWaypoint(String address, double lat, double lng, {int stopDuration = 15}) async {
    if (currentTrip.value == null) return;
    
    currentTrip.value!.addWaypoint(address, lat, lng, stopDuration: stopDuration);
    _syncObservables();
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Supprime un point d'arrêt
  Future<void> removeWaypoint(int index) async {
    if (currentTrip.value == null) return;
    
    currentTrip.value!.removeWaypoint(index);
    _syncObservables();
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Ajoute un type de colis accepté
  Future<void> addAcceptedParcelType(String parcelType) async {
    if (currentTrip.value == null) return;
    
    if (!currentTrip.value!.acceptedParcelTypes.contains(parcelType)) {
      final updatedTypes = List<String>.from(currentTrip.value!.acceptedParcelTypes);
      updatedTypes.add(parcelType);
      
      currentTrip.value = currentTrip.value!.copyWith(acceptedParcelTypes: updatedTypes);
      acceptedParcelTypesValid.value = updatedTypes.isNotEmpty;
      
      _syncObservables();
      
      if (isLocalMode.value) {
        await _saveLocalDraft();
      } else if (autoSave.value) {
        await saveTrip();
      }
    }
  }
  
  /// Supprime un type de colis accepté
  Future<void> removeAcceptedParcelType(String parcelType) async {
    if (currentTrip.value == null) return;
    
    final updatedTypes = List<String>.from(currentTrip.value!.acceptedParcelTypes);
    updatedTypes.remove(parcelType);
    
    currentTrip.value = currentTrip.value!.copyWith(acceptedParcelTypes: updatedTypes);
    acceptedParcelTypesValid.value = updatedTypes.isNotEmpty;
    
    _syncObservables();
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Met à jour une capacité de manipulation
  Future<void> updateHandlingCapability(String capability, bool enabled) async {
    if (currentTrip.value == null) return;
    
    final updatedCapabilities = Map<String, dynamic>.from(currentTrip.value!.handlingCapabilities);
    updatedCapabilities[capability] = enabled;
    
    currentTrip.value = currentTrip.value!.copyWith(handlingCapabilities: updatedCapabilities);
    handlingCapabilitiesValid.value = updatedCapabilities.isNotEmpty;
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Vérifie si le trip peut accepter un colis
  bool canTripAcceptParcel(ParcelModel parcel) {
    if (currentTrip.value == null) return false;
    return currentTrip.value!.canAcceptParcel(parcel);
  }
  
  /// Navigation - Étape suivante
  Future<void> nextStep() async {
    currentStep.value++;
    
    if (currentTrip.value != null) {
      currentTrip.value = currentTrip.value!.copyWith(navigation_step: currentStep.value);
      
      if (isLocalMode.value) {
        await _saveLocalDraft();
      } else if (autoSave.value) {
        await saveTrip();
      }
    }
  }
  
  /// Navigation - Étape précédente
  Future<void> previousStep() async {
    if (currentStep.value > 0) {
      currentStep.value--;
      
      if (currentTrip.value != null) {
        currentTrip.value = currentTrip.value!.copyWith(navigation_step: currentStep.value);
        
        if (isLocalMode.value) {
          await _saveLocalDraft();
        } else if (autoSave.value) {
          await saveTrip();
        }
      }
    }
  }
  
  /// Va à une étape spécifique
  Future<void> goToStep(int stepIndex) async {
    if (stepIndex < 0) return;
    
    currentStep.value = stepIndex;
    
    if (currentTrip.value != null) {
      currentTrip.value = currentTrip.value!.copyWith(navigation_step: stepIndex);
      
      if (isLocalMode.value) {
        await _saveLocalDraft();
      } else if (autoSave.value) {
        await saveTrip();
      }
    }
  }
  
  /// Obtient les trips récents de l'utilisateur
  Future<List<TripModel>> getRecentTrips() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    return await _tripService.getUserRecentTrips(user.uid);
  }
  
  /// Stream des trips disponibles de l'utilisateur
  Stream<List<TripModel>> getAvailableTrips() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _tripService.getUserAvailableTrips(user.uid);
  }
  
  /// Trouve des trips compatibles avec un colis
  Future<List<TripModel>> findCompatibleTripsForParcel(ParcelModel parcel) async {
    return await _tripService.findCompatibleTrips(parcel);
  }
  
  /// Annule un trip
  Future<bool> cancelTrip(String reason) async {
    if (currentTrip.value?.tripId == null) return false;
    
    try {
      await _tripService.cancelTrip(currentTrip.value!.tripId!, reason);
      currentTrip.value = currentTrip.value!.copyWith(status: 'cancelled');
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de l\'annulation: ${e.toString()}';
      return false;
    }
  }
  
  // ----- GESTION DU MODE LOCAL -----
  
  /// Transition vers Firestore
 Future<void> _transitionToFirestore() async {
  if (!isLocalMode.value || currentTrip.value == null) {
    print("⚠️ _transitionToFirestore appelé mais pas en local ou currentTrip null");
    return;
  }
  
  try {
    print('🔄 Début transition vers Firestore...');
    
    // Créer et publier en une fois
    print('📥 Appel createEmptyTrip...');
    final tripId = await _tripService.createEmptyTrip(currentTrip.value!);
    print('✅ Trip créé avec ID: $tripId');

    currentTrip.value = currentTrip.value!.copyWith(
      tripId: tripId,
      status: 'available'
    );
    
    print('📤 Appel updateTrip pour finaliser...');
    await _tripService.updateTrip(currentTrip.value!);
    print('✅ updateTrip terminé');

    // Finaliser la transition
    isLocalMode.value = false;
    autoSave.value = true;
    _stopLocalAutoSave();
    
    print('🎉 Transition complète - Trip créé ET publié');
  } catch (e) {
    print('❌ Erreur _transitionToFirestore: $e');
    rethrow;
  }
}

  
  /// Génère un ID local
  String _generateLocalId() {
    return 'local_trip_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid.substring(0, 8) ?? 'anon'}';
  }
  
  /// Vérifie si le brouillon est récent
  bool _isRecentDraft(TripModel draft) {
    final lastEdited = draft.updatedAt ?? draft.createdAt ?? DateTime.now();
    return DateTime.now().difference(lastEdited).inHours < 48;
  }
  
  /// Démarre l'auto-save local
  void _startLocalAutoSave() {
    _localSaveTimer?.cancel();
    _localSaveTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isLocalMode.value && !isSaving.value) {
        _saveLocalDraft();
      }
    });
  }
  
  /// Arrête l'auto-save local
  void _stopLocalAutoSave() {
    _localSaveTimer?.cancel();
  }
  
  /// Sauvegarde en local
  Future<void> _saveLocalDraft() async {
    if (currentTrip.value == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = _tripToLocalJson(currentTrip.value!);
      draftData['currentStep'] = currentStep.value;
      draftData['localDraftId'] = localDraftId.value;
      
      await prefs.setString(LOCAL_DRAFT_KEY, jsonEncode(draftData));
      print('💾 Brouillon trip sauvé localement');
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
    }
  }
  
  /// Charge le brouillon local
  Future<TripModel?> _loadLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(LOCAL_DRAFT_KEY);
      
      if (draftJson != null) {
        final draftData = jsonDecode(draftJson);
        currentStep.value = draftData['currentStep'] ?? 0;
        localDraftId.value = draftData['localDraftId'] ?? _generateLocalId();
        
        return _tripFromLocalJson(draftData);
      }
    } catch (e) {
      print('❌ Erreur chargement brouillon: $e');
    }
    
    return null;
  }
  
  /// Nettoie le brouillon local
  Future<void> _clearLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LOCAL_DRAFT_KEY);
      localDraftId.value = '';
      print('💾 Brouillon trip nettoyé localement');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
  
  /// Reset complet
  Future<void> _forceCompleteReset() async {
    print('🧹 FORCE COMPLETE RESET TRIP - DÉBUT');
    
    _stopLocalAutoSave();
    
    currentTrip.value = null;
    currentStep.value = 0;
    isLocalMode.value = true;
    localDraftId.value = '';
    _justNavigatedToPublisher.value = false;
    _modalAlreadyShown.value = false;
    
    // Reset observables de validation
    originValid.value = false;
    destinationValid.value = false;
    departureTimeValid.value = false;
    vehicleTypeValid.value = false;
    vehicleCapacityValid.value = false;
    acceptedParcelTypesValid.value = false;
    handlingCapabilitiesValid.value = false;
    
    acceptedParcelTypesList.clear();
    waypointsList.clear();
    validationErrorsList.clear();
    errorMessage.value = '';
    
    isLoading.value = false;
    isSaving.value = false;
    autoSave.value = true;
    
    await _clearLocalDraft();
    update();
    
    print('🧹 FORCE COMPLETE RESET TRIP - TERMINÉ');
  }
  
  /// Convertit le trip en JSON pour le stockage local
  Map<String, dynamic> _tripToLocalJson(TripModel trip) {
    final json = trip.toFirestore();
    
    // Conversion récursive des Timestamps
    Map<String, dynamic> convertTimestamps(Map<String, dynamic> data) {
      final converted = <String, dynamic>{};
      
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is Timestamp) {
          converted[key] = value.toDate().toIso8601String();
        } else if (value is Map<String, dynamic>) {
          converted[key] = convertTimestamps(value);
        } else if (value is List) {
          converted[key] = value.map((item) {
            if (item is Map<String, dynamic>) {
              return convertTimestamps(item);
            } else if (item is Timestamp) {
              return item.toDate().toIso8601String();
            }
            return item;
          }).toList();
        } else {
          converted[key] = value;
        }
      }
      return converted;
    }
    
    final cleanedJson = convertTimestamps(json);
    
    // Gérer les coordonnées GPS
    if (trip.origin != null) {
      cleanedJson['origin_lat'] = trip.origin!.latitude;
      cleanedJson['origin_lng'] = trip.origin!.longitude;
      cleanedJson.remove('origin');
    }
    if (trip.destination != null) {
      cleanedJson['destination_lat'] = trip.destination!.latitude;
      cleanedJson['destination_lng'] = trip.destination!.longitude;
      cleanedJson.remove('destination');
    }
    
    return cleanedJson;
  }
  
  /// Convertit le JSON local en TripModel
  TripModel _tripFromLocalJson(Map<String, dynamic> json) {
    // Fonction récursive pour restaurer les Timestamps
    Map<String, dynamic> restoreTimestamps(Map<String, dynamic> data) {
      final restored = <String, dynamic>{};
      
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String && _isTimestampField(key)) {
          try {
            restored[key] = Timestamp.fromDate(DateTime.parse(value));
          } catch (e) {
            print("⚠️ Erreur conversion Timestamp pour $key: $e");
            restored[key] = value;
          }
        } else if (value is Map<String, dynamic>) {
          restored[key] = restoreTimestamps(value);
        } else if (value is List) {
          restored[key] = value.map((item) {
            if (item is Map<String, dynamic>) {
              return restoreTimestamps(item);
            }
            return item;
          }).toList();
        } else {
          restored[key] = value;
        }
      }
      return restored;
    }
    
    final restoredJson = restoreTimestamps(json);
    
    // Reconstruire les GeoFirePoint
    if (restoredJson['origin_lat'] != null && restoredJson['origin_lng'] != null) {
      restoredJson['origin'] = GeoPoint(restoredJson['origin_lat'], restoredJson['origin_lng']);
      restoredJson.remove('origin_lat');
      restoredJson.remove('origin_lng');
    }
    if (restoredJson['destination_lat'] != null && restoredJson['destination_lng'] != null) {
      restoredJson['destination'] = GeoPoint(restoredJson['destination_lat'], restoredJson['destination_lng']);
      restoredJson.remove('destination_lat');
      restoredJson.remove('destination_lng');
    }
    
    final mockDoc = _MockDocumentSnapshot(restoredJson, restoredJson['tripId'] ?? '');
    return TripModel.fromFirestore(mockDoc as DocumentSnapshot<Object?>);
  }
  
  /// Identifie les champs Timestamp
  bool _isTimestampField(String fieldName) {
    const timestampFields = [
      'createdAt', 'updatedAt', 'departureTime', 'arrivalTime'
    ];
    
    return timestampFields.contains(fieldName) || 
           fieldName.contains('time') || 
           fieldName.contains('Time') ||
           fieldName.contains('_at');
  }
  
  // ----- GESTION DES MODALS DE BROUILLON -----
  
  /// Vérifie s'il faut afficher le modal de choix de brouillon
  Future<bool> shouldShowDraftModal() async {
    print("TripController: shouldShowDraftModal called");
    
    if (_modalAlreadyShown.value) {
      print("  - Modal already shown, returning false");
      return false;
    }
    
    if (_justNavigatedToPublisher.value && currentTrip.value != null) {
      bool hasContent = _hasSignificantContent(currentTrip.value!);
      print("  - Has significant content: $hasContent");
      return hasContent;
    }
    
    final localDraft = await _loadLocalDraft();
    if (localDraft != null && _isRecentDraft(localDraft)) {
      bool hasContent = _hasSignificantContent(localDraft);
      print("  - Local draft has significant content: $hasContent");
      return hasContent;
    }
    
    return false;
  }
  
  /// Modal montré
  void onDraftModalShown() {
    print("TripController: onDraftModalShown called");
    _modalAlreadyShown.value = true;
    _justNavigatedToPublisher.value = false;
  }
  
  /// Continue le brouillon existant
  Future<void> continueDraft() async {
    print("TripController: continueDraft called");
    _modalAlreadyShown.value = true;
    _justNavigatedToPublisher.value = false;
    
    if (currentTrip.value == null) {
      final localDraft = await _loadLocalDraft();
      if (localDraft != null) {
        currentTrip.value = localDraft;
        currentStep.value = localDraft.navigation_step;
        isLocalMode.value = true;
        _startLocalAutoSave();
        validateFields();
        _syncObservables();
      } else {
        await initTrip();
      }
    }
  }
  
  /// Commence un nouveau trip
  Future<void> startNewTrip() async {
    print("TripController: startNewTrip called");
    _modalAlreadyShown.value = true;
    _justNavigatedToPublisher.value = false;
    
    if (currentTrip.value != null && _hasSignificantContent(currentTrip.value!)) {
      await _saveLocalDraft();
    }
    
    await clearLocalDraft();
    await initTrip();
  }
  
  /// Utilisateur annule le choix de brouillon
  void onUserCancelledDraftChoice() {
    print("TripController: onUserCancelledDraftChoice called");
    
    _justNavigatedToPublisher.value = false;
    _modalAlreadyShown.value = false;
    
    if (isLocalMode.value && currentTrip.value != null && _hasSignificantContent(currentTrip.value!)) {
      _saveLocalDraft();
      print("💾 Trip draft saved before returning");
    }
    
    _stopLocalAutoSave();
  }
  
  /// Quitte le publisher
  void onLeavePublisher() {
    print("TripController: onLeavePublisher called");
    _justNavigatedToPublisher.value = false;
    _modalAlreadyShown.value = false;
    
    if (isLocalMode.value && currentTrip.value != null && _hasSignificantContent(currentTrip.value!)) {
      _saveLocalDraft();
    }
  }
  
  /// Vérifie si le trip a du contenu significatif
  bool _hasSignificantContent(TripModel trip) {
    return trip.originAddress.isNotEmpty || 
           trip.destinationAddress.isNotEmpty ||
           trip.vehicleType.isNotEmpty ||
           trip.acceptedParcelTypes.isNotEmpty ||
           (trip.waypoints != null && trip.waypoints!.isNotEmpty);
  }
  
  /// Nettoie le brouillon local (version publique)
  Future<void> clearLocalDraft() async {
    await _clearLocalDraft();
    isLocalMode.value = true;
    currentTrip.value = null;
    currentStep.value = 0;
    localDraftId.value = '';
    _stopLocalAutoSave();
  }
  
  /// Vérifie s'il existe un brouillon local
  Future<bool> hasLocalDraft() async {
    final draft = await _loadLocalDraft();
    return draft != null && _isRecentDraft(draft);
  }
  
  /// Données d'affichage pour l'interface
  Map<String, dynamic> getDisplayData() {
    if (currentTrip.value == null) {
      return {};
    }
    
    return currentTrip.value!.toDisplayCard();
  }
  
  /// Récupère les informations du véhicule actuel
  Map<String, dynamic> getCurrentVehicleInfo() {
    if (currentTrip.value == null) {
      return {};
    }
    
    return {
      'vehicleType': currentTrip.value!.vehicleType,
      'vehicleInfo': currentTrip.value!.vehicleInfo,
      'vehicleCapacity': currentTrip.value!.vehicleCapacity,
    };
  }
  
  /// Récupère les types de colis acceptés actuels
  List<String> getCurrentAcceptedParcelTypes() {
    return currentTrip.value?.acceptedParcelTypes ?? [];
  }
  
  /// Récupère les capacités de manipulation actuelles
  Map<String, dynamic> getCurrentHandlingCapabilities() {
    return currentTrip.value?.handlingCapabilities ?? {};
  }
  
  /// Récupère les points d'arrêt actuels
  List<Map<String, dynamic>> getCurrentWaypoints() {
    return currentTrip.value?.waypoints ?? [];
  }
  
  /// Récupère les paramètres de notification actuels
  Map<String, dynamic> getCurrentNotificationSettings() {
    return currentTrip.value?.notificationSettings ?? {};
  }
  
  /// Met à jour les paramètres de notification
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    if (currentTrip.value == null) return;
    
    currentTrip.value = currentTrip.value!.copyWith(notificationSettings: settings);
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  /// Active/désactive la récurrence
  Future<void> toggleRecurring(bool isRecurring, {Map<String, dynamic>? schedule}) async {
    if (currentTrip.value == null) return;
    
    currentTrip.value = currentTrip.value!.copyWith(
      isRecurring: isRecurring,
      schedule: isRecurring ? schedule : null,
    );
    
    if (isLocalMode.value) {
      await _saveLocalDraft();
    } else if (autoSave.value) {
      await saveTrip();
    }
  }
  
  @override
  void onClose() {
    _stopLocalAutoSave();
    super.onClose();
  }
}

// Classe helper pour le mock DocumentSnapshot
class _MockDocumentSnapshot {
  final Map<String, dynamic> _data;
  final String id;
  
  _MockDocumentSnapshot(this._data, this.id);
  
  Map<String, dynamic> data() => _data;
}