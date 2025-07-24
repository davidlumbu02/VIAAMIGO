import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/shared/widgets/custom_bottom_bar.dart';

/// Conteneur principal de l'application qui affiche les pages et la bottom bar
///
/// AppShell gère:
/// - L'affichage conditionnel de la bottom bar
/// - Les transitions animées entre les pages
/// - L'adaptation du contenu selon l'état de navigation
class AppShell extends StatelessWidget {
  // Récupérer le contrôleur de navigation centralisé
  final navigationController = Get.find<NavigationController>();

  AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser Obx pour réagir aux changements d'état
    return Obx(() {
      // Variables locales pour la lisibilité
      final showNav = navigationController.showBottomBar.value;
      final isModal = navigationController.isModalRoute.value;
      
      return Scaffold(
        // Corps réactif qui change selon l'état de navigation
        body: AnimatedSwitcher(
          // Animation de transition entre les pages
          duration: const Duration(milliseconds: 300),
          
          // Constructeur de transition personnalisé selon le type de navigation
          transitionBuilder: (child, animation) {
            // Animation différente si c'est une route modale
            if (isModal) {
              // Animation de bas en haut pour les pages modales
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), // Commence en bas de l'écran
                  end: Offset.zero, // Termine à la position normale
                ).animate(animation),
                child: child,
              );
            } else {
              // Animation de fondu pour les transitions standards
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }
          },
          
          // Page actuelle à afficher (gérée par le contrôleur)
          child: navigationController.currentPage.value,
        ),
        
        // Bottom bar conditionnelle (affichée ou masquée selon l'état)
        bottomNavigationBar: showNav
            ? const CustomBottomNavigationBar() // Afficher la barre
            : null, // Masquer la barre
        
        // Permettre au contenu de passer sous la bottom bar
        // Important pour les interfaces immersives
        extendBody: showNav,
      );
    });
  }
}