// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/vehicules.dart';

/// Contrôleur pour gérer les données des véhicules avec GetX
/// Gère les opérations CRUD et maintient un état réactif pour les opérations liées aux véhicules
class VehicleController extends GetxController {
  /// Service de véhicules pour les opérations Firestore
  /// Injecté via le système d'injection de dépendances de GetX
  final VehiclesService _vehiclesService = Get.find<VehiclesService>();
  
  /// Liste observable des véhicules de l'utilisateur
  /// Se met à jour automatiquement lorsque les données changent
  final RxList<Vehicle> userVehicles = <Vehicle>[].obs;
  
  /// Véhicule actuellement sélectionné pour affichage ou édition
  /// Utilisé lors de l'affichage des détails d'un véhicule ou des formulaires d'édition
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  
  /// Véhicule par défaut de l'utilisateur
  /// C'est le véhicule marqué comme par défaut pour les trajets
  final Rx<Vehicle?> defaultVehicle = Rx<Vehicle?>(null);
  
  /// Indicateur d'état de chargement
  /// Vrai lorsque des opérations sont en cours
  final RxBool isLoading = false.obs;
  
  /// Message d'erreur pour les opérations échouées
  /// Une chaîne vide indique qu'il n'y a pas d'erreur
  final RxString error = ''.obs;

  /// Charge tous les véhicules appartenant à un utilisateur spécifique
  /// 
  /// @param userId L'ID de l'utilisateur dont les véhicules doivent être chargés
  /// 
  /// Met à jour [userVehicles] avec les données récupérées et charge également le véhicule par défaut
  Future<void> loadUserVehicles(String userId) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // Récupère tous les véhicules de l'utilisateur depuis Firestore
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      
      // Charge également le véhicule par défaut
      await loadDefaultVehicle(userId);
    } catch (e) {
      error.value = e.toString();
      print('Erreur lors du chargement des véhicules: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Charge le véhicule par défaut de l'utilisateur
  /// 
  /// @param userId L'ID de l'utilisateur dont le véhicule par défaut doit être chargé
  /// 
  /// Met à jour [defaultVehicle] avec les données récupérées
  Future<void> loadDefaultVehicle(String userId) async {
    try {
      defaultVehicle.value = await _vehiclesService.getDefaultVehicle(userId);
    } catch (e) {
      print('Erreur lors du chargement du véhicule par défaut: $e');
    }
  }
  
  /// Ajoute un nouveau véhicule pour un utilisateur
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicle L'objet véhicule à ajouter
  /// 
  /// Après l'ajout, recharge tous les véhicules et le véhicule par défaut
  Future<void> addVehicle(String userId, Vehicle vehicle) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // Ajoute le véhicule dans Firestore
      await _vehiclesService.addVehicle(userId, vehicle);
      
      // Actualise la liste des véhicules
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      
      // Recharge le véhicule par défaut (au cas où le nouveau serait défini par défaut)
      await loadDefaultVehicle(userId);
      
      // Ferme le formulaire et affiche un message de succès
      Get.back();
      Get.snackbar('Success', 'Vehicle added successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to add vehicle: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Met à jour un véhicule existant
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicle L'objet véhicule mis à jour
  /// 
  /// Après la mise à jour, recharge tous les véhicules et le véhicule par défaut
  Future<void> updateVehicle(String userId, Vehicle vehicle) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // Met à jour le véhicule dans Firestore
      await _vehiclesService.updateVehicle(userId, vehicle);
      
      // Actualise la liste des véhicules
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      
      // Recharge le véhicule par défaut (au cas où celui-ci serait défini par défaut)
      await loadDefaultVehicle(userId);
      
      // Ferme le formulaire d'édition et affiche un message de succès
      Get.back();
      Get.snackbar('Success', 'Vehicle updated successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to update vehicle: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Supprime un véhicule
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicleId L'ID du véhicule à supprimer
  /// 
  /// Après la suppression, recharge tous les véhicules et le véhicule par défaut
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // Supprime le véhicule de Firestore
      await _vehiclesService.deleteVehicle(userId, vehicleId);
      
      // Actualise la liste des véhicules
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      
      // Recharge le véhicule par défaut (au cas où nous aurions supprimé le véhicule par défaut)
      await loadDefaultVehicle(userId);
      
      // Affiche un message de succès
      Get.snackbar('Success', 'Vehicle deleted successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to delete vehicle: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Définit un véhicule comme véhicule par défaut
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicleId L'ID du véhicule à définir comme par défaut
  /// 
  /// Après la définition, recharge tous les véhicules et le véhicule par défaut
  Future<void> setAsDefault(String userId, String vehicleId) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // Définit le véhicule comme par défaut dans Firestore
      await _vehiclesService.setAsDefaultVehicle(userId, vehicleId);
      
      // Actualise la liste des véhicules
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      
      // Recharge le véhicule par défaut
      await loadDefaultVehicle(userId);
      
      // Affiche un message de succès
      Get.snackbar('Success', 'Vehicle set as default');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to set vehicle as default: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Sélectionne un véhicule pour affichage ou modification
  /// 
  /// @param vehicle Le véhicule à sélectionner
  /// 
  /// Met à jour [selectedVehicle] avec le véhicule spécifié
  void selectVehicle(Vehicle vehicle) {
    selectedVehicle.value = vehicle;
  }
  
  /// Efface le véhicule actuellement sélectionné
  /// Utilisé lors de la fermeture des vues de détails du véhicule
  void clearSelection() {
    selectedVehicle.value = null;
  }
  
  /// Écoute les mises à jour en temps réel des véhicules
  /// 
  /// @param userId L'ID de l'utilisateur dont les véhicules doivent être écoutés
  /// 
  /// Retourne un flux de listes de véhicules qui se met à jour automatiquement
  Stream<List<Vehicle>> getVehiclesStream(String userId) {
    return _vehiclesService.getUserVehiclesStream(userId);
  }
  
  /// Vérifie si un utilisateur a des véhicules
  /// 
  /// @param userId L'ID de l'utilisateur à vérifier
  /// @returns Vrai si l'utilisateur a au moins un véhicule
  Future<bool> hasVehicles(String userId) async {
    final vehicles = await _vehiclesService.getUserVehicles(userId);
    return vehicles.isNotEmpty;
  }
  
  /// Récupère un véhicule spécifique par son ID
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicleId L'ID du véhicule à récupérer
  /// @returns Le véhicule s'il est trouvé, null sinon
  Future<Vehicle?> getVehicle(String userId, String vehicleId) async {
    try {
      return await _vehiclesService.getUserVehicle(userId, vehicleId);
    } catch (e) {
      print('Erreur lors de la récupération du véhicule: $e');
      error.value = e.toString();
      return null;
    }
  }
  
  /// Initialise un véhicule vide pour les nouveaux utilisateurs
  /// 
  /// @param userId L'ID de l'utilisateur à initialiser
  Future<void> initializeEmptyVehicle(String userId) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      await _vehiclesService.createEmptyVehicleDoc(userId);
      Get.snackbar('Success', 'Vehicle initialized successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to initialize vehicle: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Supprime tous les véhicules d'un utilisateur
  /// Utile pour réinitialiser les données ou pour les tests
  /// 
  /// @param userId L'ID de l'utilisateur dont les véhicules doivent être supprimés
  Future<void> deleteAllVehicles(String userId) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      await _vehiclesService.deleteAllVehicles(userId);
      userVehicles.clear();
      defaultVehicle.value = null;
      Get.snackbar('Success', 'All vehicles deleted successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to delete all vehicles: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Met à jour uniquement certaines propriétés d'un véhicule
  /// Permet de ne modifier que les champs nécessaires sans toucher aux autres
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicleId L'ID du véhicule à mettre à jour
  /// @param updates Map contenant les champs à mettre à jour
  Future<void> updateVehicleProperties(String userId, String vehicleId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // D'abord récupérer le véhicule actuel
      final existingVehicle = await _vehiclesService.getUserVehicle(userId, vehicleId);
      if (existingVehicle == null) {
        throw Exception('Vehicle not found');
      }
      
      // Créer un nouveau véhicule avec les propriétés mises à jour
      final updatedVehicle = Vehicle(
        id: vehicleId,
        type: updates['type'] ?? existingVehicle.type,
        make: updates['make'] ?? existingVehicle.make,
        model: updates['model'] ?? existingVehicle.model,
        year: updates['year'] ?? existingVehicle.year,
        licensePlate: updates['licensePlate'] ?? existingVehicle.licensePlate,
        color: updates['color'] ?? existingVehicle.color,
        cargoVolume: updates['cargoVolume'] ?? existingVehicle.cargoVolume,
        maxWeight: updates['maxWeight'] ?? existingVehicle.maxWeight,
        photoUrls: updates['photoUrls'] ?? existingVehicle.photoUrls,
        verified: updates['verified'] ?? existingVehicle.verified,
        verifiedAt: updates['verifiedAt'] ?? existingVehicle.verifiedAt,
        isDefault: updates['isDefault'] ?? existingVehicle.isDefault,
        dimensions: updates['dimensions'] ?? existingVehicle.dimensions,
        insurance: updates['insurance'] ?? existingVehicle.insurance,
        trackingEnabled: updates['trackingEnabled'] ?? existingVehicle.trackingEnabled,
      );
      
      // Mettre à jour le véhicule
      await _vehiclesService.updateVehicle(userId, updatedVehicle);
      
      // Rafraîchir les données
      userVehicles.value = await _vehiclesService.getUserVehicles(userId);
      await loadDefaultVehicle(userId);
      
      Get.snackbar('Success', 'Vehicle properties updated successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Unable to update vehicle properties: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Vérifie si un véhicule existe
  /// 
  /// @param userId L'ID de l'utilisateur propriétaire du véhicule
  /// @param vehicleId L'ID du véhicule à vérifier
  /// @returns Vrai si le véhicule existe, faux sinon
  Future<bool> vehicleExists(String userId, String vehicleId) async {
    try {
      return await _vehiclesService.vehicleExists(userId, vehicleId);
    } catch (e) {
      print('Erreur lors de la vérification de l\'existence du véhicule: $e');
      return false;
    }
  }
}

/*import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/collections/users/subcollection/vehicules.dart';

void exampleVehicleControllerUsage() async {
  // ⚙️ Initialisation du controller (à faire une fois au démarrage de l'app ou dans les Bindings)
  Get.put<VehicleController>(VehicleController());

  // 📌 Récupère le controller (dans un autre controller ou service, par exemple)
  final vehicleController = Get.find<VehicleController>();

  // 🔑 Récupération de l'ID de l'utilisateur courant via Firebase
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Charger tous les véhicules de l’utilisateur
  await vehicleController.loadUserVehicles(userId);

  // ➕ Ajouter un véhicule
  final newVehicle = Vehicle(
    id: '', // Firestore générera l'ID
    type: 'SUV',
    make: 'Toyota',
    model: 'RAV4',
    year: 2020,
    licensePlate: 'XYZ123',
    color: 'Blue',
    photoUrls: ['https://example.com/vehicle.jpg'],
    cargoVolume: 500.0,
    maxWeight: 300.0,
    verified: false,
    isDefault: true,
    trackingEnabled: true,
    verifiedAt: null,
    dimensions: {
      'length': 100.0,
      'width': 90.0,
      'height': 80.0,
    },
    insurance: VehicleInsurance(
      provider: 'Allianz',
      policyNumber: 'POL123456',
      expiryDate: DateTime.now().add(const Duration(days: 365)),
    ),
  );
  await vehicleController.addVehicle(userId, newVehicle);

  // ✏️ Modifier un véhicule existant
  final vehicleToUpdate = vehicleController.userVehicles.firstWhere((v) => v.id == 'veh123');
  final updatedVehicle = vehicleToUpdate.copyWith(
    color: 'Black',
    isDefault: true,
  );
  await vehicleController.updateVehicle(userId, updatedVehicle);

  // 🗑 Supprimer un véhicule
  await vehicleController.deleteVehicle(userId, 'veh123');

  // 🌟 Définir un véhicule comme par défaut
  await vehicleController.setAsDefault(userId, 'veh123');

  // 📄 Initialiser un document vide (utile pour onboarding MVP)
  await vehicleController.initializeEmptyVehicle(userId);

  // 🧼 Supprimer tous les véhicules d’un utilisateur (réinitialisation ou suppression de compte)
  await vehicleController.deleteAllVehicles(userId);

  // 🔍 Vérifier si un véhicule existe dans Firestore
  final exists = await vehicleController.vehicleExists(userId, 'veh123');
  if (exists) {
    print('Le véhicule existe');
  } else {
    print('Le véhicule n’existe pas');
  }

  // 🔄 Écouter les mises à jour en temps réel de la collection vehicles
  final stream = vehicleController.getVehiclesStream(userId);
  stream.listen((vehicles) {
    print('Mise à jour des véhicules : ${vehicles.length}');
  });
}
 */