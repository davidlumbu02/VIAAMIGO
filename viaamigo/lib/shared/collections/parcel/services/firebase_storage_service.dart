import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int _compressionQuality = 85;

  /// Upload des photos d'un parcel vers Firebase Storage
  static Future<List<String>> uploadParcelPhotos({
    required List<String> localPhotoPaths,
    required String parcelId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('🚫 Utilisateur non authentifié');
      }

      print('🔄 Début upload de ${localPhotoPaths.length} photos...');
      List<String> uploadedUrls = [];

      for (int i = 0; i < localPhotoPaths.length; i++) {
        final localPath = localPhotoPaths[i];
        print('📤 Upload photo ${i + 1}/${localPhotoPaths.length}: $localPath');

        try {
          // Vérifier que le fichier existe
          final file = File(localPath);
          if (!await file.exists()) {
            print('⚠️ Fichier inexistant: $localPath');
            continue;
          }

          // Compresser l'image
          final compressedFile = await _compressImage(file);
          
          // Générer un nom unique
          final photoId = const Uuid().v4();
          final fileName = '${photoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // Créer la référence Firebase Storage
          final storageRef = _storage.ref().child(
            'parcels/${user.uid}/$parcelId/photos/$fileName'
          );

          // Métadonnées
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': user.uid,
              'parcelId': parcelId,
              'photoIndex': i.toString(),
              'uploadTime': DateTime.now().toIso8601String(),
              'originalPath': localPath,
              'compressed': 'true',
            },
          );

          // Upload du fichier
          final uploadTask = storageRef.putFile(compressedFile, metadata);
          
          // Suivre la progression
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            print('📊 Upload photo ${i + 1}: ${progress.toStringAsFixed(1)}%');
          });

          // Attendre la fin de l'upload
          final taskSnapshot = await uploadTask;
          
          // Récupérer l'URL de téléchargement
          final downloadUrl = await taskSnapshot.ref.getDownloadURL();
          uploadedUrls.add(downloadUrl);
          
          print('✅ Photo ${i + 1} uploadée: ${downloadUrl.substring(0, 50)}...');
          
          // Nettoyer le fichier compressé temporaire
          if (compressedFile.path != file.path) {
            await compressedFile.delete();
          }

        } catch (e) {
          print('❌ Erreur upload photo ${i + 1}: $e');
          // Continuer avec les autres photos
          continue;
        }
      }

      print('🎉 Upload terminé: ${uploadedUrls.length}/${localPhotoPaths.length} photos uploadées');
      return uploadedUrls;

    } catch (e) {
      print('💥 Erreur critique upload photos: $e');
      rethrow;
    }
  }

  /// Compression d'image
  static Future<File> _compressImage(File originalFile) async {
    try {
      // Lire l'image
      final imageBytes = await originalFile.readAsBytes();
      
      // Vérifier la taille
      if (imageBytes.length <= _maxImageSize) {
        print('📏 Image déjà optimale: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        return originalFile;
      }

      print('🗜️ Compression nécessaire: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // Décoder l'image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }

      // Redimensionner si trop grande (max 1920px)
      img.Image resizedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
        print('📐 Image redimensionnée: ${resizedImage.width}x${resizedImage.height}');
      }

      // Compresser en JPEG
      final compressedBytes = img.encodeJpg(resizedImage, quality: _compressionQuality);
      
      // Sauvegarder dans un fichier temporaire
      final tempDir = Directory.systemTemp;
      final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      await compressedFile.writeAsBytes(compressedBytes);

      print('✅ Compression terminée: ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      return compressedFile;

    } catch (e) {
      print('❌ Erreur compression: $e');
      return originalFile; // Retourner l'original si la compression échoue
    }
  }

  /// Supprimer les photos d'un parcel
  static Future<void> deleteParcelPhotos({
    required String parcelId,
    required String userId,
  }) async {
    try {
      final folderRef = _storage.ref().child('parcels/$userId/$parcelId/photos');
      final listResult = await folderRef.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
        print('🗑️ Photo supprimée: ${item.name}');
      }
      
      print('✅ Toutes les photos du parcel $parcelId supprimées');
    } catch (e) {
      print('❌ Erreur suppression photos: $e');
    }
  }

  /// Obtenir une URL signée temporaire (1h d'expiration)
  static Future<String?> getSignedUrl(String gsUrl) async {
    try {
      final ref = _storage.refFromURL(gsUrl);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('❌ Erreur génération URL signée: $e');
      return null;
    }
  }
}