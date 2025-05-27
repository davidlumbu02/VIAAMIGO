// ignore_for_file: avoid_print, unintended_html_in_doc_comment

import 'package:cloud_firestore/cloud_firestore.dart';

/// 📦 Modèle représentant l'assurance d'un véhicule
/// Stocke les informations d'assurance liées à un véhicule
class VehicleInsurance {
  /// Nom du fournisseur d'assurance
  final String provider;
  /// Numéro de police d'assurance
  final String policyNumber;
  /// Date d'expiration de l'assurance
  final DateTime expiryDate;

  /// Constructeur principal avec paramètres nommés
  const VehicleInsurance({
    required this.provider,
    required this.policyNumber,
    required this.expiryDate,
  });

  /// Convertit l'instance en Map pour stockage Firestore
  /// Gère la conversion de DateTime en Timestamp pour compatibilité Firestore
  Map<String, dynamic> toMap() => {
        'provider': provider,
        'policyNumber': policyNumber,
        'expiryDate': Timestamp.fromDate(expiryDate),
      };

  /// Crée une instance à partir de données Firestore
  /// Gère la conversion de Timestamp en DateTime
  factory VehicleInsurance.fromMap(Map<String, dynamic> map) {
    return VehicleInsurance(
      provider: map['provider'] ?? '',
      policyNumber: map['policyNumber'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
    );
  }
  
  /// Convertit l'instance en JSON pour API ou stockage local
  /// Utilise format ISO 8601 pour les dates (lisible pour humains)
  Map<String, dynamic> toJson() => {
    'provider': provider,
    'policyNumber': policyNumber,
    'expiryDate': expiryDate.toIso8601String(),
  };

  /// Crée une instance à partir de données JSON
  factory VehicleInsurance.fromJson(Map<String, dynamic> json) {
    return VehicleInsurance(
      provider: json['provider'] ?? '',
      policyNumber: json['policyNumber'] ?? '',
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now().add(const Duration(days: 365)),
    );
  }
  
  /// Crée une copie modifiée de cette instance
  /// Permet de modifier certains champs sans créer une toute nouvelle instance
  VehicleInsurance copyWith({
    String? provider,
    String? policyNumber,
    DateTime? expiryDate,
  }) {
    return VehicleInsurance(
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
  
  /// Compare deux instances pour égalité
  /// Deux assurances sont égales si tous leurs champs sont identiques
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleInsurance &&
        other.provider == provider &&
        other.policyNumber == policyNumber &&
        other.expiryDate.isAtSameMomentAs(expiryDate);
  }

  /// Calcule un code de hachage unique pour cette instance
  /// Utilisé par les collections qui nécessitent une comparaison rapide
  @override
  int get hashCode => 
      provider.hashCode ^ policyNumber.hashCode ^ expiryDate.hashCode;
}

/// 📦 Modèle représentant un véhicule du conducteur
/// Contient toutes les informations relatives à un véhicule enregistré
class Vehicle {
  /// Identifiant unique du véhicule
  final String id;
  
  /// Type de véhicule (sedan, SUV, etc.)
  final String type;
  
  /// Marque du véhicule
  final String make;
  
  /// Modèle du véhicule
  final String model;
  
  /// Année de fabrication
  final int year;
  
  /// Plaque d'immatriculation (peut être chiffrée pour confidentialité)
  final String licensePlate;
  
  /// Couleur du véhicule
  final String color;
  
  /// Volume de chargement disponible en litres
  final double cargoVolume;
  
  /// Poids maximum supporté en kilogrammes
  final double maxWeight;
  
  /// URLs des photos du véhicule
  final List<String> photoUrls;
  
  /// Indique si le véhicule a été vérifié par l'administration
  final bool verified;
  
  /// Date de vérification du véhicule
  final DateTime? verifiedAt;
  
  /// Indique si c'est le véhicule par défaut de l'utilisateur
  final bool isDefault;
  
  /// Dimensions du coffre/espace de chargement en cm
  final Map<String, double>? dimensions;
  
  /// Informations d'assurance du véhicule
  final VehicleInsurance? insurance;
  
  /// Indique si le suivi GPS est autorisé pour ce véhicule
  final bool trackingEnabled;

  /// Constructeur principal avec paramètres nommés et valeurs par défaut
  const Vehicle({
    required this.id,
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    this.cargoVolume = 0.0,
    this.maxWeight = 0.0,
    this.photoUrls = const [],
    this.verified = false,
    this.verifiedAt,
    this.isDefault = false,
    this.dimensions,
    this.insurance,
    this.trackingEnabled = true,
  });

  /// Crée une instance à partir d'un document Firestore
  /// Gère la conversion et offre des valeurs par défaut pour tous les champs
  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Construction des dimensions depuis les données imbriquées
    Map<String, double>? dimensions;
    if (data['dimensions'] != null) {
      dimensions = {
        'length': (data['dimensions']['length'] ?? 0.0).toDouble(),
        'width': (data['dimensions']['width'] ?? 0.0).toDouble(),
        'height': (data['dimensions']['height'] ?? 0.0).toDouble(),
      };
    }

    // Construction de l'objet d'assurance depuis les données imbriquées
    VehicleInsurance? insurance;
    if (data['insurance'] != null) {
      insurance = VehicleInsurance.fromMap(Map<String, dynamic>.from(data['insurance']));
    }

    return Vehicle(
      id: doc.id,
      type: data['type'] ?? 'sedan',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      licensePlate: data['licensePlate'] ?? '',
      color: data['color'] ?? '',
      cargoVolume: (data['cargoVolume'] ?? 0.0).toDouble(),
      maxWeight: (data['maxWeight'] ?? 0.0).toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      verified: data['verified'] ?? false,
      verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
      isDefault: data['isDefault'] ?? false,
      dimensions: dimensions,
      insurance: insurance,
      trackingEnabled: data['trackingEnabled'] ?? true,
    );
  }

  /// Convertit l'instance en Map pour stockage Firestore
  /// Note : 'id' est inclus ici pour les cas particuliers, bien que généralement
  /// l'ID serait géré séparément comme clé du document
  Map<String, dynamic> toFirestore() => {
        'id': id, // Conservé comme demandé, bien que ce ne soit pas une pratique courante
        'type': type,
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'color': color,
        'cargoVolume': cargoVolume,
        'maxWeight': maxWeight,
        'photoUrls': photoUrls,
        'verified': verified,
        'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
        'isDefault': isDefault,
        'dimensions': dimensions,
        'insurance': insurance?.toMap(),
        'trackingEnabled': trackingEnabled,
      };

  /// Convertit l'instance en JSON pour API ou stockage local
  /// Alias pour toFirestore() pour maintenir la cohérence avec d'autres modèles
  Map<String, dynamic> toJson() => toFirestore();

  /// Crée une instance à partir de données JSON
  /// Gère la conversion des données imbriquées comme insurance et dimensions
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      type: json['type'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      licensePlate: json['licensePlate'],
      color: json['color'],
      cargoVolume: (json['cargoVolume'] ?? 0.0).toDouble(),
      maxWeight: (json['maxWeight'] ?? 0.0).toDouble(),
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      verified: json['verified'] ?? false,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      isDefault: json['isDefault'] ?? false,
      dimensions: json['dimensions'] != null
          ? Map<String, double>.from(json['dimensions'])
          : null,
      insurance: json['insurance'] != null
          ? VehicleInsurance.fromMap(Map<String, dynamic>.from(json['insurance']))
          : null,
      trackingEnabled: json['trackingEnabled'] ?? true,
    );
  }
  
  /// Crée une copie modifiée de cette instance
  /// Permet de modifier certains champs sans créer une toute nouvelle instance
  Vehicle copyWith({
    String? type,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? color,
    double? cargoVolume,
    double? maxWeight,
    List<String>? photoUrls,
    bool? verified,
    DateTime? verifiedAt,
    bool? isDefault,
    Map<String, double>? dimensions,
    VehicleInsurance? insurance,
    bool? trackingEnabled,
  }) {
    return Vehicle(
      id: id, // ID reste inchangé
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      cargoVolume: cargoVolume ?? this.cargoVolume,
      maxWeight: maxWeight ?? this.maxWeight,
      photoUrls: photoUrls ?? this.photoUrls,
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isDefault: isDefault ?? this.isDefault,
      dimensions: dimensions ?? this.dimensions,
      insurance: insurance ?? this.insurance,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
    );
  }
  
  /// Compare deux instances pour égalité
  /// Deux véhicules sont considérés comme égaux s'ils ont le même ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  /// Calcule un code de hachage unique pour cette instance
  /// Basé uniquement sur l'ID car c'est l'identifiant unique du véhicule
  @override
  int get hashCode => id.hashCode; // Gardé comme demandé
}

/// 🚗 Service pour gérer les véhicules
/// Fournit des méthodes pour interagir avec la sous-collection vehicles dans Firestore
class VehiclesService {
  /// Instance Firestore pour les opérations de base de données
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère la liste de tous les véhicules d'un utilisateur
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Future<List<Vehicle>> Liste des véhicules
  Future<List<Vehicle>> getUserVehicles(String userId) async {
    try {
      final query = await _firestore.collection('users').doc(userId).collection('vehicles').get();
      return query.docs.map((doc) => Vehicle.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des véhicules: $e');
      rethrow;
    }
  }

  /// Récupère un stream de tous les véhicules d'un utilisateur
  /// Utile pour les widgets qui doivent se mettre à jour en temps réel
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Stream<List<Vehicle>> Stream de la liste des véhicules
  Stream<List<Vehicle>> getUserVehiclesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots()
        .map((s) => s.docs.map((d) => Vehicle.fromFirestore(d)).toList());
  }

  /// Récupère un véhicule spécifique par son ID
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicleId ID du véhicule à récupérer
  /// @return Future<Vehicle?> Véhicule trouvé ou null si non trouvé
  Future<Vehicle?> getUserVehicle(String userId, String vehicleId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).get();
      return doc.exists ? Vehicle.fromFirestore(doc) : null;
    } catch (e) {
      print('Erreur lors de la récupération du véhicule: $e');
      rethrow;
    }
  }

  /// Vérifie si un véhicule existe pour un utilisateur donné
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicleId ID du véhicule à vérifier
  /// @return Future<bool> true si le véhicule existe, false sinon
  Future<bool> vehicleExists(String userId, String vehicleId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification d\'existence du véhicule: $e');
      rethrow;
    }
  }

  /// Récupère le véhicule par défaut d'un utilisateur
  /// S'il n'y a pas de véhicule par défaut, retourne le premier véhicule trouvé
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Future<Vehicle?> Véhicule par défaut ou null si aucun véhicule
  Future<Vehicle?> getDefaultVehicle(String userId) async {
    try {
      // Recherche d'un véhicule avec isDefault = true
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      // Si un véhicule par défaut est trouvé, le retourner
      if (query.docs.isNotEmpty) return Vehicle.fromFirestore(query.docs.first);

      // Sinon, retourner le premier véhicule (s'il y en a)
      final all = await getUserVehicles(userId);
      return all.isNotEmpty ? all.first : null;
    } catch (e) {
      print('Erreur lors de la récupération du véhicule par défaut: $e');
      rethrow;
    }
  }

  /// Ajoute un nouveau véhicule
  /// Si le véhicule est marqué par défaut, réinitialise les autres véhicules
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicle Objet Vehicle à ajouter
  /// @return Future<String> ID du nouveau véhicule créé
  Future<String> addVehicle(String userId, Vehicle vehicle) async {
    try {
      // Si ce véhicule doit être le véhicule par défaut, s'assurer que les autres ne le sont pas
      if (vehicle.isDefault) await _resetDefaultVehicles(userId);
      
      // Créer un nouveau document et y stocker les données du véhicule
      final doc = _firestore.collection('users').doc(userId).collection('vehicles').doc();
      await doc.set(vehicle.toFirestore());
      return doc.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du véhicule: $e');
      rethrow;
    }
  }

  /// Met à jour un véhicule existant
  /// Si le véhicule est marqué par défaut, réinitialise les autres véhicules
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicle Objet Vehicle avec les modifications à appliquer
  /// @return Future<void> Complète lorsque l'opération est terminée
  Future<void> updateVehicle(String userId, Vehicle vehicle) async {
    try {
      // Si ce véhicule doit être le véhicule par défaut, s'assurer que les autres ne le sont pas
      if (vehicle.isDefault) await _resetDefaultVehicles(userId);
      
      // Mettre à jour le document du véhicule
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .doc(vehicle.id)
          .update(vehicle.toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour du véhicule: $e');
      rethrow;
    }
  }

  /// Supprime un véhicule
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicleId ID du véhicule à supprimer
  /// @return Future<void> Complète lorsque l'opération est terminée
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .doc(vehicleId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression du véhicule: $e');
      rethrow;
    }
  }

  /// Définit un véhicule comme étant le véhicule par défaut
  /// Réinitialise d'abord tous les autres véhicules pour s'assurer qu'il n'y a qu'un seul par défaut
  /// @param userId ID de l'utilisateur propriétaire
  /// @param vehicleId ID du véhicule à définir comme défaut
  /// @return Future<void> Complète lorsque l'opération est terminée
  Future<void> setAsDefaultVehicle(String userId, String vehicleId) async {
    try {
      // S'assurer qu'aucun autre véhicule n'est le véhicule par défaut
      await _resetDefaultVehicles(userId);
      
      // Définir ce véhicule comme le véhicule par défaut
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .doc(vehicleId)
          .update({'isDefault': true});
    } catch (e) {
      print('Erreur lors de la définition du véhicule par défaut: $e');
      rethrow;
    }
  }

  /// Supprime tous les véhicules d'un utilisateur
  /// Utile lors de la suppression du compte ou pour réinitialiser les données
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Future<void> Complète lorsque l'opération est terminée
  Future<void> deleteAllVehicles(String userId) async {
    try {
      // Récupérer tous les documents de véhicules
      final snapshot = await _firestore.collection('users').doc(userId).collection('vehicles').get();
      
      // Si aucun véhicule trouvé, terminer tôt
      if (snapshot.docs.isEmpty) return;
      
      // Utiliser un batch pour les supprimer tous en une seule opération
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Erreur lors de la suppression de tous les véhicules: $e');
      rethrow;
    }
  }

  /// Méthode privée pour réinitialiser tous les véhicules par défaut
  /// Garantit qu'aucun véhicule n'est marqué comme par défaut avant d'en définir un nouveau
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Future<void> Complète lorsque l'opération est terminée
  Future<void> _resetDefaultVehicles(String userId) async {
    try {
      // Récupérer tous les véhicules marqués comme par défaut
      final docs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .where('isDefault', isEqualTo: true)
          .get();
      
      // Si aucun véhicule par défaut trouvé, terminer tôt
      if (docs.docs.isEmpty) return;
      
      // Utiliser un batch pour les mettre tous à jour en une seule opération
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    } catch (e) {
      print('Erreur lors de la réinitialisation des véhicules par défaut: $e');
      rethrow;
    }
  }
  
  /// Crée un document de véhicule vide pour une nouvelle installation ou un MVP
  /// Utilise intentionnellement un ID fixe 'placeholder' comme demandé
  /// @param userId ID de l'utilisateur propriétaire
  /// @return Future<void> Complète lorsque l'opération est terminée
  /// Crée un véhicule vide avec un ID auto-généré dans Firestore
/// Utilisé pour initialiser un utilisateur avec un véhicule par défaut (MVP)
/// @param userId L'UID de l'utilisateur auquel associer le véhicule
Future<void> createEmptyVehicleDoc(String userId) async {
  try {
    // 🔹 Référence à un nouveau document avec ID aléatoire (pas 'placeholder')
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(); // ✅ Firestore génère un ID unique

    // 🔹 Création d'un objet Vehicle vide avec les champs requis
    final emptyVehicle = Vehicle(
      id: docRef.id, // 🆔 On attribue explicitement l'ID Firestore à l'objet
      type: '', // 🔧 Type vide (ex: 'SUV', 'camionnette' à remplir plus tard)
      make: '', // 🔧 Marque
      model: '', // 🔧 Modèle
      year: DateTime.now().year, // 📅 Année actuelle par défaut
      licensePlate: '', // 🔧 Plaque vide
      color: '', // 🎨 Couleur vide
      photoUrls: [], // 🖼️ Pas de photo à l'initialisation
      cargoVolume: 0.0, // 📦 Volume vide
      maxWeight: 0.0, // ⚖️ Poids max vide
      isDefault: false, // 🚗 Pas le véhicule par défaut (à ajuster plus tard)
      trackingEnabled: false, // 📍 GPS désactivé pour un véhicule vide
      verified: false, // 🔒 Non vérifié
      verifiedAt: null, // 📅 Pas encore vérifié
      dimensions: { // 📐 Dimensions vides
        'length': 0.0,
        'width': 0.0,
        'height': 0.0,
      },
      insurance: VehicleInsurance(
        provider: '', // 🏢 Nom de l'assureur vide
        policyNumber: '', // 🆔 Police vide
        expiryDate: DateTime.now().add(const Duration(days: 365)), // 📅 Par défaut, expire dans 1 an
      ),
    );

    // 🔹 Enregistrement dans Firestore
    await docRef.set(emptyVehicle.toFirestore());
  } catch (e) {
    // 🚨 Log d'erreur en cas d'échec
    print('Erreur lors de la création du document de véhicule vide: $e');
    rethrow;
  }
}

  /*Future<void> createEmptyVehicleDoc(String userId) async {
    try {
      // Créer un véhicule avec des valeurs par défaut
      final emptyVehicle = Vehicle(
        id: 'empty', // ID local qui sera remplacé par 'placeholder'
        type: '',
        make: '',
        model: '',
        year: DateTime.now().year,
        licensePlate: '',
        color: '',
        photoUrls: [],
        cargoVolume: 0.0,
        maxWeight: 0.0,
        isDefault: false,
        trackingEnabled: false,
        verified: false,
        verifiedAt: null,
        dimensions: {
          'length': 0.0,
          'width': 0.0,
          'height': 0.0,
        },
        insurance: VehicleInsurance(
          provider: '',
          policyNumber: '',
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
      );

      // Utiliser un ID fixe 'placeholder' comme demandé
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .doc('placeholder')
          .set(emptyVehicle.toFirestore());
    } catch (e) {
      print('Erreur lors de la création du document de véhicule vide: $e');
      rethrow;
    }
  }*/
}
