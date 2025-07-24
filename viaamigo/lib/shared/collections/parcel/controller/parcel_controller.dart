// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_dimension_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/parcel/services/parcel_service.dart';



class ParcelsController extends GetxController {
  final ParcelsService _parcelsService = ParcelsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ✅ AJOUT: Constante pour la limite de photos
  static const int MAX_PHOTOS = 4;
  
  
  // Variables observables
  Rx<ParcelModel?> currentParcel = Rx<ParcelModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;
  RxString errorMessage = ''.obs;
  RxInt currentStep = 0.obs;
  RxBool autoSave = true.obs; // Option de sauvegarde automatique
  
  
  // État du formulaire
  final RxBool titleValid = false.obs;
  final RxBool descriptionValid = false.obs;
  final RxBool dimensionValid = false.obs;
  final RxBool sizeValid = false.obs;
  final RxBool categoryValid = false.obs;
  final RxBool recipientNameValid = false.obs;
  final RxBool recipientPhoneValid = false.obs;
  final RxBool pickupDescriptionValid = false.obs;
  final RxBool deliveryDescriptionValid = false.obs;
  final RxBool senderNameValid = false.obs;
  final RxBool weightValid = false.obs;
  final RxBool originValid = false.obs;
  final RxBool destinationValid = false.obs;
  final RxBool recipientValid = false.obs;

    // ✅ NOUVEAUX OBSERVABLES D'ASSURANCE
  final RxBool isInsured = false.obs;
  final RxString insuranceLevel = 'none'.obs;
  final RxDouble declaredValue = 0.0.obs;
  final RxDouble insuranceFee = 0.0.obs;
  final RxDouble platformFee = 0.0.obs;
  final RxDouble finalPrice = 0.0.obs;
   final RxString paymentStatus = 'unpaid'.obs;
final RxString paymentId = ''.obs;
final Rx<DateTime?> paidAt = Rx<DateTime?>(null);

  // AMÉLIORATION: Observables pour la liste des photos
  RxList<String> photosList = <String>[].obs;
  RxString primaryPhoto = ''.obs;
  
  // AMÉLIORATION: Liste observable des erreurs de validation
  RxList<String> validationErrorsList = <String>[].obs;
  
  // Getters utiles
  bool get isReadyToPublish => currentParcel.value?.isReadyToPublish() ?? false;
  int get completionPercentage => currentParcel.value?.completion_percentage ?? 0;
  bool get isDraft => currentParcel.value?.draft ?? true;
  
  // Initialiser un nouveau colis ou récupérer un brouillon existant
  Future<void> initParcel({String? existingParcelId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Récupérer les informations de l'utilisateur actuel
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      
      if (existingParcelId != null) {
        // Charger un parcel existant
        currentParcel.value = await _parcelsService.getParcelById(existingParcelId);
        paymentStatus.value = currentParcel.value!.paymentStatus;
        paymentId.value = currentParcel.value!.paymentId ?? '';
        paidAt.value = currentParcel.value!.paidAt;

        // AMÉLIORATION: Synchroniser les observables avec le modèle
        photosList.value = List<String>.from(currentParcel.value!.photos);
        primaryPhoto.value = currentParcel.value!.primaryPhotoUrl ?? '';
        validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
      } else {
        // Créer un nouveau parcel vide
        final now = DateTime.now();
        final emptyParcel = ParcelModel(
          senderId: user.uid,
          paymentId: '',
          paymentStatus: 'unpaid',
          paidAt: null,
          senderName: user.displayName ?? 'User',
          title: '',
          description: '',
          pickupDescription: '',
          deliveryDescription: '',
          quantity: 1,
          senderPhone: user.phoneNumber ?? '',
          weight: 0.0,
          size: '', // Taille par défaut
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
            'start_time': Timestamp.fromDate(now.add(Duration(days: 0))),
            'end_time': Timestamp.fromDate(now.add(Duration(days: 7, hours: 2))),
          },
          delivery_window: {
            'start_time': Timestamp.fromDate(now.add(Duration(days: 0))),
            'end_time': Timestamp.fromDate(now.add(Duration(days: 14, hours: 4))),
          },
          draft: true,
          completion_percentage: 0,
          navigation_step: 0,
          status: 'draft',
          isInsured: false,
          insurance_level: 'none',
          insurance_fee: 0.0,        // ✅ NOUVEAU
          platform_fee: 0.0,
          delivery_speed: 'standard',
          photos: [],
          geoIndexReady: false
        );
        
        // Créer dans Firestore et récupérer l'ID
        final parcelId = await _parcelsService.createEmptyParcel(emptyParcel);
        emptyParcel.id = parcelId;
        currentParcel.value = emptyParcel;
      }
      
      // Définir l'étape initiale
      currentStep.value = currentParcel.value!.navigation_step;
      
      // Valider l'état initial des champs
      validateFields();
      
    } catch (e) {
      errorMessage.value = 'Erreur: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Valider l'état des champs
  void validateFields() {
    if (currentParcel.value == null) return;
    
    titleValid.value = currentParcel.value!.title.isNotEmpty;
   // descriptionValid.value = currentParcel.value!.description.isNotEmpty;
    weightValid.value = currentParcel.value!.weight > 0;
    originValid.value = currentParcel.value!.originAddress.isNotEmpty;
    destinationValid.value = currentParcel.value!.destinationAddress.isNotEmpty;
    recipientValid.value = 
        currentParcel.value!.recipientName.isNotEmpty && 
        currentParcel.value!.recipientPhone.isNotEmpty;
        
// ✅ NOUVEAU : Synchroniser les observables d'assurance
  isInsured.value = currentParcel.value!.isInsured;
  insuranceLevel.value = currentParcel.value!.insurance_level;
  declaredValue.value = currentParcel.value!.declared_value ?? 0.0;
  insuranceFee.value = currentParcel.value!.insurance_fee ?? 0.0;
  platformFee.value = currentParcel.value!.platform_fee ?? 0.0;
  
  // Calculer le prix final
  //finalPrice.value = currentParcel.value!.calculateTotalPrice();
      
  // AMÉLIORATION: Mettre à jour la liste des erreurs de validation
  currentParcel.value!.validate();
  validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
  }
  
  // Sauvegarder le colis (en mode brouillon)
  Future<void> saveParcel() async {
    if (currentParcel.value == null) return;
    
    isSaving.value = true;
    
    try {
      // Mettre à jour les timestamps et l'étape
      currentParcel.value!.last_edited = DateTime.now();
      currentParcel.value!.navigation_step = currentStep.value;
      
      // Calculer le pourcentage de complétion
      currentParcel.value!.completion_percentage = 
          currentParcel.value!.calculateCompletionPercentage();
      
       // Calculer les frais de manutention
    computeTotalHandlingFee();
      
      await _parcelsService.updateParcel(currentParcel.value!);
      validateFields(); // AMÉLIORATION: Revalider après sauvegarde
    } catch (e) {
      errorMessage.value = 'Erreur lors de la sauvegarde: ${e.toString()}';
    } finally {
      isSaving.value = false;
    }
  }
  
  // Publier le colis (passer de brouillon à publié)
  Future<bool> publishParcel() async {
    if (currentParcel.value == null) return false;
    
    // Valider le colis avant publication
    if (!currentParcel.value!.validate()) {
      validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
      errorMessage.value = 'Erreurs de validation:\n${validationErrorsList.join('\n')}';
      return false;
    }
    
    isSaving.value = true;
    
    try {
      // Finaliser le parcel pour publication
      await _parcelsService.publishParcel(currentParcel.value!);
      
      // Mettre à jour le modèle local
      currentParcel.value!.draft = false;
      currentParcel.value!.status = 'pending';
      
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la publication: ${e.toString()}';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
   Future<void> updateField(String fieldName, dynamic value) async {
    if (currentParcel.value == null) return;
    
    // Mettre à jour le champ approprié
    switch (fieldName) {
      case 'title':
        currentParcel.value = currentParcel.value!.copyWith(title: value);
        titleValid.value = value.toString().isNotEmpty;
        break;
      case 'description':
        currentParcel.value = currentParcel.value!.copyWith(description: value);
        descriptionValid.value = value.toString().isNotEmpty;
        break;
      case 'pickupDescription':
        currentParcel.value = currentParcel.value!.copyWith(pickupDescription: value);
        break;
      case 'deliveryDescription':
        currentParcel.value = currentParcel.value!.copyWith(deliveryDescription: value);
        break;
      case 'weight':
    
          double weightValue = double.parse(value.toString());
          currentParcel.value = currentParcel.value!.copyWith(weight: weightValue);
          weightValid.value = weightValue > 0;
          
          // Recalculer le prix estimé avec la nouvelle méthode
          if (weightValid.value && currentParcel.value!.estimatedDistance != null) {
            double estimatedPrice = PriceCalculator.calculateFromParcel(currentParcel.value!);
            currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: estimatedPrice);
            
            if (currentParcel.value!.initialPrice == null) {
              currentParcel.value = currentParcel.value!.copyWith(initialPrice: estimatedPrice);
            }
          }
        break;
      case 'size':
        currentParcel.value = currentParcel.value!.copyWith(
          size: value,
          //dimensions: autoDimensions  // ✅ Définit automatiquement les dimensions
        );
        break;
      case 'category':
        currentParcel.value = currentParcel.value!.copyWith(category: value);
        break;
      case 'recipientName':
        currentParcel.value = currentParcel.value!.copyWith(recipientName: value);
        validateRecipientFields();
        break;
      case 'recipientPhone':
        currentParcel.value = currentParcel.value!.copyWith(recipientPhone: value);
        validateRecipientFields();
        break;
      case 'delivery_speed':
         currentParcel.value = currentParcel.value!.copyWith(delivery_speed: value);
  
        // Recalculer le prix si nécessaire
        if (currentParcel.value!.estimatedDistance != null) {
          double estimatedPrice = PriceCalculator.calculateFromParcel(currentParcel.value!);
          currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: estimatedPrice);
          //currentParcel.value = currentParcel.value!.copyWith(initialPrice: estimatedPrice);
        }
        break;
      case 'insurance_level':
        currentParcel.value = currentParcel.value!.copyWith(
          insurance_level: value,
          isInsured: value != 'none'
        );
       /* if (currentParcel.value!.isInsured) {
        double insuranceFee = currentParcel.value!.calculateInsurancePremium();
        currentParcel.value = currentParcel.value!.copyWith(insurance_fee: insuranceFee);
      } else {
        currentParcel.value = currentParcel.value!.copyWith(insurance_fee: 0.0);
      }*/
        break;
      case 'declared_value':
        currentParcel.value = currentParcel.value!.copyWith(declared_value: value);
        // ✅ NOUVEAU : Mise à jour automatique du niveau d'assurance
      /*if (currentParcel.value!.isInsured) {
        currentParcel.value!.updateInsuranceLevel();
        // Forcer la mise à jour du modèle
        currentParcel.value = currentParcel.value!.copyWith(
          insurance_level: currentParcel.value!.insurance_level,
          insurance_fee: currentParcel.value!.insurance_fee
        );
      }*/
        break;
          // ✅ NOUVEAUX CHAMPS D'ASSURANCE :
    case 'isInsured':
      currentParcel.value = currentParcel.value!.copyWith(isInsured: value);
      if (!value) {
        // Désactiver l'assurance
        currentParcel.value = currentParcel.value!.copyWith(
          insurance_level: 'none',
          insurance_fee: 0.0,
          declared_value: null
        );
      }
      break; 
     case 'insurance_fee':
      currentParcel.value = currentParcel.value!.copyWith(insurance_fee: value);

      break;   
      case 'dimensions':
        currentParcel.value = currentParcel.value!.copyWith(dimensions: value);
        break;
      case 'pickupHandling':
        currentParcel.value = currentParcel.value!.copyWith(pickupHandling: value);
        // Recalculer les frais totaux
        computeTotalHandlingFee();
        break;
      case 'deliveryHandling':
        currentParcel.value = currentParcel.value!.copyWith(deliveryHandling: value);
        // Recalculer les frais totaux
        computeTotalHandlingFee();
        break;
      case 'platform_fee':
  currentParcel.value = currentParcel.value!.copyWith(platform_fee: value);
  break;
case 'price':
  currentParcel.value = currentParcel.value!.copyWith(price: value);
  break;
case 'initialPrice':
  currentParcel.value = currentParcel.value!.copyWith(initialPrice: value);
  break;
case 'discount_amount':
  currentParcel.value = currentParcel.value!.copyWith(discount_amount: value);
  break;
case 'promo_code_applied':
  currentParcel.value = currentParcel.value!.copyWith(promo_code_applied: value);
  break;
  case 'paymentStatus':
  currentParcel.value = currentParcel.value!.copyWith(paymentStatus: value);
  paymentStatus.value = value;
  break;

case 'paymentId':
  currentParcel.value = currentParcel.value!.copyWith(paymentId: value);
  paymentId.value = value;
  break;

case 'paidAt':
  currentParcel.value = currentParcel.value!.copyWith(paidAt: value);
  paidAt.value = value;
  break;

    }
    syncObservables();
    // Sauvegarder automatiquement après modifications si activé
    if (autoSave.value) {
      await saveParcel();
    }
  }
   /// Recalcule le prix complet avec tous les paramètres
  void recalculatePrice() {
    if (currentParcel.value?.estimatedDistance == null) return;
    
    double newPrice = PriceCalculator.calculateFromParcel(currentParcel.value!);
    currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: newPrice);
    
    // Debug détaillé
    final breakdown = PriceCalculator.calculateBreakdownFromParcel(currentParcel.value!);
    print("💰 NOUVEAU PRIX: ${breakdown.total.toStringAsFixed(2)} CAD");
    print(breakdown.toString());
  }

  /// Obtient le détail complet du calcul
  PriceBreakdown getPriceBreakdown() {
    if (currentParcel.value == null) {
      // Retourner un breakdown vide si pas de parcel
      return PriceBreakdown(
        distanceKm: 0.0,
        weightKg: 0.0,
        basePrice: 0.0,
        weightPrice: 0.0,
        volumeSurcharge: 0.0,
        speedMultiplier: 1.0,
        adjustedPrice: 0.0,
        handlingFees: 0.0,
        insuranceFee: 0.0,
        promoDiscount: 0.0,
        platformFee: 0.0,
        subtotal: 0.0,
        total: 0.0,
        minimumApplied: false,
        maximumApplied: false,
        quantity: 1,
      );
    }
    return PriceCalculator.calculateBreakdownFromParcel(currentParcel.value!);
  }
  /// Met à jour une dimension spécifique (longueur, largeur, hauteur)
Future<void> updateDimension(String key, String value) async {
  if (currentParcel.value == null) return;

  final dims = Map<String, dynamic>.from(currentParcel.value!.dimensions);
  dims[key] = double.tryParse(value) ?? 0;

  await updateField('dimensions', dims);
}
/*Map<String, dynamic> _getSizeDimensions(String size) {
  switch (size) {
    case 'SIZE S':
      return ParcelDimensions.small().toMap();
    case 'SIZE M':
      return ParcelDimensions.medium().toMap();
    case 'SIZE L':
      return ParcelDimensions.large().toMap();
    case 'SIZE XL':
      return ParcelDimensions.extraLarge().toMap();
    case 'SIZE XXL':
      return ParcelDimensions.doubleExtraLarge().toMap();
    default:
      return {'length': 0, 'width': 0, 'height': 0};
  }
}*/

  
  // Valider les champs du destinataire
  void validateRecipientFields() {
    final parcel = currentParcel.value;
    if (parcel == null) return;
    
    recipientValid.value = 
        parcel.recipientName.isNotEmpty && 
        parcel.recipientPhone.isNotEmpty;
  }
  
  // Définir l'adresse d'origine
  Future<void> setOriginAddress(String address, double lat, double lng) async {
    if (currentParcel.value == null) return;
    
 final point = GeoFirePoint(GeoPoint(lat, lng));

    
    currentParcel.value = currentParcel.value!.copyWith(
      originAddress: address,
      origin: point
    );
    
    originValid.value = address.isNotEmpty;
    
    // Recalculer la distance et le prix si la destination est aussi définie
    if (currentParcel.value!.destination != null) {
      await calculateDistanceAndPrice();
    }
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  
  // Définir l'adresse de destination
  Future<void> setDestinationAddress(String address, double lat, double lng) async {
    if (currentParcel.value == null) return;
    
 final point = GeoFirePoint(GeoPoint(lat, lng));

    
    currentParcel.value = currentParcel.value!.copyWith(
      destinationAddress: address,
      destination: point
    );
    
    destinationValid.value = address.isNotEmpty;
    
    // Recalculer la distance et le prix si l'origine est aussi définie
    if (currentParcel.value!.origin != null) {
      await calculateDistanceAndPrice();
    }
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  Future<void>calculateEstimatePrice() async {
    if (currentParcel.value == null) return;
    
    try {
      // Recalculer le prix estimé
      double estimatedPrice = PriceCalculator.calculateFromParcel(currentParcel.value!);
      
      // Mettre à jour le modèle
      currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: estimatedPrice);
      
      // Si c'est la première fois, initialiser le prix proposé aussi
      //if (currentParcel.value!.initialPrice = null) {
        currentParcel.value = currentParcel.value!.copyWith(initialPrice: estimatedPrice);
     // }
      
      if (autoSave.value) {
        await saveParcel();
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du calcul du prix: ${e.toString()}';
    }
  }
  // Calculer la distance et le prix estimé
  Future<void> calculateDistanceAndPrice() async {
    if (currentParcel.value?.origin == null || currentParcel.value?.destination == null) return;
    
    try {
      // AMÉLIORATION: Utiliser la classe utilitaire GeoUtils
      double distance = GeoUtils.calculateDistance(
        currentParcel.value!.origin!,
        currentParcel.value!.destination!
      );
      
      // Mettre à jour la distance
      currentParcel.value = currentParcel.value!.copyWith(estimatedDistance: distance);
      
      // Calculer le prix estimé avec le service dédié
      double estimatedPrice = PriceCalculator.calculateFromParcel(
        currentParcel.value!,
      );
      
      // Mettre à jour les prix
      currentParcel.value = currentParcel.value!.copyWith(
        estimatedPrice: estimatedPrice,
        initialPrice:  estimatedPrice // Initialiser prix si null
      );
      
      if (autoSave.value) {
        await saveParcel();
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du calcul de la distance: ${e.toString()}';
    }
  }
  //handling fees
  void computeTotalHandlingFee() {
  final pickupFee = currentParcel.value?.pickupHandling?['estimatedFee'] ?? 0.0;
  final deliveryFee = currentParcel.value?.deliveryHandling?['estimatedFee'] ?? 0.0;
  final total = (pickupFee as num).toDouble() + (deliveryFee as num).toDouble();

  currentParcel.value = currentParcel.value!.copyWith(totalHandlingFee: total);
}

  
  // AMÉLIORATION: Ajouter une photo
  Future<void> addPhoto(String photoUrl) async {
    if (currentParcel.value == null) return;
    // ✅ NOUVEAU: Vérifier la limite avant d'ajouter
  final currentPhotos = currentParcel.value!.photos;
  if (currentPhotos.length >= MAX_PHOTOS) {
    errorMessage.value = 'Limite de $MAX_PHOTOS photos atteinte';
    throw Exception('Limite de $MAX_PHOTOS photos atteinte');
  }
    
    // Copier la liste existante et ajouter la nouvelle photo
    List<String> updatedPhotos = List<String>.from(currentParcel.value!.photos);
    updatedPhotos.add(photoUrl);
    
    // Mettre à jour le modèle
    currentParcel.value = currentParcel.value!.copyWith(photos: updatedPhotos);
    
    // Si c'est la première photo, la définir comme principale
    if (currentParcel.value!.primaryPhotoUrl == null && updatedPhotos.length == 1) {
      currentParcel.value = currentParcel.value!.copyWith(primaryPhotoUrl: photoUrl);
      primaryPhoto.value = photoUrl;
    }
    
    // Mettre à jour l'observable
    photosList.value = updatedPhotos;
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  // ✅ NOUVEAU: Vérifier si on peut ajouter plus de photos
bool canAddMorePhotos() {
  if (currentParcel.value == null) return false;
  return currentParcel.value!.photos.length < MAX_PHOTOS;
}

// ✅ NOUVEAU: Obtenir le nombre de photos restantes
int getRemainingPhotoSlots() {
  if (currentParcel.value == null) return MAX_PHOTOS;
  return MAX_PHOTOS - currentParcel.value!.photos.length;
}

// ✅ NOUVEAU: Getter pour la limite de photos
int get maxPhotos => MAX_PHOTOS;
  
  // AMÉLIORATION: Supprimer une photo
  Future<void> removePhoto(String photoUrl) async {
    if (currentParcel.value == null) return;
    
    // Copier la liste existante et supprimer la photo
    List<String> updatedPhotos = List<String>.from(currentParcel.value!.photos);
    updatedPhotos.remove(photoUrl);
    
    // Mettre à jour le modèle
    currentParcel.value = currentParcel.value!.copyWith(photos: updatedPhotos);
    
    // Si c'était la photo principale, réinitialiser
    if (currentParcel.value!.primaryPhotoUrl == photoUrl) {
      String? newPrimary = updatedPhotos.isNotEmpty ? updatedPhotos.first : null;
      currentParcel.value = currentParcel.value!.copyWith(primaryPhotoUrl: newPrimary);
      primaryPhoto.value = newPrimary ?? '';
    }
    
    // Mettre à jour l'observable
    photosList.value = updatedPhotos;
    
      // ✅ NOUVEAU: Reset l'erreur si on est sous la limite
  if (updatedPhotos.length < MAX_PHOTOS && errorMessage.value.contains('Limite de $MAX_PHOTOS photos')) {
    errorMessage.value = '';
  }
    if (autoSave.value) {
      await saveParcel();
    }
  }
  
  // AMÉLIORATION: Définir une photo comme principale
  Future<void> setAsPrimaryPhoto(String photoUrl) async {
    if (currentParcel.value == null) return;
    
    if (currentParcel.value!.photos.contains(photoUrl)) {
      currentParcel.value = currentParcel.value!.copyWith(primaryPhotoUrl: photoUrl);
      primaryPhoto.value = photoUrl;
      
      if (autoSave.value) {
        await saveParcel();
      }
      
      // Appel au service pour stocker la modification
      await _parcelsService.setAsPrimaryPhoto(currentParcel.value!.id!, photoUrl);
    }
  }
  
  // Définir la fenêtre de ramassage
  Future<void> setPickupWindow(DateTime start, DateTime end) async {
    if (currentParcel.value == null) return;
    
    // Créer l'objet TimeWindow typé
    TimeWindow window = TimeWindow(start_time: start, end_time: end);
    
    // Mettre à jour via la propriété typée
    currentParcel.value!.typedPickupWindow = window;
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  
  // Définir la fenêtre de livraison
  Future<void> setDeliveryWindow(DateTime start, DateTime end) async {
    if (currentParcel.value == null) return;
    
    // Créer l'objet TimeWindow typé
    TimeWindow window = TimeWindow(start_time: start, end_time: end);
    
    // Mettre à jour via la propriété typée
    currentParcel.value!.typedDeliveryWindow = window;
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  
  // Avancer à l'étape suivante du formulaire
  Future<void> nextStep() async {
    debugPrint('Étape actuelle : ${currentStep.value}');

    currentStep.value++;
    
    // Mettre à jour l'étape dans le modèle
    if (currentParcel.value != null) {
      currentParcel.value = currentParcel.value!.copyWith(navigation_step: currentStep.value);
      
      if (autoSave.value) {
        await saveParcel();
      }
    }
  }
  
  // Revenir à l'étape précédente
  Future<void> previousStep() async {

    if (currentStep.value > 0) {
      currentStep.value--;
      
      // Mettre à jour l'étape dans le modèle
      if (currentParcel.value != null) {
        currentParcel.value = currentParcel.value!.copyWith(navigation_step: currentStep.value);
        
        if (autoSave.value) {
          await saveParcel();
        }
      }
    }
  }
  
  // Obtenir les brouillons récents
  Future<List<ParcelModel>> getRecentDrafts() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    return await _parcelsService.getUserRecentDrafts(user.uid);
  }
  
  // Stream des colis en attente
  Stream<List<ParcelModel>> getPendingParcels() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _parcelsService.getUserPendingParcels(user.uid);
  }
  
  // AMÉLIORATION: Traiter les résultats d'analyse IA des photos
  Future<void> processAiPhotoAnalysis(Map<String, dynamic> aiResponse) async {
    if (currentParcel.value == null) return;
    
    // Utiliser la méthode dédiée du modèle pour parser la réponse
    currentParcel.value!.parseAiResponse(aiResponse);
    
    // Si l'IA a détecté des dimensions et qu'elles sont vides, les appliquer
    ParcelDimensions current = currentParcel.value!.typedDimensions;
    
    if (current.length <= 0 && current.width <= 0 && current.height <= 0) {
      if (currentParcel.value!.typedAiResults?.suggested_dimensions != null) {
        currentParcel.value!.typedDimensions = 
            currentParcel.value!.typedAiResults!.suggested_dimensions!;
      }
    }
    
    // Si l'IA a détecté une catégorie et que celle-ci est "normal", l'appliquer
    String suggestedCategory = currentParcel.value!.typedAiResults?.suggestCategory() ?? 'normal';
    if (currentParcel.value!.category == 'normal' && suggestedCategory != 'normal') {
      currentParcel.value = currentParcel.value!.copyWith(category: suggestedCategory);
    }
    
    if (autoSave.value) {
      await saveParcel();
    }
  }
  
  // AMÉLIORATION: Obtenir les données pour affichage UI
  Map<String, dynamic> getDisplayData() {
    if (currentParcel.value == null) {
      return {};
    }
    
    return currentParcel.value!.toDisplayCard();
  }
  // ✅ NOUVELLES MÉTHODES D'ASSURANCE

/// Sélectionne automatiquement la tranche d'assurance appropriée
/// Sélectionne automatiquement la tranche d'assurance appropriée
Future<void> updateInsuranceForDeclaredValue(double declaredValue) async {
  if (currentParcel.value == null) return;
  
  // Utiliser la méthode du modèle pour recommander le niveau
  String recommendedLevel = currentParcel.value!.getRecommendedInsuranceLevel(declaredValue);
  
  // Mettre à jour le niveau et les frais
  currentParcel.value = currentParcel.value!.copyWith(
    declared_value: declaredValue,
    insurance_level: recommendedLevel,
  );
  
  // ✅ AMÉLIORATION : Recalculer les frais après la mise à jour
  double newInsuranceFee = currentParcel.value!.calculateInsurancePremium();
  currentParcel.value = currentParcel.value!.copyWith(insurance_fee: newInsuranceFee);
  
  // Synchroniser les observables
  syncObservables();
  
  if (autoSave.value) {
    await saveParcel();
  }
}
void syncObservables() {
  if (currentParcel.value == null) return;
  
  // Synchroniser les observables d'assurance
  isInsured.value = currentParcel.value!.isInsured;
  insuranceLevel.value = currentParcel.value!.insurance_level;
  declaredValue.value = currentParcel.value!.declared_value ?? 0.0;
  insuranceFee.value = currentParcel.value!.insurance_fee ?? 0.0;
  platformFee.value = currentParcel.value!.platform_fee ?? 0.0;
  //finalPrice.value = currentParcel.value!.calculateTotalPrice();
  
  // Synchroniser les autres observables
  photosList.value = List<String>.from(currentParcel.value!.photos);
  primaryPhoto.value = currentParcel.value!.primaryPhotoUrl ?? '';
  validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
  paymentStatus.value = currentParcel.value!.paymentStatus;
paymentId.value = currentParcel.value!.paymentId ?? '';
paidAt.value = currentParcel.value!.paidAt;

}
bool get isPaid => paymentStatus.value == 'paid';
bool get isEscrowed => paymentStatus.value == 'escrowed';
bool get isUnpaid => paymentStatus.value == 'unpaid';
bool get isRefunded => paymentStatus.value == 'refunded';


/// Active/désactive l'assurance
Future<void> toggleInsurance(bool isEnabled) async {
  if (currentParcel.value == null) return;
  
  if (isEnabled) {
    currentParcel.value = currentParcel.value!.copyWith(
      isInsured: true,
      insurance_level: 'tranche_150', // Niveau par défaut
    );
  } else {
    currentParcel.value = currentParcel.value!.copyWith(
      isInsured: false,
      insurance_level: 'none',
      insurance_fee: 0.0,
      declared_value: null
    );
  }
  
  if (autoSave.value) {
    await saveParcel();
  }
}

/// Obtient les options d'assurance disponibles
List<Map<String, dynamic>> getInsuranceOptions() {
  return ParcelModel.getInsuranceOptions();
}

/// Obtient les détails d'une option d'assurance
Map<String, dynamic>? getInsuranceOption(String key) {
  return ParcelModel.getInsuranceOption(key);
}

/// Valide les informations d'assurance
bool validateInsuranceInfo() {
  if (currentParcel.value == null) return false;
  return currentParcel.value!.validateInsurance();
}
/// Calcule le prix total incluant tous les frais
/*
double calculateTotalWithInsurance() {
  if (currentParcel.value == null) return 0.0;
  
  return currentParcel.value!.calculateTotalPrice();
}
*/
/// Obtient le détail des coûts avec assurance
/*
Map<String, double> getCostBreakdownWithInsurance() {
  if (currentParcel.value == null) return {};
  
  return currentParcel.value!.getCostBreakdown();
}*/
}