// ignore_for_file: public_member_api_docs, sort_constructors_first
//import 'package:canandar/src/fonctionnalites/onboarding/screens/onboarding_screen2.dart';
import 'package:viaamigo/src/fonctionnalites/onboarding/widgets/onboardingwidget.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:viaamigo/src/constantes/image_string.dart'; // Contient les images
import 'package:viaamigo/src/constantes/text_string.dart'; // Contient les textes
import 'package:viaamigo/src/fonctionnalites/onboarding/models/model_on_boarding.dart'; // Modèle
//import 'package:viaamigo/src/fonctionnalites/auth/screens/signin2.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState(); // Retrait du "_" ici
}

class OnboardingScreenState extends State<OnboardingScreen> { // Classe rendue publique
  final LiquidController controller = LiquidController(); // Contrôleur LiquidSwipe
  int currentPage = 0; // Page active

  // Callback pour mettre à jour la page courante
  void onPageChangeCallback(int activePageIndex) {
    setState(() {
      currentPage = activePageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Pages d'onboarding avec des images, textes et couleurs uniques
    final pages = [
      OnboardingPageWidget(
        model: OnBoardingModel(
          image: onBoardingImage1, // Image unique pour la première page
          title1: page1onbording1,
          title2: page1onbording2,
          title3: page1onbording3,
          counterText: onbordingcounter1,
          height: size.height,
          bgcolor:  const Color.fromARGB(255, 190, 208, 240),
        ),
      ),
      OnboardingPageWidget(
        model: OnBoardingModel(
          image: onBoardingImage2, // Image unique pour la deuxième page
          title1: page2onbording1,
          title2: page2onbording2,
          title3: page2onbording3,
          counterText: onbordingcounter2,
          height: size.height,
          bgcolor:  const Color.fromARGB(255, 198, 238, 219),
        ),
      ),
      OnboardingPageWidget(
        model: OnBoardingModel(
          image: onBoardingImage3, // Image unique pour la troisième page
          title1: page3onbording1,
          title2: page3onbording2,
          title3: page3onbording3,
          counterText: onbordingcounter3,
          height: size.height,
          bgcolor:  const Color.fromARGB(255, 241, 234, 224),
        ),
      ),
      OnboardingPageWidget(
        model: OnBoardingModel(
          image: onBoardingImage4, // Image unique pour la quatrième page
          title1: page4onbording1,
          title2: page4onbording2,
          title3: page4onbording3,
          counterText: onbordingcounter4,
          height: size.height,
          bgcolor:  const Color.fromARGB(255, 230, 220, 231)
        ),
      ),
      OnboardingPageWidget(
        model: OnBoardingModel(
          image: onBoardingImage5, // Image unique pour la cinquième page
          title1: page5onbording1,
          title2: page5onbording2,
          title3: page5onbording3,
          counterText: onbordingcounter5,
          height: size.height,
          bgcolor: const Color.fromARGB(255, 255, 255, 255),  // Couleur de fond de la cinquième page
        ),
      ),
    ];

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // LiquidSwipe pour afficher les pages avec un effet fluide
          LiquidSwipe(
            pages: pages,
            liquidController: controller,
            onPageChangeCallback: onPageChangeCallback, // Callback pour changer la page
            slideIconWidget: const Icon(Icons.arrow_back_ios),
            enableSideReveal: true,
          ),

          // Bouton circulaire pour avancer à la page suivante
          Positioned(
            bottom: 60,
            child: OutlinedButton(
              onPressed: () {
                if (currentPage < pages.length - 1) {
                  controller.animateToPage(page: currentPage + 1,duration: 700); // Aller à la page suivante
                } else {
                      //Navigator.of(context).pushReplacement(
                      //  MaterialPageRoute(builder: (_) => const Signin()),
                      //);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ),
            ),
          ),

          // Bouton "Skip" pour ignorer l'onboarding
          Positioned(
            top: 50,
            right: 20.0,
            child: TextButton(
              onPressed: () {
                controller.jumpToPage(page: pages.length - 1); // Aller à la dernière page
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Indicateur de progression en bas
          Positioned(
            bottom: 10,
            child: AnimatedSmoothIndicator(
              activeIndex: currentPage, // Page courante
              count: pages.length, // Nombre total de pages
              effect: WormEffect(
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Colors.black26,
                dotHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


