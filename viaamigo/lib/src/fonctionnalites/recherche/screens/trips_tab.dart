import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';

/// Onglet Trajets - Style Poparide avec recherche intelligente intégrée - CORRIGÉ
/// 
/// Fonctionnalités :
/// - Interface de recherche From/To
/// - Options avancées (points de passage, détours)
/// - Recherche intelligente avec 3 types de trajets
/// - Résultats avec badges colorés
/// - Réservation intégrée
/// 
/// ✅ CORRIGÉ : Remplacement de .withOpacity() par .withValues(alpha:)
class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  // Contrôleurs de recherche
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Options de recherche intelligente
  bool _includeIntermediateStops = true;
  bool _allowDetours = false;
  double _maxDetourDistance = 50.0;
  int _maxDetourTime = 30;

  // État de la recherche
  List<Map<String, dynamic>> _tripResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Interface de recherche intelligente - STYLE POPARIDE
          _buildIntelligentSearchInterface(theme),
          
          const SizedBox(height: 30),
          
          // Résultats de recherche
          _buildSearchResults(theme),
        ],
      ),
    );
  }

  /// Interface de recherche intelligente - STYLE POPARIDE - CORRIGÉ
  Widget _buildIntelligentSearchInterface(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ✅ CORRIGÉ : withOpacity → withValues
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
          // Header comme Poparide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ✅ CORRIGÉ : withOpacity → withValues
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
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche Intelligente',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Trouvez des trajets avec points de passage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          // ✅ CORRIGÉ : withOpacity → withValues
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

          // Champs From/To - STYLE POPARIDE
          CustomTextField(
            controller: _fromController,
            hintText: 'Enter a location',
            prefixIcon: const Icon(Icons.location_on),
            labelText: 'From',
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
             
              hasBorder: true,
              borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),

          ),
          
          const SizedBox(height: 1),
          
          // Bouton d'échange
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: IconButton(
                onPressed: () {
                  final temp = _fromController.text;
                  _fromController.text = _toController.text;
                  _toController.text = temp;
                },
                icon: Icon(
                  Icons.swap_vert,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 1),
          
          CustomTextField(
            controller: _toController,
            hintText: 'Enter a location',
            prefixIcon: const Icon(Icons.flag),
            labelText: 'To',
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              hasBorder: true,
              borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),

          const SizedBox(height: 25),

          // Options intelligentes - STYLE CLEAN
          Text(
            'More Options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 15),

          // Toggle pour points de passage
          _buildCleanOption(
            title: 'Include Intermediate Stops',
            subtitle: 'Ex: Trips passing through your city',
            value: _includeIntermediateStops,
            onChanged: (value) {
              setState(() {
                _includeIntermediateStops = value;
              });
            },
            icon: Icons.alt_route,
            theme: theme,
          ),

          const SizedBox(height: 12),

          // Toggle pour détours
          _buildCleanOption(
            title: 'Allow Detours',
            subtitle: 'Accept trips with slight detours',
            value: _allowDetours,
            onChanged: (value) {
              setState(() {
                _allowDetours = value;
              });
            },
            icon: Icons.explore,
            theme: theme,
          ),

          // Options de détour (si activées) - CORRIGÉ
          if (_allowDetours) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // ✅ CORRIGÉ : withOpacity → withValues
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // ✅ CORRIGÉ : withOpacity → withValues
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limites des détours',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Distance slider
                  Text(
                    'Distance max: ${_maxDetourDistance.toInt()} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      // ✅ CORRIGÉ : withOpacity → withValues
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Slider(
                    value: _maxDetourDistance,
                    min: 10,
                    max: 100,
                    divisions: 18,
                    onChanged: (value) {
                      setState(() {
                        _maxDetourDistance = value;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Temps slider
                  Text(
                    'Temps max: $_maxDetourTime min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      // ✅ CORRIGÉ : withOpacity → withValues
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Slider(
                    value: _maxDetourTime.toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() {
                        _maxDetourTime = value.toInt();
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 25),

          // Bouton de recherche - STYLE POPARIDE
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _searchIntelligentTrips,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isSearching
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// TextField propre - STYLE POPARIDE - CORRIGÉ

  /// Option propre - STYLE CLEAN - CORRIGÉ
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
            // ✅ CORRIGÉ : withOpacity → withValues
            ? theme.colorScheme.primary.withValues(alpha: 0.1) 
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              // ✅ CORRIGÉ : withOpacity → withValues
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
                // ✅ CORRIGÉ : withOpacity → withValues
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
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white//theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Système de recherche intelligente pour trajets
  Future<void> _searchIntelligentTrips() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir les champs DE et VERS',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _tripResults.clear();
    });

    try {
      // 1. Recherche trajets directs
      final directTrips = await _searchDirectTrips();
      
      // 2. Recherche trajets avec points de passage
      List<Map<String, dynamic>> intermediateTrips = [];
      if (_includeIntermediateStops) {
        intermediateTrips = await _searchIntermediateTrips();
      }
      
      // 3. Recherche trajets avec détours acceptés
      List<Map<String, dynamic>> detourTrips = [];
      if (_allowDetours) {
        detourTrips = await _searchDetourTrips();
      }

      // Combiner et trier les résultats
      final allTrips = [...directTrips, ...intermediateTrips, ...detourTrips];
      allTrips.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));

      setState(() {
        _tripResults = allTrips;
        _isSearching = false;
      });

      Get.snackbar(
        'Recherche terminée',
        '${allTrips.length} trajets trouvés',
        // ignore: use_build_context_synchronously
        backgroundColor: Theme.of(context).colorScheme.primary,
        colorText: Colors.white,
      );

    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      Get.snackbar(
        'Erreur de recherche',
        'Une erreur est survenue lors de la recherche',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Recherche trajets directs
  Future<List<Map<String, dynamic>>> _searchDirectTrips() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'id': 'direct_1',
        'tripType': 'direct',
        'route': '${_fromController.text} → ${_toController.text}',
        'departure': _fromController.text,
        'destination': _toController.text,
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
  Future<List<Map<String, dynamic>>> _searchIntermediateTrips() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      {
        'id': 'intermediate_1',
        'tripType': 'intermediate',
        'route': 'Montréal → ${_fromController.text} → ${_toController.text}',
        'departure': 'Montréal',
        'destination': _toController.text,
        'stops': ['Montréal', _fromController.text, _toController.text],
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
  Future<List<Map<String, dynamic>>> _searchDetourTrips() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      {
        'id': 'detour_1',
        'tripType': 'detour',
        'route': 'Gatineau → ${_fromController.text} → ${_toController.text}',
        'departure': 'Gatineau',
        'destination': _toController.text,
        'matchScore': 70,
        'actualPrice': 30.0,
        'originalPrice': 25.0,
        'detourInfo': {
          'distance': 25.0,
          'time': 20,
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

  /// Résultats de recherche - CORRIGÉ
  Widget _buildSearchResults(ThemeData theme) {
    if (_tripResults.isEmpty && !_isSearching) {
      return Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              // ✅ CORRIGÉ : withOpacity → withValues
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 15),
            Text(
              'Aucun résultat pour le moment',
              style: theme.textTheme.titleMedium?.copyWith(
                // ✅ CORRIGÉ : withOpacity → withValues
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez la recherche intelligente ci-dessus',
              style: theme.textTheme.bodySmall?.copyWith(
                // ✅ CORRIGÉ : withOpacity → withValues
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tripResults.isNotEmpty) ...[
          Text(
            'Résultats trouvés (${_tripResults.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Liste des résultats
        ..._tripResults.map((trip) => _buildCleanTripCard(trip, theme)),
      ],
    );
  }

  /// Carte de trajet propre - STYLE POPARIDE - CORRIGÉ
  Widget _buildCleanTripCard(Map<String, dynamic> trip, ThemeData theme) {
    final tripType = trip['tripType'] as String;
    
    // Couleurs selon votre thème
    Color badgeColor = theme.colorScheme.primary;
    String typeLabel;
    IconData typeIcon;

    switch (tripType) {
      case 'direct':
        typeLabel = 'DIRECT';
        typeIcon = Icons.straight;
        break;
      case 'intermediate':
        typeLabel = 'POINT DE PASSAGE';
        typeIcon = Icons.alt_route;
        badgeColor = Colors.blue;
        break;
      case 'detour':
        typeLabel = 'DÉTOUR';
        typeIcon = Icons.explore;
        badgeColor = Colors.orange;
        break;
      default:
        typeLabel = 'TRAJET';
        typeIcon = Icons.directions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            // ✅ CORRIGÉ : withOpacity → withValues
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Score: ${trip['matchScore']}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Info du trajet
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    // ✅ CORRIGÉ : withOpacity → withValues
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person, 
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip['route'] ?? 'Trajet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip['driverName'] ?? 'Conducteur',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // ✅ CORRIGÉ : withOpacity → withValues
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '⭐ ${trip['rating'] ?? 'N/A'} • ${trip['completedTrips'] ?? 0} trajets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            // ✅ CORRIGÉ : withOpacity → withValues
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (trip['departureTime'] != null && trip['arrivalTime'] != null)
                          Text(
                            '🕐 ${trip['departureTime']} → ${trip['arrivalTime']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              // ✅ CORRIGÉ : withOpacity → withValues
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Prix
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${trip['actualPrice']?.toStringAsFixed(2) ?? '0.00'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (tripType == 'intermediate')
                        Text(
                          'Portion: ${trip['usedPortion']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            // ✅ CORRIGÉ : withOpacity → withValues
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      if (trip['seats'] != null)
                        Text(
                          '${trip['seats']} places',
                          style: theme.textTheme.bodySmall?.copyWith(
                            // ✅ CORRIGÉ : withOpacity → withValues
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Info détour si applicable - CORRIGÉ
              if (tripType == 'detour' && trip['detourInfo'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Détour: +${trip['detourInfo']['distance']}km, +${trip['detourInfo']['time']}min (+\$${trip['detourInfo']['extraCost']})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            // ✅ CORRIGÉ : withOpacity → withValues
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Bouton de réservation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookTrip(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Réserver ce trajet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fonction de réservation - CORRIGÉ
  void _bookTrip(Map<String, dynamic> trip) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Réservation',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Voulez-vous réserver ce trajet ${trip['tripType']} ?\n\n'
          'Route: ${trip['route']}\n'
          'Prix: \$${trip['actualPrice']?.toStringAsFixed(2)}',
          // ✅ CORRIGÉ : withOpacity → withValues
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Annuler', 
              // ✅ CORRIGÉ : withOpacity → withValues
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Réservation confirmée',
                'Votre trajet a été réservé avec succès !',
                backgroundColor: Theme.of(context).colorScheme.primary,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Confirmer', 
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}