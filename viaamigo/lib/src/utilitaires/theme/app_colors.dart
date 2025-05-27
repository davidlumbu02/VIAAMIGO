import 'package:flutter/material.dart';

@immutable
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
}
