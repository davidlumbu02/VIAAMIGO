import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/src/fonctionnalites/recherche/screens/recheche_page.dart';


/// Onglet Colis - Style Cocolis avec carte interactive
/// 
/// Fonctionnalités :
/// - Barre de recherche géographique
/// - Toggle Map/List view
/// - Filtres rapides
/// - Compteur de listings
/// - Cartes/marqueurs de prix/// Onglet Colis - Style Cocolis avec carte interactive - CORRIGÉ
/// 
/// Fonctionnalités :
/// - Barre de recherche géographique
/// - Toggle Map/List view
/// - Filtres rapides
/// - Compteur de listings
/// - Cartes/marqueurs de prix
/// 
/// ✅ CORRIGÉ : Remplacement de .withOpacity() par .withValues(alpha:)
class ParcelsTab extends StatelessWidget {
  const ParcelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<SearchPageController>();

    return Obx(() => Column(
      children: [
        // Système de recherche Cocolis pour colis
        _buildCocolisSearchHeader(context, theme, controller),
        
        // Header avec compteur et toggle Map/List
        _buildHeaderWithToggle(context, theme, controller),
        
        // Contenu : Map ou List
        Expanded(
          child: controller.isMapView.value 
              ? _buildInteractiveMap(context, theme)
              : _buildCocolisStyleList(context, theme),
        ),
      ],
    ));
  }

  /// Header avec compteur et toggle Map/List (style Cocolis) - CORRIGÉ
  Widget _buildHeaderWithToggle(BuildContext context, ThemeData theme, SearchPageController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            '4433 listings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          
          // Toggle Map/List
          Container(
            decoration: BoxDecoration(
              // ✅ CORRIGÉ : withOpacity → withValues
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildToggleButton('List', !controller.isMapView.value, () {
                  controller.setMapView(false);
                }, theme),
                _buildToggleButton('Map', controller.isMapView.value, () {
                  controller.setMapView(true);
                }, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Système de recherche Cocolis pour colis - CORRIGÉ
  Widget _buildCocolisSearchHeader(BuildContext context, ThemeData theme, SearchPageController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color:theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            // ✅ CORRIGÉ : withOpacity → withValues
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche principale (style Cocolis)
          Container(
            decoration: BoxDecoration(
              // ✅ CORRIGÉ : withOpacity → withValues
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                // ✅ CORRIGÉ : withOpacity → withValues
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: CustomTextField(
              controller: TextEditingController(),
                hintText: 'Search for city, address...',
              isTransparent: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              hasBorder: true,
              borderColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                prefixIcon: Icon(
                  Icons.search,
                  // ✅ CORRIGÉ : withOpacity → withValues
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    // Filtres pour colis
                    _showParcelsFilters(context, theme);
                  },
                  icon: Icon(
                    Icons.tune,
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

              
            ),
          ),
          
          const SizedBox(height: 5),
          
          // Filtres rapides spécifiques aux colis
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilter('View all', true, theme),
                const SizedBox(width: 12),
                _buildQuickFilter('Mes routes', false, theme),
                const SizedBox(width: 12),
                _buildQuickFilter('Urgent', false, theme),
                const SizedBox(width: 12),
                _buildQuickFilter('Près de moi', false, theme),
                const SizedBox(width: 12),
                _buildQuickFilter('Réservation instantanée', false, theme),
              ],
            ),
          ),
          
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  /// Bouton toggle Map/List
  Widget _buildToggleButton(String label, bool isActive, VoidCallback onPressed, ThemeData theme) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? Colors.white : theme.colorScheme.primary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Carte interactive (simulée) - CORRIGÉ
  Widget _buildInteractiveMap(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        // ✅ CORRIGÉ : withOpacity → withValues
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      ),
      child: Stack(
        children: [
          // Simuler une carte
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // ✅ CORRIGÉ : withOpacity → withValues
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.1),
                  Colors.yellow.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          
          // Markers de prix simulés
          ..._buildPriceMarkers(theme),
          
          // Info popup en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Touchez un marqueur pour voir les détails',
                style: theme.textTheme.bodyMedium?.copyWith(
                  // ✅ CORRIGÉ : withOpacity → withValues
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Markers de prix sur la carte - CORRIGÉ
  List<Widget> _buildPriceMarkers(ThemeData theme) {
    final markers = [
      {'price': '123 €', 'top': 150.0, 'left': 100.0},
      {'price': '89 €', 'top': 200.0, 'left': 200.0},
      {'price': '45 €', 'top': 180.0, 'left': 150.0},
      {'price': '67 €', 'top': 250.0, 'left': 120.0},
    ];
    
    return markers.map((marker) {
      return Positioned(
        top: marker['top'] as double,
        left: marker['left'] as double,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // ✅ CORRIGÉ : withOpacity → withValues
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            marker['price'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Liste style Cocolis
  Widget _buildCocolisStyleList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 50,
      itemBuilder: (context, index) {
        return _buildCocolisStyleCard(context, theme, index);
      },
    );
  }

  /// Carte style Cocolis - CORRIGÉ
  Widget _buildCocolisStyleCard(BuildContext context, ThemeData theme, int index) {
    final items = [
      {
        'title': 'Table de ferme en chêne massif',
        'from': 'Le Pellerin (44640)',
        'to': 'Levallois-Perret (92300)',
        'date': 'Between 10 Sep and 19 Sep',
        'price': '123 €',
        'badges': ['XXL'],
      },
      {
        'title': 'Moto Suzuki',
        'from': 'Vergiate',
        'to': 'Saint-Médard-en-Jalles',
        'date': 'Between 11 Sep and 25 Sep',
        'price': '300 €',
        'badges': ['XXL'],
      },
      {
        'title': 'Armoire vintage à croisillons',
        'from': 'Ermont (95120)',
        'to': 'Saint-Maximin (30700)',
        'date': 'Between 10 Sep and 24 Sep',
        'price': '149.50 €',
        'badges': ['XXL', 'URGENT'],
      },
    ];
    
    final item = items[index % items.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ✅ CORRIGÉ : withOpacity → withValues
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            // ✅ CORRIGÉ : withOpacity → withValues
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec titre et prix
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item['title'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item['price'] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Locations avec icônes
            Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  item['from'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 12,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  item['to'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // ✅ CORRIGÉ : withOpacity → withValues
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date et badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['date'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      // ✅ CORRIGÉ : withOpacity → withValues
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                
                // Badges
                ...((item['badges'] as List<String>).map((badge) {
                  final isUrgent = badge == 'URGENT';
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUrgent 
                          // ✅ CORRIGÉ : withOpacity → withValues
                          ? Colors.orange.withValues(alpha: 0.1)
                          : theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isUrgent 
                            // ✅ CORRIGÉ : withOpacity → withValues
                            ? Colors.orange.withValues(alpha: 0.3)
                            : theme.colorScheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUrgent) ...[
                          Icon(
                            Icons.bolt,
                            size: 10,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUrgent 
                                ? Colors.orange
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Filtre rapide - CORRIGÉ
  Widget _buildQuickFilter(String label, bool isActive, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            // ✅ CORRIGÉ : withOpacity → withValues
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive 
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            _getFilterIcon(label),
            size: 20,
            color: isActive 
                ? theme.colorScheme.primary
                // ✅ CORRIGÉ : withOpacity → withValues
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive 
                  ? theme.colorScheme.primary
                  // ✅ CORRIGÉ : withOpacity → withValues
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Icônes pour les filtres
  IconData _getFilterIcon(String label) {
    switch (label) {
      case 'View all': return LucideIcons.galleryHorizontalEnd;//Icons.grid_view;
      case 'Mes routes': return Icons.route;
      case 'Urgent': return LucideIcons.zap;
      case 'Près de moi': return LucideIcons.locateFixed;//Icons.place;
      case 'Réservation instantanée': return LucideIcons.link;//Icons.flash_on;
      default: return Icons.category;
    }
  }

  /// Afficher les filtres pour colis
  void _showParcelsFilters(BuildContext context, ThemeData theme) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtres pour Colis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ici vous pouvez ajouter vos filtres spécifiques aux colis'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}