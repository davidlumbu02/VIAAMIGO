import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? suffixText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;                    // ✅ Ajouté
  final TextInputType keyboardType;
  final bool isTransparent;
  final String? errorText;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;           // ✅ Ajouté
  final double borderRadius;
  final int? maxLines;
  final Color? borderColor;                    // ✅ Renommé pour clarté
  final Color? errorBorderColor;               // ✅ Ajouté
  final Color? fillColor;                      // ✅ Ajouté
  final bool enabled;                          // ✅ Ajouté
  final bool readOnly;                         // ✅ Ajouté
  final String? semanticsLabel;                // ✅ Accessibilité
  final bool hasBorder; // ✅ Ajouté
    final VoidCallback? onTap;                // ✅ NEW

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.suffixText,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.isTransparent = false,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.borderRadius = 30,
    this.errorText,
    this.maxLines,
    this.borderColor,
    this.errorBorderColor,
    this.fillColor,
    this.enabled = true,
    this.readOnly = false,
    this.semanticsLabel,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;
  bool get _hasError => widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: widget.semanticsLabel,
      enabled: widget.enabled,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        focusNode: widget.focusNode,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,              // ✅ Ajouté
        enabled: widget.enabled,                  // ✅ Ajouté
        readOnly: widget.readOnly,                // ✅ Ajouté
        onTap: widget.onTap,                      // ✅ NEW
        style: theme.textTheme.bodyMedium?.copyWith(
          color: widget.enabled ? null : theme.colorScheme.onSurface.withAlpha(100),
        ),
        maxLines: widget.obscureText ? 1 : (widget.maxLines ?? 1), // ✅ Sécurité
        decoration: InputDecoration(
          labelText: widget.labelText,            // ✅ Simplifié
          hintText: widget.hintText,
          helperText: widget.helperText,
          suffixText: widget.suffixText,
          labelStyle: TextStyle(
            color: _hasError 
              ? theme.colorScheme.error 
              : theme.colorScheme.outline,
          ),
          filled: true,
          fillColor: widget.fillColor ?? 
            (widget.isTransparent
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerHighest),
          prefixIcon: widget.prefixIcon,
          suffixIcon: _buildSuffixIcon(theme),    // ✅ Méthode séparée
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          
          // ✅ Bordures améliorées
enabledBorder: widget.hasBorder
    ? OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: _hasError 
            ? (widget.errorBorderColor ?? theme.colorScheme.error)
            : (widget.borderColor ?? theme.colorScheme.outline),
        ),
      )
    : InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: _hasError 
                ? (widget.errorBorderColor ?? theme.colorScheme.error)
                : (widget.borderColor ?? theme.colorScheme.primary),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.errorBorderColor ?? theme.colorScheme.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.errorBorderColor ?? theme.colorScheme.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(100),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          errorText: widget.errorText,
          errorStyle: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ✅ Logique du suffixIcon séparée et améliorée
  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }
    
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          color: theme.colorScheme.outline,
        ),
        onPressed: widget.enabled ? () => setState(() => _obscure = !_obscure) : null,
        tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe', // ✅ Accessibilité
      );
    }
    
    return null;
  }
}

/*import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;        // ✅ Ajouté
  final String? helperText;       // ✅ Ajouté
  final String? suffixText;       // ✅ Ajouté
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final TextInputType keyboardType;
  final bool isTransparent;
  final String? errorText;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final double borderRadius;
  final int? maxLines;
  final Color? bordercolor;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,      // ✅
    this.helperText,     // ✅
    this.suffixText,     // ✅
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isTransparent = false,
    this.focusNode,
    this.onSubmitted,
    this.borderRadius = 30,
    this.errorText,
    this.maxLines,
    this.bordercolor,
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
      maxLines: widget.maxLines ?? 1,
      decoration: InputDecoration(
        labelText: widget.labelText ?? widget.hintText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        suffixText: widget.suffixText,
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
          borderSide: BorderSide(color: widget.bordercolor ?? theme.colorScheme.primary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        errorText: widget.errorText,
        errorStyle: TextStyle(
          color: theme.colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
*/