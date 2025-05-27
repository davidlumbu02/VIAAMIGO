// ignore_for_file: unused_element
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
//import 'package:viaamigo/src/fonctionnalites/auth/services/firebase_auth.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';
 // 👈 Assure-toi d'importer tes fonctions

class WelcomePageSignin extends StatefulWidget {
  const WelcomePageSignin({super.key});

  @override
  State<WelcomePageSignin> createState() => _WelcomePageStateSignin();
}

class _WelcomePageStateSignin extends State<WelcomePageSignin> {
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

  @override
  void initState() {
    super.initState();
    
    _startTyping();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

void _startTyping() {
  typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    final fullText = texts[currentIndex];

    if (!isDeleting) {
      if (charIndex < fullText.length) {
        if (!mounted) return; // ✅ Empêche le crash après dispose
        setState(() {
          visibleText += fullText[charIndex];
          charIndex++;
        });
      } else {
        typingTimer?.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          isDeleting = true;
          _startTyping();
        });
      }
    } else {
      if (charIndex > 0) {
        if (!mounted) return; // ✅ Pareil ici
        setState(() {
          visibleText = visibleText.substring(0, charIndex - 1);
          charIndex--;
        });
      } else {
        isDeleting = false;
        currentIndex = (currentIndex + 1) % texts.length;
      }
    }
  });
}


  @override
  void dispose() {
    typingTimer?.cancel();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Get.back(),
                        ),
                      ),

                  const SizedBox(),
                  // 👇 Texte animé avec logo
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

                  // 👇 Zone des boutons
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
                              label: 'Continue with Google',
                              iconAsset: 'assets/logo/google.png',
                              height: 50,
                              isFilled: false,
                              borderRadius: 30,
                             onTap: () async {
                              final result = await authenticationService.signInWithGoogle();
                              if (result != null) {
                                await Get.find<UserController>().fetchUserData(); // ⬅️ important !
                              }
                             }),
                            const SizedBox(height: 10),
                            buildButtonTextLogo(
                              context,
                              label: 'Continue with Apple',
                              height: 50,
                              iconAsset: theme.brightness == Brightness.dark
                                  ? 'assets/logo/whiteapple.png'
                                  : 'assets/logo/apple.png',
                              isFilled: false,
                              onTap: () async {
                                
                              final result = await authenticationService.signInWithApple();
                              if (result != null) {
                                await Get.find<UserController>().fetchUserData();
                              }
                            },

                            ),
                            const SizedBox(height: 10),
                            buildButtonTextLogo(
                              context,
                              label: 'Continue with Facebook',
                              iconAsset: 'assets/logo/fb.png',
                              height: 50,
                              isFilled: false,
                              onTap: () {
                                // TODO: activer Facebook sign-in si disponible
                                // await signInWithFacebook();
                                /*onTap: () async {
                                    final result = await authenticationService.signInWithFacebook();
                                    if (result != null) {
                                      await Get.find<UserController>().fetchUserData();
                                    }
                                  }, */
                                Get.snackbar('Unavailable', 'Facebook sign-in is not available yet',
                                    );
                              },
                            ),
                           
                            const SizedBox(height: 10),
                            buildButtonTextLogo(
                              context,
                              label: 'Sign up',
                              height: 50,
                              outlined: false,
                              onTap: () => Get.toNamed('/welcomePageSignup'),
                            ),
                            const SizedBox(height: 10),
                            /*buildButtonTextLogo(
                              context,
                              label: 'Log in',
                              height: 50,
                              outlined: true,
                              onTap: () => Get.toNamed('/welcomePageSignup'),
                            ),*/
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
