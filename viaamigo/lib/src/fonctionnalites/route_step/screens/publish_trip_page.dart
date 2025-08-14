import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/trip/controller/trip_controller.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

class PublishTripPage extends StatefulWidget {
  const PublishTripPage({super.key});

  @override
  State<PublishTripPage> createState() => _PublishTripPageState();
}

class _PublishTripPageState extends State<PublishTripPage> {
  // ✅ CORRECTION: Initialisation sécurisée du controller
  late final TripController tripController;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeForm();
  }

  // ✅ NOUVEAU: Méthode pour initialiser le controller de manière sécurisée
  void _initializeController() {
    try {
      tripController = Get.find<TripController>();
    } catch (e) {
      // Si le controller n'existe pas, le créer
      print('⚠️ TripController non trouvé, création...');
      tripController = Get.put(TripController());
    }
  }

  void _initializeForm() {
    try {
      final tripModel = tripController.currentTrip.value;
      print('✅ Trip model loaded: $tripModel');
    } catch (e) {
      print('❌ Erreur initialisation form: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
 
    return Scaffold(
      backgroundColor: colors.parcelColor,
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(context, "Voyage"),
                    const SizedBox(height: 8),
                    // ✅ AJOUT: Contenu du voyage
                    _buildTripContent(context),
                  ],
                ), // ✅ CORRECTION: Parenthèse bien fermée
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU: Méthode pour construire le contenu du voyage
  Widget _buildTripContent(BuildContext context) {
    return Obx(() {
      final currentTrip = tripController.currentTrip.value;
      
      if (currentTrip == null) {
        return const Center(
          child: Text('Aucun voyage en cours'),
        );
      }
      
      return Column(
        children: [
          // Ajoutez ici vos widgets pour afficher les détails du voyage
          Text('Voyage: ${currentTrip.toString()}'),
          // Plus de contenu selon vos besoins...
        ],
      );
    });
  }
}