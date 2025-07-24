import 'package:flutter/material.dart';

/// Modèle représentant une route dans l'application
///
/// Ce modèle permet de définir des routes avec leurs caractéristiques:
/// - Un nom unique pour l'identification
/// - Une fonction de création de page (construction paresseuse)
/// - Des paramètres comme l'affichage de la bottom bar
class AppRoute {
  /// Identifiant unique de la route
  final String name;
  
  /// Fonction qui construit la page à la demande (lazy loading)
  /// Permet d'économiser des ressources en ne créant la page que lorsqu'elle est nécessaire
  final Widget Function() pageBuilder;
  
  /// Détermine si la bottom bar doit être affichée sur cette route
  /// Par défaut à true (afficher la barre)
  final bool showBottomBar;
  
  /// Constructeur avec paramètres nommés
  const AppRoute({
    required this.name,         // Nom obligatoire
    required this.pageBuilder,  // Builder de page obligatoire
    this.showBottomBar = true,  // Par défaut, on affiche la bottom bar
  });
  }