/*import 'package:viaamigo/src/utilitaires/theme/text_theme.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Gère les thèmes clair et sombre de l'application ViaAmigo.
/// Inspiré par des styles modernes IA (ChatGPT, Gemini, Grok) pour une UX douce et futuriste.
abstract final class AppTheme {
  /// 🌞 Thème clair inspiré ChatGPT avec accents Gemini – style zen, professionnel et doux
  static ThemeData light(BuildContext context) => FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xFF10A37F),              // Vert IA – actions principales, confiance
          primaryContainer: Color(0xFFF2F5F6),     // Fond clair neutre – sections / surfaces
          primaryLightRef: Color(0xFF1BBF9A),
          secondary: Color(0xFFCBD5E1),            // Gris bleuté – éléments secondaires
          secondaryContainer: Color(0xFFE2E8F0),   // Blocs, cartes, champs
          secondaryLightRef: Color(0xFF94A3B8),
          tertiary: Color(0xFF7C3AED),             // Violet modéré – badges IA, statuts
          tertiaryContainer: Color(0xFFEDE9FE),    // Fond doux pour IA/premium
          tertiaryLightRef: Color(0xFF8B5CF6),
          appBarColor: Color(0xFFFAFAFA),          // AppBar clair, professionnel
          error: Color(0xFFDC2626),                // Rouge alerte – erreurs critiques
          errorContainer: Color(0xFFFEE2E2),       // Fond d’erreur doux
        ),
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface, // Pour un effet de profondeur équilibré
        blendLevel: 12, // Mélange des couleurs sur les surfaces
        appBarStyle: FlexAppBarStyle.background, // AppBar intégré au fond
        useMaterial3: true, // Pour une migration progressive vers Material 3
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
        textTheme: TTextTheme.lightTextTheme(context),
      );

  /// 🌚 Thème sombre Gemini x Grok – ambiance cosmique, tech et futuriste
  static ThemeData dark(BuildContext context) => FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF4A90E2),              // Bleu IA – boutons, liens, accents tech
          primaryContainer: Color(0xFF0C0C10),     // Fond sombre profond – ambiance Gemini
          primaryLightRef: Color(0xFF5AA7F0),
          secondary: Color(0xFF1E1E23),            // Gris spatial – cartes, composants
          secondaryContainer: Color(0xFF2A2A2F),   // Champs, widgets
          secondaryLightRef: Color(0xFF353541),
          tertiary: Color(0xFF8C5EFF),             // Violet néon – statuts spéciaux, focus
          tertiaryContainer: Color(0xFF2C1B3C),    // Fond violet foncé – badges IA
          tertiaryLightRef: Color(0xFFB983FF),
          appBarColor: Color(0xFF101014),          // AppBar discret, fusionné
          error: Color(0xFFEF4444),                // Rouge vibrant – alertes
          errorContainer: Color(0xFF7F1D1D),       // Fond sombre d’erreur
        ),
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
        blendLevel: 20,
        appBarStyle: FlexAppBarStyle.background,
        useMaterial3: true,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
        textTheme: TTextTheme.darkTextTheme(context),
      );
}
*/
import 'package:viaamigo/src/utilitaires/theme/text_theme.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

/// Gère les thèmes clair et sombre de l'application ViaAmigo.
/// Inspiré par des styles modernes IA (ChatGPT, Gemini, Grok) pour une UX douce et futuriste.
abstract final class AppTheme {
  /// 🌞 Thème clair inspiré ChatGPT avec accents Gemini – style zen, professionnel et doux
  static ThemeData light(BuildContext context) => FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xFF10A37F),              // Vert IA – actions principales, confiance
          primaryContainer: Color(0xFFF2F5F6),     // Fond clair neutre – sections / surfaces
          primaryLightRef: Color(0xFF1BBF9A),
          secondary: Color(0xFFCBD5E1),            // Gris bleuté – éléments secondaires
          secondaryContainer: Color(0xFFE2E8F0),   // Blocs, cartes, champs
          secondaryLightRef: Color(0xFF94A3B8),
          tertiary: Color(0xFF7C3AED),             // Violet modéré – badges IA, statuts
          tertiaryContainer: Color(0xFFEDE9FE),    // Fond doux pour IA/premium
          tertiaryLightRef: Color(0xFF8B5CF6),
          appBarColor: Color(0xFFFAFAFA),          // AppBar clair, professionnel
          error: Color(0xFFDC2626),                // Rouge alerte – erreurs critiques
          errorContainer: Color(0xFFFEE2E2),       // Fond d’erreur doux
        ),
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface, // Pour un effet de profondeur équilibré
        blendLevel: 12, // Mélange des couleurs sur les surfaces
        appBarStyle: FlexAppBarStyle.background, // AppBar intégré au fond
        useMaterial3: true, // Pour une migration progressive vers Material 3
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
        textTheme: TTextTheme.lightTextTheme(context),
        extensions: <ThemeExtension<dynamic>>[
          const AppColors(
            primaryLightRef: Color(0xFF1BBF9A),
            secondaryLightRef: Color(0xFF94A3B8),
            tertiaryLightRef: Color(0xFF8B5CF6),
            appBarColor: Color(0xFFFAFAFA),
            parcelColor: Color(0xFF10A37F),  // Vert IA – publication colis
    driverColor: Color(0xFF7C3AED),  // Violet modéré – publication trajet
          ),
        ],
      );

  /// 🌚 Thème sombre Gemini x Grok – ambiance cosmique, tech et futuriste
  static ThemeData dark(BuildContext context) => FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF4A90E2),              // Bleu IA – boutons, liens, accents tech
          primaryContainer: Color(0xFF0C0C10),     // Fond sombre profond – ambiance Gemini
          primaryLightRef: Color(0xFF5AA7F0),
          secondary: Color(0xFF1E1E23),            // Gris spatial – cartes, composants
          secondaryContainer: Color(0xFF2A2A2F),   // Champs, widgets
          secondaryLightRef: Color(0xFF353541),
          tertiary: Color(0xFF8C5EFF),             // Violet néon – statuts spéciaux, focus
          tertiaryContainer: Color(0xFF2C1B3C),    // Fond violet foncé – badges IA
          tertiaryLightRef: Color(0xFFB983FF),
          appBarColor: Color(0xFF101014),          // AppBar discret, fusionné
          error: Color(0xFFEF4444),                // Rouge vibrant – alertes
          errorContainer: Color(0xFF7F1D1D),       // Fond sombre d’erreur
        ),
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
        blendLevel: 20,
        appBarStyle: FlexAppBarStyle.background,
        useMaterial3: true,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
        textTheme: TTextTheme.darkTextTheme(context),
        extensions: <ThemeExtension<dynamic>>[
          const AppColors(
            primaryLightRef: Color(0xFF5AA7F0),
            secondaryLightRef: Color(0xFF353541),
            tertiaryLightRef: Color(0xFFB983FF),
            appBarColor: Color(0xFF101014),
            parcelColor: Color(0xFF4A90E2),  // Bleu IA – colis
    driverColor: Color(0xFF8C5EFF),  // Violet néon – trajet
          ),
        ],
      );
}
