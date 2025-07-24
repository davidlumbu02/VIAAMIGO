import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_arrive.dart';

// Import des étapes
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_colis.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_depart.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_prix.dart';


/// 🔄 Assistant de création de colis, 4 étapes avec transitions fluides.
/// Chaque étape gère son propre bouton "Suivant".
class ParcelWizardPage extends StatelessWidget {
  ParcelWizardPage({super.key});

  /*
    ParcelWizardPage({super.key}) {
  // Initialisation sécurisée du controller
  if (!Get.isRegistered<ParcelsController>()) {
    final controller = Get.put(ParcelsController());
    controller.initParcel();
  } else {
    Get.find<ParcelsController>().initParcel();
  }
} */

  // Étapes de l'assistant colis (Widgets en ordre)
  final List<Widget> steps = [
    ParcelStepColis(),
   ParcelStepDepart(),
    ParcelStepArrivee(),
    ParcelStepPrix(),
  ];

  @override
  Widget build(BuildContext context) {
    final parcelController = Get.find<ParcelsController>();
    //final navigationController = Get.find<NavigationController>();

    return Obx(() {
      final parcel = parcelController.currentParcel.value;

      if (parcel == null || parcelController.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,


        /// 🧭 Étape actuelle avec transition animée
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: steps[parcelController.currentStep.value],
        ),
      );
    });
  }
}

/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_colis.dart';


// Placeholder widgets for each step (to be replaced)

class ParcelWizardPage extends StatelessWidget {
  final controller = Get.put(ParcelsController());

  ParcelWizardPage({super.key}) {
    controller.initParcel(); // ✅ Appelle l'initialisation ici
  }

  final List<Widget> pages = [
    ParcelStepColis(),
    // ParcelStepDepart(),
    // ParcelStepArrivee(),
    // ParcelStepPrix(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final parcel = controller.currentParcel.value;

      // ✅ Étape 2 – Gérer le chargement
      if (parcel == null || controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text("Nouvelle annonce"),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: pages[controller.currentStep.value],
        ),
        bottomNavigationBar: const ParcelStepNavigation(),
      );
    });
  }
}
class ParcelStepNavigation extends StatelessWidget {
  const ParcelStepNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParcelsController>();
    return Obx(() {
      final step = controller.currentStep.value;
      final isLast = step == 3;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.previousStep(),
                  child: const Text("Retour"),
                ),
              ),
            if (step > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (isLast) {
                    final success = await controller.publishParcel();
                    if (success) Get.offAllNamed('/confirmation');
                  } else {
                    await controller.nextStep();
                  }
                },
                child: Text(isLast ? "Valider" : "Suivant"),
              ),
            ),
          ],
        ),
      );
    });
  }
}
*/