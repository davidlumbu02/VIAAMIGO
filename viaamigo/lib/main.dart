import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/badges.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/devices.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/documents.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/driver_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/sender_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/settings.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/travel_patterns.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/vehicules.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/user_devices_controller.dart';

// NOUVEAUX IMPORTS POUR LA NAVIGATION CENTRALISÉE

import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/widgets/app_shell.dart';

import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/services/user_service.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/privacy_page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/terms_page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signin.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signintest.dart';

import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/profile_settings.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings_app.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';
import 'package:viaamigo/utilitaires/translate.dart';

import 'firebase_options.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/Welcome_Page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/forget_password_mail.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/login.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/otp_screen.dart';

import 'package:viaamigo/src/fonctionnalites/auth/screens/signup.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_birth.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_contact.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_name.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_password.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_role.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_summary.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_verify.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/test.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signup.dart';


import 'package:viaamigo/src/fonctionnalites/onboarding/screens/onboarding_screen.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings.dart';
import 'package:viaamigo/src/utilitaires/theme/app_theme.dart';
import 'package:viaamigo/src/utilitaires/theme_controller.dart';


/// Point d'entrée principal de l'application
///
/// Initialise tous les services et contrôleurs nécessaires
/// avant le démarrage de l'interface utilisateur
Future<void> main() async {
  // Nécessaire pour appeler des méthodes natives avant runApp()
  WidgetsFlutterBinding.ensureInitialized();

  //==========================================================
  // INITIALISATION DES SERVICES
  //==========================================================

  // 🔥 Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 📱 Détection de la langue du téléphone
  final deviceLocale = Get.deviceLocale ?? const Locale('en', 'US');
  await Get.updateLocale(deviceLocale);
  FirebaseAuth.instance.setLanguageCode(deviceLocale.languageCode);

  // 🎨 Initialisation du thème
  final themeController = Get.put(ThemeController());
  await themeController.loadThemeMode();

  // 🔐 AuthService (asynchrone)
  await Get.putAsync(() async => AuthService());

  //==========================================================
  // INJECTION DES SERVICES FIRESTORE (AVANT LES CONTRÔLEURS)
  //==========================================================
  
  Get.put(UserService());
  Get.put(UserSettingsService());
  Get.put(VehiclesService());
  Get.put(TravelPatternsService());
  Get.put(DriverPreferencesService());
  Get.put(SenderPreferencesService());
  Get.put(UserDocumentsService());
  Get.put(UserDevicesService());
  Get.put(UserBadgesService());

  //==========================================================
  // INJECTION DES CONTRÔLEURS
  //==========================================================
  
  Get.put(UserDevicesController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(SignupController(), permanent: true);
  
  // 🧭 NOUVEAU: Injection du contrôleur de navigation centralisée
  Get.put(NavigationController(), permanent: true);

  // Configuration de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 🚀 Démarrage de l'application
  runApp(MyApp());
}


/// Widget racine de l'application
///
/// Configure le thème, les traductions et le système de navigation
class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Accès au contrôleur de thème
  final ThemeController themeController = Get.find<ThemeController>();
  
  /// Détermine quelle page afficher au démarrage en fonction de l'authentification
  Widget _determineHomePage() {
    final authService = Get.find<AuthService>();
    
    // Si l'utilisateur est déjà connecté, aller au tableau de bord
    if (authService.isLoggedIn()) {
      // Utiliser AppShell comme conteneur principal pour les utilisateurs authentifiés
      return AppShell();
    } else {
      // Sinon, aller à la page d'accueil/connexion
      return const WelcomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Utiliser Obx pour réagir aux changements de thème
        return Obx(() => GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ViaAmigo',
              
              // Configuration des traductions
              translations: AppTranslation(),
              locale:  Get.locale,
              fallbackLocale: const Locale('fr', 'FR'),
              
              // Configuration du thème (réactif)
              theme: AppTheme.light(context),
              darkTheme: AppTheme.dark(context),
              themeMode: themeController.themeMode.value,
              
              // Configuration des transitions
              defaultTransition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 900),
              
              // Page initiale déterminée dynamiquement selon l'authentification
              home: _determineHomePage(), 
              initialRoute: null, // Pas besoin de route initiale car on utilise 'home'
      // AJOUT ICI: Application globale du ThemedScaffoldWrapper
      builder: (context, child) {
        // Ceci s'applique à TOUTE l'application (routes et home)
        return ThemedScaffoldWrapper(child: child ?? Container());
      },
              // Définition de toutes les routes de l'application
              getPages: [
                //==========================================================
                // ROUTES D'AUTHENTIFICATION
                //==========================================================
                
                GetPage(name: '/welcomePage', page: () => const WelcomePage()),
                GetPage(name: '/welcomePageSignin', page: () => const WelcomePageSignin()),
                GetPage(name: '/welcomePageSignintest', page: () => const WelcomePageSignintest()),
                GetPage(name: '/welcomePageOnboarding', page: () => const WelcomePage()),
                GetPage(name: '/welcomePageSignup', page: () => const WelcomePageSignUp()),
                GetPage(name: '/signup', page: () => const SignUpPage()),
                
                //==========================================================
                // NOUVEAU: ROUTE PRINCIPALE AVEC APPSHELL
                //==========================================================
                
                GetPage(
                  name: '/dashboard', 
                  page: () => AppShell(), // Utiliser AppShell au lieu de DashboardPage
                  transition: Transition.fadeIn,
                ),
                
                //==========================================================
                // ROUTES AUTRES
                //==========================================================
                
                GetPage(name: '/settingsApp', page: () => const SettingsApp()),
                GetPage(name: '/settingsApp/profile', page: () => const ProfileSettingPage()),
                
                // NOTE: La route '/request-ride' n'est plus nécessaire car gérée par NavigationController
                
                //==========================================================
                // ROUTES D'INSCRIPTION AVEC TRANSITIONS DOUCES
                //==========================================================
                
                GetPage(
                  name: '/signup/name',
                  page: () => const SignupNamePage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/contact',
                  page: () => const SignupContactPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/password',
                  page: () => const SignupPasswordPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/birthday',
                  page: () => const SignupBirthdayPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/role',
                  page: () => const SignupRolePage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/verify',
                  page: () => const SignupVerifyPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/summary',
                  page: () => const SignupSummaryPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),

                //==========================================================
                // MOT DE PASSE OUBLIÉ & OTP
                //==========================================================
                
                GetPage(name: '/forgetPasswordMail', page: () => ForgetPasswordMailScreen()),
                GetPage(name: '/otpScreen', page: () => const OTPScreen()),

                //==========================================================
                // AUTHENTIFICATION
                //==========================================================
                
                GetPage(name: '/login', page: () => const LoginPage()),
               
                //==========================================================
                // PROFIL & PARAMÈTRES
                //==========================================================
                
                GetPage(name: '/profile', page: () => ProfilePopup()),

                //==========================================================
                // ONBOARDING ET ACCUEIL
                //==========================================================
                
                GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
                
                //==========================================================
                // DIVERS
                //==========================================================
                
                GetPage(name: '/test', page: () => const FeaturedScreen()),
                GetPage(name: '/terms', page: () => const TermsPage()),
                GetPage(name: '/privacy', page: () => const PrivacyPage()),
              ],
              
              //==========================================================
              // NAVIGATION GUARD - PROTECTION DES ROUTES
              //==========================================================
              
              // Intercepte les changements de route pour gérer l'authentification
              routingCallback: (routing) {
                // Liste des routes qui nécessitent une authentification
                final authenticatedRoutes = [
                  '/dashboard',
                  '/settingsApp',
                  '/settingsApp/profile',
                  '/profile',
                  // Ajoutez ici d'autres routes protégées
                ];
                
                // Vérifier si la route actuelle nécessite une authentification
                if (authenticatedRoutes.contains(routing?.current) && 
                    !Get.find<AuthService>().isLoggedIn()) {
                  // Rediriger vers la page de connexion si non authentifié
                  Get.offNamed('/welcomePageSignin');
                }
                
                // Adapter la navigation pour les routes spéciales
                if (routing?.current == '/dashboard') {
                  // S'assurer que le NavigationController affiche la page d'accueil
                  Get.find<NavigationController>().goToTab(0);
                }
              },
            ));
      },
    );
  }
}
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/badges.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/devices.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/documents.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/driver_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/sender_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/settings.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/travel_patterns.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/vehicules.dart';
//import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/devices_controller.dart';
import 'package:viaamigo/shared/collections/users/subcollection/subcollection_controller/user_devices_controller.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/services/user_service.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/privacy_page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/terms_page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signin.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signintest.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_wizard_page.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/profile_settings.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settingsapp.dart';
import 'package:viaamigo/utilitaires/translate.dart';

import 'firebase_options.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/Welcome_Page.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/forget_password_mail.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/login.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/otp_screen.dart';

import 'package:viaamigo/src/fonctionnalites/auth/screens/signup.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_birth.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_contact.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_name.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_password.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_role.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_summary.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/signup_verify.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/test.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/welcome_page_signup.dart';
import 'package:viaamigo/src/fonctionnalites/dashboard/screens/dashbord_page.dart';

import 'package:viaamigo/src/fonctionnalites/onboarding/screens/onboarding_screen.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings.dart';
import 'package:viaamigo/src/utilitaires/theme/app_theme.dart';
import 'package:viaamigo/src/utilitaires/theme_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 📱 Détection de la langue du téléphone
  final deviceLocale = Get.deviceLocale ?? const Locale('en', 'US');
  await Get.updateLocale(deviceLocale);
  FirebaseAuth.instance.setLanguageCode(deviceLocale.languageCode);

  // 🎨 Initialisation du thème
  final themeController = Get.put(ThemeController());
  await themeController.loadThemeMode();

  // 🔐 AuthService (asynchrone)
  await Get.putAsync(() async => AuthService());

  // 🧩 Injection des services Firestore (AVANT les contrôleurs)
  Get.put(UserService());
  Get.put(UserSettingsService());
  Get.put(VehiclesService());
  Get.put(TravelPatternsService());
  Get.put(DriverPreferencesService());
  Get.put(SenderPreferencesService());
  Get.put(UserDocumentsService());
  Get.put(UserDevicesService());
  Get.put(UserBadgesService());

  // 🎯 Injection des contrôleurs (APRÈS services)
  Get.put(UserDevicesController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(SignupController(), permanent: true);

    FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );


  // 🚀 Démarrage de l'application
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Obx(() => GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ViaAmigo',
              translations: AppTranslation(),
              locale:  Get.locale,
              fallbackLocale: const Locale('fr', 'FR'),
              theme: AppTheme.light(context),
              darkTheme: AppTheme.dark(context),
              themeMode: themeController.themeMode.value,
              defaultTransition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 900),
              initialRoute: '/welcomePage',
              getPages: [
                GetPage(name: '/dashboard', page: () => DashboardPage()),
                GetPage(name: '/welcomePage', page: () => const WelcomePage()),
                GetPage(name: '/welcomePageSignin', page: () => const WelcomePageSignin()),
                GetPage(name: '/welcomePageSignintest', page: () => const WelcomePageSignintest()),
                GetPage(name: '/welcomePageOnboarding', page: () => const WelcomePage()),
                GetPage(name: '/welcomePageSignup', page: () => const WelcomePageSignUp()),
                GetPage(name: '/settingsApp', page: () => const SettingsApp()),
                GetPage(name: '/settingsApp/profile', page: () => const ProfileSettingPage()),
                GetPage(name: '/signup', page: () => const SignUpPage()),
                GetPage(name: '/request-ride', page: () =>  ParcelWizardPage()),

                // 🔐 Signup pages avec transitions douces personnalisées
                GetPage(
                  name: '/signup/name',
                  page: () => const SignupNamePage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/contact',
                  page: () => const SignupContactPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/password',
                  page: () => const SignupPasswordPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/birthday',
                  page: () => const SignupBirthdayPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/role',
                  page: () => const SignupRolePage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/verify',
                  page: () => const SignupVerifyPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),
                GetPage(
                  name: '/signup/summary',
                  page: () => const SignupSummaryPage(),
                  transition: Transition.rightToLeftWithFade,
                  transitionDuration: Duration(milliseconds: 400),
                ),

                // 📧 Mot de passe oublié & OTP
                GetPage(name: '/forgetPasswordMail', page: () => ForgetPasswordMailScreen()),
                GetPage(name: '/otpScreen', page: () => const OTPScreen()),

                // 🔐 Authentification
                GetPage(name: '/login', page: () => const LoginPage()),
               

                // ⚙️ Profil & Paramètres
                GetPage(name: '/profile', page: () => ProfilePopup()),

                // 🚀 Onboarding et accueil
                GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
                

                // 🧪 Test
                GetPage(name: '/test', page: () => const FeaturedScreen()),
                GetPage(name: '/terms', page: () => const TermsPage()),
                GetPage(name: '/privacy', page: () => const PrivacyPage()),

              ],
            ));
      },
    );
  }
}
*/