// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant les habitudes de déplacement d'un utilisateur
class TravelPattern {
  final String id; // ID unique du motif de déplacement
  final GeoPoint fromLocation; // Point de départ habituel
  final GeoPoint toLocation; // Point d'arrivée habituel
  final String fromAddress; // Adresse formatée de départ
  final String toAddress; // Adresse formatée d'arrivée
  final String frequency; // Fréquence (daily, weekly, monthly, occasional)
  final String? usualDay; // Jour habituel
  final String? usualTime; // Heure habituelle
  final double confidence; // Indice de confiance (0-1)
  final DateTime? lastTripDate; // Date du dernier trajet
  final bool detectedAutomatically; // Si détecté automatiquement par l'IA
  final int tripsCount; // Nombre de trajets effectués sur ce motif

  /// Constructeur principal
  const TravelPattern({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.fromAddress,
    required this.toAddress,
    required this.frequency,
    this.usualDay,
    this.usualTime,
    this.confidence = 0.0,
    this.lastTripDate,
    this.detectedAutomatically = true,
    this.tripsCount = 0,
  });

  /// Factory pour créer un nouveau pattern sans ID
  /// Utile pour la création de nouveaux patterns
  factory TravelPattern.withoutId({
    required GeoPoint fromLocation,
    required GeoPoint toLocation,
    required String fromAddress,
    required String toAddress,
    required String frequency,
    String? usualDay,
    String? usualTime,
    double confidence = 0.0,
    DateTime? lastTripDate,
    bool detectedAutomatically = true,
    int tripsCount = 0,
  }) {
    return TravelPattern(
      id: '', // ID vide pour nouvelle création
      fromLocation: fromLocation,
      toLocation: toLocation,
      fromAddress: fromAddress,
      toAddress: toAddress,
      frequency: frequency,
      usualDay: usualDay,
      usualTime: usualTime,
      confidence: confidence,
      lastTripDate: lastTripDate,
      detectedAutomatically: detectedAutomatically,
      tripsCount: tripsCount,
    );
  }

  /// Crée une instance à partir d'un document Firestore
  factory TravelPattern.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TravelPattern(
      id: doc.id,
      fromLocation: data['from_location'] ?? const GeoPoint(0, 0),
      toLocation: data['to_location'] ?? const GeoPoint(0, 0),
      fromAddress: data['from_address'] ?? '',
      toAddress: data['to_address'] ?? '',
      frequency: data['frequency'] ?? 'occasional',
      usualDay: data['usual_day'],
      usualTime: data['usual_time'],
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      lastTripDate: data['last_trip_date'] != null 
          ? (data['last_trip_date'] as Timestamp).toDate() 
          : null,
      detectedAutomatically: data['detected_automatically'] ?? true,
      tripsCount: data['trips_count'] ?? 0,
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'from_location': fromLocation,
      'to_location': toLocation,
      'from_address': fromAddress,
      'to_address': toAddress,
      'frequency': frequency,
      'usual_day': usualDay,
      'usual_time': usualTime,
      'confidence': confidence,
      'last_trip_date': lastTripDate != null ? Timestamp.fromDate(lastTripDate!) : null,
      'detected_automatically': detectedAutomatically,
      'trips_count': tripsCount,
    };
  }

  /// Crée une copie modifiée de cette instance
  TravelPattern copyWith({
    String? id,  // Ajout de l'ID pour permettre de le modifier si nécessaire
    GeoPoint? fromLocation,
    GeoPoint? toLocation,
    String? fromAddress,
    String? toAddress,
    String? frequency,
    String? usualDay,
    String? usualTime,
    double? confidence,
    DateTime? lastTripDate,
    bool? detectedAutomatically,
    int? tripsCount,
  }) {
    return TravelPattern(
      id: id ?? this.id,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      frequency: frequency ?? this.frequency,
      usualDay: usualDay ?? this.usualDay,
      usualTime: usualTime ?? this.usualTime,
      confidence: confidence ?? this.confidence,
      lastTripDate: lastTripDate ?? this.lastTripDate,
      detectedAutomatically: detectedAutomatically ?? this.detectedAutomatically,
      tripsCount: tripsCount ?? this.tripsCount,
    );
  }

  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_location': {
        'latitude': fromLocation.latitude,
        'longitude': fromLocation.longitude,
      },
      'to_location': {
        'latitude': toLocation.latitude,
        'longitude': toLocation.longitude,
      },
      'from_address': fromAddress,
      'to_address': toAddress,
      'frequency': frequency,
      'usual_day': usualDay,
      'usual_time': usualTime,
      'confidence': confidence,
      'last_trip_date': lastTripDate?.toIso8601String(),
      'detected_automatically': detectedAutomatically,
      'trips_count': tripsCount,
    };
  }
  
  /// Crée une instance à partir de JSON
  factory TravelPattern.fromJson(Map<String, dynamic> json) {
    return TravelPattern(
      id: json['id'],
      fromLocation: GeoPoint(
        json['from_location']?['latitude'] ?? 0.0,
        json['from_location']?['longitude'] ?? 0.0,
      ),
      toLocation: GeoPoint(
        json['to_location']?['latitude'] ?? 0.0,
        json['to_location']?['longitude'] ?? 0.0,
      ),
      fromAddress: json['from_address'] ?? '',
      toAddress: json['to_address'] ?? '',
      frequency: json['frequency'] ?? 'occasional',
      usualDay: json['usual_day'],
      usualTime: json['usual_time'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      lastTripDate: json['last_trip_date'] != null 
          ? DateTime.parse(json['last_trip_date'])
          : null,
      detectedAutomatically: json['detected_automatically'] ?? true,
      tripsCount: json['trips_count'] ?? 0,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TravelPattern && 
           other.id == id && 
           other.fromLocation.latitude == fromLocation.latitude &&
           other.fromLocation.longitude == fromLocation.longitude &&
           other.toLocation.latitude == toLocation.latitude &&
           other.toLocation.longitude == toLocation.longitude;
  }
  
  @override
  int get hashCode => 
      id.hashCode ^ 
      fromLocation.latitude.hashCode ^ 
      fromLocation.longitude.hashCode ^
      toLocation.latitude.hashCode ^
      toLocation.longitude.hashCode;
}

/// Service pour gérer les habitudes de déplacement des utilisateurs
class TravelPatternsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère toutes les habitudes de déplacement d'un utilisateur
  Future<List<TravelPattern>> getUserTravelPatterns(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .get();
          
      return querySnapshot.docs
          .map((doc) => TravelPattern.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching travel patterns: $e');
      return [];
    }
  }
  
  /// Récupère toutes les habitudes de déplacement d'un utilisateur comme Stream
  Stream<List<TravelPattern>> getUserTravelPatternsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('travel_patterns')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => TravelPattern.fromFirestore(doc)).toList())
        .handleError((error) {
          print('Error in travel patterns stream: $error');
          return <TravelPattern>[];
        });
  }
  
  /// Trouve des habitudes de déplacement similaires
  Future<TravelPattern?> findSimilarPattern(
    String userId, 
    GeoPoint fromLocation, 
    GeoPoint toLocation,
    double proximityThresholdKm,
  ) async {
    try {
      // Conversion de km à degrés (approximation)
      final double proximityThresholdDegree = proximityThresholdKm / 111.0;
      
      // Récupérer tous les patterns et filtrer côté client
      // (Firestore ne permet pas de requêtes géospatiales complexes)
      final patterns = await getUserTravelPatterns(userId);
      
      // Chercher un pattern similaire
      for (final pattern in patterns) {
        final bool isFromNearby = _isLocationNearby(
          pattern.fromLocation, 
          fromLocation,
          proximityThresholdDegree
        );
        
        final bool isToNearby = _isLocationNearby(
          pattern.toLocation,
          toLocation,
          proximityThresholdDegree
        );
        
        if (isFromNearby && isToNearby) {
          return pattern;
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding similar pattern: $e');
      return null;
    }
  }
  
  /// Vérifie si deux localisations sont à proximité
  bool _isLocationNearby(GeoPoint loc1, GeoPoint loc2, double thresholdDegree) {
    final double latDiff = (loc1.latitude - loc2.latitude).abs();
    final double lngDiff = (loc1.longitude - loc2.longitude).abs();
    return latDiff < thresholdDegree && lngDiff < thresholdDegree;
  }
  
  /// Ajoute une nouvelle habitude de déplacement
  Future<String> addTravelPattern(String userId, TravelPattern pattern) async {
    try {
      // Vérifier s'il existe déjà un pattern similaire
      final existingPattern = await findSimilarPattern(
        userId,
        pattern.fromLocation,
        pattern.toLocation,
        2.0, // 2 km de proximité
      );
      
      if (existingPattern != null) {
        // Mettre à jour le pattern existant
        final updatedPattern = existingPattern.copyWith(
          lastTripDate: DateTime.now(),
          tripsCount: existingPattern.tripsCount + 1,
          confidence: (existingPattern.confidence + 0.1).clamp(0.0, 1.0),
        );
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('travel_patterns')
            .doc(existingPattern.id)
            .update(updatedPattern.toFirestore());
            
        return existingPattern.id;
      } else {
        // Créer un nouveau pattern
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('travel_patterns')
            .add(pattern.toFirestore());
            
        return docRef.id;
      }
    } catch (e) {
      print('Error adding travel pattern: $e');
      rethrow;
    }
  }
  
  /// Met à jour une habitude de déplacement
  Future<void> updateTravelPattern(String userId, TravelPattern pattern) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .doc(pattern.id)
          .update(pattern.toFirestore());
    } catch (e) {
      print('Error updating travel pattern: $e');
      rethrow;
    }
  }
  
  /// Supprime une habitude de déplacement
  Future<void> deleteTravelPattern(String userId, String patternId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .doc(patternId)
          .delete();
    } catch (e) {
      print('Error deleting travel pattern: $e');
      rethrow;
    }
  }
  
  /// Incrémente le compteur de trajets pour un pattern donné
  Future<void> incrementTripCount(String userId, String patternId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .doc(patternId);
          
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        
        final currentCount = snapshot.data()?['trips_count'] ?? 0;
        transaction.update(docRef, {
          'trips_count': currentCount + 1,
          'last_trip_date': Timestamp.now(),
        });
      });
    } catch (e) {
      print('Error incrementing trip count: $e');
      rethrow;
    }
  }
  /// Crée un document de TravelPattern vide avec un ID auto-généré
/// Utilisé pour initialiser un compte avec un motif de déplacement par défaut
Future<void> createEmptyTravelPatternDoc(String userId) async {
  try {
    // 🔹 Crée une référence à un document avec un ID automatique (évite les conflits)
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('travel_patterns')
        .doc(); // ✅ Firestore génère un ID unique

    // 🔹 Construction d'un pattern vide avec valeurs par défaut
    final placeholder = TravelPattern(
      id: docRef.id, // 🆔 Injecter l’ID auto-généré dans l’objet
      fromLocation: const GeoPoint(0.0, 0.0), // 📍 Point vide
      toLocation: const GeoPoint(0.0, 0.0),
      fromAddress: '',
      toAddress: '',
      frequency: 'occasional', // 📆 Fréquence par défaut
      usualDay: null, // 📅 Jour et heure non définis
      usualTime: null,
      confidence: 0.0, // 🔢 Confiance minimale
      lastTripDate: null,
      detectedAutomatically: false, // 👁️ Non détecté automatiquement
      tripsCount: 0, // 📊 Aucun trajet encore
    );

    // 🔹 Enregistrer dans Firestore avec un ID unique (pas "placeholder")
    await docRef.set(placeholder.toFirestore());
  } catch (e) {
    print('Error creating empty travel pattern: $e');
    rethrow;
  }
}

  
  // Initialisation doc vide pour MVP
 /* Future<void> createEmptyTravelPatternDoc(String userId) async {
    try {
      final placeholder = TravelPattern(
        id: 'placeholder',
        fromLocation: const GeoPoint(0.0, 0.0),
        toLocation: const GeoPoint(0.0, 0.0),
        fromAddress: '',
        toAddress: '',
        frequency: 'occasional',
        usualDay: null,
        usualTime: null,
        confidence: 0.0,
        lastTripDate: null,
        detectedAutomatically: false,
        tripsCount: 0,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .doc('placeholder')
          .set(placeholder.toFirestore());
    } catch (e) {
      print('Error creating empty travel pattern: $e');
      rethrow;
    }
  }*/
  
  Future<void> deleteAllTravelPatterns(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .get();

      // Si aucun document, ne rien faire
      if (snapshot.docs.isEmpty) return;
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all travel patterns: $e');
      rethrow;
    }
  }
  
  /// Vérifie si des patterns de voyage existent pour un utilisateur
  Future<bool> hasTravelPatterns(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('travel_patterns')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if travel patterns exist: $e');
      return false;
    }
  }
}
