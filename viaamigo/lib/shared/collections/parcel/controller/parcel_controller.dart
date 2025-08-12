// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_dimension_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/parcel/services/firebase_storage_service.dart';
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

  // ✅ AJOUTER SEULEMENT CES 4 NOUVELLES VARIABLES :
  final RxBool isLocalMode = true.obs;        // Mode local par défaut
  final RxString localDraftId = ''.obs;       // ID temporaire local
  Timer? _localSaveTimer;                     // Timer pour auto-save local
  static const String LOCAL_DRAFT_KEY = 'viaamigo_local_draft';

    // Nouvelle propriété pour tracker l'upload
  final RxBool _isUploadingPhotos = false.obs;
  bool get isUploadingPhotos => _isUploadingPhotos.value;

  // AMÉLIORATION: Observables pour la liste des photos
  RxList<String> photosList = <String>[].obs;
  RxString primaryPhoto = ''.obs;
  
  // AMÉLIORATION: Liste observable des erreurs de validation
  RxList<String> validationErrorsList = <String>[].obs;
  
  // Getters utiles
  bool get isReadyToPublish => currentParcel.value?.isReadyToPublish() ?? false;
  int get completionPercentage => currentParcel.value?.completion_percentage ?? 0;
  bool get isDraft => currentParcel.value?.draft ?? true;
    // Nouvelle propriété pour tracker si on vient de naviguer vers le wizard
  final _justNavigatedToWizard = false.obs;
  final _modalAlreadyShown = false.obs;

  // Méthode appelée quand on navigue vers le wizard
  void onNavigateToWizard() {
    print("ParcelsController: onNavigateToWizard called");
    _justNavigatedToWizard.value = true;
    _modalAlreadyShown.value = false;
  }
  
  // Initialiser un nouveau colis ou récupérer un brouillon existant
  /*Future<void> initParcel({String? existingParcelId}) async {
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
          paymentMethod: 'pay_later', // 'pay_now' ou 'pay_later'
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
  */
  Map<String, dynamic> toJsonForLocalStorage() {
  final data = currentParcel.value?.toMap() ?? {};
  
  // ✅ Convertir les Timestamp en chaînes
  data.forEach((key, value) {
    if (value is Timestamp) {
      data[key] = value.toDate().toIso8601String();
    }
  });
  
  return data;
}
    Future<void> initParcel({String? existingParcelId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      
      if (existingParcelId != null) {
        // ✅ LOGIQUE EXISTANTE inchangée : Charger un parcel Firestore
        print('🔄 Chargement parcel existant: $existingParcelId');
        isLocalMode.value = false;
        currentParcel.value = await _parcelsService.getParcelById(existingParcelId);
        autoSave.value = true;
        
        // Votre code existant pour synchroniser les observables...
        paymentStatus.value = currentParcel.value!.paymentStatus;
        paymentId.value = currentParcel.value!.paymentId ?? '';
        paidAt.value = currentParcel.value!.paidAt;
        photosList.value = List<String>.from(currentParcel.value!.photos);
        primaryPhoto.value = currentParcel.value!.primaryPhotoUrl ?? '';
        validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
      } else {
        // 🆕 NOUVEAU : Logique de brouillon local
        await _initializeLocalDraft(user);
      }
      
      currentStep.value = currentParcel.value!.navigation_step;
      validateFields();
      
    } catch (e) {
      errorMessage.value = 'Erreur: ${e.toString()}';
      print('❌ Erreur initParcel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ AJOUTER cette nouvelle méthode :
  Future<void> _initializeLocalDraft(User user) async {
    // 1. Chercher un brouillon local existant
    final existingDraft = await _loadLocalDraft();
    
    if (existingDraft != null && _isRecentDraft(existingDraft)) {
      print('📂 Reprise brouillon local');
      isLocalMode.value = true;
      currentParcel.value = existingDraft;
      currentStep.value = existingDraft.navigation_step;
      localDraftId.value = existingDraft.id ?? _generateLocalId();
      autoSave.value = false; // Pas d'auto-save Firestore
      _startLocalAutoSave();
    } else {
      print('🆕 Création nouveau brouillon local');
      await _createNewLocalDraft(user);
    }
  }

  // ✅ AJOUTER cette nouvelle méthode :
  Future<void> _createNewLocalDraft(User user) async {
    isLocalMode.value = true;
    localDraftId.value = _generateLocalId();
    autoSave.value = false;
    
    // ✅ UTILISER VOTRE LOGIQUE EXISTANTE exactement comme avant :
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
      size: '',
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
      insurance_fee: 0.0,
      platform_fee: 0.0,
      delivery_speed: 'standard',
      photos: [],
      geoIndexReady: false
    );
    
    currentParcel.value = emptyParcel;
    currentStep.value = 0;
    
    validateFields();
    _startLocalAutoSave();
    
    // Sauvegarder immédiatement en local
    await _saveLocalDraft();
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
    // ✅ MODIFIER votre méthode saveParcel existante - AJOUTER AU DÉBUT :
  Future<void> saveParcel() async {
    if (currentParcel.value == null) return;
    
    // ✅ AJOUTER CETTE CONDITION AU DÉBUT :
    if (isLocalMode.value) {
      await _saveLocalDraft();
      return;
    }
    
    // ✅ GARDER EXACTEMENT VOTRE LOGIQUE EXISTANTE :
    isSaving.value = true;
    
    try {
      currentParcel.value!.last_edited = DateTime.now();
      currentParcel.value!.navigation_step = currentStep.value;
      currentParcel.value!.completion_percentage = 
          currentParcel.value!.calculateCompletionPercentage();
      
      computeTotalHandlingFee();
      
      await _parcelsService.updateParcel(currentParcel.value!);
      validateFields();
    } catch (e) {
      errorMessage.value = 'Erreur lors de la sauvegarde: ${e.toString()}';
    } finally {
      isSaving.value = false;
    }
  }
  // Publier le colis (passer de brouillon à publié)
Future<bool> publishParcel() async {
  if (currentParcel.value == null) return false;
  
  // 🔒 PROTECTION : Si en mode local, faire transition ET s'arrêter
  if (isLocalMode.value) {
    print('🔄 Transition vers Firestore pour publication...');
    await _transitionToFirestore();
    
    // ✅ CRITIQUE : S'ARRÊTER ICI après transition réussie
    try {
      await _clearLocalDraft();
      await _forceCompleteReset();
      print('✅ Publication terminée via transition');
      return true;
    } catch (resetError) {
      print('⚠️ Erreur lors du reset: $resetError');
      return true; // Publication réussie malgré erreur reset
    }
  }
  
  // ✅ LOGIQUE EXISTANTE pour parcels déjà en Firestore
  if (!currentParcel.value!.validate()) {
    validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
    errorMessage.value = 'Erreurs de validation:\n${validationErrorsList.join('\n')}';
    return false;
  }
  
  isSaving.value = true;
  
  try {
    await _parcelsService.publishParcel(currentParcel.value!);
    
    currentParcel.value!.draft = false;
    currentParcel.value!.status = 'pending';
    
    try {
      await _clearLocalDraft();
      await _forceCompleteReset();
      print('✅ Reset exécuté après publication réussie');
    } catch (resetError) {
      print('⚠️ Erreur lors du reset (publication réussie): $resetError');
    }
    return true;
  } catch (e) {
    errorMessage.value = 'Erreur lors de la publication: ${e.toString()}';
    return false;
  } finally {
    isSaving.value = false;
  }
}
  /*Future<bool> publishParcel() async {
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
  }*/
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

        break;
      case 'declared_value':
        currentParcel.value = currentParcel.value!.copyWith(declared_value: value);
 
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
  case 'paymentMethod':
  currentParcel.value = currentParcel.value!.copyWith(paymentMethod: value);
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
   
        // ✅ MODIFIER SEULEMENT CETTE PARTIE À LA FIN :
    if (isLocalMode.value) {
      //
          await _saveLocalDraft(); // Sauvegarde locale uniquement
    // ✅ SUPPRIMÉ : Plus de _shouldTransitionToFirestore() ni _transitionToFiresto
    } else {
      // Mode Firestore : VOTRE LOGIQUE EXISTANTE
      if (autoSave.value) {
        await saveParcel();
      }
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
 // ✅ AJOUTER toutes ces nouvelles méthodes à la fin de votre classe :

  String _generateLocalId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid.substring(0, 8) ?? 'anon'}';
  }

  bool _isRecentDraft(ParcelModel draft) {
    return DateTime.now().difference(draft.last_edited).inHours < 48;
  }
/*
  bool _shouldTransitionToFirestore() {
    if (!isLocalMode.value || currentParcel.value == null) return false;
    
    return currentParcel.value!.title.isNotEmpty &&
           currentParcel.value!.weight > 0 &&
           currentParcel.value!.originAddress.isNotEmpty &&
           currentParcel.value!.destinationAddress.isNotEmpty&&
           currentParcel.value!.recipientName.isNotEmpty && // ← CONDITION SUPPLÉMENTAIRE
         currentParcel.value!.recipientPhone.isNotEmpty;  // ← CONDITION SUPPLÉMENTAIRE
  }*/

Future<void> _transitionToFirestore() async {
  if (!isLocalMode.value || currentParcel.value == null) return;
  
  try {
    print('🔄 Transition vers Firestore avec upload des photos...');
    
    // ✅ UPLOAD PHOTOS VERS FIREBASE AVANT CRÉATION FIRESTORE
    if (currentParcel.value!.photos.isNotEmpty) {
      _isUploadingPhotos.value = true;
      
      print('📸 Upload de ${currentParcel.value!.photos.length} photos vers Firebase Storage...');
      
      // Utiliser votre service qui appelle FirebaseStorageService
      final firebaseUrls = await FirebaseStorageService.uploadParcelPhotos(
        localPhotoPaths: currentParcel.value!.photos,
        parcelId: localDraftId.value,
      );

      
      // ✅ REMPLACER les chemins locaux par URLs Firebase
      currentParcel.value = currentParcel.value!.copyWith(photos: firebaseUrls);
      
      // Mettre à jour la photo principale
      if (currentParcel.value!.primaryPhotoUrl != null && 
          !currentParcel.value!.primaryPhotoUrl!.startsWith('https://')) {
        currentParcel.value = currentParcel.value!.copyWith(
          primaryPhotoUrl: firebaseUrls.isNotEmpty ? firebaseUrls.first : null
        );
      }
      
      // Synchroniser les observables
      photosList.value = firebaseUrls;
      primaryPhoto.value = currentParcel.value!.primaryPhotoUrl ?? '';
      
      _isUploadingPhotos.value = false;
      print('✅ Photos uploadées vers Firebase Storage');
    }
    
    // ✅ CRÉER PARCEL DANS FIRESTORE AVEC URLs Firebase
// ✅ CRÉER ET PUBLIER EN UNE FOIS
    print('🔄 Création du parcel dans Firestore...');
    final parcelId = await _parcelsService.createEmptyParcel(currentParcel.value!);
    currentParcel.value = currentParcel.value!.copyWith(
      id: parcelId,
      draft: false,        // ✅ MARQUER COMME PUBLIÉ
      status: 'pending'    // ✅ STATUT PUBLIÉ
    );

    // ✅ MISE À JOUR DIRECTE pour publication
    await _parcelsService.updateParcel(currentParcel.value!);

    // Finaliser la transition
    isLocalMode.value = false;
    autoSave.value = true;
    _stopLocalAutoSave();

    print('✅ Transition complète - Parcel créé ET publié en une fois');
  } catch (e) {
    _isUploadingPhotos.value = false;
    print('❌ Erreur transition: $e');
    rethrow;
  }
}
  void _startLocalAutoSave() {
    _localSaveTimer?.cancel();
    _localSaveTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isLocalMode.value && !isSaving.value) {
        _saveLocalDraft();
      }
    });
  }

  void _stopLocalAutoSave() {
    _localSaveTimer?.cancel();
  }

  Future<void> _saveLocalDraft() async {
    if (currentParcel.value == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = _parcelToLocalJson(currentParcel.value!);
      draftData['currentStep'] = currentStep.value;
      draftData['localDraftId'] = localDraftId.value;
      
      await prefs.setString(LOCAL_DRAFT_KEY, jsonEncode(draftData));
      print('💾 Brouillon sauvé localement');
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
    }
  }

  Future<ParcelModel?> _loadLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(LOCAL_DRAFT_KEY);
      
      if (draftJson != null) {
        final draftData = jsonDecode(draftJson);
        currentStep.value = draftData['currentStep'] ?? 0;
        localDraftId.value = draftData['localDraftId'] ?? _generateLocalId();
        
        return _parcelFromLocalJson(draftData);
      }
    } catch (e) {
      print('❌ Erreur chargement brouillon: $e');
    }
    
    return null;
  }
// ✅ AJOUTER cette méthode dans ParcelsController
Future<void> _forceCompleteReset() async {
  print('🧹 FORCE COMPLETE RESET - DÉBUT');
  print('🧹 FORCE RESET - Avant: currentParcel=${currentParcel.value?.id}');
  // 1. Arrêter tous les timers
  _stopLocalAutoSave();
  
  // 2. Reset BRUTAL de toutes les variables
  currentParcel.value = null;
  currentStep.value = 0;
  isLocalMode.value = true;
  localDraftId.value = '';
  _justNavigatedToWizard.value = false;
  _modalAlreadyShown.value = false;
  
  // 3. Reset tous les observables
  titleValid.value = false;
  weightValid.value = false;
  originValid.value = false;
  destinationValid.value = false;
  recipientValid.value = false;
  
  isInsured.value = false;
  insuranceLevel.value = 'none';
  declaredValue.value = 0.0;
  insuranceFee.value = 0.0;
  platformFee.value = 0.0;
  finalPrice.value = 0.0;
  
  paymentStatus.value = 'unpaid';
  paymentId.value = '';
  paidAt.value = null;
  
  photosList.clear();
  primaryPhoto.value = '';
  validationErrorsList.clear();
  errorMessage.value = '';
  
  isLoading.value = false;
  isSaving.value = false;
  autoSave.value = true;
  print('🧹 FORCE RESET - Après: currentParcel=${currentParcel.value}');
  // 4. Nettoyer le stockage local
  await _clearLocalDraft();
  
  // 5. Forcer la mise à jour de l'interface
  update();
  
  print('🧹 FORCE COMPLETE RESET - TERMINÉ');
}
  Future<void> _clearLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LOCAL_DRAFT_KEY);
      localDraftId.value = '';
      print('💾 Brouillon nettoyé localement');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
Map<String, dynamic> _parcelToLocalJson(ParcelModel parcel) {
  final json = parcel.toFirestore();
  
  // ✅ FONCTION RÉCURSIVE pour convertir TOUS les Timestamps
  Map<String, dynamic> convertTimestamps(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    
    for (var entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Timestamp) {
        // ✅ Timestamp → String ISO
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        // ✅ Récursion pour Maps imbriquées
        converted[key] = convertTimestamps(value);
      } else if (value is List) {
        // ✅ Traiter les listes
        converted[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return convertTimestamps(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        // ✅ Autres types : copier tel quel
        converted[key] = value;
      }
    }
    return converted;
  }
  
  // ✅ Appliquer la conversion
  final cleanedJson = convertTimestamps(json);
  
  // ✅ Gérer les coordonnées GPS
  if (parcel.origin != null) {
    cleanedJson['origin_lat'] = parcel.origin!.latitude;
    cleanedJson['origin_lng'] = parcel.origin!.longitude;
    cleanedJson.remove('origin');
  }
  if (parcel.destination != null) {
    cleanedJson['destination_lat'] = parcel.destination!.latitude;
    cleanedJson['destination_lng'] = parcel.destination!.longitude;
    cleanedJson.remove('destination');
  }
  
  return cleanedJson;
}
  /*Map<String, dynamic> _parcelToLocalJson(ParcelModel parcel) {
    final json = parcel.toFirestore();
    
    // Gérer les types complexes
    if (parcel.origin != null) {
      json['origin_lat'] = parcel.origin!.latitude;
      json['origin_lng'] = parcel.origin!.longitude;
      json.remove('origin');
    }
    if (parcel.destination != null) {
      json['destination_lat'] = parcel.destination!.latitude;
      json['destination_lng'] = parcel.destination!.longitude;
      json.remove('destination');
    }
     // ✅ AJOUTEZ CES LIGNES ICI :
  for (var windowKey in ['pickup_window', 'delivery_window']) {
    if (json[windowKey] is Map) {
      final window = json[windowKey] as Map<String, dynamic>;
      if (window['start_time'] is Timestamp) {
        window['start_time'] = (window['start_time'] as Timestamp).toDate().toIso8601String();
      }
      if (window['end_time'] is Timestamp) {
        window['end_time'] = (window['end_time'] as Timestamp).toDate().toIso8601String();
      }
    }
  }
    return json;
  }*/
  /// Vérifie s'il existe un brouillon local récent
Future<bool> hasLocalDraft() async {
  final draft = await _loadLocalDraft();
  return draft != null && _isRecentDraft(draft);
}

/// Efface le brouillon local et recommence
Future<void> clearLocalDraft() async {
  await _clearLocalDraft();
  isLocalMode.value = true;
  currentParcel.value = null;
  currentStep.value = 0;
  localDraftId.value = '';
  _stopLocalAutoSave();
}
  // ✅ NOUVELLE MÉTHODE : Reset complet quand l'utilisateur annule
  void onUserCancelledDraftChoice() {
    print("ParcelsController: onUserCancelledDraftChoice called");
    
    // Reset tous les flags
    _justNavigatedToWizard.value = false;
    _modalAlreadyShown.value = false;
    
    // Optionnel : Sauvegarder le brouillon actuel avant de partir
    if (isLocalMode.value && currentParcel.value != null && _hasSignificantContent(currentParcel.value!)) {
      _saveLocalDraft();
      print("💾 Draft saved before returning to role selection");
    }
    
    // Arrêter l'auto-save local
    _stopLocalAutoSave();
  }

/// Détermine s'il faut afficher le modal de choix de brouillon
 Future<bool> shouldShowDraftModal() async {
    print("ParcelsController: shouldShowDraftModal called");
    print("  - _justNavigatedToWizard: ${_justNavigatedToWizard.value}");
    print("  - _modalAlreadyShown: ${_modalAlreadyShown.value}");
    print("  - currentParcel.value != null: ${currentParcel.value != null}");
    
    // ✅ CRITIQUE : Vérifier si le parcel est publié
  if (currentParcel.value != null && !currentParcel.value!.draft) {
    print("  - Parcel is published, no modal needed");
    print("  - Parcel is published, auto-starting new parcel");
    startNewParcel();
    return false;
  }
    // Si le modal a déjà été montré cette session, ne pas le re-montrer
    if (_modalAlreadyShown.value) {
      print("  - Modal already shown, returning false");
      return false;
    }
    
    // Si on vient de naviguer et qu'il y a un brouillon en mémoire avec du contenu
    if (_justNavigatedToWizard.value && currentParcel.value != null) {
      bool hasContent = _hasSignificantContent(currentParcel.value!);
      print("  - Has significant content: $hasContent");
      return hasContent;
    }
    
    // Sinon, vérifier s'il y a un brouillon sauvegardé localement
    final localDraft = await _loadLocalDraft();
    if (localDraft != null && _isRecentDraft(localDraft)) {
      bool hasContent = _hasSignificantContent(localDraft);
      print("  - Local draft has significant content: $hasContent");
      return hasContent;
    }
    
    return false;
  }
  // Méthode appelée quand le modal est montré
  void onDraftModalShown() {
    print("ParcelsController: onDraftModalShown called");
    _modalAlreadyShown.value = true;
    _justNavigatedToWizard.value = false;
  }


  // Méthode pour continuer le brouillon existant
  Future<void> continueDraft() async {
    print("ParcelsController: continueDraft called");
    _modalAlreadyShown.value = true;
    _justNavigatedToWizard.value = false;
    
    // Si on n'a pas de brouillon en mémoire, le charger depuis le stockage local
    if (currentParcel.value == null) {
      final localDraft = await _loadLocalDraft();
      if (localDraft != null) {
        currentParcel.value = localDraft;
        currentStep.value = localDraft.navigation_step;
        isLocalMode.value = true;
        _startLocalAutoSave();
      } else {
        // Fallback : créer un nouveau brouillon
        await initParcel();
      }
    }
    // Sinon, le brouillon est déjà chargé, on continue simplement
  }
// Méthode pour commencer un nouveau colis
  Future<void> startNewParcel() async {
    print("ParcelsController: startNewParcel called");
    _modalAlreadyShown.value = true;
    _justNavigatedToWizard.value = false;
    
    // Sauvegarder l'ancien brouillon avant de le remplacer (optionnel)
    if (currentParcel.value != null && _hasSignificantContent(currentParcel.value!)) {
      await _saveLocalDraft();
    }
    
    // Effacer le brouillon actuel et créer un nouveau
    await clearLocalDraft();
    await initParcel();
  }

  // Méthode modifiée pour reset quand on quitte vraiment le wizard
  void onLeaveWizard() {
    print("ParcelsController: onLeaveWizard called");
    _justNavigatedToWizard.value = false;
    _modalAlreadyShown.value = false;
    // Sauvegarder le brouillon actuel si on est en mode local
    if (isLocalMode.value && currentParcel.value != null && _hasSignificantContent(currentParcel.value!)) {
      _saveLocalDraft();
    }
  }
/// Vérifie si le parcel a du contenu significatif qui mérite de proposer de continuer
bool _hasSignificantContent(ParcelModel parcel) {
  return parcel.title.isNotEmpty || 
         parcel.description!.isNotEmpty ||
         parcel.weight > 0 ||
         parcel.originAddress.isNotEmpty ||
         parcel.destinationAddress.isNotEmpty ||
         parcel.photos.isNotEmpty;
}

/// Force l'affichage du modal au prochain lancement (optionnel)
void markForDraftChoice() {
  // Cette méthode peut être appelée quand vous quittez le formulaire
  // pour forcer l'affichage du modal au prochain retour
  if (currentParcel.value != null && _hasSignificantContent(currentParcel.value!)) {
  }
}

// Ajoutez cette variable privée

/// Version publique de _clearLocalDraft pour l'accès externe
Future<void> clearLocalDraftPublic() async {
  await _clearLocalDraft();
}

  /*ParcelModel _parcelFromLocalJson(Map<String, dynamic> json) {
    // Reconstruire les GeoFirePoint
    if (json['origin_lat'] != null && json['origin_lng'] != null) {
      json['origin'] = GeoPoint(json['origin_lat'], json['origin_lng']);
    }
    if (json['destination_lat'] != null && json['destination_lng'] != null) {
      json['destination'] = GeoPoint(json['destination_lat'], json['destination_lng']);
    }
    
    // Utiliser un mock DocumentSnapshot
    final mockDoc = _MockDocumentSnapshot(json, json['id'] ?? '');
    return ParcelModel.fromFirestore(mockDoc as DocumentSnapshot<Object?>);
  }*/
ParcelModel _parcelFromLocalJson(Map<String, dynamic> json) {
  // ✅ FONCTION RÉCURSIVE pour reconvertir les Strings en Timestamps
  Map<String, dynamic> restoreTimestamps(Map<String, dynamic> data) {
    final restored = <String, dynamic>{};
    
    for (var entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String && _isTimestampField(key)) {
        try {
          // ✅ String ISO → Timestamp
          restored[key] = Timestamp.fromDate(DateTime.parse(value));
        } catch (e) {
          print("⚠️ Erreur conversion Timestamp pour $key: $e");
          restored[key] = value; // Garder la valeur originale en cas d'erreur
        }
      } else if (value is Map<String, dynamic>) {
        // ✅ Récursion pour Maps imbriquées
        restored[key] = restoreTimestamps(value);
      } else if (value is List) {
        // ✅ Traiter les listes
        restored[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return restoreTimestamps(item);
          }
          return item;
        }).toList();
      } else {
        // ✅ Autres types : copier tel quel
        restored[key] = value;
      }
    }
    return restored;
  }
  
  // ✅ Appliquer la restauration
  final restoredJson = restoreTimestamps(json);
  
  // ✅ Reconstruire les GeoFirePoint
  if (restoredJson['origin_lat'] != null && restoredJson['origin_lng'] != null) {
    restoredJson['origin'] = GeoPoint(restoredJson['origin_lat'], restoredJson['origin_lng']);
    restoredJson.remove('origin_lat');
    restoredJson.remove('origin_lng');
  }
  if (restoredJson['destination_lat'] != null && restoredJson['destination_lng'] != null) {
    restoredJson['destination'] = GeoPoint(restoredJson['destination_lat'], restoredJson['destination_lng']);
    restoredJson.remove('destination_lat');
    restoredJson.remove('destination_lng');
  }
  
  final mockDoc = _MockDocumentSnapshot(restoredJson, restoredJson['id'] ?? '');
  return ParcelModel.fromFirestore(mockDoc as DocumentSnapshot<Object?>);
}

// ✅ MÉTHODE UTILITAIRE : Identifier les champs Timestamp
bool _isTimestampField(String fieldName) {
  const timestampFields = [
    'createdAt', 'last_edited', 'paidAt', 'start_time', 'end_time',
    'pickup_start', 'pickup_end', 'delivery_start', 'delivery_end'
  ];
  
  return timestampFields.contains(fieldName) || 
         fieldName.contains('time') || 
         fieldName.contains('_at') ||
         fieldName.contains('Time');
}
  @override
  void onClose() {
    _stopLocalAutoSave();
    super.onClose();
  }
}

// ✅ AJOUTER cette classe helper à la fin du fichier :
class _MockDocumentSnapshot {
  final Map<String, dynamic> _data;
  final String id;
  
  _MockDocumentSnapshot(this._data, this.id);
  
  Map<String, dynamic> data() => _data;
}

