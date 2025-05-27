import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/widgets/theme_button.dart';
import 'package:viaamigo/src/utilitaires/theme_controller.dart';

class AppearanceSettingsModal extends StatelessWidget {
  final ThemeController themeController = Get.find<ThemeController>();

  AppearanceSettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: theme.colorScheme.surface.withAlpha(242), // 0.95 * 255 = 242.25
          padding: const EdgeInsets.all(1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ⬅️ Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Text("Appearance", style: textTheme.titleLarge),
                ],
              ),

              const SizedBox(height: 20),

              /// 🌗 Choix du thème
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      themeButton(
                        context,
                        icon: LucideIcons.sliders,
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

              const SizedBox(height: 30),

              /// 🔤 Taille du texte (fonctionnelle)
              Text("FONT SIZE", style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),

              Obx(() => Slider(
                    value: themeController.fontScale.value,
                    min: 1.0,
                    max: 1.5,
                    divisions: 5,
                    label: "${(themeController.fontScale.value * 100).toInt()}%",
                    onChanged: (value) => themeController.setFontScale(value),
                  )),

              TextButton(
                onPressed: () => themeController.resetFontScale(),
                child: const Text("RESET TO DEFAULT"),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
