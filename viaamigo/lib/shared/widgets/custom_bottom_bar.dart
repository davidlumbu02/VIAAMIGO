import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Assurez-vous que ce chemin correspond à la classe NavigationController

import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
// OU ajustez le nom de la classe selon le fichier réel
// import 'package:viaamigo/shared/controllers/navigation_state_controller.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Récupérer le contrôleur une seule fois pour tout le widget
    final navController = Get.find<NavigationController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(25),
                ),
              ),
              
              // Observer les changements d'index
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, LucideIcons.layoutDashboard, 0, navController), // Accueil
                  _buildNavItem(context, LucideIcons.search, 1, navController), // Recherche
                  _buildCentralButton(context, navController), // Bouton central (index 2)
                  _buildNavItem(context, LucideIcons.messagesSquare, 3, navController), // Messages
                  _buildNavItem(context, LucideIcons.user2, 4, navController), // Profil
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }

  // Passer le contrôleur en paramètre pour éviter de le récupérer plusieurs fois
  Widget _buildNavItem(BuildContext context, IconData icon, int index, NavigationController navController) {
    final theme = Theme.of(context);
    final isActive = navController.selectedTabIndex.value == index;

    return IconButton(
      icon: Icon(
        icon,
        size: 24,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withAlpha(102),
      ),
      onPressed: () => navController.goToTab(index),
    );
  }

  // Passer le contrôleur en paramètre pour éviter de le récupérer plusieurs fois
  Widget _buildCentralButton(BuildContext context, NavigationController navController) {
    final theme = Theme.of(context);
    final isActive = navController.selectedTabIndex.value == 2;

    return GestureDetector(
      onTap: () => navController.goToTab(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(isActive ? 70 : 102),
              blurRadius: isActive ? 12 : 10,
              spreadRadius: isActive ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            Icons.add,
            key: ValueKey<bool>(isActive),
            color: isActive ? theme.colorScheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
  /// Construit le bouton central (+) avec effet d'élévation
  ///
  /// [context] - Contexte BuildContext
  /// 
  /*Widget _buildCentralButton(BuildContext context) {
    final navController = Get.find<NavigationController>();
    final theme = Theme.of(context);

    return GestureDetector(
      // Ouvrir le modal au clic
      onTap: () => navController.openRoleSelectorModal(context),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          // Style du bouton central
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          // Ombre portée pour effet d'élévation
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(102),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Icône + centrée
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}*/
/*import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;  // Index de la page sélectionnée
  final Function(int) onTap; // Callback pour changer de page
  final Function() onCentralTap; // Callback pour le bouton central (ex: ouvrir un modal)

  const CustomBottomBar({super.key, 
    required this.selectedIndex, 
    required this.onTap,
    required this.onCentralTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Accès au thème pour la personnalisation

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Pas de marge supplémentaire
        child: ClipRRect(  // Bord arrondi
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),  // Coins arrondis en haut à gauche
            topRight: Radius.circular(35), // Coins arrondis en haut à droite
          ),
          child: BackdropFilter( // Application de flou sur l'arrière-plan
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container( // Conteneur de la bottom bar
              height: 70, // Hauteur de la bottom bar
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, // Couleur de fond basée sur le thème
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(25), // Bord léger
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Espacement égal entre les éléments
                children: [
                  // Icônes de la barre de navigation
                  _buildNavItem(context, LucideIcons.layoutDashboard, 0), // Accueil
                  _buildNavItem(context, LucideIcons.search, 1),           // Recherche
                  _buildCentralButton(context),  // Bouton central (icône +)
                  _buildNavItem(context, LucideIcons.messagesSquare, 2), // Messages
                  _buildNavItem(context, LucideIcons.user2, 3),           // Profil
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Crée un bouton de navigation avec une icône et un index
  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final theme = Theme.of(context); // Accès au thème
    final isActive = selectedIndex == index; // Vérifie si cet élément est actif

    return IconButton(
      icon: Icon(
        icon,
        size: 24,  // Taille de l'icône
        color: isActive
            ? theme.colorScheme.primary  // Couleur active
            : theme.colorScheme.onSurface.withAlpha(102), // Couleur inactive (gris clair)
      ),
      onPressed: () => onTap(index),  // Callback pour changer la page
    );
  }

  // Crée le bouton central (icône +)
  Widget _buildCentralButton(BuildContext context) {
    final theme = Theme.of(context); // Accès au thème

    return GestureDetector(
      onTap: onCentralTap, // Appelle le callback lorsque l'on clique
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,  // Couleur du bouton central
          shape: BoxShape.circle,  // Forme circulaire
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(102),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white),  // Icône "+" dans le bouton
      ),
    );
  }
}
*/