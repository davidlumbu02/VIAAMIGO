import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
//import 'package:viaamigo/shared/collections/parcel/model/parcel_dimension_model.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/shared/widgets/theme_button.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';

class ParcelStepColis extends StatefulWidget  {
  const ParcelStepColis({super.key});

   @override
  ParcelStepColisState createState() => ParcelStepColisState();
}
  class ParcelStepColisState extends State<ParcelStepColis> {
  // ✅ Récupération du controller ParcelsController
  final controller = Get.find<ParcelsController>();
  
   int get MAX_PHOTOS => controller.maxPhotos; 
  final ImagePicker _picker = ImagePicker();
  final RxBool isUploadingPhoto = false.obs;
  // ✅ Variables GetX 
  final RxBool useExactDimensions = false.obs;
  final RxString selectedSize = ''.obs;
  final RxString selectedWeight = ''.obs;
  final RxBool lengthHasError = false.obs;
  final RxBool widthHasError = false.obs;
  final RxBool heightHasError = false.obs;
  final RxBool quantityHasError = false.obs;
  final RxBool titleHasError = false.obs;
  final RxBool sizeHasError = false.obs;
  final RxBool weightHasError = false.obs;
  
  // ✅ Contrôleurs late
  late TextEditingController quantityController;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  late TextEditingController heightController;
  


  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
void _initializeForm() {
  final parcel = controller.currentParcel.value;
  
  if (parcel != null) {
    quantityController = TextEditingController(text: parcel.quantity.toString());
    titleController = TextEditingController(text: parcel.title);
    descriptionController = TextEditingController(text: parcel.description);
    lengthController = TextEditingController(text: parcel.dimensions['length']?.toString() ?? '');
    widthController = TextEditingController(text: parcel.dimensions['width']?.toString() ?? '');
    heightController = TextEditingController(text: parcel.dimensions['height']?.toString() ?? '');
    selectedSize.value = parcel.size;
    //selectedWeight.value = _getWeightCategory(parcel.weight);
    
    // ✅ NOUVEAU : Déterminer le mode initial EXCLUSIF
    final dims = parcel.dimensions;
    bool hasDimensions = dims['length'] != null && dims['length'] > 0 && 
                         dims['width'] != null && dims['width'] > 0 && 
                         dims['height'] != null && dims['height'] > 0;
    
    if (hasDimensions) {
      // Si on a des dimensions réelles, activer le mode exact
      useExactDimensions.value = true;
      selectedSize.value = ''; // ← Vider la taille affichée
    } else if (parcel.size.isNotEmpty) {
      // Si on a une taille mais pas de dimensions, mode taille
      useExactDimensions.value = false;
      // Garder selectedSize.value = parcel.size (déjà fait plus haut)
    } else {
      // Aucune donnée, mode taille par défaut
      useExactDimensions.value = false;
      //selectedSize.value = 'SIZE M';
    }
  } else {
    quantityController = TextEditingController(text: '1');
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    lengthController = TextEditingController();
    widthController = TextEditingController();  
    heightController = TextEditingController();
    // ✅ Valeurs par défaut
   // selectedSize.value = 'SIZE M'; // Taille par défaut
    useExactDimensions.value = false; // Mode tailles par défaut
  }
}
  
   String _getWeightCategory(double? weight) {
    if (weight == null) return '';
    
    final Map<String, double> weightOptions = {
      '< 5 kg': 4.9,
      '5–10 kg': 7.5,
      '10–30 kg': 30.0,
      '30–50 kg': 40.0,
      '50–70 kg': 55.0,
      '70–100 kg': 80.0,
      '> 100 kg': 100.0,
    };
    
    for (var entry in weightOptions.entries) {
      if (weight <= entry.value) {
        return entry.key;
      }
    }
    return '> 100 kg';
  }
void _onDimensionModeChanged(bool useExact) {
  useExactDimensions.value = useExact;
  FocusScope.of(context).unfocus(); // ✅ Ferme le clavier
  if (!useExact) {
    // Passage en mode tailles prédéfinies : vider les dimensions
    lengthController.clear();
    widthController.clear();
    heightController.clear();
    lengthHasError.value = false;
    widthHasError.value = false;
    heightHasError.value = false;
  }
  // Note: on ne vide pas selectedSize car on garde la taille dans les deux modes
}

 @override
  void dispose() {
    // ✅ Libération de la mémoire
    quantityController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    //parcel model
    final  parcel = controller.currentParcel.value;
    if (parcel == null) {
      return const Center(child: Text("⛔ package not initialized", style: TextStyle(color: Colors.red)));
    }

    if (parcel.weight > 0 && selectedWeight.value.isEmpty) {//if (parcel.weight != null) {
      selectedWeight.value = _getWeightCategory(parcel.weight);
    }

    return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(), // ✅ Ferme le clavier au clic extérieur
  behavior: HitTestBehavior.translucent, // Important pour capturer les taps "vides"
      child: Scaffold(
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
                   keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle(context, "Package photos"),
                      _photoPicker(context, parcel),
                      const SizedBox(height: 24),
      
                      sectionTitle(context, "Description"),
                            Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child:  Obx(() =>CustomTextField(
                                  controller: quantityController,
                                  //hintText: 'Quantité',
                                  keyboardType: TextInputType.number,
                                  borderRadius: 10,
                                  isTransparent: true,
                                  borderColor: quantityHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77), // ✅ ICI
                                  onChanged: (_) => quantityHasError.value = false,
                                  
                                ),)
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child:  Obx(() =>CustomTextField(
                                  controller: titleController,
                                  labelText: 'Title',
                                  hintText: 'Ex: Handbag, TV...',
                                  //onSubmitted: (val) => controller.updateField('title', val),
                                  borderRadius: 10,
                                  isTransparent: true,
                                  borderColor: titleHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77),
                                 onChanged: (_) => titleHasError.value = false,
                                ),)
                              )
                            ],
                          ),
      
      
                      const SizedBox(height: 24),
                      sectionTitle(context, "Dimensions"),
                      Obx(() => Row(
                            children: [
                              Text("I know the exact dimensions", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Switch(value: useExactDimensions.value, onChanged: _onDimensionModeChanged),
                              //Switch(value: useExactDimensions.value, onChanged: useExactDimensions.call),
                            ],
                          )),
                      const SizedBox(height: 8),
                      Obx(() => useExactDimensions.value 
                        ? _exactDimensions(parcel)
                        : buildButtonTextLogo(
                            context,
      
                            label: selectedSize.value.isNotEmpty 
                                ? selectedSize.value 
                                : "Choose a size",
                            icon: LucideIcons.ruler,
                            isFilled: false,
                            alignIconStart: true,
                            borderRadius: 10,
                            height: 50,
                            endIcon: Icons.expand_more,
                            bordercolerput: sizeHasError.value
                            ? Colors.red
                            : theme.colorScheme.primary.withAlpha(77),
                            onTap: () async {
                              FocusScope.of(context).unfocus(); // ✅ Ferme le clavier
                              // Utiliser la valeur actuelle de selectedSize comme référence
                              final currentSize = selectedSize.value.isNotEmpty 
                                  ? selectedSize.value 
                                  : controller.currentParcel.value?.size ?? "";
                              
                              await showParcelSizeSelectorModal(context, currentSize, (selected) {
                                
                                controller.updateField('size', selected);
                                // CORRECTION: Mettre à jour selectedSize.value ici pour maintenir la cohérence
                                selectedSize.value = selected;
                              });
                            },
                            outlined: true,
                          )
                      ),
      
                      const SizedBox(height: 24),
                      sectionTitle(context, "Weight"),
                      _openWeightModal(context),
      
                      const SizedBox(height: 32),
                      sectionTitle(context, "Additional info"),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: "Ex: The longest box is 2m15, the heaviest is a sofa",
                        labelText: "infos",
                        onSubmitted: (val) => controller.updateField('description', val),
                        maxLines: 6,
                        borderRadius: 10,
                        isTransparent: true,
                        borderColor: theme.colorScheme.primary.withAlpha(77),
                      ),
      
                      const SizedBox(height: 32),
                      MyButton(
                        onTap: () {
                          if (_validateAllFields()) {
                            // Save all data (weight is already saved in modal)
                            controller.updateField('title', titleController.text.trim());
                            controller.updateField('description', descriptionController.text.trim());
                            controller.updateField('quantity', int.tryParse(quantityController.text.trim()) ?? 1);
                            controller.calculateEstimatePrice();
                            
                            // ✅ NOUVEAU : SOIT/SOIT exclusif
                            if (useExactDimensions.value) {
                              // Mode dimensions exactes : dimensions réelles + size = vide/null
                              // Les dimensions sont déjà sauvegardées dans _validateAndSaveDimensions()
                              controller.updateField('size', ''); // ← Vider la taille
                            } else {
                              // Mode tailles prédéfinies : taille + dimensions = 0
                              controller.updateField('size', selectedSize.value);
                              controller.updateField('dimensions', {'length': 0, 'width': 0, 'height': 0});
                            }
                            controller.nextStep();
                          }
                        },
                        text: "Next step",
                        height: 50,
                        width: double.infinity,
                        borderRadius: 30,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }




Widget _photoPicker(BuildContext context, ParcelModel parcel) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ✅ Afficher le nombre de photos actuel
      Obx(() {
        //final photos = controller.currentParcel.value?.photos ?? [];
        final photos = controller.photosList;
        final canAddMore = photos.length < MAX_PHOTOS;
        
        return GestureDetector(
          onTap: (isUploadingPhoto.value || !canAddMore) ? null : _showImageSourceModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: !canAddMore 
                  ? Colors.grey.withAlpha(77)
                  : isUploadingPhoto.value 
                    ? Colors.grey.withAlpha(77)
                    : theme.colorScheme.primary.withAlpha(77)
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (isUploadingPhoto.value)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else if (!canAddMore)
                  Icon(Icons.photo_library, size: 32, color: Colors.grey.shade400)
                else
                  const Icon(Icons.camera_alt_outlined, size: 32, color: Colors.grey),
                
                const SizedBox(height: 8),
                Text(
                  isUploadingPhoto.value 
                    ? "Uploading..." 
                    : !canAddMore 
                      ? "Maximum $MAX_PHOTOS photos reached"
                      : "Add photos (${photos.length}/$MAX_PHOTOS)", 
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: !canAddMore ? Colors.grey : null,
                  )
                ),
                
                if (canAddMore) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(77),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "AI-analyzed photos", 
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      )
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Add photos, we'll ",
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        TextSpan(
                          text: "handle the rest", 
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.primary
                          )
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      }),

      const SizedBox(height: 16),

      // ✅ Photos existantes en une seule ligne horizontale scrollable
      Obx(() {
        //final photos = controller.currentParcel.value?.photos ?? [];
        final photos = controller.photosList;
        if (photos.isEmpty) {
          return const SizedBox.shrink(); // N'affiche rien si pas de photos
        }
        
        return SizedBox(
          height: 100, // ✅ Hauteur fixe pour la ligne de photos
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // ✅ Scroll horizontal
            child: Row(
              children: [
                ...photos.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final photoUrl = entry.value;
                    
                    return Container(
                      margin: EdgeInsets.only(
                        right: index < photos.length - 1 ? 12 : 0, // ✅ Espacement entre les photos
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildPhotoWidget(photoUrl),
                            
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withAlpha(128),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 14, color: Colors.white),
                              onPressed: () => controller.removePhoto(photoUrl),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}


// ✅ Méthode séparée pour construire l'image
Widget _buildPhotoWidget(String photoUrl) {
  // Si c'est un chemin local (commence par /)
  if (photoUrl.startsWith('/')) {
    return Image.file(
      File(photoUrl),
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  } else {
    // Si c'est une URL réseau
    return Image.network(
      photoUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }
}

  Widget _exactDimensions(ParcelModel parcel) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child:  Obx(() => CustomTextField(
            controller: lengthController,
            hintText: 'Length',
            keyboardType: TextInputType.number,
            //onSubmitted: (val) => controller.updateDimension('length', val),
            borderRadius: 10,
            isTransparent: true,
            borderColor: lengthHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77),
          ),),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:  Obx(() =>CustomTextField(
            controller: widthController,
            hintText: 'Width',
            keyboardType: TextInputType.number,
           // onSubmitted: (val) => controller.updateDimension('width', val),
            borderRadius: 10,
            isTransparent: true,
            borderColor: widthHasError.value ? Colors.red :  theme.colorScheme.primary.withAlpha(77),
          ),),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:  Obx(() =>CustomTextField(
            controller: heightController,
            hintText: 'Height',
            keyboardType: TextInputType.number,
          //  onSubmitted: (val) => controller.updateDimension('height', val),
            borderRadius: 10,
            isTransparent: true,
            borderColor: heightHasError.value ? Colors.red :  theme.colorScheme.primary.withAlpha(77),
          ),
        ),),
      ],
    );
  }

  Widget _openWeightModal(BuildContext context) {
  return Obx(() => buildButtonTextLogo(
    context,
    label: selectedWeight.value.isNotEmpty ? selectedWeight.value : "Choose a weight",
    icon: LucideIcons.dumbbell,
    isFilled: false,
    alignIconStart: true,
    height: 50,
    borderRadius: 10,
    endIcon: Icons.expand_more,
    bordercolerput: weightHasError.value 
        ? Colors.red 
        : Theme.of(context).colorScheme.primary.withAlpha(77),
    onTap: () async {
      final theme = Theme.of(context);
      final navigationController = Get.find<NavigationController>();

      final Map<String, double> options = {
        '< 5 kg': 4.9,
        '5–10 kg': 7.5,
        '10–30 kg': 30.0,
        '30–50 kg': 40.0,
        '50–70 kg': 55.0,
        '70–100 kg': 80.0,
        '> 100 kg': 100.0,
      };

      // ✅ UTILISER showAppBottomSheet
      await navigationController.showAppBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: theme.colorScheme.surface, 
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle du modal
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Titre
                Text(
                  "Choose a weight", 
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                
                // Options de poids
                ...options.entries.map((entry) {
                  final bool selected = selectedWeight.value == entry.key;

                  return Container(
                    height: 55,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: ListTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        // ✅ Mettre à jour les valeurs
                        controller.updateField('weight', entry.value);
                        selectedWeight.value = entry.key;
                        // ✅ Reset l'erreur quand on sélectionne
                        weightHasError.value = false;
                        
                        // ✅ Fermer le modal
                        Get.back();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
    outlined: true,
  ));
}
  void safePop(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
bool _validateAllFields() {
  bool isValid = true;
  
  // Quantity validation
  final quantity = int.tryParse(quantityController.text.trim());
  quantityHasError.value = quantity == null || quantity <= 0;
  if (quantityHasError.value) isValid = false;
  
  // Title validation
  titleHasError.value = titleController.text.trim().isEmpty;
  if (titleHasError.value) isValid = false;
  
  // Weight validation
   // ✅ Weight validation avec weightHasError
  weightHasError.value = selectedWeight.value.isEmpty;
  if (selectedWeight.value.isEmpty) {
    UIMessageExtensions.chooseWeight();
    isValid = false;
  }
  
  // Size validation if selection mode
// ✅ NOUVEAU : Validation selon le mode choisi SANS custom
 // ✅ CORRECTION : Validation selon le mode choisi (EXCLUSIF)
  if (useExactDimensions.value) {
    // Mode dimensions exactes : valider SEULEMENT les dimensions
    if (!_validateAndSaveDimensions()) isValid = false;
    // ❌ NE PAS valider la taille en mode dimensions exactes
  } else {
    // Mode tailles prédéfinies : valider SEULEMENT la taille
    sizeHasError.value = selectedSize.value.isEmpty;
    if (sizeHasError.value) {
      UIMessageManager.validationError("Please choose a size");
      isValid = false;
    }
  }
  
  if (!isValid) {
  UIMessageManager.validationError("Please fill in all required fields");
  }
  
  return isValid;
}

bool _validateAndSaveDimensions() {
  final lengthText = lengthController.text.trim();
  final widthText = widthController.text.trim();
  final heightText = heightController.text.trim();

  final double? length = double.tryParse(lengthText);
  final double? width = double.tryParse(widthText);
  final double? height = double.tryParse(heightText);

  lengthHasError.value = length == null || length <= 0;
  widthHasError.value = width == null || width <= 0;
  heightHasError.value = height == null || height <= 0;

  if (lengthHasError.value || widthHasError.value || heightHasError.value) {
    UIMessageExtensions.enterValidDimensions();
    return false;
  }

  controller.updateDimension('length', lengthText);
  controller.updateDimension('width', widthText);
  controller.updateDimension('height', heightText);
  // ✅ NOUVEAU : Définir size = 'custom' pour les dimensions exactes
//controller.updateField('size', 'custom');
  return true;
}


Future<void> showParcelSizeSelectorModal(BuildContext context, String currentValue, void Function(String) onSelected) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();

  final List<Map<String, dynamic>> options = [
  {
    'title': 'SIZE S',
    'subtitle': 'Fits in a shoebox (phone, keys, soft toy...)',
    'icon': Icons.inventory_2_outlined,
    'value': 'SIZE S',
  },
  {
    'title': 'SIZE M',
    'subtitle': 'Fits in a cabin suitcase (laptop, wine crate...)',
    'icon': Icons.work_outline,
    'value': 'SIZE M',
  },
  {
    'title': 'Size L',
    'subtitle': 'Fits in 4 cabin suitcases (painting, TV, travel crib...)',
    'icon': Icons.chair_alt_outlined,
    'value': 'SIZE L',
  },
  {
    'title': 'SIZE XL',
    'subtitle': 'Fits in a station wagon or minivan (dresser, armchair...)',
    'icon': Icons.airport_shuttle_outlined,
    'value': 'SIZE XL',
  },
  {
    'title': 'SIZE XXL',
    'subtitle': 'Fits in a small van (sofa, wardrobe, bed...)',
    'icon': Icons.king_bed_outlined,
    'value': 'SIZE XXL',
  },
];

  
  // ✅ UTILISER showAppBottomSheet au lieu de showModalBottomSheet
  await navigationController.showAppBottomSheet<void>(
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    backgroundColor: theme.colorScheme.surface, 
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle du modal
            Container(
              width: 45,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Titre
            Text(
              "Choose a size", 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Options
            ...options.map((option) {
              final bool selected = option['value'] == currentValue;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                ),
                child: ListTile(
                  leading: Icon(option['icon'], color: selected ? theme.colorScheme.primary : null),
                  title: Text(option['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(option['subtitle'], style: const TextStyle(fontSize: 13)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    // ✅ Mettre à jour les valeurs
                    onSelected(option['value']);
                    //selectedSize.value = option['value'];
                    
                    // ✅ Fermer le modal avec Get.back()
                    Get.back();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showImageSourceModal() async {
  // ✅ Vérifier la limite avant d'ouvrir le modal
  //final currentPhotos = controller.currentParcel.value?.photos ?? [];
  final currentPhotos = controller.photosList;
  if (currentPhotos.length >= MAX_PHOTOS) {
  UIMessageExtensions.photoLimitReached(controller.maxPhotos);
    return;
  }

  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final remainingSlots = controller.getRemainingPhotoSlots();
  
  // ✅ UTILISER showAppBottomSheet
  await navigationController.showAppBottomSheet<void>(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: theme.colorScheme.surface, 
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle du modal
            Container(
              width: 45,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Titre
            Text(
              "Add photos ($remainingSlots remaining)", 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Options de photo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                themeButton(
                  context,
                  icon: LucideIcons.image,
                  label: 'Photos',
                  isSelected: isUploadingPhoto.value,
                  onTap: () {
                    Get.back(); // ✅ Fermer le modal d'abord
                    _pickMultipleImages();
                  },
                ),
                themeButton(
                  context,
                  icon: LucideIcons.camera,
                  label: 'Camera',
                  isSelected: isUploadingPhoto.value,
                  onTap: () {
                    Get.back(); // ✅ Fermer le modal d'abord
                    _pickImage(ImageSource.camera);
                  },
                ),
                themeButton(
                  context,
                  icon: LucideIcons.fileInput,
                  label: 'Files',
                  isSelected: isUploadingPhoto.value,
                  onTap: () {
                    Get.back(); // ✅ Fermer le modal d'abord
                    _pickFilesImages();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
Future<void> _pickImage(ImageSource source) async {
  try {
    // ✅ Vérifier la limite avant de prendre la photo
    //final currentPhotos = controller.currentParcel.value?.photos ?? [];
    final currentPhotos = controller.photosList;
    if (currentPhotos.length >= MAX_PHOTOS) {
      UIMessageExtensions.photoLimitReached(controller.maxPhotos);
      return;
    }

    isUploadingPhoto.value = true;
    
    // Vérifier les permissions
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        UIMessageExtensions.cameraPermissionRequired();
        return;
      }
    }
    
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    
    if (image != null) {
      //await _uploadPhoto(image.path);
      await controller.addPhoto(image.path);
    }
  } catch (e) {
    UIMessageManager.error("Failed to pick image: $e");
  } finally {
    isUploadingPhoto.value = false;
  }
}
// ✅ Pour plusieurs photos (galerie)
Future<void> _pickMultipleImages() async {
  try {
    // ✅ Calculer combien de photos on peut encore ajouter
    //final currentPhotos = controller.currentParcel.value?.photos ?? [];
    final currentPhotos = controller.photosList;
    final remainingSlots = MAX_PHOTOS - currentPhotos.length;
    
    if (remainingSlots <= 0) {
    UIMessageExtensions.photoLimitReached(MAX_PHOTOS);
      return;
    }

    isUploadingPhoto.value = true;
    
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    
    if (images.isNotEmpty) {
      // ✅ Limiter au nombre de slots restants
      final limitedImages = images.take(remainingSlots).toList();
      
      for (final image in limitedImages) {
        await controller.addPhoto(image.path);
      }
      
      // ✅ Message informatif adapté
      if (images.length > remainingSlots) {
      UIMessageManager.info("Only the first $remainingSlots photos were added (limit: ${controller.maxPhotos})");
      } else if (limitedImages.isNotEmpty) {
        UIMessageManager.photoUploadSuccess(limitedImages.length);
      }
    }
  } catch (e) {
    UIMessageManager.error("Failed to pick images: $e");
  } finally {
    isUploadingPhoto.value = false;
  }
}

// ✅ NOUVELLE MÉTHODE: Pour sélectionner des images depuis les fichiers
Future<void> _pickFilesImages() async {
  try {
    // ✅ Vérifier la limite avec le contrôleur
    final remainingSlots = controller.getRemainingPhotoSlots();
    
    if (remainingSlots <= 0) {
      UIMessageExtensions.photoLimitReached(controller.maxPhotos);
      return;
    }

    isUploadingPhoto.value = true;
    
    // ✅ Sélectionner des fichiers images
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      // ignore: deprecated_member_use
      allowCompression: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      // ✅ Filtrer uniquement les fichiers avec un chemin valide
      List<PlatformFile> validFiles = result.files
          .where((file) => file.path != null)
          .toList();
      
      if (validFiles.isEmpty) {
        UIMessageManager.error("No valid file selected");
        return;
      }
      
      // ✅ Limiter au nombre de slots restants
      final limitedFiles = validFiles.take(remainingSlots).toList();
      
      // ✅ Valider et traiter chaque fichier
      List<String> successfulUploads = [];
      
      for (final file in limitedFiles) {
        try {
          // Vérifier la taille du fichier (ex: max 10MB)
          if (file.size > 10 * 1024 * 1024) {
            UIMessageExtensions.fileTooLarge(file.name, "10MB");
            continue;
          }
          
          // Vérifier l'extension
          if (!_isValidImageExtension(file.extension?.toLowerCase())) {
            UIMessageExtensions.unsupportedFileFormat(file.name);
            continue;
          }
          //await _uploadPhoto(file.path!);/
          await controller.addPhoto(file.path!);
          successfulUploads.add(file.name);
          
        } catch (e) {
          UIMessageExtensions.uploadFailed(file.name);
        }
      }
      
      // ✅ Messages informatifs
      if (successfulUploads.isNotEmpty) {
      UIMessageManager.success("${successfulUploads.length} file${successfulUploads.length > 1 ? 's' : ''} added");
      }
      
      if (validFiles.length > remainingSlots) {
    UIMessageManager.info("Only the first $remainingSlots files were processed (limit: ${controller.maxPhotos})");
      }
    }
  } catch (e) {
    UIMessageManager.error("File selection failed: $e");
  } finally {
    isUploadingPhoto.value = false;
  }
}

// ✅ MÉTHODE UTILITAIRE: Valider les extensions d'images
bool _isValidImageExtension(String? extension) {
  if (extension == null) return false;
  
  const validExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'svg'
  ];
  
  return validExtensions.contains(extension.toLowerCase());
}
}