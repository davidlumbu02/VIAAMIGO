import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un badge obtenu par l'utilisateur
class UserBadge {
  final String id; // ID unique du badge de l'utilisateur
  final String badgeId; // Référence au badge principal
  final DateTime earnedAt; // Date d'obtention
  final bool displayed; // Si affiché sur le profil
  final int progress; // Progression (0-100)
  final int level; // Niveau du badge

  /// Constructeur principal
  const UserBadge({
    required this.id,
    required this.badgeId,
    required this.earnedAt,
    this.displayed = true,
    this.progress = 100,
    this.level = 1,
  });

  /// Crée une instance à partir d'un document Firestore
  factory UserBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadge(
      id: doc.id,
      badgeId: data['badgeId'] ?? '',
      earnedAt: data['earnedAt'] != null 
          ? (data['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
      displayed: data['displayed'] ?? true,
      progress: data['progress'] ?? 100,
      level: data['level'] ?? 1,
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'displayed': displayed,
      'progress': progress,
      'level': level,
    };
  }

  /// Crée une copie modifiée de cette instance
  UserBadge copyWith({
    String? badgeId,
    DateTime? earnedAt,
    bool? displayed,
    int? progress,
    int? level,
  }) {
    return UserBadge(
      id: id,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      displayed: displayed ?? this.displayed,
      progress: progress ?? this.progress,
      level: level ?? this.level,
    );
  }

  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badgeId': badgeId,
      'earnedAt': earnedAt.toIso8601String(),
      'displayed': displayed,
      'progress': progress,
      'level': level,
    };
  }
  
  /// Crée une instance à partir de JSON
  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'],
      badgeId: json['badgeId'],
      earnedAt: DateTime.parse(json['earnedAt']),
      displayed: json['displayed'] ?? true,
      progress: json['progress'] ?? 100,
      level: json['level'] ?? 1,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBadge && 
           other.id == id && 
           other.badgeId == badgeId;
  }
  
  @override
  int get hashCode => id.hashCode ^ badgeId.hashCode;
}

/// Service pour gérer les badges des utilisateurs
class UserBadgesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère tous les badges d'un utilisateur
  Future<List<UserBadge>> getUserBadges(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .get();
        
    return querySnapshot.docs
        .map((doc) => UserBadge.fromFirestore(doc))
        .toList();
  }
  
  /// Récupère tous les badges d'un utilisateur comme Stream
  Stream<List<UserBadge>> getUserBadgesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => UserBadge.fromFirestore(doc)).toList());
  }
  
  /// Vérifie si un utilisateur possède un badge spécifique
  Future<bool> userHasBadge(String userId, String badgeId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .where('badgeId', isEqualTo: badgeId)
        .limit(1)
        .get();
        
    return query.docs.isNotEmpty;
  }
  
  /// Attribue un nouveau badge à l'utilisateur
  Future<String> awardBadge(String userId, UserBadge badge) async {
    // Vérifier si le badge existe déjà
    final existingBadge = await _getExistingBadge(userId, badge.badgeId);
    
    if (existingBadge != null) {
      // Mettre à jour le badge existant (progression ou niveau)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(existingBadge.id)
          .update({
            'progress': badge.progress,
            'level': badge.level > existingBadge.level ? badge.level : existingBadge.level,
            'displayed': badge.displayed,
          });
      return existingBadge.id;
    } else {
      // Créer un nouveau badge
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .add(badge.toFirestore());
      return docRef.id;
    }
  }
  
  /// Récupère un badge existant par son badgeId
  Future<UserBadge?> _getExistingBadge(String userId, String badgeId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .where('badgeId', isEqualTo: badgeId)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return UserBadge.fromFirestore(query.docs.first);
    }
    
    return null;
  }
  
  /// Met à jour la progression d'un badge
  Future<void> updateBadgeProgress(String userId, String badgeId, int progress) async {
    final existingBadge = await _getExistingBadge(userId, badgeId);
    
    if (existingBadge != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(existingBadge.id)
          .update({'progress': progress});
    }
  }
  
  /// Toggle l'affichage d'un badge
  Future<void> toggleBadgeDisplay(String userId, String userBadgeId, bool displayed) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(userBadgeId)
        .update({'displayed': displayed});
  }
  
  /// Supprime un badge
  Future<void> revokeBadge(String userId, String userBadgeId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(userBadgeId)
        .delete();
  }
  /// 🏅 Initialise un badge utilisateur par défaut (MVP) dans `/users/{uid}/badges/{autoId}`
/// 📌 À utiliser lors du premier login ou onboarding
Future<void> createEmptyBadgeDoc(String userId) async {
  try {
    // 🔗 Référence Firestore avec ID auto-généré
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(); // ✅ Pas d’ID fixe ("placeholder")

    // 🧱 Création d’un badge par défaut (ex: "first_login")
    final badge = UserBadge(
      id: docRef.id,           // 🆔 On injecte l’ID auto-généré dans l’objet
      badgeId: 'first_login',  // 🏁 Badge symbolique du premier accès
      earnedAt: DateTime.now(),// 📅 Obtenu maintenant
      displayed: true,         // ✅ Affiché sur le profil
      progress: 100,           // 📊 Déjà complété
      level: 1,                // 🔢 Niveau initial
    );

    // 📤 Sauvegarde dans Firestore
    await docRef.set(badge.toFirestore());
  } catch (e) {
    print('Error creating default badge for $userId: $e');
    rethrow;
  }
}

/*
  //mvp
  /// Initialise un badge par défaut pour le MVP
Future<void> createEmptyBadgeDoc(String userId) async {
  final badge = UserBadge(
    id: 'placeholder',
    badgeId: 'first_login',
    earnedAt: DateTime.now(),
    displayed: true,
    progress: 100,
    level: 1,
  );

  await _firestore
      .collection('users')
      .doc(userId)
      .collection('badges')
      .doc('placeholder') // ou utilise .add(...) pour un ID auto
      .set(badge.toFirestore());
}
*/
}