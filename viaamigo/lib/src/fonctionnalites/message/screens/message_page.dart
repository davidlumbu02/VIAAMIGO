import 'package:flutter/material.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';


class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedScaffoldWrapper( // 🌟 Ajout du wrapper ici
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false, // ✅ Supprime la flèche retour
          title: const Text('Messages'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "💬 Messagerie en cours de développement",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
