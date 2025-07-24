import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
//import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

class ParcelStepPrix extends StatefulWidget {
  const ParcelStepPrix({super.key});

  @override
  ParcelStepPrixState createState() => ParcelStepPrixState();
}

class ParcelStepPrixState extends State<ParcelStepPrix> {
  final controller = Get.find<ParcelsController>();

  // Controllers pour les champs
  late TextEditingController priceController;
  late TextEditingController declaredValueController;
  late TextEditingController promoCodeController;

  // États des erreurs
  final RxBool priceHasError = false.obs;
  final RxBool declaredValueHasError = false.obs;
  final RxBool promoCodeError = false.obs;

  // Options d'assurance
  final RxString selectedInsuranceLevel = 'none'.obs;
  final RxBool isInsured = false.obs;

  // États du formulaire
  final RxBool isPublishing = false.obs;
  final RxBool promoCodeApplied = false.obs;
  final RxDouble calculatedDiscount = 0.0.obs;
  final RxDouble finalPrice = 0.0.obs;

  // Prix et calculs
  final RxDouble estimatedPrice = 0.0.obs;
  final RxDouble insuranceFee = 0.0.obs;
  final RxDouble platformFee = 0.0.obs;
    // ✅ NOUVEAU : Variable d'erreur spécifique au modal
  final RxBool modalDeclaredValueHasError = false.obs;
  final RxString modalDeclaredValueErrorText = ''.obs;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    
     
  }

  // ✅ NOUVEAU : Setup du listener pour les changements en temps réel

String _getDisplaySizeOrDimensions(ParcelModel parcel) {
  // 1. Vérifier les dimensions réelles
  final dims = parcel.dimensions;
  final hasRealDimensions = dims['length'] != null && dims['length'] > 0 && 
                           dims['width'] != null && dims['width'] > 0 && 
                           dims['height'] != null && dims['height'] > 0;
  
  // 2. Si on a des dimensions réelles, les afficher
  if (hasRealDimensions) {
    return "${dims['length']}×${dims['width']}×${dims['height']} cm";
  }
  
  // 3. Sinon, vérifier si on a une taille
  if (parcel.size.isNotEmpty) {
    return parcel.size;
  }
  
  // 4. Fallback si rien n'est défini
  return "Non défini";
}
Timer? _debounceTimer;

void _debouncedCalculation() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    _updateFinalPrice();
  });
}
void _updateFinalPrice() {
  final price = double.tryParse(priceController.text) ?? 0.0;
  //final discount = calculatedDiscount.value;
  final insurance = insuranceFee.value;
  finalPrice.value = price + insurance ;//- discount;
}


  void _initializeForm() {
    final parcel = controller.currentParcel.value;
    
    if (parcel != null) {
      priceController = TextEditingController(
        text: parcel.initialPrice?.toStringAsFixed(2) ?? ''
      );
      declaredValueController = TextEditingController(
        text: parcel.declared_value?.toStringAsFixed(2) ?? ''
      );
      promoCodeController = TextEditingController(
        text: parcel.promo_code_applied ?? ''
      );
      
      // Initialiser les options d'assurance
      selectedInsuranceLevel.value = parcel.insurance_level;
      isInsured.value = parcel.isInsured;
      insuranceFee.value = parcel.insurance_fee ?? 0.0;
      
      // Initialiser les prix calculés
      estimatedPrice.value = parcel.estimatedPrice ?? 0.0;
      finalPrice.value = parcel.initialPrice ?? parcel.estimatedPrice ?? 0.0;
      
      
      // Si un code promo est déjà appliqué
      if (parcel.promo_code_applied != null && parcel.promo_code_applied!.isNotEmpty) {
        promoCodeApplied.value = true;
        calculatedDiscount.value = parcel.discount_amount ?? 0.0;
      }
      _updateFinalPrice();
    } else {
      priceController = TextEditingController(text: '0.00');
      declaredValueController = TextEditingController();
      promoCodeController = TextEditingController();
      _updateFinalPrice();
    }
    print("ParcelStepPrix initialized with parcel: ${parcel?.id ?? 'none'}");
    print("Initial price: ${priceController.text}");
    print("Initial declared value: ${declaredValueController.text}");
  }



 @override
@override
void dispose() {
  _debounceTimer?.cancel(); // ✅ Ajouter ceci
  priceController.dispose();
  declaredValueController.dispose();
  promoCodeController.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final parcel = controller.currentParcel.value;

    if (parcel == null) {
      return const Center(
        child: Text("⛔ Colis non initialisé", style: TextStyle(color: Colors.red)),
      );
    }

  return Scaffold(
    backgroundColor: colors.parcelColor,
    body: Column(
      children: [
        buildHeader(context),
        Expanded(  // ✅ CRITIQUE : Expanded manquant
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: LayoutBuilder(  // ✅ NOUVEAU : Contraintes explicites
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(  // ✅ NOUVEAU : Hauteur minimale
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40, // Padding
                  ),
                  child: IntrinsicHeight(  // ✅ NOUVEAU : Hauteur adaptative
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sectionTitle(context, "Delivery price"),
                        _buildPriceSection(),
                        const SizedBox(height: 24),

                        sectionTitle(context, "Insurance"),
                        _buildInsuranceSection(),
                        const SizedBox(height: 24),

                        //sectionTitle(context, "Promotional code"),
                        //_buildPromoCodeSection(),
                        //const SizedBox(height: 24),

                        sectionTitle(context, "Summary"),
                        _buildSummarySection(),
                        
                        const Spacer(), // ✅ NOUVEAU : Pousse le bouton vers le bas
                        
                        const SizedBox(height: 32),
                        _buildNextButton(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
  Widget _buildPriceSection() {
    final theme = Theme.of(context);
    final parcel = controller.currentParcel.value!;
    return Column(
      children: [
        // Prix estimé (lecture seule)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(77)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calculator, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Automatic price estimate",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      "${parcel.estimatedDistance?.toStringAsFixed(1) ?? "?"} km •\n ${parcel.weight.toStringAsFixed(1)} kg • \n${_getDisplaySizeOrDimensions(parcel)}•",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${estimatedPrice.value.toStringAsFixed(2)} CAD",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Prix proposé (modifiable)
        Obx(() => CustomTextField(
          controller: priceController,
          labelText: 'Your suggested price',
          hintText: 'Prices in CAD',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          borderRadius: 10,
          isTransparent: true,
          prefixIcon: const Icon(LucideIcons.dollarSign),
          suffixText: 'CAD',
          borderColor: priceHasError.value ? Colors.red : null,
          onChanged: (value) {
            priceHasError.value = false;
            _debouncedCalculation();
                // ✅ NOUVEAU : Sauvegarder le prix immédiatement
          final price = double.tryParse(value);
          if (price != null && price > 0) {
            controller.updateField('initialPrice', price);
          }
          },
        )),
      ],
    );
  }

Widget _buildInsuranceSection() {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ✅ NOUVEAU : Tuile principale - Clic ouvre la modale
      InkWell(
        onTap: () => _showInsuranceSelectionModal(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(() {
            final hasInsurance = isInsured.value;
            final currentLevel = selectedInsuranceLevel.value;
            final declaredValue = double.tryParse(declaredValueController.text) ?? 0.0;
            
            return Row(
              children: [
                Icon(
                  hasInsurance ? LucideIcons.shield : LucideIcons.shieldOff,
                  color: hasInsurance ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasInsurance ? "Insurance activated" : "No insurance",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasInsurance ? theme.colorScheme.primary : null,
                        ),
                      ),
                      Text(
                        hasInsurance 
                          ? "${_getInsuranceLabel(currentLevel)} • \$${declaredValue.toStringAsFixed(2)} CAD"
                          : "Tap to configure protection",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasInsurance && insuranceFee.value > 0) ...[
                  Text(
                    "+\$${insuranceFee.value.toStringAsFixed(0)} CAD",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            );
          }),
        ),
      ),
    ],
  );
}
// ✅ CORRECTION COMPLÈTE du modal d'assurance
// ✅ CORRECTION : Gestion plus sûre des observables temporaires
Future<void> _showInsuranceSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  
  String tempSelectedLevel = selectedInsuranceLevel.value;
  double tempDeclaredValue = double.tryParse(declaredValueController.text) ?? 0.0;
  String tempDeclaredValueText = declaredValueController.text;
  double tempInsuranceFee = insuranceFee.value;

  try {
    await navigationController.showAppBottomSheet<void>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Container(
            // ✅ CORRECTION PRINCIPALE : Contraintes fixes sans dépendance clavier
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              minHeight: 400,
            ),
            child: Padding(
              // ✅ MODIFICATION : Padding sans viewInsets
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle du modal
                  Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // En-tête - Taille fixe
                  SizedBox(
                    height: 80, // ✅ NOUVEAU : Hauteur fixe pour l'en-tête
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.shield,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Choose your insurance",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Protect your parcel against loss, theft and damage during transport",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Champ de saisie - Taille fixe
                  SizedBox(
                    height: 70, // ✅ NOUVEAU : Hauteur fixe
                    child: TextFormField(
                      initialValue: tempDeclaredValueText,
                      decoration: InputDecoration(
                        labelText: 'Declared content value',
                        hintText: 'Enter the value in CAD',
                        prefixIcon: const Icon(LucideIcons.dollarSign),
                        suffixText: 'CAD',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setModalState(() {
                          tempDeclaredValueText = value;
                          tempDeclaredValue = double.tryParse(value) ?? 0.0;
                          _updateFinalPrice();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ CORRECTION PRINCIPALE : Liste scrollable avec Expanded
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Option "Aucune assurance"
                          _buildInsuranceModalOptionFixed(
                            context: context,
                            key: 'none',
                            title: 'No insurance',
                            subtitle: 'No protection (not recommended)',
                            premium: 0.0,
                            maxValue: 0,
                            icon: LucideIcons.x,
                            iconColor: Colors.red,
                            selectedLevel: tempSelectedLevel,
                            declaredValue: tempDeclaredValue,
                            onTap: (key) {
                              setModalState(() {
                                tempSelectedLevel = key;
                                //tempDeclaredValueText = '';
                                tempInsuranceFee = 0.0; // Aucune assurance, pas de frais
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          // Séparateur
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.outline)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Insurance options",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.outline)),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Options d'assurance
                          ...ParcelModel.insuranceTranches.entries
                              .where((entry) => entry.key != 'none')
                              .map((entry) => _buildInsuranceModalOptionFixed(
                                context: context,
                                key: entry.key,
                                title: 'Up to \$${entry.value['maxValue']} CAD',
                                subtitle: 'Coverage up to ${entry.value['maxValue']} CAD',
                                premium: entry.value['premium'].toDouble(),
                                maxValue: entry.value['maxValue'],
                                icon: LucideIcons.shield,
                                iconColor: theme.colorScheme.primary,
                                selectedLevel: tempSelectedLevel,
                                declaredValue: tempDeclaredValue,
                                onTap: (key) {
                                  setModalState(() {
                                    tempSelectedLevel = key;
                                    // Calculer les frais d'assurance
                                    tempInsuranceFee = entry.value['premium'].toDouble();
                                  });
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
                  
                  // ✅ NOUVEAU : Boutons avec hauteur fixe
                  SizedBox(
                    height: 70, // ✅ Hauteur fixe pour les boutons
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: MyButton(
                            onTap: () {
                              if (tempSelectedLevel != 'none') {
                                isInsured.value = true;
                                selectedInsuranceLevel.value = tempSelectedLevel;
                                declaredValueController.text = tempDeclaredValueText;
                                insuranceFee.value = tempInsuranceFee;
                                      // ✅ NOUVEAU : Sauvegarder immédiatement
                                controller.updateField('isInsured', true);
                                controller.updateField('insurance_level', tempSelectedLevel);
                                controller.updateField('declared_value', double.tryParse(tempDeclaredValueText) ?? 0.0);
                                controller.updateField('insurance_fee', tempInsuranceFee);
                              } else {
                                isInsured.value = false;
                                selectedInsuranceLevel.value = 'none';
                                declaredValueController.clear();
                                insuranceFee.value = 0.0;
                                      // ✅ NOUVEAU : Nettoyer les données sauvegardées
                                controller.updateField('isInsured', false);
                                controller.updateField('insurance_level', 'none');
                                controller.updateField('declared_value', null);
                                controller.updateField('insurance_fee', 0.0);
                              }
                              Get.back();
                              _updateFinalPrice();
                              if (tempSelectedLevel == 'none') {
                              UIMessageManager.info("No insurance selected", title: "Insurance updated");
                            } else {
                              UIMessageManager.success(
                                "Insurance ${_getInsuranceLabel(tempSelectedLevel)} selected",
                                title: "Insurance updated"
                              );
                            }
                            },
                            text: "Apply",
                            height: 50,
                            borderRadius: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } catch (e) {
    print("❌ Erreur dans modal assurance: $e");
  }
}


// ✅ NOUVEAU : Widget sans Obx pour éviter les conflits GetX
Widget _buildInsuranceModalOptionFixed({
  required BuildContext context,
  required String key,
  required String title,
  required String subtitle,
  required double premium,
  required int maxValue,
  required IconData icon,
  required Color iconColor,
  required String selectedLevel, // ✅ String simple, pas Rx
  required double declaredValue, // ✅ double simple, pas Rx
  required Function(String) onTap,
}) {
  final theme = Theme.of(context);
  final isSelected = selectedLevel == key;
  
  // Logique inchangée mais sans réactivité GetX
  final isInsufficient = key != 'none' && declaredValue > maxValue && maxValue > 0;
  final isRecommended = key != 'none' && _getRecommendedInsuranceLevel(declaredValue) == key;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: () => onTap(key), // ✅ Callback simple
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
            ? theme.colorScheme.primary.withAlpha(25)
            : null,
        ),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            
            // Contenu (logique identique mais sans Obx)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  
                  // Badge "Recommandé"
                  if (isRecommended) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(77),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Recommanded",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  // Avertissement si couverture insuffisante
                  if (isInsufficient) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Insufficient coverage for the declared value (\$${declaredValue.toStringAsFixed(2)})",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Prix et sélection
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (premium > 0)
                  Text(
                    "+\$${premium.toStringAsFixed(0)} CAD",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                      width: 2,
                    ),
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  child: isSelected 
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


// ✅ Méthode utilitaire pour recommander le niveau d'assurance
// ✅ NOUVEAU : Recommande mais ne force pas
String _getRecommendedInsuranceLevel(double declaredValue) {
  if (declaredValue <= 0) return 'none';
  
  // Recommander la tranche minimale qui couvre la valeur
  // MAIS ne pas l'imposer automatiquement
  for (final entry in ParcelModel.insuranceTranches.entries) {
    if (entry.key == 'none') continue;
    
    final maxValue = entry.value['maxValue'] as int;
    if (declaredValue <= maxValue) {
      return entry.key; // Juste pour affichage "recommandé"
    }
  }
  
  // Si aucune tranche ne couvre, recommander la plus élevée
  final availableKeys = ParcelModel.insuranceTranches.keys
      .where((key) => key != 'none')
      .toList();
  
  return availableKeys.isNotEmpty ? availableKeys.last : 'none';
}



/// Obtient le label d'affichage pour une tranche d'assurance
String _getInsuranceLabel(String key) {
  if (key == 'none') return 'No insurance';
  
  final data = ParcelModel.insuranceTranches[key];
  if (data == null) return 'Unknown';
  
  return 'Up to \$${data['maxValue']} CAD';
}

 /* Widget _buildPromoCodeSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => CustomTextField(
                controller: promoCodeController,
                labelText: 'Promotional code',
                hintText: 'Enter your code',
                borderRadius: 10,
                isTransparent: true,
                prefixIcon: const Icon(LucideIcons.tag),
                borderColor: promoCodeError.value ? Colors.red : null,
                enabled: !promoCodeApplied.value,
                onChanged: (value) {
                  promoCodeError.value = false;
                },
              )),
            ),
            const SizedBox(width: 12),
            Obx(() => ElevatedButton(
              onPressed: promoCodeApplied.value ? _removePromoCode : _applyPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: promoCodeApplied.value ? Colors.red : theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text(
                promoCodeApplied.value ? "Remove" : "Apply",
                style: const TextStyle(color: Colors.white),
              ),
            )),
          ],
        ),
        
        // Affichage du code appliqué
        Obx(() {
          if (!promoCodeApplied.value) return const SizedBox.shrink();
          
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Promotional code applied",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Reduction of ${calculatedDiscount.value.toStringAsFixed(2)} CAD",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }*/

// ✅ Dans _buildSummarySection, ajouter des contraintes
Widget _buildSummarySection() {
  final theme = Theme.of(context);

  return Obx(() => Container(
    width: double.infinity, // ✅ NOUVEAU : Largeur explicite
    constraints: const BoxConstraints(
      minHeight: 100, // ✅ NOUVEAU : Hauteur minimale
      maxHeight: 400, // ✅ NOUVEAU : Hauteur maximale
    ),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // ✅ NOUVEAU : Taille minimale
      children: [
        _buildSummaryLine("Delivery price", "${double.tryParse(priceController.text)?.toStringAsFixed(2) ?? "0.00"} CAD"),
        if (insuranceFee.value > 0)
          _buildSummaryLine("Insurance", "${insuranceFee.value.toStringAsFixed(2)} CAD"),
        //_buildSummaryLine("Platform costs", "${platformFee.value.toStringAsFixed(2)} CAD"),
        if (calculatedDiscount.value > 0)
          _buildSummaryLine("Reduction", "-${calculatedDiscount.value.toStringAsFixed(2)} CAD", isDiscount: true),
        const Divider(thickness: 1),
        _buildSummaryLine(
          "Total ", 
          "${finalPrice.value.toStringAsFixed(2)} CAD", 
          isTotal: true,
        ),
      ],
    ),
  ));
}


  Widget _buildSummaryLine(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : null,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : null,
              color: isDiscount ? Colors.green : (isTotal ? theme.colorScheme.primary : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Obx(() => MyButton(
      onTap:() async {
      if (!_validateAllFields()) return;
      _saveData();
      //Get.find<NavigationController>().navigateToNamed('parcel-step-next'); // ← à adapter selon ton routing
    }, 
      text: "Next step",
      height: 56,
      width: double.infinity,
      borderRadius: 30,
      backgroundColor: isPublishing.value ? Colors.grey : null,
      child: isPublishing.value 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : null,
    ));
  }

  /*void _applyPromoCode() async {
    final code = promoCodeController.text.trim();
    if (code.isEmpty) {
      promoCodeError.value = true;
      Get.snackbar(
        "Invalid code",
        "Please enter a promotional code",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _updateFinalPrice();
      return;
    }

    // Simulation de validation de code promo
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock de codes promotionnels
    final mockPromoCodes = {
      'WELCOME10': 10.0,
      'SAVE20': 20.0,
      'FIRST50': 50.0,
    };

    if (mockPromoCodes.containsKey(code.toUpperCase())) {
      calculatedDiscount.value = mockPromoCodes[code.toUpperCase()]!;
      promoCodeApplied.value = true;      
      Get.snackbar(
        "Applied code",
        "Reduction of ${calculatedDiscount.value.toStringAsFixed(2)} CAD applied",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      promoCodeError.value = true;
      Get.snackbar(
        "Invalid code",
        "This promotional code does not exist or has expired",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }*/

 /* void _removePromoCode() {
    promoCodeController.clear();
    promoCodeApplied.value = false;
    calculatedDiscount.value = 0.0;
    _updateFinalPrice();
    Get.snackbar(
      "Code removed",
      "The promotional code has been removed",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }*/

bool _validateAllFields() {
  bool isValid = true;
  List<String> errors = [];

  // Validation prix (inchangée)
  final price = double.tryParse(priceController.text.trim());
  if (price == null || price <= 0) {
    priceHasError.value = true;
    errors.add("Price must be greater than 0");
    isValid = false;
  } else if (price < 5.0) {
    priceHasError.value = true;
    errors.add("The minimum price is CAD 5.00");
    isValid = false;
  } else if (price > 10000.0) {
    priceHasError.value = true;
    errors.add("The maximum price is 10,000.00 CAD");
    isValid = false;
  }

  // ✅ VALIDATION ASSURANCE MODIFIÉE POUR PERMETTRE LA LIBERTÉ DE CHOIX
  if (isInsured.value) {
    final declaredValue = double.tryParse(declaredValueController.text.trim());
    if (declaredValue == null || declaredValue <= 0) {
      declaredValueHasError.value = true;
      errors.add("Declared value required for insurance purposes");
      isValid = false;
    } else if (declaredValue < 10.0) {
      declaredValueHasError.value = true;
      errors.add("The minimum declared value is 10.00 CAD");
      isValid = false;
    } else {
      // ✅ CHANGEMENT PRINCIPAL : Avertissement au lieu d'erreur bloquante
      final maxCoverage = ParcelModel.insuranceTranches[selectedInsuranceLevel.value]?['maxValue'] ?? 0;
      if (declaredValue > maxCoverage && maxCoverage > 0) {
        // Ne plus bloquer ici, juste informer l'utilisateur
        // declaredValueHasError.value = true;  // ❌ SUPPRIMÉ
        // errors.add("Declared value exceeds maximum coverage of \$$maxCoverage CAD");  // ❌ SUPPRIMÉ
        // isValid = false;  // ❌ SUPPRIMÉ
        
        // ✅ NOUVEAU : Afficher un avertissement informatif
        UIMessageManager.warning(
  "Your item is worth \$${declaredValue.toStringAsFixed(2)} CAD but the selected insurance only covers up to \$$maxCoverage CAD.\n\nIn case of loss, you will only be reimbursed up to \$$maxCoverage CAD.",
  title: "Insufficient coverage",
  duration: const Duration(seconds: 5),
);
      }
    }
    
    // Vérifier que la valeur déclarée est cohérente avec le prix (inchangé)
    if (declaredValue != null && price != null && declaredValue < price) {
      UIMessageManager.warning(
  "Declared value(\$${declaredValue.toStringAsFixed(2)} CAD) is lower than the delivery price (\$${price.toStringAsFixed(2)} CAD)",
  title: "Attention",
);
    }
  }

  if (!isValid) {
    UIMessageManager.validationError(errors.join('\n'));
  }

  return isValid;
}
void _saveData() async {
  try {
    final parcel = controller.currentParcel.value;
    if (parcel == null) throw Exception("Colis non initialisé");

    // ✅ Validation finale avant sauvegarde
    final finalPriceValue = finalPrice.value;
    final initialPriceValue = double.tryParse(priceController.text) ?? 0.0;
    
    if (finalPriceValue <= 0 || initialPriceValue <= 0) {
      throw Exception("Invalid price");
    }

    // Sauvegarder le prix final
    await controller.updateField('initialPrice', finalPriceValue);
    //await controller.updateField('initialPrice', initialPriceValue);
    
    
    if (isInsured.value && declaredValueController.text.isNotEmpty) {
      final declaredValue = double.tryParse(declaredValueController.text) ?? 0.0;
      await controller.updateField('declared_value', declaredValue);
      
      // ✅ NOUVEAU : Sauvegarder les frais d'assurance calculés
      await controller.updateField('insurance_fee', insuranceFee.value);
    } else {
      // ✅ Nettoyer les champs d'assurance si désactivée
      await controller.updateField('declared_value', null);
      await controller.updateField('insurance_fee', 0.0);
    }

    // Sauvegarder le code promo si appliqué
    if (promoCodeApplied.value && promoCodeController.text.trim().isNotEmpty) {
      await controller.updateField('promo_code_applied', null);
      await controller.updateField('discount_amount', 0);
    } else {
      // ✅ Nettoyer les codes promo si non appliqués
      await controller.updateField('promo_code_applied', null);
      await controller.updateField('discount_amount', 0.0);
    }
    
    print("✅ RÉSUMÉ PRIX SAUVEGARDÉ:");
    print("   - Prix initial: ${initialPriceValue.toStringAsFixed(2)} CAD");
    print("   - Frais assurance: ${insuranceFee.value.toStringAsFixed(2)} CAD");
    print("   - Niveau assurance: ${selectedInsuranceLevel.value}");
    print("   - Frais plateforme: ${platformFee.value.toStringAsFixed(2)} CAD");
    print("   - Réduction: ${calculatedDiscount.value.toStringAsFixed(2)} CAD");
    print("   - Prix final: ${finalPriceValue.toStringAsFixed(2)} CAD");
    
  } catch (e) {
    print("❌ Erreur lors de la sauvegarde des prix: $e");
    rethrow; // Re-lancer l'erreur pour gestion dans _publishParcel
  }
}
}