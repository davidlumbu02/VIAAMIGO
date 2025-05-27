// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un appareil connecté de l'utilisateur
class UserDevice {
  final String id; // ID unique de l'appareil
  final String fcmToken; // Token Firebase Cloud Messaging
  final String platform; // Plateforme
  final String model; // Modèle de l'appareil
  final String osVersion; // Version du système d'exploitation
  final String appVersion; // Version de l'application
  final DateTime lastUsedAt; // Dernière utilisation
  final String? ipAddress; // Dernière adresse IP connue
  final bool isCurrentDevice; // Si c'est l'appareil actuel
  final String deviceName; // Nom convivial de l'appareil

  /// Constructeur principal
  const UserDevice({
    required this.id,
    required this.fcmToken,
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.lastUsedAt,
    this.ipAddress,
    this.isCurrentDevice = false,
    required this.deviceName,
  });

  /// Crée une instance à partir d'un document Firestore
  factory UserDevice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDevice(
      id: doc.id,
      fcmToken: data['fcmToken'] ?? '',
      platform: data['platform'] ?? 'unknown',
      model: data['model'] ?? 'unknown',
      osVersion: data['osVersion'] ?? 'unknown',
      appVersion: data['appVersion'] ?? 'unknown',
      lastUsedAt: data['lastUsedAt'] != null 
          ? (data['lastUsedAt'] as Timestamp).toDate()
          : DateTime.now(),
      ipAddress: data['ipAddress'],
      isCurrentDevice: data['isCurrentDevice'] ?? false,
      deviceName: data['deviceName'] ?? 'Appareil inconnu',
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fcmToken': fcmToken,
      'platform': platform,
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'ipAddress': ipAddress,
      'isCurrentDevice': isCurrentDevice,
      'deviceName': deviceName,
    };
  }

  /// Crée une copie modifiée de cette instance
  UserDevice copyWith({
    String? fcmToken,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    DateTime? lastUsedAt,
    String? ipAddress,
    bool? isCurrentDevice,
    String? deviceName,
  }) {
    return UserDevice(
      id: id,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fcmToken': fcmToken,
      'platform': platform,
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'ipAddress': ipAddress,
      'isCurrentDevice': isCurrentDevice,
      'deviceName': deviceName,
    };
  }
  
  /// Crée une instance à partir de JSON
  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'],
      fcmToken: json['fcmToken'],
      platform: json['platform'],
      model: json['model'],
      osVersion: json['osVersion'],
      appVersion: json['appVersion'],
      lastUsedAt: DateTime.parse(json['lastUsedAt']),
      ipAddress: json['ipAddress'],
      isCurrentDevice: json['isCurrentDevice'] ?? false,
      deviceName: json['deviceName'],
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDevice && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Service pour gérer les appareils des utilisateurs
class UserDevicesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère tous les appareils d'un utilisateur
  Future<List<UserDevice>> getUserDevices(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .get();
        
    return querySnapshot.docs
        .map((doc) => UserDevice.fromFirestore(doc))
        .toList();
  }
  
  /// Récupère tous les appareils d'un utilisateur comme Stream
  Stream<List<UserDevice>> getUserDevicesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => UserDevice.fromFirestore(doc)).toList());
  }
  
  /// Ajoute ou met à jour un appareil
  Future<String> registerDevice(String userId, UserDevice device) async {
    // Vérifie si l'appareil existe déjà par son FCM token
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .where('fcmToken', isEqualTo: device.fcmToken)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      // Mise à jour d'un appareil existant
      final existingDocId = query.docs.first.id;
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(existingDocId)
        .set(device.copyWith(lastUsedAt: DateTime.now()).toFirestore(), SetOptions(merge: true));
      return existingDocId;
    } else {
      // Création d'un nouvel appareil
      final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .add(device.toFirestore());
      return docRef.id;
    }
  }
  
  /// Marque un appareil comme courant et les autres comme non courants
  Future<void> setCurrentDevice(String userId, String deviceId) async {
    // D'abord, marquer tous les appareils comme non actuels
    final batch = _firestore.batch();
    
    final devices = await getUserDevices(userId);
    for (final device in devices) {
      if (device.isCurrentDevice && device.id != deviceId) {
        batch.update(
          _firestore
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(device.id),
          {'isCurrentDevice': false}
        );
      }
    }
    
    // Ensuite, marquer l'appareil spécifié comme actuel
    batch.update(
      _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId),
      {'isCurrentDevice': true, 'lastUsedAt': Timestamp.now()}
    );
    
    await batch.commit();
  }
  
  /// Supprime un appareil
  Future<void> deleteDevice(String userId, String deviceId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }
  
  /// Met à jour le token FCM d'un appareil
  Future<void> updateFcmToken(String userId, String deviceId, String newToken) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .update({'fcmToken': newToken, 'lastUsedAt': Timestamp.now()});
  }
  /// 📱 Crée un document d’appareil vide dans `/users/{uid}/devices/{auto_id}`
/// 💡 Appelé lors de l’inscription ou de la première utilisation sur un appareil
Future<void> createEmptyDeviceDoc(String userId) async {
  try {
    // 🔗 Génère une référence Firestore avec un ID auto-généré
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(); // ✅ ID Firestore généré dynamiquement

    // 🧱 Données par défaut simulant un appareil Android typique
    final defaultDevice = UserDevice(
      id: docRef.id,         // 🆔 Injection manuelle de l'ID dans le modèle
      fcmToken: '',          // 🔕 Token FCM vide pour MVP
      platform: 'android',   // 📱 Plateforme de base (modifiable dynamiquement)
      model: 'Pixel 5',      // 📦 Modèle simulé
      osVersion: '13',       // 🧠 Version d’Android par défaut
      appVersion: '1.0.0',   // 🚀 Version initiale de l’app
      lastUsedAt: DateTime.now(), // ⏰ Date d’activité courante
      ipAddress: null,       // 🌐 IP non connue au moment de la création
      isCurrentDevice: true, // ✅ Appareil courant par défaut
      deviceName: 'Mon appareil', // 🏷️ Nom convivial
    );

    // 📤 Enregistrement dans Firestore
    await docRef.set(defaultDevice.toFirestore());
  } catch (e) {
    print('Error creating empty device for user $userId: $e');
    rethrow;
  }
}

/*
  //mvp 
  /// 📱 Crée un appareil vide avec données MVP par défaut
Future<void> createEmptyDeviceDoc(String userId) async {
  final defaultDevice = UserDevice(
    id: 'placeholder',
    fcmToken: '',
    platform: 'android',
    model: 'Pixel 5',
    osVersion: '13',
    appVersion: '1.0.0',
    lastUsedAt: DateTime.now(),
    ipAddress: null,
    isCurrentDevice: true,
    deviceName: 'Mon appareil',
  );

  await _firestore
      .collection('users')
      .doc(userId)
      .collection('devices')
      .doc(defaultDevice.id)
      .set(defaultDevice.toFirestore());
}
*/
}