import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/models/app_route.dart';

// Import des pages principales
import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';
import 'package:viaamigo/src/fonctionnalites/message/screens/message_page.dart';
import 'package:viaamigo/src/fonctionnalites/plus%20boutton/screen/select_role.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/recheche_page.dart';
import 'package:viaamigo/src/fonctionnalites/route_step/screens/publish_trip_page.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings_app.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_wizard_page.dart';

/// Contrôleur principal de navigation pour toute l'application
///
/// Ce contrôleur centralise toute la logique de navigation de l'application:
/// - Gestion des routes et de leur historique
/// - Affichage conditionnel de la bottom bar
/// - Navigation entre les pages
/// - Transitions et animations
/// - Gestion spéciale des modals pour éviter les conflits de navigation
class NavigationController extends GetxController {
  //============================================================
  // VARIABLES RÉACTIVES (OBSERVABLES)
  //============================================================
  
  /// Page actuellement affichée (observable)
  final Rx<Widget> currentPage = Rx<Widget>(DashboardHomePage());
  
  /// Indique si la bottom bar doit être affichée (observable)
  final RxBool showBottomBar = true.obs;
  
  /// Index de l'onglet sélectionné dans la bottom bar (observable)
  final RxInt selectedTabIndex = 0.obs;
  
  /// Indique si la page actuelle est une route modale (observable)
  /// Influence le type d'animation de transition
  final RxBool isModalRoute = false.obs;
  
  /// NOUVEAU : Indique si un modal sheet est actuellement affiché
  /// Permet d'éviter les interférences de navigation lors de l'affichage de modals
  final RxBool isModalSheetActive = false.obs;
  
  /// NOUVEAU : Navigateur dédié aux modals
  final GlobalKey<NavigatorState> modalNavigatorKey = GlobalKey<NavigatorState>();
  
  //============================================================
  // VARIABLES PRIVÉES
  //============================================================
  
  /// Historique des routes pour gérer la navigation arrière
  final List<AppRoute> _navigationHistory = [];
  
  //============================================================
  // DÉFINITION DES ROUTES
  //============================================================
  
  /// Routes principales avec la bottom bar
  /// Ces routes correspondent aux onglets de la bottom bar
  final List<AppRoute> mainRoutes = [
    AppRoute(
      name: 'home', 
      pageBuilder: () => DashboardHomePage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'search', 
      pageBuilder: () => RecherchePage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'role-selection',
      pageBuilder: () => const RoleSelectionPage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'messages', 
      pageBuilder: () => MessagesPage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'profile', 
      pageBuilder: () => SettingsApp(),
      showBottomBar: true,
    ),
  ];
  
  //============================================================
  // CYCLE DE VIE
  //============================================================
  
  @override
  void onInit() {
    super.onInit();
    // Initialiser l'historique avec la page d'accueil
    // Cela garantit que l'utilisateur a toujours une page "précédente"
    _navigationHistory.add(mainRoutes[0]);
  }
  
  //============================================================
  // MÉTHODES DE NAVIGATION PUBLIQUES
  //============================================================
  
  /// Navigue vers un onglet principal (tabs de la bottom bar)
  ///
  /// [index] - L'index de l'onglet (0: accueil, 1: recherche, etc.)
  void goToTab(int index) {
    // NOUVEAU : Ne rien faire si un modal est actif
    if (isModalSheetActive.value) return;
    
    // Vérifier que l'index est valide pour éviter les erreurs
    if (index < 0 || index >= mainRoutes.length) return;
    
    // Mettre à jour l'index sélectionné
    selectedTabIndex.value = index;
    
    // Naviguer vers la route correspondante
    _navigateToRoute(mainRoutes[index]);
  }
  
  /// Navigue vers une route identifiée par son nom
  ///
  /// [routeName] - Nom unique de la route (défini dans _findRouteByName)
  /// [arguments] - Arguments optionnels à passer à la page
  void navigateToNamed(String routeName, {Map<String, dynamic>? arguments}) {
    // NOUVEAU : Ne rien faire si un modal est actif
    if (isModalSheetActive.value) return;
    
    final route = _findRouteByName(routeName);
    if (route == null) return;

    // 🔐 Ne rien faire si on est déjà sur cette page
    if (_navigationHistory.isNotEmpty && _navigationHistory.last.name == route.name) {
      return;
    }

    _navigateToRoute(route, arguments: arguments);
  }

  /// Affiche une page en mode modal (par dessus la pile actuelle)
  ///
  /// [page] - Widget de la page à afficher en modal
  void showModal(Widget page) {
    // Ne pas afficher de modal si un autre est déjà actif
    if (isModalSheetActive.value) return;
    
    // Marquer comme route modale pour l'animation appropriée
    isModalRoute.value = true;
    
    // Changer la page actuelle
    currentPage.value = page;
    
    // Masquer la bottom bar pour les modaux
    showBottomBar.value = false;
  }
  
  /// NOUVEAU : Méthode dédiée pour afficher des bottom sheets
  /// Cette méthode gère correctement l'état du modal pour éviter les conflits de navigation
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
    ShapeBorder? shape,
    Color? backgroundColor,
    bool enableDrag = true,
    double? elevation,
  }) async {
    // Ne pas afficher de modal si un autre est déjà actif
    if (isModalSheetActive.value) return null;
    
    // Marquer que nous affichons un modal
    isModalSheetActive.value = true;
    
    try {
      // Utiliser Get.bottomSheet pour l'affichage
      final result = await Get.bottomSheet<T>(
        child,
        isScrollControlled: isScrollControlled,
        shape: shape ?? const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: backgroundColor,
        enableDrag: enableDrag,
        elevation: elevation,
      );
      
      return result;
    } finally {
      // S'assurer que le flag est réinitialisé même en cas d'erreur
      // Un petit délai pour s'assurer que la transition est bien terminée
      Future.delayed(const Duration(milliseconds: 300), () {
        isModalSheetActive.value = false;
      });
    }
  }
  
  /// Retourne à la page précédente
  ///
  /// Renvoie true si la navigation a réussi, false sinon
  bool goBack() {
    // NOUVEAU : Ne rien faire si un modal est actif - les modals ont leur propre gestion de "back"
    if (isModalSheetActive.value) return false;
    
    // Si l'historique est vide ou ne contient qu'une seule page
    // impossible de revenir en arrière
    if (_navigationHistory.length <= 1) {
      return false;
    }
    
    // Retirer la page actuelle de l'historique
    _navigationHistory.removeLast();
    
    // Restaurer la page précédente (dernière de l'historique)
    final previousRoute = _navigationHistory.last;
    
    // Mettre à jour les états
    currentPage.value = previousRoute.pageBuilder();
    showBottomBar.value = previousRoute.showBottomBar;
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(previousRoute);
    
    return true;
  }
  
  /// Vérifie si la route actuelle correspond au nom donné
  bool isCurrentRoute(String routeName) {
    if (_navigationHistory.isEmpty) return false;
    return _navigationHistory.last.name == routeName;
  }
  
  //============================================================
  // MÉTHODES DE NAVIGATION PRIVÉES
  //============================================================
  
  /// Navigation interne vers une route
  ///
  /// [route] - Route vers laquelle naviguer
  /// [arguments] - Arguments optionnels à passer à la page
  void _navigateToRoute(AppRoute route, {Map<String, dynamic>? arguments}) {
    // NOUVEAU : Ne rien faire si un modal est actif
    if (isModalSheetActive.value) return;
    
    // Mettre à jour les états UI
    currentPage.value = route.pageBuilder();
    showBottomBar.value = route.showBottomBar;
    isModalRoute.value = false;
    
    // Ajouter la route à l'historique pour pouvoir revenir en arrière
    _navigationHistory.add(route);
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(route);
  }
  
  /// Trouve une route par son nom
  ///
  /// [name] - Nom de la route à rechercher
  /// Retourne la route si trouvée, null sinon
  AppRoute? _findRouteByName(String name) {
    // Vérifier d'abord dans les routes principales (tabs)
    for (final route in mainRoutes) {
      if (route.name == name) return route;
    }
    
    // Définition des routes supplémentaires (hors tabs)
    final additionalRoutes = {
      'parcel-wizard': AppRoute(
        name: 'parcel-wizard', 
        pageBuilder: () {
          // Initialisation du contrôleur de colis et de la page
         // final controller = Get.put(ParcelsController());
         // controller.initParcel();
          return ParcelWizardPage();
        },
        showBottomBar: true, // Pas de bottom bar pour cette page
      ),
      'publish-trip': AppRoute(
        name: 'publish-trip',
        pageBuilder: () => const PublishTripPage(),
        showBottomBar: true,
      ),
    };
    
    // Retourner la route correspondante ou null si non trouvée
    return additionalRoutes[name];
  }
  
  /// Met à jour l'index de tab si la route est une route principale
  ///
  /// [route] - Route à vérifier
  void _updateSelectedTabIfMainRoute(AppRoute route) {
    for (int i = 0; i < mainRoutes.length; i++) {
      if (mainRoutes[i].name == route.name) {
        selectedTabIndex.value = i;
        break;
      }
    }
  }
}
/*

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/models/app_route.dart';

// Import des pages principales
import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';
import 'package:viaamigo/src/fonctionnalites/message/screens/message_page.dart';
import 'package:viaamigo/src/fonctionnalites/plus%20boutton/screen/select_role.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/recheche_page.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings_app.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_wizard_page.dart';

/// Contrôleur principal de navigation pour toute l'application
///
/// Ce contrôleur centralise toute la logique de navigation de l'application:
/// - Gestion des routes et de leur historique
/// - Affichage conditionnel de la bottom bar
/// - Navigation entre les pages
/// - Transitions et animations
class NavigationController extends GetxController {
  //============================================================
  // VARIABLES RÉACTIVES (OBSERVABLES)
  //============================================================
  
  /// Page actuellement affichée (observable)
  final Rx<Widget> currentPage = Rx<Widget>(DashboardHomePage());
  
  /// Indique si la bottom bar doit être affichée (observable)
  final RxBool showBottomBar = true.obs;
  
  /// Index de l'onglet sélectionné dans la bottom bar (observable)
  final RxInt selectedTabIndex = 0.obs;
  
  /// Indique si la page actuelle est une route modale (observable)
  /// Influence le type d'animation de transition
  final RxBool isModalRoute = false.obs;
  
  //============================================================
  // VARIABLES PRIVÉES
  //============================================================
  
  /// Historique des routes pour gérer la navigation arrière
  final List<AppRoute> _navigationHistory = [];
  
  //============================================================
  // DÉFINITION DES ROUTES
  //============================================================
  
  /// Routes principales avec la bottom bar
  /// Ces routes correspondent aux onglets de la bottom bar
  final List<AppRoute> mainRoutes = [
    AppRoute(
      name: 'home', 
      pageBuilder: () => DashboardHomePage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'search', 
      pageBuilder: () => RecherchePage(),
      showBottomBar: true,
    ),
      AppRoute(
    name: 'role-selection',
    pageBuilder: () => const RoleSelectionPage(),
    showBottomBar: true,
  ),
    AppRoute(
      name: 'messages', 
      pageBuilder: () => MessagesPage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'profile', 
      pageBuilder: () => SettingsApp(),
      showBottomBar: true,
    ),
  ];
  
  //============================================================
  // CYCLE DE VIE
  //============================================================
  
  @override
  void onInit() {
    super.onInit();
    // Initialiser l'historique avec la page d'accueil
    // Cela garantit que l'utilisateur a toujours une page "précédente"
    _navigationHistory.add(mainRoutes[0]);
  }
  
  //============================================================
  // MÉTHODES DE NAVIGATION PUBLIQUES
  //============================================================
  
  /// Navigue vers un onglet principal (tabs de la bottom bar)
  ///
  /// [index] - L'index de l'onglet (0: accueil, 1: recherche, etc.)
  void goToTab(int index) {
    // Vérifier que l'index est valide pour éviter les erreurs
    if (index < 0 || index >= mainRoutes.length) return;
    
    // Mettre à jour l'index sélectionné
    selectedTabIndex.value = index;
    
    // Naviguer vers la route correspondante
    _navigateToRoute(mainRoutes[index]);
  }
  
  /// Navigue vers une route identifiée par son nom
  ///
  /// [routeName] - Nom unique de la route (défini dans _findRouteByName)
  /// [arguments] - Arguments optionnels à passer à la page
  /*
  void navigateToNamed(String routeName, {Map<String, dynamic>? arguments}) {
    // Chercher la route par son nom
    final route = _findRouteByName(routeName);
    
    // Si la route n'existe pas, afficher un message et abandonner
    if (route == null) {
      print('Route $routeName not found');
      return;
    }
    
    // Naviguer vers la route trouvée
    _navigateToRoute(route, arguments: arguments);
  }
  */
  void navigateToNamed(String routeName, {Map<String, dynamic>? arguments}) {
  final route = _findRouteByName(routeName);
  if (route == null) return;

  // 🔐 Ne rien faire si on est déjà sur cette page
  if (_navigationHistory.isNotEmpty && _navigationHistory.last.name == route.name) {
    return;
  }

  _navigateToRoute(route, arguments: arguments);
}

  /// Affiche une page en mode modal (par dessus la pile actuelle)
  ///
  /// [page] - Widget de la page à afficher en modal
  void showModal(Widget page) {
    // Marquer comme route modale pour l'animation appropriée
    isModalRoute.value = true;
    
    // Changer la page actuelle
    currentPage.value = page;
    
    // Masquer la bottom bar pour les modaux
    showBottomBar.value = false;
  }
  
  /// Retourne à la page précédente
  ///
  /// Renvoie true si la navigation a réussi, false sinon
  bool goBack() {
    // Si l'historique est vide ou ne contient qu'une seule page
    // impossible de revenir en arrière
    if (_navigationHistory.length <= 1) {
      return false;
    }
    
    // Retirer la page actuelle de l'historique
    _navigationHistory.removeLast();
    
    // Restaurer la page précédente (dernière de l'historique)
    final previousRoute = _navigationHistory.last;
    
    // Mettre à jour les états
    currentPage.value = previousRoute.pageBuilder();
    showBottomBar.value = previousRoute.showBottomBar;
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(previousRoute);
    
    return true;
  }
  /// Vérifie si la route actuelle correspond au nom donné
bool isCurrentRoute(String routeName) {
  if (_navigationHistory.isEmpty) return false;
  return _navigationHistory.last.name == routeName;
}
  //============================================================
  // MÉTHODES DE NAVIGATION PRIVÉES
  //============================================================
  
  /// Navigation interne vers une route
  ///
  /// [route] - Route vers laquelle naviguer
  /// [arguments] - Arguments optionnels à passer à la page
  void _navigateToRoute(AppRoute route, {Map<String, dynamic>? arguments}) {
    // Mettre à jour les états UI
    currentPage.value = route.pageBuilder();
    showBottomBar.value = route.showBottomBar;
    isModalRoute.value = false;
    
    // Ajouter la route à l'historique pour pouvoir revenir en arrière
    _navigationHistory.add(route);
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(route);
  }
  
  /// Trouve une route par son nom
  ///
  /// [name] - Nom de la route à rechercher
  /// Retourne la route si trouvée, null sinon
  AppRoute? _findRouteByName(String name) {
    // Vérifier d'abord dans les routes principales (tabs)
    for (final route in mainRoutes) {
      if (route.name == name) return route;
    }
    
    // Définition des routes supplémentaires (hors tabs)
    final additionalRoutes = {
      'parcel-wizard': AppRoute(
        name: 'parcel-wizard', 
        pageBuilder: () {
          // Initialisation du contrôleur de colis et de la page
          final controller = Get.put(ParcelsController());
          controller.initParcel();
          return ParcelWizardPage();
        },
        showBottomBar: true, // Pas de bottom bar pour cette page
      ),
      'publish-trip': AppRoute(
        name: 'publish-trip',
        pageBuilder: () => const PublishTripPage(), // À adapter si nécessaire
        showBottomBar: false,
      ),

    };
    
    // Retourner la route correspondante ou null si non trouvée
    return additionalRoutes[name];
  }
  
  /// Met à jour l'index de tab si la route est une route principale
  ///
  /// [route] - Route à vérifier
  void _updateSelectedTabIfMainRoute(AppRoute route) {
    for (int i = 0; i < mainRoutes.length; i++) {
      if (mainRoutes[i].name == route.name) {
        selectedTabIndex.value = i;
        break;
      }
    }
  }
  
  //============================================================
  // MÉTHODES UI
  //============================================================
  
  /// Ouvre le modal de sélection de rôle
  ///
  /// [context] - Contexte BuildContext pour le modal
  void openRoleSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(76),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    minHeight: 400,
                  ),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poignée en haut du modal
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Titre du modal
                        Text(
                          "Heading somewhere?",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Option "Envoyer un colis"
                        _buildActionTile(
                          context,
                          icon: LucideIcons.packagePlus,
                          title1: "I want to send a package",
                          subtitle: "I'll contribute to their trip expenses",
                          onTap: () {
                            Navigator.pop(context);
                            
                            // Navigation avec le système centralisé
                            navigateToNamed('parcel-wizard');
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Option "Je conduis"
                        _buildActionTile(
                          context,
                          icon: LucideIcons.car,
                          title1: "I'm driving",
                          subtitle: "I want to help someone send a package on my way",
                          onTap: () {
                            Navigator.pop(context);
                            
                            // Navigation avec le système centralisé
                            navigateToNamed('publish-trip');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Construit une tuile d'action pour le modal
  ///
  /// [context] - Contexte BuildContext
  /// [icon] - Icône à afficher
  /// [title1] - Titre principal
  /// [title2] - Titre secondaire optionnel
  /// [subtitle] - Sous-titre explicatif
  /// [onTap] - Action à exécuter lors du clic
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title1,
    String? title2,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 25),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(30), width: 1),
        ),
        child: Row(
          children: [
            // Icône à gauche
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            
            // Contenu central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title1,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  
                  // Titre secondaire optionnel
                  if (title2 != null)
                    Text(title2,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                  const SizedBox(height: 4),
                  
                  Text(subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                ],
              ),
            ),
            
            // Flèche à droite
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Page de publication de trajet (à adapter selon votre implémentation)
class PublishTripPage extends StatelessWidget {
  const PublishTripPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publier un trajet"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.find<NavigationController>().goBack(),
        ),
      ),
      body: const Center(
        child: Text("Page de publication de trajet"),
      ),
    );
  }
}*/

/*
//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:lucide_icons/lucide_icons.dart';

import 'package:viaamigo/shared/models/app_route.dart';

// Import des pages principales
import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';
import 'package:viaamigo/src/fonctionnalites/message/screens/message_page.dart';
import 'package:viaamigo/src/fonctionnalites/plus%20boutton/screen/select_role.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/recheche_page.dart';
import 'package:viaamigo/src/fonctionnalites/route_step/screens/publish_trip_page.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings_app.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_wizard_page.dart';

/// Contrôleur principal de navigation pour toute l'application
///
/// Ce contrôleur centralise toute la logique de navigation de l'application:
/// - Gestion des routes et de leur historique
/// - Affichage conditionnel de la bottom bar
/// - Navigation entre les pages
/// - Transitions et animations
class NavigationController extends GetxController {
  //============================================================
  // VARIABLES RÉACTIVES (OBSERVABLES)
  //============================================================
  
  /// Page actuellement affichée (observable)
  final Rx<Widget> currentPage = Rx<Widget>(DashboardHomePage());
  
  /// Indique si la bottom bar doit être affichée (observable)
  final RxBool showBottomBar = true.obs;
  
  /// Index de l'onglet sélectionné dans la bottom bar (observable)
  final RxInt selectedTabIndex = 0.obs;
  
  /// Indique si la page actuelle est une route modale (observable)
  /// Influence le type d'animation de transition
  final RxBool isModalRoute = false.obs;
  
  //============================================================
  // VARIABLES PRIVÉES
  //============================================================
  
  /// Historique des routes pour gérer la navigation arrière
  final List<AppRoute> _navigationHistory = [];
  
  //============================================================
  // DÉFINITION DES ROUTES
  //============================================================
  
  /// Routes principales avec la bottom bar
  /// Ces routes correspondent aux onglets de la bottom bar
  final List<AppRoute> mainRoutes = [
    AppRoute(
      name: 'home', 
      pageBuilder: () => DashboardHomePage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'search', 
      pageBuilder: () => RecherchePage(),
      showBottomBar: true,
    ),
      AppRoute(
    name: 'role-selection',
    pageBuilder: () => const RoleSelectionPage(),
    showBottomBar: true,
  ),
    AppRoute(
      name: 'messages', 
      pageBuilder: () => MessagesPage(),
      showBottomBar: true,
    ),
    AppRoute(
      name: 'profile', 
      pageBuilder: () => SettingsApp(),
      showBottomBar: true,
    ),
  ];
  
  //============================================================
  // CYCLE DE VIE
  //============================================================
  
  @override
  void onInit() {
    super.onInit();
    // Initialiser l'historique avec la page d'accueil
    // Cela garantit que l'utilisateur a toujours une page "précédente"
    _navigationHistory.add(mainRoutes[0]);
  }
  
  //============================================================
  // MÉTHODES DE NAVIGATION PUBLIQUES
  //============================================================
  
  /// Navigue vers un onglet principal (tabs de la bottom bar)
  ///
  /// [index] - L'index de l'onglet (0: accueil, 1: recherche, etc.)
  void goToTab(int index) {
    // Vérifier que l'index est valide pour éviter les erreurs
    if (index < 0 || index >= mainRoutes.length) return;
    
    // Mettre à jour l'index sélectionné
    selectedTabIndex.value = index;
    
    // Naviguer vers la route correspondante
    _navigateToRoute(mainRoutes[index]);
  }
  
  /// Navigue vers une route identifiée par son nom
  ///
  /// [routeName] - Nom unique de la route (défini dans _findRouteByName)
  /// [arguments] - Arguments optionnels à passer à la page
  /*
  void navigateToNamed(String routeName, {Map<String, dynamic>? arguments}) {
    // Chercher la route par son nom
    final route = _findRouteByName(routeName);
    
    // Si la route n'existe pas, afficher un message et abandonner
    if (route == null) {
      print('Route $routeName not found');
      return;
    }
    
    // Naviguer vers la route trouvée
    _navigateToRoute(route, arguments: arguments);
  }
  */
  void navigateToNamed(String routeName, {Map<String, dynamic>? arguments}) {
  final route = _findRouteByName(routeName);
  if (route == null) return;

  // 🔐 Ne rien faire si on est déjà sur cette page
  if (_navigationHistory.isNotEmpty && _navigationHistory.last.name == route.name) {
    return;
  }

  _navigateToRoute(route, arguments: arguments);
}

  /// Affiche une page en mode modal (par dessus la pile actuelle)
  ///
  /// [page] - Widget de la page à afficher en modal
  void showModal(Widget page) {
    // Marquer comme route modale pour l'animation appropriée
    isModalRoute.value = true;
    
    // Changer la page actuelle
    currentPage.value = page;
    
    // Masquer la bottom bar pour les modaux
    showBottomBar.value = false;
  }
  
  /// Retourne à la page précédente
  ///
  /// Renvoie true si la navigation a réussi, false sinon
  bool goBack() {
    // Si l'historique est vide ou ne contient qu'une seule page
    // impossible de revenir en arrière
    if (_navigationHistory.length <= 1) {
      return false;
    }
    
    // Retirer la page actuelle de l'historique
    _navigationHistory.removeLast();
    
    // Restaurer la page précédente (dernière de l'historique)
    final previousRoute = _navigationHistory.last;
    
    // Mettre à jour les états
    currentPage.value = previousRoute.pageBuilder();
    showBottomBar.value = previousRoute.showBottomBar;
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(previousRoute);
    
    return true;
  }
  /// Vérifie si la route actuelle correspond au nom donné
bool isCurrentRoute(String routeName) {
  if (_navigationHistory.isEmpty) return false;
  return _navigationHistory.last.name == routeName;
}
  //============================================================
  // MÉTHODES DE NAVIGATION PRIVÉES
  //============================================================
  
  /// Navigation interne vers une route
  ///
  /// [route] - Route vers laquelle naviguer
  /// [arguments] - Arguments optionnels à passer à la page
  void _navigateToRoute(AppRoute route, {Map<String, dynamic>? arguments}) {
    // Mettre à jour les états UI
    currentPage.value = route.pageBuilder();
    showBottomBar.value = route.showBottomBar;
    isModalRoute.value = false;
    
    // Ajouter la route à l'historique pour pouvoir revenir en arrière
    _navigationHistory.add(route);
    
    // Si c'est une route principale, mettre à jour l'index de tab
    _updateSelectedTabIfMainRoute(route);
  }
  
  /// Trouve une route par son nom
  ///
  /// [name] - Nom de la route à rechercher
  /// Retourne la route si trouvée, null sinon
  AppRoute? _findRouteByName(String name) {
    // Vérifier d'abord dans les routes principales (tabs)
    for (final route in mainRoutes) {
      if (route.name == name) return route;
    }
    
    // Définition des routes supplémentaires (hors tabs)
    final additionalRoutes = {
      'parcel-wizard': AppRoute(
      name: 'parcel-wizard', 
      pageBuilder: () => ParcelWizardPage(),
      showBottomBar: true,
    ),

      /*'parcel-wizard': AppRoute(
        name: 'parcel-wizard', 
        pageBuilder: () {
          // Initialisation du contrôleur de colis et de la page
          final controller = Get.put(ParcelsController());
          controller.initParcel();
          return ParcelWizardPage();
        },
        showBottomBar: true, // Pas de bottom bar pour cette page
      ),*/
      'publish-trip': AppRoute(
        name: 'publish-trip',
        pageBuilder: () => const PublishTripPage(), // À adapter si nécessaire
        showBottomBar: true,
      ),

    };
    
    // Retourner la route correspondante ou null si non trouvée
    return additionalRoutes[name];
  }
  
  /// Met à jour l'index de tab si la route est une route principale
  ///
  /// [route] - Route à vérifier
  void _updateSelectedTabIfMainRoute(AppRoute route) {
    for (int i = 0; i < mainRoutes.length; i++) {
      if (mainRoutes[i].name == route.name) {
        selectedTabIndex.value = i;
        break;
      }
    }
  }
  
}
*/