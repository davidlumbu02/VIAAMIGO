// 📦 Import des packages nécessaires
import 'package:flutter/material.dart'; // Composants UI Flutter
import 'package:get/get.dart'; // Navigation et gestion d'état avec GetX
import 'package:firebase_auth/firebase_auth.dart'; // Authentification Firebase
import 'package:viaamigo/shared/widgets/custom_text_field.dart'; // Champ personnalisé réutilisable
import 'package:viaamigo/shared/controllers/signup_controller.dart'; // Contrôleur d'inscription GetX
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart'; // Enveloppe pour gestion du thème

// 👤 Widget de la page d'inscription au nom complet
class SignupNamePage extends StatefulWidget {
  const SignupNamePage({super.key});

  @override
  State<SignupNamePage> createState() => _SignupNamePageState();
}

// 🎯 État associé à la page
class _SignupNamePageState extends State<SignupNamePage> {
  // 🧠 Contrôleurs pour les champs de texte
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  // 🎯 FocusNodes pour gérer le focus clavier entre les champs
  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    signupController.currentStepRoute.value = '/signup/name'; // ✅ Étape actuelle
     final provider = signupController.getField('provider');
      if (provider != 'email') {
    _preFillNameFromFirebase();
  } // 🪄 Préremplir automatiquement les champs si nom existant dans Firebase
  }

  /// 🔄 Préremplit le nom/prénom depuis Firebase si disponible (Google, Apple...)
  void _preFillNameFromFirebase() {
    final user = FirebaseAuth.instance.currentUser; // 🔐 Récupère l'utilisateur actuel connecté
    if (user != null && user.displayName != null) {
      final parts = user.displayName!.split(' '); // ✂️ Découpe du nom complet en parties
      if (parts.isNotEmpty) {
        firstNameController.text = parts.first; // 🖊️ Premier mot = prénom
        if (parts.length > 1) {
          lastNameController.text = parts.sublist(1).join(' '); // 🔁 Le reste = nom
        }
      }
    }
  }

  /// ✅ Validation des champs
  bool _validateAndSave() {
    final firstName = firstNameController.text.trim(); // ✂️ Enlève les espaces
    final lastName = lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      // ❌ Si vide, afficher un message d'erreur
      Get.snackbar('Error', 'Please enter your first and last name.');
      return false;
    }
    // ✅ Enregistrement dans le contrôleur global
    signupController.updateField('firstName', firstName);
    signupController.updateField('lastName', lastName);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 🎨 Thème actuel
    final textTheme = theme.textTheme; // 📝 Thème du texte

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface, // 🎨 Couleur de fond personnalisée
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0), // 📏 Marge intérieure
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 🔄 Alignement à gauche
              children: [
                // 🔙 Flèche retour
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(), // 🔁 Retour à la page précédente
                ),

                const SizedBox(height: 10), // 🕳️ Espace vertical

                // 🧑‍💼 Titre de la page
                Text(
                  "What is \nyour name?",
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, // 💪 Titre en gras
                  ),
                ),
                const SizedBox(height: 30), // 🕳️ Espace vertical

                // 🧍‍♂️ Champ prénom
                CustomTextField(
                  controller: firstNameController, // 🖊️ Lien avec le contrôleur
                  hintText: 'Firstname', // 🧠 Placeholder
                  isTransparent: true, // 🧼 Fond transparent
                  focusNode: firstNameFocus, // 🎯 Focus automatique
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(lastNameFocus), // ➡️ Passe au champ suivant
                ),
                const SizedBox(height: 16), // 🕳️ Espace vertical

                // 🧍‍♂️ Champ nom
                CustomTextField(
                  controller: lastNameController,
                  hintText: 'Lastname',
                  isTransparent: true,
                  focusNode: lastNameFocus,
                ),

                const Spacer(), // 📏 Espace automatique pour pousser le bouton vers le bas

                // ➡️ Bouton flèche "Continuer"
                Align(
                  alignment: Alignment.centerRight, // ↘️ Aligné en bas à droite
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary, // 🎨 Couleur du bouton
                      shape: BoxShape.circle, // ⭕ Forme arrondie
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white), // ➡️ Flèche blanche
                      iconSize: 32, // 🔍 Taille du bouton
                      onPressed: () {
                        if (_validateAndSave()) {
                          // ✅ Si valide, aller à la prochaine page
                          Get.toNamed('/signup/contact'); // 🧭 Navigation via GetX
                        }
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
}
