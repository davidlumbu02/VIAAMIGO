import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final TextInputType keyboardType;
  final bool isTransparent;
  // Ajouter le paramètre errorText
  final String? errorText;

  // ✅ Nouveaux paramètres
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final double borderRadius; // 👈 ajouté ici

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isTransparent = false,
    this.focusNode,
    this.onSubmitted,
    this.borderRadius = 30, // 👈 valeur par défaut
    this.errorText, // Ajouter le paramètre dans le constructeur
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onSubmitted,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.hintText,
        labelStyle: TextStyle(color: theme.colorScheme.outline),
        filled: true,
        fillColor: widget.isTransparent
            ? Colors.transparent
            : theme.colorScheme.surfaceContainerHighest,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.outline,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        // Utiliser le paramètre errorText pour afficher les erreurs
        errorText: widget.errorText,
        // Style du texte d'erreur
        errorStyle: TextStyle(
          color: theme.colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
