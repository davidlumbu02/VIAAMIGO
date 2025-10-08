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
  Future<List<TripModel>> searchTrips({
    required String fromLocation,
    required String toLocation,
    bool includeIntermediateStops = true,
    bool allowDetours = false,
    double maxDetourDistance = 50.0,
    int maxDetourTime = 30,
    GeoPoint? centerForDetours,
    int? limit = 50, // ✅ OPTIMISATION PERFORMANCE
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