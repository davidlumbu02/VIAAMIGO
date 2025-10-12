import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';

import 'package:viaamigo/src/fonctionnalites/recherche/controllers/search_controller.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/service/firebase_search_service.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';


class TripsSearchController extends GetxController {
  final FirebaseService _service = FirebaseService();
  final SearchPageController _pageController = Get.find<SearchPageController>();
  // 🔥 GETTER PROPRE pour éviter _pageController dans l'UI
  bool get isLoading => _pageController.isLoading.value;

  // États réactifs pour l'UI de TripsTab
  final RxList<TripModel> results = <TripModel>[].obs;
  final RxString fromLocation = ''.obs;
  final RxString toLocation = ''.obs;
  final RxBool includeIntermediateStops = true.obs;
  final RxBool allowDetours = false.obs;
  final RxDouble maxDetourDistance = 50.0.obs;
  final RxInt maxDetourTime = 30.obs;

/*
/// Version simplifiée - reconstruction manuelle du TripModel
Future<void> searchIntelligentTrips({GeoPoint? centerForDetours}) async {
  if (fromLocation.value.isEmpty || toLocation.value.isEmpty) {
    UIMessageManager.validationError("Please fill in the FROM and TO fields.");
    return;
  }
  
  _pageController.isLoading.value = true;
  
  try {
    final searchResults = await _service.searchTrips(
      fromLocation: fromLocation.value,
      toLocation: toLocation.value,
    );
    
    // ✅ CONVERSION SIMPLE : utiliser directement les IDs pour récupérer les TripModel
    List<TripModel> tripModels = [];
    
    for (var tripData in searchResults) {
      try {
        // Récupérer le TripModel complet depuis Firestore
        final tripModel = await _service.getTripById(tripData['id']);
        if (tripModel != null) {
          // Ajouter le type de match
          tripModel.validationErrors.clear();
          tripModel.validationErrors.add(tripData['match_type'] ?? 'unknown');
          tripModels.add(tripModel);
        }
      } catch (e) {
        print('Erreur récupération trajet ${tripData['id']}: $e');
      }
    }
    
    results.value = tripModels;
    
    if (results.isEmpty) {
      Get.snackbar('Aucun résultat', 'Aucun trajet trouvé pour ces critères');
    } else {
      Get.snackbar('Succès', '${results.length} trajets trouvés');
    }
    
  } catch (e) {
    Get.snackbar('Erreur', 'Échec de la recherche des trajets: $e');
  } finally {
    _pageController.isLoading.value = false;
  }
}*/
  /// Recherche intelligente de trajets (appel au service)
  Future<void> searchIntelligentTrips({GeoPoint? centerForDetours}) async {
    if (fromLocation.value.isEmpty || toLocation.value.isEmpty) {
      UIMessageManager.validationError("Please fill all mandatory fields.");
      return;
    }
    _pageController.isLoading.value = true;
    try {
      results.value = await _service.searchTrips(
        fromLocation: fromLocation.value,
        toLocation: toLocation.value,
        includeIntermediateStops: includeIntermediateStops.value,
        allowDetours: allowDetours.value,
        maxDetourDistance: maxDetourDistance.value,
        maxDetourTime: maxDetourTime.value,
        centerForDetours: centerForDetours,  // Passe une GeoPoint pour détours (ex. : position utilisateur)
      );
      if (results.isEmpty) {
        Get.snackbar('no results', 'No trips found for these criteria');
      } else {
        Get.snackbar('success', '${results.length} trips found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search for trips: $e');
    } finally {
      _pageController.isLoading.value = false;
    }
  }
    /// 🔥 NOUVELLE MÉTHODE : Initialisation depuis l'UI
  void initializeFromUI({
    required String fromLocation,
    required String toLocation,
    String? fromLat,
    String? fromLng,
    String? toLat,
    String? toLng,
  }) {
    this.fromLocation.value = fromLocation;
    this.toLocation.value = toLocation;
    
    // Stocker les coordonnées pour les détours
    if (fromLat != null && fromLng != null) {
      // Vous pouvez ajouter des RxString pour les coordonnées si nécessaire
    }
  }

  /// 🔥 NOUVELLE MÉTHODE : Reset pour une nouvelle recherche
  void resetSearch() {
    results.clear();
    fromLocation.value = '';
    toLocation.value = '';
    includeIntermediateStops.value = true;
    allowDetours.value = false;
    maxDetourDistance.value = 50.0;
    maxDetourTime.value = 30;
  }

  /// Réserver un trajet (appel au service si besoin)
  void bookTrip(TripModel trip, {String? parcelId}) {
    Get.dialog(
      AlertDialog(
        title: const Text('Réservation'),
        content: Text('Réserver ${trip.originAddress} → ${trip.destinationAddress} ?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.bookTrip(trip.tripId ?? '', 'userId', parcelId: parcelId);  // Remplace 'userId' par l'ID réel
                Get.back();
                Get.snackbar('Succès', 'Trajet réservé !');
              } catch (e) {
                Get.snackbar('Erreur', 'Échec de la réservation: $e');
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // Setters pour états réactifs
  void setFromLocation(String value) {
    fromLocation.value = value;
  }

  void setToLocation(String value) {
    toLocation.value = value;
  }

  void setMaxDetourDistance(double value) {
    maxDetourDistance.value = value;
  }

  void setMaxDetourTime(int value) {
    maxDetourTime.value = value;
  }

  void toggleIntermediateStops(bool value) {
    includeIntermediateStops.value = value;
  }

  void toggleAllowDetours(bool value) {
    allowDetours.value = value;
  }
}

