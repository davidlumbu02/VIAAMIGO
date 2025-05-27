// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/badges.dart'; // Assurez-vous que le chemin d'import est correct
import 'package:viaamigo/shared/services/auth_service.dart';

/// Contrôleur pour gérer les badges de l'utilisateur
class UserBadgesController extends GetxController {
  // Services injectés
  final UserBadgesService _badgesService = UserBadgesService();
  final AuthService _authService = Get.find<AuthService>();

  // Variables observables
  final RxList<UserBadge> userBadges = <UserBadge>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'authentification
    ever(_authService.firebaseUser, _onUserChanged);

    // Si l'utilisateur est connecté, charger ses badges
    if (_authService.firebaseUser.value != null) {
      loadUserBadges();
    }
  }

  // Méthode pour réagir aux changements d'utilisateur
  void _onUserChanged(user) async {
    if (user != null) {
      loadUserBadges();
    } else {
      // Réinitialiser les badges quand l'utilisateur est déconnecté
      userBadges.clear();
    }
  }

  // Méthode pour charger les badges de l'utilisateur
  Future<void> loadUserBadges() async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final badges = await _badgesService.getUserBadges(userId);
      userBadges.assignAll(badges);
    } catch (e) {
      error.value = 'Error loading user badges: $e';
      print('Error loading user badges: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour attribuer un badge à l'utilisateur
  Future<String?> awardBadge(UserBadge badge) async {
    if (_authService.firebaseUser.value == null) return null;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final badgeId = await _badgesService.awardBadge(userId, badge);
      await loadUserBadges(); // Recharger la liste
      print('Badge awarded successfully');
      return badgeId;
    } catch (e) {
      error.value = 'Error awarding badge: $e';
      print('Error awarding badge: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour mettre à jour la progression d'un badge
  Future<void> updateBadgeProgress(String badgeId, int progress) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _badgesService.updateBadgeProgress(userId, badgeId, progress);
      await loadUserBadges(); // Recharger la liste
      print('Badge progress updated successfully');
    } catch (e) {
      error.value = 'Error updating badge progress: $e';
      print('Error updating badge progress: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour basculer l'affichage d'un badge
  Future<void> toggleBadgeDisplay(String userBadgeId, bool displayed) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _badgesService.toggleBadgeDisplay(userId, userBadgeId, displayed);
      await loadUserBadges(); // Recharger la liste
      print('Badge display toggled successfully');
    } catch (e) {
      error.value = 'Error toggling badge display: $e';
      print('Error toggling badge display: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour révoquer un badge
  Future<void> revokeBadge(String userBadgeId) async {
    if (_authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      await _badgesService.revokeBadge(userId, userBadgeId);
      await loadUserBadges(); // Recharger la liste
      print('Badge revoked successfully');
    } catch (e) {
      error.value = 'Error revoking badge: $e';
      print('Error revoking badge: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour vérifier si un utilisateur possède un badge
  Future<bool> userHasBadge(String badgeId) async {
    if (_authService.firebaseUser.value == null) return false;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      return await _badgesService.userHasBadge(userId, badgeId);
    } catch (e) {
      print('Error checking if user has badge: $e');
      return false;
    }
  }

  // Méthode pour initialiser avec un badge par défaut
  Future<void> createEmptyBadgeDoc(String userId) async {
    isLoading.value = true;
    error.value = '';

    try {
      await _badgesService.createEmptyBadgeDoc(userId);
      print('✅ Badge par défaut initialisé pour l\'utilisateur: $userId');
    } catch (e) {
      error.value = 'Error initializing default badge: $e';
      print('❌ Erreur lors de l\'initialisation du badge par défaut: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour obtenir les badges affichés
  List<UserBadge> getDisplayedBadges() {
    return userBadges.where((badge) => badge.displayed).toList();
  }

  // Méthode pour obtenir un badge par son ID
  UserBadge? getBadgeById(String userBadgeId) {
    try {
      return userBadges.firstWhere((badge) => badge.id == userBadgeId);
    } catch (e) {
      print('Error finding badge by ID: $e');
      return null;
    }
  }

  // Méthode pour obtenir un badge par son badgeId
  UserBadge? getBadgeByBadgeId(String badgeId) {
    try {
      return userBadges.firstWhere((badge) => badge.badgeId == badgeId);
    } catch (e) {
      print('Error finding badge by badgeId: $e');
      return null;
    }
  }

  // Méthode pour obtenir le nombre de badges de l'utilisateur
  int getBadgeCount() {
    return userBadges.length;
  }
}
/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/controllers/user_badges_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/badges.dart';

/// Exemple d'un autre controller qui interagit avec les badges
class ProfileController extends GetxController {
  final UserBadgesController _badgesController = Get.find<UserBadgesController>();

  final RxString statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOrInitBadges();
  }

  /// Charger les badges ou initialiser si aucun
  Future<void> _loadOrInitBadges() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final hasVerifiedBadge = await _badgesController.userHasBadge('verified_profile');

    if (!hasVerifiedBadge) {
      await _badgesController.createEmptyBadgeDoc(userId);
      statusMessage.value = '🆕 Badges initialisés pour le nouvel utilisateur.';
    } else {
      await _badgesController.loadUserBadges();
      statusMessage.value = '📦 Badges chargés depuis Firestore.';
    }
  }

  /// Attribue un badge manuellement
  Future<void> awardVerifiedBadge() async {
    final badge = UserBadge(
      id: '',
      badgeId: 'verified_profile',
      earnedAt: DateTime.now(),
      displayed: true,
      progress: 100,
      level: 1,
    );

    final badgeId = await _badgesController.awardBadge(badge);
    statusMessage.value = badgeId != null
        ? '🏅 Badge "verified_profile" attribué avec succès.'
        : '❌ Échec d\'attribution du badge.';
  }

  /// Incrémente la progression d’un badge déjà attribué
  Future<void> incrementProgress(String badgeId, int increment) async {
    final badge = _badgesController.getBadgeById(badgeId);
    if (badge == null) {
      statusMessage.value = '❌ Badge introuvable.';
      return;
    }

    final newProgress = (badge.progress + increment).clamp(0, 100);
    await _badgesController.updateBadgeProgress(badgeId, newProgress);
    statusMessage.value = '📈 Progression mise à jour à $newProgress%.';
  }

  /// Basculer l’affichage d’un badge
  Future<void> toggleBadgeVisibility(String badgeId) async {
    final badge = _badgesController.getBadgeById(badgeId);
    if (badge != null) {
      await _badgesController.toggleBadgeDisplay(badgeId, !badge.displayed);
      statusMessage.value =
          badge.displayed ? '🙈 Badge masqué.' : '🎖️ Badge affiché.';
    }
  }

  /// Supprimer un badge de l’utilisateur
  Future<void> removeBadge(String badgeId) async {
    await _badgesController.revokeBadge(badgeId);
    statusMessage.value = '🗑️ Badge supprimé.';
  }

  /// Lire les badges pour UI
  List<UserBadge> get visibleBadges => _badgesController.getDisplayedBadges();

  /// Obtenir un badge spécifique pour usage ciblé
  UserBadge? getBadge(String badgeId) => _badgesController.getBadgeByBadgeId(badgeId);

  /// Nombre total de badges (utile en statistiques/profil)
  int get totalBadges => _badgesController.getBadgeCount();
}
*/