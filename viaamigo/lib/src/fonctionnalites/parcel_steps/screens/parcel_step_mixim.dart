import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
//import 'package:get/get_core/src/get_main.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

Widget buildHeader(BuildContext context) {
  final colors = Theme.of(context).extension<AppColors>()!;
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  
  return Container(
    width: double.infinity,
    color: colors.parcelColor,
    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ✅ Si un modal est actif, ne pas naviguer
              if (navigationController.isModalSheetActive.value) return;
              
              // ✅ Vérifier d'abord s'il y a un modal Flutter natif ouvert
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return;
              }
              
              // ✅ Gérer la navigation normale
              final controller = Get.find<ParcelsController>();
              if (controller.currentStep.value > 0) {
                controller.previousStep();
              } else {
                navigationController.goBack();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        const Text("Nouvelle annonces", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
