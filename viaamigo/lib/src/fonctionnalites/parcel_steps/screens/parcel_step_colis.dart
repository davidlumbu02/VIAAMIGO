import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';


class ParcelStepColis extends StatelessWidget {
  final controller = Get.find<ParcelsController>();

  ParcelStepColis({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parcel = controller.currentParcel.value!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ListView(
        children: [
          Text("Photos du colis", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...parcel.photos.map((photoUrl) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(photoUrl, width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => controller.removePhoto(photoUrl),
                      )
                    ],
                  )),
              GestureDetector(
                onTap: () {
                  // Intègre ton image picker ici (ex: ImagePicker, FilePicker, etc.)
                  // Exemple simplifié : controller.addPhoto("https://dummyimage.com/100x100");
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
                  ),
                  child: const Center(child: Icon(Icons.add_a_photo_outlined)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text("Titre du colis", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: parcel.title,
            onChanged: (value) => controller.updateField('title', value),
            decoration: const InputDecoration(hintText: "Ex: Vélo d’occasion"),
          ),

          const SizedBox(height: 24),
          Text("Description", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: parcel.description,
            onChanged: (value) => controller.updateField('description', value),
            decoration: const InputDecoration(hintText: "Détails utiles pour le transport"),
            maxLines: 3,
          ),

          const SizedBox(height: 24),
          Text("Dimensions et poids", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: parcel.dimensions['length'].toString(),
                  onChanged: (val) => controller.updateField('dimensions', {
                    'length': double.tryParse(val) ?? 0,
                    'width': parcel.dimensions['width'],
                    'height': parcel.dimensions['height'],
                  }),
                  decoration: const InputDecoration(labelText: "Longueur (cm)"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: parcel.dimensions['width'].toString(),
                  onChanged: (val) => controller.updateField('dimensions', {
                    'length': parcel.dimensions['length'],
                    'width': double.tryParse(val) ?? 0,
                    'height': parcel.dimensions['height'],
                  }),
                  decoration: const InputDecoration(labelText: "Largeur (cm)"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: parcel.dimensions['height'].toString(),
                  onChanged: (val) => controller.updateField('dimensions', {
                    'length': parcel.dimensions['length'],
                    'width': parcel.dimensions['width'],
                    'height': double.tryParse(val) ?? 0,
                  }),
                  decoration: const InputDecoration(labelText: "Hauteur (cm)"),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          TextFormField(
            initialValue: parcel.weight.toString(),
            onChanged: (val) => controller.updateField('weight', val),
            decoration: const InputDecoration(labelText: "Poids (kg)"),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),
          Text("Type d'objet", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: parcel.category,
            onChanged: (val) => controller.updateField('category', val),
            items: const [
              DropdownMenuItem(value: 'normal', child: Text("Objet standard")),
              DropdownMenuItem(value: 'fragile', child: Text("Fragile")),
              DropdownMenuItem(value: 'perishable', child: Text("Périssable")),
              DropdownMenuItem(value: 'valuable', child: Text("Valeur")),
            ],
          ),
        ],
      ),
    );
  }
}
