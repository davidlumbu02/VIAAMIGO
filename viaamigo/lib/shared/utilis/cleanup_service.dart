import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// ✅ MÉTHODE QUI FONCTIONNE SANS INDEX
  static Future<void> cleanupAbandonedDraftsNoIndex() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(hours: 24));
      int totalDeleted = 0;
      
      // ✅ ÉTAPE 1: Récupérer TOUS les brouillons de l'utilisateur (sans contrainte de date)
      final allDrafts = await _firestore
          .collection('parcels')
          .where('senderId', isEqualTo: user.uid)
          .where('draft', isEqualTo: true)
          // ❌ PAS de .where('last_edited', isLessThan: ...)
          .limit(500) // Limiter pour éviter les gros téléchargements
          .get();
      
      print('📥 Récupéré ${allDrafts.docs.length} brouillons au total');
      
      // ✅ ÉTAPE 2: Filtrage LOCAL (côté client)
      final abandonedDocs = allDrafts.docs.where((doc) {
        final data = doc.data();
        
        // Vérifier la date de dernière modification
        final lastEditedTimestamp = data['last_edited'] as Timestamp?;
        if (lastEditedTimestamp == null) return false;
        
        final lastEdited = lastEditedTimestamp.toDate();
        final isOld = lastEdited.isBefore(cutoffDate);
        
        // Vérifier le pourcentage de complétion
        final completionPercentage = data['completion_percentage'] as int? ?? 0;
        final isIncomplete = completionPercentage < 10;
        
        return isOld && isIncomplete;
      }).toList();
      
      print('🧹 Trouvé ${abandonedDocs.length} brouillons abandonnés à supprimer');
      
      // ✅ ÉTAPE 3: Suppression par lots
      if (abandonedDocs.isNotEmpty) {
        // Traiter par lots de 500 (limite Firestore batch)
        for (int i = 0; i < abandonedDocs.length; i += 500) {
          final batch = _firestore.batch();
          final endIndex = (i + 500).clamp(0, abandonedDocs.length);
          
          for (int j = i; j < endIndex; j++) {
            batch.delete(abandonedDocs[j].reference);
          }
          
          await batch.commit();
          totalDeleted += (endIndex - i);
          print('🗑️ Supprimé ${endIndex - i} brouillons (lot ${(i / 500).floor() + 1})');
        }
      }
      
      print('✅ Nettoyage terminé: $totalDeleted brouillons supprimés au total');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
  /// ATTENTION: Supprime TOUS les documents de la collection parcels
static Future<int> deleteAllParcels() async {
  try {
    final querySnapshot = await _firestore.collection('parcels').get();
    final batch = _firestore.batch();
    int count = 0;
    
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      count++;
    }
    
    await batch.commit();
    print('⚠️ ATTENTION: $count documents supprimés de la collection parcels');
    return count;
  } catch (e) {
    print('❌ Erreur lors de la suppression complète: $e');
    return -1;
  }
}

  /// ✅ NETTOYAGE ULTRA-SIMPLE : Brouillons vides uniquement
  static Future<void> cleanupEmptyDraftsSimple() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // ✅ REQUÊTE MINIMALE sans problème d'index
      final empty = await _firestore
          .collection('parcels')
          .where('senderId', isEqualTo: user.uid)
          .where('draft', isEqualTo: true)
          // ❌ Pas d'autres where() ou orderBy()
          .limit(100)
          .get();
      
      // Filtrage local pour les brouillons vraiment vides
      final reallyEmpty = empty.docs.where((doc) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final weight = data['weight'] as double? ?? 0.0;
        final originAddress = data['originAddress'] as String? ?? '';
        final destinationAddress = data['destinationAddress'] as String? ?? '';
        
        return title.isEmpty && 
               weight <= 0 && 
               originAddress.isEmpty && 
               destinationAddress.isEmpty;
      }).toList();
      
      print('🧹 Trouvé ${reallyEmpty.length} brouillons vraiment vides');
      
      if (reallyEmpty.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in reallyEmpty) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Supprimé ${reallyEmpty.length} brouillons vides');
      }
      
    } catch (e) {
      print('❌ Erreur nettoyage vides: $e');
    }
  }
  
  /// ✅ NETTOYAGE PAR PAGINATION (pour de gros volumes)
  static Future<void> cleanupWithPagination() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: 7));
      DocumentSnapshot? lastDoc;
      int totalProcessed = 0;
      int totalDeleted = 0;
      
      while (true) {
        // ✅ PAGINATION SIMPLE sans index complexe
        Query query = _firestore
            .collection('parcels')
            .where('senderId', isEqualTo: user.uid)
            .where('draft', isEqualTo: true)
            .limit(50);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final batch = await query.get();
        
        if (batch.docs.isEmpty) break;
        
        // Filtrage local
        final toDelete = batch.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Vérifier la date
          final lastEditedTimestamp = data['last_edited'] as Timestamp?;
          if (lastEditedTimestamp == null) return false;
          
          final lastEdited = lastEditedTimestamp.toDate();
          return lastEdited.isBefore(cutoffDate);
        }).toList();
        
        // Suppression
        if (toDelete.isNotEmpty) {
          final deleteBatch = _firestore.batch();
          for (final doc in toDelete) {
            deleteBatch.delete(doc.reference);
          }
          await deleteBatch.commit();
          totalDeleted += toDelete.length;
        }
        
        totalProcessed += batch.docs.length;
        lastDoc = batch.docs.last;
        
        print('📊 Traité: $totalProcessed, Supprimé: $totalDeleted');
        
        // Si moins de 50 docs, on a fini
        if (batch.docs.length < 50) break;
      }
      
      print('✅ Nettoyage terminé: $totalDeleted/$totalProcessed supprimés');
    } catch (e) {
      print('❌ Erreur nettoyage pagination: $e');
    }
  }
  
  /// ✅ NETTOYAGE MANUEL : Lister puis supprimer
  static Future<List<Map<String, dynamic>>> listAbandonedDrafts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      
      final cutoffDate = DateTime.now().subtract(Duration(hours: 24));
      
      // Récupérer tous les brouillons
      final allDrafts = await _firestore
          .collection('parcels')
          .where('senderId', isEqualTo: user.uid)
          .where('draft', isEqualTo: true)
          .get();
      
      // Filtrage local et création de la liste
      final abandoned = allDrafts.docs.where((doc) {
        final data = doc.data();
        
        final lastEditedTimestamp = data['last_edited'] as Timestamp?;
        if (lastEditedTimestamp == null) return false;
        
        final lastEdited = lastEditedTimestamp.toDate();
        final isOld = lastEdited.isBefore(cutoffDate);
        
        final completionPercentage = data['completion_percentage'] as int? ?? 0;
        final isIncomplete = completionPercentage < 10;
        
        return isOld && isIncomplete;
      }).map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'last_edited': (data['last_edited'] as Timestamp?)?.toDate(),
          'completion_percentage': data['completion_percentage'] ?? 0,
        };
      }).toList();
      
      print('📋 Trouvé ${abandoned.length} brouillons abandonnés');
      return abandoned;
      
    } catch (e) {
      print('❌ Erreur listage: $e');
      return [];
    }
  }
  
  /// ✅ SUPPRESSION MANUELLE par ID
  static Future<void> deleteParcelById(String parcelId) async {
    try {
      await _firestore.collection('parcels').doc(parcelId).delete();
      print('✅ Supprimé parcel: $parcelId');
    } catch (e) {
      print('❌ Erreur suppression $parcelId: $e');
    }
  }
  
  /// ✅ SUPPRESSION MANUELLE en lot
  static Future<void> deleteParcelsByIds(List<String> parcelIds) async {
    try {
      // Traiter par lots de 500 (limite Firestore)
      for (int i = 0; i < parcelIds.length; i += 500) {
        final batch = _firestore.batch();
        final endIndex = (i + 500).clamp(0, parcelIds.length);
        
        for (int j = i; j < endIndex; j++) {
          final docRef = _firestore.collection('parcels').doc(parcelIds[j]);
          batch.delete(docRef);
        }
        
        await batch.commit();
        print('✅ Supprimé lot ${(i / 500).floor() + 1}: ${endIndex - i} parcels');
      }
    } catch (e) {
      print('❌ Erreur suppression lot: $e');
    }
  }
}
