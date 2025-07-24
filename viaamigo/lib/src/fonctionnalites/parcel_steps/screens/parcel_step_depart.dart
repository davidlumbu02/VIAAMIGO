// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

class ParcelStepDepart extends StatefulWidget {
  const ParcelStepDepart({super.key});

  @override
  ParcelStepDepartState createState() => ParcelStepDepartState();
}

class ParcelStepDepartState extends State<ParcelStepDepart> {
  final controller = Get.find<ParcelsController>();

  // Controllers pour les champs
  late TextEditingController addressController;
  late TextEditingController instructionsController;
  late TextEditingController senderNameController;
  late TextEditingController senderPhoneController;

  // ✅ CORRECTION : Initialiser directement au lieu de late
  TextEditingController startDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();

  // États des erreurs
  final RxBool addressHasError = false.obs;
  final RxBool senderNameHasError = false.obs;
  final RxBool senderPhoneHasError = false.obs;
  final RxBool pickupTimeHasError = false.obs;
  final RxBool handlingHasError = false.obs; // ✅ NOUVEAU : Erreur handling

  // Options de flexibilité
  final RxBool flexibleDays = false.obs;
  final RxBool advancedPickupAllowed = false.obs;

  // Sélection des dates et heures
 /* final Rx<DateTime?> pickupStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> pickupEndDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> pickupStartTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> pickupEndTime = Rx<TimeOfDay?>(null);

*/
  // Variables internes pour stocker les vraies valeurs
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  final RxList<GeocodingResult> addressSuggestions = <GeocodingResult>[].obs;
final List<Map<String, dynamic>> pickupHandlingOptions = [
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

// ✅ CORRECTION COMPLÈTE :
// ✅ CORRECTION : Meilleure synchronisation avec le modèle
void _initializeForm() {
  final parcel = controller.currentParcel.value;
  
  if (parcel != null) {
    addressController = TextEditingController(text: parcel.originAddress);
    instructionsController = TextEditingController(text: parcel.pickupDescription);
    senderNameController = TextEditingController(text: parcel.senderName);
    senderPhoneController = TextEditingController(text: parcel.senderPhone ?? '');
    

        // Réinitialiser le handling si pas encore sélectionné
    if (parcel.pickupHandling?['assistanceLevel'] == null || 
        parcel.pickupHandling?['assistanceLevel'] == '') {
      controller.updateField('pickupHandling', {
        'assistanceLevel': '', // ✅ Vide par défaut
        'floor': 0,
        'hasElevator': false,
        'accessNotes': '',
        'estimatedFee': 0.0,
      });
    }
    
    // ✅ CORRECTION : Synchronisation améliorée des dates
    final pickupStart = parcel.getPickupStartTime();
    final pickupEnd = parcel.getPickupEndTime();
    
    if (pickupStart != null && pickupEnd != null) {
      _startDate = pickupStart;
      _startTime = TimeOfDay.fromDateTime(pickupStart);
      _endDate = pickupEnd;
      _endTime = TimeOfDay.fromDateTime(pickupEnd);
      
      // Initialiser les controllers avec les valeurs formatées
      startDateController = TextEditingController(text: _formatDate(_startDate));
      startTimeController = TextEditingController(text: _formatTime(_startTime));
      endDateController = TextEditingController(text: _formatDate(_endDate));
      endTimeController = TextEditingController(text: _formatTime(_endTime));
    } //else {
      //_setDefaultPickupTimes();
   // }
  } else {
    // Nouveau colis
    addressController = TextEditingController();
    instructionsController = TextEditingController();
    senderNameController = TextEditingController();
    senderPhoneController = TextEditingController();
    
   
  }
}

// ✅ NOUVEAU : Méthodes de formatage
String _formatDate(DateTime? date) {
  if (date == null) return "Choisir date";
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return "Heure";
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}

  @override
  void dispose() {
    addressController.dispose();
    instructionsController.dispose();
    senderNameController.dispose();
    senderPhoneController.dispose();

  // ✅ NOUVEAU : Dispose des controllers de dates
  startDateController.dispose();
  startTimeController.dispose();
  endDateController.dispose();
  endTimeController.dispose();
  
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
          //_buildHeader(context),
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
                    sectionTitle(context, "Sender information"),
                    const SizedBox(height: 16),
                    _buildSenderInfo(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Departure address"),
                    _buildAddressSection(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Handling details"),
                    const SizedBox(height: 8),
                    _buildHandlingTile(context),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Pick-up window"),
                    _buildPickupTimeSection(),
                    const SizedBox(height: 24),

                    sectionTitle(context, "Special collection instructions "),
                    _buildInstructionsSection(),
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



  Widget _buildSenderInfo() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => CustomTextField(
                controller: senderNameController,
                labelText: 'Full name',
                hintText: 'sender name ',
                borderRadius: 10,
                isTransparent: true,
                prefixIcon: const Icon(LucideIcons.user),
                borderColor:  senderNameHasError.value  // ✅ CORRIGÉ
                  ? Colors.red
                  : theme.colorScheme.primary.withAlpha(77),
                onChanged: (_) => senderNameHasError.value = false,
              )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(() => CustomTextField(
                controller: senderPhoneController,
                labelText: 'Phone number',
                hintText: '(555) 123-4567',
                keyboardType: TextInputType.phone,
                borderRadius: 10,
                
                isTransparent: true,
                prefixIcon: const Icon(LucideIcons.phone),
                borderColor: senderPhoneHasError.value  // ✅ CORRIGÉ
                  ? Colors.red
                  : theme.colorScheme.primary.withAlpha(77),
                onChanged: (_) => senderPhoneHasError.value = false,
              )),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildAddressSection() {
  final theme = Theme.of(context);

  return Column(
    children: [
      InkWell(
        onTap: () => showAddressSearchModal(
          context: context,
          initialValue: addressController.text,
          onSelected: (GeocodingResult result) {
            addressController.text = result.formattedAddress;
            controller.setOriginAddress(
              result.formattedAddress,
              result.latitude,
              result.longitude,
            );
          },
        ),
        child: IgnorePointer(
          child: Obx(() => CustomTextField(
            controller: addressController,
            labelText: 'Pick-up address',
            hintText: '',
            keyboardType: TextInputType.streetAddress,
            borderRadius: 10,
            isTransparent: true,
            prefixIcon: const Icon(LucideIcons.mapPin),
            // ✅ NOUVEAU : Ajout du suffixIcon conditionnel
            suffixIcon: addressController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => _clearAddress(),
                    tooltip: 'Supprimer l\'adresse',
                  )
                : null,
            borderColor: addressHasError.value
                ? Colors.red
                : theme.colorScheme.primary.withAlpha(77),
          )),
        ),
      ),
    ],
  );
}

// ✅ NOUVELLE MÉTHODE : Supprimer l'adresse
void _clearAddress() {
  // Vider le champ texte
  addressController.clear();
  
  // Réinitialiser l'adresse dans le contrôleur
  controller.setOriginAddress('', 0.0, 0.0);
  
  // Réinitialiser l'erreur d'adresse
  addressHasError.value = false;
  

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
  enableDrag:true,
  child: SafeArea(
    child: Padding(
      padding:  EdgeInsets.fromLTRB(20,16,20,20 + MediaQuery.of(context).viewInsets.bottom),
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
              hintText: "Pick-up address",
              borderRadius: 12,
              borderColor: addressHasError.value
                ? Colors.red
                : theme.colorScheme.primary.withAlpha(77),
              prefixIcon: const Icon(Icons.search),
              // ✅ NOUVEAU : Bouton X dans le modal aussi
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

Widget _buildPickupTimeSection() {
  final theme = Theme.of(context);

  return Column(  // ✅ Plus besoin d'Obx() !
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: pickupTimeHasError.value 
              ? Colors.red 
              : theme.colorScheme.primary.withAlpha(77)
          ),
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
                    dateController: startDateController,  // ✅ Controller
                    timeController: startTimeController,  // ✅ Controller
                    onDateTap: () => _selectDate(context, isStart: true),
                    onTimeTap: () => _selectTime(context, isStart: true),
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
                    label: "End date",
                    icon: LucideIcons.calendar,
                    dateController: endDateController,    // ✅ Controller
                    timeController: endTimeController,    // ✅ Controller
                    onDateTap: () => _selectDate(context, isStart: false),
                    onTimeTap: () => _selectTime(context, isStart: false),
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

// ✅ CORRECTION : Améliorer l'affichage des dates// ✅ CORRECTION : Nouvelle signature avec controllers
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
                  borderColor: pickupTimeHasError.value
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
                  borderColor: pickupTimeHasError.value
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
  Widget _buildInstructionsSection() {
    final theme = Theme.of(context);

    return CustomTextField(
      controller: instructionsController,
      labelText: 'Pick-up instructions',
      hintText: 'Ex: Ringing the intercom, asking for the concierge...',
      maxLines: 4,
      borderRadius: 10,
      isTransparent: true,
      borderColor: theme.colorScheme.primary.withAlpha(77),
    );
  }

// ✅ CORRECTION : Forcer le rebuild avec setState()
Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
  final initialDate = (isStart ? _startDate : _endDate) ?? 
    DateTime.now();
  
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  if (pickedDate != null) {
    if (isStart) {
      _startDate = pickedDate;
      startDateController.text = _formatDate(_startDate);  // ✅ Mise à jour controller
    } else {
      _endDate = pickedDate;
      endDateController.text = _formatDate(_endDate);      // ✅ Mise à jour controller
    }
    
    pickupTimeHasError.value = false;
    await _updatePickupWindow();
  }
}


Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
  final initialTime = (isStart ? _startTime : _endTime) ?? 
    const TimeOfDay(hour: 9, minute: 0);
  
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );

  if (pickedTime != null) {
    if (isStart) {
      _startTime = pickedTime;
      startTimeController.text = _formatTime(_startTime);  // ✅ Mise à jour controller
    } else {
      _endTime = pickedTime;
      endTimeController.text = _formatTime(_endTime);      // ✅ Mise à jour controller
    }
    
    pickupTimeHasError.value = false;
    await _updatePickupWindow();
  }
}
  // ✅ NOUVELLE MÉTHODE : Mise à jour du modèle
// ✅ CORRECTION : Gestion d'erreur et validation
// ✅ CORRECTION : Validation plus précise avec debug
// ✅ CORRECTION : Utiliser les variables internes
Future<void> _updatePickupWindow() async {
  try {
    if (_startDate == null || _startTime == null ||
        _endDate == null || _endTime == null) {
      print("⚠️ Valeurs de pickup window incomplètes");
      return;
    }
    
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    
    final now = DateTime.now();
    
    print("🔍 DEBUG DATES:");
    print("   Now: $now");
    print("   Start: $startDateTime");
    print("   End: $endDateTime");
    
    if (startDateTime.isBefore(now.subtract(const Duration(minutes: 0)))) {
      print("❌ Date de début dans le passé: $startDateTime vs $now");
      pickupTimeHasError.value = true;
      return;
    }
    
    if (startDateTime.isAfter(endDateTime)) {
      print("❌ Date de début après date de fin");
      pickupTimeHasError.value = true;
      return;
    }
    
    await controller.setPickupWindow(startDateTime, endDateTime);
    pickupTimeHasError.value = false;
    
    print("✅ Pickup window sauvegardée: $startDateTime → $endDateTime");
    
  } catch (e) {
    print("❌ Erreur lors de la sauvegarde pickup window: $e");
    pickupTimeHasError.value = true;
  }
}
  bool _validatePhoneNumber(String phone) {
  // Regex pour valider le format téléphonique
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
  return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
}

 // ✅ CORRECTION : Validation plus robuste
// ✅ CORRECTION : Validation avec variables internes
bool _validateAllFields() {
  bool isValid = true;

  // Validation téléphone
  if (senderPhoneController.text.trim().isEmpty || 
      !_validatePhoneNumber(senderPhoneController.text.trim())) {
    senderPhoneHasError.value = true;
    isValid = false;
  }

  // Validation nom expéditeur
  if (senderNameController.text.trim().isEmpty) {
    senderNameHasError.value = true;
    isValid = false;
  }

  // Validation adresse
  if (addressController.text.trim().isEmpty) {
    addressHasError.value = true;
    isValid = false;
  }
    // ✅ NOUVEAU : Validation du handling
  final parcel = controller.currentParcel.value;
  final handlingLevel = parcel?.pickupHandling?['assistanceLevel'] ?? '';
  if (handlingLevel.isEmpty) {
    handlingHasError.value = true;
    isValid = false;
  }


  // ✅ CORRECTION : Validation avec variables internes
  if (_startDate == null || _startTime == null ||
      _endDate == null || _endTime == null) {
    pickupTimeHasError.value = true;
    isValid = false;
  } else {
    // Validation cohérence des dates
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (startDateTime.isAfter(endDateTime)) {
      pickupTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Date error",
        "Start date must be earlier than end date",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (startDateTime.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      pickupTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Date error",
        "Pick-up date must be in the future",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (endDateTime.difference(startDateTime).inMinutes < 30) {
      pickupTimeHasError.value = true;
      isValid = false;
      Get.snackbar(
        "Erreur de dates",
        "La fenêtre de ramassage doit être d'au moins 30 minutes",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  if (!isValid) {
    Get.snackbar(
      "Missing fields",
      "Please fill in all required fields",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  return isValid;
}
void _saveData() async {
  try {
    // ✅ 1. SAUVEGARDER LES INFORMATIONS EXPÉDITEUR
    await controller.updateField('senderName', senderNameController.text.trim());
    await controller.updateField('senderPhone', senderPhoneController.text.trim());
    await controller.calculateEstimatePrice();
    
    // ✅ 2. GÉOCODAGE ET SAUVEGARDE DE L'ADRESSE
    final geo = await GeocodingService.getCoordinatesFromAddress(addressController.text.trim());
    print("Adresse géocodée : ${geo?.formattedAddress}, ${geo?.latitude}, ${geo?.longitude}");
    
    if (geo != null) {
      await controller.setOriginAddress(
        geo.formattedAddress,
        geo.latitude,
        geo.longitude,
      );
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
    

    
    // ✅ 4. SAUVEGARDER LES INSTRUCTIONS DE RAMASSAGE
    await controller.updateField('pickupDescription', instructionsController.text.trim());
    
    // ✅ 5. FENÊTRE DE RAMASSAGE (déjà sauvegardée via _updatePickupWindow() mais vérification finale)
if (_startDate != null && _startTime != null &&
        _endDate != null && _endTime != null) {
      
      await _updatePickupWindow();
    }
    
    print("✅ Toutes les données de départ ont été sauvegardées avec succès");
    
  } catch (e) {
    // ✅ 6. GESTION D'ERREURS
    print("❌ Erreur lors de la sauvegarde : $e");
    Get.snackbar(
      "Erreur de sauvegarde",
      "Une erreur s'est produite lors de la sauvegarde. Veuillez réessayer.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

Future<void> _showHandlingSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final parcel = controller.currentParcel.value;
  final current = parcel?.pickupHandling?['assistanceLevel'] ?? '';

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
            ...pickupHandlingOptions.map((option) {
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
                          " +${fee.toStringAsFixed(0)}CAD",
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

                      await controller.updateField('pickupHandling', updated);
                      
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

// Méthode utilitaire pour les suffixes ordinaux
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
Widget _buildHandlingTile(BuildContext context) {
  final theme = Theme.of(context);
  
  return Obx(() {
    final parcel = controller.currentParcel.value;
    final current = parcel?.pickupHandling?['assistanceLevel'] ?? '';
    final floor = parcel?.pickupHandling?['floor'] ?? 0;
    final hasElevator = parcel?.pickupHandling?['hasElevator'] ?? false;
    final fee = parcel?.pickupHandling?['estimatedFee'] ?? 0.0;
    
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
      currentOption = pickupHandlingOptions.firstWhere(
        (e) => e['value'] == current,
        orElse: () => pickupHandlingOptions[0],
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
Future<void> _showFloorSelectionModal(BuildContext context) async {
  final theme = Theme.of(context);
  final navigationController = Get.find<NavigationController>();
  final parcel = controller.currentParcel.value;
  
  int currentFloor = parcel?.pickupHandling?['floor'] ?? 0;
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
                    "Pick-up floor",
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
                    final currentHandling = Map<String, dynamic>.from(parcel!.pickupHandling ?? {});
                    currentHandling['floor'] = selectedFloor.value;
                    
                    await controller.updateField('pickupHandling', currentHandling);
                    
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
  
  bool currentElevator = parcel?.pickupHandling?['hasElevator'] ?? false;
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
                    final currentHandling = Map<String, dynamic>.from(parcel!.pickupHandling ?? {});
                    currentHandling['hasElevator'] = hasElevator.value;
                    
                    await controller.updateField('pickupHandling', currentHandling);
                    
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