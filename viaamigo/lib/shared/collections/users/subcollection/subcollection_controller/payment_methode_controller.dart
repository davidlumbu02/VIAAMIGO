// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/payment_methodes.dart';

/// 🧠 Contrôleur GetX pour gérer les méthodes de paiement
class PaymentMethodsController extends GetxController {
  final PaymentMethodsService _service = PaymentMethodsService();

  /// Liste réactive des méthodes de paiement
  final RxList<PaymentMethod> paymentMethods = <PaymentMethod>[].obs;

  /// Méthode par défaut sélectionnée
  final Rx<PaymentMethod?> defaultMethod = Rx<PaymentMethod?>(null);

  /// État de chargement
  final RxBool isLoading = false.obs;

  /// Message d’erreur
  final RxString error = ''.obs;

  /// Chargement initial des méthodes de paiement
  Future<void> loadPaymentMethods() async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final all = await _service.getPaymentMethods(uid);
      final def = await _service.getDefaultPaymentMethod(uid);
      paymentMethods.assignAll(all);
      defaultMethod.value = def;
    } catch (e) {
      error.value = 'Erreur de chargement : ${e.toString()}';
      print(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream pour la réactivité en temps réel (utilisable dans UI)
  Stream<List<PaymentMethod>> getPaymentMethodsStream() {
    final uid = _getUserIdOrNull();
    if (uid == null) return const Stream.empty();
    return _service.getPaymentMethodsStream(uid);
  }

  /// Ajoute une méthode de paiement
  Future<void> addPaymentMethod(PaymentMethod method) async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    try {
      await _service.addPaymentMethod(uid, method);
      await loadPaymentMethods();
    } catch (e) {
      error.value = 'Ajout échoué : ${e.toString()}';
      print(error.value);
    }
  }

  /// Met à jour une méthode de paiement
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    try {
      await _service.updatePaymentMethod(uid, method);
      await loadPaymentMethods();
    } catch (e) {
      error.value = 'Mise à jour échouée : ${e.toString()}';
    }
  }

  /// Supprime une méthode
  Future<void> deletePaymentMethod(String methodId) async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    try {
      await _service.deletePaymentMethod(uid, methodId);
      await loadPaymentMethods();
    } catch (e) {
      error.value = 'Suppression échouée : ${e.toString()}';
    }
  }

  /// Définit une méthode comme par défaut
  Future<void> setAsDefault(String methodId) async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    try {
      await _service.setAsDefaultPaymentMethod(uid, methodId);
      await loadPaymentMethods();
    } catch (e) {
      error.value = 'Erreur de définition du mode par défaut : ${e.toString()}';
    }
  }

  /// Initialise une méthode vide pour MVP (test/inscription)
  Future<void> createEmptyPaymentMethod() async {
    final uid = _getUserIdOrNull();
    if (uid == null) return;

    try {
      await _service.createEmptyPaymentMethod(uid);
      await loadPaymentMethods();
    } catch (e) {
      error.value = 'Erreur d\'initialisation : ${e.toString()}';
    }
  }

  /// 🔍 Récupère une méthode par son ID
  PaymentMethod? getMethodById(String id) {
    return paymentMethods.firstWhereOrNull((m) => m.id == id);
  }

  /// 🔎 Vérifie si l’utilisateur a déjà une méthode de paiement
  bool hasMethods() {
    return paymentMethods.isNotEmpty;
  }

  /// 🔐 Récupération sécurisée de l'UID
  String? _getUserIdOrNull() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Réinitialise l’état du contrôleur
  void reset() {
    paymentMethods.clear();
    defaultMethod.value = null;
    isLoading.value = false;
    error.value = '';
  }
}
/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/payment_methods_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/payment_methodes.dart';

void examplePaymentMethodsCrudUsage() async {
  // ⚙️ Étape 1 : Initialisation du contrôleur GetX (à faire une fois)
  Get.put(PaymentMethodsController());
  final controller = Get.find<PaymentMethodsController>();

  // 🔐 Récupération de l'utilisateur connecté
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // 🧱 Étape 2 : Initialiser une méthode de paiement MVP à la création du compte
  await controller.createEmptyPaymentMethod();
  print('✅ Méthode de paiement MVP vide initialisée');

  // ➕ Étape 3 : Ajouter une nouvelle méthode réelle (ex: carte Visa)
  final newMethod = PaymentMethod(
    id: '', // généré automatiquement
    type: 'card',
    last4: '4242',
    expMonth: 12,
    expYear: 2026,
    brand: 'Visa',
    holderName: 'Jean Dupont',
    isDefault: false,
    stripePaymentMethodId: 'pm_test_visa4242',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await controller.addPaymentMethod(newMethod);
  print('💳 Nouvelle méthode de paiement ajoutée (Visa 4242)');

  // 🔁 Étape 4 : Recharger les méthodes de paiement
  await controller.loadPaymentMethods();
  print('📦 ${controller.paymentMethods.length} méthode(s) chargée(s)');

  // 🖋️ Étape 5 : Mettre à jour le nom du titulaire d’une carte existante
  final methodToUpdate = controller.paymentMethods.firstWhereOrNull((m) => m.brand == 'Visa');
  if (methodToUpdate != null) {
    final updatedMethod = methodToUpdate.copyWith(holderName: 'Marie Curie');
    await controller.updatePaymentMethod(updatedMethod);
    print('✏️ Carte mise à jour (nouveau nom : Marie Curie)');
  }

  // ⭐ Étape 6 : Définir une méthode comme par défaut
  final firstMethod = controller.paymentMethods.firstOrNull;
  if (firstMethod != null) {
    await controller.setAsDefault(firstMethod.id);
    print('⭐ Carte définie comme par défaut : ${firstMethod.last4}');
  }

  // 🔎 Étape 7 : Lire une méthode de paiement par ID
  if (firstMethod != null) {
    final found = controller.getMethodById(firstMethod.id);
    if (found != null) {
      print('🔍 Méthode trouvée : ${found.brand} – ${found.holderName}');
    }
  }

  // 🗑️ Étape 8 : Supprimer une méthode spécifique
  final methodToDelete = controller.paymentMethods.lastOrNull;
  if (methodToDelete != null) {
    await controller.deletePaymentMethod(methodToDelete.id);
    print('🗑️ Méthode supprimée : ${methodToDelete.brand} ${methodToDelete.last4}');
  }

  // 🧪 Étape 9 : Vérifier s’il reste des méthodes enregistrées
  final hasAny = controller.hasMethods();
  print(hasAny
      ? '📂 Il reste des méthodes de paiement actives.'
      : '📭 Plus aucune méthode disponible.');

  // 🧹 Étape 10 : Réinitialiser entièrement le contrôleur (utile lors d’un logout)
  controller.reset();
  print('🔄 Contrôleur des paiements réinitialisé');
}
*/