import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:viaamigo/src/utilitaires/theme_controller.dart';
/// Fonction utilitaire pour adapter dynamiquement la taille du texte selon le facteur de zoom du système
/*double adaptiveFontSize(BuildContext context, double baseSize) {
  // ignore: deprecated_member_use
  final scaleFactor = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.5);
  return baseSize * scaleFactor;
}*/





double adaptiveFontSize(BuildContext context, double baseSize) {
  final scaleFactor = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.5);
  final userScale = Get.find<ThemeController>().fontScale.value;
  return baseSize * scaleFactor * userScale;
}


/// Classe contenant les thèmes de texte pour les modes clair et sombre, compatibles Material 3
class TTextTheme {
  /// 🌞 Thème Clair – élégant, lisible, moderne
  static TextTheme lightTextTheme(BuildContext context) {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 57),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: const Color(0xFF090A3B),
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 45),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
        color: const Color(0xFF090A3B),
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 36),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF090A3B),
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 32),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF090A3B),
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 28),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.25,
        color: const Color(0xFF090A3B),
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 24),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: const Color(0xFF090A3B),
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 22),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 16),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 16),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
        color: const Color(0xFF090A3B),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
        color: const Color(0xFF090A3B),
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 12),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 12),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 11),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: const Color(0xFF090A3B),
      ),
    );
  }

  /// 🌙 Thème Sombre – lisibilité optimisée, couleurs douces
  static TextTheme darkTextTheme(BuildContext context) {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 57),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 45),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 36),
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 32),
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 28),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.25,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 24),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 22),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 16),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 16),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 12),
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 12),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: adaptiveFontSize(context, 11),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: const Color.fromARGB(255, 255, 255, 255),//const Color(0xFF9FC9FF),
      ),
    );
  }
}


/*
Correspondance M3 ↔ M2
M3 (Nomenclature actuelle)	M2 (Nomenclature précédente)	Description
displayLarge	headline1	Texte d'affichage très grand, utilisé pour les titres majeurs.
displayMedium	headline2	Texte d'affichage grand, utilisé pour des sous-titres importants.
displaySmall	headline3	Texte d'affichage moyen, utilisé pour des sous-titres modérés.
headlineLarge	headline4	Grand titre utilisé pour des sections ou contenus majeurs.
headlineMedium	headline5	Titre moyen utilisé pour des sous-sections ou contenus secondaires.
headlineSmall	headline6	Petit titre, souvent utilisé dans des cartes ou en-têtes.
titleLarge	subtitle1	Titre principal pour des contenus descriptifs ou guides.
titleMedium	subtitle2	Sous-titre, souvent utilisé pour des textes descriptifs concis.
titleSmall	(Nouveau)	Nouveau style spécifique à M3 pour des titres plus petits.
bodyLarge	bodyText1	Texte de corps principal, utilisé pour des paragraphes.
bodyMedium	bodyText2	Texte de corps secondaire, utilisé pour des paragraphes concis.
bodySmall	(Nouveau)	Nouveau style spécifique à M3 pour des textes de petite taille.
labelLarge	button	Texte des boutons ou éléments interactifs.
labelMedium	(Nouveau)	Nouveau style spécifique à M3 pour des labels moyens.
labelSmall	caption	Texte des légendes ou annotations. */


/*import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TTextTheme {
  // Thème clair
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline1 : Texte d'affichage très grand, utilisé pour les titres majeurs
    displayMedium: GoogleFonts.roboto(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline2 : Texte d'affichage grand, utilisé pour des sous-titres importants
    displaySmall: GoogleFonts.roboto(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline3 : Texte d'affichage moyen, utilisé pour des sous-titres modérés
    headlineLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline4 : Grand titre utilisé pour des sections ou contenus majeurs
    headlineMedium: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.25,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline5 : Titre moyen utilisé pour des sous-sections ou contenus secondaires
    headlineSmall: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement headline6 : Petit titre, souvent utilisé dans des cartes ou en-têtes
    titleLarge: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement subtitle1 : Titre principal pour des contenus descriptifs ou guides
    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement subtitle2 : Sous-titre, souvent utilisé pour des textes descriptifs concis
    titleSmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Nouveau style spécifique à M3 pour des titres plus petits
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement bodyText1 : Texte de corps principal, utilisé pour des paragraphes
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement bodyText2 : Texte de corps secondaire, utilisé pour des paragraphes concis
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Nouveau style spécifique à M3 pour des textes de petite taille
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement button : Texte des boutons ou éléments interactifs
    labelMedium: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Nouveau style spécifique à M3 pour des labels moyens
    labelSmall: GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: Color.fromARGB(255, 9, 10, 59),
    ), // Anciennement caption : Texte des légendes ou annotations
  );

  // Thème sombre
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline1
    displayMedium: GoogleFonts.roboto(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline2
    displaySmall: GoogleFonts.roboto(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline3
    headlineLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline4
    headlineMedium: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.25,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline5
    headlineSmall: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: Color(0xFF9FC9FF),
    ), // Anciennement headline6
    titleLarge: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Anciennement subtitle1
    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Anciennement subtitle2
    titleSmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Nouveau style spécifique à M3
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      color: Color(0xFF9FC9FF),
    ), // Anciennement bodyText1
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
      color: Color(0xFF9FC9FF),
    ), // Anciennement bodyText2
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Nouveau style spécifique à M3
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Anciennement button
    labelMedium: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Nouveau style spécifique à M3
    labelSmall: GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: Color(0xFF9FC9FF),
    ), // Anciennement caption
  );
}

/*
Correspondance M3 ↔ M2
M3 (Nomenclature actuelle)	M2 (Nomenclature précédente)	Description
displayLarge	headline1	Texte d'affichage très grand, utilisé pour les titres majeurs.
displayMedium	headline2	Texte d'affichage grand, utilisé pour des sous-titres importants.
displaySmall	headline3	Texte d'affichage moyen, utilisé pour des sous-titres modérés.
headlineLarge	headline4	Grand titre utilisé pour des sections ou contenus majeurs.
headlineMedium	headline5	Titre moyen utilisé pour des sous-sections ou contenus secondaires.
headlineSmall	headline6	Petit titre, souvent utilisé dans des cartes ou en-têtes.
titleLarge	subtitle1	Titre principal pour des contenus descriptifs ou guides.
titleMedium	subtitle2	Sous-titre, souvent utilisé pour des textes descriptifs concis.
titleSmall	(Nouveau)	Nouveau style spécifique à M3 pour des titres plus petits.
bodyLarge	bodyText1	Texte de corps principal, utilisé pour des paragraphes.
bodyMedium	bodyText2	Texte de corps secondaire, utilisé pour des paragraphes concis.
bodySmall	(Nouveau)	Nouveau style spécifique à M3 pour des textes de petite taille.
labelLarge	button	Texte des boutons ou éléments interactifs.
labelMedium	(Nouveau)	Nouveau style spécifique à M3 pour des labels moyens.
labelSmall	caption	Texte des légendes ou annotations. */



*/