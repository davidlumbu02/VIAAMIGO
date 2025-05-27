// ignore_for_file: avoid_print



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

/// Service centralisé pour interagir avec la collection Firestore "users"
/// Contient des méthodes pour récupérer, créer, mettre à jour et enrichir les données utilisateurs
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Référence principale à la collection users
  CollectionReference get _usersRef => _firestore.collection('users');

  /// 🔍 Récupère un utilisateur par son UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ getUserById: $e');
      rethrow;
    }
  }
  /// 🔍 Vérifie si un utilisateur existe dans Firestore à partir de son UID
Future<bool> userExists(String uid) async {
  try {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  } catch (e) {
    print('❌ userExists: $e');
    rethrow;
  }
}

  /// 🔐 Récupère l'utilisateur actuellement connecté (via Firebase Auth)
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    return getUserById(currentUser.uid);
  }

  /// 🧱 Crée ou met à jour un utilisateur Firestore (fusion des données existantes)
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('❌ createOrUpdateUser: $e');
      rethrow;
    }
  }

  /// 🆕 Crée un utilisateur à partir des données minimales lors de l'inscription
  Future<void> createNewUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? profilePicture,
    required String role,
    String? provider,
    bool emailVerified = false,
    bool phoneVerified = true,
    String? language,
  }) async {
    try {
      final newUser = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        profilePicture: profilePicture,
        role: role,
        provider: provider ?? 'email',
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
        acceptsTerms: true,
        acceptedTermsVersion: '1.0',
        termsAcceptedAt: Timestamp.now(),
        createdAt: DateTime.now(),
        isPro: false,
        isBanned: false,
        status: 'active',
        stats: const UserStats(),
        walletBalance: 0.0,
        blockedUsers: [],
        verificationStatus: null,
        emergencyContact: null,
        location: null,
        currentTripId: null,
        referredBy: null,
        referralCode: null,
        appVersion: null,
        devicePlatform: null,
        deactivationReason: null,
        language: language,
        lastLoginAt: null,
      );

      await createOrUpdateUser(newUser);
    } catch (e) {
      print('❌ createNewUser: $e');
      rethrow;
    }
  }

  /// 🚫 Bloque un utilisateur en l'ajoutant à la liste des `blocked_users`
  Future<void> blockUser(String uid, String targetUid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>;
      final List<String> blocked = List<String>.from(data['blocked_users'] ?? []);

      if (!blocked.contains(targetUid)) {
        blocked.add(targetUid);
        await _usersRef.doc(uid).update({'blocked_users': blocked});
      }
    } catch (e) {
      print('❌ blockUser: $e');
      rethrow;
    }
  }

  /// ✅ Débloque un utilisateur en le retirant de la liste des `blocked_users`
  Future<void> unblockUser(String uid, String targetUid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>;
      final List<String> blocked = List<String>.from(data['blocked_users'] ?? []);

      if (blocked.contains(targetUid)) {
        blocked.remove(targetUid);
        await _usersRef.doc(uid).update({'blocked_users': blocked});
      }
    } catch (e) {
      print('❌ unblockUser: $e');
      rethrow;
    }
  }

  /// 💰 Met à jour le solde du portefeuille (+ ou -) et journalise dans `transactions`
  Future<void> updateWalletBalance(
    String uid,
    double amount, {
    bool isIncrement = true,
  }) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>;
      double current = (data['walletBalance'] ?? 0.0).toDouble();

      final newBalance = isIncrement ? current + amount : (current - amount).clamp(0.0, double.infinity);

      await _usersRef.doc(uid).update({'walletBalance': newBalance});

      await _firestore.collection('transactions').add({
        'userId': uid,
        'amount': isIncrement ? amount : -amount,
        'balanceBefore': current,
        'balanceAfter': newBalance,
        'type': isIncrement ? 'credit' : 'debit',
        'description': isIncrement
            ? 'Crédit ajouté au portefeuille'
            : 'Débit du portefeuille',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ updateWalletBalance: $e');
      rethrow;
    }
  }

  /// 📍 Met à jour la dernière position connue de l'utilisateur
  Future<void> updateLocation(String uid, double lat, double lng) async {
    try {
      final GeoPoint newLocation = GeoPoint(lat, lng);
      await _usersRef.doc(uid).update({
        'location': newLocation,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ updateLocation: $e');
      rethrow;
    }
  }

  /// 🔁 Active/désactive un utilisateur
  Future<void> updateStatus(String uid, String status) async {
    try {
      await _usersRef.doc(uid).update({'status': status});
    } catch (e) {
      print('❌ updateStatus: $e');
      rethrow;
    }
  }

  /// 🧠 Met à jour uniquement les champs personnalisés nécessaires
  Future<void> updateFields(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersRef.doc(uid).update(updates);
    } catch (e) {
      print('❌ updateFields: $e');
      rethrow;
    }
  }

  /// 🗑 Supprime un utilisateur de Firestore (⚠️ ne supprime pas Auth)
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
    } catch (e) {
      print('❌ deleteUser: $e');
      rethrow;
    }
  }
  /// 📡 Stream temps réel des transactions utilisateur, ordonnées par date
Stream<List<Map<String, dynamic>>> getUserTransactionsStream(String uid) {
  return _firestore
      .collection('transactions')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => doc.data()).toList());
}
/// 🔁 Récupère l'historique des transactions d'un utilisateur
Future<List<Map<String, dynamic>>> getUserTransactions(String uid) async {
  try {
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    print('❌ getUserTransactions: $e');
    rethrow;
  }
}

}

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';//import 'package:viaamigo/shared/collections/users/model/vehicule_model.dart';

import '../model/user_model.dart';


class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Référence à la collection users
  CollectionReference get _usersRef => _firestore.collection('users');

  // Obtenir un utilisateur par son ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // Obtenir l'utilisateur actuellement connecté
  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return getUserById(currentUser.uid);
    }
    return null;
  }

  // Créer ou mettre à jour un utilisateur
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }
  

  // Créer un nouvel utilisateur lors de l'inscription
  Future<void> createNewUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? profilePicture,
    required String role,
    String? provider ,
    bool emailVerified = false,
    
  }) async {
    try {
      // Créer l'utilisateur principal
      UserModel newUser = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        role: role,
        provider: provider,
        emailVerified: emailVerified,
        phoneVerified: true,
        acceptsTerms: true,
        acceptedTermsVersion: '1.0',
        termsAcceptedAt: Timestamp.now(),
        createdAt: DateTime.now(),
        isPro: false,
        isBanned: false,
        status: 'active',
        stats: UserStats(),
        walletBalance: 0,
        blockedUsers: [],
        profilePicture: profilePicture,
        
      );


    } catch (e) {
      print('Error creating new user: $e');
      rethrow;
    }
  }

// Bloquer un utilisateur
Future<void> blockUser(String uid, String targetUid) async {
  try {
    // Récupérer la liste actuelle des utilisateurs bloqués
    DocumentSnapshot userDoc = await _usersRef.doc(uid).get();
    List<String> blockedUsers = List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['blocked_users'] ?? []);
    
    // Vérifier si l'utilisateur est déjà bloqué
    if (!blockedUsers.contains(targetUid)) {
      blockedUsers.add(targetUid);
      
      // Mettre à jour la liste des utilisateurs bloqués
      await _usersRef.doc(uid).update({
        'blocked_users': blockedUsers,
      });
    }
  } catch (e) {
    print('Error blocking user: $e');
    rethrow;
  }
}

// Débloquer un utilisateur
Future<void> unblockUser(String uid, String targetUid) async {
  try {
    // Récupérer la liste actuelle des utilisateurs bloqués
    DocumentSnapshot userDoc = await _usersRef.doc(uid).get();
    List<String> blockedUsers = List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['blocked_users'] ?? []);
    
    // Retirer l'utilisateur de la liste des bloqués
    blockedUsers.remove(targetUid);
    
    // Mettre à jour la liste des utilisateurs bloqués
    await _usersRef.doc(uid).update({
      'blocked_users': blockedUsers,
    });
  } catch (e) {
    print('Error unblocking user: $e');
    rethrow;
  }
}

// Mettre à jour le solde du portefeuille
Future<void> updateWalletBalance(String uid, double amount, {bool isIncrement = true}) async {
  try {
    DocumentSnapshot userDoc = await _usersRef.doc(uid).get();
    double currentBalance = (userDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
    
    double newBalance;
    if (isIncrement) {
      newBalance = currentBalance + amount;
    } else {
      newBalance = currentBalance - amount;
      // S'assurer que le solde ne devient pas négatif
      if (newBalance < 0) newBalance = 0;
    }
    
    await _usersRef.doc(uid).update({
      'walletBalance': newBalance,
    });
    
    // Enregistrer la transaction pour historique
    await _firestore.collection('transactions').add({
      'userId': uid,
      'amount': isIncrement ? amount : -amount,
      'type': isIncrement ? 'credit' : 'debit',
      'balanceBefore': currentBalance,
      'balanceAfter': newBalance,
      'createdAt': FieldValue.serverTimestamp(),
      'description': isIncrement ? 'Crédit ajouté au portefeuille' : 'Débit du portefeuille',
    });
  } catch (e) {
    print('Error updating wallet balance: $e');
    rethrow;
  }
}

// Mettre à jour la position de l'utilisateur
Future<void> updateLocation(String uid, double latitude, double longitude) async {
  try {
    GeoPoint newLocation = GeoPoint(latitude, longitude);
    
    await _usersRef.doc(uid).update({
      'location': newLocation,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error updating location: $e');
    rethrow;
  }
}
}*/