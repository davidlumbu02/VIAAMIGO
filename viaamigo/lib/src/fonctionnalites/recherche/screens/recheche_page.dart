import 'package:flutter/material.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class RecherchePage extends StatelessWidget {
  const RecherchePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false, // ✅ Supprime la flèche retour
          title: const Text('Recherche'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "🔍 Fonction de recherche à venir",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
