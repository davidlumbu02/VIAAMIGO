import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/trip/controller/trip_controller.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';
import 'package:viaamigo/shared/collections/parcel/services/geocoding_service.dart';

class PublishTripPage extends StatefulWidget {
  const PublishTripPage({super.key});

  @override
  State<PublishTripPage> createState() => _PublishTripPageState();
}

class _PublishTripPageState extends State<PublishTripPage> {
  late final TripController tripController;

  // Dates/horaires internes
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;

  // Suggestions adresse
  final RxList<GeocodingResult> addressSuggestions = <GeocodingResult>[].obs;

  // Controllers champs adresse & temps
  late TextEditingController originAddressController;
  late TextEditingController destinationAddressController;
  late TextEditingController departureDateController;
  late TextEditingController departureTimeController;
  late TextEditingController arrivalDateController;
  late TextEditingController arrivalTimeController;

  // Controllers infos véhicule (directement dans vehicleInfo du TripModel)
  late TextEditingController vehicleTypeController;
  late TextEditingController vehicleBrandController;
  late TextEditingController vehicleModelController;
  late TextEditingController vehicleYearController;
  late TextEditingController vehicleColorController;
  late TextEditingController vehiclePlateController;

  // Controllers capacité
  late TextEditingController maxWeightController;
  late TextEditingController maxVolumeController;
  late TextEditingController maxParcelsController;

  // Controllers waypoints et flexibilité
  late TextEditingController waypointAddressController;
  //late TextEditingController flexibilityController;
  final RxList<Map<String, dynamic>> tripWaypoints = <Map<String, dynamic>>[].obs;
  final RxDouble flexibility = 30.0.obs;

  // Controllers autres champs
  late TextEditingController acceptedParcelTypesController;
  late TextEditingController handlingRequirementsController;
  late TextEditingController notificationSettingsController;

  // Erreurs / états
  final RxBool originHasError = false.obs;
  final RxBool destinationHasError = false.obs;
  final RxBool timeHasError = false.obs;
  final RxBool isRecurring = false.obs;

  // Switches handling
  final RxBool hFragile = false.obs;
  final RxBool hRefrigerated = false.obs;
  final RxBool hOversized = false.obs;
  final RxBool hValuable = false.obs;
  // Autoriser détour (simple bool)
final RxBool allowDetours = false.obs;


  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeForm();
  }

  void _initializeController() {
    try {
      tripController = Get.find<TripController>();
    } catch (_) {
      tripController = Get.put(TripController());
    }

    // Si aucun trip en cours, créer un nouveau brouillon
  if (tripController.currentTrip.value == null) {
    // Créer un trip minimal pour éviter les erreurs
    tripController.initTrip();
  }
  }

  void _initializeForm() {
    final trip = tripController.currentTrip.value;

    // --- Adresses ---
    originAddressController = TextEditingController(text: trip?.originAddress ?? '');
    destinationAddressController = TextEditingController(text: trip?.destinationAddress ?? '');

    // --- Temps ---
    final dep = trip?.departureTime;
    final arr = trip?.arrivalTime;
  // Charger la valeur si elle existe dans le modèle, sinon false
    allowDetours.value = trip?.allowDetours ?? false;
    
    _departureDate = dep;
    _departureTime = dep != null ? TimeOfDay.fromDateTime(dep) : null;
    _arrivalDate = arr;
    _arrivalTime = arr != null ? TimeOfDay.fromDateTime(arr) : null;

    departureDateController = TextEditingController(text: _formatDate(dep));
    departureTimeController = TextEditingController(text: _formatTime(_departureTime));
    arrivalDateController = TextEditingController(text: _formatDate(arr));
    arrivalTimeController = TextEditingController(text: _formatTime(_arrivalTime));

    // --- Véhicule infos ---
    vehicleTypeController = TextEditingController(text: trip?.vehicleType ?? 'car');
    vehicleBrandController = TextEditingController(text: trip?.vehicleInfo['brand'] ?? '');
    vehicleModelController = TextEditingController(text: trip?.vehicleInfo['model'] ?? '');
    vehicleYearController = TextEditingController(
        text: (trip?.vehicleInfo['year'] ?? DateTime.now().year).toString());
    vehicleColorController = TextEditingController(text: trip?.vehicleInfo['color'] ?? '');
    vehiclePlateController = TextEditingController(text: trip?.vehicleInfo['licensePlate'] ?? '');

    // --- Capacité ---
    maxWeightController = TextEditingController(
        text: (trip?.vehicleCapacity['maxWeight'] ?? 20.0).toString());
    maxVolumeController = TextEditingController(
        text: (trip?.vehicleCapacity['maxVolume'] ?? 100.0).toString());
    maxParcelsController = TextEditingController(
        text: (trip?.vehicleCapacity['maxParcels'] ?? 3).toString());

    // Waypoints & Flexibilité
    tripWaypoints.assignAll(trip?.waypoints ?? []);
    waypointAddressController = TextEditingController();
    flexibility.value = (trip?.vehicleInfo['flexibility']?.toDouble()) ?? 30.0;
    //flexibilityController = TextEditingController(text: flexibility.value.round().toString());

    // --- Types acceptés ---
    acceptedParcelTypesController = TextEditingController(
        text: (trip?.acceptedParcelTypes ?? const [])
            .map((e) => e.toString())
            .join(', '));

    // --- Handling switches ---
    final hc = trip?.handlingCapabilities ?? {};
    hFragile.value = hc['fragile'] ?? false;
    hRefrigerated.value = hc['refrigerated'] ?? false;
    hOversized.value = hc['oversized'] ?? false;
    hValuable.value = hc['valuable'] ?? false;
    handlingRequirementsController = TextEditingController();

    // --- Notifications ---
    notificationSettingsController = TextEditingController(
      text: jsonEncode(trip?.notificationSettings ?? {
        'app': true,
        'sms': false,
        'email': true,
        'sound': true,
      }),
    );

    // --- Récurrence ---
    isRecurring.value = trip?.isRecurring ?? false;
  }

  @override
  void dispose() {
    // Dispose tous les controllers
    originAddressController.dispose();
    destinationAddressController.dispose();
    departureDateController.dispose();
    departureTimeController.dispose();
    arrivalDateController.dispose();
    arrivalTimeController.dispose();
    vehicleTypeController.dispose();
    vehicleBrandController.dispose();
    vehicleModelController.dispose();
    vehicleYearController.dispose();
    vehicleColorController.dispose();
    vehiclePlateController.dispose();
    maxWeightController.dispose();
    maxVolumeController.dispose();
    maxParcelsController.dispose();
    waypointAddressController.dispose();
    //flexibilityController.dispose();
    acceptedParcelTypesController.dispose();
    handlingRequirementsController.dispose();
    notificationSettingsController.dispose();

    super.dispose();
  }

  // --- HELPERS FORMATAGE ---

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                      // --- SECTION DÉPART ---
                       const SizedBox(height: 16),
                      sectionTitle(context, "Origin"),
                      _buildOriginAddress(),
                      const SizedBox(height: 24),
                      _buildDepartureDateTime(),
                      const SizedBox(height: 24),

                      // --- SECTION DESTINATION ---
                      sectionTitle(context, "Destination"),
                      _buildDestinationAddress(),
                      const SizedBox(height: 24),

                      // --- SECTION VÉHICULE ---
                      //sectionTitle(context, "Vehicle Information"),
                      _buildVehicleSection(),
                      const SizedBox(height: 24),

                      // --- SECTION OPTIONS ROUTE ---
                      //sectionTitle(context, "Route Options"),
                      _buildWaypointsSection(),
                      const SizedBox(height: 24),
/*
                      // --- SECTION PLANNING ---
                      sectionTitle(context, "Scheduling"),
                      _buildFlexibilitySection(),
                      const SizedBox(height: 24),*/

                      // --- SECTION CAPACITÉ ---
                      sectionTitle(context, "Capacity"),
                      _buildCapacitySection(),
                      const SizedBox(height: 24),

                      // --- SECTION TYPES ACCEPTÉS ---
                     /* sectionTitle(context, "Accepted parcel types"),
                      _buildAcceptedTypes(),
                      const SizedBox(height: 24),*/

                      // --- SECTION HANDLING ---
                     /* sectionTitle(context, "Handling"),
                      _buildHandlingSection(),
                      const SizedBox(height: 24),*/

                      // --- SECTION NOTIFICATIONS ---
                      /*sectionTitle(context, "Notifications"),
                      _buildNotificationSection(),
                      const SizedBox(height: 24),*/

                      // --- SECTION RÉCURRENCE ---
                     /* sectionTitle(context, "Recurrence"),
                      _buildRecurrence(),
                      const SizedBox(height: 32), */

                      // --- BOUTON PUBLICATION ---
                      MyButton(
                        text: "Save & Publish",
                        height: 50,
                        width: double.infinity,
                        borderRadius: 30,
                        onTap: _onSubmit,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI BUILDERS ---

  Widget _buildOriginAddress() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showAddressSearchModal(
        context: context,
        initialValue: originAddressController.text,
        isOrigin: true,
        onSelected: (res) {
          originAddressController.text = res.formattedAddress;
          tripController.setOriginAddress(res.formattedAddress, res.latitude, res.longitude);
        },
      ),
      child: IgnorePointer(
        child: Obx(() => CustomTextField(
          controller: originAddressController,
          labelText: 'Enter an origin',
          borderRadius: 10,
          isTransparent: true,
          prefixIcon: const Icon(LucideIcons.mapPin),
          suffixIcon: originAddressController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () {
                    originAddressController.clear();
                    tripController.setOriginAddress('', 0, 0);
                    originHasError.value = false;
                  },
                )
              : null,
          borderColor: originHasError.value 
              ? Colors.red 
              : theme.colorScheme.outline.withAlpha(77),
        )),
      ),
    );
  }

  Widget _buildDestinationAddress() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showAddressSearchModal(
        context: context,
        initialValue: destinationAddressController.text,
        isOrigin: false,
        onSelected: (res) {
          destinationAddressController.text = res.formattedAddress;
          tripController.setDestinationAddress(res.formattedAddress, res.latitude, res.longitude);
        },
      ),
      child: IgnorePointer(
        child: Obx(() => CustomTextField(
          controller: destinationAddressController,
          labelText: 'Enter a destination',
          borderRadius: 10,
          isTransparent: true,
          prefixIcon: const Icon(LucideIcons.mapPin),
          suffixIcon: destinationAddressController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () {
                    destinationAddressController.clear();
                    tripController.setDestinationAddress('', 0, 0);
                    destinationHasError.value = false;
                  },
                )
              : null,
          borderColor: destinationHasError.value
              ? Colors.red
              : theme.colorScheme.outline.withAlpha(77),
          
        )),
      ),
    );
  }

  Widget _buildDepartureDateTime() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: timeHasError.value
              ? Colors.red
              : theme.colorScheme.outline.withAlpha(77),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _dateTimeRow(
            dateController: departureDateController,
            timeController: departureTimeController,
            onPickDate: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _departureDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                _departureDate = picked;
                departureDateController.text = _formatDate(picked);
                await _applyDeparture();
              }
            },
            onPickTime: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _departureTime ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked != null) {
                _departureTime = picked;
                departureTimeController.text = _formatTime(picked);
                await _applyDeparture();
              }
            },
          ),
          const SizedBox(height: 12),
          _dateTimeRow(
            label: "Estimated arrival (optional)",
            dateController: arrivalDateController,
            timeController: arrivalTimeController,
            onPickDate: () async {
              final base = _departureDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _arrivalDate ?? base,
                firstDate: base,
                lastDate: base.add(const Duration(days: 365)),
              );
              if (picked != null) {
                _arrivalDate = picked;
                arrivalDateController.text = _formatDate(picked);
                await _applyArrival();
              }
            },
            onPickTime: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _arrivalTime ?? const TimeOfDay(hour: 12, minute: 0),
              );
              if (picked != null) {
                _arrivalTime = picked;
                arrivalTimeController.text = _formatTime(picked);
                await _applyArrival();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _dateTimeRow({
    String label = "Departure",
    required TextEditingController dateController,
    required TextEditingController timeController,
    required VoidCallback onPickDate,  
    required VoidCallback onPickTime,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onPickDate,
                child: IgnorePointer(
                  child: CustomTextField(
                    controller: dateController,
                    isTransparent: true,
                    borderRadius: 8,
                    prefixIcon: const Icon(LucideIcons.calendar, size: 16),
                    borderColor: timeHasError.value
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
                onTap: onPickTime,
                child: IgnorePointer(
                  child: CustomTextField(
                    controller: timeController,
                    isTransparent: true,
                    borderRadius: 8,
                    prefixIcon: const Icon(LucideIcons.clock, size: 16),
                    borderColor: timeHasError.value
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

  // SECTION VÉHICULE
  Widget _buildVehicleSection() {
      final theme = Theme.of(context);
    return Column(
      children: [
        // Type de véhicule dropdown
        DropdownButtonFormField<String>(
          value: vehicleTypeController.text.isEmpty ? 'car' : vehicleTypeController.text,
          decoration: InputDecoration(
            labelText: "Vehicle type",
            prefixIcon: const Icon(LucideIcons.car),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(77))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.transparent,
          ),
          items: const [
            DropdownMenuItem(value: 'car', child: Text('🚗 Car')),
            DropdownMenuItem(value: 'van', child: Text('🚐 Van')),
            DropdownMenuItem(value: 'truck', child: Text('🚛 Truck')),
            DropdownMenuItem(value: 'motorcycle', child: Text('🏍️ Motorcycle')),
            //DropdownMenuItem(value: 'bicycle', child: Text('🚲 Bicycle')),
          ],
          onChanged: (value) {
            if (value != null) {
              vehicleTypeController.text = value;
              tripController.updateField('vehicleType', value);
            }
          },
        ),
        const SizedBox(height: 12),
        
        // Détails véhicule
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: vehicleBrandController,
                labelText: "Brand",
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
                onSubmitted: (val) => tripController.updateVehicleInfo('brand', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: vehicleModelController,
                labelText: "Model",
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
                onSubmitted: (val) => tripController.updateVehicleInfo('model', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: vehicleYearController,
                labelText: "Year",
                keyboardType: TextInputType.number,
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
                onSubmitted: (val) {
                  final year = int.tryParse(val) ?? DateTime.now().year;
                  tripController.updateVehicleInfo('year', year);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: vehicleColorController,
                labelText: "Color",
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
                onSubmitted: (val) => tripController.updateVehicleInfo('color', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: vehiclePlateController,
          labelText: "License plate",
          isTransparent: true,
          borderRadius: 10,
          borderColor: theme.colorScheme.outline.withAlpha(77),
          onSubmitted: (val) => tripController.updateVehicleInfo('licensePlate', val),
        ),
      ],
    );
  }

  // SECTION WAYPOINTS
  Widget _buildWaypointsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liste waypoints existants
        Obx(() => Column(
              children: tripWaypoints.asMap().entries.map((entry) {
                final index = entry.key;
                final waypoint = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      waypoint['address'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text("Stop duration: ${waypoint['stopDuration'] ?? 15} min"),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => _removeWaypoint(index),
                    ),
                  ),
                );
              }).toList(),
            )),
            Obx(() => Row(
              children: [
                Expanded(
                  child: Text(
                    "Allow detours between origins and destinations, waypoints",
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: allowDetours.value,
                  onChanged: (v) {
                    allowDetours.value = v;
                    tripController.updateField('allowDetours', v);
                  },
                ),
              ],
            )),

        
        // Bouton ajouter waypoint
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddWaypointModal(),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text("Add intermediate stop"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
/*
  // SECTION FLEXIBILITÉ
  Widget _buildFlexibilitySection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time flexibility around departure",
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
              children: [
                Slider(
                  min: 0,
                  max: 120,
                  divisions: 8,
                  value: flexibility.value,
                  label: "±${flexibility.value.round()} min",
                  onChanged: (value) {
                    flexibility.value = value;
                    flexibilityController.text = value.round().toString();
                    tripController.updateVehicleInfo('flexibility', value.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Exact time", style: theme.textTheme.bodySmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "±${flexibility.value.round()} minutes",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text("Very flexible", style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            )),
      ],
    );
  }
*/

  Widget _buildCapacitySection() {
   final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: maxWeightController,
                labelText: "Max weight (kg)",
                keyboardType: TextInputType.number,
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: maxVolumeController,
                labelText: "Max volume (L)",
                keyboardType: TextInputType.number,
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: maxParcelsController,
                labelText: "Max parcels",
                keyboardType: TextInputType.number,
                isTransparent: true,
                borderRadius: 10,
                borderColor: theme.colorScheme.outline.withAlpha(77),
              ),
            ),
            const SizedBox(width: 12),
           /* Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final w = double.tryParse(maxWeightController.text.trim()) ?? 20.0;
                    final v = double.tryParse(maxVolumeController.text.trim()) ?? 100.0;
                    final p = int.tryParse(maxParcelsController.text.trim()) ?? 3;
                    tripController.updateVehicleCapacity(w, v, p);
                  },
                  icon: const Icon(LucideIcons.save, size: 16),
                  label: const Text("Save capacity"),
                ),
              ),
            ),*/
          ],
        ),
      ],
    );
  }
/*
Widget _buildAcceptedTypes() {
  final theme = Theme.of(context);
  return Column(
    children: [
      CustomTextField(
        controller: acceptedParcelTypesController,
        labelText: "Accepted types (comma separated)",
        hintText: "documents, electronics, clothing...",
        isTransparent: true,
        borderRadius: 10,
        borderColor: theme.colorScheme.primary.withAlpha(77),
        onSubmitted: (val) {
          final list = val
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          tripController.updateField('acceptedParcelTypes', list);
        },
      ),
      const SizedBox(height: 8),
      Obx(() => Wrap(
            spacing: 8,
            // ✅ CORRECTION ICI :
            children: (tripController.acceptedParcelTypesList ?? [])
                .map((t) => Chip(
                      label: Text(t),
                      onDeleted: () => tripController.removeAcceptedParcelType(t),
                    ))
                .toList(),
          )),
    ],
  );
}*//*
  Widget _buildHandlingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switches liés au modèle
        Obx(() => Column(
              children: [
                SwitchListTile(
                  title: const Text("Fragile parcels"),
                  subtitle: const Text("Can handle fragile items"),
                  value: hFragile.value,
                  onChanged: (v) {
                    hFragile.value = v;
                    tripController.updateHandlingCapability('fragile', v);
                  },
                ),
                SwitchListTile(
                  title: const Text("Refrigerated transport"),
                  subtitle: const Text("Has cooling capability"),
                  value: hRefrigerated.value,
                  onChanged: (v) {
                    hRefrigerated.value = v;
                    tripController.updateHandlingCapability('refrigerated', v);
                  },
                ),
                SwitchListTile(
                  title: const Text("Oversized parcels"),
                  subtitle: const Text("Can handle large items"),
                  value: hOversized.value,
                  onChanged: (v) {
                    hOversized.value = v;
                    tripController.updateHandlingCapability('oversized', v);
                  },
                ),
                SwitchListTile(
                  title: const Text("Valuable items"),
                  subtitle: const Text("Secure transport for valuables"),
                  value: hValuable.value,
                  onChanged: (v) {
                    hValuable.value = v;
                    tripController.updateHandlingCapability('valuable', v);
                  },
                ),
              ],
            )),
        const SizedBox(height: 8),
       /* CustomTextField(
          controller: handlingRequirementsController,
          labelText: "Additional handling notes (optional)",
          maxLines: 3,
          isTransparent: true,
          borderRadius: 10,
          borderColor: Theme.of(context).colorScheme.primary.withAlpha(77),
        ),*/
      ],
    );
  }
/*
  Widget _buildNotificationSection() {
    final theme = Theme.of(context);
    return CustomTextField(
      controller: notificationSettingsController,
      labelText: "Notification settings (JSON)",
      maxLines: 3,
      isTransparent: true,
      borderRadius: 10,
      borderColor: theme.colorScheme.primary.withAlpha(77),
      onSubmitted: (val) {
        try {
          final parsed = jsonDecode(val);
          if (parsed is Map<String, dynamic>) {
            tripController.updateNotificationSettings(parsed);
          }
        } catch (_) {
          // ignore parse error
        }
      },
    );
  }
*/
  Widget _buildRecurrence() {
    return Obx(() => SwitchListTile(
          title: const Text("Recurring trip"),
          subtitle: const Text("This trip repeats weekly"),
          value: isRecurring.value,
          onChanged: (v) {
            isRecurring.value = v;
            tripController.toggleRecurring(v);
          },
        ));
  }
*/
  // --- HELPERS ---

  Future<void> _applyDeparture() async {
    if (_departureDate == null || _departureTime == null) return;
    final dt = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );
if (dt.isBefore(DateTime.now())) {
    timeHasError.value = true;
    UIMessageManager.dateError("Departure date must be in the future");
    return;
  }
  await tripController.updateField('departureTime', dt);
  timeHasError.value = false;
 // UIMessageManager.pickupTimeSet();
  }

Future<void> _applyArrival() async {
  if (_arrivalDate == null || _arrivalTime == null) {
    await tripController.updateField('arrivalTime', null);
    return;
  }
  final dt = DateTime(
    _arrivalDate!.year,
    _arrivalDate!.month,
    _arrivalDate!.day,
    _arrivalTime!.hour,
    _arrivalTime!.minute,
  );
  if (_departureDate != null && _departureTime != null) {
    final departureDt = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );
    if (dt.isBefore(departureDt)) {
      timeHasError.value = true;
      UIMessageManager.error("Arrival time must be after departure time");
      return;
    }
  }
  await tripController.updateField('arrivalTime', dt);
}

  void _removeWaypoint(int index) {
    tripWaypoints.removeAt(index);
    tripController.updateField('waypoints', tripWaypoints.toList());
  }

  Future<void> _showAddWaypointModal() async {
    final theme = Theme.of(context);
    final navigationController = Get.find<NavigationController>();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController durationController = TextEditingController(text: "15");
    final RxList<GeocodingResult> suggestions = <GeocodingResult>[].obs;

    await navigationController.showAppBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
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
                "Add Intermediate Stop",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: addressController,
                hintText: "Stop address",
                borderRadius: 12,
                prefixIcon: const Icon(LucideIcons.mapPin),
                isTransparent: true,
                borderColor: theme.colorScheme.primary.withAlpha(77),
                onChanged: (query) async {
                  if (query.trim().length < 3) {
                    suggestions.clear();
                    return;
                  }
              try {
                  final results = await GeocodingService.searchAddressSuggestions(query);
                  suggestions.assignAll(results);
                } catch (e) {
                  UIMessageManager.addressError("Failed to fetch address suggestions: $e");
                }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: durationController,
                      labelText: "Stop duration (min)",
                      keyboardType: TextInputType.number,
                      borderRadius: 12,
                      isTransparent: true,
                      borderColor: theme.colorScheme.primary.withAlpha(77),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (addressController.text.isNotEmpty) {
                        final duration = int.tryParse(durationController.text) ?? 15;
                        _addWaypoint(addressController.text, 0, 0, duration);
                        Get.back();
                      }
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Obx(
                  () => suggestions.isEmpty
                      ? const Center(child: Text("Type to search addresses"))
                      : ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, i) {
                            final s = suggestions[i];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, size: 20),
                              title: Text(s.formattedAddress),
                              onTap: () {
                                addressController.text = s.formattedAddress;
                                _addWaypoint(s.formattedAddress, s.latitude, s.longitude, int.tryParse(durationController.text) ?? 15);
                                suggestions.clear();
                                Get.back();
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ✅ NOUVELLE MÉTHODE : Supprimer l'adresse
void _clearAddress() {
  // Vider le champ texte
  originAddressController.clear();
  
  // Réinitialiser l'adresse dans le contrôleur
  tripController.setOriginAddress('', 0.0, 0.0);
  
  // Réinitialiser l'erreur d'adresse
  originHasError.value = false;
  

}
void _clearAddress2() {
  // Vider le champ texte
  destinationAddressController.clear();
  
  // Réinitialiser l'adresse dans le contrôleur
  tripController.setDestinationAddress('', 0.0, 0.0);
  
  // Réinitialiser l'erreur d'adresse
  destinationHasError.value = false;
  

}
  void _addWaypoint(String address, double lat, double lng, int duration) {
    if (lat == 0 || lng == 0) {
    UIMessageManager.error("Invalid coordinates for waypoint: $address");
    return;
  }
    final waypoint = {
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'stopDuration': duration,
    };
    tripWaypoints.add(waypoint);
    tripController.updateField('waypoints', tripWaypoints.toList());
  }

  Future<void> _showAddressSearchModal({
    required BuildContext context,
    required String initialValue,
    required bool isOrigin,
    required Function(GeocodingResult) onSelected,
  }) async {
    final theme = Theme.of(context);
    final RxList<GeocodingResult> suggestions = <GeocodingResult>[].obs;
    final TextEditingController searchController =
        TextEditingController(text: initialValue);
    final navigationController = Get.find<NavigationController>();

    await navigationController.showAppBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      enableDrag: true,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85 -
                  MediaQuery.of(context).viewInsets.bottom,
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
                hintText: isOrigin ? "Origin address" : "Destination address",
                borderRadius: 12,
                borderColor: isOrigin
                    ? (originHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77))
                    : (destinationHasError.value ? Colors.red : theme.colorScheme.primary.withAlpha(77)),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () {
                          searchController.clear();
                          suggestions.clear();
                          if (isOrigin) {
                            _clearAddress();
                          } else {
                            _clearAddress2();
                          }
                        },
                      )
                    : null,
                isTransparent: true,
                onChanged: (query) async {
                  if (query.trim().length < 3) {
                    suggestions.clear();
                    return;
                  }
                  try {
                    final results = await GeocodingService.searchAddressSuggestions(query);
                    suggestions.assignAll(results);
                  } catch (e) {
                    UIMessageManager.addressError("Failed to fetch address suggestions: $e");
                  }
                },
              ),
                const SizedBox(height: 20),
                Expanded(
                  child: Obx(
                    () => suggestions.isEmpty
                        ? const Center(child: Text("No suggestions"))
                        : ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, i) {
                              final s = suggestions[i];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(s.formattedAddress),
                                onTap: () {
                                  onSelected(s);
                                  
                                  Get.back();
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
Future<void> _onSubmit() async {
  // ✅ AJOUTEZ CETTE VÉRIFICATION AU DÉBUT :
  // S'assurer qu'un trip existe avant de continuer
  if (tripController.currentTrip.value == null) {
    print("⚠️ Aucun currentTrip, création en cours...");
    await tripController.initTrip();
    
    // Attendre que l'initialisation se termine
    if (tripController.currentTrip.value == null) {
      UIMessageManager.error("Unable to initialize trip. Please try again.");
      return;
    }
  }

  // Validation des champs obligatoires
  bool hasErrors = false;
  if (tripWaypoints.any((w) => w['latitude'] == 0 || w['longitude'] == 0)) {
  UIMessageManager.error("All waypoints must have valid coordinates");
  hasErrors = true;
}

  // Validation adresses
  if (originAddressController.text.isEmpty) {
    originHasError.value = true;
    hasErrors = true;
  } else {
    // ✅ ASSUREZ-VOUS QUE L'ADRESSE EST DANS LE MODÈLE :
    if (tripController.currentTrip.value!.originAddress.isEmpty) {
      await tripController.updateField('originAddress', originAddressController.text);
    }
  }
  
  if (destinationAddressController.text.isEmpty) {
    destinationHasError.value = true;
    hasErrors = true;
  } else {
    // ✅ ASSUREZ-VOUS QUE L'ADRESSE EST DANS LE MODÈLE :
    if (tripController.currentTrip.value!.destinationAddress.isEmpty) {
      await tripController.updateField('destinationAddress', destinationAddressController.text);
    }
  }

  // Validation timing
  if (_departureDate == null || _departureTime == null) {
    timeHasError.value = true;
    hasErrors = true;
  } else {
    // ✅ ASSUREZ-VOUS QUE LA DATE EST DANS LE MODÈLE :
    final dt = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );
    await tripController.updateField('departureTime', dt);
  }

  if (hasErrors) {
    UIMessageManager.error("Please fill all required fields correctly");
    return;
  }

  try {
    // ✅ ASSUREZ-VOUS QUE TOUS LES CHAMPS SONT À JOUR AVANT PUBLICATION :
    await tripController.updateField('vehicleType', vehicleTypeController.text.trim().isNotEmpty 
        ? vehicleTypeController.text.trim() 
        : 'car');
      
    // VehicleInfo 
    await tripController.updateField('vehicleInfo', {
      'brand': vehicleBrandController.text.trim(),
      'model': vehicleModelController.text.trim(),
      'year': int.tryParse(vehicleYearController.text.trim()) ?? DateTime.now().year,
      'color': vehicleColorController.text.trim(),
      'licensePlate': vehiclePlateController.text.trim(),
      'flexibility': flexibility.value.round(),
    });

    // Types acceptés
    final list = acceptedParcelTypesController.text.isNotEmpty
        ? acceptedParcelTypesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>['documents']; // Valeur par défaut si vide
    await tripController.updateField('acceptedParcelTypes', list);

    // Capacités
    final w = double.tryParse(maxWeightController.text.trim()) ?? 20.0;
    final v = double.tryParse(maxVolumeController.text.trim()) ?? 100.0;
    final p = int.tryParse(maxParcelsController.text.trim()) ?? 3;
    await tripController.updateVehicleCapacity(w, v, p);
// Autoriser détour
await tripController.updateField('allowDetours', allowDetours.value);
    // Waypoints
    await tripController.updateField('waypoints', tripWaypoints.toList());

    // ✅ ATTENDRE UN PEU POUR S'ASSURER QUE TOUT EST SYNCHRONISÉ :
    await Future.delayed(Duration(milliseconds: 100));

    // ✅ VÉRIFICATION FINALE AVANT PUBLICATION :
    print("🔍 Vérification finale avant publication:");
    print("   - currentTrip non null: ${tripController.currentTrip.value != null}");
    print("   - originAddress: '${tripController.currentTrip.value?.originAddress}'");
    print("   - destinationAddress: '${tripController.currentTrip.value?.destinationAddress}'");
    print("   - departureTime: ${tripController.currentTrip.value?.departureTime}");
    
    // Publication
    final success = await tripController.publishTrip();
          // juste attendre un peu pour la stabilité
      await Future.delayed(const Duration(milliseconds: 400));
      // Rediriger vers le dashboard ou la liste des colis
      
    if (success) {
      UIMessageManager.success("Trip published successfully!");
      Get.find<NavigationController>().navigateToNamed('home');
      Get.back(); // Retour à la page précédente
    } else {
      UIMessageManager.error((tripController.validationErrorsList).join('\n'));
    }
  } catch (e) {
UIMessageManager.error("An error occurred while publishing the trip: $e");
  }
}
}