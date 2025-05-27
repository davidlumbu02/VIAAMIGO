import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartContextCardArea extends StatelessWidget {
  const SmartContextCardArea({super.key});

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            itemCount: _smartCardData.length,
            itemBuilder: (context, index) {
              final data = _smartCardData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _smartCard(
                  context,
                  icon: data['icon'],
                  title: data['title'],
                  subtitle: data['subtitle'],
                  color: data['color'],
                  actionLabel: data['actionLabel'],
                  onActionTap: data['onActionTap'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static final List<Map<String, dynamic>> _smartCardData = [
    {
      'icon': LucideIcons.checkCircle,
      'title': "Vous êtes disponible pour livrer",
      'subtitle': "Activez le mode indisponible si besoin",
      'color': Colors.green,
    },
    {
      'icon': LucideIcons.packageCheck,
      'title': "Colis #123 prêt à être livré",
      'subtitle': "Départ prévu à 15h vers Gatineau",
      'color': Colors.blue,
      'actionLabel': "Voir les détails",
      'onActionTap': () {},
    },
    {
      'icon': LucideIcons.mapPin,
      'title': "Proposez un trajet aujourd'hui",
      'subtitle': "Il n'y a aucun trajet actif",
      'color': Colors.orange,
      'actionLabel': "Créer un trajet",
      'onActionTap': () {},
    },
    {
      'icon': LucideIcons.mailQuestion,
      'title': "3 messages non lus",
      'subtitle': "Sophie a répondu au sujet du colis #237",
      'color': Colors.purple,
      'actionLabel': "Lire maintenant",
      'onActionTap': () {},
    },
    {
      'icon': LucideIcons.barChart4,
      'title': "4 trajets cette semaine",
      'subtitle': "Bravo David 👏 Continue comme ça !",
      'color': Colors.indigo,
    },
    {
      'icon': LucideIcons.lightbulb,
      'title': "Tip IA : Livrez à 16h",
      'subtitle': "Basé sur vos habitudes",
      'color': Colors.teal,
      'actionLabel': "Voir suggestions",
      'onActionTap': () {},
    },
    {
      'icon': LucideIcons.helpCircle,
      'title': "Besoin d'aide ?",
      'subtitle': "Le centre d'aide est disponible 24/7",
      'color': Colors.grey,
      'actionLabel': "Contacter",
      'onActionTap': () {},
    },
    {
      'icon': LucideIcons.gift,
      'title': "🎁 Parrainage dispo",
      'subtitle': "Invitez un ami et recevez 10 \$",
      'color': Colors.pink,
      'actionLabel': "Partager",
      'onActionTap': () {},
    },
  ];

  static Widget _smartCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(51), // 0.2 * 255 = 51
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withAlpha(38), // 0.15 * 255 = 38
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: onActionTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ),
        ],
      ),
    );
  }
}
