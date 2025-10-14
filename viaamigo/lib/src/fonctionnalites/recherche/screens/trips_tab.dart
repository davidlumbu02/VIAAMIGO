import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/search_tripresults_page.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/controllers/trips_search_controller.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';

/// ✅ TRIPS TAB - FORMULAIRE DE RECHERCHE UNIQUEMENT
/// Les résultats s'affichent dans SearchResultsPage
class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  final TripsSearchController _searchController = Get.put(TripsSearchController());
  
  // Contrôleurs UI
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Variables observables pour UI
  final RxString _fromAddress = ''.obs;
  final RxString _fromLatitude = ''.obs;
  final RxString _fromLongitude = ''.obs;
  final RxString _toAddress = ''.obs;
  final RxString _toLatitude = ''.obs;
  final RxString _toLongitude = ''.obs;

  @override
  void initState() {
    super.initState();
    
    _fromController.addListener(() {
      _fromAddress.value = _fromController.text;
      _searchController.setFromLocation(_fromController.text);
    });
    
    _toController.addListener(() {
      _toAddress.value = _toController.text;
      _searchController.setToLocation(_toController.text);
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🎯 UNIQUEMENT LE FORMULAIRE DE RECHERCHE
          _buildIntelligentSearchInterface(theme),
          
          // 🔥 PAS DE RÉSULTATS ICI - Navigation directe vers SearchResultsPage
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Interface de recherche - SEULE SECTION DE L'ONGLET
  Widget _buildIntelligentSearchInterface(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart search',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Find routes with waypoints or detours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Champs From/To
          _buildAddressSection(),
          const SizedBox(height: 1),
          
          Center(
            child: IconButton(
              onPressed: _swapAddresses,
              icon: Icon(LucideIcons.arrowUpDown, color: theme.colorScheme.primary, size: 24),
            ),
          ),
          
          const SizedBox(height: 1),
          _buildToAddressSection(theme),
          const SizedBox(height: 10),

          // Date selector
          _buildDateTimeSelector(
            context: context,
            label: '',
            icon: LucideIcons.calendar,
            dateController: _dateController,
            timeController: _timeController,
            onDateTap: () => _selectDate(context),
          ),

          const SizedBox(height: 25),

          // Options avancées
          Text(
            'More options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 15),

          Obx(() => _buildCleanOption(
            title: 'Include intermediate stops',
            subtitle: 'Search routes with waypoints',
            value: _searchController.includeIntermediateStops.value,
            onChanged: _searchController.toggleIntermediateStops,
            icon: Icons.alt_route,
            theme: theme,
          )),

          const SizedBox(height: 12),

          Obx(() => _buildCleanOption(
            title: 'Allow detours',
            subtitle: 'Search routes allowing detours',
            value: _searchController.allowDetours.value,
            onChanged: _searchController.toggleAllowDetours,
            icon: Icons.explore,
            theme: theme,
          )),

          // Options de détour (conditionnelles)
          Obx(() {
            if (!_searchController.allowDetours.value) return const SizedBox();
            
            return Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max detour distance (km)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Text(
                    'Distance max: ${_searchController.maxDetourDistance.value.toInt()} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  )),
                  Obx(() => Slider(
                    value: _searchController.maxDetourDistance.value,
                    min: 10,
                    max: 100,
                    divisions: 18,
                    onChanged: _searchController.setMaxDetourDistance,
                    activeColor: theme.colorScheme.primary,
                  )),
                ],
              ),
            );
          }),

          const SizedBox(height: 25),

          // 🔥 BOUTON DE RECHERCHE - NAVIGATION DIRECTE VERS SEARCHRESULTSPAGE
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Obx(() => ElevatedButton(
              onPressed: _searchController.isLoading
                  ? null 
                  : _performSearchAndNavigate, // 🎯 Navigation directe
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _searchController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Search trips',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            )),
          ),
        ],
      ),
    );
  }

  /// 🔥 RECHERCHE ET NAVIGATION DIRECTE VERS SEARCHRESULTSPAGE
  /// 🔥 RECHERCHE ET NAVIGATION BASÉE SUR LE VRAI TRIPMODEL
Future<void> _performSearchAndNavigate() async {

    // Validation des champs obligatoires
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      UIMessageManager.error("Veuillez remplir tous les champs obligatoires.");
      return;
    }

    // Construire le GeoPoint pour détours si disponible
    GeoPoint? centerForDetours;
    try {
      if (_fromLatitude.value.isNotEmpty && _fromLongitude.value.isNotEmpty) {
        centerForDetours = GeoPoint(
          double.parse(_fromLatitude.value),
          double.parse(_fromLongitude.value),
        );
      }
    } catch (e) {
      print('⚠️ Erreur parsing coordonnées: $e');
      centerForDetours = null;
    }
  // 🎯 RECHERCHE VIA LE CONTRÔLEUR
  await _searchController.searchIntelligentTrips(
    centerForDetours: centerForDetours,
  );

 try {
      // 🔥 NAVIGATION AVEC LES VRAIS TRIPMODEL (correction du type)
      final List<TripModel> tripResults = _searchController.results; // ✅ Correction
      
      if (tripResults.isEmpty) {
        Get.to(() => SearchResultsPage(
          trips: [], // ✅ Liste vide de TripModel
          from: _fromController.text,
          to: _toController.text,
          date: _dateController.text,
          time: _timeController.text,
        ));
        return;
      }

      // 🚀 NAVIGATION AVEC LES VRAIS TRIPMODEL
      Get.to(() => SearchResultsPage(
        trips: tripResults, // ✅ Passer directement les TripModel
        from: _fromController.text,
        to: _toController.text,
        date: _dateController.text,
        time: _timeController.text,
      ));
      
    } catch (e) {
      print('❌ Erreur lors de la navigation: $e');
      UIMessageManager.error("Erreur lors de l'affichage des résultats: ${e.toString()}");
    }

}
 /* Future<void> _performSearchAndNavigate() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      UIMessageManager.error("Please all mandatory fields.");

      return;
    }

    // Construire le GeoPoint pour détours si disponible
    GeoPoint? centerForDetours;
    if (_fromLatitude.value.isNotEmpty && _fromLongitude.value.isNotEmpty) {
      centerForDetours = GeoPoint(
        double.parse(_fromLatitude.value),
        double.parse(_fromLongitude.value),
      );
    }

    // 🎯 RECHERCHE VIA LE CONTRÔLEUR
    await _searchController.searchIntelligentTrips(
      centerForDetours: centerForDetours,
    );

    // 🔥 NAVIGATION IMMÉDIATE VERS SEARCHRESULTSPAGE
    final results = _searchController.results;
    
    if (results.isEmpty) {
      // Si pas de résultats, naviguer quand même vers la page avec liste vide
      Get.to(() => SearchResultsPage(
        trips: [],
        from: _fromController.text,
        to: _toController.text,
        date: _dateController.text,
        time: _timeController.text,
      ));
      return;
    }

    // 🎯 TRANSFORMATION DES TRIPMODEL VERS MAP POUR SEARCHRESULTSPAGE
    final trips = results.asMap().entries.map((entry) {
      final index = entry.key;
      final trip = entry.value;
      
      // Simuler les mêmes types et données pour cohérence visuelle
      final List<String> tripTypes = ['direct', 'intermediate', 'detour'];
      final tripType = tripTypes[index % tripTypes.length];
      final matchScore = 95 - (index * 5).clamp(0, 95);
      final price = 25.0 + (index * 5);
      
      return {
        'tripId': trip.tripId,
        'driverId': trip.driverId,
        'route': '${trip.originAddress} → ${trip.destinationAddress}',
        'origin': trip.originAddress,
        'destination': trip.destinationAddress,
        'departureTime': DateFormat('HH:mm').format(trip.departureTime),
        'arrivalTime': DateFormat('HH:mm').format(trip.departureTime.add(const Duration(hours: 2))),
        'vehicleType': trip.vehicleType,
        'vehicleCapacity': trip.vehicleCapacity,
        'acceptedParcelTypes': trip.acceptedParcelTypes,
        'status': trip.status,
        'allowDetours': trip.allowDetours,
        'waypoints': trip.waypoints ?? [],
        
        // 🔥 DONNÉES POUR AFFICHAGE PROFESSIONNEL
        'tripType': tripType,
        'matchScore': matchScore,
        'actualPrice': price,
        'driverName': 'Conducteur ViaAmigo',
        'rating': '4.${8 - (index % 5)}',
        'completedTrips': (index + 1) * 15,
        'seats': trip.vehicleCapacity['maxParcels'] ?? 4,
        
        // Info détour si applicable
        if (tripType == 'detour')
          'detourInfo': {
            'distance': (index + 1) * 3,
            'time': (index + 1) * 5,
            'extraCost': index * 2.0,
          },
        
        // Info portion si intermédiaire
        if (tripType == 'intermediate')
          'usedPortion': '${100 - (index * 10)}%',
      };
    }).toList();

    // 🚀 NAVIGATION VERS SEARCHRESULTSPAGE AVEC TOUS LES RÉSULTATS
    Get.to(() => SearchResultsPage(
      trips: trips,
      from: _fromController.text,
      to: _toController.text,
      date: _dateController.text,
      time: _timeController.text,
    ));
  }*/

  // Méthodes utilitaires (identiques)
  void _swapAddresses() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
      
      final tempAddress = _fromAddress.value;
      _fromAddress.value = _toAddress.value;
      _toAddress.value = tempAddress;
      
      final tempLat = _fromLatitude.value;
      _fromLatitude.value = _toLatitude.value;
      _toLatitude.value = tempLat;
      
      final tempLng = _fromLongitude.value;
      _fromLongitude.value = _toLongitude.value;
      _toLongitude.value = tempLng;
    });
  }

  // Méthodes pour les champs d'adresse (identiques à votre version)
  Widget _buildAddressSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => showAddressSearchModal(
            context: context,
            isFromField: true,
            initialValue: _fromController.text,
            onSelected: (GeocodingResult result) {
              _fromController.text = result.formattedAddress;
              _fromAddress.value = result.formattedAddress;
              _fromLatitude.value = result.latitude.toString();
              _fromLongitude.value = result.longitude.toString();
              //var city = result.formattedAddress.split(',').first;
            },
          ),
          child: IgnorePointer(
            child: Obx(() => CustomTextField(
              controller: _fromController,
              labelText: 'From',
              hintText: 'Departure address',
              keyboardType: TextInputType.streetAddress,
              borderRadius: 30,
              isTransparent: true,
              prefixIcon: const Icon(LucideIcons.mapPin),
              suffixIcon: _fromAddress.value.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: _clearFromAddress,
                      tooltip: 'Delete address',
                    )
                  : null,
              borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 1),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildToAddressSection(ThemeData theme) {
    return InkWell(
      onTap: () => showAddressSearchModal(
        context: context,
        isFromField: false,
        initialValue: _toController.text,
        onSelected: (GeocodingResult result) {
          _toController.text = result.formattedAddress;
          _toAddress.value = result.formattedAddress;
          _toLatitude.value = result.latitude.toString();
          _toLongitude.value = result.longitude.toString();
        },
      ),
      child: IgnorePointer(
        child: Obx(() => CustomTextField(
          controller: _toController,
          hintText: 'Adresse de destination',
          prefixIcon: const Icon(LucideIcons.map),
          labelText: 'Vers',
          keyboardType: TextInputType.streetAddress,
          borderRadius: 30,
          isTransparent: true,
          suffixIcon: _toAddress.value.isNotEmpty 
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: _clearToAddress,
                  tooltip: 'Supprimer l\'adresse',
                )
              : null,
          hasBorder: true,
          borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        )),
      ),
    );
  }

  Future<void> showAddressSearchModal({
    required BuildContext context,
    required String initialValue,
    required bool isFromField,
    required Function(GeocodingResult) onSelected,
  }) async {
    final theme = Theme.of(context);
    final RxList<GeocodingResult> suggestions = <GeocodingResult>[].obs;
    final TextEditingController searchController = TextEditingController(text: initialValue);
    final FocusNode searchFocusNode = FocusNode();
    
    final RxString searchText = initialValue.obs;
    final navigationController = Get.find<NavigationController>();

    await navigationController.showAppBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      enableDrag: true,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85 - 
                          MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                Obx(() => CustomTextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  hintText: " Address of ${isFromField ? 'départure' : 'destination'}",
                  borderRadius: 30,
                  borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 1),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchText.value.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () {
                            searchController.clear();
                            searchText.value = '';
                            suggestions.clear();
                            if (isFromField) {
                              _clearFromAddress();
                            } else {
                              _clearToAddress();
                            }
                          },
                        )
                      : null,
                  isTransparent: true,
                  onChanged: (query) async {
                    searchText.value = query;
                    
                    if (query.trim().length < 3) {
                      suggestions.clear();
                      return;
                    }
                    final results = await GeocodingService.searchAddressSuggestions(query);
                    suggestions.assignAll(results);
                  },
                )),

                const SizedBox(height: 20),
                Expanded(
                  child: Obx(() => suggestions.isEmpty
                      ? const Center(child: Text("No suggestions"))
                      : ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(suggestion.formattedAddress),
                              onTap: () {
                                onSelected(suggestion);
                                Get.back();
                              },
                            );
                          },
                        )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required VoidCallback onDateTap,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onDateTap,
          child: IgnorePointer(
            child: CustomTextField(
              controller: dateController,
              hintText: 'Select date',
              borderRadius: 30,
              isTransparent: true,
              prefixIcon: Icon(icon, size: 16),
              hasBorder: true,
              borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 1),
            ),
          ),
        )
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _clearFromAddress() {
    setState(() {
      _fromController.clear();
      _fromAddress.value = '';
      _fromLatitude.value = '';
      _fromLongitude.value = '';
    });
  }

  void _clearToAddress() {
    setState(() {
      _toController.clear();
      _toAddress.value = '';
      _toLatitude.value = '';
      _toLongitude.value = '';
    });
  }
}