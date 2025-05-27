// ignore_for_file: avoid_print

// 📦 Importations des bibliothèques nécessaires
import 'package:flutter/material.dart'; // UI de Flutter
import 'package:get/get.dart'; // Navigation et gestion d'état réactif
import 'package:firebase_auth/firebase_auth.dart'; // Authentification Firebase
import 'package:intl_phone_field/intl_phone_field.dart'; // Champ de numéro de téléphone international
import 'package:lucide_icons/lucide_icons.dart'; // Icônes stylées
import 'package:viaamigo/shared/widgets/custom_text_field.dart'; // Champ personnalisé
import 'package:viaamigo/shared/controllers/signup_controller.dart'; // Contrôleur d'inscription
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart'; // Wrapper pour la gestion du thème

// 🧾 Page d'inscription – contact
class SignupContactPage extends StatefulWidget {
  const SignupContactPage({super.key});

  @override
  State<SignupContactPage> createState() => _SignupContactPageState();
}

class _SignupContactPageState extends State<SignupContactPage> {
  // 📧 Contrôleur du champ email
  final TextEditingController emailController = TextEditingController();

  // 📱 Numéro de téléphone complet (réactif)
  final Rx<String?> completePhoneNumber = Rx<String?>(null);

  // 🔕 Option de refus des offres promotionnelles
  final RxBool refuseOffers = false.obs;

  // ✅ Variables de validation
  final RxBool isEmailValid = false.obs;
  final RxBool isPhoneValid = false.obs;
  final RxBool isValidating = false.obs;

  // ❌ Messages d'erreur
  final RxString emailError = ''.obs;
  final RxString phoneError = ''.obs;

  @override
  void initState() {
    super.initState();
    signupController.currentStepRoute.value = '/signup/contact'; // ✅ Étape courante
    _preFillContactFromFirebase(); // 🪄 Préremplir depuis Firebase si dispo

    // 🔁 Écouter les changements dans le champ email pour le valider en live
    emailController.addListener(() {
      _validateEmail(emailController.text);
    });
  }

  @override
  void dispose() {
    emailController.dispose(); // 🧹 Nettoyage pour éviter les leaks
    super.dispose();
  }

  /// 🔄 Préremplir les données de contact depuis Firebase Auth ou le contrôleur local
  void _preFillContactFromFirebase() {
    final user = FirebaseAuth.instance.currentUser; // 🔐 Utilisateur connecté
    if (user != null && user.email != null) {
      emailController.text = user.email!;
      _validateEmail(user.email!); // 🧪 Validation immédiate
    }

    // 📲 Remplissage du numéro s'il a été déjà entré
    if (signupController.hasField('phone')) {
      completePhoneNumber.value = signupController.getField('phone');
      isPhoneValid.value = _isValidPhoneNumber(completePhoneNumber.value);
    }

    // 🔘 Préférence de refus d'offre déjà enregistrée ?
    if (signupController.hasField('refuseOffers')) {
      refuseOffers.value = signupController.getField('refuseOffers') ?? false;
    }
  }

  /// 📱 Validation du numéro de téléphone
  bool _isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    if (phone.length < 8) return false;
    return phone.startsWith('+') &&
        phone.substring(1).replaceAll(RegExp(r'[0-9]'), '').length <= 3;
  }

  /// 📧 Validation de l'email et vérification de disponibilité via Firebase
  void _validateEmail(String email) async {
    final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    bool validFormat = emailRegExp.hasMatch(email);

    isEmailValid.value = false;
    emailError.value = '';

    if (email.isEmpty) {
      emailError.value = 'Email is required';
      return;
    }

    if (!validFormat) {
      emailError.value = 'Please enter a valid email address';
      return;
    }

    // ✅ Si l'email est valide mais différent de celui de l'utilisateur connecté
    if (validFormat && FirebaseAuth.instance.currentUser?.email != email) {
      isValidating.value = true;

      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          emailError.value = 'This email is already in use';
        } else {
          isEmailValid.value = true;
        }
      } catch (e) {
        print('Error checking email: $e');
        isEmailValid.value = true; // ✅ On ne bloque pas
      } finally {
        isValidating.value = false;
      }
    } else if (validFormat) {
      isEmailValid.value = true;
    }
  }

  /// 🧪 Vérifie que tout est OK, puis sauvegarde dans le controller
  bool _validateAndSave() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      emailError.value = 'Email is required';
      return false;
    } else if (!isEmailValid.value) {
      return false;
    }

    if (completePhoneNumber.value == null || completePhoneNumber.value!.isEmpty) {
      phoneError.value = 'Phone number is required';
      return false;
    } else if (!isPhoneValid.value) {
      phoneError.value = 'Please enter a valid phone number';
      return false;
    }

    // ✅ Tous les champs sont bons, on sauvegarde
    signupController.updateField('email', email);
    signupController.updateField('phone', completePhoneNumber.value!.trim());
    signupController.updateField('refuseOffers', refuseOffers.value);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        resizeToAvoidBottomInset: true, // 📱 Recalcule la hauteur si le clavier apparaît
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔙 Retour arrière
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Get.back(),
                          ),
                          const SizedBox(height: 10),

                          // 🧾 Titre principal
                          Text(
                            "Your contact \ninformation",
                            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),

                          // 📧 Champ email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: emailController,
                                hintText: 'Email address',
                                keyboardType: TextInputType.emailAddress,
                                isTransparent: true,
                                errorText: emailError.value.isEmpty ? null : emailError.value,
                              ),
                              // 🟥 Affiche le message d'erreur email si besoin
                              Obx(() => emailError.value.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 4),
                                      child: Text(
                                        emailError.value,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 📱 Champ téléphone
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IntlPhoneField(
                                initialCountryCode: 'CA',
                                initialValue: completePhoneNumber.value?.replaceAll(RegExp(r'^\+\d+'), '') ?? '',
                                decoration: InputDecoration(
                                  labelText: 'Phone number',
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: theme.colorScheme.primary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: theme.colorScheme.error),
                                  ),
                                  labelStyle: textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                style: textTheme.bodyMedium,
                                dropdownTextStyle: textTheme.bodyMedium,
                                onChanged: (phone) {
                                  completePhoneNumber.value = phone.completeNumber;
                                  isPhoneValid.value = _isValidPhoneNumber(phone.completeNumber);
                                  if (isPhoneValid.value) {
                                    phoneError.value = '';
                                  }
                                },
                              ),
                              // 🟥 Affiche l'erreur de téléphone
                              Obx(() => phoneError.value.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 4),
                                      child: Text(
                                        phoneError.value,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ℹ️ Information sur l’utilisation du téléphone
                          Text(
                            "Your phone number will be communicated to the carrier or sender to organise with them the delivery or withdrawal of your package.",
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),

                          // 🔘 Checkbox pour refuser les promotions
                          Obx(() => CheckboxListTile(
                                value: refuseOffers.value,
                                onChanged: (val) => refuseOffers.value = val ?? false,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  "I do not wish to receive special offers or personalized recommendations by email",
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                contentPadding: EdgeInsets.zero,
                              )),
                          const SizedBox(height: 8),

                          // 📝 Explication sur les emails promotionnels
                          Text(
                            "By entering your email address, you agree to receive promotional emails from ViaAmigo. You can unsubscribe by checking the box above, or at any time in your profile settings.",
                            style: textTheme.bodySmall,
                          ),

                          const Spacer(), // ⬇️ Pousse le bouton vers le bas

                          // ⏭️ Bouton continuer
                          Obx(() => Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (isEmailValid.value && isPhoneValid.value && !isValidating.value)
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary.withAlpha(128),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withAlpha(64),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: isValidating.value
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ))
                                        : const Icon(LucideIcons.arrowRight, color: Colors.white),
                                    iconSize: 32,
                                    onPressed: (isEmailValid.value && isPhoneValid.value && !isValidating.value)
                                        ? () {
                                            if (_validateAndSave()) {
                                              Get.toNamed('/signup/password'); // ✅ Navigation à la page suivante
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              )),
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
