import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
//import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';

class ParcelStepArrivee extends StatefulWidget {
  const ParcelStepArrivee({super.key});

  @override
  ParcelStepArriveeState createState() => ParcelStepArriveeState();
}

class ParcelStepArriveeState extends State<ParcelStepArrivee> {
  final controller = Get.find<ParcelsController>();

  // Controllers pour les champs
  late TextEditingController destinationAddressController;
  late TextEditingController recipientNameController;
  late TextEditingController recipientPhoneController;
  late TextEditingController deliveryInstructionsController;


  // ✅ NOUVEAU : Controllers pour dates/heures (cohérent avec parcel_step_depart)
  TextEditingController deliveryStartDateController = TextEditingController();
  TextEditingController deliveryStartTimeController = TextEditingController();
  TextEditingController deliveryEndDateController = TextEditingController();
  TextEditingController deliveryEndTimeController = TextEditingController();
  // États des erreurs
  final RxBool destinationHasError = false.obs;
  final RxBool recipientNameHasError = false.obs;
  final RxBool recipientPhoneHasError = false.obs;
  final RxBool deliveryTimeHasError = false.obs;
  final RxBool handlingHasError = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isCalculatingDistance = false.obs;
  final RxBool useReceiverInfo = false.obs;
    DateTime? _deliveryStartDate;
  TimeOfDay? _deliveryStartTime;
  DateTime? _deliveryEndDate;
  TimeOfDay? _deliveryEndTime;
  // Vitesse de livraison sélectionnée
  final RxString selectedDeliverySpeed = ''.obs;

  // Sélection des dates et heures de livraison


  // Options de livraison
  final RxBool usePickupPoint = false.obs;
  final RxString selectedPickupPointId = ''.obs;

    final RxList<GeocodingResult> addressSuggestions = <GeocodingResult>[].obs;
    final List<Map<String, dynamic>> deliveryHandlingOptions = [
  {
    'title': 'At the foot of the vehicle/before the house door',
    'subtitle': 'The driver drops off or picks up the parcel in front of your home',
    'icon': Icons.directions_car_outlined,
    'value': 'door',
    'fee': 0.0,
    'requiresDetails': false,
  },
  {
    'title': 'In the room of my choice - with 1 person',
    'subtitle': 'The driver helps you transport the parcel to the desired room',
    'icon': Icons.person_outline,
    'value': 'light_assist',
    'fee': 29.0,
    'requiresDetails': true,
  },
  {
    'title': 'In the room of my choice - with 2 people',
    'subtitle': '2 people provide transport to your home',
    'icon': Icons.people_outline,
    'value': 'room',
    'fee': 59.0,
    'requiresDetails': true,
  },
    ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  // ✅ NOUVEAU : Méthodes de formatage (mêmes que parcel_step_depart)
  String _formatDate(DateTime? date) {
    if (date == null) return "Choisir date";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Heure";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  bool _validatePhoneNumber(String phone) {
  // Regex pour valider le format téléphonique
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
  return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
}


 void _initializeForm() {
    final parcel = controller.currentParcel.value;
    
    if (parcel != null) {
      destinationAddressController = TextEditingController(text: parcel.destinationAddress);
      recipientNameController = TextEditingController(text: parcel.recipientName);
      recipientPhoneController = TextEditingController(text: parcel.recipientPhone);
      deliveryInstructionsController = TextEditingController(text: parcel.deliveryDescription);
      
      // Initialiser la vitesse de livraison
      selectedDeliverySpeed.value = parcel.delivery_speed;
      
      // Initialiser les options de point relais
      selectedPickupPointId.value = parcel.delivery_point_id ?? '';
      usePickupPoint.value = parcel.delivery_point_id != null;

          // ✅ NOUVEAU : Détecter si on a déjà des infos destinataire
    if (parcel.recipientName.isNotEmpty || parcel.recipientPhone.isNotEmpty) {
      useReceiverInfo.value = true;
    }
            // Réinitialiser le handling si pas encore sélectionné
    if (parcel.deliveryHandling?['assistanceLevel'] == null || 
        parcel.deliveryHandling?['assistanceLevel'] == '') {
      controller.updateField('deliveryHandling', {
        'assistanceLevel': '', // ✅ Vide par défaut
        'floor': 0,
        'hasElevator': false,
        'accessNotes': '',
        'estimatedFee': 0.0,
      });
    }
      
      // ✅ NOUVEAU : Initialiser les dates avec controllers
      final deliveryStart = parcel.getDeliveryStartTime();
      final deliveryEnd = parcel.getDeliveryEndTime();
      
      if (deliveryStart != null && deliveryEnd != null) {
        _deliveryStartDate = deliveryStart;
        _deliveryStartTime = TimeOfDay.fromDateTime(deliveryStart);
        _deliveryEndDate = deliveryEnd;
        _deliveryEndTime = TimeOfDay.fromDateTime(deliveryEnd);
        
        // Mettre à jour les controllers
 // Mettre à jour les controllers
      deliveryStartDateController = TextEditingController(text: _formatDate(_deliveryStartDate));
      deliveryStartTimeController = TextEditingController(text: _formatTime(_deliveryStartTime));
      deliveryEndDateController = TextEditingController(text: _formatDate(_deliveryEndDate));
      deliveryEndTimeController = TextEditingController(text: _formatTime(_deliveryEndTime));
      } 
    } else {
      destinationAddressController = TextEditingController();
      recipientNameController = TextEditingController();
      recipientPhoneController = TextEditingController();
      deliveryInstructionsController = TextEditingController();
      selectedDeliverySpeed.value = 'standard';
      
      
    }
  }
// ✅ NOUVEAU : Valeurs par défaut pour livraison


  @override
  void dispose() {
    destinationAddressController.dispose();
    recipientNameController.dispose();
    recipientPhoneController.dispose();
    deliveryInstructionsController.dispose();
    
    // ✅ NOUVEAU : Dispose des controllers de dates
    deliveryStartDateController.dispose();
    deliveryStartTimeController.dispose();
    deliveryEndDateController.dispose();
    deliveryEndTimeController.dispose();
    
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
                    sectionTitle(context, "Destination address"),
                    _buildDestinationSection(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Handling details"),
                    const SizedBox(height: 8),
                    _buildHandlingTile(context),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Receiver information"),
                    _buildRecipientInfo(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Delivery speed"),
                    _buildDeliverySpeedSection(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Delivery window"),
                    _buildDeliveryTimeSection(),
                    const SizedBox(height: 24),

                    //sectionTitle(context, "Options de livraison"),
                    //_buildDeliveryOptionsSection(),
                   // const SizedBox(height: 24),

                    sectionTitle(context, "Delivery instructions"),
                    _buildDeliveryInstructionsSection(),
                    const SizedBox(height: 32),

                    MyButton(
                      onTap: () {
                        if (_validateAllFields()) {
                          _saveData();
                          controller.nextStep();
                        }
                      },
                      text: "Next Step",
                      height: 50,
                      width: double.infinity,
                      borderRadius: 30,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
Future<void> showAddressSearchModal({
  required BuildContext context,
  required String initialValue,
  required Function(GeocodingResult) onSelected,
}) async {
  final theme = Theme.of(context);
  final RxList<GeocodingResult> suggestions = <GeocodingResult>[].obs;
  final TextEditingController searchController = TextEditingController(text: initialValue);
  final FocusNode searchFocusNode = FocusNode();

  final navigationController = Get.find<NavigationController>();

await navigationController.showAppBottomSheet<void>(
  isScrollControlled: true,
  backgroundColor: theme.colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
  ),
  child: SafeArea(
    child: Padding(
      padding:  EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85 - 
             MediaQuery.of(context).viewInsets.bottom, // 💡 Jusqu’à 85% de l’écran
        ),
        child: Column(
          children: [
            Container(
              width: 45,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            CustomTextField(
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: "Delivery  address",
              borderRadius: 12,
              borderColor: destinationHasError.value
                ? Colors.red
                : theme.colorScheme.primary.withAlpha(77),
              prefixIcon: const Icon(Icons.search),
               suffixIcon: searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () {
                        searchController.clear();
                        suggestions.clear();
                        _clearAddress();
                      },
                    )
                  : null,
              isTransparent: true,
              onChanged: (query) async {
                if (query.trim().length < 3) {
                  suggestions.clear();
                  return;
                }
                final results = await GeocodingService.searchAddressSuggestions(query);
                suggestions.assignAll(results);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() => suggestions.isEmpty
                  ? const Center(child: Text("No suggestions"))
                  : ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(suggestion.formattedAddress),
                          onTap: () {
                            onSelected(suggestion);
                            Get.back();
                          },
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    ),
  ),
);

}
  Widget _buildDestinationSection() {
    final theme = Theme.of(context);

    return Column(
    children: [
      InkWell(
        onTap: () => showAddressSearchModal(
          context: context,
          initialValue: destinationAddressController.text,
          onSelected: (GeocodingResult result) {
            destinationAddressController.text = result.formattedAddress;
            controller.setDestinationAddress(
              result.formattedAddress,
              result.latitude,
              result.longitude,
            );
          },
        ),
        child: IgnorePointer(
          child: Obx(() => CustomTextField(
            controller: destinationAddressController,
            labelText: 'Delivery address',
            hintText: 'Commencez à taper...',
            keyboardType: TextInputType.streetAddress,
            borderRadius: 10,
            isTransparent: true,
            prefixIcon: const Icon(LucideIcons.mapPin),
            suffixIcon: destinationAddressController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => _clearAddress(),
                    tooltip: 'Supprimer l\'adresse',
                  )
                : null,
            borderColor: destinationHasError.value
                ? Colors.red
                : theme.colorScheme.primary.withAlpha(77),
          )),
        ),
      ),
    ],
  );
  }
void _clearAddress() {
  // Vider le champ texte
  destinationAddressController.clear();
  
  // Réinitialiser l'adresse dans le contrôleur
  controller.setOriginAddress('', 0.0, 0.0);
  
  // Réinitialiser l'erreur d'adresse
  destinationHasError.value = false;
  

}
Widget _buildRecipientInfo() {
  final theme = Theme.of(context);

  return Column(
    children: [
      // ✅ NOUVEAU : Switch pour activer/désactiver les infos destinataire
      Obx(() => Row(
        children: [
          Text(
            "I know the receiver's information", 
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
          ),
          const Spacer(),
          Switch(
            value: useReceiverInfo.value, 
            onChanged: (value) {
              useReceiverInfo.value = value;
              
              // ✅ Si on désactive, vider les champs et reset les erreurs
              if (!value) {
                recipientNameController.clear();
                recipientPhoneController.clear();
                recipientNameHasError.value = false;
                recipientPhoneHasError.value = false;
                
                // ✅ Mettre à jour le modèle
                controller.updateField('recipientName', '');
                controller.updateField('recipientPhone', '');
              }
            }
          ),
        ],
      )),
      const SizedBox(height: 16),

      // ✅ NOUVEAU : Afficher les champs seulement si le switch est activé
      Obx(() => useReceiverInfo.value ? Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => CustomTextField(
                  controller: recipientNameController,
                  labelText: 'Nom du destinataire',
                  hintText: 'Nom complet',
                  borderRadius: 10,
                  isTransparent: true,
                  prefixIcon: const Icon(LucideIcons.userCheck),
                  borderColor: recipientNameHasError.value ? Colors.red : null,
                  onChanged: (_) => recipientNameHasError.value = false,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => CustomTextField(
                  controller: recipientPhoneController,
                  labelText: 'Téléphone destinataire',
                  hintText: '+1 (555) 123-4567',
                  keyboardType: TextInputType.phone,
                  borderRadius: 10,
                  isTransparent: true,
                  prefixIcon: const Icon(LucideIcons.phone),
                  borderColor: recipientPhoneHasError.value ? Colors.red : null,
                  onChanged: (_) => recipientPhoneHasError.value = false,
                )),
              ),
            ],
          ),
        ],
      ) : 
      // ✅ Message quand le switch est désactivé
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.userX, 
              size: 32, 
              color: theme.colorScheme.onSurfaceVariant
            ),
            const SizedBox(height: 8),
            Text(
              "Receiver information not specified",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "The carrier will contact you for delivery details",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )),
    ],
  );
}

  Widget _buildDeliverySpeedSection() {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> speedOptions = [
   
      {
        'value': 'standard',
        'title': 'Standard',
        'subtitle': 'Delivery according to driver availability',
        'fee': 0.0,
        'icon': LucideIcons.truck,
        'color': Colors.blue,
      },
      {
        'value': 'urgent',
        'title': 'Urgent',
        'subtitle': 'Priority delivery',
        'fee': 8.99 ,
        'icon': LucideIcons.zap,
        'color': Colors.red,
      },
    ];

    return Column(
      children: speedOptions.map((option) {
        return Obx(() {
          final isSelected = selectedDeliverySpeed.value == option['value'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => selectedDeliverySpeed.value = option['value'],
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? option['color'] : theme.colorScheme.outline.withAlpha(77),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? option['color'].withAlpha(25) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'], 
                      color: isSelected ? option['color'] : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? option['color'] : null,
                            ),
                          ),
                          Text(
                            option['subtitle'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected ? option['color'] : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (option['fee'] != null)
                            Text(
                              "+${option['fee'].toStringAsFixed(2)} CAD",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:theme.colorScheme.primary ,
                                fontWeight: FontWeight.bold,
                              ),
                              
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: option['color'],
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildDeliveryTimeSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: deliveryTimeHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeSelector(
                      context: context,
                      label: "Start date",
                      icon: LucideIcons.calendar,
                      dateController: deliveryStartDateController, 
                      timeController: deliveryStartTimeController,
                      onDateTap: () => _selectDeliveryDate(context, isStart: true),
                      onTimeTap: () => _selectDeliveryTime(context, isStart: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeSelector(
                      context: context,
                      label: "Date de fin",
                      icon: LucideIcons.calendar,
                      dateController: deliveryEndDateController,
                      timeController: deliveryEndTimeController,
                      onDateTap: () => _selectDeliveryDate(context, isStart: false),
                      onTimeTap: () => _selectDeliveryTime(context, isStart: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

 Widget _buildDateTimeSelector({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TextEditingController dateController,  // ✅ Controller
    required TextEditingController timeController,  // ✅ Controller
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onDateTap,
                child: IgnorePointer(  // ✅ Empêcher l'édition directe
                  child: CustomTextField(
                    controller: dateController,  // ✅ Controller
                    labelText: '',
                    borderRadius: 8,
                    isTransparent: true,
                    prefixIcon: Icon(icon, size: 16),
                    borderColor: deliveryTimeHasError.value
                      ? Colors.red
                      : theme.colorScheme.outline.withAlpha(77),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onTimeTap,
                child: IgnorePointer(  // ✅ Empêcher l'édition directe
                  child: CustomTextField(
                    controller: timeController,  // ✅ Controller
                    labelText: '',
                    borderRadius: 8,
                    isTransparent: true,
                    prefixIcon: const Icon(LucideIcons.clock, size: 16),
                    borderColor: deliveryTimeHasError.value
                      ? Colors.red
                      : theme.colorScheme.outline.withAlpha(77),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /*Widget _buildDeliveryOptionsSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Obx(() => _buildOptionTile(
          context: context,
          title: "Point relais",
          subtitle: "Livrer dans un point relais plutôt qu'à domicile",
          icon: LucideIcons.package,
          value: usePickupPoint.value,
          onChanged: (value) {
            usePickupPoint.value = value;
            if (!value) {
              selectedPickupPointId.value = '';
            }
          },
        )),
        const SizedBox(height: 16),
        Obx(() {
          if (!usePickupPoint.value) return const SizedBox.shrink();
          
          return buildButtonTextLogo(
            context,
            label: selectedPickupPointId.value.isNotEmpty 
                ? "Point relais sélectionné" 
                : "Choisir un point relais",
            icon: LucideIcons.mapPin,
            isFilled: false,
            alignIconStart: true,
            borderRadius: 10,
            height: 50,
            endIcon: Icons.expand_more,
            bordercolerput: theme.colorScheme.primary.withAlpha(77),
            onTap: () async {
             
              _showPickupPointSelector(context);
            },
            outlined: true,
          );
        }),
      ],
    );
  }*/

 /* Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }*/

  Widget _buildDeliveryInstructionsSection() {
    final theme = Theme.of(context);

    return CustomTextField(
      controller: deliveryInstructionsController,
      labelText: 'Delivery instructions',
      hintText: 'Ex: Leave at the door, call when you arrive...',
      maxLines: 4,
      borderRadius: 10,
      isTransparent: true,
      borderColor: theme.colorScheme.primary.withAlpha(77),
    );
  }

 // ✅ NOUVEAU : Méthodes de sélection avec controllers
  Future<void> _selectDeliveryDate(BuildContext context, {required bool isStart}) async {
    final initialDate = (isStart ? _deliveryStartDate : _deliveryEndDate) ?? 
                      DateTime.now().add(const Duration(days: 1));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (isStart) {
        _deliveryStartDate = pickedDate;
        deliveryStartDateController.text = _formatDate(_deliveryStartDate);  // ✅ Mise à jour controller
      } else {
        _deliveryEndDate = pickedDate;
        deliveryEndDateController.text = _formatDate(_deliveryEndDate);      // ✅ Mise à jour controller
      }
      
      deliveryTimeHasError.value = false;
      await _updateDeliveryWindow();
    }
  }

  // ✅ NOUVEAU : Mise à jour du modèle
  Future<void> _updateDeliveryWindow() async {
    try {
      if (_deliveryStartDate == null || _deliveryStartTime == null ||
          _deliveryEndDate == null || _deliveryEndTime == null) {
        print("⚠️ Valeurs de delivery window incomplètes");
        return;
      }
      
      final startDateTime = DateTime(
        _deliveryStartDate!.year,
        _deliveryStartDate!.month,
        _deliveryStartDate!.day,
        _deliveryStartTime!.hour,
        _deliveryStartTime!.minute,
      );
      
      final endDateTime = DateTime(
        _deliveryEndDate!.year,
        _deliveryEndDate!.month,
        _deliveryEndDate!.day,
        _deliveryEndTime!.hour,
        _deliveryEndTime!.minute,
      );
      
      await controller.setDeliveryWindow(startDateTime, endDateTime);
      print("✅ Delivery window sauvegardée: $startDateTime → $endDateTime");
      
    } catch (e) {
      print("❌ Erreur lors de la sauvegarde delivery window: $e");
      deliveryTimeHasError.value = true;
    }
  }

 Future<void> _selectDeliveryTime(BuildContext context, {required bool isStart}) async {
    final initialTime = (isStart ? _deliveryStartTime : _deliveryEndTime) ?? 
                      const TimeOfDay(hour: 14, minute: 0);
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      if (isStart) {
        _deliveryStartTime = pickedTime;
        deliveryStartTimeController.text = _formatTime(_deliveryStartTime);  // ✅ Mise à jour controller
      } else {
        _deliveryEndTime = pickedTime;
        deliveryEndTimeController.text = _formatTime(_deliveryEndTime);      // ✅ Mise à jour controller
      }
      
      deliveryTimeHasError.value = false;
      await _updateDeliveryWindow();
    }
  }

 /* void _showPickupPointSelector(BuildContext context) {
    // Mock de points relais pour démonstration
    final mockPickupPoints = [
      {'id': 'point1', 'name': 'Pharmaprix - Centre-ville', 'address': '123 Rue Sainte-Catherine'},
      {'id': 'point2', 'name': 'Couche-Tard - Plateau', 'address': '456 Avenue du Mont-Royal'},
      {'id': 'point3', 'name': 'Dépanneur du Coin', 'address': '789 Boulevard Saint-Laurent'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  "Choisir un point relais",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...mockPickupPoints.map((point) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(LucideIcons.mapPin),
                      title: Text(point['name']!),
                      subtitle: Text(point['address']!),
                      trailing: selectedPickupPointId.value == point['id'] 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        selectedPickupPointId.value = point['id']!;
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }*/

bool _validateAllFields() {
  bool isValid = true;

  // Validation adresse destination
  if (destinationAddressController.text.trim().isEmpty) {
    destinationHasError.value = true;
    isValid = false;
  }

  // ✅ NOUVEAU : Validation des infos destinataire seulement si le switch est activé
  if (useReceiverInfo.value) {
    // Validation nom destinataire
    if (recipientNameController.text.trim().isEmpty) {
      recipientNameHasError.value = true;
      isValid = false;
    }

    // ✅ CORRECTION : Validation téléphone avec méthode
    if (recipientPhoneController.text.trim().isEmpty || 
        !_validatePhoneNumber(recipientPhoneController.text.trim())) {
      recipientPhoneHasError.value = true;
      isValid = false;
    }
  }
    final parcel = controller.currentParcel.value;
  final handlingLevel = parcel?.deliveryHandling?['assistanceLevel'] ?? '';
  if (handlingLevel.isEmpty) {
    handlingHasError.value = true;
    isValid = false;
  }

  // ✅ NOUVEAU : Validation avec variables internes
  if (_deliveryStartDate == null || _deliveryStartTime == null ||
      _deliveryEndDate == null || _deliveryEndTime == null) {
    deliveryTimeHasError.value = true;
    isValid = false;
  } else {
    // Validation cohérence des dates
    final startDateTime = DateTime(
      _deliveryStartDate!.year,
      _deliveryStartDate!.month,
      _deliveryStartDate!.day,
      _deliveryStartTime!.hour,
      _deliveryStartTime!.minute,
    );
    
    final endDateTime = DateTime(
      _deliveryEndDate!.year,
      _deliveryEndDate!.month,
      _deliveryEndDate!.day,
      _deliveryEndTime!.hour,
      _deliveryEndTime!.minute,
    );

    if (startDateTime.isAfter(endDateTime)) {
      deliveryTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Date error",
        "Start date must be earlier than end date",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (startDateTime.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      deliveryTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Date error",
        "Delivery date must be in the future",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (endDateTime.difference(startDateTime).inMinutes < 30) {
      deliveryTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Date error",
        "The delivery window must be at least 30 minutes long",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }    
  }

  if (!isValid) {
    // ✅ NOUVEAU : Message d'erreur adapté selon le contexte
    String errorMessage = "Please fill in all required fields";
    
    if (useReceiverInfo.value && (recipientNameHasError.value || recipientPhoneHasError.value)) {
      errorMessage = "Please complete the receiver information or disable the switch";
    } else if (deliveryTimeHasError.value) {
      errorMessage = "Please check the delivery time window";
    } else if (destinationHasError.value) {
      errorMessage = "Please specify a delivery address";
    }
    
    Get.snackbar(
      "Missing fields",
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  return isValid;
}

void _saveData() async {
  try {
    //save the Price(),
    await controller.calculateEstimatePrice();
    // ✅ 1. SAUVEGARDER LES INFORMATIONS DESTINATAIRE (seulement si switch activé)
    if (useReceiverInfo.value) {
      await controller.updateField('recipientName', recipientNameController.text.trim());
      await controller.updateField('recipientPhone', recipientPhoneController.text.trim());
      print("✅ Informations destinataire sauvegardées");
    } else {
      // ✅ S'assurer que les champs sont vides si le switch est désactivé
      await controller.updateField('recipientName', '');
      await controller.updateField('recipientPhone', '');
      print("✅ Informations destinataire effacées (switch désactivé)");
    }
    
    // ✅ 2. GÉOCODAGE ET SAUVEGARDE DE L'ADRESSE
    final geo = await GeocodingService.getCoordinatesFromAddress(destinationAddressController.text.trim());
    print("Géocodage de l'adresse : ${destinationAddressController.text.trim()}");
    print("Adresse géocodée : ${geo?.formattedAddress}, ${geo?.latitude}, ${geo?.longitude}");

    if (geo != null) {
      await controller.setDestinationAddress(
        geo.formattedAddress,
        geo.latitude,
        geo.longitude,
      );
      print("✅ Adresse de destination sauvegardée");
    } else {
      Get.snackbar(
        "Adresse introuvable",
        "Impossible de localiser cette adresse. Vérifiez votre saisie.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // Arrêter l'exécution si l'adresse est invalide
    }
    
    // ✅ 3. SAUVEGARDER LA VITESSE DE LIVRAISON
    await controller.updateField('delivery_speed', selectedDeliverySpeed.value);
    print("✅ Vitesse de livraison sauvegardée: ${selectedDeliverySpeed.value}");
    
    // ✅ 4. SAUVEGARDER LES OPTIONS DE POINT RELAIS
    if (usePickupPoint.value && selectedPickupPointId.value.isNotEmpty) {
      await controller.updateField('delivery_point_id', selectedPickupPointId.value);
      print("✅ Point relais sauvegardé: ${selectedPickupPointId.value}");
    } else {
      // ✅ S'assurer que le point relais est vide si non utilisé
      await controller.updateField('delivery_point_id', null);
      print("✅ Point relais désactivé");
    }
    
    // ✅ 5. SAUVEGARDER LES INSTRUCTIONS DE LIVRAISON
    await controller.updateField('deliveryDescription', deliveryInstructionsController.text.trim());
    print("✅ Instructions de livraison sauvegardées");
    
    // ✅ 6. FENÊTRE DE LIVRAISON (vérification finale)
    if (_deliveryStartDate != null && _deliveryStartTime != null &&
        _deliveryEndDate != null && _deliveryEndTime != null) {
      await _updateDeliveryWindow();
      print("✅ Fenêtre de livraison sauvegardée");
    }
    
    // ✅ 7. AFFICHER UN RÉSUMÉ DES DONNÉES SAUVEGARDÉES
    print("📋 RÉSUMÉ SAUVEGARDE:");
    print("   - Adresse: ${geo.formattedAddress}");
    print("   - Destinataire: ${useReceiverInfo.value ? recipientNameController.text.trim() : 'Non spécifié'}");
    print("   - Téléphone: ${useReceiverInfo.value ? recipientPhoneController.text.trim() : 'Non spécifié'}");
    print("   - Vitesse: ${selectedDeliverySpeed.value}");
    print("   - Point relais: ${usePickupPoint.value ? selectedPickupPointId.value : 'Non utilisé'}");
    print("   - Instructions: ${deliveryInstructionsController.text.trim()}");
    
    print("✅ Toutes les données d'arrivée ont été sauvegardées avec succès");
    
  } catch (e) {
    // ✅ 8. GESTION D'ERREURS DÉTAILLÉE
    print("❌ Erreur lors de la sauvegarde : $e");
    
    // ✅ Message d'erreur spécifique selon le type d'erreur
    String errorTitle = "Erreur de sauvegarde";
    String errorMessage = "Une erreur s'est produite lors de la sauvegarde. Veuillez réessayer.";
    
    if (e.toString().contains('network') || e.toString().contains('connection')) {
      errorTitle = "Problème de connexion";
      errorMessage = "Vérifiez votre connexion internet et réessayez.";
    } else if (e.toString().contains('geocoding') || e.toString().contains('address')) {
      errorTitle = "Erreur d'adresse";
      errorMessage = "Impossible de valider l'adresse. Vérifiez la saisie.";
    } else if (e.toString().contains('permission')) {
      errorTitle = "Permissions insuffisantes";
      errorMessage = "Permissions requises pour sauvegarder les données.";
    }
    
    Get.snackbar(
      errorTitle,
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
Widget _buildHandlingTile(BuildContext context) {
  final theme = Theme.of(context);
  
  return Obx(() {
    final parcel = controller.currentParcel.value;
    final current = parcel?.deliveryHandling?['assistanceLevel'] ?? '';
    final floor = parcel?.deliveryHandling?['floor'] ?? 0;
    final hasElevator = parcel?.deliveryHandling?['hasElevator'] ?? false;
    final fee = parcel?.deliveryHandling?['estimatedFee'] ?? 0.0;
    
    // ✅ NOUVEAU : Gestion de l'état vide
    final bool isEmpty = current.isEmpty;
    
    // Trouver l'option correspondante ou définir un état vide
    Map<String, dynamic> currentOption;
    if (isEmpty) {
      currentOption = {
        'title': 'Select handling assistance',
        'subtitle': 'Choose how you want the parcel to be handled',
        'icon': Icons.touch_app_outlined,
        'value': '',
        'fee': 0.0,
        'requiresDetails': false,
      };
    } else {
      currentOption = deliveryHandlingOptions.firstWhere(
        (e) => e['value'] == current,
        orElse: () => deliveryHandlingOptions[0],
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: handlingHasError.value 
            ? Colors.red 
            : theme.colorScheme.outline.withAlpha(77),
          width: handlingHasError.value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ✅ SECTION PRINCIPALE - Sélection du type de manutention
          InkWell(
            onTap: () => _showHandlingSelectionModal(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ✅ MODIFICATION : Gestion des couleurs selon l'état
                  Icon(
                    currentOption['icon'], 
                    color: isEmpty 
                      ? (handlingHasError.value ? Colors.red : theme.colorScheme.onSurfaceVariant)
                      : theme.colorScheme.primary
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ MODIFICATION : Gestion des couleurs pour le titre
                        Text(
                          currentOption['title'],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isEmpty 
                              ? (handlingHasError.value ? Colors.red : theme.colorScheme.onSurfaceVariant)
                              : null,
                          ),
                        ),
                        // ✅ AJOUT : Affichage du sous-titre pour l'état vide
                        if (isEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            currentOption['subtitle'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: handlingHasError.value 
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (fee > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            "+${fee.toStringAsFixed(0)} CAD",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ MODIFICATION : Couleur de la flèche selon l'état d'erreur
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: handlingHasError.value 
                      ? Colors.red 
                      : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          // ✅ SECTION DÉTAILS - Affichage conditionnel des champs étage et ascenseur
          if (currentOption['requiresDetails'] == true && !isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ✅ CHAMP ÉTAGE
                  Expanded(
                    child: InkWell(
                      onTap: () => _showFloorSelectionModal(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Floor",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.building,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    floor == 0 
                                        ? "Ground floor" 
                                        : "$floor${_getOrdinalSuffix(floor)} floor",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // ✅ CHAMP ASCENSEUR
                  Expanded(
                    child: InkWell(
                      onTap: () => _showElevatorSelectionModal(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Elevator",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasElevator ? LucideIcons.check : LucideIcons.x,
                                  size: 16,
                                  color: hasElevator 
                                      ? Colors.green 
                                      : theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasElevator ? "Available" : "Not available",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: hasElevator 
                                          ? Colors.green 
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  });
}
Future<void> _showHandlingSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final parcel = controller.currentParcel.value;
  final current = parcel?.deliveryHandling?['assistanceLevel'] ?? '';

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
              "Choose handling assistance",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Options de handling
            ...deliveryHandlingOptions.map((option) {
              final bool selected = current == option['value'];
              final double fee = option['fee'] ?? 0.0;

              return Container(
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
                  leading: Icon(
                    option['icon'], 
                    color: selected ? theme.colorScheme.primary : null
                  ),
                  title: Text(
                    option['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['subtitle'],
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (fee > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          "+${fee.toStringAsFixed(0)}CAD",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: selected 
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  onTap: () async {
                    try {
                        // ✅ NOUVEAU : Reset l'erreur dès qu'on sélectionne
                      handlingHasError.value = false;
                      // ✅ Mettre à jour le handling
                      final updated = {
                        'assistanceLevel': option['value'],
                        'floor': 0,
                        'hasElevator': false,
                        'accessNotes': '',
                        'estimatedFee': fee,
                      };

                      await controller.updateField('deliveryHandling', updated);
                      
                      // ✅ Fermer le modal
                      Get.back();
                      
                      // ✅ Petit délai pour laisser le modal se fermer
                      await Future.delayed(const Duration(milliseconds: 300));


                    } catch (e) {
                      print("Error updating handling: $e");
                    }
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
String _getOrdinalSuffix(int number) {
  if (number >= 11 && number <= 13) {
    return 'th';
  }
  switch (number % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}
Future<void> _showFloorSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final parcel = controller.currentParcel.value;
  
  int currentFloor = parcel?.deliveryHandling?['floor'] ?? 0;
  final RxInt selectedFloor = currentFloor.obs;

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
              "Floor selection",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Sélection d'étage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Delivery floor",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                  ),
                  const SizedBox(height: 12),
                  Obx(() => DropdownButton<int>(
                    value: selectedFloor.value,
                    isExpanded: true,
                    underline: Container(),
                    items: List.generate(20, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(
                          index == 0 ? "Ground floor" : "$index${_getOrdinalSuffix(index)} floor"
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        selectedFloor.value = value;
                      }
                    },
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de validation
            SizedBox(
              width: double.infinity,
              child: MyButton(
                onTap: () async {
                  try {
                    // Mettre à jour le handling avec la nouvelle valeur
                    final currentHandling = Map<String, dynamic>.from(parcel!.deliveryHandling ?? {});
                    currentHandling['floor'] = selectedFloor.value;
                    
                    await controller.updateField('deliveryHandling', currentHandling);
                    
                    Get.back();
                    
                    Get.snackbar(
                      "Update",
                      "Successfully saved floor",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      "Erreur",
                      "Impossible de sauvegarder l'étage",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                text: "Sauvegarder",
                height: 50,
                borderRadius: 25,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Future<void> _showElevatorSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final parcel = controller.currentParcel.value;
  
  bool currentElevator = parcel?.deliveryHandling?['hasElevator'] ?? false;
  final RxBool hasElevator = currentElevator.obs;

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
              "Elevator availability",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Options ascenseur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Option OUI
                  Obx(() => ListTile(
                    leading: Icon(
                      LucideIcons.check,
                      color: hasElevator.value ? Colors.green : theme.colorScheme.outline,
                    ),
                    title: const Text("Elevator available"),
                    subtitle: const Text("Easy access to floors"),
                    trailing: Radio<bool>(
                      value: true,
                      groupValue: hasElevator.value,
                      onChanged: (value) => hasElevator.value = value!,
                    ),
                    onTap: () => hasElevator.value = true,
                  )),
                  
                  const Divider(),
                  
                  // Option NON
                  Obx(() => ListTile(
                    leading: Icon(
                      LucideIcons.x,
                      color: !hasElevator.value ? theme.colorScheme.error : theme.colorScheme.outline,
                    ),
                    title: const Text("No elevator"),
                    subtitle: const Text("Access by stairs only"),
                    trailing: Radio<bool>(
                      value: false,
                      groupValue: hasElevator.value,
                      onChanged: (value) => hasElevator.value = value!,
                    ),
                    onTap: () => hasElevator.value = false,
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de validation
            SizedBox(
              width: double.infinity,
              child: MyButton(
                onTap: () async {
                  try {
                    // Mettre à jour le handling avec la nouvelle valeur
                    final currentHandling = Map<String, dynamic>.from(parcel!.deliveryHandling ?? {});
                    currentHandling['hasElevator'] = hasElevator.value;
                    
                    await controller.updateField('deliveryHandling', currentHandling);
                    
                    Get.back();
                    
                    Get.snackbar(
                      "update",
                      "Successfully saved elevator preference",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      "Error",
                      "Failed to save elevator preference",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                text: "save",
                height: 50,
                borderRadius: 25,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  }
