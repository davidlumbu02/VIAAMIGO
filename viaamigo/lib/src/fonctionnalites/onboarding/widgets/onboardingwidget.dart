// Widget pour chaque page d'onboarding
import 'package:viaamigo/src/fonctionnalites/onboarding/models/model_on_boarding.dart';
import 'package:flutter/material.dart';

class OnboardingPageWidget extends StatelessWidget {
  const OnboardingPageWidget({
    super.key,
    required this.model,
  });

  final OnBoardingModel model; // Modèle contenant les données de la page

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: model.bgcolor, // Couleur par défaut si aucune couleur n'est définie
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Affichage de l'image
          Image(
            image: AssetImage(model.image),
            height: model.height * 0.3,
            fit: BoxFit.contain,
          ),
          // Affichage des textes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  model.title1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10), // Espacement entre les textes
                Text(
                  model.title2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5), // Espacement entre les textes
                Text(
                  model.title3,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Compteur de page
          Text(
            model.counterText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 50), // Espacement pour équilibrer le bas
        ],
      ),

    );
  }
}
