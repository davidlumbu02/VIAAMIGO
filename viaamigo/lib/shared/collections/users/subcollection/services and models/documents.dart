// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un document d'identité de l'utilisateur
class UserDocument {
  final String id; // ID unique du document
  final String type; // Type de document
  final String url; // URL sécurisée du document stocké
  final bool verified; // Statut de vérification
  final DateTime? verifiedAt; // Date de vérification
  final String? verifiedBy; // Admin ayant vérifié
  final DateTime uploadedAt; // Date d'upload
  final DateTime? expiryDate; // Date d'expiration du document
  final String? rejectionReason; // Raison du rejet
  final String? documentNumber; // Numéro du document (crypté)

  /// Constructeur principal
  const UserDocument({
    required this.id,
    required this.type,
    required this.url,
    this.verified = false,
    this.verifiedAt,
    this.verifiedBy,
    required this.uploadedAt,
    this.expiryDate,
    this.rejectionReason,
    this.documentNumber,
  });

  /// Crée une instance à partir d'un document Firestore
  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDocument(
      id: doc.id,
      type: data['type'] ?? 'ID',
      url: data['url'] ?? '',
      verified: data['verified'] ?? false,
      verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
      verifiedBy: data['verifiedBy'],
      uploadedAt: data['uploadedAt'] != null 
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiryDate: data['expiryDate'] != null ? (data['expiryDate'] as Timestamp).toDate() : null,
      rejectionReason: data['rejectionReason'],
      documentNumber: data['documentNumber'],
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'url': url,
      'verified': verified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'rejectionReason': rejectionReason,
      'documentNumber': documentNumber,
    };
  }

  /// Crée une copie modifiée de cette instance
  UserDocument copyWith({
    String? type,
    String? url,
    bool? verified,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? uploadedAt,
    DateTime? expiryDate,
    String? rejectionReason,
    String? documentNumber,
  }) {
    return UserDocument(
      id: id,
      type: type ?? this.type,
      url: url ?? this.url,
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documentNumber: documentNumber ?? this.documentNumber,
    );
  }

  /// Convertit en JSON pour le stockage local
  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'verified': verified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'documentNumber': documentNumber,
    };
  }
  
  /// Crée une instance à partir de JSON
  factory UserDocument.fromJson(Map<String, dynamic> json) {
    return UserDocument(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      verified: json['verified'] ?? false,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      verifiedBy: json['verifiedBy'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      rejectionReason: json['rejectionReason'],
      documentNumber: json['documentNumber'],
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDocument && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Service pour gérer les documents d'identité des utilisateurs
class UserDocumentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère tous les documents d'un utilisateur
  Future<List<UserDocument>> getUserDocuments(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .get();
        
    return querySnapshot.docs
        .map((doc) => UserDocument.fromFirestore(doc))
        .toList();
  }
  
  /// Récupère tous les documents d'un utilisateur comme Stream
  Stream<List<UserDocument>> getUserDocumentsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => UserDocument.fromFirestore(doc)).toList());
  }
  
  /// Récupère un document spécifique
  Future<UserDocument?> getUserDocument(String userId, String documentId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(documentId)
        .get();
        
    return doc.exists ? UserDocument.fromFirestore(doc) : null;
  }
  
  /// Ajoute un nouveau document
  Future<String> addUserDocument(String userId, UserDocument document) async {
    // Création d'un nouvel ID unique
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc();
        
    // Sauvegarde des données sans l'ID (il sera fourni par la référence)
    final Map<String, dynamic> data = document.toFirestore();
    await docRef.set(data);
    
    return docRef.id;
  }
  
  /// Met à jour un document existant
  Future<void> updateUserDocument(String userId, UserDocument document) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(document.id)
        .update(document.toFirestore());
  }
  
  /// Supprime un document
  Future<void> deleteUserDocument(String userId, String documentId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(documentId)
        .delete();
  }
  /// 🛠️ Crée un document d'identité vide lors de l'inscription (MVP)
/// 📌 Ajouté dans /users/{uid}/documents/{generated_id} avec un contenu par défaut
Future<void> createEmptyUserDocument(String userId) async {
  try {
    // 🔗 Génère une référence avec ID automatique
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(); // ✅ Firestore génère un ID unique automatiquement

    // 🧱 Document d'identité par défaut (non vérifié)
    final defaultDoc = UserDocument(
      id: docRef.id, // 🆔 On injecte l'ID Firestore dans le modèle
      type: 'ID', // 🪪 Type générique (ex: carte d'identité)
      url: '', // 🌐 URL vide car non encore uploadé
      verified: false, // 🔒 Non vérifié
      verifiedAt: null,
      verifiedBy: null,
      uploadedAt: DateTime.now(), // 📅 Date de création
      expiryDate: DateTime.now().add(const Duration(days: 365)), // ⏳ Expiration 1 an plus tard
      rejectionReason: null,
      documentNumber: null, // 🔢 Numéro du document non fourni
    );

    // 📤 Enregistrement dans Firestore
    await docRef.set(defaultDoc.toFirestore());
  } catch (e) {
    print('Error creating empty user document for $userId: $e');
    rethrow;
  }
}

/*
  //mvp
  /// Ajoute un document placeholder par défaut lors de l'inscription
Future<void> createEmptyUserDocument(String userId) async {
  final defaultDoc = UserDocument(
    id: 'placeholder_doc',
    type: 'ID',
    url: '',
    verified: false,
    verifiedAt: null,
    verifiedBy: null,
    uploadedAt: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 365)),
    rejectionReason: null,
    documentNumber: null,
  );

  await _firestore
      .collection('users')
      .doc(userId)
      .collection('documents')
      .doc('placeholder_doc')
      .set(defaultDoc.toFirestore());
}
*/
}