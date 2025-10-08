import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/controllers/search_controller.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/service/firebase_search_service.dart';
  // Ton controller partagé existant

class ParcelsSearchController extends GetxController {
  FirebaseService get _service => FirebaseService();
  final SearchPageController _pageController = Get.find<SearchPageController>();

  // États réactifs pour l'UI de ParcelsTab
  final RxList<ParcelModel> results = <ParcelModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxMap<String, bool> quickFilters = {
    'view_all': true,
    'my_routes': false,
    'urgent': false,
    'near_me': false,
    'instant_booking': false,
  }.obs;
  final RxInt listingsCount = 0.obs;

  /// Recherche de colis (appel au service)
  Future<void> searchParcels({String? query, GeoPoint? nearLocation, double radiusKm = 50.0}) async {
    _pageController.isLoading.value = true;
    try {
      results.value = await _service.searchParcels(
        query: query ?? searchQuery.value,
        nearLocation: nearLocation,
        radiusKm: radiusKm,
        filters: quickFilters,
      );
      listingsCount.value = results.length;
      if (results.isEmpty) {
        Get.snackbar('Aucun résultat', 'Aucun colis trouvé pour ces critères');
      } else {
        Get.snackbar('Succès', '${results.length} colis trouvés');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de la recherche des colis: $e');
    } finally {
      _pageController.isLoading.value = false;
    }
  }

  /// Toggle filtre rapide
  void toggleFilter(String filterKey) {
    quickFilters[filterKey] = !quickFilters[filterKey]!;
    quickFilters.refresh();  // Pour notifier l'UI
    searchParcels();  // Relancer la recherche avec les nouveaux filtres
  }

  /// Afficher bottom sheet pour filtres avancés
  void showFilters() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtres pour Colis', style: Get.theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            // Ajoute des switches pour filtres avancés (ex. : poids, catégorie)
            SwitchListTile(
              title: const Text('Urgent'),
              value: quickFilters['urgent']!,
              onChanged: (value) => toggleFilter('urgent'),
            ),
            SwitchListTile(
              title: const Text('Près de moi'),
              value: quickFilters['near_me']!,
              onChanged: (value) => toggleFilter('near_me'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                searchParcels();
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}