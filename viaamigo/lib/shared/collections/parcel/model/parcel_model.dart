import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  /// Identifiant unique du colis (généré par Firestore)
  String? id;
  
  /// ID de l'utilisateur qui envoie le colis
  String senderId;
  
  /// Nom complet de l'expéditeur
  String senderName;
  
  /// Numéro de téléphone de l'expéditeur (optionnel)
  String? senderPhone;
  
  /// Titre court décrivant le contenu du colis
  String title;
  
  /// Description détaillée du colis et de son contenu
  String description;
  
  /// Poids du colis en kilogrammes
  double weight;
  
  /// Taille standard du colis (énumération sous forme de string)
  /// Valeurs possibles: "small", "medium", "large", "custom"
  String size;
  
  /// Dimensions précises du colis en cm {length, width, height}
  /// Utilisé principalement quand size = "custom"
  Map<String, dynamic> dimensions;
  
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
  
  /// Indique si des jours alternatifs de livraison sont acceptables
  bool flexible_days;
  
  /// Indique si le ramassage peut être effectué en avance
  bool advanced_pickup_allowed;
  
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
    required this.senderId,
    required this.senderName,
    this.senderPhone,
    required this.title,
    required this.description,
    required this.weight,
    required this.size,
    required this.dimensions,
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
    this.flexible_days = false,
    this.advanced_pickup_allowed = false,
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

  /// Crée un modèle de colis vide avec les valeurs minimales requises
  /// Utilisé pour initialiser un nouveau colis en mode brouillon
  factory ParcelModel.empty(String userId, String userName) {
    final now = DateTime.now();
    return ParcelModel(
      senderId: userId,
      senderName: userName,
      title: '',
      description: '',
      weight: 0.0,
      size: 'medium',
      dimensions: {
        'length': 0,
        'width': 0,
        'height': 0,
      },
      category: 'normal',
      originAddress: '',
      destinationAddress: '',
      recipientName: '',
      recipientPhone: '',
      createdAt: now,
      last_edited: now,
      pickup_window: {
        'start_time': Timestamp.fromDate(now.add(Duration(days: 1))),
        'end_time': Timestamp.fromDate(now.add(Duration(days: 1, hours: 2))),
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
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhone: data['senderPhone'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      weight: data['weight']?.toDouble() ?? 0.0,
      size: data['size'] ?? 'medium',
      dimensions: data['dimensions'] ?? {'length': 0, 'width': 0, 'height': 0},
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
      flexible_days: data['flexible_days'] ?? false,
      advanced_pickup_allowed: data['advanced_pickup_allowed'] ?? false,
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
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'title': title,
      'description': description,
      'weight': weight,
      'size': size,
      'dimensions': dimensions,
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
      'flexible_days': flexible_days,
      'advanced_pickup_allowed': advanced_pickup_allowed,
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
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? title,
    String? description,
    double? weight,
    String? size,
    Map<String, dynamic>? dimensions,
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
    bool? flexible_days,
    bool? advanced_pickup_allowed,
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
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      size: size ?? this.size,
      dimensions: dimensions ?? this.dimensions,
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
      flexible_days: flexible_days ?? this.flexible_days,
      advanced_pickup_allowed: advanced_pickup_allowed ?? this.advanced_pickup_allowed,
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
    if (description.isNotEmpty) completedFields++;
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

  /// Valide toutes les données du colis
  /// Remplit la liste validationErrors avec les problèmes détectés
  /// Retourne true si le colis est valide, false sinon
  bool validate() {
    validationErrors.clear();
    
    // Vérification des champs textuels obligatoires
    if (title.isEmpty) validationErrors.add('Titre manquant');
    if (description.isEmpty) validationErrors.add('Description manquante');
    if (weight <= 0) validationErrors.add('Poids invalide');
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
    if (isInsured && (declared_value == null || declared_value! <= 0)) {
      validationErrors.add('Valeur déclarée requise pour l\'assurance');
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
      'title': title,
      'thumbnail': mainPhotoUrl,
      'fromTo': '$originAddress → $destinationAddress',
      'distance': '${estimatedDistance?.toStringAsFixed(1) ?? "?"} km',
      'status': _getDisplayStatus(),
      'price': price?.toStringAsFixed(2) ?? estimatedPrice?.toStringAsFixed(2) ?? '?',
      'weight': '${weight.toStringAsFixed(1)} kg',
      'size': _getDisplaySize(),
      'pickupDate': _formatDisplayDate(getPickupStartTime()),
      'isUrgent': delivery_speed == 'express',
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
      case 'small': return 'Petit';
      case 'medium': return 'Moyen';
      case 'large': return 'Grand';
      case 'custom': return 'Sur mesure';
      default: return 'Inconnu';
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
}
