// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart'; // Ton champ réutilisable
import 'package:viaamigo/shared/controllers/signup_controller.dart'; // Pour stocker les infos
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart'; // Enveloppe thème

// Page d'inscription – Choix du mot de passe
class SignupPasswordPage extends StatefulWidget {
  const SignupPasswordPage({super.key});

  @override
  State<SignupPasswordPage> createState() => _SignupPasswordPageState();
}

class _SignupPasswordPageState extends State<SignupPasswordPage> {
  // 🎯 Contrôleurs des champs
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  // 🔁 FocusNode pour navigation clavier
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmFocus = FocusNode();

  // 🔐 Déterminer si on doit sauter l'étape du mot de passe (si provider = Google/Apple/etc.)
bool get shouldSkipPassword {
  final provider = signupController.getField('provider');
  return provider != null && provider != 'email';
}


  @override
  void initState() {
    super.initState();
    signupController.currentStepRoute.value = '/signup/password';
  print("🔍 Provider au moment de /signup/password: ${signupController.getField('provider')}");
    // 🚀 Si l’utilisateur s’est inscrit via un fournisseur externe, on saute cette étape
    /*if (shouldSkipPassword) {
      Future.delayed(Duration.zero, () {
        Get.toNamed('/signup/birthday');
      });
    }*/
  }

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (shouldSkipPassword) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed('/signup/birthday');
    });
  }
}

  /// ✅ Valider que les champs sont remplis correctement
  bool _validateAndSave() {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (password.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters.');
      return false;
    }
    if (confirm != password) {
      Get.snackbar('Error', 'Passwords do not match.');
      return false;
    }

    // 🧠 Sauvegarder dans le controller global
    signupController.updateField('password', password);
    print("🔒 Mot de passe enregistré dans le controller: ${signupController.getField('password')}");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // ⛔ Si on doit sauter cette étape, on retourne un widget vide
    if (shouldSkipPassword) return const SizedBox.shrink();

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Flèche retour
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(height: 10),

                // 🧾 Titre principal
                Text(
                  "Choose a password \nto protect your account",
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // 🔑 Champ mot de passe (avec affichage/masquage géré par CustomTextField)
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true, // ✅ Le champ gère nativement le toggle dans ton widget
                  isTransparent: true,
                  focusNode: passwordFocus,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(confirmFocus),
                ),
                const SizedBox(height: 16),

                // 🔑 Champ confirmation mot de passe
                CustomTextField(
                  controller: confirmController,
                  hintText: 'Confirm password',
                  obscureText: true,
                  isTransparent: true,
                  focusNode: confirmFocus,
                ),
                const SizedBox(height: 16),

                // ℹ️ Info sécurité
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "This password will be used to log in and recover your account. It must contain at least 6 characters.",
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    softWrap: true,
                  ),
                ),

                const Spacer(), // ⬇️ pousse le bouton vers le bas

                // ➡️ Bouton "continuer"
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      iconSize: 32,
                      onPressed: () {
                        if (_validateAndSave()) {
                          Get.toNamed('/signup/birthday'); // ⏭️ Aller à l'étape suivante
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
