import 'dart:ui';


class OnBoardingModel {
  final String image;
  final String title1;
  final String title2;
  final String title3;
  final Color bgcolor; // Ajout du champ `bgcolor`
  final String counterText;
  final double height;

  OnBoardingModel({
    required this.image,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.bgcolor, // Initialisation obligatoire
    required this.counterText,
    required this.height,
  });
}

