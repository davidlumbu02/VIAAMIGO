class PriceCalculator {
  // Tarifs de base (à terme, ces valeurs viendront de Firestore config)
  static const double _basePricePerKm = 1.50; // CAD par km
  static const double _weightMultiplier = 0.50; // CAD par kg supplémentaire au-delà de 5kg
  static const double _platformFeePercent = 0.05; // 5% de frais de plateforme
  static const double _minimumPrice = 5.00; // Prix minimum
  
  // Multiplicateurs selon vitesse de livraison
  static const Map<String, double> _speedMultipliers = {
    'economy': 0.8,    // -20%
    'standard': 1.0,   // Prix normal
    'express': 1.5,    // +50%
  };
  
  // Tarifs d'assurance (% de la valeur déclarée)
  static const Map<String, double> _insuranceRates = {
    'none': 0.0,
    'basic': 0.01,     // 1%
    'premium': 0.02,   // 2%
  };
  
  /// Calcule le prix estimé d'une livraison
  static double calculateEstimatedPrice({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
  }) {
    // 1. Prix de base selon distance
    double basePrice = distanceKm * _basePricePerKm;
    
    // 2. Ajout selon poids (si > 5kg)
    if (weightKg > 5.0) {
      double extraWeight = weightKg - 5.0;
      basePrice += extraWeight * _weightMultiplier;
    }
    
    // 3. Multiplicateur selon vitesse
    double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
    basePrice *= speedMultiplier;
    
    // 4. Calcul de l'assurance
    double insuranceFee = 0.0;
    if (insuranceLevel != 'none' && declaredValue != null && declaredValue > 0) {
      double rate = _insuranceRates[insuranceLevel] ?? 0.0;
      insuranceFee = declaredValue * rate;
    }
    
    // 5. Prix total avant frais de plateforme
    double subtotal = basePrice + insuranceFee;
    
    // 6. Frais de plateforme
    double platformFee = subtotal * _platformFeePercent;
    
    // 7. Prix final
    double finalPrice = subtotal + platformFee;
    
    // 8. Appliquer le prix minimum
    return finalPrice < _minimumPrice ? _minimumPrice : finalPrice;
  }
  
  /// Calcule les frais d'assurance séparément
  static double calculateInsuranceFee(String insuranceLevel, double? declaredValue) {
    if (insuranceLevel == 'none' || declaredValue == null || declaredValue <= 0) {
      return 0.0;
    }
    
    double rate = _insuranceRates[insuranceLevel] ?? 0.0;
    return declaredValue * rate;
  }
  
  /// Calcule les frais de plateforme
  static double calculatePlatformFee(double basePrice) {
    return basePrice * _platformFeePercent;
  }
  
  /// Calcule une estimation de prix rapide (sans assurance)
  static double calculateQuickEstimate(double distanceKm, double weightKg) {
    return calculateEstimatedPrice(
      distanceKm: distanceKm,
      weightKg: weightKg,
      deliverySpeed: 'standard',
      insuranceLevel: 'none',
    );
  }
  
  /// Retourne le détail du calcul pour affichage
  static PriceBreakdown calculatePriceBreakdown({
    required double distanceKm,
    required double weightKg,
    required String deliverySpeed,
    double? declaredValue,
    required String insuranceLevel,
  }) {
    // Calculs étape par étape
    double basePrice = distanceKm * _basePricePerKm;
    
    double weightSurcharge = 0.0;
    if (weightKg > 5.0) {
      weightSurcharge = (weightKg - 5.0) * _weightMultiplier;
      basePrice += weightSurcharge;
    }
    
    double speedMultiplier = _speedMultipliers[deliverySpeed] ?? 1.0;
    double adjustedPrice = basePrice * speedMultiplier;
    
    double insuranceFee = calculateInsuranceFee(insuranceLevel, declaredValue);
    double subtotal = adjustedPrice + insuranceFee;
    double platformFee = calculatePlatformFee(subtotal);
    double total = subtotal + platformFee;
    
    if (total < _minimumPrice) {
      total = _minimumPrice;
    }
    
    return PriceBreakdown(
      distanceKm: distanceKm,
      weightKg: weightKg,
      basePrice: distanceKm * _basePricePerKm,
      weightSurcharge: weightSurcharge,
      speedMultiplier: speedMultiplier,
      adjustedPrice: adjustedPrice,
      insuranceFee: insuranceFee,
      platformFee: platformFee,
      subtotal: subtotal,
      total: total,
      minimumApplied: total == _minimumPrice,
    );
  }
}

/// Classe pour le détail du calcul de prix
class PriceBreakdown {
  final double distanceKm;
  final double weightKg;
  final double basePrice;
  final double weightSurcharge;
  final double speedMultiplier;
  final double adjustedPrice;
  final double insuranceFee;
  final double platformFee;
  final double subtotal;
  final double total;
  final bool minimumApplied;
  
  PriceBreakdown({
    required this.distanceKm,
    required this.weightKg,
    required this.basePrice,
    required this.weightSurcharge,
    required this.speedMultiplier,
    required this.adjustedPrice,
    required this.insuranceFee,
    required this.platformFee,
    required this.subtotal,
    required this.total,
    required this.minimumApplied,
  });
}