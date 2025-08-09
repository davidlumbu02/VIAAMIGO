import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:viaamigo/shared/collections/parcel/model/parcel_dimension_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/collections/parcel/services/firebase_storage_service.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';
import 'package:viaamigo/shared/collections/parcel/services/photo_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ AJOUT CRITIQUE
//import 'package:viaamigo/shared/utilis/geo_utils.dart';


class ParcelsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ AJOUT CRITIQUE
  
  
  // Collection reference
  CollectionReference get _parcelsCollection => _firestore.collection('parcels');
  
  // Créer un colis vide (brouillon)
  Future<String> createEmptyParcel(ParcelModel parcel) async {
    try {
      
            final currentUser = _auth.currentUser;
      
      print('🔐 === DEBUG AUTHENTIFICATION ===');
      print('🔐 Current user: ${currentUser?.uid}');
      print('🔐 User email: ${currentUser?.email}');
      print('🔐 User displayName: ${currentUser?.displayName}');
      print('🔐 Auth token exists: ${currentUser != null}');
      
      if (currentUser == null) {
        throw Exception('❌ ERREUR CRITIQUE: Utilisateur non authentifié !');
      }
      if (currentUser == null) {
        throw Exception('❌ ERREUR CRITIQUE: Utilisateur non authentifié !');
      }
      
      // 🔐 VÉRIFICATION ET CORRECTION DU senderId
      print('🔐 Parcel senderId AVANT correction: ${parcel.senderId}');
      
      if (parcel.senderId == null || parcel.senderId.isEmpty) {
        print('🔄 Attribution automatique du senderId: ${currentUser.uid}');
        parcel.senderId = currentUser.uid;
      } else if (parcel.senderId != currentUser.uid) {
        print('⚠️  SenderId différent détecté !');
        print('   Current user: ${currentUser.uid}');
        print('   Parcel senderId: ${parcel.senderId}');
        print('🔄 Correction forcée du senderId');
        parcel.senderId = currentUser.uid;
      }
      
      print('🔐 Parcel senderId APRÈS correction: ${parcel.senderId}');
      print('🔐 SenderId match: ${parcel.senderId == currentUser.uid}');
      
      // 📋 PRÉPARATION DES DONNÉES POUR FIRESTORE
      final parcelData = parcel.toFirestore();
      
      print('📋 === DONNÉES ENVOYÉES À FIRESTORE ===');
      print('📋 Nombre de champs: ${parcelData.length}');
      
      // Debug des champs critiques
      parcelData.forEach((key, value) {
        if (key == 'senderId') {
          print('   ⭐ $key: $value (${value.runtimeType}) ← CRITIQUE');
        } else if (value is Timestamp) {
          print('   🕐 $key: $value (Timestamp)');
        } else if (value == null) {
          print('   ⚪ $key: null');
        } else {
          print('   📝 $key: ${value.toString().length > 50 ? "${value.toString().substring(0, 50)}..." : value} (${value.runtimeType})');
        }
      });
     // 🚀 TENTATIVE DE CRÉATION FIRESTORE
      print('🚀 Tentative de création dans Firestore...');
      final docRef = await _parcelsCollection.add(parcel.toFirestore());
      print('✅ ✅ ✅ SUCCÈS ! Parcel créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
            print('❌ ❌ ❌ ERREUR DÉTAILLÉE createEmptyParcel:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');
      
      // Analyse spécifique des erreurs Firestore
      if (e.toString().contains('permission-denied')) {
        print('🚨 ERREUR DE PERMISSIONS FIRESTORE !');
        print('   Vérifiez les règles Firestore');
        print('   User ID: ${_auth.currentUser?.uid}');
        print('   SenderId dans parcel: ${parcel.senderId}');
      }
      throw Exception('Erreur lors de la création du colis: $e');
    }
  }
  
  // Mettre à jour un colis
  Future<void> updateParcel(ParcelModel parcel) async {
    try {
      // Mise à jour du pourcentage de complétion
      parcel.completion_percentage = parcel.calculateCompletionPercentage();
      parcel.last_edited = DateTime.now();
      
      // Génération du geohash si les coordonnées sont disponibles
      if (parcel.origin != null && !parcel.geoIndexReady) {
        final geohash = GeoUtils.generateGeohash(
          parcel.origin!.latitude, 
          parcel.origin!.longitude
        );
        parcel.g = geohash;
        parcel.geoIndexReady = true;
      }
      
      await _parcelsCollection.doc(parcel.id).update(parcel.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du colis: $e');
    }
  }
  // ✅ NOUVELLE MÉTHODE : Upload photos avec URLs réelles
 Future<List<String>> uploadParcelPhotos(List<String> localPaths, String parcelId) async {
    try {
      return await FirebaseStorageService.uploadParcelPhotos(
      localPhotoPaths: localPaths,
      parcelId: parcelId,
    );
    } catch (e) {
      throw Exception('Erreur upload photos: $e');
    }
  } /*
  Future<List<String>> uploadParcelPhotos(List<String> localPaths, String parcelId) async {
  try {
    return await PhotoUploadService.uploadForTransition(
      localPaths, 
      parcelId,
      onProgress: (current, total) {
        print('📸 Upload photo $current/$total');
      },
    );
  } catch (e) {
    throw Exception('Erreur upload photos: $e');
  }
}*/
  
  // ✅ NOUVELLE MÉTHODE : Géocodage d'adresse
  Future<GeocodingResult?> geocodeAddress(String address) async {
    try {
      return await GeocodingService.getCoordinatesFromAddress(address);
    } catch (e) {
      throw Exception('Erreur géocodage: $e');
    }
  }
  
  // Publier un colis (passer de brouillon à publié)
  Future<void> publishParcel(ParcelModel parcel) async {
    try {
      // Valider le colis avant publication
      if (!parcel.validate()) {
        throw Exception('Le colis n\'est pas valide pour publication: ${parcel.validationErrors.join(", ")}');
      }
      
      parcel.draft = false;
      parcel.status = 'pending';
      parcel.last_edited = DateTime.now();
      
      // S'assurer que le geohash est généré pour le matching géospatial
      if (parcel.origin != null && !parcel.geoIndexReady) {
        final geohash = GeoUtils.generateGeohash(
          parcel.origin!.latitude, 
          parcel.origin!.longitude
        );
        parcel.g = geohash;
        parcel.geoIndexReady = true;
      }
      
      // Créer une date d'expiration (ex: +30 jours)
      parcel.expiresAt = DateTime.now().add(Duration(days: 30));
      
      // Mettre à jour le colis
      await _parcelsCollection.doc(parcel.id).update(parcel.toFirestore());
      
      // AMÉLIORATION: Ajouter un événement de création dans le tracking
      await addTrackingEvent(
        parcelId: parcel.id!, 
        status: 'created',
        location: GeoPoint(
          parcel.origin?.latitude ?? 0, 
          parcel.origin?.longitude ?? 0
        ),
        note: 'Colis créé et publié',
        confirmedBy: parcel.senderId,
        eventType: 'status_change',
        performedBy: 'sender',
        deviceInfo: {'platform': 'app'}, // À remplacer par de vraies infos
        sequence: 1 // Premier événement
      );
    } catch (e) {
      throw Exception('Erreur lors de la publication du colis: $e');
    }
  }
  
  // Supprimer un colis
  Future<void> deleteParcel(String parcelId) async {
    try {
      await _parcelsCollection.doc(parcelId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du colis: $e');
    }
  }
  
  // Récupérer un colis par son ID
  Future<ParcelModel> getParcelById(String parcelId) async {
    try {
      final docSnap = await _parcelsCollection.doc(parcelId).get();
      
      if (docSnap.exists) {
        return ParcelModel.fromFirestore(docSnap);
      } else {
        throw Exception('Colis non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du colis: $e');
    }
  }
  
  // Récupérer tous les colis d'un utilisateur (publiés et brouillons)
  Stream<List<ParcelModel>> getUserParcels(String userId, {bool draftsOnly = false}) {
    Query query = _parcelsCollection
        .where('senderId', isEqualTo: userId)
        .orderBy('last_edited', descending: true);
    
    if (draftsOnly) {
      query = query.where('draft', isEqualTo: true);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ParcelModel.fromFirestore(doc)).toList();
    });
  }
  
  // Récupérer les brouillons récents d'un utilisateur
  Future<List<ParcelModel>> getUserRecentDrafts(String userId, {int limit = 5}) async {
    try {
      final querySnapshot = await _parcelsCollection
          .where('senderId', isEqualTo: userId)
          .where('draft', isEqualTo: true)
          .orderBy('last_edited', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ParcelModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des brouillons: $e');
    }
  }
  
  // Récupérer les colis en attente d'un utilisateur (statut pending)
  Stream<List<ParcelModel>> getUserPendingParcels(String userId) {
    return _parcelsCollection
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .where('draft', isEqualTo: false)
        .orderBy('last_edited', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ParcelModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // AMÉLIORATION: Ajouter un événement au suivi de colis avec séquence
  Future<void> addTrackingEvent({
    required String parcelId,
    required String status,
    required GeoPoint location,
    String? note,
    String? photoUrl,
    required String confirmedBy,
    required String eventType,
    required String performedBy,
    required Map<String, dynamic> deviceInfo,
    required int sequence, // AMÉLIORATION: Séquence pour ordonner les événements
  }) async {
    try {
      // Créer l'événement de suivi
      TrackingEvent event = TrackingEvent(
        status: status,
        location: location,
        timestamp: DateTime.now(),
        note: note,
        photoUrl: photoUrl,
        confirmedBy: confirmedBy,
        event_type: eventType,
        performed_by: performedBy,
        device_info: deviceInfo,
        sequence: sequence,
      );
      
      // Ajouter à la sous-collection tracking
      await _firestore
          .collection('parcels')
          .doc(parcelId)
          .collection('tracking')
          .add(event.toFirestore());
      
      // Mettre à jour le statut du colis si nécessaire
      if (['created', 'picked_up', 'in_transit', 'delivered'].contains(status)) {
        await _parcelsCollection.doc(parcelId).update({
          'status': status == 'created' ? 'pending' :
                    status == 'picked_up' ? 'in_transit' :
                    status == 'in_transit' ? 'in_transit' :
                    status == 'delivered' ? 'delivered' : 'pending'
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout d\'un événement de suivi: $e');
    }
  }
  
  // AMÉLIORATION: Obtenir l'historique de suivi d'un colis avec séquence
  Stream<List<TrackingEvent>> getParcelTracking(String parcelId) {
    return _firestore
        .collection('parcels')
        .doc(parcelId)
        .collection('tracking')
        .orderBy('sequence', descending: false) // Utiliser la séquence pour l'ordre
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TrackingEvent.fromFirestore(doc)).toList();
        });
  }
  
  // AMÉLIORATION: Définir une photo principale pour le colis
  Future<void> setAsPrimaryPhoto(String parcelId, String photoUrl) async {
    try {
      await _parcelsCollection.doc(parcelId).update({
        'primaryPhotoUrl': photoUrl
      });
    } catch (e) {
      throw Exception('Erreur lors de la définition de la photo principale: $e');
    }
  }
}