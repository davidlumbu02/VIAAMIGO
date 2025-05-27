import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
//import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/fonctionnalites/auth/models/forget_password_model_bottom_sheet.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ✅ AuthService global via GetX
  final AuthService authService = Get.find<AuthService>();

  // ✅ Champs de saisie
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;     // ⏳ Pour afficher le loader pendant la connexion
  bool usePhone = false;      // 🔁 Bascule Email ↔ Téléphone

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// ✅ Fonction de connexion
/// ✅ Fonction de connexion avec email et mot de passe
/// 🔐 Sign in the user using email and password
Future<void> _handleLogin() async {
  final contact = contactController.text.trim();    // 🧹 Clean up the input
  final password = passwordController.text.trim();

  // 🛡️ Validate fields
  if (contact.isEmpty || password.isEmpty) {
    Get.snackbar(
      'Missing Information',
      'Please fill in both email and password.',
      backgroundColor: Colors.red.withAlpha(25),
      colorText: Colors.red,
    );
    return;
  }

  setState(() => isLoading = true); // ⏳ Show loader

  try {
    // 🔐 Attempt Firebase sign-in
    final userCredential = await authService.signInWithEmailPassword(contact, password);

    if (userCredential != null) {
      // 🔄 Load user's Firestore data
      await Get.find<UserController>().fetchUserData();

      // 🎉 Show success message
      Get.snackbar(
        'Login Successful',
        'Welcome back to ViaAmigo 👋',
        backgroundColor: Colors.green.withAlpha(25),
        colorText: Colors.green,
      );

      // 🔁 Redirect to dashboard
      Get.offAllNamed('/dashboard');
      return;
    }

    // ⚠️ Fallback error if signIn returns null
    Get.snackbar(
      'Unexpected Error',
      'Unable to log in. Please try again later.',
      backgroundColor: Colors.red.withAlpha(25),
      colorText: Colors.red,
    );

  } catch (e) {
    // 🔍 Interpret FirebaseAuth errors
    String errorMessage = 'An error occurred during login.';

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid or expired credentials.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.code}';
      }
    }

    // ❌ Show user-friendly error
    Get.snackbar(
      'Login Failed',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500), // 📱 Responsive mobile / tablette
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 🔷 Logo + Nom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          theme.brightness == Brightness.dark
                              ? 'assets/logo/LOGOBLANC.png'
                              : 'assets/logo/LOGONOIR.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ViaAmigo',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
      
                    const SizedBox(height: 30),
      
                    // 📩 Email ou 📞 Téléphone
                    CustomTextField(
                      key: ValueKey(usePhone),
                      controller: contactController,
                      hintText: usePhone ? 'Phone number' : 'Email address',
                      keyboardType: usePhone ? TextInputType.phone : TextInputType.emailAddress,
                      isTransparent: true,
                    ),
      
                    const SizedBox(height: 20),
      
                    // 🔒 Mot de passe
                    CustomTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      isTransparent: true,
                    ),
      
                    const SizedBox(height: 12),
      
                    // 🔗 Lien : Mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ForgetPasswordModelBottomSheetScreen.buildShowModalBottomSheet(context);
                        },
                        child: Text(
                          'Forgot password ?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
      
                    const SizedBox(height: 12),
      
                    // ✅ Bouton principal "Continuer"
                    MyButton(
                      text: isLoading ? 'Connexion...' : 'Continue',
                      width: double.infinity,
                      height: 45,
                      borderRadius: 30,
                      onTap: _handleLogin,
                      isLoading: isLoading,
                    ),
      
                    const SizedBox(height: 12),
      
                    // 🧾 Lien vers page d'inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('You don\'t have an account ?', style: textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            Get.toNamed('/welcomePageSignup');
                          },
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
      
                    const SizedBox(height: 0),
      
                    /*➖ Séparateur "OU"
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text('OR', style: textTheme.bodySmall),
                        ),
                        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                      ],
                    ),
      
                    const SizedBox(height: 16),*/
      
                    // 🔁 Bascule Email ↔ Téléphone
                    /*buildButtonTextLogo(
                      context,
                      borderRadius: 30,
                      height: 50,
                      alignIconStart: true,
                      label: usePhone
                          ? 'Continue with an email'
                          : 'Continue with a phone number',
                      icon: usePhone ? Icons.email_outlined : Icons.phone_outlined,
                      outlined: true,
                      useAltBorder: true,
                      onTap: () {
                        setState(() => usePhone = !usePhone);
                      },
                    ),*/
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
