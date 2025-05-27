import 'package:flutter/material.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String hintText,
  bool obscureText = false,
  InputBorder? border, // Changement de type ici
  Widget? suffixIcon,
  Widget? prefixIcon, // Ajout de l'argument prefixIcon
  String? Function(String?)? validator,
  bool bottomBorder = false,
  bool isTransparent = false,
}) {
  return Container(
    // Padding ajusté pour réduire la hauteur si nécessaire
    padding: const EdgeInsets.symmetric(horizontal: 5),  // Vous pouvez ajuster ce padding si besoin
    decoration: bottomBorder
        ? BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          )
        : null,
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: isTransparent ? Colors.transparent : Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        border: border ?? OutlineInputBorder(borderRadius: BorderRadius.circular(30)), // Contours arrondis
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25), // Contour lorsque le champ est sélectionné
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300), // Contour normal
          borderRadius: BorderRadius.circular(30),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon, // Utilisation de l'argument prefixIcon
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),  // Réduire la hauteur ici
      ),
      validator: validator,
    ),
  );
}
