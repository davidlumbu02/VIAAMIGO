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