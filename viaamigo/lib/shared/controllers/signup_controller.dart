import 'package:get/get.dart';

class SignupController extends GetxController {
  final RxMap<String, dynamic> data = <String, dynamic>{}.obs;

  /// Étape actuelle sous forme d'int (facultatif)
  final RxInt currentStep = 0.obs;

  /// Route de l’étape actuelle pour reprendre après redémarrage
  final RxString currentStepRoute = ''.obs;

  final RxBool isVerified = false.obs;
  final RxBool isEmailVerified = false.obs;
  final RxBool isPhoneVerified = false.obs;

  void updateField(String key, dynamic value) {
    data[key] = value;
  }

  dynamic getField(String key) => data[key];

  bool hasField(String key) =>
      data.containsKey(key) &&
      data[key] != null &&
      data[key].toString().isNotEmpty;

  void resetAll() {
    data.clear();
    currentStep.value = 0;
    currentStepRoute.value = '/signup/name'; // ✅ Réinitialiser la route aussi
    isVerified.value = false;
    isEmailVerified.value = false;
    isPhoneVerified.value = false;
  }

  Map<String, dynamic> toMap() => data;

  static const List<String> standardFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'birthday',
    'role',
    'provider',
    'password',
    'profilePicture',
    'createdAt',
    'emailVerified',
    'phoneVerified',
    'idDocumentType',
    'idDocumentUrl',
    'isIdVerified',
    'vehicleType',
    'vehiclePlate',
    'vehiclePicture',
    'isDriverLicenseVerified',
    'isProfessional',
    'companyName',
    'acceptsTerms',
    'refuseOffers',
    'profilepictureUrl',
    'language',
    'theme'
  ];

  bool get isComplete => standardFields.every((field) => hasField(field));
}

final SignupController signupController = Get.put(SignupController());

/*import 'package:get/get.dart';

/// Contrôleur centralisé pour gérer les données d'inscription multi-étapes.
/// Utilisé avec GetX pour rendre chaque champ réactif, facile à mettre à jour et persister.
class SignupController extends GetxController {
  // Données d'inscription stockées dynamiquement
  final RxMap<String, dynamic> data = <String, dynamic>{}.obs;

  /// Mémorise l'étape actuelle (utile pour du routing ou une progress bar)
  final RxInt currentStep = 0.obs;

  /// Indique si l'utilisateur a terminé la vérification SMS ou email
  final RxBool isVerified = false.obs;

  /// Vérification email et téléphone séparée
  final RxBool isEmailVerified = false.obs;
  final RxBool isPhoneVerified = false.obs;

  /// Mise à jour ou ajout d'une valeur
  void updateField(String key, dynamic value) {
    data[key] = value;
  }

  /// Accès à un champ
  dynamic getField(String key) => data[key];

  /// Vérifie si un champ est rempli
  bool hasField(String key) => data.containsKey(key) && data[key] != null && data[key].toString().isNotEmpty;

  /// Réinitialise toutes les données (ex: retour au début ou changement de compte)
  void resetAll() {
    data.clear();
    currentStep.value = 0;
    isVerified.value = false;
    isEmailVerified.value = false;
    isPhoneVerified.value = false;
  }

  /// Utilisé pour le résumé final avant validation
  Map<String, dynamic> toMap() => data;

  /// Liste des champs standards à prévoir (tu peux ajouter d'autres au besoin)
  static const List<String> standardFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'birthday',
    'role',
    'provider',
    'password',
    'profilePicture',
    'createdAt',
    'emailVerified',
    'phoneVerified',
    'idDocumentType',
    'idDocumentUrl',
    'isIdVerified',
    'vehicleType',
    'vehiclePlate',
    'vehiclePicture',
    'isDriverLicenseVerified',
    'isProfessional',
    'companyName',
    'acceptsTerms',
    'refuseOffers',
    'profilepictureUrl',
    'password',
    'language',
    'theme'
    'currentStepRoute'
  ];

  /// Fonction optionnelle : vérifie si tous les champs essentiels sont remplis
  bool get isComplete => standardFields.every((field) => hasField(field));
}

/// Injecte globalement le contrôleur (à faire dans main.dart)
final SignupController signupController = Get.put(SignupController());
*/