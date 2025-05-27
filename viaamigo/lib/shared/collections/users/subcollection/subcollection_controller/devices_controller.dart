// ignore_for_file: avoid_print

/*import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/devices.dart'; // Assurez-vous que le chemin d'import est correct
import 'package:viaamigo/shared/services/auth_service.dart';

/// Contrôleur pour gérer les appareils de l'utilisateur
class UserDevicesController extends GetxController {
  // Services injectés
  final UserDevicesService _devicesService = UserDevicesService();
  final AuthService _authService = Get.find<AuthService>();

  // Variables observables
  final RxList<UserDevice> userDevices = <UserDevice>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'authentification
    ever(_authService.firebaseUser, _onUserChanged);

    // Si l'utilisateur est connecté, charger ses appareils
    if (_authService.firebaseUser.value != null) {
      loadUserDevices();
    }
  }

  // Méthode pour réagir aux changements d'utilisateur
  void _onUserChanged(user) async {
    if (user != null) {
      loadUserDevices();
    } else {
      // Réinitialiser les appareils quand l'utilisateur est déconnecté
      userDevices.clear();
    }
  }

  // Méthode pour charger les appareils de l'utilisateur
  Future<void> loadUserDevices() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final devices = await _devicesService.getUserDevices(userId);
      userDevices.assignAll(devices);
    } catch (e) {
      error.value = 'Error loading user devices: $e';
      print('Error loading user devices: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour enregistrer un appareil (ajout ou mise à jour)
  Future<String?> registerDevice(UserDevice device) async {
    if (_authService.firebaseUser.value == null) return null;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final deviceId = await _devicesService.registerDevice(userId, device);
      await loadUserDevices(); // Recharger la liste
      print('User device registered successfully');
      return deviceId;
    } catch (e) {
      error.value = 'Error registering user device: $e';
      print('Error registering user device: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour définir l'appareil actuel
  Future<void> setCurrentDevice(String deviceId) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _devicesService.setCurrentDevice(userId, deviceId);
      await loadUserDevices(); // Recharger la liste
      print('Current device set successfully');
    } catch (e) {
      error.value = 'Error setting current device: $e';
      print('Error setting current device: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour supprimer un appareil
  Future<void> deleteDevice(String deviceId) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _devicesService.deleteDevice(userId, deviceId);
      await loadUserDevices(); // Recharger la liste
      print('User device deleted successfully');
    } catch (e) {
      error.value = 'Error deleting user device: $e';
      print('Error deleting user device: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour mettre à jour le token FCM d'un appareil
  Future<void> updateFcmToken(String deviceId, String newToken) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _devicesService.updateFcmToken(userId, deviceId, newToken);
      await loadUserDevices(); // Recharger la liste
      print('FCM token updated successfully');
    } catch (e) {
      error.value = 'Error updating FCM token: $e';
      print('Error updating FCM token: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour initialiser avec un appareil vide
  Future<void> createEmptyDeviceDoc(String userId) async {
    isLoading.value = true;
    error.value = '';

    try {
      await _devicesService.createEmptyDeviceDoc(userId);
      print('✅ Appareil par défaut initialisé pour l\'utilisateur: $userId');
    } catch (e) {
      error.value = 'Error initializing default device: $e';
      print('❌ Erreur lors de l\'initialisation de l\'appareil par défaut: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour obtenir l'appareil courant
  UserDevice? getCurrentDevice() {
    try {
      return userDevices.firstWhere((device) => device.isCurrentDevice);
    } catch (e) {
      print('No current device found: $e');
      return userDevices.isNotEmpty ? userDevices.first : null;
    }
  }

  // Méthode pour obtenir un appareil par son ID
  UserDevice? getDeviceById(String deviceId) {
    try {
      return userDevices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      print('Error finding device by ID: $e');
      return null;
    }
  }

  // Méthode pour obtenir les appareils par plateforme
  List<UserDevice> getDevicesByPlatform(String platform) {
    return userDevices.where((device) => device.platform.toLowerCase() == platform.toLowerCase()).toList();
  }

  // Méthode pour vérifier si un appareil existe avec ce token FCM
  bool deviceExistsWithToken(String fcmToken) {
    return userDevices.any((device) => device.fcmToken == fcmToken);
  }
}*/
/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/user_devices_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/devices.dart';

void exampleDeviceCrudUsage() async {
  // ⚙️ Étape 1 : Initialisation du controller
  Get.put(UserDevicesController());
  final controller = Get.find<UserDevicesController>();

  final userId = FirebaseAuth.instance.currentUser!.uid;

  // 📲 Étape 2 : Enregistrement d’un appareil (ex : après login ou update FCM)
  final newDevice = UserDevice(
    id: '', // ID généré automatiquement
    fcmToken: 'FCM123456',
    platform: 'android',
    model: 'Pixel 7 Pro',
    osVersion: '13',
    appVersion: '1.1.0',
    lastUsedAt: DateTime.now(),
    ipAddress: '192.168.1.10',
    isCurrentDevice: true,
    deviceName: 'Mon Pixel Pro',
  );

  final registeredId = await controller.registerDevice(newDevice);
  print('📱 Appareil enregistré avec ID : $registeredId');

  // ✅ Étape 3 : Définir cet appareil comme appareil courant
  if (registeredId != null) {
    await controller.setCurrentDevice(registeredId);
    print('📍 Appareil courant défini : $registeredId');
  }

  // 🧾 Étape 4 : Lire les appareils de l’utilisateur (localement)
  final devices = controller.userDevices;
  for (var d in devices) {
    print('🔎 ${d.deviceName} – ${d.platform} (${d.appVersion})');
  }

  // 📍 Étape 5 : Récupérer l'appareil actuellement marqué comme actif
  final current = controller.getCurrentDevice();
  if (current != null) {
    print('📌 Appareil actuel : ${current.deviceName}');
  }

  // 🎯 Étape 6 : Mettre à jour un token FCM
  if (registeredId != null) {
    await controller.updateFcmToken(registeredId, 'NEW_FCM_TOKEN_999');
    print('🔁 Token FCM mis à jour');
  }

  // 🔄 Étape 7 : Supprimer un ancien appareil
  if (registeredId != null) {
    await controller.deleteDevice(registeredId);
    print('🗑️ Appareil supprimé');
  }

  // 🧪 Étape 8 : Vérifier si un token FCM existe déjà
  final exists = controller.deviceExistsWithToken('FCM123456');
  print('🔍 Token FCM déjà utilisé ? $exists');

  // 🧱 Étape 9 : Initialisation MVP (ex: à la création de compte)
  await controller.createEmptyDeviceDoc(userId);
  print('🆕 Appareil par défaut enregistré');

  // 🧠 Étape 10 : Obtenir tous les appareils Android
  final androidDevices = controller.getDevicesByPlatform('android');
  print('📊 Android actifs : ${androidDevices.length}');
}
*/