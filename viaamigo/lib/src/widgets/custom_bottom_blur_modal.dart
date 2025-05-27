import 'dart:ui';
import 'package:flutter/material.dart';

class BottomSheetWithBlur extends StatelessWidget {
  final Widget child;
  const BottomSheetWithBlur({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🌫 Flou d’arrière-plan
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
           color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
          ),
        ),

        /// 📦 Contenu du modal (scrollable + draggable)
        child,
      ],
    );
  }
}
