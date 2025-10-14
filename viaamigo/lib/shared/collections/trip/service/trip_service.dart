import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:viaamigo/shared/collections/trip/model/trip_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeoCollectionReference<Map<String, dynamic>> _tripsGeoCollection;

  TripService() :_tripsGeoCollection = GeoCollectionReference<Map<String, dynamic>>(
          FirebaseFirestore.instance.collection('trips'),
        );

  
  // Collection reference
  CollectionReference get _tripsCollection => _firestore.collection('trips');
  
  /// Crée un trip vide (brouillon)
  Future<String> createEmptyTrip(TripModel trip) async {
    try {
      final currentUser = _auth.currentUser;
      
      print('🔐 === DEBUG AUTHENTIFICATION TRIP ===');
      print('🔐 Current user: ${currentUser?.uid}');
      print('🔐 User email: ${currentUser?.email}');
      
      if (currentUser == null) {
        throw Exception('❌ ERREUR CRITIQUE: Utilisateur non authentifié !');
      }
      
      // Vérification et correction du driverId
      print('🔐 Trip driverId AVANT correction: ${trip.driverId}');
      
      if (trip.driverId == null || trip.driverId!.isEmpty) {
        print('🔄 Attribution automatique du driverId: ${currentUser.uid}');
        trip.driverId = currentUser.uid;
      } else if (trip.driverId != currentUser.uid) {
        print('⚠️ DriverId différent détecté !');
        print('   Current user: ${currentUser.uid}');
        print('   Trip driverId: ${trip.driverId}');
        print('🔄 Correction forcée du driverId');
        trip.driverId = currentUser.uid;
      }
      
      print('🔐 Trip driverId APRÈS correction: ${trip.driverId}');
      
      // Préparation des données pour Firestore
      final tripData = trip.toFirestore();
      
      print('📋 === DONNÉES TRIP ENVOYÉES À FIRESTORE ===');
      print('📋 Nombre de champs: ${tripData.length}');
      
      // Debug des champs critiques
      tripData.forEach((key, value) {
        if (key == 'driverId') {
          print('   ⭐ $key: $value (${value.runtimeType}) ← CRITIQUE');
        } else if (value is Timestamp) {
          print('   🕐 $key: $value (Timestamp)');
        } else if (value == null) {
          print('   ⚪ $key: null');
        } else {
          print('   📝 $key: ${value.toString().length > 50 ? "${value.toString().substring(0, 50)}..." : value} (${value.runtimeType})');
        }
      });
      
      // Tentative de création Firestore
      print('🚀 Tentative de création trip dans Firestore...');
      final docRef = await _tripsCollection.add(trip.toFirestore());
      print('✅ ✅ ✅ SUCCÈS ! Trip créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ ❌ ❌ ERREUR DÉTAILLÉE createEmptyTrip:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');
      
      if (e.toString().contains('permission-denied')) {
        print('🚨 ERREUR DE PERMISSIONS FIRESTORE !');
        print('   Vérifiez les règles Firestore pour la collection trips');
        print('   User ID: ${_auth.currentUser?.uid}');
        print('   DriverId dans trip: ${trip.driverId}');
      }
      throw Exception('Erreur lors de la création du trip: $e');
    }
  }
  
  /// Met à jour un trip
  Future<void> updateTrip(TripModel trip) async {
    try {
      trip.updatedAt = DateTime.now();
      
      // Génération du geohash si les coordonnées sont disponibles
      if (trip.origin != null && trip.g == null) {
        final geohash = GeoUtils.generateGeohash(
          trip.origin!.latitude, 
          trip.origin!.longitude
        );
        trip.g = geohash;
      }
      
      await _tripsCollection.doc(trip.tripId).update(trip.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du trip: $e');
    }
  }
  
  /// Publie un trip (le rend disponible pour matching)
  Future<void> publishTrip(TripModel trip) async {
    try {
      // Valider le trip avant publication
      if (!trip.validate()) {
        throw Exception('Le trip n\'est pas valide pour publication: ${trip.validationErrors.join(", ")}');
      }
      
      trip.status = 'available';
      trip.updatedAt = DateTime.now();
      
      // S'assurer que le geohash est généré pour le matching géospatial
      if (trip.origin != null && trip.g == null) {
        final geohash = GeoUtils.generateGeohash(
          trip.origin!.latitude, 
          trip.origin!.longitude
        );
        trip.g = geohash;
      }
      
      // Mettre à jour le trip
      await _tripsCollection.doc(trip.tripId).update(trip.toFirestore());
      
      // Ajouter un événement de création dans le tracking
      await addTripEvent(
        tripId: trip.tripId!, 
        status: 'created',
        location: GeoPoint(
          trip.origin?.latitude ?? 0, 
          trip.origin?.longitude ?? 0
        ),
        note: 'Trip créé et publié',
        confirmedBy: trip.driverId!,
        eventType: 'status_change',
        performedBy: 'driver',
        deviceInfo: {'platform': 'app'},
        sequence: 1
      );
    } catch (e) {
      throw Exception('Erreur lors de la publication du trip: $e');
    }
  }
  
  /// Supprime un trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripsCollection.doc(tripId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du trip: $e');
    }
  }
  

  
  /// Récupère tous les trips d'un conducteur
  Stream<List<TripModel>> getUserTrips(String userId, {String? status}) {
    Query query = _tripsCollection
        .where('driverId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    });
  }
  
  /// Récupère les trips récents d'un conducteur
  Future<List<TripModel>> getUserRecentTrips(String userId, {int limit = 5}) async {
    try {
      final querySnapshot = await _tripsCollection
          .where('driverId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des trips récents: $e');
    }
  }
  
  /// Récupère les trips disponibles d'un conducteur
  Stream<List<TripModel>> getUserAvailableTrips(String userId) {
    return _tripsCollection
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'available')
        .orderBy('departureTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc))
              .toList();
        });
  }
  
  /// Recherche des trips compatibles avec un colis
  Future<List<TripModel>> findCompatibleTrips(ParcelModel parcel) async {
    try {
      // Recherche géospatiale basique (à améliorer avec des requêtes plus complexes)
      final querySnapshot = await _tripsCollection
          .where('status', isEqualTo: 'available')
          .where('departureTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();
      
      List<TripModel> compatibleTrips = [];
      
      for (var doc in querySnapshot.docs) {
        final trip = TripModel.fromFirestore(doc);
        
        // Vérifier la compatibilité
        if (trip.canAcceptParcel(parcel)) {
          // Vérifier si les points sont sur la route (logique simplifiée)
          if (parcel.origin != null && parcel.destination != null) {
            if (trip.isOnRoute(parcel.origin!, parcel.destination!)) {
              compatibleTrips.add(trip);
            }
          }
        }
      }
      
      return compatibleTrips;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de trips compatibles: $e');
    }
  }
  
  /// Recherche des trips par zone géographique
  Stream<List<TripModel>> getTripsInRadius(GeoPoint center, double radiusKm) {
    // Pour une implémentation complète, utiliseriez GeoFlutterFire ou une solution similaire
    // Ici, implémentation basique
    return _tripsCollection
        .where('status', isEqualTo: 'available')
        .orderBy('departureTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc))
              .where((trip) {
                if (trip.origin == null) return false;
                
                // Calcul de distance simple (à améliorer)
                double distance = GeoUtils.calculateDistance(
                  GeoFirePoint(center),
                  trip.origin!
                );
                
                return distance <= radiusKm;
              })
              .toList();
        });
  }
  
  /// Géocodage d'adresse
  Future<GeocodingResult?> geocodeAddress(String address) async {
    try {
      return await GeocodingService.getCoordinatesFromAddress(address);
    } catch (e) {
      throw Exception('Erreur géocodage: $e');
    }
  }
  
  /// Ajoute un événement au suivi de trip
  Future<void> addTripEvent({
    required String tripId,
    required String status,
    required GeoPoint location,
    String? note,
    String? photoUrl,
    required String confirmedBy,
    required String eventType,
    required String performedBy,
    required Map<String, dynamic> deviceInfo,
    required int sequence,
  }) async {
    try {
      // Créer l'événement de suivi
      TripTrackingEvent event = TripTrackingEvent(
        status: status,
        location: location,
        timestamp: DateTime.now(),
        note: note,
        photoUrl: photoUrl,
        confirmedBy: confirmedBy,
        eventType: eventType,
        performedBy: performedBy,
        deviceInfo: deviceInfo,
        sequence: sequence,
      );
      
      // Ajouter à la sous-collection tracking
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('tracking')
          .add(event.toFirestore());
      
      // Mettre à jour le statut du trip si nécessaire
      if (['created', 'started', 'in_progress', 'completed'].contains(status)) {
        await _tripsCollection.doc(tripId).update({
          'status': status == 'created' ? 'available' :
                    status == 'started' ? 'in_progress' :
                    status == 'in_progress' ? 'in_progress' :
                    status == 'completed' ? 'completed' : 'available'
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout d\'un événement de suivi trip: $e');
    }
  }
  
  /// Obtient l'historique de suivi d'un trip
  Stream<List<TripTrackingEvent>> getTripTracking(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('tracking')
        .orderBy('sequence', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TripTrackingEvent.fromFirestore(doc)).toList();
        });
  }
  
  /// Met à jour la capacité disponible d'un trip
  Future<void> updateTripCapacity(String tripId, Map<String, dynamic> newCapacity) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'vehicleCapacity': newCapacity,
        'updatedAt': Timestamp.fromDate(DateTime.now())
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la capacité: $e');
    }
  }
  
  /// Annule un trip
  Future<void> cancelTrip(String tripId, String reason) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now())
      });
      
      // Ajouter un événement d'annulation
      await addTripEvent(
        tripId: tripId,
        status: 'cancelled',
        location: GeoPoint(0, 0), // Location par défaut
        note: 'Trip annulé: $reason',
        confirmedBy: _auth.currentUser?.uid ?? 'system',
        eventType: 'cancellation',
        performedBy: 'driver',
        deviceInfo: {'platform': 'app'},
        sequence: 999, // Séquence élevée pour l'annulation
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du trip: $e');
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
  
  /// Obtenir un trajet par ID avec gestion d'erreur
  Future<TripModel?> getTripById2(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      return doc.exists ? TripModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du trajet: $e');
    }
  }

  /// Récupère un trip par son ID
  Future<TripModel> getTripById(String tripId) async {
    try {
      final docSnap = await _tripsCollection.doc(tripId).get();
      
      if (docSnap.exists) {
        return TripModel.fromFirestore(docSnap);
      } else {
        throw Exception('Trip non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du trip: $e');
    }
  }  

   /// Stream d'un trajet spécifique
  Stream<TripModel?> getTripStream(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map(
      (doc) => doc.exists ? TripModel.fromFirestore(doc) : null,
    );
  }
    /// ✅ OPTIMISATION GROK #4: Validation centralisée des trajets
  bool _isValidTrip(Map<String, dynamic>? data) {
    return data != null && data['status'] == 'available';
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
  // ==================== RECHERCHE DE COLIS OPTIMISÉE ====================

  /// Recherche de colis avec filtres (fetch unique) - VERSION OPTIMISÉE
 

  

}

// Modèle pour les événements de suivi de trip
class TripTrackingEvent {
  final String status;
  final GeoPoint location;
  final DateTime timestamp;
  final String? note;
  final String? photoUrl;
  final String confirmedBy;
  final String eventType;
  final String performedBy;
  final Map<String, dynamic> deviceInfo;
  final int sequence;
  
  TripTrackingEvent({
    required this.status,
    required this.location,
    required this.timestamp,
    this.note,
    this.photoUrl,
    required this.confirmedBy,
    required this.eventType,
    required this.performedBy,
    required this.deviceInfo,
    required this.sequence,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'photoUrl': photoUrl,
      'confirmedBy': confirmedBy,
      'eventType': eventType,
      'performedBy': performedBy,
      'deviceInfo': deviceInfo,
      'sequence': sequence,
    };
  }
  
  static TripTrackingEvent fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TripTrackingEvent(
      status: data['status'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      note: data['note'],
      photoUrl: data['photoUrl'],
      confirmedBy: data['confirmedBy'] ?? '',
      eventType: data['eventType'] ?? '',
      performedBy: data['performedBy'] ?? '',
      deviceInfo: Map<String, dynamic>.from(data['deviceInfo'] ?? {}),
      sequence: data['sequence'] ?? 0,
    );
  }
}

// ✅ Classes utilitaires corrigées
class GeoUtils {
  /// Génère un geohash simple (implémentation basique)
  static String generateGeohash(double lat, double lng) {
    // Implémentation simplifiée - pour production, utilisez une vraie librairie
    final latStr = lat.toStringAsFixed(6).replaceAll('.', '').replaceAll('-', 'n');
    final lngStr = lng.toStringAsFixed(6).replaceAll('.', '').replaceAll('-', 'n');
    return '${latStr}_$lngStr';
  }
  
  /// Calcule la distance entre deux points (formule haversine)
  static double calculateDistance(GeoFirePoint point1, GeoFirePoint point2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Vérifie si un point est dans un rayon donné
  static bool isWithinRadius(GeoFirePoint center, GeoFirePoint point, double radiusKm) {
    return calculateDistance(center, point) <= radiusKm;
  }
}