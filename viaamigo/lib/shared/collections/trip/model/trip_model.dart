import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// Modèle principal représentant un trajet dans le système ViaAmigo
/// 
/// Cette classe gère toutes les données associées à un trajet de conducteur,
/// de sa création jusqu'à sa complétion. Elle inclut des fonctionnalités pour 
/// la validation, la conversion depuis/vers Firestore, et diverses opérations 
/// de compatibilité avec les colis (ParcelModel).
class TripModel {
  // ----- PROPRIÉTÉS DE BASE -----
  
  /// Identifiant unique du trajet (généré par Firestore)
  String? tripId;
  
  /// ID du conducteur qui propose le trajet
  String? driverId;
  
  /// Date de création du trajet dans le système
  DateTime? createdAt;
  
  /// Date de dernière modification
  DateTime? updatedAt;
  
  /// État actuel du trajet dans le système
  /// Valeurs possibles: "available", "in_progress", "completed", "cancelled"
  String status;
  
  // ----- INFORMATIONS GÉOGRAPHIQUES -----
  
  /// Point géographique de départ (avec latitude/longitude)
  GeoFirePoint? origin;
  
  /// Adresse textuelle du point de départ
  String originAddress;
  
  /// Point géographique de destination (avec latitude/longitude)  
  GeoFirePoint? destination;
  
  /// Adresse textuelle du point de destination
  String destinationAddress;
  
  /// Points d'arrêt intermédiaires optionnels sur le trajet
  /// Structure: [{"address": "...", "latitude": x, "longitude": y, "stopDuration": minutes}]
  List<Map<String, dynamic>>? waypoints;
  
  // ----- INFORMATIONS TEMPORELLES -----
  
  /// Date et heure de départ prévues
  DateTime departureTime;
  
  /// Date et heure d'arrivée estimées (optionnel)
  DateTime? arrivalTime;
  
  /// Indique si le trajet est récurrent (hebdomadaire, quotidien, etc.)
  bool isRecurring;
  
  /// Configuration de la récurrence si applicable
  /// Structure: {"frequency": "weekly", "days": ["monday", "friday"], "endDate": "..."}
  Map<String, dynamic>? schedule;
  
  // ----- INFORMATIONS VÉHICULE & CAPACITÉ -----
  
  /// Capacités maximales du véhicule pour le transport de colis
  /// Structure: {"maxWeight": kg, "maxVolume": liters, "maxParcels": count}
  Map<String, dynamic> vehicleCapacity;
  
  /// Type de véhicule utilisé
  /// Valeurs possibles: "car", "van", "truck", "motorcycle", "bicycle"
  String vehicleType;
  
  /// Informations détaillées du véhicule
  /// Structure: {"brand": "...", "model": "...", "year": 2020, "color": "...", "licensePlate": "..."}
  Map<String, dynamic> vehicleInfo;
  
  // ----- COMPATIBILITÉ & RESTRICTIONS COLIS -----
  
  /// Types de colis acceptés par le conducteur
  /// Valeurs possibles: ["documents", "electronics", "clothing", "fragile", "perishable", "bulky"]
  List<String> acceptedParcelTypes;
  
  /// Capacités de manipulation spéciale du conducteur/véhicule
  /// Structure: {"fragile": true, "refrigerated": false, "oversized": true, "valuable": true}
  Map<String, dynamic> handlingCapabilities;
  
  // ----- PARAMÈTRES DE NOTIFICATION -----
  
  /// Préférences de notification du conducteur
  /// Structure: {"app": true, "sms": false, "email": true, "sound": true}
  Map<String, dynamic> notificationSettings;
  
  /// ✅ AJOUT - Geohash pour l'indexation géographique
  String? g;
  
  /// ✅ AJOUT - Étape de navigation (pour compatibilité avec le controller)
  int navigation_step;
  
  /// Liste des erreurs de validation pour afficher à l'utilisateur
  List<String> validationErrors;
  
  // ----- CONSTRUCTEURS -----
  
  /// Constructeur principal avec tous les paramètres possibles
  TripModel({
    this.tripId,
    this.driverId,
    this.createdAt,
    this.updatedAt,
    this.status = 'available',
    this.origin,
    required this.originAddress,
    this.destination,
    required this.destinationAddress,
    this.waypoints,
    required this.departureTime,
    this.arrivalTime,
    this.isRecurring = false,
    this.schedule,
    required this.vehicleCapacity,
    required this.vehicleType,
    required this.vehicleInfo,
    required this.acceptedParcelTypes,
    required this.handlingCapabilities,
    required this.notificationSettings,
    this.g, // ✅ AJOUT
    this.navigation_step = 0, // ✅ AJOUT
    this.validationErrors = const [],
  });

  /// Crée un modèle de trajet vide avec les valeurs minimales requises
  /// Utilisé pour initialiser un nouveau trajet en mode brouillon
  factory TripModel.empty(String userId) {
    final now = DateTime.now();
    return TripModel(
      driverId: userId,
      status: 'available',
      originAddress: '',
      destinationAddress: '',
      departureTime: now.add(Duration(hours: 2)), // Départ dans 2h par défaut
      vehicleCapacity: {
        'maxWeight': 20.0, // 20kg par défaut
        'maxVolume': 100.0, // 100L par défaut
        'maxParcels': 3, // 3 colis max par défaut
      },
      vehicleType: 'car',
      vehicleInfo: {
        'brand': '',
        'model': '',
        'year': DateTime.now().year,
        'color': '',
        'licensePlate': '',
      },
      acceptedParcelTypes: ['documents', 'electronics', 'clothing'],
      handlingCapabilities: {
        'fragile': false,
        'refrigerated': false,
        'oversized': false,
        'valuable': false,
      },
      notificationSettings: {
        'app': true,
        'sms': false,
        'email': true,
        'sound': true,
      },
      createdAt: now,
      updatedAt: now,
      navigation_step: 0, // ✅ AJOUT
    );
  }

  /// Construit une instance depuis un document Firestore
  /// Gère la conversion des types spécifiques (GeoPoint, Timestamp, etc.)
  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Conversion des coordonnées géographiques
    GeoFirePoint? origin;
    if (data['origin'] != null) {
      GeoPoint geoPoint = data['origin'];
      origin = GeoFirePoint(geoPoint);
    }

    GeoFirePoint? destination;
    if (data['destination'] != null) {
      GeoPoint geoPoint = data['destination'];
      destination = GeoFirePoint(geoPoint);
    }

    return TripModel(
      tripId: doc.id,
      driverId: data['driverId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'available',
      origin: origin,
      originAddress: data['originAddress'] ?? '',
      destination: destination,
      destinationAddress: data['destinationAddress'] ?? '',
      waypoints: data['waypoints'] != null 
        ? List<Map<String, dynamic>>.from(data['waypoints'])
        : null,
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      arrivalTime: (data['arrivalTime'] as Timestamp?)?.toDate(),
      isRecurring: data['isRecurring'] ?? false,
      schedule: data['schedule'],
      vehicleCapacity: Map<String, dynamic>.from(data['vehicleCapacity'] ?? {}),
      vehicleType: data['vehicleType'] ?? 'car',
      vehicleInfo: Map<String, dynamic>.from(data['vehicleInfo'] ?? {}),
      acceptedParcelTypes: List<String>.from(data['acceptedParcelTypes'] ?? []),
      handlingCapabilities: Map<String, dynamic>.from(data['handlingCapabilities'] ?? {}),
      notificationSettings: Map<String, dynamic>.from(data['notificationSettings'] ?? {}),
      g: data['g'], // ✅ AJOUT
      navigation_step: data['navigation_step'] ?? 0, // ✅ AJOUT
      validationErrors: List<String>.from(data['validationErrors'] ?? []),
    );
  }

  /// Convertit l'instance en Map pour le stockage Firestore
  /// Gère la conversion des types spécifiques (DateTime en Timestamp, etc.)
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'driverId': driverId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      'origin': origin != null ? GeoPoint(origin!.latitude, origin!.longitude) : null,
      'originAddress': originAddress,
      'destination': destination != null ? GeoPoint(destination!.latitude, destination!.longitude) : null,
      'destinationAddress': destinationAddress,
      'waypoints': waypoints,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'isRecurring': isRecurring,
      'schedule': schedule,
      'vehicleCapacity': vehicleCapacity,
      'vehicleType': vehicleType,
      'vehicleInfo': vehicleInfo,
      'acceptedParcelTypes': acceptedParcelTypes,
      'handlingCapabilities': handlingCapabilities,
      'notificationSettings': notificationSettings,
      'g': g, // ✅ AJOUT
      'navigation_step': navigation_step, // ✅ AJOUT
      'validationErrors': validationErrors,
    };
  }

  /// Crée une nouvelle instance avec certains champs modifiés
  /// Implémente le pattern "immutable update"
  TripModel copyWith({
    String? tripId,
    String? driverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    GeoFirePoint? origin,
    String? originAddress,
    GeoFirePoint? destination,
    String? destinationAddress,
    List<Map<String, dynamic>>? waypoints,
    DateTime? departureTime,
    DateTime? arrivalTime,
    bool? isRecurring,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? vehicleCapacity,
    String? vehicleType,
    Map<String, dynamic>? vehicleInfo,
    List<String>? acceptedParcelTypes,
    Map<String, dynamic>? handlingCapabilities,
    Map<String, dynamic>? notificationSettings,
    String? g, // ✅ AJOUT
    int? navigation_step, // ✅ AJOUT
    List<String>? validationErrors,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      originAddress: originAddress ?? this.originAddress,
      destination: destination ?? this.destination,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      waypoints: waypoints ?? (this.waypoints != null 
        ? List<Map<String, dynamic>>.from(this.waypoints!)
        : null),
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      isRecurring: isRecurring ?? this.isRecurring,
      schedule: schedule ?? (this.schedule != null 
        ? Map<String, dynamic>.from(this.schedule!)
        : null),
      vehicleCapacity: vehicleCapacity ?? Map<String, dynamic>.from(this.vehicleCapacity),
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleInfo: vehicleInfo ?? Map<String, dynamic>.from(this.vehicleInfo),
      acceptedParcelTypes: acceptedParcelTypes ?? List<String>.from(this.acceptedParcelTypes),
      handlingCapabilities: handlingCapabilities ?? Map<String, dynamic>.from(this.handlingCapabilities),
      notificationSettings: notificationSettings ?? Map<String, dynamic>.from(this.notificationSettings),
      g: g ?? this.g, // ✅ AJOUT
      navigation_step: navigation_step ?? this.navigation_step, // ✅ AJOUT
      validationErrors: validationErrors ?? List<String>.from(this.validationErrors),
    );
  }

  // ----- MÉTHODES JSON POUR SÉRIALISATION -----

  /// Construit une instance depuis JSON
  static TripModel fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['tripId'],
      driverId: json['driverId'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'])
        : null,
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'])
        : null,
      status: json['status'] ?? 'available',
      origin: _parseGeoFirePoint(json['origin']),
      originAddress: json['originAddress'] ?? '',
      destination: _parseGeoFirePoint(json['destination']),
      destinationAddress: json['destinationAddress'] ?? '',
      waypoints: json['waypoints'] != null
        ? List<Map<String, dynamic>>.from(json['waypoints'])
        : null,
      departureTime: DateTime.parse(json['departureTime']),
      arrivalTime: json['arrivalTime'] != null
        ? DateTime.parse(json['arrivalTime'])
        : null,
      isRecurring: json['isRecurring'] ?? false,
      schedule: json['schedule'],
      vehicleCapacity: Map<String, dynamic>.from(json['vehicleCapacity'] ?? {}),
      vehicleType: json['vehicleType'] ?? 'car',
      vehicleInfo: Map<String, dynamic>.from(json['vehicleInfo'] ?? {}),
      acceptedParcelTypes: List<String>.from(json['acceptedParcelTypes'] ?? []),
      handlingCapabilities: Map<String, dynamic>.from(json['handlingCapabilities'] ?? {}),
      notificationSettings: Map<String, dynamic>.from(json['notificationSettings'] ?? {}),
      g: json['g'], // ✅ AJOUT
      navigation_step: json['navigation_step'] ?? 0, // ✅ AJOUT
      validationErrors: List<String>.from(json['validationErrors'] ?? []),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'driverId': driverId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'origin': origin != null ? {
        'latitude': origin!.latitude,
        'longitude': origin!.longitude,
      } : null,
      'originAddress': originAddress,
      'destination': destination != null ? {
        'latitude': destination!.latitude,
        'longitude': destination!.longitude,
      } : null,
      'destinationAddress': destinationAddress,
      'waypoints': waypoints,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime?.toIso8601String(),
      'isRecurring': isRecurring,
      'schedule': schedule,
      'vehicleCapacity': vehicleCapacity,
      'vehicleType': vehicleType,
      'vehicleInfo': vehicleInfo,
      'acceptedParcelTypes': acceptedParcelTypes,
      'handlingCapabilities': handlingCapabilities,
      'notificationSettings': notificationSettings,
      'g': g, // ✅ AJOUT
      'navigation_step': navigation_step, // ✅ AJOUT
      'validationErrors': validationErrors,
    };
  }

  /// Helper pour parser GeoFirePoint depuis JSON
  static GeoFirePoint? _parseGeoFirePoint(dynamic geoData) {
    if (geoData == null) return null;
    
    try {
      if (geoData is Map<String, dynamic>) {
        final lat = geoData['latitude'] ?? geoData['lat'];
        final lng = geoData['longitude'] ?? geoData['lng'];
        if (lat != null && lng != null) {
          return GeoFirePoint(GeoPoint(lat.toDouble(), lng.toDouble()));
        }
      }
    } catch (e) {
      debugPrint('Erreur parsing GeoFirePoint: $e');
    }
    return null;
  }

  // ----- MÉTHODES DE VALIDATION -----

  /// Valide toutes les données du trajet
  /// Remplit la liste validationErrors avec les problèmes détectés
  bool validate() {
    validationErrors.clear();
    
    // Vérification des champs obligatoires
    if (driverId == null || driverId!.isEmpty) {
      validationErrors.add('ID du conducteur manquant');
    }
    if (originAddress.isEmpty) {
      validationErrors.add('Adresse de départ manquante');
    }
    if (destinationAddress.isEmpty) {
      validationErrors.add('Adresse de destination manquante');
    }
    if (vehicleType.isEmpty) {
      validationErrors.add('Type de véhicule manquant');
    }
    if (acceptedParcelTypes.isEmpty) {
      validationErrors.add('Types de colis acceptés non spécifiés');
    }
    
    // Vérification des capacités
    final maxWeight = vehicleCapacity['maxWeight'];
    final maxVolume = vehicleCapacity['maxVolume'];
    final maxParcels = vehicleCapacity['maxParcels'];
    
    if (maxWeight == null || maxWeight <= 0) {
      validationErrors.add('Capacité de poids invalide');
    }
    if (maxVolume == null || maxVolume <= 0) {
      validationErrors.add('Capacité de volume invalide');
    }
    if (maxParcels == null || maxParcels <= 0) {
      validationErrors.add('Nombre maximum de colis invalide');
    }
    
    // Vérification du timing
    final now = DateTime.now();
    if (departureTime.isBefore(now)) {
      validationErrors.add('L\'heure de départ ne peut pas être dans le passé');
    }
    
    if (arrivalTime != null && arrivalTime!.isBefore(departureTime)) {
      validationErrors.add('L\'heure d\'arrivée ne peut pas être avant le départ');
    }
    
    return validationErrors.isEmpty;
  }

  /// Vérifie si le trajet est prêt à être publié
  bool isReadyToPublish() {
    return validate() && origin != null && destination != null;
  }

  // ----- MÉTHODES DE COMPATIBILITÉ AVEC PARCELMODEL -----

  /// Vérifie si ce trajet peut accepter un colis spécifique
  /// Contrôle la compatibilité de poids, volume, type et exigences spéciales
  bool canAcceptParcel(dynamic parcel) {
    // Vérification du poids
    final parcelWeight = parcel.weight ?? 0.0;
    final maxWeight = vehicleCapacity['maxWeight'] ?? 0.0;
    if (parcelWeight > maxWeight) return false;
    
    // Vérification du type de colis
    final parcelType = parcel.category ?? '';
    if (parcelType.isNotEmpty && !acceptedParcelTypes.contains(parcelType)) {
      return false;
    }
    
    // Vérification des exigences spéciales
    final specialRequirements = parcel.specialRequirements ?? [];
    if (specialRequirements is List) {
      for (String requirement in specialRequirements) {
        if (!handlingCapabilities.containsKey(requirement) || 
            !handlingCapabilities[requirement]) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Vérifie si les points de ramassage et livraison sont sur la route
  /// Utilise une logique de déviation maximale acceptable
  bool isOnRoute(GeoFirePoint pickupLocation, GeoFirePoint deliveryLocation) {
    if (origin == null || destination == null) return false;
    
    // TODO: Implémenter la logique de calcul de déviation
    // Pour l'instant, retourne true (à implémenter avec une API de routing)
    return true;
  }

  /// Calcule une estimation du temps de livraison pour un colis
  /// Basé sur la position du colis sur la route et la vitesse estimée
  DateTime? estimateDeliveryTime(dynamic parcel) {
    if (parcel.destination == null || destination == null) return null;
    
    // TODO: Implémenter la logique de calcul basée sur:
    // - Distance entre origin et parcel.destination
    // - Distance totale du trajet
    // - Heure de départ
    // - Vitesse moyenne estimée
    
    return arrivalTime;
  }

  // ----- MÉTHODES UTILITAIRES -----

  /// Met à jour les capacités du véhicule
  void updateVehicleCapacity(double maxWeight, double maxVolume, int maxParcels) {
    vehicleCapacity = {
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'maxParcels': maxParcels,
    };
  }

  /// Ajoute un point d'arrêt intermédiaire
  void addWaypoint(String address, double latitude, double longitude, {int stopDuration = 15}) {
    waypoints ??= [];
    waypoints!.add({
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'stopDuration': stopDuration, // en minutes
    });
  }

  /// Supprime un point d'arrêt par index
  void removeWaypoint(int index) {
    if (waypoints != null && index >= 0 && index < waypoints!.length) {
      waypoints!.removeAt(index);
    }
  }

  /// Calcule la durée totale estimée du trajet
  Duration get estimatedDuration {
    if (arrivalTime != null) {
      return arrivalTime!.difference(departureTime);
    }
    
    // Estimation par défaut basée sur la distance (à améliorer)
    return Duration(hours: 2);
  }

  /// Retourne le statut formaté pour l'affichage
  String get displayStatus {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  /// Prépare un objet simplifié pour l'affichage dans une carte UI
  Map<String, dynamic> toDisplayCard() {
    return {
      'tripId': tripId,
      'route': '$originAddress → $destinationAddress',
      'departureTime': departureTime.toIso8601String(),
      'vehicleType': vehicleType,
      'availableCapacity': '${vehicleCapacity['maxWeight']}kg / ${vehicleCapacity['maxParcels']} colis',
      'status': displayStatus,
      'acceptedTypes': acceptedParcelTypes.join(', '),
      'isRecurring': isRecurring,
    };
  }
}