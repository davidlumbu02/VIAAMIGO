/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';

/// Service Firebase optimisé pour VIAAMIGO avec geoflutterfire_plus 0.0.33
/// Implémente toutes les recommendations de Grok pour une performance maximale
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections géolocalisées centralisées - Excellente pratique selon Grok
  final GeoCollectionReference<Map<String, dynamic>> _parcelsGeoCollection;
  final GeoCollectionReference<Map<String, dynamic>> _tripsGeoCollection;

  FirebaseService()
      : _parcelsGeoCollection = GeoCollectionReference<Map<String, dynamic>>(
          FirebaseFirestore.instance.collection('parcels'),
        ),
        _tripsGeoCollection = GeoCollectionReference<Map<String, dynamic>>(
          FirebaseFirestore.instance.collection('trips'),
        );

  // ==================== MÉTHODES UTILITAIRES OPTIMISÉES ====================

  /// ✅ OPTIMISATION GROK #1: Factorisation des filtres pour éviter la duplication
  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query, 
    Map<String, bool>? filters
  ) {
    if (filters != null) {
      if (filters['urgent'] == true) {
        query = query.where('delivery_speed', isEqualTo: 'express');
      }
      if (filters['instant_booking'] == true) {
        query = query.where('paymentMethod', isEqualTo: 'pay_now');
      }
    }
    return query;
  }

  /// ✅ OPTIMISATION GROK #2: Gestion sécurisée du geopointFrom avec validation
  GeoPoint _extractGeoPoint(Map<String, dynamic> data, String field) {
    if (data[field] == null) {
      throw Exception('Champ "$field" manquant ou mal formaté');
    }
    
    final fieldData = data[field];
    
    // ✅ Support flexible: GeoPoint direct OU Map avec {geopoint, geohash}
    if (fieldData is GeoPoint) {
      return fieldData; // Cas de vos modèles actuels
    } else if (fieldData is Map<String, dynamic>) {
      // Cas documentation officielle {geopoint: GeoPoint, geohash: String}
      if (fieldData.containsKey('geopoint')) {
        return fieldData['geopoint'] as GeoPoint;
      }
    }
    
    throw Exception('Structure du champ "$field" invalide. Attendu: GeoPoint ou {geopoint: GeoPoint}');
  }

  /// ✅ OPTIMISATION GROK #3: Validation et filtrage centralisé des colis
  bool _isValidParcel(Map<String, dynamic>? data, String? query, Map<String, bool>? filters) {
    if (data == null || 
        data['status'] != 'pending' || 
        data['geoIndexReady'] != true) {
      return false;
    }
    
    // Filtre textuel
    if (query != null && query.isNotEmpty) {
      final originAddress = data['originAddress'] as String? ?? '';
      if (!originAddress.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
    }
    
    // Filtres rapides
    if (filters != null) {
      if (filters['urgent'] == true && data['delivery_speed'] != 'express') {
        return false;
      }
      if (filters['instant_booking'] == true && data['paymentMethod'] != 'pay_now') {
        return false;
      }
    }
    
    return true;
  }

  /// ✅ OPTIMISATION GROK #4: Validation centralisée des trajets
  bool _isValidTrip(Map<String, dynamic>? data) {
    return data != null && data['status'] == 'available';
  }
  
  // === MÉTHODES CORRIGÉES POUR LA RECHERCHE DE SEGMENTS ===

  /// Trouve l'index d'une location dans la route complète
  int? _findLocationIndex(List<Map<String, dynamic>> fullRoute, String locationName) {
    for (int i = 0; i < fullRoute.length; i++) {
      final location = fullRoute[i];
      String? locationAddress;
      
      // Gérer les différents formats (origin/destination vs waypoints)
      if (location.containsKey('address')) {
        // C'est un waypoint
        locationAddress = location['address']?.toString();
      } else if (location.containsKey('originAddress')) {
        // C'est l'origine
        locationAddress = location['originAddress']?.toString();
      } else if (location.containsKey('destinationAddress')) {
        // C'est la destination  
        locationAddress = location['destinationAddress']?.toString();
      }
      
      if (locationAddress?.toLowerCase() == locationName.toLowerCase()) {
        return i;
      }
    }
    return null;
  }

  /// Construit la route complète avec origine, waypoints et destination
  List<Map<String, dynamic>> _buildFullRoute(Map<String, dynamic> tripData) {
    List<Map<String, dynamic>> fullRoute = [];
    
    // 1. Ajouter l'origine
    if (tripData['originAddress'] != null) {
      fullRoute.add({
        'address': tripData['originAddress'],
        'type': 'origin',
        'latitude': tripData['origin']?.latitude,
        'longitude': tripData['origin']?.longitude,
      });
    }
    
    // 2. Ajouter les waypoints
    if (tripData['waypoints'] != null && tripData['waypoints'] is List) {
      for (var waypoint in tripData['waypoints']) {
        if (waypoint is Map<String, dynamic>) {
          fullRoute.add({
            'address': waypoint['address'],
            'type': 'waypoint',
            'latitude': waypoint['latitude'],
            'longitude': waypoint['longitude'],
            'stopDuration': waypoint['stopDuration'],
          });
        }
      }
    }
    
    // 3. Ajouter la destination
    if (tripData['destinationAddress'] != null) {
      fullRoute.add({
        'address': tripData['destinationAddress'],
        'type': 'destination', 
        'latitude': tripData['destination']?.latitude,
        'longitude': tripData['destination']?.longitude,
      });
    }
    
    return fullRoute;
  }

  /// Vérifie si le segment demandé existe dans le trajet avec le bon ordre
  bool _isValidSegment(Map<String, dynamic> tripData, String fromLocation, String toLocation) {
    final fullRoute = _buildFullRoute(tripData);
    
    if (fullRoute.length < 2) return false;
    
    int? fromIndex;
    int? toIndex;
    
    // Trouver les indices des locations dans la route
    for (int i = 0; i < fullRoute.length; i++) {
      final locationAddress = fullRoute[i]['address']?.toString().toLowerCase();
      
      if (locationAddress == fromLocation.toLowerCase()) {
        fromIndex = i;
      }
      if (locationAddress == toLocation.toLowerCase()) {
        toIndex = i;
      }
    }
    
    // Vérifier que les deux locations existent et que from vient avant to
    bool isValid = fromIndex != null && toIndex != null && fromIndex < toIndex;
    
    if (isValid) {
      print('✅ Segment valide: $fromLocation (index $fromIndex) → $toLocation (index $toIndex)');
      print('   Route complète: ${fullRoute.map((r) => r['address']).join(' → ')}');
    }
    
    return isValid;
  }

  /// Recherche les trajets qui contiennent le segment demandé
  Future<List<QueryDocumentSnapshot>> _searchTripSegments(
    String fromLocation, 
    String toLocation
  ) async {
    try {
      print('🔍 Recherche de segments: $fromLocation → $toLocation');
      
      // ÉTAPE 1: Rechercher tous les trajets actifs
      // (On ne peut pas faire de requête complexe sur les waypoints directement)
      final allTripsQuery = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .get();
      
      List<QueryDocumentSnapshot> validTrips = [];
      int checkedTrips = 0;
      
      // ÉTAPE 2: Vérifier chaque trajet individuellement
      for (var doc in allTripsQuery.docs) {
        checkedTrips++;
        final tripData = doc.data() as Map<String, dynamic>;
        
        // Vérifier si c'est un segment valide
        if (_isValidSegment(tripData, fromLocation, toLocation)) {
          validTrips.add(doc);
          print('✅ Segment valide trouvé: ${doc.id}');
          
          // Debug: afficher la route du trajet trouvé
          final route = _buildFullRoute(tripData);
          print('   Route: ${route.map((r) => r['address']).join(' → ')}');
        }
      }
      
      print('📊 Vérification: $checkedTrips trajets analysés');
      print('📊 Résultat: ${validTrips.length} segments valides trouvés');
      return validTrips;
      
    } catch (e) {
      print('❌ Erreur lors de la recherche de segments: $e');
      return [];
    }
  }

  // ==================== RECHERCHE DE COLIS OPTIMISÉE ====================

  /// Recherche de colis avec filtres (fetch unique) - VERSION OPTIMISÉE
  Future<List<ParcelModel>> searchParcels({
    String? query,
    GeoPoint? nearLocation,
    double radiusKm = 50.0,
    Map<String, bool>? filters,
    int? limit = 50, // ✅ OPTIMISATION PERFORMANCE: Limite par défaut
  }) async {
    try {
      // Recherche géographique optimisée
      if (nearLocation != null) {
        final center = GeoFirePoint(nearLocation);
        
        final geoResults = await _parcelsGeoCollection.fetchWithin(
          center: center,
          radiusInKm: radiusKm,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: true,
        );

        // ✅ OPTIMISATION: Filtrage et conversion en une seule passe
        final results = geoResults
            .where((doc) => _isValidParcel(doc.data(), query, filters))
            .take(limit ?? 50) // Limite de performance
            .map((doc) => ParcelModel.fromFirestore(doc))
            .toList();
            
        return results;
      }

      // Recherche classique optimisée avec filtres factorisés
      Query<Map<String, dynamic>> parcelQuery = _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'pending')
          .where('geoIndexReady', isEqualTo: true);

      // Filtre textuel
      if (query != null && query.isNotEmpty) {
        parcelQuery = parcelQuery
            .where('originAddress', isGreaterThanOrEqualTo: query)
            .where('originAddress', isLessThanOrEqualTo: '$query\uf8ff');
      }

      // ✅ OPTIMISATION GROK: Utilisation de la méthode factorisée
      parcelQuery = _applyFilters(parcelQuery, filters);
      
      // Limite de performance
      if (limit != null) {
        parcelQuery = parcelQuery.limit(limit);
      }

      final querySnapshot = await parcelQuery.get();
      return querySnapshot.docs.map((doc) => ParcelModel.fromFirestore(doc)).toList();

    } catch (e) {
      throw Exception('Erreur lors de la recherche des colis: $e');
    }
  }

  /// Recherche de colis en temps réel (stream) - VERSION OPTIMISÉE
  Stream<List<ParcelModel>> searchParcelsStream({
    String? query,
    GeoPoint? nearLocation,
    double radiusKm = 50.0,
    Map<String, bool>? filters,
    int? limit = 50,
  }) {
    try {
      if (nearLocation != null) {
        final center = GeoFirePoint(nearLocation);
        
        return _parcelsGeoCollection.subscribeWithin(
          center: center,
          radiusInKm: radiusKm,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: true,
        ).map((docs) {
          return docs
              .where((doc) => _isValidParcel(doc.data(), query, filters))
              .take(limit ?? 50)
              .map((doc) => ParcelModel.fromFirestore(doc))
              .toList();
        });
      }

      // Stream classique avec filtres optimisés
      Query<Map<String, dynamic>> parcelQuery = _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'pending')
          .where('geoIndexReady', isEqualTo: true);

      if (query != null && query.isNotEmpty) {
        parcelQuery = parcelQuery
            .where('originAddress', isGreaterThanOrEqualTo: query)
            .where('originAddress', isLessThanOrEqualTo: '$query\uf8ff');
      }

      parcelQuery = _applyFilters(parcelQuery, filters);
      
      if (limit != null) {
        parcelQuery = parcelQuery.limit(limit);
      }

      return parcelQuery.snapshots().map((snapshot) => 
          snapshot.docs.map((doc) => ParcelModel.fromFirestore(doc)).toList());
          
    } catch (e) {
      throw Exception('Erreur lors du stream de recherche des colis: $e');
    }
  }

  // ==================== RECHERCHE DE TRAJETS OPTIMISÉE ====================

  Future<List<Map<String, dynamic>>> searchTrips({
    required String fromLocation,
    required String toLocation,
    DateTime? departureDate,
    int? availableSeats,
  }) async {
    try {
      print('🔍 Recherche de trajets: $fromLocation → $toLocation');
      
      Set<String> uniqueTrips = {};
      List<Map<String, dynamic>> allTrips = [];

      // === 1. RECHERCHE DIRECTE ===
      print('🎯 Phase 1: Recherche directe');
      final directQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .where('originAddress', isEqualTo: fromLocation)
          .where('destinationAddress', isEqualTo: toLocation);

      final directResults = await directQuery.get();
      
      for (var doc in directResults.docs) {
        if (!uniqueTrips.contains(doc.id)) {
          uniqueTrips.add(doc.id);
          final data = doc.data();
          data['id'] = doc.id;
          data['match_type'] = 'direct';
          allTrips.add(data);
        }
      }
      print('📊 Trajets directs trouvés: ${directResults.docs.length}');

      // === 2. RECHERCHE AVEC WAYPOINTS ===
      print('🛣️ Phase 2: Recherche avec waypoints');
      
      // 2a. Trajets où origin = fromLocation ET waypoints contient toLocation
      final waypointAsDestQuery = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .where('originAddress', isEqualTo: fromLocation)
          .get();

      for (var doc in waypointAsDestQuery.docs) {
        if (!uniqueTrips.contains(doc.id)) {
          final data = doc.data();
          // Vérifier si les waypoints contiennent toLocation
          if (data['waypoints'] != null && data['waypoints'] is List) {
            bool hasDestination = false;
            for (var waypoint in data['waypoints']) {
              if (waypoint is Map<String, dynamic> && 
                  waypoint['address']?.toString().toLowerCase() == toLocation.toLowerCase()) {
                hasDestination = true;
                break;
              }
            }
            if (hasDestination) {
              uniqueTrips.add(doc.id);
              data['id'] = doc.id;
              data['match_type'] = 'waypoint_as_destination';
              allTrips.add(data);
            }
          }
        }
      }

      // 2b. Trajets où destination = toLocation ET waypoints contient fromLocation
      final waypointAsOriginQuery = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .where('destinationAddress', isEqualTo: toLocation)
          .get();

      for (var doc in waypointAsOriginQuery.docs) {
        if (!uniqueTrips.contains(doc.id)) {
          final data = doc.data();
          // Vérifier si les waypoints contiennent fromLocation
          if (data['waypoints'] != null && data['waypoints'] is List) {
            bool hasOrigin = false;
            for (var waypoint in data['waypoints']) {
              if (waypoint is Map<String, dynamic> && 
                  waypoint['address']?.toString().toLowerCase() == fromLocation.toLowerCase()) {
                hasOrigin = true;
                break;
              }
            }
            if (hasOrigin) {
              uniqueTrips.add(doc.id);
              data['id'] = doc.id;
              data['match_type'] = 'waypoint_as_origin';
              allTrips.add(data);
            }
          }
        }
      }
      print('📊 Trajets avec waypoints trouvés: ${waypointAsDestQuery.docs.length + waypointAsOriginQuery.docs.length}');

      // === 3. NOUVELLE RECHERCHE DE SEGMENTS ===
      print('🧩 Phase 3: Recherche de segments d\'itinéraire');
      final segmentResults = await _searchTripSegments(fromLocation, toLocation);
      
      for (var doc in segmentResults) {
        if (!uniqueTrips.contains(doc.id)) {
          uniqueTrips.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['match_type'] = 'segment';
          allTrips.add(data);
        }
      }
      print('📊 Segments d\'itinéraire trouvés: ${segmentResults.length}');

      // === 4. RECHERCHE GÉOSPATIALE (SIMPLIFIÉE) ===
      print('🌍 Phase 4: Recherche géospatiale');
      
      // Version simplifiée - on cherche les trajets avec allowDetours = true
      final geoQuery = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .where('allowDetours', isEqualTo: true)
          .get();

      for (var doc in geoQuery.docs) {
        if (!uniqueTrips.contains(doc.id)) {
          uniqueTrips.add(doc.id);
          final data = doc.data();
          data['id'] = doc.id;
          data['match_type'] = 'geospatial';
          allTrips.add(data);
        }
      }
      print('📊 Trajets géospatiaux trouvés: ${geoQuery.docs.length}');

      // === FILTRAGE ET TRI ===
      if (departureDate != null) {
        allTrips = allTrips.where((trip) {
          if (trip['departureTime'] != null) {
            final tripDate = (trip['departureTime'] as Timestamp).toDate();
            return tripDate.isAfter(departureDate.subtract(Duration(days: 1))) &&
                   tripDate.isBefore(departureDate.add(Duration(days: 1)));
          }
          return false;
        }).toList();
      }

      if (availableSeats != null) {
        allTrips = allTrips.where((trip) {
          final maxParcels = trip['vehicleCapacity']?['maxParcels'] ?? 0;
          return maxParcels >= availableSeats;
        }).toList();
      }

      // Trier par priorité de match
      allTrips.sort((a, b) {
        const matchPriority = {
          'direct': 1,
          'waypoint_as_destination': 2,
          'waypoint_as_origin': 3,
          'segment': 4,
          'geospatial': 5,
        };
        
        final aPriority = matchPriority[a['match_type']] ?? 6;
        final bPriority = matchPriority[b['match_type']] ?? 6;
        
        return aPriority.compareTo(bPriority);
      });

      print('✅ Total des trajets uniques trouvés: ${allTrips.length}');
      return allTrips;

    } catch (e) {
      print('❌ Erreur lors de la recherche: $e');
      rethrow;
    }
  }

  /// Recherche de trajets en temps réel (stream) - VERSION OPTIMISÉE
  Stream<List<TripModel>> searchTripsStream({
    required String fromLocation,
    required String toLocation,
    GeoPoint? centerForDetours,
    double maxDetourDistance = 50.0,
    int? limit = 50,
  }) {
    try {
      if (centerForDetours != null) {
        final center = GeoFirePoint(centerForDetours);
        
        return _tripsGeoCollection.subscribeWithin(
          center: center,
          radiusInKm: maxDetourDistance,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: false,
        ).map((docs) {
          return docs
              .where((doc) => _isValidTrip(doc.data()))
              .map((doc) => TripModel.fromFirestore(doc))
              .where((trip) => trip.allowDetours)
              .take(limit ?? 50)
              .toList();
        });
      }

      // Stream classique optimisé
      Query<Map<String, dynamic>> tripQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'available')
          .where('originAddress', isEqualTo: fromLocation)
          .where('destinationAddress', isEqualTo: toLocation);
          
      if (limit != null) {
        tripQuery = tripQuery.limit(limit);
      }

      return tripQuery.snapshots().map((snapshot) => 
          snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
          
    } catch (e) {
      throw Exception('Erreur lors du stream de recherche des trajets: $e');
    }
  }

  // ==================== OPERATIONS CRUD OPTIMISÉES ====================

  /// Réserver un trajet - ✅ GROK: Ajout de updatedAt
  Future<void> bookTrip(String tripId, String userId, {String? parcelId}) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'booked',
        'bookedBy': userId,
        if (parcelId != null) 'matchId': parcelId,
        'updatedAt': FieldValue.serverTimestamp(), // ✅ GROK: Suivi des modifications
      });
    } catch (e) {
      throw Exception('Erreur lors de la réservation du trajet: $e');
    }
  }

  /// Annuler une réservation - ✅ GROK: Ajout de updatedAt
  Future<void> cancelBooking(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'available',
        'bookedBy': FieldValue.delete(),
        'matchId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(), // ✅ GROK: Suivi des modifications
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }

  // ==================== MATCHING OPTIMISÉ ====================

  /// Matching colis-trajet - ✅ GROK: Gestion sécurisée des GeoPoint null
  Future<List<Map<String, dynamic>>> matchTripsForParcel(ParcelModel parcel) async {
    return await searchTrips(
      fromLocation: parcel.originAddress,
      toLocation: parcel.destinationAddress,
    );
  }

  /// Matching en temps réel - ✅ GROK: Gestion sécurisée
  Stream<List<TripModel>> matchTripsForParcelStream(ParcelModel parcel) {
    return searchTripsStream(
      fromLocation: parcel.originAddress,
      toLocation: parcel.destinationAddress,
      limit: 20,
    ).map((trips) => trips.where((trip) => trip.canAcceptParcel(parcel)).toList());
  }

  // ==================== ACCESSEURS INDIVIDUELS ====================

  /// Obtenir un colis par ID avec gestion d'erreur
  Future<ParcelModel?> getParcelById(String parcelId) async {
    try {
      final doc = await _firestore.collection('parcels').doc(parcelId).get();
      return doc.exists ? ParcelModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du colis: $e');
    }
  }

  /// Obtenir un trajet par ID avec gestion d'erreur
  Future<TripModel?> getTripById(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      return doc.exists ? TripModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du trajet: $e');
    }
  }

  /// Stream d'un colis spécifique
  Stream<ParcelModel?> getParcelStream(String parcelId) {
    return _firestore.collection('parcels').doc(parcelId).snapshots().map(
      (doc) => doc.exists ? ParcelModel.fromFirestore(doc) : null,
    );
  }

  /// Stream d'un trajet spécifique
  Stream<TripModel?> getTripStream(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map(
      (doc) => doc.exists ? TripModel.fromFirestore(doc) : null,
    );
  }

  // ==================== MÉTHODES DE DIAGNOSTIQUE ====================

  /// ✅ BONUS: Méthode de test pour valider la configuration geoflutterfire_plus
  Future<Map<String, dynamic>> testGeoConfiguration() async {
    try {
      final testCenter = GeoFirePoint(GeoPoint(45.5017, -73.5673)); // Montréal
      
      // Test simple de connectivité géospatiale
      final testResults = await _parcelsGeoCollection.fetchWithin(
        center: testCenter,
        radiusInKm: 1.0,
        field: 'origin',
        geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
        strictMode: true,
      );
      
      return {
        'status': 'success',
        'geoflutterfire_version': '0.0.33',
        'test_location': {'lat': 45.5017, 'lng': -73.5673},
        'results_count': testResults.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';

/// Service Firebase optimisé pour VIAAMIGO avec geoflutterfire_plus 0.0.33
/// Implémente toutes les recommendations de Grok pour une performance maximale
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections géolocalisées centralisées - Excellente pratique selon Grok
  final GeoCollectionReference<Map<String, dynamic>> _parcelsGeoCollection;
  final GeoCollectionReference<Map<String, dynamic>> _tripsGeoCollection;

  FirebaseService()
      : _parcelsGeoCollection = GeoCollectionReference<Map<String, dynamic>>(
          FirebaseFirestore.instance.collection('parcels'),
        ),
        _tripsGeoCollection = GeoCollectionReference<Map<String, dynamic>>(
          FirebaseFirestore.instance.collection('trips'),
        );

  // ==================== MÉTHODES UTILITAIRES OPTIMISÉES ====================

  /// ✅ OPTIMISATION GROK #1: Factorisation des filtres pour éviter la duplication
  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query, 
    Map<String, bool>? filters
  ) {
    if (filters != null) {
      if (filters['urgent'] == true) {
        query = query.where('delivery_speed', isEqualTo: 'express');
      }
      if (filters['instant_booking'] == true) {
        query = query.where('paymentMethod', isEqualTo: 'pay_now');
      }
    }
    return query;
  }

  /// ✅ OPTIMISATION GROK #2: Gestion sécurisée du geopointFrom avec validation
  GeoPoint _extractGeoPoint(Map<String, dynamic> data, String field) {
    if (data[field] == null) {
      throw Exception('Champ "$field" manquant ou mal formaté');
    }
    
    final fieldData = data[field];
    
    // ✅ Support flexible: GeoPoint direct OU Map avec {geopoint, geohash}
    if (fieldData is GeoPoint) {
      return fieldData; // Cas de vos modèles actuels
    } else if (fieldData is Map<String, dynamic>) {
      // Cas documentation officielle {geopoint: GeoPoint, geohash: String}
      if (fieldData.containsKey('geopoint')) {
        return fieldData['geopoint'] as GeoPoint;
      }
    }
    
    throw Exception('Structure du champ "$field" invalide. Attendu: GeoPoint ou {geopoint: GeoPoint}');
  }

  /// ✅ OPTIMISATION GROK #3: Validation et filtrage centralisé des colis
  bool _isValidParcel(Map<String, dynamic>? data, String? query, Map<String, bool>? filters) {
    if (data == null || 
        data['status'] != 'pending' || 
        data['geoIndexReady'] != true) {
      return false;
    }
    
    // Filtre textuel
    if (query != null && query.isNotEmpty) {
      final originAddress = data['originAddress'] as String? ?? '';
      if (!originAddress.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
    }
    
    // Filtres rapides
    if (filters != null) {
      if (filters['urgent'] == true && data['delivery_speed'] != 'express') {
        return false;
      }
      if (filters['instant_booking'] == true && data['paymentMethod'] != 'pay_now') {
        return false;
      }
    }
    
    return true;
  }

  /// ✅ OPTIMISATION GROK #4: Validation centralisée des trajets
  bool _isValidTrip(Map<String, dynamic>? data) {
    return data != null && data['status'] == 'available';
  }
  
// === MÉTHODES CORRIGÉES POUR LA RECHERCHE DE SEGMENTS ===

/// Trouve l'index d'une location dans la route complète
/*int? _findLocationIndex(List<Map<String, dynamic>> fullRoute, String locationName) {
  for (int i = 0; i < fullRoute.length; i++) {
    final location = fullRoute[i];
    String? locationAddress;
    
    // Gérer les différents formats (origin/destination vs waypoints)
    if (location.containsKey('address')) {
      // C'est un waypoint
      locationAddress = location['address']?.toString();
    } else if (location.containsKey('originAddress')) {
      // C'est l'origine
      locationAddress = location['originAddress']?.toString();
    } else if (location.containsKey('destinationAddress')) {
      // C'est la destination  
      locationAddress = location['destinationAddress']?.toString();
    }
    
    if (locationAddress?.toLowerCase() == locationName.toLowerCase()) {
      return i;
    }
  }
  return null;
}
*/

  // ==================== RECHERCHE DE COLIS OPTIMISÉE ====================

  /// Recherche de colis avec filtres (fetch unique) - VERSION OPTIMISÉE
  Future<List<ParcelModel>> searchParcels({
    String? query,
    GeoPoint? nearLocation,
    double radiusKm = 50.0,
    Map<String, bool>? filters,
    int? limit = 50, // ✅ OPTIMISATION PERFORMANCE: Limite par défaut
  }) async {
    try {
      // Recherche géographique optimisée
      if (nearLocation != null) {
        final center = GeoFirePoint(nearLocation);
        
        final geoResults = await _parcelsGeoCollection.fetchWithin(
          center: center,
          radiusInKm: radiusKm,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: true,
        );

        // ✅ OPTIMISATION: Filtrage et conversion en une seule passe
        final results = geoResults
            .where((doc) => _isValidParcel(doc.data(), query, filters))
            .take(limit ?? 50) // Limite de performance
            .map((doc) => ParcelModel.fromFirestore(doc))
            .toList();
            
        return results;
      }

      // Recherche classique optimisée avec filtres factorisés
      Query<Map<String, dynamic>> parcelQuery = _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'pending')
          .where('geoIndexReady', isEqualTo: true);

      // Filtre textuel
      if (query != null && query.isNotEmpty) {
        parcelQuery = parcelQuery
            .where('originAddress', isGreaterThanOrEqualTo: query)
            .where('originAddress', isLessThanOrEqualTo: '$query\uf8ff');
      }

      // ✅ OPTIMISATION GROK: Utilisation de la méthode factorisée
      parcelQuery = _applyFilters(parcelQuery, filters);
      
      // Limite de performance
      if (limit != null) {
        parcelQuery = parcelQuery.limit(limit);
      }

      final querySnapshot = await parcelQuery.get();
      return querySnapshot.docs.map((doc) => ParcelModel.fromFirestore(doc)).toList();

    } catch (e) {
      throw Exception('Erreur lors de la recherche des colis: $e');
    }
  }

  /// Recherche de colis en temps réel (stream) - VERSION OPTIMISÉE
  Stream<List<ParcelModel>> searchParcelsStream({
    String? query,
    GeoPoint? nearLocation,
    double radiusKm = 50.0,
    Map<String, bool>? filters,
    int? limit = 50,
  }) {
    try {
      if (nearLocation != null) {
        final center = GeoFirePoint(nearLocation);
        
        return _parcelsGeoCollection.subscribeWithin(
          center: center,
          radiusInKm: radiusKm,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: true,
        ).map((docs) {
          return docs
              .where((doc) => _isValidParcel(doc.data(), query, filters))
              .take(limit ?? 50)
              .map((doc) => ParcelModel.fromFirestore(doc))
              .toList();
        });
      }

      // Stream classique avec filtres optimisés
      Query<Map<String, dynamic>> parcelQuery = _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'pending')
          .where('geoIndexReady', isEqualTo: true);

      if (query != null && query.isNotEmpty) {
        parcelQuery = parcelQuery
            .where('originAddress', isGreaterThanOrEqualTo: query)
            .where('originAddress', isLessThanOrEqualTo: '$query\uf8ff');
      }

      parcelQuery = _applyFilters(parcelQuery, filters);
      
      if (limit != null) {
        parcelQuery = parcelQuery.limit(limit);
      }

      return parcelQuery.snapshots().map((snapshot) => 
          snapshot.docs.map((doc) => ParcelModel.fromFirestore(doc)).toList());
          
    } catch (e) {
      throw Exception('Erreur lors du stream de recherche des colis: $e');
    }
  }

  // ==================== RECHERCHE DE TRAJETS OPTIMISÉE ====================

  /// Recherche intelligente de trajets (fetch unique) - VERSION ULTRA-OPTIMISÉE
  /// Recherche intelligente de trajets (fetch unique) - VERSION ULTRA-OPTIMISÉE
Future<List<TripModel>> searchTrips({
  required String fromLocation,
  required String toLocation,
  bool includeIntermediateStops = true,
  bool allowDetours = false,
  double maxDetourDistance = 50.0,
  int maxDetourTime = 100, // en minutes
  GeoPoint? centerForDetours,
  int? limit = 100, // ✅ OPTIMISATION PERFORMANCE
}) async {
  try {
    final allTrips = <TripModel>[];
    final processedIds = <String>{}; // ✅ GROK: Excellente pratique anti-doublons

    // 1. Trajets directs
    Query<Map<String, dynamic>> directQuery = _firestore
        .collection('trips')
        .where('status', isEqualTo: 'available')
        .where('originAddress', isEqualTo: fromLocation)
        .where('destinationAddress', isEqualTo: toLocation);
    
    if (limit != null) directQuery = directQuery.limit(limit ~/ 3);
    
    final directSnapshot = await directQuery.get();
    
    // ✅ OPTIMISATION GROK: Filtrage et ajout optimisés
    allTrips.addAll(
      directSnapshot.docs
          .where((doc) => processedIds.add(doc.id))
          .map((doc) => TripModel.fromFirestore(doc))
    );

    // 2. ✅ CORRIGÉ : Trajets avec segments d'itinéraire
    if (includeIntermediateStops) {
      // Chercher le segment formaté "fromLocation→toLocation"
      final segmentToFind = '$fromLocation→$toLocation';
      
      Query<Map<String, dynamic>> segmentQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'available')
          .where('routeSegments', arrayContains: segmentToFind);
          
      if (limit != null) segmentQuery = segmentQuery.limit(limit ~/ 3);
      
      final segmentSnapshot = await segmentQuery.get();
      
      allTrips.addAll(
        segmentSnapshot.docs
            .where((doc) => processedIds.add(doc.id))
            .map((doc) => TripModel.fromFirestore(doc))
      );
    }

    // 3. Trajets avec détours géolocalisés
    if (allowDetours && centerForDetours != null) {
      final center = GeoFirePoint(centerForDetours);
      
      final geoResults = await _tripsGeoCollection.fetchWithin(
        center: center,
        radiusInKm: maxDetourDistance,
        field: 'origin',
        geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
        strictMode: false, // Moins strict pour les détours
      );

      // ✅ OPTIMISATION: Pipeline de traitement efficace
      allTrips.addAll(
        geoResults
            .where((doc) => processedIds.add(doc.id))
            .where((doc) => _isValidTrip(doc.data()))
            .map((doc) => TripModel.fromFirestore(doc))
            .where((trip) => trip.allowDetours)
            .take(limit != null ? limit ~/ 3 : 50)
      );
    }

    // ✅ GROK: Tri pour cohérence des résultats
    allTrips.sort((a, b) => (a.tripId ?? '').compareTo(b.tripId ?? ''));
    
    // Limite finale si spécifiée
    return limit != null ? allTrips.take(limit).toList() : allTrips;
    
  } catch (e) {
    throw Exception('Erreur lors de la recherche des trajets: $e');
  }
}
  /*Future<List<TripModel>> searchTrips({
    required String fromLocation,
    required String toLocation,
    bool includeIntermediateStops = true,
    bool allowDetours = false,
    double maxDetourDistance = 50.0,
    int maxDetourTime = 100, // en minutes
    GeoPoint? centerForDetours,
    int? limit = 100, // ✅ OPTIMISATION PERFORMANCE
  }) async {
    try {
      final allTrips = <TripModel>[];
      final processedIds = <String>{}; // ✅ GROK: Excellente pratique anti-doublons

      // 1. Trajets directs
      Query<Map<String, dynamic>> directQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'available')
          .where('originAddress', isEqualTo: fromLocation)
          .where('destinationAddress', isEqualTo: toLocation);
      
      if (limit != null) directQuery = directQuery.limit(limit ~/ 3);
      
      final directSnapshot = await directQuery.get();
      
      // ✅ OPTIMISATION GROK: Filtrage et ajout optimisés
      allTrips.addAll(
        directSnapshot.docs
            .where((doc) => processedIds.add(doc.id))
            .map((doc) => TripModel.fromFirestore(doc))
      );

      // 2. Trajets avec points de passage
      if (includeIntermediateStops) {
        Query<Map<String, dynamic>> intermediateQuery = _firestore
            .collection('trips')
            .where('status', isEqualTo: 'available')
            .where('waypoints', arrayContainsAny: [fromLocation, toLocation]);
            
        if (limit != null) intermediateQuery = intermediateQuery.limit(limit ~/ 3);
        
        final intermediateSnapshot = await intermediateQuery.get();
        
        allTrips.addAll(
          intermediateSnapshot.docs
              .where((doc) => processedIds.add(doc.id))
              .map((doc) => TripModel.fromFirestore(doc))
        );
      }

      // 3. Trajets avec détours géolocalisés
      if (allowDetours && centerForDetours != null) {
        final center = GeoFirePoint(centerForDetours);
        
        final geoResults = await _tripsGeoCollection.fetchWithin(
          center: center,
          radiusInKm: maxDetourDistance,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: false, // Moins strict pour les détours
        );

        // ✅ OPTIMISATION: Pipeline de traitement efficace
        allTrips.addAll(
          geoResults
              .where((doc) => processedIds.add(doc.id))
              .where((doc) => _isValidTrip(doc.data()))
              .map((doc) => TripModel.fromFirestore(doc))
              .where((trip) => trip.allowDetours)
              .take(limit != null ? limit ~/ 3 : 50)
        );
      }

      // ✅ GROK: Tri pour cohérence des résultats
      allTrips.sort((a, b) => (a.tripId ?? '').compareTo(b.tripId ?? ''));
      
      // Limite finale si spécifiée
      return limit != null ? allTrips.take(limit).toList() : allTrips;
      
    } catch (e) {
      throw Exception('Erreur lors de la recherche des trajets: $e');
    }
  }*/

  /// Recherche de trajets en temps réel (stream) - VERSION OPTIMISÉE
  Stream<List<TripModel>> searchTripsStream({
    required String fromLocation,
    required String toLocation,
    GeoPoint? centerForDetours,
    double maxDetourDistance = 50.0,
    int? limit = 50,
  }) {
    try {
      if (centerForDetours != null) {
        final center = GeoFirePoint(centerForDetours);
        
        return _tripsGeoCollection.subscribeWithin(
          center: center,
          radiusInKm: maxDetourDistance,
          field: 'origin',
          geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
          strictMode: false,
        ).map((docs) {
          return docs
              .where((doc) => _isValidTrip(doc.data()))
              .map((doc) => TripModel.fromFirestore(doc))
              .where((trip) => trip.allowDetours)
              .take(limit ?? 50)
              .toList();
        });
      }

      // Stream classique optimisé
      Query<Map<String, dynamic>> tripQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'available')
          .where('originAddress', isEqualTo: fromLocation)
          .where('destinationAddress', isEqualTo: toLocation);
          
      if (limit != null) {
        tripQuery = tripQuery.limit(limit);
      }

      return tripQuery.snapshots().map((snapshot) => 
          snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
          
    } catch (e) {
      throw Exception('Erreur lors du stream de recherche des trajets: $e');
    }
  }

  // ==================== OPERATIONS CRUD OPTIMISÉES ====================

  /// Réserver un trajet - ✅ GROK: Ajout de updatedAt
  Future<void> bookTrip(String tripId, String userId, {String? parcelId}) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'booked',
        'bookedBy': userId,
        if (parcelId != null) 'matchId': parcelId,
        'updatedAt': FieldValue.serverTimestamp(), // ✅ GROK: Suivi des modifications
      });
    } catch (e) {
      throw Exception('Erreur lors de la réservation du trajet: $e');
    }
  }

  /// Annuler une réservation - ✅ GROK: Ajout de updatedAt
  Future<void> cancelBooking(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'available',
        'bookedBy': FieldValue.delete(),
        'matchId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(), // ✅ GROK: Suivi des modifications
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }

  // ==================== MATCHING OPTIMISÉ ====================

  /// Matching colis-trajet - ✅ GROK: Gestion sécurisée des GeoPoint null
  Future<List<TripModel>> matchTripsForParcel(ParcelModel parcel) async {
    // ✅ OPTIMISATION GROK: Gestion null-safe avec opérateur ??
    GeoPoint? originGeoPoint = parcel.origin != null
        ? GeoPoint(parcel.origin!.latitude, parcel.origin!.longitude)
        : null;

    final trips = await searchTrips(
      fromLocation: parcel.originAddress,
      toLocation: parcel.destinationAddress,
      includeIntermediateStops: true,
      allowDetours: true,
      centerForDetours: originGeoPoint,
      limit: 20, // ✅ Limite raisonnable pour le matching
    );
    
    return trips.where((trip) => trip.canAcceptParcel(parcel)).toList();
  }

  /// Matching en temps réel - ✅ GROK: Gestion sécurisée
  Stream<List<TripModel>> matchTripsForParcelStream(ParcelModel parcel) {
    GeoPoint? originGeoPoint = parcel.origin != null
        ? GeoPoint(parcel.origin!.latitude, parcel.origin!.longitude)
        : null;

    return searchTripsStream(
      fromLocation: parcel.originAddress,
      toLocation: parcel.destinationAddress,
      centerForDetours: originGeoPoint,
      limit: 20,
    ).map((trips) => trips.where((trip) => trip.canAcceptParcel(parcel)).toList());
  }

  // ==================== ACCESSEURS INDIVIDUELS ====================

  /// Obtenir un colis par ID avec gestion d'erreur
  Future<ParcelModel?> getParcelById(String parcelId) async {
    try {
      final doc = await _firestore.collection('parcels').doc(parcelId).get();
      return doc.exists ? ParcelModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du colis: $e');
    }
  }

  /// Obtenir un trajet par ID avec gestion d'erreur
  Future<TripModel?> getTripById(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      return doc.exists ? TripModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du trajet: $e');
    }
  }

  /// Stream d'un colis spécifique
  Stream<ParcelModel?> getParcelStream(String parcelId) {
    return _firestore.collection('parcels').doc(parcelId).snapshots().map(
      (doc) => doc.exists ? ParcelModel.fromFirestore(doc) : null,
    );
  }

  /// Stream d'un trajet spécifique
  Stream<TripModel?> getTripStream(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map(
      (doc) => doc.exists ? TripModel.fromFirestore(doc) : null,
    );
  }

  // ==================== MÉTHODES DE DIAGNOSTIQUE ====================

  /// ✅ BONUS: Méthode de test pour valider la configuration geoflutterfire_plus
  Future<Map<String, dynamic>> testGeoConfiguration() async {
    try {
      final testCenter = GeoFirePoint(GeoPoint(45.5017, -73.5673)); // Montréal
      
      // Test simple de connectivité géospatiale
      final testResults = await _parcelsGeoCollection.fetchWithin(
        center: testCenter,
        radiusInKm: 1.0,
        field: 'origin',
        geopointFrom: (data) => _extractGeoPoint(data, 'origin'),
        strictMode: true,
      );
      
      return {
        'status': 'success',
        'geoflutterfire_version': '0.0.33',
        'test_location': {'lat': 45.5017, 'lng': -73.5673},
        'results_count': testResults.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}