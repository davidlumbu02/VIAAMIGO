import 'package:flutter/material.dart';

/// Widget réutilisable pour les boutons avec icône/logo facultatif.
/// Supporte aussi une icône à gauche (icon) et à droite (endIcon).
Widget buildButtonTextLogo(
  BuildContext context, {
  required String label,
  IconData? icon,
  String? iconAsset,
  required VoidCallback onTap,
  bool isFilled = false,
  bool outlined = false,
  double borderRadius = 30,
  bool alignIconStart = false,

  /// 🎯 NOUVEAUX PARAMÈTRES
  double? width,
  double? height,
  bool useAltBorder = false,
  IconData? endIcon, // ✅ Nouveau paramètre
  Color? bordercolerput,
}) {
  final theme = Theme.of(context);
  final textColor = isFilled
      ? theme.colorScheme.onPrimary
      : theme.colorScheme.onSurface;

  final backgroundColor = isFilled
      ? theme.colorScheme.primary
      : outlined
          ? Colors.transparent
          : theme.colorScheme.surface;

  final borderColor = outlined
      ? (useAltBorder
          ? theme.colorScheme.outline
          : bordercolerput ?? theme.colorScheme.primary)
      : Colors.transparent;

  final hasIcon = icon != null || iconAsset != null;

  return SizedBox(
    width: width,
    height: height,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor),
        ),
        shadowColor: theme.colorScheme.shadow.withAlpha(25),
      ),

      /// 🎯 Si aligné à gauche → Stack, sinon → Row
      child: hasIcon && alignIconStart
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(icon, size: 20),
                      ),
                    if (iconAsset != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.asset(iconAsset, width: 20, height: 20),
                      ),
                  ],
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (endIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(endIcon, size: 20),
                  )
                else
                  const SizedBox(width: 20), // pour garder l'équilibre visuel
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(icon, size: 20),
                  ),
                if (iconAsset != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(iconAsset, width: 20, height: 20),
                  ),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (endIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(endIcon, size: 20),
                  ),
              ],
            ),
    ),
  );
}
