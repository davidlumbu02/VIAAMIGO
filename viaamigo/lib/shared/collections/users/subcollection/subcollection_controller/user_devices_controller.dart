// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services and models/devices.dart';

/// 🎮 Contrôleur GetX fusionné pour la gestion complète des appareils utilisateurs
class UserDevicesController extends GetxController {
  // 🔗 Services et instances Firebase
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _messaging = FirebaseMessaging.instance;
  final AuthService _authService = Get.find<AuthService>();
  final UserDevicesService _devicesService = UserDevicesService();

  // 🔄 États observables
  final RxList<UserDevice> userDevices = <UserDevice>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // 🔐 UID de l'utilisateur connecté
  String? get _uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    ever(_authService.firebaseUser, _onUserChanged);
    if (_authService.firebaseUser.value != null) {
      loadUserDevices();
    }
  }

  // 🔁 Écoute des changements de session utilisateur
  void _onUserChanged(User? user) async {
    if (user != null) {
      loadUserDevices();
    } else {
      userDevices.clear();
    }
  }

  /// 🔄 Charge tous les appareils du compte utilisateur
  Future<void> loadUserDevices() async {
    if (_uid == null) return;
    isLoading.value = true;
    error.value = '';
    try {
      final devices = await _devicesService.getUserDevices(_uid!);
      userDevices.assignAll(devices);
    } catch (e) {
      error.value = 'Error loading user devices: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// ➕ Enregistre un nouvel appareil ou met à jour un existant
  Future<String?> registerDevice(UserDevice device) async {
    if (_uid == null) return null;
    isLoading.value = true;
    error.value = '';
    try {
      final deviceId = await _devicesService.registerDevice(_uid!, device);
      await loadUserDevices();
      return deviceId;
    } catch (e) {
      error.value = 'Error registering user device: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 🗑 Supprime un appareil par son ID
  Future<void> deleteDevice(String deviceId) async {
    if (_uid == null) return;
    isLoading.value = true;
    error.value = '';
    try {
      await _devicesService.deleteDevice(_uid!, deviceId);
      await loadUserDevices();
    } catch (e) {
      error.value = 'Error deleting user device: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔄 Met à jour le token FCM d'un appareil spécifique
  Future<void> updateFcmToken(String deviceId, String newToken) async {
    if (_uid == null) return;
    isLoading.value = true;
    error.value = '';
    try {
      await _devicesService.updateFcmToken(_uid!, deviceId, newToken);
      await loadUserDevices();
    } catch (e) {
      error.value = 'Error updating FCM token: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 📱 Initialise un document Firestore pour l'appareil courant (MVP)
  Future<void> createEmptyDeviceDoc(String userId) async {
    isLoading.value = true;
    error.value = '';
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      final deviceInfo = await _getDeviceInfo();

      final defaultDevice = UserDevice(
        id: token,
        fcmToken: token,
        platform: GetPlatform.isAndroid
            ? 'android'
            : GetPlatform.isIOS
                ? 'ios'
                : 'unknown',
        model: deviceInfo['model']!,
        osVersion: deviceInfo['osVersion']!,
        appVersion: deviceInfo['appVersion']!,
        lastUsedAt: DateTime.now(),
        ipAddress: null,
        isCurrentDevice: true,
        deviceName: deviceInfo['deviceName']!,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .set(defaultDevice.toFirestore());
    } catch (e) {
      error.value = 'Error initializing default device: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Marque un appareil comme courant et désactive les autres
  Future<void> setCurrentDevice(String deviceId) async {
    if (_uid == null) return;
    isLoading.value = true;
    error.value = '';
    try {
      await _devicesService.setCurrentDevice(_uid!, deviceId);
      await loadUserDevices();
    } catch (e) {
      error.value = 'Error setting current device: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 📍 Récupère l'appareil marqué comme actuel
  UserDevice? getCurrentDevice() {
    try {
      return userDevices.firstWhere((d) => d.isCurrentDevice);
    } catch (_) {
      return userDevices.isNotEmpty ? userDevices.first : null;
    }
  }

  /// 🔍 Récupère un appareil selon son ID
  UserDevice? getDeviceById(String id) {
    return userDevices.firstWhereOrNull((d) => d.id == id);
  }

  /// 🔎 Filtre les appareils par plateforme (Android, iOS...)
  List<UserDevice> getDevicesByPlatform(String platform) {
    return userDevices.where((d) => d.platform.toLowerCase() == platform.toLowerCase()).toList();
  }

  /// ❓ Vérifie si un token FCM est déjà associé à un appareil
  bool deviceExistsWithToken(String fcmToken) {
    return userDevices.any((d) => d.fcmToken == fcmToken);
  }

  /// 🔐 Vérifie si l'appareil courant est toujours actif côté Firestore
  Future<bool> isStillCurrentDevice() async {
    final token = await _messaging.getToken();
    if (_uid == null || token == null) return false;
    final doc = await _firestore.collection('users').doc(_uid).collection('devices').doc(token).get();
    final data = doc.data();
    return data?['isCurrentDevice'] == true;
  }

  /// 🧼 Supprime tous les anciens appareils sauf l'actuel
  Future<void> deleteOtherDevices() async {
    final token = await _messaging.getToken();
    if (_uid == null || token == null) return;
    final devices = await _firestore.collection('users').doc(_uid).collection('devices').get();
    for (final doc in devices.docs) {
      if (doc.id != token) {
        await doc.reference.delete();
      }
    }
  }

  /// 🛠 Met à jour un champ spécifique sur un appareil
  Future<void> updateDeviceField(String token, Map<String, dynamic> fields) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).collection('devices').doc(token).set(fields, SetOptions(merge: true));
  }

  /// 🔁 Active uniquement l'appareil actuel et désactive tous les autres
  Future<void> setCurrentDeviceOnly() async {
    final token = await _messaging.getToken();
    if (_uid == null || token == null) return;
    final ref = _firestore.collection('users').doc(_uid).collection('devices');
    final devices = await ref.get();
    for (final doc in devices.docs) {
      final isCurrent = doc.id == token;
      await doc.reference.update({'isCurrentDevice': isCurrent});
    }
  }

  /// 🧠 Récupère les infos système de l'appareil actuel (modèle, version OS...)
  Future<Map<String, String>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return {
        'model': '${android.brand} ${android.model}',
        'osVersion': 'Android ${android.version.release}',
        'appVersion': appVersion,
        'deviceName': android.device,
      };
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return {
        'model': ios.utsname.machine,
        'osVersion': '${ios.systemName} ${ios.systemVersion}',
        'appVersion': appVersion,
        'deviceName': ios.name,
      };
    } else {
      return {
        'model': 'Unknown',
        'osVersion': 'Unknown',
        'appVersion': appVersion,
        'deviceName': 'Unknown Device',
      };
    }
  }
}
