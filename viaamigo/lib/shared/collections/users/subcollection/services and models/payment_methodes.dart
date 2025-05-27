import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une méthode de paiement de l'utilisateur
class PaymentMethod {
  final String id; // ID unique de la méthode de paiement
  final String type; // Type de paiement
  final String last4; // 4 derniers chiffres
  final int? expMonth; // Mois d'expiration
  final int? expYear; // Année d'expiration
  final String? brand; // Marque de la carte
  final String holderName; // Nom du titulaire
  final bool isDefault; // Méthode par défaut
  final String? stripePaymentMethodId; // ID externe (Stripe)
  final DateTime createdAt; // Date d'ajout
  final DateTime updatedAt; // Dernière mise à jour

  /// Constructeur principal
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    this.expMonth,
    this.expYear,
    this.brand,
    required this.holderName,
    this.isDefault = false,
    this.stripePaymentMethodId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une instance à partir d'un document Firestore
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      type: data['type'] ?? 'card',
      last4: data['last4'] ?? '0000',
      expMonth: data['expMonth'],
      expYear: data['expYear'],
      brand: data['brand'],
      holderName: data['holderName'] ?? '',
      isDefault: data['isDefault'] ?? false,
      stripePaymentMethodId: data['stripePaymentMethodId'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'brand': brand,
      'holderName': holderName,
      'isDefault': isDefault,
      'stripePaymentMethodId': stripePaymentMethodId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crée une copie modifiée de cette instance
  PaymentMethod copyWith({
    String? type,
    String? last4,
    int? expMonth,
    int? expYear,
    String? brand,
    String? holderName,
    bool? isDefault,
    String? stripePaymentMethodId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      brand: brand ?? this.brand,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convertit en JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'brand': brand,
      'holderName': holderName,
      'isDefault': isDefault,
      'stripePaymentMethodId': stripePaymentMethodId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Crée une instance à partir de JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      last4: json['last4'],
      expMonth: json['expMonth'],
      expYear: json['expYear'],
      brand: json['brand'],
      holderName: json['holderName'],
      isDefault: json['isDefault'] ?? false,
      stripePaymentMethodId: json['stripePaymentMethodId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Service pour gérer les méthodes de paiement des utilisateurs
class PaymentMethodsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Récupère toutes les méthodes de paiement d'un utilisateur
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .get();
        
    return querySnapshot.docs
        .map((doc) => PaymentMethod.fromFirestore(doc))
        .toList();
  }
  
  /// Récupère toutes les méthodes de paiement d'un utilisateur comme Stream
/// Récupère toutes les méthodes de paiement d'un utilisateur comme Stream
  Stream<List<PaymentMethod>> getPaymentMethodsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList());
  }
  
  /// Récupère une méthode de paiement spécifique
  Future<PaymentMethod?> getPaymentMethod(String userId, String methodId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .get();
        
    return doc.exists ? PaymentMethod.fromFirestore(doc) : null;
  }
  
  /// Récupère la méthode de paiement par défaut d'un utilisateur
  Future<PaymentMethod?> getDefaultPaymentMethod(String userId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return PaymentMethod.fromFirestore(query.docs.first);
    }
    
    // Si aucune méthode par défaut, retourner la première trouvée
    final allMethods = await getPaymentMethods(userId);
    return allMethods.isNotEmpty ? allMethods.first : null;
  }
  
  /// Ajoute une nouvelle méthode de paiement
  Future<String> addPaymentMethod(String userId, PaymentMethod method) async {
    // Création d'un nouvel ID unique
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc();
    
    // Si c'est la première méthode ou qu'elle est marquée par défaut,
    // s'assurer que toutes les autres ne sont pas par défaut
    if (method.isDefault) {
      await _resetDefaultPaymentMethods(userId);
    }
    
    // Sauvegarde des données sans l'ID (il sera fourni par la référence)
    final Map<String, dynamic> data = method.toFirestore();
    await docRef.set(data);
    
    return docRef.id;
  }
  
  /// Met à jour une méthode de paiement existante
  Future<void> updatePaymentMethod(String userId, PaymentMethod method) async {
    // Si la méthode est marquée par défaut, réinitialiser les autres
    if (method.isDefault) {
      await _resetDefaultPaymentMethods(userId);
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(method.id)
        .update(method.copyWith(updatedAt: DateTime.now()).toFirestore());
  }
  
  /// Définit une méthode de paiement comme méthode par défaut
  Future<void> setAsDefaultPaymentMethod(String userId, String methodId) async {
    // Réinitialiser toutes les méthodes par défaut
    await _resetDefaultPaymentMethods(userId);
    
    // Définir la méthode spécifiée comme par défaut
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .update({
          'isDefault': true,
          'updatedAt': Timestamp.now(),
        });
  }
  
  /// Réinitialise toutes les méthodes par défaut
  Future<void> _resetDefaultPaymentMethods(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .where('isDefault', isEqualTo: true)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }
  
  /// Supprime une méthode de paiement
  Future<void> deletePaymentMethod(String userId, String methodId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .delete();
  }
  /// Initialise une méthode de paiement par défaut pour un MVP
Future<void> createEmptyPaymentMethod(String userId) async {
  final emptyMethod = PaymentMethod(
    id: 'placeholder',
    type: 'card',
    last4: '0000',
    expMonth: 1,
    expYear: 2030,
    brand: 'Test',
    holderName: 'Nom temporaire',
    isDefault: true,
    stripePaymentMethodId: 'pm_placeholder',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('payment_methods')
      .doc('placeholder')
      .set(emptyMethod.toFirestore());
}

}