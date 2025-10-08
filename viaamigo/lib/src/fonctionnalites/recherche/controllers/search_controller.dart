import 'package:get/get.dart';

/// Contrôleur partagé pour la recherche (Colis + Trajets)
/// 
/// Gère les états communs entre les deux onglets :
/// - Mode d'affichage (Map/List pour Colis)
/// - Localisation actuelle
/// - États de chargement
/// - Données partagées
class SearchPageController extends GetxController {
  // ========== ÉTATS POUR L'ONGLET COLIS ==========
  
  /// Mode d'affichage pour l'onglet Colis (Map ou List)
  final RxBool isMapView = false.obs;
  
  /// Filtres actifs pour les colis
  final RxList<String> activeFilters = <String>[].obs;
  
  /// Résultats de recherche pour les colis
  final RxList<Map<String, dynamic>> parcelsResults = <Map<String, dynamic>>[].obs;
  
  /// État de chargement pour les colis
  final RxBool isParcelsLoading = false.obs;

  // ========== ÉTATS POUR L'ONGLET TRAJETS ==========
  
  /// Résultats de recherche pour les trajets
  final RxList<Map<String, dynamic>> tripsResults = <Map<String, dynamic>>[].obs;
  
  /// État de chargement pour les trajets
  final RxBool isTripsLoading = false.obs;
  
  /// Options de recherche intelligente
  final RxBool includeIntermediateStops = true.obs;
  final RxBool allowDetours = false.obs;
  final RxDouble maxDetourDistance = 50.0.obs;
  final RxInt maxDetourTime = 30.obs;

  // ========== ÉTATS PARTAGÉS ==========
  
  /// Localisation actuelle de l'utilisateur
  final RxString currentLocation = ''.obs;
  
  /// État de chargement global
  final RxBool isLoading = false.obs;
  
  /// Erreurs
  final RxString errorMessage = ''.obs;

  // ========== MÉTHODES POUR L'ONGLET COLIS ==========
  
  /// Basculer entre Map et List pour les colis
  void setMapView(bool value) {
    isMapView.value = value;
  }
  
  /// Ajouter/retirer un filtre pour les colis
  void toggleFilter(String filter) {
    if (activeFilters.contains(filter)) {
      activeFilters.remove(filter);
    } else {
      activeFilters.add(filter);
    }
    _searchParcels(); // Rechercher avec nouveaux filtres
  }
  
  /// Rechercher des colis
  Future<void> _searchParcels() async {
    isParcelsLoading.value = true;
    
    try {
      // Simulation - remplacez par votre API réelle
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Exemple de données
      parcelsResults.value = [
        {
          'id': 'parcel_1',
          'title': 'Table de ferme en chêne massif',
          'from': 'Le Pellerin (44640)',
          'to': 'Levallois-Perret (92300)',
          'date': 'Between 10 Sep and 19 Sep',
          'price': '123 €',
          'badges': ['XXL'],
        },
        // ... autres colis
      ];
      
    } catch (e) {
      errorMessage.value = 'Erreur lors de la recherche de colis';
    } finally {
      isParcelsLoading.value = false;
    }
  }

  // ========== MÉTHODES POUR L'ONGLET TRAJETS ==========
  
  /// Rechercher des trajets intelligents
  Future<void> searchIntelligentTrips(String from, String to) async {
    if (from.isEmpty || to.isEmpty) {
      errorMessage.value = 'Veuillez remplir les champs DE et VERS';
      return;
    }

    isTripsLoading.value = true;
    tripsResults.clear();
    
    try {
      List<Map<String, dynamic>> allTrips = [];
      
      // 1. Recherche trajets directs
      final directTrips = await _searchDirectTrips(from, to);
      allTrips.addAll(directTrips);
      
      // 2. Recherche trajets avec points de passage
      if (includeIntermediateStops.value) {
        final intermediateTrips = await _searchIntermediateTrips(from, to);
        allTrips.addAll(intermediateTrips);
      }
      
      // 3. Recherche trajets avec détours acceptés
      if (allowDetours.value) {
        final detourTrips = await _searchDetourTrips(from, to);
        allTrips.addAll(detourTrips);
      }

      // Trier par score de correspondance
      allTrips.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
      
      tripsResults.value = allTrips;
      
      // Notification de succès
      Get.snackbar(
        'Recherche terminée',
        '${allTrips.length} trajets trouvés',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
    } catch (e) {
      errorMessage.value = 'Erreur lors de la recherche de trajets';
      Get.snackbar(
        'Erreur de recherche',
        'Une erreur est survenue lors de la recherche',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isTripsLoading.value = false;
    }
  }
  
  /// Recherche trajets directs
  Future<List<Map<String, dynamic>>> _searchDirectTrips(String from, String to) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'id': 'direct_1',
        'tripType': 'direct',
        'route': '$from → $to',
        'departure': from,
        'destination': to,
        'matchScore': 100,
        'usedPortion': '100%',
        'actualPrice': 25.0,
        'driverName': 'Jean Dupont',
        'rating': 4.8,
        'completedTrips': 42,
        'departureTime': '14:30',
        'arrivalTime': '17:45',
        'seats': 3,
      }
    ];
  }

  /// Recherche trajets avec points de passage
  Future<List<Map<String, dynamic>>> _searchIntermediateTrips(String from, String to) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      {
        'id': 'intermediate_1',
        'tripType': 'intermediate',
        'route': 'Montréal → $from → $to',
        'departure': 'Montréal',
        'destination': to,
        'stops': ['Montréal', from, to],
        'matchScore': 85,
        'usedPortion': '74%',
        'actualPrice': 18.5,
        'originalPrice': 25.0,
        'fromStopIndex': 1,
        'toStopIndex': 2,
        'driverName': 'Marie Tremblay',
        'rating': 4.6,
        'completedTrips': 28,
        'departureTime': '13:00',
        'arrivalTime': '18:30',
        'seats': 2,
      }
    ];
  }

  /// Recherche trajets avec détours acceptés
  Future<List<Map<String, dynamic>>> _searchDetourTrips(String from, String to) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      {
        'id': 'detour_1',
        'tripType': 'detour',
        'route': 'Gatineau → $from → $to',
        'departure': 'Gatineau',
        'destination': to,
        'matchScore': 70,
        'actualPrice': 30.0,
        'originalPrice': 25.0,
        'detourInfo': {
          'distance': maxDetourDistance.value,
          'time': maxDetourTime.value,
          'extraCost': 5.0,
        },
        'driverName': 'Pierre Leblanc',
        'rating': 4.9,
        'completedTrips': 15,
        'departureTime': '15:00',
        'arrivalTime': '19:15',
        'seats': 1,
      }
    ];
  }
  
  /// Réserver un trajet
  Future<void> bookTrip(Map<String, dynamic> trip) async {
    isLoading.value = true;
    
    try {
      // Simulation de réservation - remplacez par votre API
      await Future.delayed(const Duration(milliseconds: 1000));
      
      Get.snackbar(
        'Réservation confirmée',
        'Votre trajet a été réservé avec succès !',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erreur de réservation',
        'Impossible de réserver ce trajet',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ========== MÉTHODES PARTAGÉES ==========
  
  /// Définir la localisation actuelle
  void setCurrentLocation(String location) {
    currentLocation.value = location;
  }
  
  /// Obtenir la position GPS de l'utilisateur
  Future<void> getCurrentPosition() async {
    isLoading.value = true;
    
    try {
      // Simulation - remplacez par votre service de géolocalisation
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Exemple de position
      currentLocation.value = 'Hawkesbury, ON';
      
    } catch (e) {
      errorMessage.value = 'Impossible d\'obtenir votre position';
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Effacer les erreurs
  void clearError() {
    errorMessage.value = '';
  }
  
  /// Réinitialiser tous les états
  void reset() {
    // Colis
    isMapView.value = false;
    activeFilters.clear();
    parcelsResults.clear();
    isParcelsLoading.value = false;
    
    // Trajets
    tripsResults.clear();
    isTripsLoading.value = false;
    includeIntermediateStops.value = true;
    allowDetours.value = false;
    maxDetourDistance.value = 50.0;
    maxDetourTime.value = 30;
    
    // Global
    currentLocation.value = '';
    isLoading.value = false;
    errorMessage.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    // Initialisation - obtenir la position de l'utilisateur
    getCurrentPosition();
  }

}