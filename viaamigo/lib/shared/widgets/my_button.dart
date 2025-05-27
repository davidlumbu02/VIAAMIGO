import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final bool isLoading;
  final bool outlined;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  // ✅ Nouveau paramètre optionnel
  final bool isDisabled;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    this.isLoading = false,
    this.outlined = false,
    this.width,
    this.height,
    this.margin,
    this.borderRadius = 10,
    this.isDisabled = false, // ✅ valeur par défaut
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = outlined
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;

    final backgroundColor = isDisabled
        ? theme.disabledColor.withAlpha(25)
        : outlined
            ? Colors.transparent
            : theme.colorScheme.primary;

    final borderColor = outlined
        ? theme.colorScheme.outline
        : Colors.transparent;

    return GestureDetector(
      onTap: (isLoading || isDisabled) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDisabled
                      ? theme.disabledColor.withAlpha(150)
                      : textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
