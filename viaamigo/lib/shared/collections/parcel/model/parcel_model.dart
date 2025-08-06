import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_dimension_model.dart';

 // Pour les calculs de distance

/// Modèle principal représentant un colis dans le système
/// 
/// Cette classe gère toutes les données associées à un colis, de sa création 
/// jusqu'à sa livraison. Elle inclut des fonctionnalités pour la validation, 
/// la conversion depuis/vers Firestore, et diverses opérations de traitement
/// des données du colis.
class ParcelModel {
  // ----- PROPRIÉTÉS DE BASE -----
    /// Configuration des tranches d'assurance inspirée de Cocolis
static const Map<String, Map<String, dynamic>> insuranceTranches = {
    'none': {'maxValue': 0, 'premium': 0},
    'tranche_150': {'maxValue': 150, 'premium': 2},
    'tranche_250': {'maxValue': 250, 'premium': 4},
    'tranche_500': {'maxValue': 500, 'premium': 5},
    'tranche_1000': {'maxValue': 1000, 'premium': 9},
    'tranche_1500': {'maxValue': 1500, 'premium': 15},
    'tranche_2000': {'maxValue': 2000, 'premium': 24},
    'tranche_2500': {'maxValue': 2500, 'premium': 35},
    'tranche_3000': {'maxValue': 3000, 'premium': 45},
    'tranche_3500': {'maxValue': 3500, 'premium': 55},
    'tranche_4000': {'maxValue': 4000, 'premium': 65},
    'tranche_4500': {'maxValue': 4500, 'premium': 75},
    'tranche_5000': {'maxValue': 5000, 'premium': 85},
  };
double? insurance_fee;    // Frais d'assurance calculés
double? platform_fee;     // Frais de plateforme

  /// Identifiant unique du colis (généré par Firestore)
  String? id;
  
  /// ID de l'utilisateur qui envoie le colis
  String senderId;
  
  /// Nom complet de l'expéditeur
  String senderName;
  
  /// Numéro de téléphone de l'expéditeur (optionnel)
  String? senderPhone;
  /// Référence vers le document de paiement dans la collection `payments`
  String? paymentId;
  String? paymentMethod;      // 'pay_now' ou 'pay_later'

  /// Statut du paiement lié à ce colis
  /// Valeurs possibles : 'unpaid', 'escrowed', 'paid', 'refunded'
  String paymentStatus;

  /// Date à laquelle le paiement a été effectué (si applicable)
  DateTime? paidAt;


  /// Titre court décrivant le contenu du colis
  String title;
  
  /// Description détaillée du colis et de son contenu
  String? description;

  ///description pick up
  String? pickupDescription;

  ///description livraison
  String? deliveryDescription;
  
  /// Poids du colis en kilogrammes
  double weight;
  
  /// Taille standard du colis (énumération sous forme de string)
  /// Valeurs possibles: "S", "M", "L", "XL", "XXL", "custom"
  String size;
  
  /// Dimensions précises du colis en cm {length, width, height}
  /// Utilisé principalement quand size = "custom"
  Map<String, dynamic> dimensions;

  Map<String, dynamic>? pickupHandling;
  Map<String, dynamic>? deliveryHandling;
  double? totalHandlingFee ;
  
  /// Catégorie du colis qui détermine les conditions de manipulation
  /// Valeurs possibles: "fragile", "normal", "perishable", "valuable"
  String category;
  
  // ----- INFORMATIONS GÉOGRAPHIQUES -----
  
  /// Point géographique de ramassage (avec latitude/longitude)
  GeoFirePoint? origin;
  
  /// Adresse textuelle du point de ramassage
  String originAddress;
  
  /// Point géographique de destination (avec latitude/longitude)
  GeoFirePoint? destination;
  
  /// Adresse textuelle du point de livraison
  String destinationAddress;
  
  /// Nom du destinataire
  String recipientName;
  
  /// Numéro de téléphone du destinataire
  String recipientPhone;
  
  /// Distance estimée entre origine et destination (en km)
  double? estimatedDistance;
  
  // ----- INFORMATIONS DE STATUT ET PRIX -----
  
  /// État actuel du colis dans le système
  /// Valeurs possibles: "draft", "pending", "matched", "in_transit", 
  /// "delivered", "cancelled", "returned"
  String status;
  
  /// Prix final de la livraison
  double? price;
  
  /// Prix estimé calculé avant confirmation
  double? estimatedPrice;
  
  /// Prix initial proposé (peut être différent du prix final)
  double? initialPrice;
  
  // ----- INFORMATIONS D'ASSURANCE -----
  
  /// ID de la police d'assurance associée
  String? insuranceId;
  
  /// Indique si le colis est assuré
  bool isInsured;
  
  /// Valeur déclarée du contenu (pour l'assurance)
  double? declared_value;

  
  /// Niveau d'assurance choisi
  /// Valeurs possibles: "none", "basic", "premium"
  String insurance_level;
  
  /// ID de l'association avec un transporteur
  String? matchId;
  
  // ----- INFORMATIONS TEMPORELLES -----
  
  /// Date de création du colis dans le système
  DateTime createdAt;
  
  /// Date d'expiration de l'annonce (si applicable)
  DateTime? expiresAt;
  
  /// Liste des URLs des photos du colis
  List<String> photos;
  
  /// URL de la photo principale pour les affichages en miniature
  String? primaryPhotoUrl;
  
  /// Plage horaire pour le ramassage {start_time, end_time}
  Map<String, dynamic> pickup_window;
  
  /// Plage horaire pour la livraison {start_time, end_time}
  Map<String, dynamic> delivery_window;
  
  // ----- INFORMATIONS D'ÉTAT ET PROGRESSION -----
  
  /// Indique si le colis est encore en brouillon
  bool draft;
  
  /// Pourcentage de complétion des informations requises (0-100%)
  int completion_percentage;
  
  /// Étape actuelle dans le processus de création du colis
  int navigation_step;
  
  /// Date de dernière modification
  DateTime last_edited;
  
  // ----- OPTIONS DE LIVRAISON -----
  

  
  /// Vitesse de livraison souhaitée
  /// Valeurs possibles: "economy", "standard", "express"
  String delivery_speed;
  
  // ----- ATTRIBUTS AVANCÉS ET INTÉGRATIONS -----
  
  /// Résultats de l'analyse par intelligence artificielle du colis
  Map<String, dynamic>? ai_recognition_results;
  
  /// ID du point de collecte (si différent de l'adresse d'origine)
  String? pickup_point_id;
  
  /// ID du point de livraison (si différent de l'adresse de destination)
  String? delivery_point_id;
  
  /// ID de l'organisation associée au colis (pour les envois d'entreprise)
  String? organizationId;
  
  /// Identifiant d'importation en masse (pour les lots de colis)
  String? bulk_import_id;
  
  /// Code promotionnel appliqué à cette livraison
  String? promo_code_applied;
  
  /// Montant de la réduction appliquée
  double? discount_amount;
  
  /// Indique si l'indexation géographique est prête pour la recherche
  bool geoIndexReady;
  
  /// Geohash utilisé pour l'indexation géographique
  String? g;
  
  /// Liste des erreurs de validation pour afficher à l'utilisateur
  List<String> validationErrors = [];

  /// quantité de colis (utile pour les envois multiples)
  int quantity;

  
  
  

  // ----- GETTERS ET SETTERS POUR LES MODÈLES TYPÉS -----
  
  /// Accès typé aux dimensions du colis
  ParcelDimensions get typedDimensions {
    return ParcelDimensions.fromMap(dimensions);
  }

  /// Définition typée des dimensions du colis
  set typedDimensions(ParcelDimensions value) {
    dimensions = value.toMap();
  }

  /// Accès typé à la fenêtre de ramassage
  TimeWindow get typedPickupWindow {
    return TimeWindow.fromMap(pickup_window);
  }

  /// Définition typée de la fenêtre de ramassage
  set typedPickupWindow(TimeWindow value) {
    pickup_window = value.toMap();
  }

  /// Accès typé à la fenêtre de livraison
  TimeWindow get typedDeliveryWindow {
    return TimeWindow.fromMap(delivery_window);
  }

  /// Définition typée de la fenêtre de livraison
  set typedDeliveryWindow(TimeWindow value) {
    delivery_window = value.toMap();
  }

  /// Accès typé aux résultats d'analyse IA
  AiRecognitionResult? get typedAiResults {
    return ai_recognition_results != null 
        ? AiRecognitionResult.fromMap(ai_recognition_results!) 
        : null;
  }

  /// Définition typée des résultats d'analyse IA
  set typedAiResults(AiRecognitionResult? value) {
    ai_recognition_results = value?.toMap();
  }
  
  /// Accès simplifié à la photo principale
  /// Renvoie la photo principale ou la première photo disponible
  String get mainPhotoUrl {
    return primaryPhotoUrl ?? (photos.isNotEmpty ? photos.first : '');
  }

  // ----- CONSTRUCTEURS -----
  
  /// Constructeur principal avec tous les paramètres possibles
  /// La plupart des paramètres optionnels ont des valeurs par défaut sensées
  ParcelModel({
    this.id,
    this.quantity = 1,
    this.paymentId,
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'pay_later',
    this.paidAt,
    required this.senderId,
    required this.senderName,
    this.senderPhone,
    required this.title,
    this.description,
    this.pickupDescription = '',
    this.deliveryDescription = '',
    required this.weight,
    required this.size,
    required this.dimensions,
    this.pickupHandling,
    this.deliveryHandling,
    this.totalHandlingFee,
    required this.category,
    this.origin,
    required this.originAddress,
    this.destination,
    required this.destinationAddress,
    required this.recipientName,
    required this.recipientPhone,
    this.estimatedDistance,
    this.status = 'draft',
    this.price,
    this.estimatedPrice,
    this.initialPrice,
    this.insuranceId,
    this.isInsured = false,
    this.declared_value,
    this.insurance_level = 'none',
    this.insurance_fee,        // ✅ AJOUT
    this.platform_fee,
    this.matchId,
    required this.createdAt,
    this.expiresAt,
    this.photos = const [],
    this.primaryPhotoUrl,
    required this.pickup_window,
    required this.delivery_window,
    this.draft = true,
    this.completion_percentage = 0,
    this.navigation_step = 0,
    required this.last_edited,

    this.delivery_speed = 'standard',
    this.ai_recognition_results,
    this.pickup_point_id,
    this.delivery_point_id,
    this.organizationId,
    this.bulk_import_id,
    this.promo_code_applied,
    this.discount_amount,
    this.geoIndexReady = false,
    this.g,
    this.validationErrors = const [],
  });
/*🔹 "assistanceLevel" (String)
Niveau d'assistance souhaité pour l'enlèvement ou la livraison

Valeur	Signification
"door"	Dépôt ou ramassage au pied du véhicule ou devant la porte
"light_assist"	Le chauffeur aide à porter brièvement jusqu’à l’entrée
"room"	Le chauffeur entre dans le logement pour livrer ou récupérer (étage, pièce précise)
"custom"	Option ouverte à discussion via le chat intégré */
  /// Crée un modèle de colis vide avec les valeurs minimales requises
  /// Utilisé pour initialiser un nouveau colis en mode brouillon
  factory ParcelModel.empty(String userId, String userName) {
    final now = DateTime.now();
    return ParcelModel(
      senderId: userId,
      paymentId: '',
      paymentStatus: 'unpaid',
      paymentMethod: 'pay_later',
      paidAt: null,
      senderName: userName,
      senderPhone: '',
      title: '',
      description: '',
      pickupDescription: '',
      deliveryDescription: '',
      weight: 0.0,
      size: '',
      dimensions: {
        'length': 0,
        'width': 0,
        'height': 0,
      },
      pickupHandling: {
        "assistanceLevel": "",
        "floor": 0,
        "hasElevator": false,
        //"snowOrObstacle": true,
        "accessNotes": "",
        "estimatedFee": 0.0
      },
      deliveryHandling: {
        "assistanceLevel": "",
        "floor": 0,
        "hasElevator": false,
        //"snowOrObstacle": true,
        "accessNotes": "",
        "estimatedFee": 0.0
      },
      totalHandlingFee: 0.0,
      category: 'normal',
      originAddress: '',
      destinationAddress: '',
      recipientName: '',
      recipientPhone: '',
      createdAt: now,
      last_edited: now,
      pickup_window: {
        'start_time': Timestamp.fromDate(now.add(Duration(days: 0, hours: 1))),
        'end_time': Timestamp.fromDate(now.add(Duration(days: 7, hours: 3))),
      },
      delivery_window: {
        'start_time': Timestamp.fromDate(now.add(Duration(days: 2))),
        'end_time': Timestamp.fromDate(now.add(Duration(days: 2, hours: 4))),
      },
    );
  }

  /// Construit une instance depuis un document Firestore
  /// Gère la conversion des types spécifiques (GeoPoint, Timestamp, etc.)
  factory ParcelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    
    // Conversion des coordonnées géographiques
 GeoFirePoint? origin;
if (data['origin'] != null) {
  GeoPoint geoPoint = data['origin'];
  origin = GeoFirePoint(geoPoint);
}

GeoFirePoint? destination;
if (data['destination'] != null) {
  GeoPoint geoPoint = data['destination'];
  destination = GeoFirePoint(geoPoint);
}

    return ParcelModel(
      id: doc.id,
      quantity: data['quantity'] ?? 1,
      paymentId: data['paymentId'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentMethod: data['paymentMethod'] ?? 'pay_later',
      paidAt: data['paidAt']?.toDate(),
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhone: data['senderPhone'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pickupDescription: data['pickupDescription'] ?? '',
      deliveryDescription: data['deliveryDescription'] ?? '',
      weight: data['weight']?.toDouble() ?? 0.0,
      size: data['size'] ?? 'SIZE M',
      dimensions: data['dimensions'] ?? {'length': 0, 'width': 0, 'height': 0},
      pickupHandling: data['pickupHandling'] ?? {
        "assistanceLevel": "door",
        "floor": 0,
        "hasElevator": false,
        //"snowOrObstacle": true,
        "accessNotes": "",
        "estimatedFee": 35.0
      },
      deliveryHandling: data['deliveryHandling'] ?? {
        "assistanceLevel": "door",
        "floor": 0,
        "hasElevator": false,
        //"snowOrObstacle": true,
        "accessNotes": "",
        "estimatedFee": 0.0
      },
      totalHandlingFee: data['totalHandlingFee']?.toDouble() ?? 0.0,
      category: data['category'] ?? 'normal',
      origin: origin,
      originAddress: data['originAddress'] ?? '',
      destination: destination,
      destinationAddress: data['destinationAddress'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      estimatedDistance: data['estimatedDistance']?.toDouble(),
      status: data['status'] ?? 'draft',
      price: data['price']?.toDouble(),
      estimatedPrice: data['estimatedPrice']?.toDouble(),
      initialPrice: data['initialPrice']?.toDouble(),
      insuranceId: data['insuranceId'],
      isInsured: data['isInsured'] ?? false,
      declared_value: data['declared_value']?.toDouble(),
      insurance_level: data['insurance_level'] ?? 'none',
      insurance_fee: data['insurance_fee']?.toDouble(),      // ✅ AJOUT
    platform_fee: data['platform_fee']?.toDouble(), 
      matchId: data['matchId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      photos: List<String>.from(data['photos'] ?? []),
      primaryPhotoUrl: data['primaryPhotoUrl'],
      pickup_window: data['pickup_window'] ?? {},
      delivery_window: data['delivery_window'] ?? {},
      draft: data['draft'] ?? true,
      completion_percentage: data['completion_percentage'] ?? 0,
      navigation_step: data['navigation_step'] ?? 0,
      last_edited: (data['last_edited'] as Timestamp?)?.toDate() ?? DateTime.now(),

      delivery_speed: data['delivery_speed'] ?? 'standard',
      ai_recognition_results: data['ai_recognition_results'],
      pickup_point_id: data['pickup_point_id'],
      delivery_point_id: data['delivery_point_id'],
      organizationId: data['organizationId'],
      bulk_import_id: data['bulk_import_id'],
      promo_code_applied: data['promo_code_applied'],
      discount_amount: data['discount_amount']?.toDouble(),
      geoIndexReady: data['geoIndexReady'] ?? false,
      g: data['g'],
    );
  }

  /// Convertit l'instance en Map pour le stockage Firestore
  /// Gère la conversion des types spécifiques (DateTime en Timestamp, etc.)
  Map<String, dynamic> toFirestore() {
    return {
      'quantity': quantity,
      'id': id,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'title': title,
      'description': description,
      'pickupDescription': pickupDescription,
      'deliveryDescription': deliveryDescription,
      'weight': weight,
      'size': size,
      'dimensions': dimensions,
      'totalHandlingFee': totalHandlingFee,
      'pickupHandling': pickupHandling,
      'deliveryHandling': deliveryHandling,
      'category': category,
      'origin': origin != null ? GeoPoint(origin!.latitude, origin!.longitude) : null,
      'originAddress': originAddress,
      'destination': destination != null ? GeoPoint(destination!.latitude, destination!.longitude) : null,
      'destinationAddress': destinationAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'estimatedDistance': estimatedDistance,
      'status': status,
      'price': price,
      'estimatedPrice': estimatedPrice,
      'initialPrice': initialPrice,
      'insuranceId': insuranceId,
      'isInsured': isInsured,
      'insurance_fee': insurance_fee,        // ✅ AJOUT
    'platform_fee': platform_fee,         // ✅ AJOUT
      'declared_value': declared_value,
      'insurance_level': insurance_level,
      'matchId': matchId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'photos': photos,
      'primaryPhotoUrl': primaryPhotoUrl,
      'pickup_window': pickup_window,
      'delivery_window': delivery_window,
      'draft': draft,
      'completion_percentage': completion_percentage,
      'navigation_step': navigation_step,
      'last_edited': Timestamp.fromDate(last_edited),
 
      'delivery_speed': delivery_speed,
      'ai_recognition_results': ai_recognition_results,
      'pickup_point_id': pickup_point_id,
      'delivery_point_id': delivery_point_id,
      'organizationId': organizationId,
      'bulk_import_id': bulk_import_id,
      'promo_code_applied': promo_code_applied,
      'discount_amount': discount_amount,
      'geoIndexReady': geoIndexReady,
      'g': g,
    };
  }

  /// Crée une nouvelle instance avec certains champs modifiés
  /// Implémente le pattern "immutable update" pour faciliter les 
  /// manipulations de données sans effets secondaires
  ParcelModel copyWith({
    String? id,
    String? paymentId,
    String? paymentStatus,
    String? paymentMethod, // 'pay_now' ou 'pay_later'
    DateTime? paidAt,
    int? quantity,
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? title,
    String? description,
    String? pickupDescription,
    String? deliveryDescription,
    double? weight,
    String? size,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? pickupHandling,
    Map<String, dynamic>? deliveryHandling,
    double? totalHandlingFee,
    String? category,
    GeoFirePoint? origin,
    String? originAddress,
    GeoFirePoint? destination,
    String? destinationAddress,
    String? recipientName,
    String? recipientPhone,
    double? estimatedDistance,
    String? status,
    double? price,
    double? estimatedPrice,
    double? initialPrice,
    String? insuranceId,
    bool? isInsured,
    double? declared_value,
    String? insurance_level,
    double? insurance_fee,
    double? platform_fee,
    String? matchId,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? photos,
    String? primaryPhotoUrl,
    Map<String, dynamic>? pickup_window,
    Map<String, dynamic>? delivery_window,
    bool? draft,
    int? completion_percentage,
    int? navigation_step,
    DateTime? last_edited,

    String? delivery_speed,
    Map<String, dynamic>? ai_recognition_results,
    String? pickup_point_id,
    String? delivery_point_id,
    String? organizationId,
    String? bulk_import_id,
    String? promo_code_applied,
    double? discount_amount,
    bool? geoIndexReady,
    String? g,
    List<String>? validationErrors,
  }) {
    return ParcelModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      quantity: quantity ?? this.quantity,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      pickupDescription: pickupDescription ?? this.pickupDescription,
      deliveryDescription: deliveryDescription ?? this.deliveryDescription,
      weight: weight ?? this.weight,
      size: size ?? this.size,
      dimensions: dimensions ?? this.dimensions,
      totalHandlingFee: totalHandlingFee ?? this.totalHandlingFee,
      pickupHandling: pickupHandling ?? this.pickupHandling,
      deliveryHandling: deliveryHandling ?? this.deliveryHandling,
      category: category ?? this.category,
      origin: origin ?? this.origin,
      originAddress: originAddress ?? this.originAddress,
      destination: destination ?? this.destination,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      status: status ?? this.status,
      price: price ?? this.price,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      initialPrice: initialPrice ?? this.initialPrice,
      insuranceId: insuranceId ?? this.insuranceId,
      isInsured: isInsured ?? this.isInsured,
      declared_value: declared_value ?? this.declared_value,
      insurance_level: insurance_level ?? this.insurance_level,
      insurance_fee: insurance_fee ?? this.insurance_fee,
      platform_fee: platform_fee ?? this.platform_fee,
      matchId: matchId ?? this.matchId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      photos: photos ?? List<String>.from(this.photos),
      primaryPhotoUrl: primaryPhotoUrl ?? this.primaryPhotoUrl,
      pickup_window: pickup_window ?? Map<String, dynamic>.from(this.pickup_window),
      delivery_window: delivery_window ?? Map<String, dynamic>.from(this.delivery_window),
      draft: draft ?? this.draft,
      completion_percentage: completion_percentage ?? this.completion_percentage,
      navigation_step: navigation_step ?? this.navigation_step,
      last_edited: last_edited ?? this.last_edited,

      delivery_speed: delivery_speed ?? this.delivery_speed,
      ai_recognition_results: ai_recognition_results ?? this.ai_recognition_results,
      pickup_point_id: pickup_point_id ?? this.pickup_point_id,
      delivery_point_id: delivery_point_id ?? this.delivery_point_id,
      organizationId: organizationId ?? this.organizationId,
      bulk_import_id: bulk_import_id ?? this.bulk_import_id,
      promo_code_applied: promo_code_applied ?? this.promo_code_applied,
      discount_amount: discount_amount ?? this.discount_amount,
      geoIndexReady: geoIndexReady ?? this.geoIndexReady,
      g: g ?? this.g,
      validationErrors: validationErrors ?? List<String>.from(this.validationErrors),
    );
  }

  /// Calcule le pourcentage de complétion du formulaire de colis
  /// En comptant les champs obligatoires qui ont été remplis
  int calculateCompletionPercentage() {
    int totalFields = 10; // Nombre total de champs obligatoires
    int completedFields = 0;
    
    // Vérification de chaque champ obligatoire
    if (title.isNotEmpty) completedFields++;
    
    //if (pickupDescription.isNotEmpty) completedFields++;
    //if (deliveryDescription.isNotEmpty) completedFields++;
    if (size.isNotEmpty) completedFields++;
    if (weight > 0) completedFields++;
    if (originAddress.isNotEmpty) completedFields++;
    if (destinationAddress.isNotEmpty) completedFields++;
    if (recipientName.isNotEmpty) completedFields++;
    if (recipientPhone.isNotEmpty) completedFields++;
    if (pickup_window.isNotEmpty) completedFields++;
    if (delivery_window.isNotEmpty) completedFields++;
    if (photos.isNotEmpty) completedFields++;
    
    // Calcul et arrondi du pourcentage
    return ((completedFields / totalFields) * 100).round();
  }

    // ✅ AJOUT OBLIGATOIRE: Méthode fromJson
  static ParcelModel fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      id: json['id'],
      senderId: json['senderId'] ?? '',
      paymentId: json['paymentId'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentMethod: json['paymentMethod'] ?? 'pay_later',
      paidAt: json['paidAt'] != null ? 
        (json['paidAt'] is Timestamp ? 
          (json['paidAt'] as Timestamp).toDate() : 
          DateTime.parse(json['paidAt'].toString())) : null,
      senderName: json['senderName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pickupDescription: json['pickupDescription'] ?? '',
      deliveryDescription: json['deliveryDescription'] ?? '',
      quantity: json['quantity'] ?? 1,
      senderPhone: json['senderPhone'] ?? '',
      weight: (json['weight'] ?? 0.0).toDouble(),
      size: json['size'] ?? '',
      dimensions: Map<String, dynamic>.from(json['dimensions'] ?? {
        'length': 0,
        'width': 0,
        'height': 0,
      }),
      category: json['category'] ?? 'normal',
      originAddress: json['originAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      recipientName: json['recipientName'] ?? '',
      recipientPhone: json['recipientPhone'] ?? '',
      createdAt: json['createdAt'] != null ?
        (json['createdAt'] is Timestamp ?
          (json['createdAt'] as Timestamp).toDate() :
          DateTime.parse(json['createdAt'].toString())) : DateTime.now(),
      last_edited: json['last_edited'] != null ?
        (json['last_edited'] is Timestamp ?
          (json['last_edited'] as Timestamp).toDate() :
          DateTime.parse(json['last_edited'].toString())) : DateTime.now(),
      pickup_window: json['pickup_window'] ?? {},
      delivery_window: json['delivery_window'] ?? {},
      draft: json['draft'] ?? true,
      completion_percentage: json['completion_percentage'] ?? 0,
      navigation_step: json['navigation_step'] ?? 0,
      status: json['status'] ?? 'draft',
      isInsured: json['isInsured'] ?? false,
      insurance_level: json['insurance_level'] ?? 'none',
      insurance_fee: (json['insurance_fee'] ?? 0.0).toDouble(),
      platform_fee: (json['platform_fee'] ?? 0.0).toDouble(),
      delivery_speed: json['delivery_speed'] ?? 'standard',
      photos: List<String>.from(json['photos'] ?? []),
      geoIndexReady: json['geoIndexReady'] ?? false,
      
      // Champs optionnels
      primaryPhotoUrl: json['primaryPhotoUrl'],
      validationErrors: List<String>.from(json['validationErrors'] ?? []),
      declared_value: json['declared_value']?.toDouble(),
      estimatedDistance: json['estimatedDistance']?.toDouble(),
      estimatedPrice: json['estimatedPrice']?.toDouble(),
      initialPrice: json['initialPrice']?.toDouble(),
      price: json['price']?.toDouble(),
      discount_amount: json['discount_amount']?.toDouble(),
      promo_code_applied: json['promo_code_applied'],
      pickupHandling: json['pickupHandling'],
      deliveryHandling: json['deliveryHandling'],
      totalHandlingFee: json['totalHandlingFee']?.toDouble(),
      
      // Géolocalisation
      origin: json['origin'] != null ? _parseGeoFirePoint(json['origin']) : null,
      destination: json['destination'] != null ? _parseGeoFirePoint(json['destination']) : null,
    );
  }
  
  // ✅ HELPER: Parser GeoFirePoint depuis JSON
  static GeoFirePoint? _parseGeoFirePoint(dynamic geoData) {
    if (geoData == null) return null;
    
    try {
      if (geoData is Map<String, dynamic>) {
        final lat = geoData['latitude'] ?? geoData['lat'];
        final lng = geoData['longitude'] ?? geoData['lng'];
        if (lat != null && lng != null) {
          return GeoFirePoint(GeoPoint(lat.toDouble(), lng.toDouble()));
        }
      }
    } catch (e) {
      debugPrint('Erreur parsing GeoFirePoint: $e');
    }
    return null;
  }
  
  // ✅ AJOUT OBLIGATOIRE: Méthode toJson pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt?.toIso8601String(),
      'senderName': senderName,
      'title': title,
      'description': description,
      'pickupDescription': pickupDescription,
      'deliveryDescription': deliveryDescription,
      'quantity': quantity,
      'senderPhone': senderPhone,
      'weight': weight,
      'size': size,
      'dimensions': dimensions,
      'category': category,
      'originAddress': originAddress,
      'destinationAddress': destinationAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'createdAt': createdAt.toIso8601String(),
      'last_edited': last_edited.toIso8601String(),
      'pickup_window': pickup_window,
      'delivery_window': delivery_window,
      'draft': draft,
      'completion_percentage': completion_percentage,
      'navigation_step': navigation_step,
      'status': status,
      'isInsured': isInsured,
      'insurance_level': insurance_level,
      'insurance_fee': insurance_fee,
      'platform_fee': platform_fee,
      'delivery_speed': delivery_speed,
      'photos': photos,
      'geoIndexReady': geoIndexReady,
      'primaryPhotoUrl': primaryPhotoUrl,
      'validationErrors': validationErrors,
      'declared_value': declared_value,
      'estimatedDistance': estimatedDistance,
      'estimatedPrice': estimatedPrice,
      'initialPrice': initialPrice,
      'price': price,
      'discount_amount': discount_amount,
      'promo_code_applied': promo_code_applied,
      'pickupHandling': pickupHandling,
      'deliveryHandling': deliveryHandling,
      'totalHandlingFee': totalHandlingFee,
      'origin': origin != null ? {
        'latitude': origin!.latitude,
        'longitude': origin!.longitude,
      } : null,
      'destination': destination != null ? {
        'latitude': destination!.latitude,
        'longitude': destination!.longitude,
      } : null,
    };
  }


  /// Valide toutes les données du colis
  /// Remplit la liste validationErrors avec les problèmes détectés
  /// Retourne true si le colis est valide, false sinon
  bool validate() {
    validationErrors.clear();
    
    // Vérification des champs textuels obligatoires
    if (title.isEmpty) validationErrors.add('Titre manquant');
    //if (description.isEmpty) validationErrors.add('Description manquante');
   // if (pickupDescription.isEmpty) validationErrors.add('Description de ramassage manquante');
    //if (deliveryDescription.isEmpty) validationErrors.add('Description de livraison manquante');
    //if (category.isEmpty) validationErrors.add('Catégorie manquante');
    //if (size.isEmpty) validationErrors.add('Taille manquante');
    //if (weight <= 0) validationErrors.add('Poids invalide');
    if (originAddress.isEmpty) validationErrors.add('Adresse de départ manquante');
    if (destinationAddress.isEmpty) validationErrors.add('Adresse de destination manquante');
    if (recipientName.isEmpty) validationErrors.add('Nom du destinataire manquant');
    if (recipientPhone.isEmpty) validationErrors.add('Téléphone du destinataire manquant');
    
    // Vérification des fenêtres temporelles
    final pickupStartTime = getPickupStartTime();
    final pickupEndTime = getPickupEndTime();
    final deliveryStartTime = getDeliveryStartTime();
    final deliveryEndTime = getDeliveryEndTime();
    
    if (pickupStartTime == null || pickupEndTime == null) {
      validationErrors.add('Fenêtre de ramassage invalide');
    } else if (pickupStartTime.isAfter(pickupEndTime)) {
      validationErrors.add('Fenêtre de ramassage incohérente');
    }
    
    if (deliveryStartTime == null || deliveryEndTime == null) {
      validationErrors.add('Fenêtre de livraison invalide');
    } else if (deliveryStartTime.isAfter(deliveryEndTime)) {
      validationErrors.add('Fenêtre de livraison incohérente');
    }
    
    // Vérification des informations d'assurance si nécessaire
  if (!validateInsurance()) {
    // Les erreurs sont déjà ajoutées dans validateInsurance()
  }
    
    return validationErrors.isEmpty;
  }
  
  /// Vérifie si le colis est prêt à être publié
  /// Exécute la validation complète et retourne le résultat
  bool isReadyToPublish() {
    return validate();
  }

  /// Prépare un objet simplifié pour l'affichage dans une carte UI
  /// Contient uniquement les informations les plus importantes
  Map<String, dynamic> toDisplayCard() {
    return {
      'id': id,
      'quantity': quantity,
      'title': title,
      'thumbnail': mainPhotoUrl,
      'fromTo': '$originAddress → $destinationAddress',
      'distance': '${estimatedDistance?.toStringAsFixed(1) ?? "?"} km',
      'status': _getDisplayStatus(),
      'price': price?.toStringAsFixed(2) ?? estimatedPrice?.toStringAsFixed(2) ?? '?',
      'weight': '${weight.toStringAsFixed(1)} kg',
      'size': _getDisplaySize(),
      'pickupDate': _formatDisplayDate(getPickupStartTime()),
      'isUrgent': delivery_speed == 'urgent',
      'completionPercent': completion_percentage,
      'isDraft': draft,
    };
  }
  
  /// Convertit le code de statut en texte lisible pour l'affichage
  String _getDisplayStatus() {
    switch (status) {
      case 'draft': return 'Brouillon';
      case 'pending': return 'En attente';
      case 'matched': return 'Jumelé';
      case 'in_transit': return 'En transit';
      case 'delivered': return 'Livré';
      case 'cancelled': return 'Annulé';
      case 'returned': return 'Retourné';
      default: return 'Inconnu';
    }
  }
  
  /// Convertit le code de taille en texte lisible pour l'affichage
String _getDisplaySize() {
  switch (size) {
    case 'SIZE S': 
      return 'Petit';
    case 'SIZE M': 
      return 'Moyen';
    case 'SIZE L': 
      return 'Grand';
    case 'SIZE XL': 
      return 'Très Grand';
    case 'SIZE XXL': 
      return 'Extra Grand';
    case 'custom': 
      return 'Sur mesure';
    default: 
      return size; // Affiche la valeur brute pour les formats inconnus
  }
}
  /// Formate une date pour l'affichage UI
  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ----- MÉTHODES UTILITAIRES -----

  /// Met à jour les dimensions du colis avec des valeurs individuelles
  /// Crée un nouveau map avec les valeurs fournies
  void updateDimensions(double length, double width, double height) {
    dimensions = {
      'length': length,
      'width': width,
      'height': height,
    };
  }


  /// Met à jour la fenêtre de ramassage avec des valeurs DateTime
  /// Convertit les DateTime en Timestamp pour le stockage
  void updatePickupWindow(DateTime start, DateTime end) {
    pickup_window = {
      'start_time': Timestamp.fromDate(start),
      'end_time': Timestamp.fromDate(end),
    };
  }

  /// Met à jour la fenêtre de livraison avec des valeurs DateTime
  /// Convertit les DateTime en Timestamp pour le stockage
  void updateDeliveryWindow(DateTime start, DateTime end) {
    delivery_window = {
      'start_time': Timestamp.fromDate(start),
      'end_time': Timestamp.fromDate(end),
    };
  }

  /// Extrait la date/heure de début de la fenêtre de ramassage
  /// Convertit le Timestamp Firestore en DateTime Dart
  DateTime? getPickupStartTime() {
    return (pickup_window['start_time'] as Timestamp?)?.toDate();
  }

  /// Extrait la date/heure de fin de la fenêtre de ramassage
  /// Convertit le Timestamp Firestore en DateTime Dart
  DateTime? getPickupEndTime() {
    return (pickup_window['end_time'] as Timestamp?)?.toDate();
  }

  /// Extrait la date/heure de début de la fenêtre de livraison
  /// Convertit le Timestamp Firestore en DateTime Dart
  DateTime? getDeliveryStartTime() {
    return (delivery_window['start_time'] as Timestamp?)?.toDate();
  }

  /// Extrait la date/heure de fin de la fenêtre de livraison
  /// Convertit le Timestamp Firestore en DateTime Dart
  DateTime? getDeliveryEndTime() {
    return (delivery_window['end_time'] as Timestamp?)?.toDate();
  }
  
  /// Définit une photo comme principale pour les affichages en miniature
  /// Vérifie si la photo existe dans la liste avant de la définir
  void setAsPrimaryPhoto(String photoUrl) {
    if (photos.contains(photoUrl)) {
      primaryPhotoUrl = photoUrl;
    } else if (photos.isNotEmpty) {
      // Si la photo demandée n'existe pas mais qu'il y en a d'autres, utiliser la première
      primaryPhotoUrl = photos.first;
    }
  }
  // ----- MÉTHODES D'ASSURANCE -----

/// Calculate insurance premium based on selected tranche
double calculateInsurancePremium() {
  return insuranceTranches[insurance_level]?['premium']?.toDouble() ?? 0.0;
}

/// Get maximum coverage for selected tranche
int getMaxInsuranceCoverage() {
  return insuranceTranches[insurance_level]?['maxValue'] ?? 0;
}

/// Generate display label for insurance tranche
String getInsuranceLabel() {
  if (insurance_level == 'none') return 'No insurance';
  
  final maxValue = getMaxInsuranceCoverage();
  return 'Up to \$$maxValue CAD';
}

/// Get recommended insurance level based on declared value
String getRecommendedInsuranceLevel(double declaredValue) {
  if (declaredValue <= 0) return 'none';
  
  for (final entry in insuranceTranches.entries) {
    if (entry.key == 'none') continue;
    
    final maxValue = entry.value['maxValue'];
    if (declaredValue <= maxValue) {
      return entry.key;
    }
  }
  
  // If value exceeds 5000 CAD, select maximum tranche
  return 'tranche_5000';
}
/*
/// Auto-update insurance level based on declared value
void updateInsuranceLevel() {
  if (declared_value != null && declared_value! > 0) {
    insurance_level = getRecommendedInsuranceLevel(declared_value!);
    insurance_fee = calculateInsurancePremium();
  } else {
    insurance_level = 'none';
    insurance_fee = 0.0;
  }
}*/

/// Validate insurance information
bool validateInsurance() {
  if (!isInsured) return true;
  
  if (declared_value == null || declared_value! <= 0) {
    validationErrors.add('Declared value required for insurance');
    return false;
  }
  
  if (declared_value! < 10.0) {
    validationErrors.add('Minimum declared value is \$10.00 CAD');
    return false;
  }
  
  final maxCoverage = getMaxInsuranceCoverage();
  if (declared_value! > maxCoverage && maxCoverage > 0) {
    validationErrors.add('Declared value (\$${declared_value!.toStringAsFixed(2)} CAD) exceeds maximum coverage (\$$maxCoverage CAD)');
    return false;
  }
  
  return true;
}
bool get isPaid => paymentStatus == 'paid';
bool get isEscrowed => paymentStatus == 'escrowed';
bool get isUnpaid => paymentStatus == 'unpaid';
bool get isRefunded => paymentStatus == 'refunded';


/// Calculate total price including insurance and platform fees
/*double calculateTotalPrice() {
  final basePrice = price ?? estimatedPrice ?? 0.0;
  final insuranceCost = isInsured ? calculateInsurancePremium() : 0.0;
  final platformCost = platform_fee ?? (basePrice * 0.20).clamp(2.0, double.infinity);
  final discount = discount_amount ?? 0.0;
  
  return (basePrice + insuranceCost + platformCost - discount).clamp(5.0, double.infinity);
}*/
/*
/// Get cost breakdown for display
Map<String, double> getCostBreakdown() {
  final basePrice = price ?? estimatedPrice ?? 0.0;
  
  return {
    'basePrice': basePrice,
    'insuranceFee': isInsured ? calculateInsurancePremium() : 0.0,
    'platformFee': platform_fee ?? (basePrice * 0.20).clamp(2.0, double.infinity),
    'discount': discount_amount ?? 0.0,
    'totalPrice': calculateTotalPrice(),
  };
}*/

/// Get all available insurance options for UI display
static List<Map<String, dynamic>> getInsuranceOptions() {
  return insuranceTranches.entries.map((entry) {
    final key = entry.key;
    final data = entry.value;
    
    return {
      'key': key,
      'maxValue': data['maxValue'],
      'premium': data['premium'],
      'label': key == 'none' ? 'No insurance' : 'Up to \$${data['maxValue']} CAD',
      'priceLabel': key == 'none' ? '' : '+\$${data['premium']} CAD',
    };
  }).toList();
}

/// Get insurance option by key
static Map<String, dynamic>? getInsuranceOption(String key) {
  if (!insuranceTranches.containsKey(key)) return null;
  
  final data = insuranceTranches[key]!;
  return {
    'key': key,
    'maxValue': data['maxValue'],
    'premium': data['premium'],
    'label': key == 'none' ? 'No insurance' : 'Up to \$${data['maxValue']} CAD',
    'priceLabel': key == 'none' ? '' : '+\$${data['premium']} CAD',
  };
}
  /// Traite les résultats d'une analyse d'image par IA pour extraire
  /// des informations utiles pour le colis (dimensions, catégorie, poids)
    /// Traite les résultats d'une analyse d'image par IA pour extraire
  /// des informations utiles pour le colis (dimensions, catégorie, poids)
  void parseAiResponse(Map<String, dynamic> aiResponse) {
    // Mise à jour des dimensions si détectées par l'IA
    if (aiResponse.containsKey('dimensions')) {
      // Applique les dimensions détectées par l'analyse d'image
      dimensions = aiResponse['dimensions'];
    }
    
    if (aiResponse.containsKey('detected_type')) {
      // Suggestion de catégorie basée sur l'analyse visuelle
      String detectedType = aiResponse['detected_type'];
      
      // Détermination de la catégorie selon le contenu détecté
      if (detectedType.contains('fragile')) {
        category = 'fragile';
      } else if (detectedType.contains('food') || 
                detectedType.contains('perishable')) {
        category = 'perishable';
      } else if (detectedType.contains('valuable') || 
                detectedType.contains('electronics')) {
        category = 'valuable';
      }
    }
    
    if (aiResponse.containsKey('estimated_weight')) {
      // Applique le poids estimé par l'analyse d'image, si disponible
      weight = (aiResponse['estimated_weight'] as num).toDouble();
    }
    
    // Conserve la réponse complète de l'IA pour référence ultérieure
    // et pour des traitements supplémentaires si nécessaire
    ai_recognition_results = aiResponse;
  }

  static ParcelModel fromMap(Map<String, dynamic> map) {
  return ParcelModel(
    // Identifiants
    id: map['id'],
    senderId: map['senderId'] ?? '',
    senderName: map['senderName'] ?? '',
    senderPhone: map['senderPhone'],
    
    // Informations du colis
    title: map['title'] ?? '',
    description: map['description'],
    pickupDescription: map['pickupDescription'] ?? '',
    deliveryDescription: map['deliveryDescription'] ?? '',
    weight: (map['weight'] ?? 0.0).toDouble(),
    size: map['size'] ?? '',
    dimensions: Map<String, dynamic>.from(map['dimensions'] ?? {
      'length': 0, 'width': 0, 'height': 0,
    }),
    category: map['category'] ?? 'normal',
    quantity: map['quantity'] ?? 1,
    photos: List<String>.from(map['photos'] ?? []),
    primaryPhotoUrl: map['primaryPhotoUrl'],
    
    // Adresses
    originAddress: map['originAddress'] ?? '',
    destinationAddress: map['destinationAddress'] ?? '',
    recipientName: map['recipientName'] ?? '',
    recipientPhone: map['recipientPhone'] ?? '',
    estimatedDistance: (map['estimatedDistance'] as num?)?.toDouble(),
    
    // Géolocalisation
    origin: _parseGeoFirePointFromMap(map['origin']),
    destination: _parseGeoFirePointFromMap(map['destination']),
    
    // Dates - ✅ Conversion sécurisée depuis String
    createdAt: _stringToDateTime(map['createdAt']) ?? DateTime.now(),
    last_edited: _stringToDateTime(map['last_edited']) ?? DateTime.now(),
    expiresAt: _stringToDateTime(map['expiresAt']),
    paidAt: _stringToDateTime(map['paidAt']),
    
    // Fenêtres temporelles
    pickup_window: _parseTimeWindow(map['pickup_window']),
    delivery_window: _parseTimeWindow(map['delivery_window']),
    
    // Prix et paiement
    price: (map['price'] as num?)?.toDouble(),
    estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble(),
    initialPrice: (map['initialPrice'] as num?)?.toDouble(),
    paymentId: map['paymentId'],
    paymentMethod: map['paymentMethod'] ?? 'pay_later',
    paymentStatus: map['paymentStatus'] ?? 'unpaid',
    discount_amount: (map['discount_amount'] as num?)?.toDouble(),
    promo_code_applied: map['promo_code_applied'],
    
    // Statut
    status: map['status'] ?? 'draft',
    draft: map['draft'] ?? true,
    completion_percentage: map['completion_percentage'] ?? 0,
    navigation_step: map['navigation_step'] ?? 0,
    
    // Assurance
    isInsured: map['isInsured'] ?? false,
    declared_value: (map['declared_value'] as num?)?.toDouble(),
    insurance_level: map['insurance_level'] ?? 'none',
    insurance_fee: (map['insurance_fee'] as num?)?.toDouble(),
    platform_fee: (map['platform_fee'] as num?)?.toDouble(),
    
    // Handling
    pickupHandling: map['pickupHandling'],
    deliveryHandling: map['deliveryHandling'],
    totalHandlingFee: (map['totalHandlingFee'] as num?)?.toDouble(),
    
    // Autres champs
    delivery_speed: map['delivery_speed'] ?? 'standard',
    matchId: map['matchId'],
    insuranceId: map['insuranceId'],
    ai_recognition_results: map['ai_recognition_results'],
    pickup_point_id: map['pickup_point_id'],
    delivery_point_id: map['delivery_point_id'],
    organizationId: map['organizationId'],
    bulk_import_id: map['bulk_import_id'],
    geoIndexReady: map['geoIndexReady'] ?? false,
    g: map['g'],
    validationErrors: List<String>.from(map['validationErrors'] ?? []),
  );
}

/// ✅ Méthodes helper pour la conversion inverse
static DateTime? _stringToDateTime(dynamic dateString) {
  if (dateString == null) return null;
  if (dateString is DateTime) return dateString;
  if (dateString is String && dateString.isNotEmpty) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('❌ Erreur conversion date: $dateString');
      return null;
    }
  }
  return null;
}

static GeoFirePoint? _parseGeoFirePointFromMap(dynamic geoData) {
  if (geoData == null) return null;
  
  try {
    if (geoData is Map<String, dynamic>) {
      final lat = geoData['latitude'];
      final lng = geoData['longitude'];
      if (lat != null && lng != null) {
        return GeoFirePoint(GeoPoint(lat.toDouble(), lng.toDouble()));
      }
    }
  } catch (e) {
    print('❌ Erreur parsing GeoFirePoint: $e');
  }
  return null;
}

static Map<String, dynamic> _parseTimeWindow(dynamic timeWindow) {
  if (timeWindow == null) return {};
  
  final Map<String, dynamic> window = Map<String, dynamic>.from(timeWindow);
  final converted = <String, dynamic>{};
  
  window.forEach((key, value) {
    if (value is String) {
      final dateTime = _stringToDateTime(value);
      converted[key] = dateTime != null ? Timestamp.fromDate(dateTime) : value;
    } else {
      converted[key] = value;
    }
  });
  
  return converted;
}
Map<String, dynamic> toMap() {
  return {
    // Identifiants
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhone': senderPhone,
    
    // Informations du colis
    'title': title,
    'description': description,
    'pickupDescription': pickupDescription,
    'deliveryDescription': deliveryDescription,
    'weight': weight,
    'size': size,
    'dimensions': dimensions,
    'category': category,
    'quantity': quantity,
    'photos': photos,
    'primaryPhotoUrl': primaryPhotoUrl,
    
    // Adresses et localisation
    'originAddress': originAddress,
    'destinationAddress': destinationAddress,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'estimatedDistance': estimatedDistance,
    
    // Géolocalisation - ✅ Conversion sécurisée
    'origin': origin != null ? {
      'latitude': origin!.latitude,
      'longitude': origin!.longitude,
    } : null,
    'destination': destination != null ? {
      'latitude': destination!.latitude,
      'longitude': destination!.longitude,
    } : null,
    
    // Dates - ✅ Conversion sécurisée des Timestamp
    'createdAt': _timestampToString(createdAt),
    'last_edited': _timestampToString(last_edited),
    'expiresAt': _timestampToString(expiresAt),
    'paidAt': _timestampToString(paidAt),
    
    // Fenêtres temporelles - ✅ Conversion des Timestamp dans les Maps
    'pickup_window': _convertTimeWindow(pickup_window),
    'delivery_window': _convertTimeWindow(delivery_window),
    
    // Prix et paiement
    'price': price,
    'estimatedPrice': estimatedPrice,
    'initialPrice': initialPrice,
    'paymentId': paymentId,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'discount_amount': discount_amount,
    'promo_code_applied': promo_code_applied,
    
    // Statut et workflow
    'status': status,
    'draft': draft,
    'completion_percentage': completion_percentage,
    'navigation_step': navigation_step,
    
    // Assurance et frais
    'isInsured': isInsured,
    'declared_value': declared_value,
    'insurance_level': insurance_level,
    'insurance_fee': insurance_fee,
    'platform_fee': platform_fee,
    
    // Handling et frais
    'pickupHandling': pickupHandling,
    'deliveryHandling': deliveryHandling,
    'totalHandlingFee': totalHandlingFee,
    
    // Préférences et options
    'delivery_speed': delivery_speed,
    'matchId': matchId,
    'insuranceId': insuranceId,
    
    // Métadonnées et avancé
    'ai_recognition_results': ai_recognition_results,
    'pickup_point_id': pickup_point_id,
    'delivery_point_id': delivery_point_id,
    'organizationId': organizationId,
    'bulk_import_id': bulk_import_id,
    'geoIndexReady': geoIndexReady,
    'g': g,
    'validationErrors': validationErrors,
  };
}

/// ✅ Méthode helper pour convertir les Timestamp de façon sécurisée
String? _timestampToString(dynamic timestamp) {
  if (timestamp == null) return null;
  
  if (timestamp is Timestamp) {
    return timestamp.toDate().toIso8601String();
  } else if (timestamp is DateTime) {
    return timestamp.toIso8601String();
  } else if (timestamp is String) {
    return timestamp;
  }
  
  return null;
}

/// ✅ Méthode helper pour convertir les fenêtres temporelles
Map<String, dynamic> _convertTimeWindow(Map<String, dynamic> timeWindow) {
  final converted = <String, dynamic>{};
  
  timeWindow.forEach((key, value) {
    if (value is Timestamp) {
      converted[key] = value.toDate().toIso8601String();
    } else if (value is DateTime) {
      converted[key] = value.toIso8601String();
    } else {
      converted[key] = value;
    }
  });
  
  return converted;
}
}
