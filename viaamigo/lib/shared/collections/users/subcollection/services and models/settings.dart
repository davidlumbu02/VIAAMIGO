// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// 📦 Modèle représentant les paramètres personnalisés de l'utilisateur
/// Cette classe contient tous les paramètres configurables par l'utilisateur
/// et offre des méthodes pour la conversion depuis/vers Firestore et JSON
class UserSettings {
  /// Mode d'affichage de l'interface (dark, light, system)
  final String themeMode;
  
  /// Langue préférée de l'utilisateur (code ISO, ex: fr, en)
  final String language;
  
  /// Si les notifications sont activées pour l'utilisateur
  final bool notificationsEnabled;
  
  /// Rôle préféré lors de l'ouverture de l'app (expediteur, conducteur, les deux)
  final String preferredRole;
  
  /// Rayon de recherche en kilomètres pour les recherches géolocalisées
  final int searchRadiusKm;
  
  /// Fonctionnalités expérimentales activées/désactivées
  final Map<String, bool> experimentalFeatures;
  
  /// Paramètres de confidentialité de l'utilisateur
  final Map<String, dynamic> privacySettings;
  
  /// Préférences détaillées pour les notifications
  final Map<String, dynamic> notificationPreferences;

  /// Constructeur principal avec valeurs par défaut pour les maps
  const UserSettings({
    required this.themeMode,
    required this.language,
    required this.notificationsEnabled,
    required this.preferredRole,
    required this.searchRadiusKm,
    this.experimentalFeatures = const {},
    this.privacySettings = const {},
    this.notificationPreferences = const {},
  });

  /// 🔄 Création à partir d'un Document Firestore
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Conversion sécurisée des Map pour éviter les erreurs de type
    Map<String, bool> experimentalFeaturesMap = {};
    if (data['experimentalFeatures'] is Map) {
      final rawMap = data['experimentalFeatures'] as Map;
      rawMap.forEach((key, value) {
        experimentalFeaturesMap[key.toString()] = value is bool ? value : false;
      });
    }

    // Conversion sécurisée des paramètres de confidentialité
    Map<String, dynamic> privacySettingsMap = {};
    if (data['privacySettings'] is Map) {
      final rawMap = data['privacySettings'] as Map;
      rawMap.forEach((key, value) {
        privacySettingsMap[key.toString()] = value;
      });
    }

    // Conversion sécurisée des préférences de notification
    Map<String, dynamic> notificationPreferencesMap = {};
    if (data['notificationPreferences'] is Map) {
      final rawMap = data['notificationPreferences'] as Map;
      rawMap.forEach((key, value) {
        notificationPreferencesMap[key.toString()] = value;
      });
    } else if (data['notification_preferences'] is Map) {
      final rawMap = data['notification_preferences'] as Map;
      rawMap.forEach((key, value) {
        notificationPreferencesMap[key.toString()] = value;
      });
    }

    return UserSettings(
      themeMode: _validateThemeMode(data['themeMode']),
      language: data['language'] ?? 'fr',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      preferredRole: _validateRole(data['preferredRole']),
      searchRadiusKm: _parseSearchRadius(data['searchRadiusKm']),
      experimentalFeatures: experimentalFeaturesMap,
      privacySettings: privacySettingsMap,
      notificationPreferences: notificationPreferencesMap,
    );
  }

  /// Valide que le mode de thème est bien une valeur attendue
  static String _validateThemeMode(dynamic value) {
    if (value is String && ['dark', 'light', 'system'].contains(value)) {
      return value;
    }
    return 'system'; // Valeur par défaut si invalide
  }

  /// Valide que le rôle est bien une valeur attendue
  static String _validateRole(dynamic value) {
    if (value is String && ['sender', 'driver', 'both'].contains(value)) {
      return value;
    }
    return 'sender'; // Valeur par défaut si invalide
  }

  /// Convertit de façon sécurisée le rayon de recherche en entier
  static int _parseSearchRadius(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 10; // Valeur par défaut si invalide
  }

  /// 🔄 Conversion en Map pour stockage dans Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'themeMode': themeMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'preferredRole': preferredRole,
      'searchRadiusKm': searchRadiusKm,
      'experimentalFeatures': experimentalFeatures,
      'privacySettings': privacySettings,
      'notificationPreferences': notificationPreferences,
    };
  }

  /// 🔁 Clone avec modifications
  UserSettings copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    String? preferredRole,
    int? searchRadiusKm,
    Map<String, bool>? experimentalFeatures,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredRole: preferredRole ?? this.preferredRole,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      experimentalFeatures: experimentalFeatures ?? this.experimentalFeatures,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  /// 🔄 Conversion en JSON pour API ou stockage local
  Map<String, dynamic> toJson() => toFirestore();

  /// 🔄 Création depuis un JSON (local storage, API)
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    Map<String, bool> experimentalFeaturesMap = {};
    if (json['experimentalFeatures'] is Map) {
      final rawMap = json['experimentalFeatures'] as Map;
      rawMap.forEach((key, value) {
        experimentalFeaturesMap[key.toString()] = value is bool ? value : false;
      });
    }

    return UserSettings(
      themeMode: _validateThemeMode(json['themeMode']),
      language: json['language'] ?? 'fr',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      preferredRole: _validateRole(json['preferredRole']),
      searchRadiusKm: _parseSearchRadius(json['searchRadiusKm']),
      experimentalFeatures: experimentalFeaturesMap,
      privacySettings: json['privacySettings'] is Map
          ? Map<String, dynamic>.from(json['privacySettings'])
          : {},
      notificationPreferences: json['notificationPreferences'] is Map
          ? Map<String, dynamic>.from(json['notificationPreferences'])
          : {},
    );
  }

  /// 🔎 Comparaison logique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.notificationsEnabled == notificationsEnabled &&
        other.preferredRole == preferredRole &&
        other.searchRadiusKm == searchRadiusKm;
  }

  @override
  int get hashCode =>
      themeMode.hashCode ^
      language.hashCode ^
      notificationsEnabled.hashCode ^
      preferredRole.hashCode ^
      searchRadiusKm.hashCode;
}

/// 📦 Service pour gérer les paramètres des utilisateurs
class UserSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📡 Récupérer les paramètres en temps réel via un Stream
  Stream<UserSettings> getUserSettingsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('app')
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? UserSettings.fromFirestore(snapshot)
            : getDefaultSettings());
  }

  /// 📋 Récupérer les paramètres une seule fois
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app')
          .get();
      return doc.exists
          ? UserSettings.fromFirestore(doc)
          : getDefaultSettings();
    } catch (e) {
      print('Error fetching user settings: $e');
      return getDefaultSettings();
    }
  }

  /// 💾 Met à jour les paramètres utilisateur avec fusion (merge)
  Future<void> updateUserSettings(String userId, UserSettings settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app')
          .set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating user settings: $e');
      rethrow;
    }
  }

  /// 🛠️ Valeurs par défaut si pas trouvé
  UserSettings getDefaultSettings() {
    return const UserSettings(
      themeMode: 'system',
      language: 'fr',
      notificationsEnabled: true,
      preferredRole: 'both',
      searchRadiusKm: 10,
      experimentalFeatures: {},
      privacySettings: {},
      notificationPreferences: {},
    );
  }
  /// 🛠️ Crée un document "settings/app" par défaut pour un utilisateur
/// Appelé lors de l’inscription ou de la première connexion
/// 🛠️ Crée un document "settings" avec ID aléatoire pour un utilisateur
/// Utilisé lors de l’inscription ou de la première connexion
Future<void> createEmptySettingsDoc(String uid) async {
  try {
    // 🧩 Valeurs par défaut à insérer dans le document
    const defaultSettings = UserSettings(
      themeMode: 'system', // 🎨 Le thème suit le système (dark/light)
      language: 'fr', // 🌍 Langue par défaut : français
      notificationsEnabled: true, // 🔔 Notifications activées par défaut
      preferredRole: 'sender', // 🚚 Rôle initial : expéditeur
      searchRadiusKm: 10, // 📍 Rayon de recherche : 10 km
      experimentalFeatures: {
        'featureA': false,
        'featureB': false,
      },
      privacySettings: {
        'showOnlineStatus': true,      // 👁️ Statut en ligne visible
        'shareLocation': true,         // 📍 Localisation partagée
        'profileVisibility': 'public', // 🌐 Profil visible publiquement
      },
      notificationPreferences: {
        'new_matches': true,             // 🔁 Notifications de matching
        'messages': true,                // 💬 Nouveaux messages
        'status_updates': true,          // 📦 Mises à jour de statut
        'payment_confirmations': true,   // 💳 Confirmation de paiement
        'promotional': true,             // 🤑 Offres promotionnelles
        'reminder_frequency': 'immediate', // ⏰ Fréquence de rappel
        'channels': {                    // 📲 Canaux activés
          'push': true,
          'email': true,
          'sms': true,
        },
      },
    );

    // 📥 Enregistre le document dans /users/{uid}/settings/ avec ID généré automatiquement
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .add(defaultSettings.toFirestore());

    print('✅ Document settings créé avec ID aléatoire');
  } catch (e) {
    // ⚠️ Log en cas d'erreur
    print('❌ Erreur création settings : $e');
    rethrow;
  }
}

/*
  /// Créer les paramètres par défaut pour un nouvel utilisateur
  Future<void> createEmptySettingsDoc(String uid) async {
    try {
      const defaultSettings = UserSettings(
        themeMode: 'system',
        language: 'fr',
        notificationsEnabled: true,
        preferredRole: 'sender',
        searchRadiusKm: 10,
        experimentalFeatures: {'featureA': false, 'featureB': false},
        privacySettings: {'showOnlineStatus': true, 'shareLocation': true},
        notificationPreferences: {'new_matches': true, 'messages': true},
      );
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app')
          .set(defaultSettings.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating empty settings document: $e');
      rethrow;
    }
  }*/

  /// Supprimer les paramètres d'un utilisateur
  Future<void> deleteSettings(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app')
          .delete();
    } catch (e) {
      print('Error deleting settings: $e');
      rethrow;
    }
  }
  
  /// Vérifie si les paramètres existent pour un utilisateur
  Future<bool> settingsExist(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking if settings exist: $e');
      return false;
    }
  }
}





/*import 'package:cloud_firestore/cloud_firestore.dart';

/// 📦 Modèle et Service représentant les paramètres personnalisés de l'utilisateur
class UserSettings {
  final String themeMode; // Mode d'affichage : dark, light, system
  final String language; // Langue préférée (fr, en, etc.)
  final bool notificationsEnabled; // Notifications activées/désactivées
  final String preferredRole; // Rôle par défaut (expediteur, driver, both)
  final int searchRadiusKm; // Rayon de recherche en km
  final Map<String, bool> experimentalFeatures; // Accès à des fonctionnalités beta
  final Map<String, dynamic> privacySettings; // Paramètres de confidentialité
  final Map<String, dynamic> notificationPreferences; // Paramètres de notifications détaillées

  /// Constructeur principal
  const UserSettings({
    required this.themeMode,
    required this.language,
    required this.notificationsEnabled,
    required this.preferredRole,
    required this.searchRadiusKm,
    this.experimentalFeatures = const {},
    this.privacySettings = const {},
    this.notificationPreferences = const {},
  });

  /// 🔄 Création à partir d'un Document Firestore
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserSettings(
      themeMode: data['themeMode'] ?? 'system',
      language: data['language'] ?? 'fr',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      preferredRole: data['preferredRole'] ?? 'expediteur',
      searchRadiusKm: (data['searchRadiusKm'] ?? 10) is int
          ? data['searchRadiusKm']
          : int.tryParse(data['searchRadiusKm'].toString()) ?? 10,
      experimentalFeatures: data['experimentalFeatures'] is Map
          ? Map<String, bool>.from(data['experimentalFeatures'])
          : {},
      privacySettings: data['privacySettings'] is Map
          ? Map<String, dynamic>.from(data['privacySettings'])
          : {},
      notificationPreferences: data['notification_preferences'] is Map
          ? Map<String, dynamic>.from(data['notification_preferences'])
          : {},
    );
  }

  /// 🔄 Conversion en Map Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'themeMode': themeMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'preferredRole': preferredRole,
      'searchRadiusKm': searchRadiusKm,
      'experimentalFeatures': experimentalFeatures,
      'privacySettings': privacySettings,
      'notification_preferences': notificationPreferences,
    };
  }

  /// 🔁 Clone avec modifications
  UserSettings copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    String? preferredRole,
    int? searchRadiusKm,
    Map<String, bool>? experimentalFeatures,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredRole: preferredRole ?? this.preferredRole,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      experimentalFeatures: experimentalFeatures ?? this.experimentalFeatures,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  /// 🔄 Conversion en JSON (API, LocalStorage)
  Map<String, dynamic> toJson() => toFirestore();

  /// 🔄 Création depuis un JSON
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      themeMode: json['themeMode'] ?? 'system',
      language: json['language'] ?? 'fr',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      preferredRole: json['preferredRole'] ?? 'expediteur',
      searchRadiusKm: (json['searchRadiusKm'] ?? 10) is int
          ? json['searchRadiusKm']
          : int.tryParse(json['searchRadiusKm'].toString()) ?? 10,
      experimentalFeatures: json['experimentalFeatures'] is Map
          ? Map<String, bool>.from(json['experimentalFeatures'])
          : {},
      privacySettings: json['privacySettings'] is Map
          ? Map<String, dynamic>.from(json['privacySettings'])
          : {},
      notificationPreferences: json['notification_preferences'] is Map
          ? Map<String, dynamic>.from(json['notification_preferences'])
          : {},
    );
  }

  /// 🔎 Comparaison logique
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.notificationsEnabled == notificationsEnabled &&
        other.preferredRole == preferredRole &&
        other.searchRadiusKm == searchRadiusKm;
  }

  @override
  int get hashCode =>
      themeMode.hashCode ^
      language.hashCode ^
      notificationsEnabled.hashCode ^
      preferredRole.hashCode ^
      searchRadiusKm.hashCode;
}

/// 📦 Service pour gérer les paramètres des utilisateurs (Fusionné ici)
class UserSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📡 Récupérer les paramètres en temps réel
  Stream<UserSettings> getUserSettingsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('app')
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? UserSettings.fromFirestore(snapshot)
            : getDefaultSettings());
  }

  /// 📋 Récupérer une seule fois les paramètres
  Future<UserSettings> getUserSettings(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('app')
        .get();

    return doc.exists
        ? UserSettings.fromFirestore(doc)
        : getDefaultSettings();
  }

  /// 💾 Mettre à jour les paramètres utilisateur (avec merge)
  Future<void> updateUserSettings(String userId, UserSettings settings) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('app')
        .set(settings.toFirestore(), SetOptions(merge: true));
  }

  /// 🛠️ Valeurs par défaut si pas trouvé
  UserSettings getDefaultSettings() {
    return const UserSettings(
      themeMode: 'system',
      language: 'fr',
      notificationsEnabled: true,
      preferredRole: 'expediteur',
      searchRadiusKm: 10,
      experimentalFeatures: {},
      privacySettings: {},
      notificationPreferences: {},
    );
  }

  //pour mvp
  Future<void> createEmptySettingsDoc(String uid) async {
  const defaultSettings = UserSettings(
    themeMode: 'system',
    language: 'fr',
    notificationsEnabled: true,
    preferredRole: 'expediteur',
    searchRadiusKm: 10,
    experimentalFeatures: {
      'featureA': false,
      'featureB': false,
    },
    privacySettings: {
      'showOnlineStatus': true,
      'shareLocation': true,
      'profileVisibility': 'public',
    },
    notificationPreferences: {
      'new_matches': true,
      'messages': true,
      'status_updates': true,
      'payment_confirmations': true,
      'promotional': true,
      'reminder_frequency': 'immediate',
      'channels': {
        'push': true,
        'email': true,
        'sms': true,
      }
    },
  );

  await _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('app')
      .set(defaultSettings.toFirestore(), SetOptions(merge: true));
}
Future<void> deleteSettings(String uid) async {
  await _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('app')
      .delete();
}

}
*/