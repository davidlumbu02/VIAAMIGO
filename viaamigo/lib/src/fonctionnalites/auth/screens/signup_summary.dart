// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ajouté pour les types d'erreurs Firebase
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart'; // Ajouté pour précharger les données
import 'package:viaamigo/shared/collections/users/model/verification_statut_model.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
 // Corrigé le nom du service

import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

/// Écran de résumé et confirmation finale du processus d'inscription
/// Permet à l'utilisateur de vérifier ses informations et d'accepter les conditions
class SignupSummaryPage extends StatefulWidget {
  const SignupSummaryPage({super.key});

  @override
  State<SignupSummaryPage> createState() => _SignupSummaryPageState();
}

class _SignupSummaryPageState extends State<SignupSummaryPage> {
  // Services injectés via GetX
  final AuthService authenticationService = Get.find<AuthService>();
  //controller d'inscription
  final SignupController signupController = Get.find<SignupController>();
  final UserController userController = Get.find<UserController>();

  // Tenter de trouver le UserController s'il existe déjà dans l'app
 // UserController? get userController => 
  //    Get.isRegistered<UserController>() ? Get.find<UserController>() : null;

  // Variables réactives pour gérer l'état de l'UI
  final RxBool acceptsTerms = false.obs; // L'utilisateur accepte les conditions
  final RxBool isLoading = false.obs;   // Indicateur de chargement
  final RxString errorMessage = ''.obs; // Message d'erreur

  // Booléens pour vérifier si l'utilisateur a ouvert et lu les documents
  final RxBool hasOpenedTerms = false.obs;
  final RxBool hasOpenedPrivacy = false.obs;

  // Calcul dynamique : l'utilisateur peut accepter uniquement s'il a lu les deux documents
  bool get canAccept => hasOpenedTerms.value && hasOpenedPrivacy.value;

  @override
  void initState() {
    super.initState();
    // Réinitialiser les états au chargement de la page
    signupController.currentStepRoute.value = '/signup/summary';
    acceptsTerms.value = false;
    hasOpenedTerms.value = false;
    hasOpenedPrivacy.value = false;
    errorMessage.value = '';
  }

  /// Crée le compte utilisateur et configure les données dans Firestore
/// 📩 Fonction pour créer un compte utilisateur dans Firebase Auth + Firestore/// 📩 Fonction complète pour créer un compte utilisateur dans Firebase Authentication + Firestore
Future<void> _createAccount() async {
  print("🚀 DÉMARRAGE _createAccount");

  if (!acceptsTerms.value) {
    Get.snackbar("Error", "You must accept the terms to continue.");
    print("❌ L'utilisateur n'a pas accepté les conditions");
    return;
  }

  signupController.updateField('acceptsTerms', true);
  isLoading.value = true;
  errorMessage.value = '';

  try {
    final email = signupController.getField('email');
    final password = signupController.getField('password');
    final firstName = signupController.getField('firstName');
    final lastName = signupController.getField('lastName');
    final phone = signupController.getField('phone');
    final role = signupController.getField('role');
    final birthdayRaw = signupController.getField('birthday');
    final provider = signupController.getField('provider');
    final profilePicture = signupController.getField('profilePicture');
    final language = signupController.getField('language');

    print("📥 Données récupérées :");
    print("Email: $email, Password: $password");
    print("FirstName: $firstName, LastName: $lastName");
    print("Phone: $phone, Role: $role, Provider: $provider, ProfilePicture: $profilePicture, Language: $language");

    DateTime? birthday;
    if (birthdayRaw is DateTime) {
      birthday = birthdayRaw;
    } else if (birthdayRaw is String) {
      try {
        birthday = DateTime.parse(birthdayRaw);
      } catch (e) {
        print('⚠️ Erreur parsing birthday: $e');
      }
    }

    //UserCredential? userCredential;
    print("Provider: $provider");

    User? user;

if (provider == 'email') {
  print("🧪 Tentative création compte Firebase...");
  final credential = await authenticationService.signUpWithEmailPassword(email, password);
  user = credential?.user;
  print('✅ Firebase account created: ${user?.uid}');
} else {
  user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("No authenticated user found for provider: $provider");
  }
  print('✅ Utilisateur déjà connecté via $provider: ${user.uid}');
}


    if (user != null) {
      //final user = userCredential.user!;
      final uid = user.uid;

      final detectedProvider = user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'email';
      print("🔍 Provider détecté: $detectedProvider");

      final userExists = await userController.userExists(uid);
      print("👀 Document Firestore existe déjà ? $userExists");

      if (!userExists) {
        try {
          await FirebaseAuth.instance.currentUser!.getIdToken(true);
          print('🧪 Type de role: ${role.runtimeType} ➜ Valeur: $role');
          await userController.createNewUser(
            uid: uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            role: role,
            provider: detectedProvider,
            emailVerified: user.emailVerified,
            profilePicture: profilePicture,
            language: language,
          );
          print('✅ Firestore user created');
          await userController.initializeUserStructure(uid);
          print('✅ Firestore user structure initialized');
        } catch (e) {
          print('❌ Failed to create Firestore user: $e');
          rethrow;
        }
      }

      try {
        final oldUser = await userController.getUserById(uid);
        print("📦 Ancien user chargé: ${oldUser?.email}");

        if (oldUser != null) {
          await userController.createOrUpdateUser(
            oldUser.copyWith(
              birthday: birthday,
              verificationStatus: VerificationStatus(
                emailVerificationReminders: [],
                phoneVerificationReminders: [],
                documentVerificationStatus: 'pending',
                documentVerificationFeedback: '',
                lastVerificationAttempt: Timestamp.now(),
              ),
            ),
          );
          print('✅ Informations utilisateur complétées');
        }
      } catch (e) {
        print('❌ Failed to update user with extra fields: $e');
      }

      print("📨 Envoi email vérification...");
      await authenticationService.sendEmailVerification();
      print("✅ Email envoyé");

      try {
        await userController.fetchUserData();
        print("✅ Données utilisateur rechargées");
      } catch (e) {
        print('❌ Error preloading user data: $e');
      }

      Get.snackbar("Success", "Account created successfully ✅\nVerification email sent to $email");
      print("🎉 Account flow complete, redirecting to dashboard...");
      Get.offAllNamed('/dashboard');
    } else {
      throw Exception("Failed to create account. Please try again.");
    }
  } catch (e, stackTrace) {
    String errorMsg = "Failed to create account";

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = "This email is already in use.";
          break;
        case 'weak-password':
          errorMsg = "The password is too weak.";
          break;
        case 'invalid-email':
          errorMsg = "The email is invalid.";
          break;
        case 'operation-not-allowed':
          errorMsg = "Email/password not allowed.";
          break;
        default:
          errorMsg = e.message ?? errorMsg;
      }
    } else {
      errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
    }

    errorMessage.value = errorMsg;
    Get.snackbar("Error", errorMsg);
    print('❌ Account creation error: $e');
    print('🧵 Stack trace: $stackTrace');
  } finally {
    isLoading.value = false;
    print("⏹ Chargement terminé");
  }
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final data = signupController.data; // Récupérer les données du controller

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la page
                const SizedBox(height: 10),
                Text(
                  "🧾 Review your info",
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Cartes récapitulatives des informations
                _buildSummaryCard("Name", "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"),
                _buildSummaryCard("Email", data['email'] ?? '-'),
                _buildSummaryCard("Phone", data['phone'] ?? '-'),
                _buildSummaryCard("Birthday", 
                    data['birthday'] != null 
                        ? (data['birthday'] is DateTime 
                            ? "${data['birthday']?.day}/${data['birthday']?.month}/${data['birthday']?.year}"
                            : data['birthday'].toString().split(' ').first) 
                        : '-'),
                _buildSummaryCard("Role", 
                    (data['role'] as String?)?.capitalizeFirst ?? '-'),

                //if (data['password'] != null)
                 // _buildSummaryCard(data['password'] , '••••••••••'),

                // Afficher un message d'erreur si présent
                Obx(() => errorMessage.value.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(height: 20)), // Espace si pas d'erreur

                // Case à cocher pour accepter les conditions
                Obx(() => CheckboxListTile(
                      enabled: canAccept, // Désactivée si l'utilisateur n'a pas lu les documents
                      value: acceptsTerms.value,
                      onChanged: (val) {
                        if (canAccept) {
                          acceptsTerms.value = val ?? false;
                        } else {
                          Get.snackbar(
                            "Please read first", 
                            "You must open both Terms and Privacy Policy to continue.",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text.rich(
                        TextSpan(
                          text: "I accept the ",
                          style: textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(204),
                          ),
                          children: [
                            // Lien vers les conditions d'utilisation
                            TextSpan(
                              text: "Terms of Use",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                decoration: TextDecoration.underline,
                                color: canAccept
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withAlpha(179),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.toNamed('/terms');
                                  hasOpenedTerms.value = true; // Marquer comme lu
                                },
                            ),
                             TextSpan(text: " and ", style: textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(204),
                          )),
                            // Lien vers la politique de confidentialité
                            TextSpan(
                              text: "Privacy Policy",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                decoration: TextDecoration.underline,
                                color: canAccept
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withAlpha(179),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.toNamed('/privacy');
                                  hasOpenedPrivacy.value = true; // Marquer comme lu
                                },
                            ),
                             TextSpan(text: ".",style: textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(204),
                          )),
                          ],
                        ),
                      ),
                    )),

                const Spacer(), // Pousse le bouton vers le bas

                // Bouton de création de compte
                Obx(() => MyButton(
                      text: isLoading.value ? "Creating account..." : "Create account",
                      isLoading: isLoading.value,
                      width: double.infinity,
                      height: 50,
                      borderRadius: 35,
                      onTap: isLoading.value ? null : _createAccount, // Éviter les clics multiples
                      isDisabled: !acceptsTerms.value, // Désactiver si conditions non acceptées
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget personnalisé pour afficher une carte d'information
  /// @param label Étiquette du champ (côté gauche)
  /// @param value Valeur du champ (côté droit)
  Widget _buildSummaryCard(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // Couleur légère avec transparence
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Étiquette (label) du champ
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            )
          ),
          // Valeur du champ avec style plus prononcé
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )
          ),
        ],
      ),
    );
  }
}
