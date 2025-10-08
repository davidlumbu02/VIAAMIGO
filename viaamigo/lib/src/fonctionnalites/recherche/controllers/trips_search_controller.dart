import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/controllers/search_controller.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/service/firebase_search_service.dart';


class TripsSearchController extends GetxController {
  final FirebaseService _service = FirebaseService();
  final SearchPageController _pageController = Get.find<SearchPageController>();

  // États réactifs pour l'UI de TripsTab
  final RxList<TripModel> results = <TripModel>[].obs;
  final RxString fromLocation = ''.obs;
  final RxString toLocation = ''.obs;
  final RxBool includeIntermediateStops = true.obs;
  final RxBool allowDetours = false.obs;
  final RxDouble maxDetourDistance = 50.0.obs;
  final RxInt maxDetourTime = 30.obs;

  /// Recherche intelligente de trajets (appel au service)
  Future<void> searchIntelligentTrips({GeoPoint? centerForDetours}) async {
    if (fromLocation.value.isEmpty || toLocation.value.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir les champs DE et VERS');
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
        Get.snackbar('Aucun résultat', 'Aucun trajet trouvé pour ces critères');
      } else {
        Get.snackbar('Succès', '${results.length} trajets trouvés');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de la recherche des trajets: $e');
    } finally {
      _pageController.isLoading.value = false;
    }
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