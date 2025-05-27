import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:get/get_core/src/get_main.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/widgets/custom_modal_controller.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/appearance_modal.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/profile_settings.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

/// 🔘 Enum pour le positionnement des raccourcis
enum ShortcutPosition { left, center, right }

class ProfilePopup extends StatelessWidget {
  const ProfilePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    //controller lié au service pour recuperer les info de l'utilisateur
    final userController = Get.find<UserController>();
    final user = userController.currentUser.value;

    return ThemedScaffoldWrapper(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30), // ✅ Coins arrondis en haut et en bas
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: theme.colorScheme.surface.withAlpha(242), // ✅ 95% sans .withOpacity
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🟧 HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 30, 20, 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Titre + Avatar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi there 👋',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  )),
                              const SizedBox(height: 4),
                              if (user != null) ...[
                              Text('${user.firstName} ${user.lastName}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  )),
                              Text(user.email,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary.withAlpha(190),
                                  )),
                            ] else
                              Text('Loading...', style: textTheme.bodySmall),
                          ],

                          ),
                          CircleAvatar(
                            radius: 34,
                            backgroundImage: (user != null && user.safeProfilePicture.isNotEmpty)
                                ? NetworkImage(user.safeProfilePicture)
                                : const AssetImage('assets/images/beaute-homme-dr-mayeux-medecine-esthetique-paris8-cover.jpg') as ImageProvider,
                          ),



                        ],
                      ),
      
                      const SizedBox(height: 35),
      
                      /// Raccourcis Help - Stat - Profil
                      Row(
                        children: [
                          _quickShortcut(theme, LucideIcons.helpCircle, 'Help', ShortcutPosition.left, () {
                            CustomModalController.showBottomSheet(
                              context: context, child:ProfileSettingPage(),
                              //child: const HelpModal(),
                            );
                          }),
                          const SizedBox(width: 6),
                          _quickShortcut(theme, LucideIcons.barChart, 'Stat', ShortcutPosition.center, () {
                            CustomModalController.showBottomSheet(
                              context: context, child: ProfileSettingPage(),
                              //child: const StatsModal(),
                            );
                          }),
                          const SizedBox(width: 6),
                          _quickShortcut(theme, LucideIcons.userCog, 'Profil', ShortcutPosition.right, () {
                            CustomModalController.showBottomSheet(
                              context: context, child: ProfileSettingPage(),
                              //child: const ProfileSettingsModal(),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
      
                /// 🔽 CONTENU BAS
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        _sectionTitle('Payment & verification'),
                        _tile(theme, LucideIcons.creditCard, 'Payement modes'),
                        _tile(theme, LucideIcons.badgeCheck, 'Verifications (ID, Licence...)'),
                        const SizedBox(height: 30),
                        _sectionTitle('Settings'),
                        _tile(theme, LucideIcons.bell, 'Notifications'),
                        _tile(theme, LucideIcons.moonStar, 'Theme', onTap: () {
                          CustomModalController.showBottomSheet(
                            context: context,
                            child: AppearanceSettingsModal(),
                          );
                        }),
                        _tile(theme, LucideIcons.settings2, 'Route Preferences'),
                        _tile(theme, LucideIcons.trash2, 'Delete account'),
                        const SizedBox(height: 30),
                        _logoutButton(context, theme), // ✅ Bouton de déconnexion
                        const SizedBox(height: 30),
                        Text(
                          'Version 1.0.0 (Build 100)',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ⬛️ Raccourcis stylés
Widget _quickShortcut(ThemeData theme, IconData icon, String label, ShortcutPosition position, VoidCallback onTap) {
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
      aspectRatio: 1,
      child: GestureDetector(
        onTap: onTap,  // Ajoute ici la fonction onTap
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  /// 🔘 Section title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }


  /// 🔧 Élément de menu
Widget _tile(ThemeData theme, IconData icon, String title, {VoidCallback? onTap}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: _styledIcon(theme, icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap, // ← supporte une action personnalisée
  );
}


Widget _styledIcon(ThemeData theme, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Icon(icon, size: 20, color: theme.colorScheme.primary),
  );
}

  /// 🔴 Bouton Déconnexion
  Widget _logoutButton(BuildContext context, ThemeData theme) {
    return TextButton.icon(
      onPressed: () async{
       await Get.find<AuthService>().signOut();
      },
      icon: Icon(Icons.logout, color: theme.colorScheme.primary),
      label: const Text("Logout"),
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}



