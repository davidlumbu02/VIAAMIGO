import 'package:flutter/material.dart';
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryLightRef;
  final Color secondaryLightRef;
  final Color tertiaryLightRef;
  final Color appBarColor;

  final Color parcelColor; // 🌿 Pour les fonctionnalités colis
  final Color driverColor; // 🚗 Pour les fonctionnalités trajets

  const AppColors({
    required this.primaryLightRef,
    required this.secondaryLightRef,
    required this.tertiaryLightRef,
    required this.appBarColor,
    required this.parcelColor,
    required this.driverColor,
  });

  @override
  AppColors copyWith({
    Color? primaryLightRef,
    Color? secondaryLightRef,
    Color? tertiaryLightRef,
    Color? appBarColor,
    Color? parcelColor,
    Color? driverColor,
  }) {
    return AppColors(
      primaryLightRef: primaryLightRef ?? this.primaryLightRef,
      secondaryLightRef: secondaryLightRef ?? this.secondaryLightRef,
      tertiaryLightRef: tertiaryLightRef ?? this.tertiaryLightRef,
      appBarColor: appBarColor ?? this.appBarColor,
      parcelColor: parcelColor ?? this.parcelColor,
      driverColor: driverColor ?? this.driverColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryLightRef: Color.lerp(primaryLightRef, other.primaryLightRef, t)!,
      secondaryLightRef: Color.lerp(secondaryLightRef, other.secondaryLightRef, t)!,
      tertiaryLightRef: Color.lerp(tertiaryLightRef, other.tertiaryLightRef, t)!,
      appBarColor: Color.lerp(appBarColor, other.appBarColor, t)!,
      parcelColor: Color.lerp(parcelColor, other.parcelColor, t)!,
      driverColor: Color.lerp(driverColor, other.driverColor, t)!,
    );
  }
}


/*@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryLightRef;
  final Color secondaryLightRef;
  final Color tertiaryLightRef;
  final Color appBarColor;

  const AppColors({
    required this.primaryLightRef,
    required this.secondaryLightRef,
    required this.tertiaryLightRef,
    required this.appBarColor,
  });

  @override
  AppColors copyWith({
    Color? primaryLightRef,
    Color? secondaryLightRef,
    Color? tertiaryLightRef,
    Color? appBarColor,
  }) {
    return AppColors(
      primaryLightRef: primaryLightRef ?? this.primaryLightRef,
      secondaryLightRef: secondaryLightRef ?? this.secondaryLightRef,
      tertiaryLightRef: tertiaryLightRef ?? this.tertiaryLightRef,
      appBarColor: appBarColor ?? this.appBarColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryLightRef: Color.lerp(primaryLightRef, other.primaryLightRef, t)!,
      secondaryLightRef: Color.lerp(secondaryLightRef, other.secondaryLightRef, t)!,
      tertiaryLightRef: Color.lerp(tertiaryLightRef, other.tertiaryLightRef, t)!,
      appBarColor: Color.lerp(appBarColor, other.appBarColor, t)!,
    );
  }
}*/
