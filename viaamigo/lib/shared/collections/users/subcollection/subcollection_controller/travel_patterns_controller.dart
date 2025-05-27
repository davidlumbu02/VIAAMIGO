// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/travel_patterns.dart';

/// Contrôleur pour gérer les habitudes de déplacement d'un utilisateur
class TravelPatternController extends ChangeNotifier {
  final TravelPatternsService _patternService = TravelPatternsService();
  String _userId = '';
  List<TravelPattern> _patterns = [];
  bool _isLoading = false;
  StreamSubscription? _patternsSubscription;
  
  /// Getter pour les patterns
  List<TravelPattern> get patterns => _patterns;
  
  /// Getter pour l'état de chargement
  bool get isLoading => _isLoading;
  
  /// Initialise le contrôleur avec l'ID utilisateur
  void initialize(String userId) {
    if (_userId == userId && _patternsSubscription != null) return;
    
    _userId = userId;
    _subscribeToPatterns();
  }
  
  /// S'abonne aux modifications des patterns
  void _subscribeToPatterns() {
    _setLoading(true);
    
    // Annule l'abonnement précédent s'il existe
    _patternsSubscription?.cancel();
    
    // S'abonne au stream des patterns
    _patternsSubscription = _patternService
        .getUserTravelPatternsStream(_userId)
        .listen((patterns) {
          _patterns = patterns;
          _setLoading(false);
          notifyListeners();
        }, onError: (error) {
          print('Error in patterns subscription: $error');
          _setLoading(false);
          notifyListeners();
        });
  }
  
  /// Crée ou met à jour un pattern de déplacement
  Future<void> savePattern(TravelPattern pattern) async {
    try {
      _setLoading(true);
      
      if (pattern.id.isEmpty) {
        // Nouveau pattern
        await _patternService.addTravelPattern(_userId, pattern);
      } else {
        // Mise à jour d'un pattern existant
        await _patternService.updateTravelPattern(_userId, pattern);
      }
    } catch (e) {
      print('Error saving travel pattern: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Supprime un pattern de déplacement
  Future<void> deletePattern(String patternId) async {
    try {
      _setLoading(true);
      await _patternService.deleteTravelPattern(_userId, patternId);
    } catch (e) {
      print('Error deleting travel pattern: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Incrémente le nombre de trajets pour un pattern donné
  Future<void> incrementTripCount(String patternId) async {
    try {
      await _patternService.incrementTripCount(_userId, patternId);
    } catch (e) {
      print('Error incrementing trip count: $e');
      rethrow;
    }
  }
  
  /// Recherche un pattern similaire
  Future<TravelPattern?> findSimilarPattern(
    GeoPoint fromLocation,
    GeoPoint toLocation,
    {double proximityThresholdKm = 2.0}
  ) async {
    try {
      return await _patternService.findSimilarPattern(
        _userId,
        fromLocation,
        toLocation,
        proximityThresholdKm
      );
    } catch (e) {
      print('Error finding similar pattern: $e');
      return null;
    }
  }
  
  /// Crée un pattern à partir d'un nouveau trajet
  Future<String?> createPatternFromTrip(
    GeoPoint fromLocation,
    GeoPoint toLocation,
    String fromAddress,
    String toAddress,
    {String frequency = 'occasional'}
  ) async {
    try {
      // Vérifier s'il existe déjà un pattern similaire
      final existingPattern = await findSimilarPattern(fromLocation, toLocation);
      
      if (existingPattern != null) {
        // Mettre à jour le pattern existant
        await incrementTripCount(existingPattern.id);
        return existingPattern.id;
      } else {
        // Créer un nouveau pattern
        final newPattern = TravelPattern.withoutId(
          fromLocation: fromLocation,
          toLocation: toLocation,
          fromAddress: fromAddress,
          toAddress: toAddress,
          frequency: frequency,
          confidence: 0.3, // Confiance initiale
          lastTripDate: DateTime.now(),
          detectedAutomatically: true,
          tripsCount: 1,
        );
        
        return await _patternService.addTravelPattern(_userId, newPattern);
      }
    } catch (e) {
      print('Error creating pattern from trip: $e');
      return null;
    }
  }
  
  /// Vérifie si l'utilisateur a des patterns de déplacement
  Future<bool> hasPatterns() async {
    try {
      return await _patternService.hasTravelPatterns(_userId);
    } catch (e) {
      print('Error checking if user has patterns: $e');
      return false;
    }
  }
  
  /// Supprime tous les patterns d'un utilisateur
  Future<void> deleteAllPatterns() async {
    try {
      _setLoading(true);
      await _patternService.deleteAllTravelPatterns(_userId);
    } catch (e) {
      print('Error deleting all patterns: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Modifie l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Obtient un pattern par son ID
/// Obtient un pattern par son ID
TravelPattern? getPatternById(String patternId) {
  try {
    return _patterns.firstWhere(
      (pattern) => pattern.id == patternId,
    );
  } catch (e) {
    // Si aucun élément ne correspond, retourne null
    return null;
  }
}

  
  /// Filtre les patterns par fréquence
  List<TravelPattern> getPatternsByFrequency(String frequency) {
    return _patterns.where((pattern) => pattern.frequency == frequency).toList();
  }
  
  /// Calcule la confiance moyenne pour tous les patterns de l'utilisateur
  double getAverageConfidence() {
    if (_patterns.isEmpty) return 0.0;
    
    final sum = _patterns.fold(
      0.0, 
      (previousValue, pattern) => previousValue + pattern.confidence
    );
    
    return sum / _patterns.length;
  }
  
  /// Libère les ressources lors de la destruction du contrôleur
  @override
  void dispose() {
    _patternsSubscription?.cancel();
    super.dispose();
  }
  
  /// Rafraîchit manuellement la liste des patterns
  Future<void> refreshPatterns() async {
    try {
      _setLoading(true);
      _patterns = await _patternService.getUserTravelPatterns(_userId);
      notifyListeners();
    } catch (e) {
      print('Error refreshing patterns: $e');
    } finally {
      _setLoading(false);
    }
  }

/// Initialise un document vide pour les habitudes de déplacement d'un utilisateur
Future<void> createEmptyTravelPatternsDoc(String userId) async {
  try {
    _setLoading(true);
    _userId = userId;
    
    // Vérifier si l'utilisateur a déjà des patterns
    bool hasExistingPatterns = await hasPatterns();
    
    if (!hasExistingPatterns) {
      // Créer le document placeholder via le service
      await _patternService.createEmptyTravelPatternDoc(_userId);
      
      print('✅ Document travel pattern initialisé pour l\'utilisateur: $_userId');
    }
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation du document travel pattern: $e');
    rethrow;
  } finally {
    _setLoading(false);
  }
}

  
}
/**import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/controllers/travel_pattern_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/travel_patterns.dart';

void exampleTravelPatternsCrudUsage() async {
  // ⚙️ Étape 1 : Initialisation du controller
  Get.put(TravelPatternController());
  final controller = Get.find<TravelPatternController>();

  // 🔑 Récupération de l'utilisateur connecté
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // 📄 Étape 2 : Initialiser si nécessaire
  await controller.createEmptyTravelPatternsDoc(userId);

  // 🔃 Étape 3 : Initialiser/écouter les patterns
  controller.initialize(userId);

  // ➕ Étape 4 : Créer un pattern manuel (ex: depuis un formulaire)
  final newPattern = TravelPattern.withoutId(
    fromLocation: const GeoPoint(45.4215, -75.6972),
    toLocation: const GeoPoint(45.5017, -73.5673),
    fromAddress: 'Ottawa, ON',
    toAddress: 'Montréal, QC',
    frequency: 'weekly',
    confidence: 0.2,
    tripsCount: 1,
    lastTripDate: DateTime.now(),
    detectedAutomatically: false,
  );
  await controller.savePattern(newPattern);

  // 🔁 Étape 5 : Charger manuellement tous les patterns
  await controller.refreshPatterns();
  print('Nombre de patterns : ${controller.patterns.length}');

  // ✏️ Étape 6 : Modifier un pattern existant
  final patternToUpdate = controller.patterns.firstOrNull;
  if (patternToUpdate != null) {
    final updated = patternToUpdate.copyWith(confidence: 0.8, frequency: 'daily');
    await controller.savePattern(updated);
  }

  // 🔍 Étape 7 : Vérifier l'existence
  final exists = await controller.hasPatterns();
  print(exists ? 'Patterns présents' : 'Aucun pattern trouvé');

  // 🗑️ Étape 8 : Supprimer un pattern
  if (patternToUpdate != null) {
    await controller.deletePattern(patternToUpdate.id);
  }

  // 🧼 Étape 9 : Supprimer tous les patterns (reset compte)
  await controller.deleteAllPatterns();

  // 🧪 Étape 10 : Détecter un pattern automatiquement depuis trajet
  final patternId = await controller.createPatternFromTrip(
    const GeoPoint(45.0, -75.0),
    const GeoPoint(45.5, -73.5),
    'Départ Auto',
    'Arrivée Auto',
  );
  print('Pattern détecté : $patternId');

  // 🎯 Étape 11 : Incrémenter manuellement le compteur d’un pattern
  if (patternId != null) {
    await controller.incrementTripCount(patternId);
  }

  // 🔄 Étape 12 : Écoute temps réel (utile pour une UI dynamique)
  final sub = controller.patterns;
  print('🔥 Nombre de patterns actuellement en mémoire : ${sub.length}');

  // 🎯 Étape 13 : Récupérer par ID
  final found = controller.getPatternById(patternId ?? '');
  if (found != null) {
    print('Pattern trouvé : ${found.fromAddress} → ${found.toAddress}');
  }

  // 📊 Étape 14 : Calculer confiance moyenne
  final average = controller.getAverageConfidence();
  print('🔬 Moyenne confiance : $average');
}
 */