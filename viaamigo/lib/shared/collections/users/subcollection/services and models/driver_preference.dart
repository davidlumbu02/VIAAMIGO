// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';  // Import du modèle TimeSlot

/// Modèle représentant les préférences spécifiques au conducteur
class DriverPreferences {
  final double maxDetourKm; // Détour maximum accepté (en km)
  final List<String> preferredParcelSizes; // Tailles de colis acceptées
  final bool avoidHighways; // Préférence pour éviter les autoroutes
  final List<String> preferredPaymentMethods; // Méthodes de paiement préférées
  final bool autoAcceptMatches; // Acceptation automatique des correspondances
  final double minimumPricePerKm; // Prix minimum par km accepté
  final List<String> availableDays; // Jours de disponibilité habituels
  final List<TimeSlot> availableTimeSlots; // Créneaux horaires préférés
  final List<String> packageTypesAccepted; // Types de colis acceptés
  final bool acceptsUrgentDeliveries; // Accepte les livraisons urgentes
  final bool advancePickupAllowed; // Accepte de récupérer en avance
  final bool automaticMatchingEnabled; // Activation du matching automatique

  /// Constructeur principal
  const DriverPreferences({
    this.maxDetourKm = 5.0,
    this.preferredParcelSizes = const ['small', 'medium'],
    this.avoidHighways = false,
    this.preferredPaymentMethods = const ['card', 'wallet'],
    this.autoAcceptMatches = false,
    this.minimumPricePerKm = 0.15,
    this.availableDays = const [],
    this.availableTimeSlots = const [],
    this.packageTypesAccepted = const [],
    this.acceptsUrgentDeliveries = true,
    this.advancePickupAllowed = true,
    this.automaticMatchingEnabled = true,
  });

  /// Crée une instance à partir d'un document Firestore
  factory DriverPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertit les créneaux horaires
    List<TimeSlot> timeSlots = [];
    if (data['availableTimeSlots'] != null) {
      timeSlots = (data['availableTimeSlots'] as List)
          .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList();
    }
    
    return DriverPreferences(
      maxDetourKm: (data['maxDetourKm'] ?? 5.0).toDouble(),
      preferredParcelSizes: List<String>.from(data['preferredParcelSizes'] ?? ['small', 'medium']),
      avoidHighways: data['avoidHighways'] ?? false,
      preferredPaymentMethods: List<String>.from(data['preferredPaymentMethods'] ?? ['card', 'wallet']),
      autoAcceptMatches: data['autoAcceptMatches'] ?? false,
      minimumPricePerKm: (data['minimumPricePerKm'] ?? 0.15).toDouble(),
      availableDays: List<String>.from(data['availableDays'] ?? []),
      availableTimeSlots: timeSlots,
      packageTypesAccepted: List<String>.from(data['packageTypesAccepted'] ?? []),
      acceptsUrgentDeliveries: data['acceptsUrgentDeliveries'] ?? true,
      advancePickupAllowed: data['advancePickupAllowed'] ?? true,
      automaticMatchingEnabled: data['automaticMatchingEnabled'] ?? true,
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'maxDetourKm': maxDetourKm,
      'preferredParcelSizes': preferredParcelSizes,
      'avoidHighways': avoidHighways,
      'preferredPaymentMethods': preferredPaymentMethods,
      'autoAcceptMatches': autoAcceptMatches,
      'minimumPricePerKm': minimumPricePerKm,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots.map((slot) => slot.toMap()).toList(),
      'packageTypesAccepted': packageTypesAccepted,
      'acceptsUrgentDeliveries': acceptsUrgentDeliveries,
      'advancePickupAllowed': advancePickupAllowed,
      'automaticMatchingEnabled': automaticMatchingEnabled,
    };
  }

  /// Crée une copie modifiée de cette instance
  DriverPreferences copyWith({
    double? maxDetourKm,
    List<String>? preferredParcelSizes,
    bool? avoidHighways,
    List<String>? preferredPaymentMethods,
    bool? autoAcceptMatches,
    double? minimumPricePerKm,
    List<String>? availableDays,
    List<TimeSlot>? availableTimeSlots,
    List<String>? packageTypesAccepted,
    bool? acceptsUrgentDeliveries,
    bool? advancePickupAllowed,
    bool? automaticMatchingEnabled,
  }) {
    return DriverPreferences(
      maxDetourKm: maxDetourKm ?? this.maxDetourKm,
      preferredParcelSizes: preferredParcelSizes ?? this.preferredParcelSizes,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      preferredPaymentMethods: preferredPaymentMethods ?? this.preferredPaymentMethods,
      autoAcceptMatches: autoAcceptMatches ?? this.autoAcceptMatches,
      minimumPricePerKm: minimumPricePerKm ?? this.minimumPricePerKm,
      availableDays: availableDays ?? this.availableDays,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      packageTypesAccepted: packageTypesAccepted ?? this.packageTypesAccepted,
      acceptsUrgentDeliveries: acceptsUrgentDeliveries ?? this.acceptsUrgentDeliveries,
      advancePickupAllowed: advancePickupAllowed ?? this.advancePickupAllowed,
      automaticMatchingEnabled: automaticMatchingEnabled ?? this.automaticMatchingEnabled,
    );
  }

  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'maxDetourKm': maxDetourKm,
      'preferredParcelSizes': preferredParcelSizes,
      'avoidHighways': avoidHighways,
      'preferredPaymentMethods': preferredPaymentMethods,
      'autoAcceptMatches': autoAcceptMatches,
      'minimumPricePerKm': minimumPricePerKm,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots.map((slot) => slot.toJson()).toList(),
      'packageTypesAccepted': packageTypesAccepted,
      'acceptsUrgentDeliveries': acceptsUrgentDeliveries,
      'advancePickupAllowed': advancePickupAllowed,
      'automaticMatchingEnabled': automaticMatchingEnabled,
    };
  }

  /// Crée une instance à partir de JSON
  factory DriverPreferences.fromJson(Map<String, dynamic> json) {
    List<TimeSlot> timeSlots = [];
    if (json['availableTimeSlots'] != null) {
      timeSlots = (json['availableTimeSlots'] as List)
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList();
    }
    
    return DriverPreferences(
      maxDetourKm: json['maxDetourKm'] ?? 5.0,
      preferredParcelSizes: List<String>.from(json['preferredParcelSizes'] ?? ['small', 'medium']),
      avoidHighways: json['avoidHighways'] ?? false,
      preferredPaymentMethods: List<String>.from(json['preferredPaymentMethods'] ?? ['card', 'wallet']),
      autoAcceptMatches: json['autoAcceptMatches'] ?? false,
      minimumPricePerKm: json['minimumPricePerKm'] ?? 0.15,
      availableDays: List<String>.from(json['availableDays'] ?? []),
      availableTimeSlots: timeSlots,
      packageTypesAccepted: List<String>.from(json['packageTypesAccepted'] ?? []),
      acceptsUrgentDeliveries: json['acceptsUrgentDeliveries'] ?? true,
      advancePickupAllowed: json['advancePickupAllowed'] ?? true,
      automaticMatchingEnabled: json['automaticMatchingEnabled'] ?? true,
    );
  }
}

/// Service pour gérer les préférences conducteur
class DriverPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère les préférences d'un conducteur comme Stream
  Stream<DriverPreferences> getDriverPreferencesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('driver_preferences')
        .doc(userId)
        .snapshots()
        .map((snapshot) => 
            snapshot.exists ? DriverPreferences.fromFirestore(snapshot) : DriverPreferences());
  }
  
  /// Récupère les préférences d'un conducteur
  Future<DriverPreferences> getDriverPreferences(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('driver_preferences')
        .doc(userId)
        .get();
        
    return doc.exists ? DriverPreferences.fromFirestore(doc) : DriverPreferences();
  }
  
  /// Met à jour les préférences d'un conducteur
  Future<void> updateDriverPreferences(String userId, DriverPreferences preferences) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('driver_preferences')
        .doc(userId)
        .set(preferences.toFirestore(), SetOptions(merge: true));
  }
/// 🛠️ Initialise le document `driver_preferences/{uid}` avec des préférences par défaut
/// 📌 Appelée automatiquement à la création d’un nouveau compte conducteur ou hybride
Future<void> createEmptyDriverPreferencesDoc(String userId) async {
  try {
    // 🔧 Définition des préférences de conduite par défaut
    const defaultPrefs = DriverPreferences(
      maxDetourKm: 10.0, // 🚗 Distance maximale de détour autorisée
      preferredParcelSizes: ['small', 'medium', 'large'], // 📦 Tailles de colis acceptées
      avoidHighways: false, // 🛣️ Autoroutes autorisées
      preferredPaymentMethods: ['wallet', 'card'], // 💳 Méthodes de paiement acceptées
      autoAcceptMatches: false, // 🔁 Matching manuel par défaut
      minimumPricePerKm: 0.25, // 💰 Minimum accepté pour le prix au kilomètre

      // 📅 Jours où le conducteur est en principe disponible
      availableDays: [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
      ],

      // 🕒 Créneaux horaires disponibles par défaut
      availableTimeSlots: [
        TimeSlot(day: 'monday', start: '08:00', end: '12:00'),
        TimeSlot(day: 'monday', start: '14:00', end: '18:00'),
        TimeSlot(day: 'friday', start: '09:00', end: '17:00'),
      ],

      packageTypesAccepted: ['standard', 'fragile'], // 📦 Types de colis que le conducteur accepte
      acceptsUrgentDeliveries: true,  // ⚡ Livraisons urgentes permises
      advancePickupAllowed: true,     // 📦 Récupération la veille possible
      automaticMatchingEnabled: true, // 🤖 Matching automatique activé (utilisable plus tard)
    );

    // 📤 Enregistrement dans Firestore : /users/{uid}/driver_preferences/{uid}
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('driver_preferences')
        .doc(userId) // 🧩 Un document unique lié à l’utilisateur
        .set(defaultPrefs.toFirestore());
  } catch (e) {
    // 🚨 Logging en cas d’échec
    print('Error creating empty driver preferences for $userId: $e');
    rethrow;
  }
}

  /*

  /// Initialisation des préférences du conducteur avec des données par défaut
  Future<void> createEmptyDriverPreferencesDoc(String userId) async {
    const defaultPrefs = DriverPreferences(
      maxDetourKm: 10.0,
      preferredParcelSizes: ['small', 'medium', 'large'],
      avoidHighways: false,
      preferredPaymentMethods: ['wallet', 'card'],
      autoAcceptMatches: false,
      minimumPricePerKm: 0.25,
      availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      availableTimeSlots: [
        TimeSlot(day: 'monday', start: '08:00', end: '12:00'),
        TimeSlot(day: 'monday', start: '14:00', end: '18:00'),
        TimeSlot(day: 'friday', start: '09:00', end: '17:00'),
      ],
      packageTypesAccepted: ['standard', 'fragile'],
      acceptsUrgentDeliveries: true,
      advancePickupAllowed: true,
      automaticMatchingEnabled: true,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('driver_preferences')
        .doc(userId)
        .set(defaultPrefs.toFirestore());
  }*/
}
