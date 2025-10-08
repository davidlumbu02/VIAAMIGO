import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/parcels_tab.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/trips_tab.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';


/// Page principale de recherche avec onglets séparés
/// 
/// Architecture modulaire :
/// - Onglet Colis : parcels_tab.dart
/// - Onglet Trajets : trips_tab.dart
/// - Contrôleur commun : search_controller.dartimport 'package:flutter/material.dart';


/// Page principale de recherche avec onglets séparés - SANS ERREURS DE DÉPRÉCIATION
/// 
/// Architecture modulaire :
/// - Onglet Colis : parcels_tab.dart
/// - Onglet Trajets : trips_tab.dart
/// - Contrôleur commun : search_controller.dart
/// 
/// ✅ CORRIGÉ : Remplacement de .withOpacity() par .withValues(alpha:)
class CocolisInspiredSearchPage extends StatefulWidget {
  const CocolisInspiredSearchPage({super.key});

  @override
  State<CocolisInspiredSearchPage> createState() => _CocolisInspiredSearchPageState();
}

class _CocolisInspiredSearchPageState extends State<CocolisInspiredSearchPage>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final controller = Get.put(SearchPageController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            // Tab bar personnalisé - CORRIGÉ
            _buildCustomTabBar(context, theme),
            
            // Contenu des onglets - FICHIERS SÉPARÉS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet Colis - Fichier séparé
                  const ParcelsTab(),
                  
                  // Onglet Trajets - Fichier séparé  
                  const TripsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab bar personnalisé - CORRIGÉ pour éviter les warnings de dépréciation
  Widget _buildCustomTabBar(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 02),
      decoration: BoxDecoration(
        // ✅ CORRIGÉ : withOpacity → withValues
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          // ✅ CORRIGÉ : withOpacity → withValues
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(
            // ✅ CORRIGÉ : withOpacity → withValues
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: theme.colorScheme.primary,
        // ✅ CORRIGÉ : withOpacity → withValues
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.packageSearch, size: 20),
                const SizedBox(width: 8),
                const Text('Packages'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.car, size: 20),
                const SizedBox(width: 8),
                const Text('Trips'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contrôleur partagé pour les deux onglets - CORRIGÉ
class SearchPageController extends GetxController {
  final RxBool isMapView = false.obs;
  
  // États partagés entre les onglets si nécessaire
  final RxString currentLocation = ''.obs;
  final RxBool isLoading = false.obs;
  
  // Méthodes communes
  void setMapView(bool value) {
    isMapView.value = value;
  }
  
  void setCurrentLocation(String location) {
    currentLocation.value = location;
  }
}