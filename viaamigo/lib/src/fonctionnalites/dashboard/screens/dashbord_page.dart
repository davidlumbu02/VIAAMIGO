// 📦 Importation des librairies nécessaires
//import 'dart:ui'; // Pour les effets de flou (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 'package:lucide_icons/lucide_icons.dart';
//import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
//import 'package:viaamigo/shared/widgets/custom_bottom_bar.dart';

// 📄 Importation des différentes pages de ton application
//import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';
//import 'package:viaamigo/src/fonctionnalites/message/screens/message_page.dart';
//import 'package:viaamigo/src/fonctionnalites/recherche/screens/recheche_page.dart';
//import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settingsapp.dart';

//import 'package:flutter/material.dart';
//import 'package:get/get.dart';
//import 'package:viaamigo/shared/controllers/navigation_controller.dart';

/// Page d'accueil du tableau de bord
///
/// Cette page contient uniquement le contenu, sans la navigation
/// qui est gérée par le NavigationController et AppShell
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Text(
              "Bienvenue dans ViaAmigo",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Envoyez et transportez des colis facilement",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            
            // Espacement
            const SizedBox(height: 24),
            
            // Carte d'action rapide
            _buildQuickActionCard(
              context,
              title: "Besoin d'envoyer un colis ?",
              description: "Trouvez quelqu'un qui voyage dans la bonne direction",
              buttonText: "Créer une annonce",
              onPressed: () {
                // Navigation via le contrôleur centralisé
                Get.find<NavigationController>().navigateToNamed('parcel-wizard');
              },
            ),
            
            // Contenu supplémentaire à ajouter selon vos besoins
            const SizedBox(height: 16),
            
            // Vous pouvez ajouter ici le reste du contenu de votre dashboard
            Expanded(
              child: Center(
                child: Text(
                  "Contenu du dashboard",
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construit une carte d'action rapide
  ///
  /// [context] - Contexte BuildContext
  /// [title] - Titre de la carte
  /// [description] - Description de l'action
  /// [buttonText] - Texte du bouton
  /// [onPressed] - Action à exécuter au clic sur le bouton
  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre de la carte
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/settings.dart';

/// 🧭 Page principale contenant la navigation entre les différentes pages
/*class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // 🔢 Index actuellement sélectionné dans la barre de navigation
  int selectedIndex = 0;

  // 📑 Liste des pages à afficher selon l'index sélectionné
  final List<Widget?> pages = const [
    DashboardHomePage(), // Accueil principal
    RecherchePage(),     // Page de recherche
    MessagesPage(),      // Page de messagerie
    SettingsApp(),                // Le profil est géré séparément avec un modal
  ];
void _openRoleSelectorModal(BuildContext context) {
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

                      Text(
                        "Headig somewhere?",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _buildActionTile(
                        context,
                        icon: LucideIcons.packagePlus,
                        title1: "I want to send a package",
                        //title2: "Notify me when someone is going my way",
                        subtitle: "I'll contribute to their trip expenses",
                        onTap: () async {
                          Navigator.pop(context);  
                          final controller = Get.put(ParcelsController()); // injection
                          await controller.initParcel(); // ✅ initialise le colis AVANT

                          Get.toNamed('/request-ride');
                        },
                      ),    
                             const SizedBox(height: 12),
                      // 🚗 I’m driving
                      _buildActionTile(
                        context,
                        icon: LucideIcons.car,
                        title1: "I'm driving",
                        //title2: "I have space in my trunk to share ",
                        subtitle: "I want to help someone send a package on my way",
                        onTap: () {
                          Navigator.pop(context);
                          Get.toNamed('/publish-trip');
                        },
                      ),

           

                      // 🔔 I need a ride

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




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationController = Get.put(NavigationStateController());  // Contrôleur d'état de navigation

    return Scaffold(
      extendBody: true, // 🔽 Permet à la BottomBar de dépasser le corps
      backgroundColor: theme.colorScheme.surface,

      // 🖥️ Affiche la page sélectionnée dans `pages[]`
      body: pages[selectedIndex] ?? const SizedBox.shrink(),

      // 🔽 Barre de navigation inférieure personnalisée
      bottomNavigationBar: SafeArea(
        child: Padding(
          //padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Pour effet flottant
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Pour la version collée
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 🌫️ Flou doux
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(25), // Bord léger
                  ),
                ),

                // 📱 Les icônes de la barre de navigation
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem(LucideIcons.layoutDashboard, 0), // Accueil
                    _buildBottomNavItem(LucideIcons.search, 1),           // Recherche

                    // ➕ Bouton central stylé
                    GestureDetector(
                      onTap: () => _openRoleSelectorModal(context),
                            // Pour l’instant : impression console
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(102),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white), // Icône "+"
                      ),
                    ),

                    _buildBottomNavItem(LucideIcons.messagesSquare, 2), // Messages
                    _buildBottomNavItem(LucideIcons.user2, 3),           // Profil
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔘 Crée un bouton d'icône pour la bottom navigation
  Widget _buildBottomNavItem(IconData icon, int index) {
    final theme = Theme.of(context);
    final isActive = selectedIndex == index;

    return IconButton(
      icon: Icon(
        icon,
        size: 24,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withAlpha(102), // Gris clair si inactif
      ),
      onPressed: () {
        setState(() {
          selectedIndex = index; // Change la page sélectionnée
        });
      },
    );
  }

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
          Icon(icon, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
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
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    ),
  );
}

}*/
