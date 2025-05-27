
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemedScaffoldWrapper extends StatelessWidget {
  final Widget child;

  const ThemedScaffoldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Immersion
        systemNavigationBarColor: theme.colorScheme.surface, // Couleur de la nav bar
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
