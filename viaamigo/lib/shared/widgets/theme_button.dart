  import 'package:flutter/material.dart';
  Widget themeButton(BuildContext context,
      {required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          color: isSelected
                ? theme.colorScheme.primary.withAlpha(26) // 0.1 * 255 = 25.5 ≈ 26
                : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                )),
          ],
        ),
      ),
    );
  }