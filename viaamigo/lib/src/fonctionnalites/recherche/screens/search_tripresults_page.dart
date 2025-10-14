
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';

/// ✅ PAGE DE RÉSULTATS BASÉE SUR LE VRAI TRIPMODEL
class SearchResultsPage extends StatelessWidget {
  final List<TripModel> trips; // ✅ Type correct
  final String from;
  final String to;
  final String date;
  final String time;

  const SearchResultsPage({
    super.key,
    required this.trips,
    required this.from,
    required this.to,
    this.date = '',
    this.time = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text('${from.split(',').first} → ${to.split(',').first}'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: trips.isEmpty ? _buildEmptyState(theme) : _buildResultsList(theme),
      ),
    );
  }

  /// État vide (identique)
  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun trajet trouvé',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Essayez de modifier vos critères de recherche ou activez les options avancées',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSuggestionChip('Élargir zone', Icons.zoom_out, theme),
                    _buildSuggestionChip('Autres dates', Icons.calendar_today, theme),
                    _buildSuggestionChip('Plus flexible', Icons.tune, theme),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Liste basée sur le vrai TripModel
  Widget _buildResultsList(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // Header avec statistiques RÉELLES
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.route, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trips.length} trajet${trips.length > 1 ? 's' : ''} trouvé${trips.length > 1 ? 's' : ''}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '$from → $to',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ Badge basé sur les statuts réels
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_countAvailableTrips()} disponibles',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (date.isNotEmpty || time.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (date.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      if (date.isNotEmpty && time.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (time.isNotEmpty) ...[
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Liste des trajets RÉELS
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 
                  index == 0 ? 0 : 8, 
                  20, 
                  index == trips.length - 1 ? 20 : 8
                ),
                child: _buildRealTripCard(trips[index], theme),
              );
            },
            childCount: trips.length,
          ),
        ),
      ],
    );
  }

  /// 🔥 CARTE BASÉE SUR LE VRAI TRIPMODEL
  Widget _buildRealTripCard(TripModel trip, ThemeData theme) {
    // ✅ Déterminer le type de trajet basé sur les vraies propriétés
    String tripType = 'direct';
    String typeLabel = 'DIRECT';
    IconData typeIcon = Icons.straight;
    Color badgeColor = theme.colorScheme.primary;

    // ✅ Logique basée sur les vraies propriétés du TripModel
    if (trip.waypoints != null && trip.waypoints!.isNotEmpty) {
      tripType = 'intermediate';
      typeLabel = 'AVEC ARRÊTS';
      typeIcon = Icons.alt_route;
      badgeColor = Colors.blue;
    } else if (trip.allowDetours) {
      tripType = 'detour';
      typeLabel = 'DÉTOURS ACCEPTÉS';
      typeIcon = Icons.explore;
      badgeColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header avec badge et statut RÉELS
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                // ✅ Statut réel du trajet
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(trip.status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    trip.displayStatus,
                    style: TextStyle(
                      color: _getStatusColor(trip.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Info du trajet basée sur TripModel
            Row(
              children: [
                // ✅ Avatar basé sur le type de véhicule
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    _getVehicleIcon(trip.vehicleType),
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Route réelle
                      Text(
                        '${trip.originAddress} → ${trip.destinationAddress}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // ✅ Type de véhicule et info véhicule RÉELS
                      Text(
                        '${_getVehicleDisplayName(trip.vehicleType)}${trip.vehicleInfo['brand'] != null && trip.vehicleInfo['brand'].toString().isNotEmpty ? ' ${trip.vehicleInfo['brand']}' : ''}${trip.vehicleInfo['model'] != null && trip.vehicleInfo['model'].toString().isNotEmpty ? ' ${trip.vehicleInfo['model']}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      
                      // ✅ Horaires RÉELS
                      if (trip.departureTime != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule, color: theme.colorScheme.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('HH:mm').format(trip.departureTime)}${trip.arrivalTime != null ? ' → ${DateFormat('HH:mm').format(trip.arrivalTime!)}' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ✅ Capacités RÉELLES du TripModel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ✅ Capacité max colis
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${trip.vehicleCapacity['maxParcels'] ?? 0} colis max',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ✅ Poids max
                    Text(
                      '${trip.vehicleCapacity['maxWeight'] ?? 0}kg max',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ✅ Informations spécialisées RÉELLES
            if (trip.waypoints != null && trip.waypoints!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alt_route, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Arrêts intermédiaires (${trip.waypoints!.length})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...trip.waypoints!.take(2).map((waypoint) => 
                      Text(
                        '• ${waypoint['address']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    if (trip.waypoints!.length > 2)
                      Text(
                        '... et ${trip.waypoints!.length - 2} autres arrêts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (trip.allowDetours) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.explore, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Détours acceptés • Le conducteur peut adapter son trajet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ✅ Types de colis acceptés (propriété réelle du TripModel)
            if (trip.acceptedParcelTypes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: trip.acceptedParcelTypes.take(4).map((type) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getParcelTypeDisplayName(type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // ✅ Bouton de réservation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _bookTrip(trip, theme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Réserver ce trajet ${typeLabel.toLowerCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTHODES UTILITAIRES BASÉES SUR LE VRAI TRIPMODEL

  int _countAvailableTrips() {
    return trips.where((trip) => trip.status == 'available').length;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'bicycle':
        return Icons.pedal_bike;
      default:
        return Icons.directions_car;
    }
  }

  String _getVehicleDisplayName(String vehicleType) {
    switch (vehicleType) {
      case 'car':
        return 'Voiture';
      case 'van':
        return 'Fourgonnette';
      case 'truck':
        return 'Camion';
      case 'motorcycle':
        return 'Moto';
      case 'bicycle':
        return 'Vélo';
      default:
        return 'Véhicule';
    }
  }

  String _getParcelTypeDisplayName(String type) {
    switch (type) {
      case 'documents':
        return 'Documents';
      case 'electronics':
        return 'Électronique';
      case 'clothing':
        return 'Vêtements';
      case 'fragile':
        return 'Fragile';
      case 'perishable':
        return 'Périssable';
      case 'bulky':
        return 'Volumineux';
      default:
        return type;
    }
  }

  /// ✅ Fonction de réservation avec le vrai TripModel
  void _bookTrip(TripModel trip, ThemeData theme) {
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Réservation',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmer la réservation de ce trajet ?',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 ${trip.originAddress} → ${trip.destinationAddress}'),
                  Text('🕐 ${DateFormat('dd/MM/yyyy HH:mm').format(trip.departureTime)}'),
                  Text('🚗 ${_getVehicleDisplayName(trip.vehicleType)}'),
                  Text('📦 ${trip.vehicleCapacity['maxParcels'] ?? 0} colis max (${trip.vehicleCapacity['maxWeight'] ?? 0}kg)'),
                  Text('📋 ${trip.displayStatus}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Réservation confirmée',
                'Trajet ${trip.tripId} réservé avec succès !',
                backgroundColor: theme.colorScheme.primary,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
