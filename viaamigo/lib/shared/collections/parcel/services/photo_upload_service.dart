import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class PhotoUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload une photo et retourne l'URL publique
  static Future<String> uploadParcelPhoto(String localPath, String parcelId) async {
    try {
      final File file = File(localPath);
      if (!file.existsSync()) {
        throw Exception('Fichier non trouvé: $localPath');
      }
      
      // Générer un nom unique pour le fichier
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';
      final String storagePath = 'parcels/$parcelId/photos/$fileName';
      
      // Créer la référence Firebase Storage
      final Reference ref = _storage.ref().child(storagePath);
      
      // Métadonnées du fichier
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(localPath),
        customMetadata: {
          'parcelId': parcelId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload du fichier
      final UploadTask uploadTask = ref.putFile(file, metadata);
      
      // Attendre la fin de l'upload
      final TaskSnapshot snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      throw Exception('Erreur upload photo: $e');
    }
  }
    /// ✅ MÉTHODE MANQUANTE : uploadForTransition
  static Future<List<String>> uploadForTransition(
    List<String> localPaths, 
    String parcelId,
    {Function(int, int)? onProgress}
  ) async {
    if (localPaths.isEmpty) return [];
    
    List<String> firebaseUrls = [];
    
    for (int i = 0; i < localPaths.length; i++) {
      String localPath = localPaths[i];
      
      try {
        // Si c'est déjà une URL Firebase, l'ignorer
        if (localPath.startsWith('https://firebasestorage.googleapis.com')) {
          firebaseUrls.add(localPath);
          onProgress?.call(i + 1, localPaths.length);
          continue;
        }
        
        // Upload avec votre méthode existante
        final firebaseUrl = await uploadParcelPhoto(localPath, parcelId);
        firebaseUrls.add(firebaseUrl);
        onProgress?.call(i + 1, localPaths.length);
        
      } catch (e) {
        print('❌ Erreur upload $localPath: $e');
        // En cas d'échec, garder le chemin local
        firebaseUrls.add(localPath);
        onProgress?.call(i + 1, localPaths.length);
      }
    }
    
    return firebaseUrls;
  }
   /// ✅ NOUVELLE MÉTHODE : Upload avec gestion locale/Firebase et nettoyage
  static Future<List<String>> uploadParcelPhotosWithCleanup(
    String parcelId, 
    List<String> localPaths
  ) async {
    if (localPaths.isEmpty) return [];
    
    List<String> firebaseUrls = [];
    
    for (String localPath in localPaths) {
      try {
        // Vérifier si c'est déjà une URL Firebase
        if (localPath.startsWith('https://firebasestorage.googleapis.com')) {
          firebaseUrls.add(localPath);
          continue;
        }
        
        // Upload vers Firebase Storage
        final firebaseUrl = await uploadParcelPhoto(localPath, parcelId);
        firebaseUrls.add(firebaseUrl);
        
        // Supprimer le fichier local après upload réussi
        try {
          final File file = File(localPath);
          if (file.existsSync()) {
            await file.delete();
            print('🗑️ Fichier local supprimé: $localPath');
          }
        } catch (e) {
          print('⚠️ Impossible de supprimer le fichier local: $e');
        }
        
      } catch (e) {
        print('❌ Erreur upload photo $localPath: $e');
        // En cas d'échec, garder le chemin local
        firebaseUrls.add(localPath);
      }
    }
    
    return firebaseUrls;
  }
  /// Upload multiple photos en parallèle
  static Future<List<String>> uploadMultipleParcelPhotos(
    List<String> localPaths, 
    String parcelId,
    {Function(int, int)? onProgress}
  ) async {
    List<String> uploadedUrls = [];
    
    for (int i = 0; i < localPaths.length; i++) {
      try {
        final url = await uploadParcelPhoto(localPaths[i], parcelId);
        uploadedUrls.add(url);
        onProgress?.call(i + 1, localPaths.length);
      } catch (e) {
        print('Erreur upload photo ${localPaths[i]}: $e');
        // Continuer avec les autres photos
      }
    }
    
    return uploadedUrls;
  }
  
  /// Supprime une photo du storage
  static Future<void> deleteParcelPhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Erreur suppression photo: $e');
    }
  }
  
  /// Détermine le type MIME du fichier
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}