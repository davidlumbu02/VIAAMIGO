
/*✅ 1. CustomModalController.showBottomSheet(...)
🔹 Fonctionnalité :
Modal glissable en hauteur

Design fluide, idéal pour interactions complexes

Parfait pour options, formulaires, listes déroulantes

🔸 Appel :
dart
Copier
Modifier
CustomModalController.showBottomSheet(
  context: context,
  child: YourModalContent(),
  initialChildSize: 0.5, // Hauteur initiale (0.0 à 1.0)
  minChildSize: 0.4,
  maxChildSize: 0.9,
  blurSigma: 10,
  barrierColor: Colors.black.withOpacity(0.2),
);
✅ 2. CustomModalController.showPopup(...)
🔹 Fonctionnalité :
Modal fixe en bas, style iOS

Utilise une animation slide

Supporte swipe pour fermeture (via SwipeToDismissWrapper)

Idéal pour confirmation, sélection simple, ou actions rapides

🔸 Appel :
dart
Copier
Modifier
CustomModalController.showPopup(
  context: context,
  child: YourModalContent(),
  heightFactor: 0.4, // Hauteur du modal (40% de l’écran)
  blurSigma: 8,
  transitionDuration: Duration(milliseconds: 250),
  barrierColor: Colors.black.withOpacity(0.25),
);
✅ 3. CustomModalController.show(...) → entrée unifiée
🔹 Fonctionnalité :
Permet de choisir dynamiquement le type (popup ou bottomSheet)

Centralise l’appel en un seul point pratique

🔸 Appel :
dart
Copier
Modifier
CustomModalController.show(
  context: context,
  child: YourModalContent(),
  variant: 'popup', // ou 'bottomSheet'
  // Paramètres supplémentaires selon le type :
  heightFactor: 0.45, // (popup)
  initialChildSize: 0.5, // (bottomSheet)
  blurSigma: 12,
  barrierColor: Colors.black.withOpacity(0.3),
);
🔁 Tu n’as plus besoin de retenir deux fonctions séparées si tu utilises celle-ci.

✅ 4. CustomModalController2.show(...)
🔹 Fonctionnalité :
Modal simple et élégant, centré en bas

Coins arrondis, effet flou, entrée fluide

Pas de swipe par défaut (mais personnalisable si tu ajoutes le wrapper)

🔸 Appel :
dart
Copier
Modifier
CustomModalController2.show(
  context: context,
  child: YourModalContent(),
  heightFactor: 0.5,
  blurSigma: 10,
  transitionDuration: Duration(milliseconds: 300),
  barrierColor: Colors.black.withOpacity(0.3),
);
🧪 Résumé visuel rapide :
dart
Copier
Modifier
// 🧱 1. Modal draggable (Google Maps style)
CustomModalController.showBottomSheet(context: context, child: YourWidget());

// 💬 2. Modal iOS-style avec slide animation
CustomModalController.showPopup(context: context, child: YourWidget());

// 🎛 3. Appel unifié (plus propre dans ton code)
CustomModalController.show(context: context, child: YourWidget(), variant: 'popup');

// 🧩 4. Version simplifiée dans CustomModalController2
CustomModalController2.show(context: context, child: YourWidget());
 */
import 'dart:ui';
import 'package:flutter/material.dart';

/// 🎯 Contrôleur universel pour afficher des modaux stylés, fluides et responsives
/// ✅ Supporte deux variantes :
///    1. BottomSheet glissable (comme Google Maps)
///    2. Popup fixe façon iOS avec animation slide
class CustomModalController {
  /// 🔻 Variante 1 : BottomSheet glissable avec swipe + tap extérieur
  static Future<void> showBottomSheet({
    required BuildContext context,
    required Widget child,
    double initialChildSize = 0.43,
    double minChildSize = 0.4,
    double maxChildSize = 0.90,
    double blurSigma = 10,
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.2),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: _SwipeToDismissWrapper(
                  child: DraggableScrollableSheet(
                    initialChildSize: initialChildSize,
                    minChildSize: minChildSize,
                    maxChildSize: maxChildSize,
                    expand: false,
                    builder: (context, scrollController) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: SafeArea(
                          top: false,
                          child: _ModalContainer(
                            scrollController: scrollController,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💬 Variante 2 : Popup fixe en bas de l'écran avec animation slide
  static Future<void> showPopup({
    required BuildContext context,
    required Widget child,
    double heightFactor = 0.4,
    double blurSigma = 10,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.2),
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "CustomPopup",
      barrierDismissible: true,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (_, __, ___) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SafeArea(
                      top: false,
                      child: _SwipeToDismissWrapper(
                        child: _ModalContainer(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (_, anim1, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  /// 🎛 Entrée unifiée pour afficher un modal en choisissant la variante ('popup' ou 'bottomSheet')
  static Future<void> show({
    required BuildContext context,
    required Widget child,
    String variant = 'bottomSheet', // 'popup' ou 'bottomSheet'
    // Options communes
    double blurSigma = 10,
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.2),
    // BottomSheet only
    double initialChildSize = 0.43,
    double minChildSize = 0.4,
    double maxChildSize = 0.90,
    // Popup only
    double heightFactor = 0.4,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    if (variant == 'popup') {
      return showPopup(
        context: context,
        child: child,
        heightFactor: heightFactor,
        blurSigma: blurSigma,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
      );
    } else {
      return showBottomSheet(
        context: context,
        child: child,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        blurSigma: blurSigma,
        barrierColor: barrierColor,
      );
    }
  }
}

/// 📦 Conteneur principal du modal
class _ModalContainer extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;

  const _ModalContainer({required this.child, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(242),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 10),
          _dragHandle(),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: scrollController != null
                  ? SingleChildScrollView(
                      controller: scrollController,
                      child: child,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: child,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(128, 128, 128, 0.35),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      );
}

/// 👆 Swipe-to-dismiss wrapper
class _SwipeToDismissWrapper extends StatefulWidget {
  final Widget child;

  const _SwipeToDismissWrapper({required this.child});

  @override
  State<_SwipeToDismissWrapper> createState() => _SwipeToDismissWrapperState();
}

class _SwipeToDismissWrapperState extends State<_SwipeToDismissWrapper> {
  double dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() => dragOffset += details.delta.dy);
      },
      onVerticalDragEnd: (_) {
        if (dragOffset > 100) {
          Navigator.of(context).pop();
        }
        dragOffset = 0;
      },
      child: AnimatedSlide(
        offset: Offset(0, dragOffset / 300),
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// 📦 ModalController alternatif (non modifié)
class CustomModalController2 {
  static Future<void> show({
    required BuildContext context,
    required Widget child,
    double heightFactor = 0.5,
    double blurSigma = 10,
    Color barrierColor = const Color(0x33000000),
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "CustomModal",
      barrierDismissible: true,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Container(color: Colors.transparent),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: GestureDetector(
                      onTap: () {},
                      child: _ModalContainer(child: child),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

/*import 'dart:ui';
import 'package:flutter/material.dart';

/// 🎯 Contrôleur universel pour afficher des modaux stylés, fluides et responsives
/// ✅ Supporte deux variantes :
///    1. BottomSheet glissable (comme Google Maps)
///    2. Popup fixe façon iOS avec animation slide
class CustomModalController {
  /// 🔻 Variante 1 : BottomSheet glissable avec swipe + tap extérieur
  static Future<void> showBottomSheet({
    required BuildContext context, // 📍 Contexte de l'application
    required Widget child,         // 🧱 Contenu du modal à afficher
    double initialChildSize = 0.43, // 📏 Hauteur initiale du BottomSheet (en fraction de l'écran)
    double minChildSize = 0.4,     // 📏 Hauteur minimale possible
    double maxChildSize = 0.90,    // 📏 Hauteur maximale possible
    double blurSigma = 10,         // 🌫 Intensité du flou d’arrière-plan
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.2), // 🌓 Couleur du fond semi-transparent
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,             // ✅ Permet d’utiliser toute la hauteur de l’écran
      backgroundColor: Colors.transparent,  // 🎨 Fond transparent pour voir le flou
      barrierColor: barrierColor,           // 🎨 Couleur du flou derrière
      builder: (_) => GestureDetector(      // 🖱 Pour détecter les taps en dehors du modal
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(), // 🚪 Ferme le modal si on clique à l'extérieur
        child: Stack(
          children: [
            // 🌫 Arrière-plan flou
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.expand(),
            ),

            // 📦 Affichage du BottomSheet aligné en bas
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // 🚫 Empêche la fermeture quand on clique dans le modal
                child: _SwipeToDismissWrapper(
                  child: DraggableScrollableSheet(
                    initialChildSize: initialChildSize,
                    minChildSize: minChildSize,
                    maxChildSize: maxChildSize,
                    expand: false,
                    builder: (context, scrollController) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600), // 🖥 Limite largeur sur tablette
                        child: SafeArea(
                          top: false,
                          child: _ModalContainer(
                            scrollController: scrollController,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💬 Variante 2 : Popup fixe en bas de l'écran avec swipe + fermeture au clic extérieur
  static Future<void> showPopup({
    required BuildContext context, // 📍 Contexte de l'application
    required Widget child,         // 🧱 Contenu du modal
    double heightFactor = 0.4,     // 📏 Hauteur du popup (en fraction de l’écran)
    double blurSigma = 10,         // 🌫 Flou d’arrière-plan
    Duration transitionDuration = const Duration(milliseconds: 300), // ⏱ Animation d’ouverture
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.2),          // 🌓 Couleur semi-transparente
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "CustomPopup",            // 🏷️ Étiquette pour accessibilité
      barrierDismissible: true,                // ✅ Ferme si on clique à l'extérieur
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,  // ⏱ Durée de l’animation
      pageBuilder: (_, __, ___) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 🌫 Arrière-plan flou
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.expand(),
            ),

            // 📦 Popup aligné en bas avec swipe et responsive
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SafeArea(
                      top: false,
                      child: _SwipeToDismissWrapper(
                        child: _ModalContainer(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 🌀 Animation de glissement vers le haut
      transitionBuilder: (_, anim1, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}

/// 📦 Conteneur principal du modal avec scroll intégré et coins arrondis
class _ModalContainer extends StatelessWidget {
  final Widget child; // 🧱 Contenu du modal
  final ScrollController? scrollController; // 🌀 Scroll externe fourni

  const _ModalContainer({required this.child, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 🎨 Pour utiliser les couleurs du thème

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(242), // 🎨 Fond du modal avec opacité 95%
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), // 🟢 Coins arrondis supérieurs
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 10),
          _dragHandle(), // 🎚 Petit handle visuel
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10), // 📦 Marge intérieure en bas
              child: scrollController != null
                  ? SingleChildScrollView(
                      controller: scrollController,
                      child: child,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: child,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎚 Petit handle visuel arrondi centré en haut du modal
  Widget _dragHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(128, 128, 128, 0.35),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      );
}

/// 👆 Gère le swipe vers le bas pour fermer un modal
class _SwipeToDismissWrapper extends StatefulWidget {
  final Widget child; // 🧱 Contenu enfant à rendre "swipeable"

  const _SwipeToDismissWrapper({required this.child});

  @override
  State<_SwipeToDismissWrapper> createState() => _SwipeToDismissWrapperState();
}

class _SwipeToDismissWrapperState extends State<_SwipeToDismissWrapper> {
  double dragOffset = 0; // 📏 Distance glissée accumulée

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() => dragOffset += details.delta.dy); // 🌀 Met à jour en temps réel
      },
      onVerticalDragEnd: (_) {
        if (dragOffset > 100) {
          Navigator.of(context).pop(); // ✅ Ferme le modal si assez glissé
        }
        dragOffset = 0; // ♻️ Réinitialise la distance
      },
      child: AnimatedSlide(
        offset: Offset(0, dragOffset / 300), // 🌀 Slide progressif vers le bas
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
*/

/*import 'dart:ui';
import 'package:flutter/material.dart';

/// 🧩 Contrôleur de modaux stylés avec flou, animation, et coins arrondis inspiré de showGeneralDialog
class CustomModalController {
  static Future<void> show({
    required BuildContext context,
    required Widget child,
    double heightFactor = 0.5, // Hauteur du modal entre 0.3 et 0.9
    double blurSigma = 10,
    Color barrierColor = const Color(0x33000000),
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "CustomModal",
      barrierDismissible: true,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                /// 🌫 Flou arrière-plan
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Container(color: Colors.transparent),
                ),

                /// 📦 Modal en bas avec coins arrondis
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: GestureDetector(
                      onTap: () {}, // Prévention de fermeture si on tape à l'intérieur
                      child: _ModalContainer(child: child),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

/// 🧱 Conteneur avec design doux, coins arrondis et drag handle
class _ModalContainer extends StatelessWidget {
  final Widget child;

  const _ModalContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _dragHandle(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.35),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}
*/