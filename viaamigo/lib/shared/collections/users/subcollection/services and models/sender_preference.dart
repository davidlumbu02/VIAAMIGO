// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';

/// Modèle représentant les préférences spécifiques à l'expéditeur
class SenderPreferences {
  final double preferredDriverRating;
  final bool insuranceDefault;
  final bool notifyOnNearbyDrivers;
  final List<TimeSlot> preferredPickupTimes;
  final String preferredDeliverySpeed;
  final double maxPricePerKm;
  final String defaultInsuranceLevel;
  final String preferredConfirmationMethod;
  final bool flexibleTimingAllowed;

  const SenderPreferences({
    this.preferredDriverRating = 4.0,
    this.insuranceDefault = true,
    this.notifyOnNearbyDrivers = true,
    this.preferredPickupTimes = const [],
    this.preferredDeliverySpeed = 'standard',
    this.maxPricePerKm = 0.3,
    this.defaultInsuranceLevel = 'basic',
    this.preferredConfirmationMethod = 'pin',
    this.flexibleTimingAllowed = true,
  });

  /// 🔄 Création à partir de Firestore
  factory SenderPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<TimeSlot> timeSlots = [];
    if (data['preferredPickupTimes'] != null) {
      timeSlots = (data['preferredPickupTimes'] as List)
          .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList();
    }

    return SenderPreferences(
      preferredDriverRating: (data['preferredDriverRating'] is num)
          ? (data['preferredDriverRating'] as num).toDouble()
          : 4.0,
      insuranceDefault: data['insuranceDefault'] ?? true,
      notifyOnNearbyDrivers: data['notifyOnNearbyDrivers'] ?? true,
      preferredPickupTimes: List.unmodifiable(timeSlots),
      preferredDeliverySpeed: data['preferredDeliverySpeed'] ?? 'standard',
      maxPricePerKm: (data['maxPricePerKm'] is num)
          ? (data['maxPricePerKm'] as num).toDouble()
          : 0.3,
      defaultInsuranceLevel: data['defaultInsuranceLevel'] ?? 'basic',
      preferredConfirmationMethod: data['preferredConfirmationMethod'] ?? 'pin',
      flexibleTimingAllowed: data['flexibleTimingAllowed'] ?? true,
    );
  }

  /// 🔁 Conversion Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'preferredDriverRating': preferredDriverRating,
      'insuranceDefault': insuranceDefault,
      'notifyOnNearbyDrivers': notifyOnNearbyDrivers,
      'preferredPickupTimes': preferredPickupTimes.map((slot) => slot.toMap()).toList(),
      'preferredDeliverySpeed': preferredDeliverySpeed,
      'maxPricePerKm': maxPricePerKm,
      'defaultInsuranceLevel': defaultInsuranceLevel,
      'preferredConfirmationMethod': preferredConfirmationMethod,
      'flexibleTimingAllowed': flexibleTimingAllowed,
    };
  }

  /// 🔁 Conversion JSON
  Map<String, dynamic> toJson() {
    return {
      'preferredDriverRating': preferredDriverRating,
      'insuranceDefault': insuranceDefault,
      'notifyOnNearbyDrivers': notifyOnNearbyDrivers,
      'preferredPickupTimes': preferredPickupTimes.map((slot) => slot.toJson()).toList(),
      'preferredDeliverySpeed': preferredDeliverySpeed,
      'maxPricePerKm': maxPricePerKm,
      'defaultInsuranceLevel': defaultInsuranceLevel,
      'preferredConfirmationMethod': preferredConfirmationMethod,
      'flexibleTimingAllowed': flexibleTimingAllowed,
    };
  }

  /// 🧱 Factory JSON
  factory SenderPreferences.fromJson(Map<String, dynamic> json) {
    List<TimeSlot> timeSlots = [];
    if (json['preferredPickupTimes'] != null) {
      timeSlots = (json['preferredPickupTimes'] as List)
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList();
    }

    return SenderPreferences(
      preferredDriverRating: (json['preferredDriverRating'] is num)
          ? (json['preferredDriverRating'] as num).toDouble()
          : 4.0,
      insuranceDefault: json['insuranceDefault'] ?? true,
      notifyOnNearbyDrivers: json['notifyOnNearbyDrivers'] ?? true,
      preferredPickupTimes: List.unmodifiable(timeSlots),
      preferredDeliverySpeed: json['preferredDeliverySpeed'] ?? 'standard',
      maxPricePerKm: (json['maxPricePerKm'] is num)
          ? (json['maxPricePerKm'] as num).toDouble()
          : 0.3,
      defaultInsuranceLevel: json['defaultInsuranceLevel'] ?? 'basic',
      preferredConfirmationMethod: json['preferredConfirmationMethod'] ?? 'pin',
      flexibleTimingAllowed: json['flexibleTimingAllowed'] ?? true,
    );
  }

  /// 🔧 Création de copie modifiée
  SenderPreferences copyWith({
    double? preferredDriverRating,
    bool? insuranceDefault,
    bool? notifyOnNearbyDrivers,
    List<TimeSlot>? preferredPickupTimes,
    String? preferredDeliverySpeed,
    double? maxPricePerKm,
    String? defaultInsuranceLevel,
    String? preferredConfirmationMethod,
    bool? flexibleTimingAllowed,
  }) {
    return SenderPreferences(
      preferredDriverRating: preferredDriverRating ?? this.preferredDriverRating,
      insuranceDefault: insuranceDefault ?? this.insuranceDefault,
      notifyOnNearbyDrivers: notifyOnNearbyDrivers ?? this.notifyOnNearbyDrivers,
      preferredPickupTimes: preferredPickupTimes ?? this.preferredPickupTimes,
      preferredDeliverySpeed: preferredDeliverySpeed ?? this.preferredDeliverySpeed,
      maxPricePerKm: maxPricePerKm ?? this.maxPricePerKm,
      defaultInsuranceLevel: defaultInsuranceLevel ?? this.defaultInsuranceLevel,
      preferredConfirmationMethod: preferredConfirmationMethod ?? this.preferredConfirmationMethod,
      flexibleTimingAllowed: flexibleTimingAllowed ?? this.flexibleTimingAllowed,
    );
  }
}

/// 📡 Service Firestore pour gérer les préférences de l'expéditeur
class SenderPreferencesService {
  final FirebaseFirestore firestore;

  SenderPreferencesService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// 🔁 Retourne un flux temps réel des préférences
  Stream<SenderPreferences> getSenderPreferencesStream(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('sender_preferences')
        .doc(userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.exists ? SenderPreferences.fromFirestore(snapshot) : getDefaultSenderPreferences());
  }

  /// 🔎 Récupération unique des préférences depuis Firestore
  Future<SenderPreferences> getSenderPreferences(String userId) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('sender_preferences')
        .doc(userId)
        .get();

    return doc.exists
        ? SenderPreferences.fromFirestore(doc)
        : getDefaultSenderPreferences(); // 🔁 fallback
  }

  /// 💾 Mise à jour (fusion) des préférences Firestore
  Future<void> updateSenderPreferences(String userId, SenderPreferences preferences) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('sender_preferences')
        .doc(userId)
        .set(preferences.toFirestore(), SetOptions(merge: true));
  }
  /// 🛠️ Crée un document de préférences expéditeur (`sender_preferences/{uid}`) avec des valeurs par défaut
/// 📌 Appelée lors de la création d’un nouveau compte utilisateur
Future<void> createEmptySenderPreferencesDoc(String userId) async {
  try {
    // 🧱 Construction des préférences par défaut via méthode centralisée
    final defaultPrefs = getDefaultSenderPreferences();

    // 🗂️ Enregistrement dans la sous-collection Firestore : /users/{uid}/sender_preferences/{uid}
    await firestore
        .collection('users')
        .doc(userId)
        .collection('sender_preferences')
        .doc(userId) // ✅ Document ID = UID → logique "singleton"
        .set(defaultPrefs.toFirestore());
  } catch (e) {
    // ⚠️ Enregistrement d’une erreur si échec
    print('Error creating empty sender preferences for user $userId: $e');
    rethrow;
  }
}

/*
  /// 🧱 Création initiale d'un document de préférences MVP
  Future<void> createEmptySenderPreferencesDoc(String userId) async {
    final defaultPrefs = getDefaultSenderPreferences();
    await firestore
        .collection('users')
        .doc(userId)
        .collection('sender_preferences')
        .doc(userId)
        .set(defaultPrefs.toFirestore());
  }
*/
  /// ✅ Méthode centralisée pour obtenir les préférences par défaut
  SenderPreferences getDefaultSenderPreferences() {
    return const SenderPreferences(
      preferredDriverRating: 4.5,
      insuranceDefault: true,
      notifyOnNearbyDrivers: true,
      preferredPickupTimes: [
        TimeSlot(day: 'tuesday', start: '10:00', end: '12:00'),
        TimeSlot(day: 'thursday', start: '14:00', end: '16:00'),
      ],
      preferredDeliverySpeed: 'standard',
      maxPricePerKm: 0.45,
      defaultInsuranceLevel: 'basic',
      preferredConfirmationMethod: 'pin',
      flexibleTimingAllowed: true,
    );
  }
}
