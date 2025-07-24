


import 'package:flutter/material.dart';
import 'package:viaamigo/src/fonctionnalites/dashbord_home/screens/dashbordhomepage.dart';

Widget quickShortcut(ThemeData theme, IconData icon, String label, ShortcutPosition position, VoidCallback onTap) {
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
  /*
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }*/
    Widget sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }


  /// 🔧 Élément de menu
Widget tile(ThemeData theme, IconData icon, String title, {VoidCallback? onTap}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: styledIcon(theme, icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap, // ← supporte une action personnalisée
  );
}


Widget styledIcon(ThemeData theme, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Icon(icon, size: 20, color: theme.colorScheme.primary),
  );
}

Widget modernThemeButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(25)
            : theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withAlpha(50),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    ),
  );
}
