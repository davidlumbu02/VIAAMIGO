import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/collections/users/services/user_service.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
//import 'package:viaamigo/src/fonctionnalites/auth/services/firebase_auth.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';


class WelcomePageSignUp extends StatefulWidget {
  const WelcomePageSignUp({super.key});

  @override
  State<WelcomePageSignUp> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePageSignUp> {
  final AuthService authenticationService = Get.find<AuthService>();
  final List<String> texts = [
    'ViaAmigo',
    'Let’s go',
    'Let’s chat',
    'Let’s discover',
    'Let’s deliver',
    'Let’s connect',
    'Let’s ride together',
    'Let’s move smart',
    'Let’s ship green',
    'Let’s save time',
    'Let’s share the road',
    'Let’s simplify delivery',
    'Let’s go farther',
    'Let’s carry with care',
    'Let’s change logistics',
    'Let’s make it happen',
    'Let’s build trust',
  ];

  int currentIndex = 0;
  String visibleText = '';
  bool isDeleting = false;
  Timer? typingTimer;
  int charIndex = 0;
  final UserService userService = Get.find<UserService>();
   final UserController userController = Get.find<UserController>();


  final RxBool isLoading = false.obs; // ✅ Pour afficher un loader pendant l'authentification

  @override
  void initState() {
    super.initState();
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startTyping();
  }

  @override
  void dispose() {
    typingTimer?.cancel();
   
    super.dispose();
  }

  /*void _setStatusBarColor() {
    final theme = Theme.of(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.surface,
      statusBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: theme.brightness == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
    ));
  }*/

void _startTyping() {
  typingTimer?.cancel(); // ✅ Ajoute cette ligne pour éviter les conflits de timer

  typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    final fullText = texts[currentIndex];
    
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (!isDeleting) {
      if (charIndex < fullText.length) {
        setState(() {
          visibleText += fullText[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return; // 🔒 double sécurité
          isDeleting = true;
          _startTyping();
        });
      }
    } else {
      if (charIndex > 0) {
        setState(() {
          visibleText = visibleText.substring(0, charIndex - 1);
          charIndex--;
        });
      } else {
        isDeleting = false;
        currentIndex = (currentIndex + 1) % texts.length;
        _startTyping(); // ⬅️ Recommence immédiatement
        timer.cancel();
      }
    }
  });
}

 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final signupController = Get.find<SignupController>();
      //_setStatusBarColor();

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Get.back(),
                          ),
                        ),
                      ),

                      const SizedBox(),
                      /// 🔠 Texte animé + logo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                visibleText,
                                style: textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 15),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: ClipOval(
                                  key: ValueKey(theme.brightness),
                                  child: Image.asset(
                                    theme.brightness == Brightness.dark
                                        ? 'assets/logo/NOIR_AVEC_CONT.png'
                                        : 'assets/logo/BLANC_AVEC_CONT.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      /// ✅ Boutons
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildButtonTextLogo(
                                  context,
                                  label: 'Sign up with Google',
                                  iconAsset: 'assets/logo/google.png',
                                  isFilled: false,
                                  alignIconStart: true,
                                  borderRadius: 30,
                                  height: 50,
                                onTap: () async {
                                  signupController.resetAll();
                                  isLoading.value = true;
                                  final userCredential = await authenticationService.signInWithGoogle();

                                  if (userCredential != null) {
                                    final user = userCredential.user;
                                    if (user != null) {

                                    signupController.updateField('provider', "google");
                                    signupController.updateField('profilePicture', user.photoURL ?? '');

                                     // final exists = await userService.userExists(user.uid);
                                      final exists = await Get.find<UserController>().userExists(user.uid);

                                      if (exists) {
                                        await Get.find<UserController>().fetchUserData();
                                        Get.offAllNamed('/dashboard'); // ✅ Déjà inscrit
                                      } else {
                                        Get.offAllNamed('/signup/name'); // ✅ Nouveau ➔ continuer inscription
                                      }
                                    }
                                  }
                                  isLoading.value = false;
                                },


                                ),
                                const SizedBox(height: 10),
                                buildButtonTextLogo(
                                  context,
                                  label: 'Sign up with Apple',
                                  borderRadius: 30,
                                  height: 50,
                                  iconAsset: theme.brightness == Brightness.dark
                                      ? 'assets/logo/whiteapple.png'
                                      : 'assets/logo/apple.png',
                                  isFilled: false,
                                  alignIconStart: true,
                                  onTap: () async { 
                                    isLoading.value = true;
                                    signupController.resetAll();
                                    final userCredential = await authenticationService.signInWithApple();
                                    if (userCredential != null) {
                                    final user = userCredential.user;
                                    if (user != null) {
                                     signupController.updateField('provider', "Apple");
                                      signupController.updateField('profilePicture', user.photoURL ?? '');
                                      //final exists = await userService.userExists(user.uid);
                                       final exists = await Get.find<UserController>().userExists(user.uid);

                                      if (exists) {
                                        await Get.find<UserController>().fetchUserData();
                                        Get.offAllNamed('/dashboard'); // ✅ Déjà inscrit
                                      } else {
                                        Get.offAllNamed('/signup/name'); // ✅ Nouveau ➔ continuer inscription
                                      }
                                    }
                                  }
                                  isLoading.value = false;
                                    } // ✅
                                ),
                                const SizedBox(height: 10),
                                buildButtonTextLogo(
                                  context,
                                  borderRadius: 30,
                                  height: 50,
                                  alignIconStart: true,
                                  label: 'Sign up with Facebook',
                                  iconAsset: 'assets/logo/fb.png',
                                  isFilled: false,
                                  onTap: () {
                                    isLoading.value = true;
                                    signupController.resetAll();/*
                                    final userCredential = await authenticationService.signInWithFacebook();

                                    if (userCredential != null) {
                                      final user = userCredential.user;
                                      if (user != null) {
                                        signupController.updateField('provider', 'facebook');
                                        signupController.updateField('profilePicture', user.photoURL ?? '');

                                        //final exists = await userService.userExists(user.uid);
                                         final exists = await Get.find<UserController>().userExists(user.uid);

                                        if (exists) {
                                          await Get.find<UserController>().fetchUserData(); // ✅ indispensable
                                          Get.offAllNamed('/dashboard');
                                        } else {
                                          Get.offAllNamed('/signup/name');
                                        }
                                      }
                                    }

                                    isLoading.value = false;*/
                                  },
                                ),/*
                                const SizedBox(height: 10),
                                buildButtonTextLogo(
                                  context,
                                  label: 'Try ViaAmigo as guest',
                                  icon: Icons.explore,
                                  isFilled: false,
                                  alignIconStart: true,
                                  borderRadius: 30,
                                  height: 50,
                                  onTap: () async {
                                    signupController.resetAll();
                                    await authenticationService.signInAnonymously();
                                  },
                                ), */
                                const SizedBox(height: 10),
                                buildButtonTextLogo(
                                  context,
                                  borderRadius: 30,
                                  height: 50,
                                  label: 'Sign up with email',
                                  outlined: true,
                                    onTap: () {
                                      signupController.resetAll();
                                  signupController.updateField('provider', 'email'); // ✅ Injection ici
                                  Get.toNamed('/signup/name');
                                },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              /// ⏳ Loader flou sur fond pendant le traitement Google
              Obx(() {
                return isLoading.value
                    ? Container(
                        color: Colors.black.withAlpha(77),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
