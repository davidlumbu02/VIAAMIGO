import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';

/// Page permettant à l’utilisateur de choisir son rôle :
/// 1. Envoyer un colis (expéditeur)
/// 2. Conduire et transporter (conducteur)
///
/// Chaque option est représentée par une carte colorée, responsive,
/// avec navigation vers le bon workflow (publier un colis ou un trajet).
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colors.appBarColor,
          elevation: 0,
           centerTitle: true, // ✅ Titre centré
          title: Text(
            "Heading somewhere?",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              /// 🟩 Bloc "Envoyer un colis"
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 280,
                  ),
                  child: _buildActionTile(
                    context,
                    icon: LucideIcons.packagePlus,
                    iconColor: colors.parcelColor,
                    backgroundColor: colors.parcelColor.withAlpha(30),
                    title: "Send a package",
                    subtitle: "Need something delivered? Create a parcel listing and get matched with drivers",
                    onTap: () {
                      Get.find<NavigationController>()
                          .navigateToNamed('parcel-wizard');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              /// 🟪 Bloc "Je conduis"
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 280,
                  ),
                  child: _buildActionTile(
                    context,
                    icon: LucideIcons.car,
                    iconColor: colors.driverColor,
                    backgroundColor: colors.driverColor.withAlpha(30),
                    title: "Offer a ride",
                    subtitle: "Have space in your vehicle? Publish your route and earn by transporting parcels",
                    onTap: () {
                      Get.find<NavigationController>()
                          .navigateToNamed('publish-trip');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une carte d’action (colis ou trajet) avec :
  /// - Icône + fond coloré
  /// - Titre et sous-titre
  /// - Flèche de navigation
  /// - Fonction de navigation au tap
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            /// 🟢 Icône dans un cercle coloré
            CircleAvatar(
              radius: 40,
              backgroundColor: backgroundColor,
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 16),

            /// 📄 Titre et description
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            /// ➡️ Flèche
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
