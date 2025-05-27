import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/shared/widgets/theme_button.dart';
import 'package:viaamigo/src/utilitaires/theme_controller.dart';

class SettingsModalContent extends StatelessWidget {
  final themeController = Get.find<ThemeController>();
final signupController = Get.find<SignupController>();
  SettingsModalContent({super.key});
bool isSystemLangSelected() {
  final device = Get.deviceLocale;
  final current = Get.locale;

  return device?.languageCode == current?.languageCode &&
         (device?.countryCode ?? '') == (current?.countryCode ?? '');
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    //final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔼 Header du modal
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(), // ← Ferme le modal manuellement
            ),
          ],
        ),

        //const SizedBox(height: 24),

        // 🌍 Section Langue
        Align(
          alignment: Alignment.center,
          child: Text(
            "LANGUAGE",
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // 🌐 Boutons de langue (Fr, En, System)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
              themeButton(
              context,
              icon: LucideIcons.smartphone,
              label: 'SYSTEM',
               isSelected: Get.locale?.languageCode == Get.deviceLocale?.languageCode &&
              Get.locale?.countryCode == Get.deviceLocale?.countryCode,
              onTap: () {
                final locale = Get.deviceLocale!;
                Get.updateLocale(Get.deviceLocale!); // 🌐 Utilise la langue du téléphone
                signupController.updateField('language', locale.languageCode); 
              },
            ),
            themeButton(
              context,
              icon: LucideIcons.languages,
              label: 'FRANCAIS',
              isSelected: Get.locale?.languageCode == 'fr',
              onTap: () {
                Get.updateLocale(const Locale('fr', 'FR')); // 🌍 Change langue → FR
                signupController.updateField('language', 'fr');
              },
            ),
            themeButton(
              context,
              icon: LucideIcons.languages,
              label: 'ENGLISH',
              isSelected: Get.locale?.languageCode == 'en',
              onTap: () {
                Get.updateLocale(const Locale('en', 'US')); // 🌍 Change langue → EN
                signupController.updateField('language', 'en');
              },
            ),

          ],
        ),

        const SizedBox(height: 24),

        // 🌗 Section Thème
        Align(
          alignment: Alignment.center,
          child: Text(
            "THEME",
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // ☀️🌙 Boutons de thème (System, Day, Night)
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                themeButton(
                  context,
                  icon: LucideIcons.smartphone,
                  label: "SYSTEM",
                  isSelected: themeController.themeMode.value == ThemeMode.system,
                  onTap: () => themeController.setSystemMode(),
                ),
                themeButton(
                  context,
                  icon: LucideIcons.sun,
                  label: "DAY",
                  isSelected: themeController.themeMode.value == ThemeMode.light,
                  onTap: () => themeController.setLightMode(),
                ),
                themeButton(
                  context,
                  icon: LucideIcons.moon,
                  label: "NIGHT",
                  isSelected: themeController.themeMode.value == ThemeMode.dark,
                  onTap: () => themeController.setDarkMode(),
                ),
              ],
            )),


      ],
    );
  }
}
