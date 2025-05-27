import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class SignupVerifyPage extends StatefulWidget {
  const SignupVerifyPage({super.key});

  @override
  State<SignupVerifyPage> createState() => _SignupVerifyPageState();
}

class _SignupVerifyPageState extends State<SignupVerifyPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? verificationId; // Identifiant de vérification fourni par Firebase
  int? resendToken;       // Jeton pour le renvoi du code
  String otpCode = "";    // Code entré par l'utilisateur
  bool isCodeSent = false; // État : code envoyé ?
  bool isLoading = false;  // Chargement pendant la vérification ?
  bool showSuccessCheck = false; // Animation de succès
  bool canResend = false;        // Est-ce qu'on peut renvoyer un code ?

  late AnimationController checkAnimation;

  @override
void initState() {
  super.initState();
  signupController.currentStepRoute.value = '/signup/verify';

  // 🛠️ Initialiser l'animation tout de suite
  checkAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // ✅ Ensuite seulement, vérifier si déjà vérifié
  /*if (_auth.currentUser?.phoneNumber != null) {
    _onSuccess();
    return;
  }*/
final phoneVerified = signupController.getField('phoneVerified') == true;
final alreadyLinked = _auth.currentUser?.phoneNumber != null;

if (alreadyLinked && phoneVerified) {
  _onSuccess();
  return;
}


  _startPhoneVerification();
}

  @override
  void dispose() {
    checkAnimation.dispose(); // 🧹 Libère l'animation
    super.dispose();
  }

  /// 🚀 Démarre la vérification du numéro de téléphone avec Firebase Auth
  Future<void> _startPhoneVerification() async {
    final phone = signupController.getField('phone');
    if (phone == null || !phone.startsWith('+')) {
      Get.snackbar('Error', 'Invalid phone number format. Must include country code.');
      return;
    }

    setState(() {
      isCodeSent = false;
      otpCode = "";       // 🔄 On réinitialise l'ancien code
      canResend = false;  // 🔐 Bloque l’envoi pendant 30s
    });

    // ⏱️ Timer de 30s avant d'autoriser le renvoi
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => canResend = true);
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // ✅ Vérification automatique (Android)
        await _auth.currentUser?.linkWithCredential(credential);
        _onSuccess();
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.snackbar('Error', e.message ?? 'Verification failed');
      },
      codeSent: (String verId, int? newResendToken) {
        setState(() {
          verificationId = verId;
          resendToken = newResendToken;
          isCodeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  /// 📩 Vérifie le code saisi manuellement
  Future<void> _verifyCode() async {
    if (verificationId == null || otpCode.length < 6) {
      Get.snackbar('Error', 'Code incomplete or expired.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpCode.trim(),
      );

      await _auth.currentUser?.linkWithCredential(credential);
      _onSuccess();
   } on FirebaseAuthException catch (e) {
  if (e.code == 'invalid-verification-code') {
    Get.snackbar('Code invalide', 'Le code entré est incorrect.');
  } else if (e.code == 'credential-already-in-use') {
    Get.snackbar('Erreur', 'Ce numéro est déjà lié à un autre compte.');
  } else {
    Get.snackbar('Erreur', e.message ?? 'Erreur inconnue');
  }
}
 finally {
      setState(() => isLoading = false);
    }
  }

  /// ✅ Action effectuée après succès de vérification
  void _onSuccess() {
    signupController.isPhoneVerified.value = true;
    signupController.updateField('phoneVerified', true);
    setState(() => showSuccessCheck = true);
    checkAnimation.forward();
    Get.snackbar('Success', 'Phone number verified!');
    Future.delayed(const Duration(seconds: 1), () {
      Get.toNamed('/signup/summary'); // ⏭️ Étape suivante
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
     final data = signupController.data; 

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔙 Retour
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Get.back(),
                          ),
                          const SizedBox(height: 10),

                          // 🧾 Titre
                          Text(
                            "Verify your phone number",
                            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // 📱 Info téléphone
                          Text("A 6-digit code was sent to:"),
                          Text(
                              data['phone'] ?? '-',
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          // 🔘 Rôle sélectionné (juste pour info visuelle)
                          Text("Selected role:",
                              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          Text(
                              (data['role'] as String?)?.capitalizeFirst ?? '-',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 40),

                          // ⌛ Statut / Champ de code
                          if (!isCodeSent)
                            const Center(child: Text("Waiting for code..."))
                          else if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: OtpTextField(
                                  numberOfFields: 6,
                                  borderColor: theme.colorScheme.primary,
                                  focusedBorderColor: theme.colorScheme.primary,
                                  showFieldAsBox: true,
                                  filled: false,
                                  fillColor: Colors.black.withAlpha(13),
                                  fieldWidth: 45,
                                  borderRadius: BorderRadius.circular(8),
                                  onSubmit: (code) {
                                    setState(() => otpCode = code);
                                  },
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // 🔁 Bouton renvoi de code
                          if (canResend)
                            TextButton(
                              onPressed: _startPhoneVerification,
                              child: const Text("Resend code"),
                            ),

                          const Spacer(),

                          // ✅ Icône animée ou bouton continuer
                          if (showSuccessCheck)
                            Center(
                              child: ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: checkAnimation,
                                  curve: Curves.easeOutBack,
                                ),
                                child: Icon(Icons.check_circle,
                                    color: theme.colorScheme.primary, size: 80),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(50),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                  iconSize: 32,
                                  onPressed: isLoading ? null : _verifyCode, // 🔒 Désactivé si en cours
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

 
}
