import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class SignupRolePage extends StatefulWidget {
  const SignupRolePage({super.key});

  @override
  State<SignupRolePage> createState() => _SignupRolePageState();
}

class _SignupRolePageState extends State<SignupRolePage> {
  // 🔘 Stocke le rôle sélectionné : 'sender', 'driver' ou 'both'
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    signupController.currentStepRoute.value = '/signup/role';
    // 🔁 Si l'utilisateur revient à la page, on pré-remplit le rôle sélectionné
    final savedRole = signupController.getField('role');
    if (savedRole != null && savedRole is String) {
      selectedRole = savedRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // Gère le clavier ouvert

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Bouton retour
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(),
                ),

                const SizedBox(height: 10),

                // 🧾 Titre principal
                Text(
                  "Choose your role",
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                // 📦 Carte "Sender"
                _buildModernRoleCard(
                  context,
                  value: 'sender',
                  icon: LucideIcons.box,
                  title: 'Sender',
                  subtitle: 'Move/Send parcels anywhere.',
                ),

                const SizedBox(height: 16),

                // 🚗 Carte "Driver"
                _buildModernRoleCard(
                  context,
                  value: 'driver',
                  icon: LucideIcons.car,
                  title: 'Driver',
                  subtitle: 'Carrying parcels en route.',
                ),

                const SizedBox(height: 16),

                // 🔁 Carte "Both"
                _buildModernRoleCard(
                  context,
                  value: 'both',
                  icon: LucideIcons.refreshCcw,
                  title: 'Both',
                  subtitle: 'Send and carry parcels.',
                ),

                const Spacer(),

                // ➡️ Bouton continuer (en bas à droite)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        iconSize: 32,
                        onPressed: () {
                          // ✅ Si un rôle est sélectionné, on enregistre et passe à la suite
                          if (selectedRole != null) {
                            signupController.updateField('role', selectedRole);
                            Get.toNamed('/signup/verify');
                          } else {
                            // ❌ Sinon on affiche une erreur
                            Get.snackbar('Error', 'Please select a role.');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧱 Widget carte de rôle moderne et animée
  Widget _buildModernRoleCard(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedRole == value;

    return GestureDetector(
      onTap: () => setState(() => selectedRole = value), // ✅ Sélectionne le rôle cliqué
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withAlpha(40)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(80),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // 🎯 Icône du rôle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withAlpha(20)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
              ),
            ),

            const SizedBox(width: 16),

            // 📄 Titre et sous-titre du rôle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // ✅ Icône de validation animée
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle,
                      key: ValueKey(true),
                      color: theme.colorScheme.primary,
                      size: 28)
                  : const SizedBox(width: 28), // Espace réservé si non sélectionné
            )
          ],
        ),
      ),
    );
  }
}
