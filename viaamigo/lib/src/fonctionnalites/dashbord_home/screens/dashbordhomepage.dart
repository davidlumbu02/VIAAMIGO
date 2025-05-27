import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';
//import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/smart_content_card.dart';

/// Enum pour déterminer la position des boutons contextuels
enum ShortcutPosition { left, center, right }

/// Page principale du tableau de bord utilisateur (expéditeur/conducteur)
class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            /// 🟦 EN-TÊTE FIXE avec encoche bicolore, message de bienvenue et actions principales
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 20,
                20,
                20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 👤 Message de bienvenue + icône de notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //const SizedBox(height: 10),
                          /*Text(
                            'Bonjour, David 👋',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),*/
                          Text(
                            'Bienvenue sur ViaAmigo',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                      //icone de deconnexion
                            Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(40),
                                  onTap: () async => await Get.find<AuthService>().signOut(),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.onPrimary.withAlpha(30),
                                    child: Icon(
                                      Icons.logout,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  borderRadius: BorderRadius.circular(40),
                                  onTap: () {
                                    // 🔔 Action pour notifications
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.onPrimary.withAlpha(30),
                                    child: Icon(
                                      Icons.notifications_none,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            ,/*
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.onPrimary.withAlpha(30),
                        child: Icon(
                          Icons.logout,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.onPrimary.withAlpha(30),
                        child: Icon(
                          Icons.notifications_none,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),*/
                    ],
                  ),
      
                  const SizedBox(height: 20),
      
                  /// 🧭 Boutons contextuels : publier un colis ou proposer un trajet
                  Row(
                    children: [
                      _quickShortcut(
                        theme,
                        LucideIcons.packagePlus,
                        'Publish a package ',
                        ShortcutPosition.left,
                        onTap: () {
                        },
                      ),
                      const SizedBox(width: 6),
                      _quickShortcut(
                        theme,
                        LucideIcons.car,
                        'Publish a trip',
                        ShortcutPosition.right,
                        onTap: () {
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
      
            /// 🔽 Contenu principal scrollable : statistiques et actions rapides
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  /// ⚡ Raccourcis rapides : navigation rapide vers d'autres sections
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        _quickAction(
                          theme,
                          LucideIcons.map,
                          'Trips',
                          onTap: () {
                          },
                        ),
                        _quickAction(
                          theme,
                          LucideIcons.box,
                          'Packages',
                          onTap: () {
                          },
                        ),
                        _quickAction(
                          theme,
                          LucideIcons.messagesSquare,
                          'Messages',
                          onTap: () {
                          },
                        ),
      
      
                    ],
                  ),
      //const SizedBox(height: 20),
                 // const SmartContextCardArea(), // ✅ Correct ici
      
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Génère un bouton contextuel stylé (gauche/droite) pour l'en-tête
 Widget _quickShortcut(
  ThemeData theme,
  IconData icon,
  String label,
  ShortcutPosition position, {
  void Function()? onTap, // 👈 Pour ajouter une action au clic
}) {
  BorderRadius borderRadius;
  switch (position) {
    case ShortcutPosition.left:
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      );
      break;
    case ShortcutPosition.right:
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
      break;
    default:
      borderRadius = BorderRadius.zero;
  }

  return Expanded(
    child: AspectRatio(
      aspectRatio: 1.8,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withAlpha(25),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  /// ⚡ Widget pour une action rapide (ex: Trajets, Colis, Messages)
Widget _quickAction(
  ThemeData theme,
  IconData icon,
  String label, {
  void Function()? onTap, // 👈 pour gérer l'action au clic
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(35),
    splashColor: theme.colorScheme.primary.withAlpha(40),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 20, color: theme.iconTheme.color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),
  );
}
}


/*
                /// 🔘 Toggle role
                /*Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      _buildToggleItem('expediteur', 'Expéditeur 📦', theme),
                      _buildToggleItem('conducteur', 'Conducteur 🚗', theme),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🎯 Bouton dynamique
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      role == 'expediteur' ? 'Publier un colis' : 'Proposer un trajet',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {

                    },
                  ),*/




import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  String role = 'expediteur'; // Valeur actuelle du rôle sélectionné

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        child: Column(
          children: [
            /// 👤 En-tête : bienvenue + cloche notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Message de bienvenue
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, David 👋',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bienvenue sur ViaAmigo',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                // Icône de notification
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withAlpha(40),
                      child: Icon(Icons.notifications_none, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🧭 Bouton Toggle pour choisir le rôle
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  _buildToggleItem('expediteur', 'Expéditeur 📦'),
                  _buildToggleItem('conducteur', 'Conducteur 🚗'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 📋 Contenu dynamique selon le rôle
            Expanded(
              child: ListView(
                // ✅ Ce padding corrige l’espace vide en bas
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                children: [
                  // 🧾 Statistiques selon le rôle
                  if (role == 'expediteur') ...[
                    _buildStatCard('📦 Colis en cours', '2 colis en attente de livraison'),
                    _buildStatCard('✅ Colis livrés', '5 livraisons réussies'),
                  ] else ...[
                    _buildStatCard('🧭 Prochain trajet', 'Ottawa → Montréal - Départ à 15h'),
                    _buildStatCard('📦 Colis à récupérer', '3 colis à charger à Gatineau'),
                  ],

                  // 🗺️ Carte miniature
                  //_buildMapCard(),

                  const SizedBox(height: 10),

                  // ⚡ Actions rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAction(theme, LucideIcons.car, 'Trajets'),
                      _quickAction(theme, LucideIcons.packageCheck, 'Colis'),
                      _quickAction(theme, LucideIcons.messageCircle, 'Messages'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  /// 🧭 Élément de sélection de rôle
  Widget _buildToggleItem(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = role == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 📊 Carte d'information/statistique
  Widget _buildStatCard(String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  /// 🗺️ Carte miniature
  Widget _buildMapCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 6),
              Text("Carte en temps réel", style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "[Mini carte interactive ici]",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Bouton d'action rapide
  Widget _quickAction(ThemeData theme, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
*/
