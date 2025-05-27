// ignore_for_file: unused_element
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/fonctionnalites/auth/models/forget_password_model_bottom_sheet.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

/// Page d'accueil pour la connexion des utilisateurs
/// Comprend:
/// - Formulaire de connexion email/mot de passe
/// - Options de connexion via réseaux sociaux
class WelcomePageSignintest extends StatefulWidget {
  const WelcomePageSignintest({super.key});

  @override
  State<WelcomePageSignintest> createState() => _WelcomePageStateSignintest();
}

class _WelcomePageStateSignintest extends State<WelcomePageSignintest> {
  // ✅ AuthService global via GetX
  final AuthService authenticationService = Get.find<AuthService>();

  // ✅ Champs de saisie
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;     // ⏳ Pour afficher le loader pendant la connexion
  bool usePhone = false;      // 🔁 Bascule Email ↔ Téléphone

  @override
  void initState() {
    super.initState();
    // L'animation a été supprimée, donc pas besoin d'appeler _startTyping() ici
  }

  /// ✅ Fonction de connexion avec email et mot de passe
  /// 🔐 Sign in the user using email and password
  Future<void> _handleLogin() async {
    final contact = contactController.text.trim();    // 🧹 Clean up the input
    final password = passwordController.text.trim();

    // 🛡️ Validate fields
    if (contact.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Missing fields',
        'Please fill in the email and password.',
        
        backgroundColor: Colors.red.withAlpha(25),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => isLoading = true); // ⏳ Show loader

    try {
      // 🔐 Attempt Firebase sign-in
      final userCredential = await authenticationService.signInWithEmailPassword(contact, password);

      if (userCredential != null) {
        // 🔄 Load user's Firestore data
        await Get.find<UserController>().fetchUserData();

        // 🎉 Show success message
        Get.snackbar(
          'Connexion réussie',
          'Bienvenue sur ViaAmigo 👋',
          backgroundColor: Colors.green.withAlpha(25),
          colorText: Colors.green,
        );

        // 🔁 Redirect to dashboard
        Get.offAllNamed('/dashboard');
        return;
      }

      // ⚠️ Fallback error if signIn returns null
      Get.snackbar(
        'Erreur inattendue',
        'Impossible de se connecter. Veuillez réessayer plus tard.',
        backgroundColor: Colors.red.withAlpha(25),
        colorText: Colors.red,
      );

    } catch (e) {
      // 🔍 Interpret FirebaseAuth errors
      String errorMessage = 'Une erreur s\'est produite lors de la connexion.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Aucun compte trouvé pour cet email.';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect. Veuillez réessayer.';
            break;
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide.';
            break;
          case 'user-disabled':
            errorMessage = 'Ce compte a été désactivé.';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives échouées. Veuillez réessayer plus tard.';
            break;
          case 'network-request-failed':
            errorMessage = 'Erreur réseau. Veuillez vérifier votre connexion.';
            break;
          case 'invalid-credential':
            errorMessage = 'Identifiants invalides ou expirés.';
            break;
          default:
            errorMessage = 'Erreur d\'authentification: ${e.code}';
        }
      }

      // ❌ Show user-friendly error
      Get.snackbar(
        'Échec de connexion',
        errorMessage,
        backgroundColor: Colors.red.withAlpha(25),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );

      // 🧪 Log full error in console for debugging
      print('Detailed login error: $e');

    } finally {
      // ✅ Hide loader
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Libérer les contrôleurs de texte
    contactController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  // Récupération des dimensions de l'écran pour calculs responsifs
  final size = MediaQuery.of(context).size;
  final isTablet = size.width > 600;  // Détection tablette
  //final isLandscape = size.width > size.height;  // Détection mode paysage
  
  // Calcul des espacements dynamiques selon la taille d'écran
  final verticalSpacing = size.height * 0.015;  // 1.5% de la hauteur
  final horizontalPadding = size.width * 0.05;  // 5% de la largeur
  final buttonHeight = size.height * 0.06;  // 6% de la hauteur pour les boutons

  return ThemedScaffoldWrapper(
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: OrientationBuilder(  // Ajout d'OrientationBuilder pour gérer l'orientation
          builder: (context, orientation) {
            // Layout différent selon l'orientation et le type d'appareil
            if (orientation == Orientation.landscape && !isTablet) {
              // Disposition horizontale pour téléphones en mode paysage
              return Row(
                children: [
                  // Partie gauche avec titre statique et navigation
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Get.back(),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'ViaAmigo', // Texte statique au lieu de l'animation
                                  style: textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Partie droite avec formulaire et boutons sociaux
                  Expanded(
                    flex: 7,
                    child: _buildMainContent(
                      context, 
                      theme, 
                      textTheme, 
                      buttonHeight, 
                      verticalSpacing,
                      horizontalPadding,
                      true,  // Mode paysage
                    ),
                  ),
                ],
              );
            } else {
              // Disposition verticale standard pour mode portrait ou tablettes
              return Column(
                children: [
                  // Bouton retour
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  
                  // Zone de texte statique (plus d'animation)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, 
                      vertical: verticalSpacing
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ViaAmigo', // Texte statique au lieu de l'animation
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: isTablet ? 42 : 30, // Taille selon appareil
                        ),
                      ),
                    ),
                  ),
                  
                  // Contenu principal (formulaire + boutons sociaux)
                  Expanded(
                    child: _buildMainContent(
                      context, 
                      theme, 
                      textTheme,
                      buttonHeight,
                      verticalSpacing,
                      horizontalPadding,
                      false,  // Mode portrait
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    ),
  );
}

// Méthode extraite pour le contenu principal (inchangée)
Widget _buildMainContent(
  BuildContext context, 
  ThemeData theme, 
  TextTheme textTheme, 
  double buttonHeight,
  double verticalSpacing,
  double horizontalPadding,
  bool isLandscape,
) {
  final size = MediaQuery.of(context).size;
  final isTablet = size.width > 600;
  
  return Column(
    children: [
      // Formulaire de connexion
      Expanded(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: verticalSpacing * 2),
                
                // Email ou Téléphone
                CustomTextField(
                  key: ValueKey(usePhone),
                  controller: contactController,
                  hintText: usePhone ? 'Numéro de téléphone' : 'Email',
                  keyboardType: usePhone ? TextInputType.phone : TextInputType.emailAddress,
                  isTransparent: true,
                ),
            
                SizedBox(height: verticalSpacing),
            
                // Mot de passe
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  isTransparent: true,
                ),
            
                SizedBox(height: verticalSpacing*2),
            
                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ForgetPasswordModelBottomSheetScreen.buildShowModalBottomSheet(context);
                    },
                    child: Text(
                      'Forgot your password ?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                ),
            
                SizedBox(height: verticalSpacing*2),
            
                // Bouton Continuer
                MyButton(
                  text: isLoading ? 'Connexion...' : 'Continue',
                  width: double.infinity,
                  height: buttonHeight,
                  borderRadius: 30,
                  onTap: _handleLogin,
                  isLoading: isLoading,
                ),
            
                SizedBox(height: isTablet ? verticalSpacing * 4 : verticalSpacing * 7),
                
                // Autres méthodes de connexion
                Center(
                  child: Text(
                    'OTHER SIGN IN METHODS',
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: isTablet ? 18 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                SizedBox(height: verticalSpacing * 2),
              ],
            ),
          ),
        ),
      ),

      // Zone des boutons d'authentification sociale (inchangée)
      Container(
        width: double.infinity,
        padding:  const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Plus large pour tablettes
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bouton Google
              buildButtonTextLogo(
                context,
                label: 'Continue with Google',
                iconAsset: 'assets/logo/google.png',
                height: buttonHeight,
                isFilled: false,
                alignIconStart: true,
                borderRadius: 30,
                onTap: () async {
                  setState(() => isLoading = true);
                  signupController.resetAll();
                  try {
                    final userCredential = await authenticationService.signInWithGoogle();
                    final user = userCredential?.user;

                    if (user != null) {
                      final uid = user.uid;
                      final exists = await Get.find<UserController>().userExists(uid);

                      if (exists) {
                        await Get.find<UserController>().fetchUserData();
                        Get.offAllNamed('/dashboard');
                      } else {
                        final signupController = Get.find<SignupController>();
                        signupController.updateField('provider', "google");
                        signupController.updateField('profilePicture', user.photoURL ?? '');
                        signupController.updateField('email', user.email ?? '');

                        Get.offAllNamed('/signup/name');
                      }
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      'Échec de connexion avec Google: ${e.toString()}',
                      backgroundColor: Colors.red.withAlpha(25),
                      colorText: Colors.red,
                    );
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                },
              ),
              
                const SizedBox(height: 10),
                // Bouton Apple
                buildButtonTextLogo(
                  context,
                  label: 'Continue with Apple',
                  height: buttonHeight,
                  iconAsset: theme.brightness == Brightness.dark
                      ? 'assets/logo/whiteapple.png'
                      : 'assets/logo/apple.png',  
                  isFilled: false,
                  alignIconStart: true,
                  onTap: () async {
                    setState(() => isLoading = true);
                    signupController.resetAll();
                    try {
                      final userCredential = await authenticationService.signInWithApple();
                      final user = userCredential?.user;

                      if (user != null) {
                        final uid = user.uid;
                        final exists = await Get.find<UserController>().userExists(uid);

                        if (exists) {
                          await Get.find<UserController>().fetchUserData();
                          Get.offAllNamed('/dashboard');
                        } else {
                          final signupController = Get.find<SignupController>();
                          signupController.updateField('provider', "apple");
                          signupController.updateField('profilePicture', user.photoURL ?? '');
                          signupController.updateField('email', user.email ?? '');

                          Get.offAllNamed('/signup/name');
                        }
                      }
                    } catch (e) {
                      Get.snackbar(
                        'Erreur',
                        'Échec de connexion avec Apple: ${e.toString()}',
                        backgroundColor: Colors.red.withAlpha(25),
                        colorText: Colors.red,
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                ),

                const SizedBox(height: 10),
                
                // Bouton Facebook
                buildButtonTextLogo(
                  context,
                  label: 'Continue with Facebook',
                  iconAsset: 'assets/logo/fb.png',
                  alignIconStart: true,
                  height: buttonHeight,
                  isFilled: false,
                  onTap: () {
                    signupController.resetAll();
                    // Fonctionnalité Facebook non implémentée
                    Get.snackbar(
                      'Non disponible', 
                      'La connexion via Facebook n\'est pas encore disponible',
                      backgroundColor: Colors.amber.withAlpha(25),
                      colorText: Colors.amber[800],
                    );
                  },
                ),
                  const SizedBox(height: 10),
                // Bouton Inscription (redirection)
                buildButtonTextLogo(
                  context,
                  label: 'Signup',
                  height: buttonHeight,
                  outlined: false,
                  onTap: () => Get.toNamed('/welcomePageSignup'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

}
