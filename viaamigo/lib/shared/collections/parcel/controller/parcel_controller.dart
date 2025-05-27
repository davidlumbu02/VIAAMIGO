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
  final RxBool weightValid = false.obs;
  final RxBool originValid = false.obs;
  final RxBool destinationValid = false.obs;
  final RxBool recipientValid = false.obs;
  
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
        throw Exception('Utilisateur non connecté');
      }
      
      if (existingParcelId != null) {
        // Charger un parcel existant
        currentParcel.value = await _parcelsService.getParcelById(existingParcelId);
        
        // AMÉLIORATION: Synchroniser les observables avec le modèle
        photosList.value = List<String>.from(currentParcel.value!.photos);
        primaryPhoto.value = currentParcel.value!.primaryPhotoUrl ?? '';
        validationErrorsList.value = List<String>.from(currentParcel.value!.validationErrors);
      } else {
        // Créer un nouveau parcel vide
        final now = DateTime.now();
        final emptyParcel = ParcelModel(
          senderId: user.uid,
          senderName: user.displayName ?? 'Utilisateur',
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
          draft: true,
          completion_percentage: 0,
          navigation_step: 0,
          status: 'draft',
          isInsured: false,
          insurance_level: 'none',
          flexible_days: false,
          advanced_pickup_allowed: false,
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
    descriptionValid.value = currentParcel.value!.description.isNotEmpty;
    weightValid.value = currentParcel.value!.weight > 0;
    originValid.value = currentParcel.value!.originAddress.isNotEmpty;
    destinationValid.value = currentParcel.value!.destinationAddress.isNotEmpty;
    recipientValid.value = 
        currentParcel.value!.recipientName.isNotEmpty && 
        currentParcel.value!.recipientPhone.isNotEmpty;
        
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
      case 'weight':
        double weightValue = double.parse(value.toString());
        currentParcel.value = currentParcel.value!.copyWith(weight: weightValue);
        weightValid.value = weightValue > 0;
        
        // Recalculer le prix estimé
        if (weightValid.value && currentParcel.value!.estimatedDistance != null) {
          double estimatedPrice = PriceCalculator.calculateEstimatedPrice(
            distanceKm: currentParcel.value!.estimatedDistance!,
            weightKg: weightValue,
            deliverySpeed: currentParcel.value!.delivery_speed,
            declaredValue: currentParcel.value!.declared_value,
            insuranceLevel: currentParcel.value!.insurance_level,
          );
          currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: estimatedPrice);
          
          // Si premier calcul, initialiser le prix proposé aussi
          if (currentParcel.value!.price == null) {
            currentParcel.value = currentParcel.value!.copyWith(price: estimatedPrice);
          }
        }
        break;
      case 'size':
        currentParcel.value = currentParcel.value!.copyWith(size: value);
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
          double estimatedPrice = PriceCalculator.calculateEstimatedPrice(
            distanceKm: currentParcel.value!.estimatedDistance!,
            weightKg: currentParcel.value!.weight,
            deliverySpeed: value,
            declaredValue: currentParcel.value!.declared_value,
            insuranceLevel: currentParcel.value!.insurance_level,
          );
          currentParcel.value = currentParcel.value!.copyWith(estimatedPrice: estimatedPrice);
        }
        break;
      case 'flexible_days':
        currentParcel.value = currentParcel.value!.copyWith(flexible_days: value);
        break;
      case 'advanced_pickup_allowed':
        currentParcel.value = currentParcel.value!.copyWith(advanced_pickup_allowed: value);
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
      case 'dimensions':
        currentParcel.value = currentParcel.value!.copyWith(dimensions: value);
        break;
    }
    
    // Sauvegarder automatiquement après modifications si activé
    if (autoSave.value) {
      await saveParcel();
    }
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
      double estimatedPrice = PriceCalculator.calculateEstimatedPrice(
        distanceKm: distance,
        weightKg: currentParcel.value!.weight,
        deliverySpeed: currentParcel.value!.delivery_speed,
        declaredValue: currentParcel.value!.declared_value,
        insuranceLevel: currentParcel.value!.insurance_level,
      );
      
      // Mettre à jour les prix
      currentParcel.value = currentParcel.value!.copyWith(
        estimatedPrice: estimatedPrice,
        price: currentParcel.value!.price ?? estimatedPrice // Initialiser prix si null
      );
      
      if (autoSave.value) {
        await saveParcel();
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du calcul de la distance: ${e.toString()}';
    }
  }
  
  // AMÉLIORATION: Ajouter une photo
  Future<void> addPhoto(String photoUrl) async {
    if (currentParcel.value == null) return;
    
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
}