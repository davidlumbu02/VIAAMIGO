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
  
  return Obx(() {
    ParcelsController? parcelsController;
    try {
      parcelsController = Get.find<ParcelsController>();
    } catch (e) {
      parcelsController = null;
    }
    
    int currentStep = parcelsController?.currentStep.value ?? 0;

    return Container(
      width: double.infinity,
      color: colors.parcelColor,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Row(
        children: [
          // Bouton retour original mais plus compact
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, 
              shape: BoxShape.circle
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () {
                if (navigationController.isModalSheetActive.value) return;
                
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                
                if (parcelsController != null && parcelsController.currentStep.value > 0) {
                  parcelsController.previousStep();
                } else {
                  navigationController.goBack();
                }
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Titre + indicateur compact
          Expanded(
            child: Row(
              children: [
                const Text(
                  "Nouvelle annonce",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                  )
                ),
                
                const Spacer(),
                
                // Indicateur ultra-minimaliste
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Petits points pour chaque étape
                      ...List.generate(4, (index) {
                        bool isActive = index == currentStep;
                        bool isCompleted = index < currentStep;
                        
                        return Container(
                          margin: EdgeInsets.only(right: index < 3 ? 3 : 0),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isActive
                                ? Colors.white
                                : Colors.white.withAlpha(102),
                          ),
                        );
                      }),
                      
                      const SizedBox(width: 6),
                      
                      Text(
                        '${currentStep + 1}/4',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}
