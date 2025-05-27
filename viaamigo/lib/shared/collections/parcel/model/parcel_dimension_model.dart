import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';




/*
ParcelDimensions - Gère les dimensions et le volume des colis

TimeWindow - Gère les créneaux horaires de livraison

AiRecognitionResult - Stocke les résultats d'analyse IA des colis

TrackingEvent - Trace les événements de mouvement des colis

GeoUtils - Fournit des calculs géographiques

PriceCalculator - Gère les calculs de prix*/


class ParcelDimensions {
  final double length;  // cm
  final double width;   // cm
  final double height;  // cm
  
  ParcelDimensions({
    required this.length,
    required this.width,
    required this.height,
  });
  
  // Calcul du volume en cm³
  double get volume => length * width * height;
  
  // AMÉLIORATION: Méthode pour calculer si un objet peut contenir celui-ci
  bool fitsInto(ParcelDimensions container) {
    // Vérifier si l'objet peut tenir dans le conteneur, quelle que soit l'orientation
    // Algorithme simple pour vérifier les 6 orientations possibles
    return (length <= container.length && width <= container.width && height <= container.height) ||
           (length <= container.length && height <= container.width && width <= container.height) ||
           (width <= container.length && length <= container.width && height <= container.height) ||
           (width <= container.length && height <= container.width && length <= container.height) ||
           (height <= container.length && length <= container.width && width <= container.height) ||
           (height <= container.length && width <= container.width && length <= container.height);
  }
  
  factory ParcelDimensions.fromMap(Map<String, dynamic> map) {
    return ParcelDimensions(
      length: map['length']?.toDouble() ?? 0.0,
      width: map['width']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
  
  // AMÉLIORATION: Possibilité de créer des dimensions standard
  static ParcelDimensions small() {
    return ParcelDimensions(length: 20, width: 15, height: 10);
  }
  
  static ParcelDimensions medium() {
    return ParcelDimensions(length: 40, width: 30, height: 20);
  }
  
  static ParcelDimensions large() {
    return ParcelDimensions(length: 60, width: 50, height: 40);
  }
  
  // Déterminer la taille standard la plus proche
  String getSizeCategory() {
    final volume = this.volume;
    
    if (volume <= small().volume) {
      return 'small';
    } else if (volume <= medium().volume) {
      return 'medium';
    } else {
      return 'large';
    }
  }
  /// Crée une copie de l'objet avec certaines dimensions modifiées
ParcelDimensions copyWith({
  double? length,
  double? width,
  double? height,
}) {
  return ParcelDimensions(
    length: length ?? this.length,
    width: width ?? this.width,
    height: height ?? this.height,
  );
}

}



class TimeWindow {
  DateTime start_time;
  DateTime end_time;

  TimeWindow({
    required this.start_time,
    required this.end_time,
  });

  factory TimeWindow.fromMap(Map<String, dynamic> map) {
    return TimeWindow(
      start_time: (map['start_time'] as Timestamp).toDate(),
      end_time: (map['end_time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_time': Timestamp.fromDate(start_time),
      'end_time': Timestamp.fromDate(end_time),
    };
  }

  bool isValid() => start_time.isBefore(end_time);

  Duration get duration => end_time.difference(start_time);

  bool contains(DateTime time) =>
      (time.isAfter(start_time) || time.isAtSameMomentAs(start_time)) &&
      (time.isBefore(end_time) || time.isAtSameMomentAs(end_time));

  bool overlaps(TimeWindow other) =>
      (start_time.isBefore(other.end_time) || start_time.isAtSameMomentAs(other.end_time)) &&
      (end_time.isAfter(other.start_time) || end_time.isAtSameMomentAs(other.start_time));

  static TimeWindow fromStartAndDuration(DateTime startTime, Duration duration) {
    return TimeWindow(
      start_time: startTime,
      end_time: startTime.add(duration),
    );
  }

  String toDisplayString() {
    final startFormat = '${start_time.day}/${start_time.month} ${start_time.hour}:${start_time.minute.toString().padLeft(2, '0')}';
    final endFormat = '${end_time.hour}:${end_time.minute.toString().padLeft(2, '0')}';
    return '$startFormat - $endFormat';
  }

  // ✅ Ajout copyWith
  TimeWindow copyWith({
    DateTime? start_time,
    DateTime? end_time,
  }) {
    return TimeWindow(
      start_time: start_time ?? this.start_time,
      end_time: end_time ?? this.end_time,
    );
  }
}


class AiRecognitionResult {
  final String? detected_type; // Respect strict du nom de champ avec underscore
  final ParcelDimensions? suggested_dimensions; // Respect strict du nom de champ avec underscore
  final double? fragility_score; // Respect strict du nom de champ avec underscore
  final double? accuracy;
  
  AiRecognitionResult({
    this.detected_type,
    this.suggested_dimensions,
    this.fragility_score,
    this.accuracy,
  });
  
  factory AiRecognitionResult.fromMap(Map<String, dynamic> map) {
    return AiRecognitionResult(
      detected_type: map['detected_type'],
      suggested_dimensions: map['suggested_dimensions'] != null 
          ? ParcelDimensions.fromMap(map['suggested_dimensions']) 
          : null,
      fragility_score: map['fragility_score']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'detected_type': detected_type,
      'suggested_dimensions': suggested_dimensions?.toMap(),
      'fragility_score': fragility_score,
      'accuracy': accuracy,
    };
  }
  
  // AMÉLIORATION: Méthode pour suggérer la catégorie du colis
  String? suggestCategory() {
    if (detected_type == null) return null;
    
    final type = detected_type!.toLowerCase();
    
    if (type.contains('glass') || 
        type.contains('ceramic') || 
        type.contains('fragile') ||
        (fragility_score != null && fragility_score! > 0.7)) {
      return 'fragile';
    } else if (type.contains('food') || 
               type.contains('fruit') || 
               type.contains('vegetable') || 
               type.contains('perishable')) {
      return 'perishable';
    } else if (type.contains('electronics') || 
               type.contains('jewelry') || 
               type.contains('valuable')) {
      return 'valuable';
    }
    
    return 'normal';
  }
  
  // AMÉLIORATION: Méthode pour vérifier la fiabilité des résultats
  bool isReliable() {
    return accuracy != null && accuracy! > 0.8;
  }/// Crée une copie de l'analyse IA avec certains champs mis à jour
AiRecognitionResult copyWith({
  String? detected_type,
  ParcelDimensions? suggested_dimensions,
  double? fragility_score,
  double? accuracy,
}) {
  return AiRecognitionResult(
    detected_type: detected_type ?? this.detected_type,
    suggested_dimensions: suggested_dimensions ?? this.suggested_dimensions,
    fragility_score: fragility_score ?? this.fragility_score,
    accuracy: accuracy ?? this.accuracy,
  );
}



}

class TrackingEvent {
  String? id;
  String status;
  GeoPoint location;
  DateTime timestamp;
  String? note;
  String? photoUrl;
  String confirmedBy;
  String event_type;
  String performed_by;
  Map<String, dynamic> device_info;
  int sequence; // AMÉLIORATION: Séquence pour l'ordre des événements
  
  TrackingEvent({
    this.id,
    required this.status,
    required this.location,
    required this.timestamp,
    this.note,
    this.photoUrl,
    required this.confirmedBy,
    required this.event_type,
    required this.performed_by,
    required this.device_info,
    required this.sequence,
  });
  
  factory TrackingEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return TrackingEvent(
      id: doc.id,
      status: data['status'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
      photoUrl: data['photoUrl'],
      confirmedBy: data['confirmedBy'] ?? '',
      event_type: data['event_type'] ?? '',
      performed_by: data['performed_by'] ?? '',
      device_info: data['device_info'] ?? {},
      sequence: data['sequence'] ?? 0, // AMÉLIORATION: Support de la séquence
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'photoUrl': photoUrl,
      'confirmedBy': confirmedBy,
      'event_type': event_type,
      'performed_by': performed_by,
      'device_info': device_info,
      'sequence': sequence, // AMÉLIORATION: Sauvegarde de la séquence
    };
  }
}

class GeoUtils {
  // Rayon de la Terre en km
  static const double _earthRadius = 6371.0;

  // Conversion degrés → radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Calcul de distance entre deux points (formule de Haversine)
  static double calculateDistanceBetweenPoints(
    double lat1, double lon1, double lat2, double lon2) {
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * 
         cos(_degreesToRadians(lat2)) * 
         sin(dLon / 2) * 
         sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceAerial = _earthRadius * c;
    
    // Ajouter 20% pour simuler la route réelle (vs vol d'oiseau)
    double routeDistance = distanceAerial * 1.2;
    
    // Retourner avec 2 décimales
    return double.parse(routeDistance.toStringAsFixed(2));
  }
  
  // Calcul de distance entre deux GeoFirePoint
  static double calculateDistance(GeoFirePoint point1, GeoFirePoint point2) {
    return calculateDistanceBetweenPoints(
      point1.latitude, 
      point1.longitude, 
      point2.latitude, 
      point2.longitude
    );
  }
  
  // Calcul de distance entre deux GeoPoint
  static double calculateGeoPointDistance(GeoPoint point1, GeoPoint point2) {
    return calculateDistanceBetweenPoints(
      point1.latitude, 
      point1.longitude, 
      point2.latitude, 
      point2.longitude
    );
  }
  
  // Vérifier si un point est dans un rayon donné
  static bool isPointInRadius(GeoFirePoint center, GeoFirePoint point, double radiusKm) {
    double distance = calculateDistance(center, point);
    return distance <= radiusKm;
  }
  
  // Générer un geohash
/// Génère un geohash à partir de coordonnées géographiques
/// 
/// [lat] : Latitude en degrés
/// [lng] : Longitude en degrés
/// [precision] : Longueur du geohash (par défaut 9 caractères)
/// 
/// Retourne : Le geohash sous forme de String
static String generateGeohash(double lat, double lng, {int precision = 9}) {
  final point = GeoFirePoint(GeoPoint(lat, lng));
  return point.geohash.substring(0, precision);
}
  
  // Estimer le temps de trajet (simple estimation)
  static Duration estimateTravelTime(double distanceKm, 
      {double speedKmh = 50.0}) {
    // Vitesse moyenne en zones urbaines/routes: 50 km/h
    double timeHours = distanceKm / speedKmh;
    int timeMinutes = (timeHours * 60).round();
    return Duration(minutes: timeMinutes);
  }
}

// lib/utils/price_calculator.dart
// AMÉLIORATION: Utilitaire dédié au calcul de prix
class PriceCalculator {
  // Prix de base par km
  static const double _basePricePerKm = 0.30; // $0.30/km
  
  // Prix par kg
  static const double _baseWeightPrice = 0.50; // $0.50/kg
  
  // Multiplicateurs pour les services express
  static const double _expressMultiplier = 1.15; // +15%
  static const double _economyMultiplier = 0.90; // -10%
  
  // Calcul du prix estimé en fonction des paramètres du colis
  static double calculateEstimatedPrice({
    required double distanceKm, 
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    String? insuranceLevel,
  }) {
    // Prix de base en fonction de la distance et du poids
    double distanceFactor = distanceKm * _basePricePerKm;
    double weightFactor = weightKg * _baseWeightPrice;
    
    // Déterminer le multiplicateur de vitesse
    double speedMultiplier = deliverySpeed == 'express' ? _expressMultiplier : 
                            deliverySpeed == 'economy' ? _economyMultiplier : 1.0;
    
    // Prix estimé basique
    double estimatedPrice = (distanceFactor + weightFactor) * speedMultiplier;
    
    // Ajouter le prix de l'assurance si applicable
    if (insuranceLevel != null && insuranceLevel != 'none' && declaredValue != null) {
      estimatedPrice += _calculateInsurancePrice(declaredValue, insuranceLevel);
    }
    
    // Arrondir à 2 décimales
    return double.parse(estimatedPrice.toStringAsFixed(2));
  }
  
  // Calculer le prix d'assurance en fonction du niveau
  static double _calculateInsurancePrice(double declaredValue, String level) {
    switch (level) {
      case 'basic':
        return declaredValue * 0.01; // 1% de la valeur
      case 'premium':
        return declaredValue * 0.025; // 2.5% de la valeur
      default:
        return 0.0;
    }
  }
}
 