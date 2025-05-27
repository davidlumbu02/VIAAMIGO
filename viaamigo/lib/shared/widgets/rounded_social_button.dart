import 'package:flutter/material.dart';

  // Widget réutilisable pour les boutons sociaux
  Widget buildSocialButton(String imagePath) {
    return ElevatedButton(
      onPressed: () {}, // Action du bouton (actuellement vide)
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(), // Bouton circulaire
        padding: const EdgeInsets.all(10), // Espace autour de l'icône
        backgroundColor: Colors.white,
      ),
      child: Image.asset(imagePath, width: 30, height: 30), // Icône du bouton
    );
  }

