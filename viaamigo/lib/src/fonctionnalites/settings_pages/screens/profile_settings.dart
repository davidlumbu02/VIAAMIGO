import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({super.key});

  @override
  ProfileSettingPageState createState() => ProfileSettingPageState();
}

class ProfileSettingPageState extends State<ProfileSettingPage> {
  final userController = Get.find<UserController>();
  final authService = Get.find<AuthService>();
  final _formKey = GlobalKey<FormState>();

  late String firstName;
  late String lastName;
  late String email;
  late String phone;
  late String role;
  late String profilePicture;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les données actuelles de l'utilisateur
    final user = userController.currentUser.value;
    firstName = user!.firstName;
    lastName = user.lastName;
    email = user.email;
    phone = user.phone!;
    role = user.role;
    profilePicture = user.profilePicture!;
  }

  // Méthode pour choisir une image de profil
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profilePicture = image.path;
      });
    }
  }

  // Méthode pour sauvegarder les informations
void _saveProfile() {
  if (_formKey.currentState!.validate()) {
    // Créer un map avec les champs à mettre à jour
    Map<String, dynamic> updatedFields = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePicture': profilePicture,
    };

    // Utiliser updateFields pour mettre à jour les informations de l'utilisateur
    userController.updateFields(updatedFields);

    Get.snackbar('Succès', 'Profil mis à jour avec succès');
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre de la page
            Text('Modifier votre profil', style: textTheme.headlineMedium),
            const SizedBox(height: 20),

            // Formulaire de modification
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Photo de profil
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: (profilePicture.isNotEmpty)
                          ? FileImage(profilePicture as File) as ImageProvider
                          : const AssetImage('assets/images/default-profile.jpg'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Champ du prénom
                  TextFormField(
                    initialValue: firstName,
                    decoration: InputDecoration(labelText: 'Prénom'),
                    onChanged: (value) {
                      firstName = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un prénom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Champ du nom de famille
                  TextFormField(
                    initialValue: lastName,
                    decoration: InputDecoration(labelText: 'Nom de famille'),
                    onChanged: (value) {
                      lastName = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom de famille';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Champ de l'email
                  TextFormField(
                    initialValue: email,
                    decoration: InputDecoration(labelText: 'Email'),
                    onChanged: (value) {
                      email = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Champ du téléphone
                  TextFormField(
                    initialValue: phone,
                    decoration: InputDecoration(labelText: 'Téléphone'),
                    onChanged: (value) {
                      phone = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Sélection du rôle
                  DropdownButtonFormField<String>(
                    value: role,
                    onChanged: (newRole) {
                      setState(() {
                        role = newRole!;
                      });
                    },
                    items: ['conducteur', 'expediteur', 'les deux']
                        .map((role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    decoration: InputDecoration(labelText: 'Rôle'),
                  ),
                  const SizedBox(height: 20),

                  // Bouton Save
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Enregistrer', style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({super.key});

  @override
  _ProfileSettingPageState createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  // Déclaration des contrôleurs de texte
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    // Initialisation des TextEditingController avec les valeurs actuelles de l'utilisateur
    final user = Get.find<UserController>().currentUser.value;
    firstNameController = TextEditingController(text: user?.firstName ?? '');
    lastNameController = TextEditingController(text: user?.lastName ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    // Libération des contrôleurs quand la page est détruite pour éviter les fuites de mémoire
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final userController = Get.find<UserController>();
    final user = userController.currentUser.value;

    return ThemedScaffoldWrapper(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30), // Coins arrondis pour l'effet visuel
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Effet de flou d'arrière-plan
          child: Material(
            color: theme.colorScheme.surface.withAlpha(242),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 30, 20, 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et Avatar de l'utilisateur
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, ${user?.firstName ?? 'User'} 👋', 
                                  style: textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                              const SizedBox(height: 4),
                              if (user != null)
                                Text('${user.firstName} ${user.lastName}',
                                    style: textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                              if (user != null)
                                Text(user.email, 
                                    style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withAlpha(190))),
                              if (user == null)
                                Text('Loading...', style: textTheme.bodySmall),
                            ],
                          ),

                          // Avatar de l'utilisateur
                          CircleAvatar(
                            radius: 34,
                            backgroundImage: (user != null && user.safeProfilePicture.isNotEmpty)
                                ? NetworkImage(user.safeProfilePicture)
                                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),
                    ],
                  ),
                ),

                // CONTENU PRINCIPAL
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        _sectionTitle('Profile Settings'), // Titre de la section
                        _inputField(theme, 'First Name', firstNameController), // Champ pour le prénom
                        _inputField(theme, 'Last Name', lastNameController), // Champ pour le nom
                        _inputField(theme, 'Phone', phoneController), // Champ pour le téléphone
                        _inputField(theme, 'Email', emailController), // Champ pour l'email

                        const SizedBox(height: 30),
                        // Bouton pour sauvegarder les modifications
                        _saveButton(context, theme, firstNameController, lastNameController, phoneController, emailController),
                        const SizedBox(height: 30),
                        _logoutButton(context, theme), // Bouton de déconnexion
                      ],
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

  // Widget pour afficher un titre de section
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // Widget pour afficher un champ de texte modifiable
  Widget _inputField(ThemeData theme, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
        ),
      ),
    );
  }

  // Widget pour le bouton de sauvegarde des changements
  Widget _saveButton(BuildContext context, ThemeData theme, TextEditingController firstNameController, TextEditingController lastNameController, TextEditingController phoneController, TextEditingController emailController) {
    return ElevatedButton(
      onPressed: () async {
        // Mettre à jour les informations de l'utilisateur
        Map<String, dynamic> fields = {
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
          'phone': phoneController.text,
          'email': emailController.text,
        };

        // Sauvegarder les données dans la base de données via le UserController
        await Get.find<UserController>().updateFields(fields);

        // Afficher un message de confirmation
        Get.snackbar('Success', 'Profile updated successfully');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text('Save Changes', style: TextStyle(color: theme.colorScheme.onPrimary)),
    );
  }

  // Widget pour le bouton de déconnexion
  Widget _logoutButton(BuildContext context, ThemeData theme) {
    return TextButton.icon(
      onPressed: () async {
        // Déconnexion de l'utilisateur via AuthService
        await Get.find<AuthService>().signOut();
      },
      icon: Icon(Icons.logout, color: theme.colorScheme.primary),
      label: const Text("Logout"),
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
*/