import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_arrive.dart';

// Import des étapes
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_colis.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_depart.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_payment_choice.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_prix.dart';


/// 🔄 Assistant de création de colis, 4 étapes avec transitions fluides.
/// Chaque étape gère son propre bouton "Suivant".
class ParcelWizardPage extends StatefulWidget {
  const ParcelWizardPage({super.key});

  @override
  State<ParcelWizardPage> createState() => _ParcelWizardPageState();
}

class _ParcelWizardPageState extends State<ParcelWizardPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }
 @override
  void dispose() {
    // Indiquer qu'on quitte le wizard
    try {
      final controller = Get.find<ParcelsController>();
      controller.onLeaveWizard();
    } catch (e) {
      print('❌ Erreur dispose: $e');
    }
    super.dispose();
  }
  /*Future<void> _initializeController() async {
    try {
      // Le contrôleur est déjà permanent depuis main.dart
      final controller = Get.find<ParcelsController>();
      
      // Initialiser seulement si pas déjà fait
      if (controller.currentParcel.value == null) {
        await controller.initParcel();
      }
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('❌ Erreur initialisation ParcelWizard: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }*/
  // Remplacez votre _initializeController() existant par :
  Future<void> _initializeController() async {
    try {
      final controller = Get.find<ParcelsController>();
      
      // Indiquer qu'on vient de naviguer vers le wizard
      controller.onNavigateToWizard();
      
      // ✅ LOGS DE DEBUG
      print('🔍 DEBUG - currentParcel exists: ${controller.currentParcel.value != null}');
      print('🔍 DEBUG - isLocalMode: ${controller.isLocalMode.value}');
      print('🔍 DEBUG - currentStep: ${controller.currentStep.value}');
      if (controller.currentParcel.value != null) {
        print('🔍 DEBUG - parcel title: "${controller.currentParcel.value!.title}"');
        print('🔍 DEBUG - parcel weight: ${controller.currentParcel.value!.weight}');
      }

      // Vérifier si on doit montrer le modal
      final shouldShowModal = await controller.shouldShowDraftModal();
      print('🔍 DEBUG - shouldShowModal: $shouldShowModal');
      
      if (shouldShowModal && mounted) {
        // Afficher le modal de choix avec votre méthode native
        await _showDraftChoiceModal(controller);
      } else {
        // Initialiser normalement
        if (controller.currentParcel.value == null) {
          await controller.initParcel();
        }
      }
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('❌ Erreur initialisation ParcelWizard: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }
Future<void> _showDraftChoiceModal(ParcelsController controller) async {
  // Marquer que le modal va être montré
  controller.onDraftModalShown();
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  
  final choice = await navigationController.showAppBottomSheet<String>(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: theme.colorScheme.surface, 
    isScrollControlled: true,
    enableDrag: true, 
    child: _buildDraftChoiceContent(context),
  );
   print('🔍 Modal dismissed with choice: $choice');
   // ✅ AJOUTEZ CES LOGS
print('🔍 DEBUG - choice returned: $choice');
print('🔍 DEBUG - choice is null: ${choice == null}');
  // Traiter le choix
  if (choice == 'continue') {
    print('✅ User chose continue');
    await controller.continueDraft();
  } else if (choice == 'new') {
    print('✅ User chose new');
    await controller.startNewParcel();
  } else {
    // ✅ CAS NOUVEAU : Modal fermé sans choix → Retourner à RoleSelectionPage
    print('⬅️ Modal dismissed - returning to role selection');
    await _handleModalDismissedToRoleSelection(controller);
  }
}
// ✅ NOUVELLE MÉTHODE : Gestion du retour à la sélection de rôle
Future<void> _handleModalDismissedToRoleSelection(ParcelsController controller) async {
  final navigationController = Get.find<NavigationController>();
  
  // 1. Nettoyer l'état du contrôleur de colis
  controller.onLeaveWizard();
    await Future.delayed(const Duration(milliseconds: 400));
  // 2. Naviguer vers le tab role-selection (index 2)
   print('🔄 [AppShell] Modal fermée, retour par historique...');
  
  // Navigation par l'historique au lieu d'aller directement à l'onglet
  if (navigationController.canGoBack()) {
    navigationController.goBack();
    print('✅ [AppShell] Retour effectué via l\'historique');
  } else {
    // Fallback si pas d'historique disponible
    print('⚠️ [AppShell] Pas d\'historique, navigation vers l\'onglet par défaut');
    navigationController.goToTab(2); // Garde comme fallback
  }
  

}

Widget _buildDraftChoiceContent(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  
  return Container(
    width: double.infinity,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar (poignée)
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 20),
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withAlpha(102),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        
        // Contenu principal
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et texte
                _buildHeader(context, colorScheme, textTheme),
                
                const SizedBox(height: 24),
                
                // Message d'information
                _buildInfoCard(context, colorScheme, textTheme),
                
                const SizedBox(height: 32),
                
                // Boutons d'action
                _buildActionButtons(context, colorScheme, textTheme),
                
                // Espace pour les insets du clavier
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
  return Row(
    children: [
      // Icône avec container stylisé
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.edit_document,
          color: colorScheme.onPrimaryContainer,
          size: 28,
        ),
      ),
      
      const SizedBox(width: 16),
      
      // Textes
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form in progress',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'You have a parcel form in progress.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorScheme.secondaryContainer.withAlpha(127),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.outline.withAlpha(51),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.help_outline_rounded,
          color: colorScheme.onSecondaryContainer,
          size: 20,
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Text(
            'What would you like to do?',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
  return Column(
    children: [
      // Bouton principal - Continuer
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop('continue'),
          icon: Icon(
            Icons.play_arrow_rounded,
            size: 20,
          ),
          label: Text(
            'Continue with the form',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      
      const SizedBox(height: 16),
      
      // Bouton secondaire - Nouveau
      SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop('new'),
          icon: Icon(
            Icons.refresh_rounded,
            size: 20,
          ),
          label: Text(
            'Start a new package',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(
              color: colorScheme.error.withAlpha(127),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Préparation de votre colis...'),
            ],
          ),
        ),
      );
    }

    final parcelController = Get.find<ParcelsController>();

    return Obx(() {
      final parcel = parcelController.currentParcel.value;

      if (parcel == null || parcelController.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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

  // ✅ VOS ÉTAPES EXISTANTES restent inchangées
  final List<Widget> steps = [
    ParcelStepColis(),
    ParcelStepDepart(),
    ParcelStepArrivee(),
    ParcelStepPrix(),
    ParcelStepPaymentChoice(),
  ];
}
/*class ParcelWizardPage extends StatelessWidget {
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
}*/

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