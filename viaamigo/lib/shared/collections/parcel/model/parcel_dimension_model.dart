import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';




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
    return ParcelDimensions(length: 25, width: 15, height: 10);
  }
  
  static ParcelDimensions medium() {
    return ParcelDimensions(length: 55, width: 35, height: 20);
  }
  
  static ParcelDimensions large() {
    return ParcelDimensions(length: 80, width: 50, height: 40);
  }
  /// Dimensions pour taille XL
static ParcelDimensions extraLarge() {
  return ParcelDimensions(length: 120, width: 80, height: 50);
}
  /// Dimensions pour taille XXL  
static ParcelDimensions doubleExtraLarge() {
  return ParcelDimensions(length: 200, width: 100, height: 60);
}
  // Déterminer la taille standard la plus proche

  
static ParcelDimensions fromSizeString(String sizeString) {
  switch (sizeString) {
    case 'SIZE S':
      return ParcelDimensions.small();
    case 'SIZE M':
      return ParcelDimensions.medium();
    case 'SIZE L':
      return ParcelDimensions.large();
    case 'SIZE XL':
      return ParcelDimensions.extraLarge();
    case 'SIZE XXL':
      return ParcelDimensions.doubleExtraLarge();
    default:
      return ParcelDimensions(length: 0, width: 0, height: 0);
  }
}

String getSizeCategory() {
  final volume = this.volume;
  
  if (volume <= small().volume) {
    return 'SIZE S';
  } else if (volume <= medium().volume) {
    return 'SIZE M';
  } else if (volume <= large().volume) {
    return 'SIZE L';
  } else if (volume <= extraLarge().volume) {
    return 'SIZE XL';
  } else {
    return 'SIZE XXL';
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

/// 🎯 CALCULATEUR DE PRIX FINAL - VERSION COMPLÈTE
/// Intégré parfaitement avec ParcelModel et ParcelsController
class PriceCalculator {
  
  // 📏 TARIFS DE BASE
  static const double _basePricePerKm = 0.18; // CAD par km
  static const double _minimumPrice = 20.0; // Prix minimum
  static const double _maximumPrice = 20000.0; // Prix maximum
  
  // ⚖️ TARIFS SELON LE POIDS (par intervalles exacts)
  static const Map<String, double> _weightPrices = {
    '< 5 kg': 4.9,
    '5–10 kg': 7.5,
    '10–30 kg': 30.0,
    '30–50 kg': 40.0,
    '50–70 kg': 55.0,
    '70–100 kg': 80.0,
    '> 100 kg': 100.0,
  };
  
  // 🚚 MULTIPLICATEURS SELON LA VITESSE
  static const Map<String, double> _speedMultipliers = {
    'standard': 1.0,   // Prix normal
    'urgent': 1.5,     // +50%
  };
  
  // 🛡️ TARIFS D'ASSURANCE (forfaitaires)
  static const Map<String, double> _insuranceFees = {
    'none': 0.0,       // Pas d'assurance
    'basic': 4.0,      // 4 dollars forfait
    'premium': 8.0,    // 8 dollars forfait
  };
  
  // 🏠 FRAIS DE MANUTENTION (selon assistanceLevel)
  /*static const Map<String, double> _handlingFees = {
    'door': 0.0,           // Au pied du véhicule = gratuit
    'light_assist': 29.0,  // Aide avec 1 personne = 29 CAD
    'room': 59.0,          // Transport à 2 personnes = 59 CAD
  };*/

  /// 🎯 MÉTHODE PRINCIPALE - CALCUL AVEC PARCELMODEL COMPLET
  static double calculateEstimatedPrice({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
    String? size,
    Map<String, dynamic>? dimensions,
    int quantity = 1,
    Map<String, dynamic>? pickupHandling,
    Map<String, dynamic>? deliveryHandling,
    double? promoDiscount,
    double? totalHandlingFees,
  }) {
    
    try {
      // 1️⃣ VALIDATION DES DONNÉES CRITIQUES
      if (distanceKm <= 0) return _minimumPrice;
      if (weightKg <= 0) return _minimumPrice;
      
      // 2️⃣ PRIX DE BASE SELON LA DISTANCE
      double basePrice = distanceKm * _basePricePerKm;
      
      // 3️⃣ PRIX SELON LE POIDS (par intervalles)
      double weightPrice = _calculateWeightPrice(weightKg);
      
      // 4️⃣ SURCHARGE VOLUMÉTRIQUE (corrigée)
      double volumeSurcharge = _calculateVolumeSurcharge(size, dimensions);
      
      // 5️⃣ SOUS-TOTAL DE BASE
      double subtotalBase = basePrice + weightPrice + volumeSurcharge;
      
      // 6️⃣ MULTIPLICATEUR VITESSE DE LIVRAISON
      double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
      subtotalBase *= speedMultiplier;
      
      // 7️⃣ MULTIPLICATEUR QUANTITÉ
      subtotalBase *= quantity;
      
      // 8️⃣ FRAIS DE MANUTENTION (pickup + delivery)
      double? handlingFees = totalHandlingFees;
      
      // 9️⃣ ASSURANCE (forfaitaire)
      double insuranceFee = _insuranceFees[insuranceLevel] ?? 0.0;
      
      // 🔟 SOUS-TOTAL AVANT REMISE
      double subtotal = subtotalBase + handlingFees! + insuranceFee;
      
      // 1️⃣1️⃣ APPLICATION DES CODES PROMO
      if (promoDiscount != null && promoDiscount > 0) {
        subtotal -= promoDiscount;
        subtotal = subtotal.clamp(0.0, double.infinity);
      }
      
      // 1️⃣2️⃣ PRIX FINAL (sans frais de plateforme comme vous l'avez voulu)
      double finalPrice = subtotal;
      
      // 1️⃣3️⃣ APPLICATION DES LIMITES GLOBALES
      return finalPrice.clamp(_minimumPrice, _maximumPrice);
      
    } catch (e) {
      // En cas d'erreur, retourner le prix minimum
      print("❌ Erreur calcul prix: $e");
      return _minimumPrice;
    }
  }

  /// 🎯 MÉTHODE SIMPLIFIÉE POUR LE CONTROLLER
  static double calculateFromParcel(ParcelModel parcel) {
    return calculateEstimatedPrice(
      distanceKm: parcel.estimatedDistance ?? 0.0,
      weightKg: parcel.weight,
      deliverySpeed: parcel.delivery_speed,
      declaredValue: parcel.declared_value,
      insuranceLevel: parcel.insurance_level,
      size: parcel.size,
      dimensions: parcel.dimensions,
      quantity: parcel.quantity,
      pickupHandling: parcel.pickupHandling,
      deliveryHandling: parcel.deliveryHandling,
      promoDiscount: parcel.discount_amount,
      totalHandlingFees: parcel.totalHandlingFee,
    );
  }

  /// ⚖️ CALCUL DU PRIX SELON LE POIDS (intervalles)
  static double _calculateWeightPrice(double weightKg) {
    if (weightKg < 5.0) return _weightPrices['< 5 kg']!;
    if (weightKg <= 10.0) return _weightPrices['5–10 kg']!;
    if (weightKg <= 30.0) return _weightPrices['10–30 kg']!;
    if (weightKg <= 50.0) return _weightPrices['30–50 kg']!;
    if (weightKg <= 70.0) return _weightPrices['50–70 kg']!;
    if (weightKg <= 100.0) return _weightPrices['70–100 kg']!;
    return _weightPrices['> 100 kg']!;
  }

  /// 📦 CALCUL DE LA SURCHARGE VOLUMÉTRIQUE (logique corrigée)
  static double _calculateVolumeSurcharge(String? size, Map<String, dynamic>? dimensions) {
    
    // CAS 1: Si dimensions personnalisées (custom ou dimensions remplies)
    if (dimensions != null && 
        dimensions['length'] != null && 
        dimensions['width'] != null && 
        dimensions['height'] != null) {
      
      try {
        double length = (dimensions['length'] as num).toDouble();
        double width = (dimensions['width'] as num).toDouble();
        double height = (dimensions['height'] as num).toDouble();
        
        if (length > 0 && width > 0 && height > 0) {
          return _calculateVolumeFee(length, width, height);
        }
      } catch (e) {
        print("❌ Erreur calcul volume dimensions: $e");
      }
    }
    
    // CAS 2: Si taille prédéfinie
    if (size != null && size.isNotEmpty && size.startsWith('SIZE')) {
      try {
        Map<String, dynamic> sizeDimensions = _getSizeDimensions(size);
        double length = (sizeDimensions['length'] as num).toDouble();
        double width = (sizeDimensions['width'] as num).toDouble();
        double height = (sizeDimensions['height'] as num).toDouble();
        
        return _calculateVolumeFee(length, width, height);
      } catch (e) {
        print("❌ Erreur calcul volume taille: $e");
      }
    }
    
    return 0.0;
  }

  /// 📐 CALCUL DES FRAIS VOLUMÉTRIQUES
  static double _calculateVolumeFee(double length, double width, double height) {
    double volumeCm3 = length * width * height;
    double volumeM3 = volumeCm3 / 1000000; // Conversion en m³
    
    // Seuil gratuit : 0.1 m³
    if (volumeM3 > 0.1) {
      return (volumeM3 - 0.1) * 50.0; // 50 CAD par m³ supplémentaire
    }
    
    return 0.0;
  }

  /// 📏 OBTENIR LES DIMENSIONS SELON LA TAILLE
  static Map<String, dynamic> _getSizeDimensions(String size) { // ✅ AJOUT static
    switch (size) {
      case 'SIZE S':
        return ParcelDimensions.small().toMap();
      case 'SIZE M':
        return ParcelDimensions.medium().toMap();
      case 'SIZE L':
        return ParcelDimensions.large().toMap();
      case 'SIZE XL':
        return ParcelDimensions.extraLarge().toMap();
      case 'SIZE XXL':
        return ParcelDimensions.doubleExtraLarge().toMap();
      default:
        return {'length': 0, 'width': 0, 'height': 0};
    }
  }

  /// 🏠 CALCUL DES FRAIS DE MANUTENTION
 /* static double _calculateHandlingFees(
    Map<String, dynamic>? pickupHandling,
    Map<String, dynamic>? deliveryHandling,
  ) {
    double pickupFee = 0.0;
    double deliveryFee = 0.0;
    
    // Frais pickup
    if (pickupHandling != null) {
      String assistanceLevel = pickupHandling['assistanceLevel']?.toString() ?? 'door';
      pickupFee = _handlingFees[assistanceLevel] ?? 0.0;
    }
    
    // Frais delivery
    if (deliveryHandling != null) {
      String assistanceLevel = deliveryHandling['assistanceLevel']?.toString() ?? 'door';
      deliveryFee = _handlingFees[assistanceLevel] ?? 0.0;
    }
    
    return pickupFee + deliveryFee;
  }

  /// 🛡️ CALCUL DES FRAIS D'ASSURANCE (forfaitaire)
  static double calculateInsuranceFee(String insuranceLevel, double? declaredValue) {
    return _insuranceFees[insuranceLevel] ?? 0.0;
  }*/

  /// ⚡ CALCUL RAPIDE (pour tests)
  static double calculateQuickEstimate(double distanceKm, double weightKg) {
    return calculateEstimatedPrice(
      distanceKm: distanceKm,
      weightKg: weightKg,
      deliverySpeed: 'standard',
      insuranceLevel: 'none',
    );
  }

  /// 📊 DÉTAIL COMPLET DU CALCUL POUR DEBUG/AFFICHAGE
  static PriceBreakdown calculatePriceBreakdown({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
    String? size,
    Map<String, dynamic>? dimensions,
    int quantity = 1,
    Map<String, dynamic>? pickupHandling,
    Map<String, dynamic>? deliveryHandling,
    double? promoDiscount,
    double? totalHandlingFees,
  }) {
    
    try {
      // Calculs étape par étape (mêmes que calculateEstimatedPrice)
      double basePrice = distanceKm * _basePricePerKm;
      double weightPrice = _calculateWeightPrice(weightKg);
      double volumeSurcharge = _calculateVolumeSurcharge(size, dimensions);
      
      double subtotalBase = basePrice + weightPrice + volumeSurcharge;
      double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
      double adjustedPrice = subtotalBase * speedMultiplier * quantity;
      
      double handlingFees = totalHandlingFees ?? 0.0;
      double insuranceFee = _insuranceFees[insuranceLevel] ?? 0.0;
      
      double subtotal = adjustedPrice + handlingFees + insuranceFee;
      double discount = promoDiscount ?? 0.0;
      subtotal = (subtotal - discount).clamp(0.0, double.infinity);
      
      double total = subtotal.clamp(_minimumPrice, _maximumPrice);
      
      return PriceBreakdown(
        distanceKm: distanceKm,
        weightKg: weightKg,
        basePrice: basePrice,
        weightPrice: weightPrice,
        volumeSurcharge: volumeSurcharge,
        speedMultiplier: speedMultiplier,
        adjustedPrice: adjustedPrice,
        handlingFees: handlingFees,
        insuranceFee: insuranceFee,
        promoDiscount: discount,
        platformFee: 0.0, // Pas de frais de plateforme
        subtotal: subtotal,
        total: total,
        minimumApplied: total == _minimumPrice,
        maximumApplied: total == _maximumPrice,
        quantity: quantity,
      );
    } catch (e) {
      print("❌ Erreur calcul breakdown: $e");
      return PriceBreakdown(
        distanceKm: distanceKm,
        weightKg: weightKg,
        basePrice: _minimumPrice,
        weightPrice: 0.0,
        volumeSurcharge: 0.0,
        speedMultiplier: 1.0,
        adjustedPrice: _minimumPrice,
        handlingFees: 0.0,
        insuranceFee: 0.0,
        promoDiscount: 0.0,
        platformFee: 0.0,
        subtotal: _minimumPrice,
        total: _minimumPrice,
        minimumApplied: true,
        maximumApplied: false,
        quantity: 1,
      );
    }
  }

  /// 📊 BREAKDOWN DEPUIS PARCELMODEL
  static PriceBreakdown calculateBreakdownFromParcel(ParcelModel parcel) {
    return calculatePriceBreakdown(
      distanceKm: parcel.estimatedDistance ?? 0.0,
      weightKg: parcel.weight,
      deliverySpeed: parcel.delivery_speed,
      declaredValue: parcel.declared_value,
      insuranceLevel: parcel.insurance_level,
      size: parcel.size,
      dimensions: parcel.dimensions,
      quantity: parcel.quantity,
      pickupHandling: parcel.pickupHandling,
      deliveryHandling: parcel.deliveryHandling,
      promoDiscount: parcel.discount_amount,
    );
  }

  /// 🔍 VALIDATION DE COHÉRENCE DU PRIX
  static bool isPriceReasonable(double price, ParcelModel parcel) {
    if (price < _minimumPrice || price > _maximumPrice) return false;
    
    if (parcel.estimatedDistance != null && parcel.estimatedDistance! > 0) {
      double pricePerKm = price / parcel.estimatedDistance!;
      if (pricePerKm < 0.5 || pricePerKm > 50.0) return false;
    }
    
    return true;
  }
}

/// 📊 CLASSE POUR LE DÉTAIL DU CALCUL
class PriceBreakdown {
  final double distanceKm;
  final double weightKg;
  final double basePrice;
  final double weightPrice;
  final double volumeSurcharge;
  final double speedMultiplier;
  final double adjustedPrice;
  final double handlingFees;
  final double insuranceFee;
  final double promoDiscount;
  final double platformFee;
  final double subtotal;
  final double total;
  final bool minimumApplied;
  final bool maximumApplied;
  final int quantity;
  
  PriceBreakdown({
    required this.distanceKm,
    required this.weightKg,
    required this.basePrice,
    required this.weightPrice,
    required this.volumeSurcharge,
    required this.speedMultiplier,
    required this.adjustedPrice,
    required this.handlingFees,
    required this.insuranceFee,
    required this.promoDiscount,
    required this.platformFee,
    required this.subtotal,
    required this.total,
    required this.minimumApplied,
    required this.maximumApplied,
    required this.quantity,
  });

  /// 📋 CONVERSION EN MAP POUR DEBUG
  Map<String, dynamic> toDetailedMap() {
    return {
      'distance_km': distanceKm,
      'weight_kg': weightKg,
      'base_price': basePrice,
      'weight_price': weightPrice,
      'volume_surcharge': volumeSurcharge,
      'speed_multiplier': speedMultiplier,
      'adjusted_price': adjustedPrice,
      'handling_fees': handlingFees,
      'insurance_fee': insuranceFee,
      'promo_discount': promoDiscount,
      'platform_fee': platformFee,
      'subtotal': subtotal,
      'total': total,
      'minimum_applied': minimumApplied,
      'maximum_applied': maximumApplied,
      'quantity': quantity,
    };
  }

  /// 📝 AFFICHAGE LISIBLE POUR DEBUG
  @override
  String toString() {
    return '''
PriceBreakdown:
  Distance: ${distanceKm}km
  Poids: ${weightKg}kg
  Prix base: ${basePrice.toStringAsFixed(2)} CAD
  Prix poids: ${weightPrice.toStringAsFixed(2)} CAD
  Manutention: ${handlingFees.toStringAsFixed(2)} CAD
  Assurance: ${insuranceFee.toStringAsFixed(2)} CAD
  Plateforme: ${platformFee.toStringAsFixed(2)} CAD
  TOTAL: ${total.toStringAsFixed(2)} CAD
    ''';
  }
}

/*
class PriceCalculator {
  // Tarifs de base (à terme, ces valeurs viendront de Firestore config)
  static const double _basePricePerKm = 0.15; // CAD par km
  static const double _weightMultiplier = 0.30; // CAD par kg supplémentaire au-delà de 5kg
  static const double _platformFeePercent = 0.05; // 5% de frais de plateforme
  static const double _minimumPrice = 40; // Prix minimum
  
  // Multiplicateurs selon vitesse de livraison
  static const Map<String, double> _speedMultipliers = {
    'economy': 0.8,    // -20%
    'standard': 1.0,   // Prix normal
    'urgent': 1.5,    // +50%
  };
  
  // Tarifs d'assurance (% de la valeur déclarée)
  static const Map<String, double> _insuranceRates = {
    'none': 0.0,
    'basic': 0.01,     // 1%
    'premium': 0.02,   // 2%
  };
  
  /// Calcule le prix estimé d'une livraison
  static double calculateEstimatedPrice({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
  }) {
    // 1. Prix de base selon distance
    double basePrice = distanceKm * _basePricePerKm;
    
    // 2. Ajout selon poids (si > 5kg)
    if (weightKg > 5.0) {
      double extraWeight = weightKg - 5.0;
      basePrice += extraWeight * _weightMultiplier;
    }
    
    // 3. Multiplicateur selon vitesse
    double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
    basePrice *= speedMultiplier;
    
    // 4. Calcul de l'assurance
    double insuranceFee = 0.0;
    if (insuranceLevel != 'none' && declaredValue != null && declaredValue > 0) {
      double rate = _insuranceRates[insuranceLevel] ?? 0.0;
      insuranceFee = declaredValue * rate;
    }
    
    // 5. Prix total avant frais de plateforme
    double subtotal = basePrice + insuranceFee;
    
    // 6. Frais de plateforme
    double platformFee = subtotal * _platformFeePercent;
    
    // 7. Prix final
    double finalPrice = subtotal + platformFee;
    
    // 8. Appliquer le prix minimum
    return finalPrice < _minimumPrice ? _minimumPrice : finalPrice;
  }
  
  /// Calcule les frais d'assurance séparément
  static double calculateInsuranceFee(String insuranceLevel, double? declaredValue) {
    if (insuranceLevel == 'none' || declaredValue == null || declaredValue <= 0) {
      return 0.0;
    }
    
    double rate = _insuranceRates[insuranceLevel] ?? 0.0;
    return declaredValue * rate;
  }
  
  /// Calcule les frais de plateforme
  static double calculatePlatformFee(double basePrice) {
    return basePrice * _platformFeePercent;
  }
  
  /// Calcule une estimation de prix rapide (sans assurance)
  static double calculateQuickEstimate(double distanceKm, double weightKg) {
    return calculateEstimatedPrice(
      distanceKm: distanceKm,
      weightKg: weightKg,
      deliverySpeed: 'standard',
      insuranceLevel: 'none',
    );
  }
  
  /// Retourne le détail du calcul pour affichage
  static PriceBreakdown calculatePriceBreakdown({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
  }) {
    // Calculs étape par étape
    double basePrice = distanceKm * _basePricePerKm;
    
    double weightSurcharge = 0.0;
    if (weightKg > 5.0) {
      weightSurcharge = (weightKg - 5.0) * _weightMultiplier;
      basePrice += weightSurcharge;
    }
    
    double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
    double adjustedPrice = basePrice * speedMultiplier;
    
    double insuranceFee = calculateInsuranceFee(insuranceLevel, declaredValue);
    double subtotal = adjustedPrice + insuranceFee;
    double platformFee = calculatePlatformFee(subtotal);
    double total = subtotal + platformFee;
    
    if (total < _minimumPrice) {
      total = _minimumPrice;
    }
    
    return PriceBreakdown(
      distanceKm: distanceKm,
      weightKg: weightKg,
      basePrice: distanceKm * _basePricePerKm,
      weightSurcharge: weightSurcharge,
      speedMultiplier: speedMultiplier,
      adjustedPrice: adjustedPrice,
      insuranceFee: insuranceFee,
      platformFee: platformFee,
      subtotal: subtotal,
      total: total,
      minimumApplied: total == _minimumPrice,
    );
  }
}

/// Classe pour le détail du calcul de prix
class PriceBreakdown {
  final double distanceKm;
  final double weightKg;
  final double basePrice;
  final double weightSurcharge;
  final double speedMultiplier;
  final double adjustedPrice;
  final double insuranceFee;
  final double platformFee;
  final double subtotal;
  final double total;
  final bool minimumApplied;
  
  PriceBreakdown({
    required this.distanceKm,
    required this.weightKg,
    required this.basePrice,
    required this.weightSurcharge,
    required this.speedMultiplier,
    required this.adjustedPrice,
    required this.insuranceFee,
    required this.platformFee,
    required this.subtotal,
    required this.total,
    required this.minimumApplied,
  });
}*/
