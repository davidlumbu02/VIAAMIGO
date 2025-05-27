// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/documents.dart';
import 'package:viaamigo/shared/services/auth_service.dart';

/// Contrôleur pour gérer les documents d'identité de l'utilisateur
class UserDocumentsController extends GetxController {
  // Services injectés
  final UserDocumentsService _documentsService = UserDocumentsService();
  final AuthService _authService = Get.find<AuthService>();

  // Variables observables
  final RxList<UserDocument> userDocuments = <UserDocument>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'authentification
    ever(_authService.firebaseUser, _onUserChanged);

    // Si l'utilisateur est connecté, charger ses documents
    if (_authService.firebaseUser.value != null) {
      loadUserDocuments();
    }
  }

  // Méthode pour réagir aux changements d'utilisateur
  void _onUserChanged(user) async {
    if (user != null) {
      loadUserDocuments();
    } else {
      // Réinitialiser les documents quand l'utilisateur est déconnecté
      userDocuments.clear();
    }
  }

  // Méthode pour charger les documents de l'utilisateur
  Future<void> loadUserDocuments() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final documents = await _documentsService.getUserDocuments(userId);
      userDocuments.assignAll(documents);
    } catch (e) {
      error.value = 'Error loading user documents: $e';
      print('Error loading user documents: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour ajouter un nouveau document
  Future<String?> addUserDocument(UserDocument document) async {
    if (_authService.firebaseUser.value == null) return null;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final docId = await _documentsService.addUserDocument(userId, document);
      await loadUserDocuments(); // Recharger la liste
      print('User document added successfully');
      return docId;
    } catch (e) {
      error.value = 'Error adding user document: $e';
      print('Error adding user document: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour mettre à jour un document
  Future<void> updateUserDocument(UserDocument document) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _documentsService.updateUserDocument(userId, document);
      await loadUserDocuments(); // Recharger la liste
      print('User document updated successfully');
    } catch (e) {
      error.value = 'Error updating user document: $e';
      print('Error updating user document: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour supprimer un document
  Future<void> deleteUserDocument(String documentId) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _documentsService.deleteUserDocument(userId, documentId);
      await loadUserDocuments(); // Recharger la liste
      print('User document deleted successfully');
    } catch (e) {
      error.value = 'Error deleting user document: $e';
      print('Error deleting user document: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour récupérer un document spécifique
  Future<UserDocument?> getUserDocument(String documentId) async {
    if (_authService.firebaseUser.value == null) return null;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final doc = await _documentsService.getUserDocument(userId, documentId);
      return doc;
    } catch (e) {
      error.value = 'Error getting user document: $e';
      print('Error getting user document: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour initialiser avec un document vide
  Future<void> createEmptyUserDocument(String userId) async {
    isLoading.value = true;
    error.value = '';

    try {
      await _documentsService.createEmptyUserDocument(userId);
      print('✅ Document utilisateur initialisé pour l\'utilisateur: $userId');
    } catch (e) {
      error.value = 'Error initializing user document: $e';
      print('❌ Erreur lors de l\'initialisation du document utilisateur: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour vérifier si un utilisateur a des documents
  Future<bool> hasDocuments() async {
    if (_authService.firebaseUser.value == null) return false;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final documents = await _documentsService.getUserDocuments(userId);
      return documents.isNotEmpty;
    } catch (e) {
      print('Error checking if user has documents: $e');
      return false;
    }
  }

  // Méthode pour vérifier si un utilisateur a un document vérifié
  bool hasVerifiedDocuments() {
    return userDocuments.any((doc) => doc.verified);
  }

  // Méthode pour obtenir tous les documents d'un certain type
  List<UserDocument> getDocumentsByType(String type) {
    return userDocuments.where((doc) => doc.type == type).toList();
  }
  
  // Méthode pour obtenir un document par son ID
  UserDocument? getDocumentById(String documentId) {
    try {
      return userDocuments.firstWhere((doc) => doc.id == documentId);
    } catch (e) {
      print('Error finding document by ID: $e');
      return null;
    }
  }
}

/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/user_documents_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/documents.dart';

void exampleUserDocumentsUsage() async {
  // ⚙️ Initialisation (à faire une fois, typiquement dans les Bindings)
  Get.put(UserDocumentsController());

  final documentController = Get.find<UserDocumentsController>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Charger tous les documents de l'utilisateur connecté
  await documentController.loadUserDocuments();

  // ➕ Ajouter un nouveau document
  final newDocument = UserDocument(
    id: '', // sera généré automatiquement
    type: 'permit',
    url: 'https://secure-storage.com/scan123.jpg',
    verified: false,
    verifiedAt: null,
    verifiedBy: null,
    uploadedAt: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 730)),
    rejectionReason: null,
    documentNumber: 'ENC123456',
  );

  final docId = await documentController.addUserDocument(newDocument);
  print('📄 Document ajouté avec ID: $docId');

  // ✏️ Modifier un document existant
  final existing = documentController.getDocumentById(docId!);
  if (existing != null) {
    final updated = existing.copyWith(
      verified: true,
      verifiedAt: DateTime.now(),
      verifiedBy: 'admin_001',
    );
    await documentController.updateUserDocument(updated);
  }

  // 🗑 Supprimer un document
  await documentController.deleteUserDocument(docId);

  // 📄 Initialiser un document vide lors de l’inscription
  await documentController.createEmptyUserDocument(userId);

  // 🔍 Vérifier si l'utilisateur a au moins un document
  final hasDocs = await documentController.hasDocuments();
  print('🧾 Documents présents ? $hasDocs');

  // 🔎 Vérifier s’il existe un document vérifié
  final hasVerified = documentController.hasVerifiedDocuments();
  print('✅ Document vérifié présent ? $hasVerified');

  // 📂 Obtenir tous les documents de type 'ID'
  final idDocs = documentController.getDocumentsByType('ID');
  print('🗂 Nombre de documents ID : ${idDocs.length}');

  // 📄 Obtenir un document par son ID localement (déjà chargé)
  final doc = documentController.getDocumentById('placeholder_doc');
  if (doc != null) print('📑 Document trouvé : ${doc.type}');
}
*/