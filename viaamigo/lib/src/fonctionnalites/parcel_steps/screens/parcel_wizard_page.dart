import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_colis.dart';


// Placeholder widgets for each step (to be replaced)

class ParcelWizardPage extends StatelessWidget {
  final controller = Get.put(ParcelsController());

  final List<Widget> pages = [
   ParcelStepColis(),
    //ParcelStepDepart(),
    //ParcelStepArrivee(),
    //ParcelStepPrix(),
  ];

   ParcelWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
