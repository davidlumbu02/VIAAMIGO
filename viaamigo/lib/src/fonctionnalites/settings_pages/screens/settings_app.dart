import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:get/get_core/src/get_main.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/users/controller/user_controller.dart';
import 'package:viaamigo/shared/services/auth_service.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/widgets/custom_modal_controller.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/appearance_modal.dart';
import 'package:viaamigo/src/fonctionnalites/settings_pages/screens/profile_settings.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

/// 🔘 Enum pour le positionnement des raccourcis
//enum ShortcutPosition { left, center, right }

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    //controller lié au service pour recuperer les info de l'utilisateur
    final userController = Get.find<UserController>();
    final user = userController.currentUser.value;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
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
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w200,
                              )),
                          Text(user.email,
                              style: textTheme.titleMedium?.copyWith(
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
          
                  const SizedBox(height: 15),
          
                  /// Raccourcis Help - Stat - Profil
                  Row(
                    children: [
                      quickShortcut(theme, LucideIcons.helpCircle, 'Help', ShortcutPosition.left, () {
                        CustomModalController.showBottomSheet(
                          context: context, child:ProfileSettingPage(),
                          //child: const HelpModal(),
                        );
                      }),
                      const SizedBox(width: 6),
                      quickShortcut(theme, LucideIcons.barChart, 'Stat', ShortcutPosition.center, () {
                        CustomModalController.showBottomSheet(
                          context: context, child: ProfileSettingPage(),
                          //child: const StatsModal(),
                        );
                      }),
                      const SizedBox(width: 6),
                      quickShortcut(theme, LucideIcons.userCog, 'Profil', ShortcutPosition.right, () {
                        Get.toNamed('/settingsApp/profile');
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
                    sectionTitle(context,'Payment & verification'),
                    tile(theme, LucideIcons.creditCard, 'Payement modes'),
                    tile(theme, LucideIcons.badgeCheck, 'Verifications (ID, Licence...)'),
                    const SizedBox(height: 30),
                    sectionTitle(context,'Settings'),
                    tile(theme, LucideIcons.bell, 'Notifications'),
                    tile(theme, LucideIcons.moonStar, 'Theme', onTap: () {
                      CustomModalController.showBottomSheet(
                        context: context,
                        child: AppearanceSettingsModal(),
                        
                      );
                    }),
                    tile(theme, LucideIcons.settings2, 'Route Preferences'),
                    tile(theme, LucideIcons.trash2, 'Delete account'),
                    const SizedBox(height: 30),
                    //_logoutButton(context, theme), // ✅ Bouton de déconnexion
                            buildButtonTextLogo(
                              context,
                              label: 'Logout',
                              height: 50,
                              outlined: true,
                              onTap: () async {
                                await Get.find<AuthService>().signOut();
                              },
                            ),
                    const SizedBox(height: 30),
                    Text(
                      'Version 1.0.0 (Build 100)',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                     SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⬛️ Raccourcis stylés



}



