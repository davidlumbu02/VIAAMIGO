import 'package:flutter/material.dart';

class NotchedClipper extends CustomClipper<Path> {
  final double notchRadius;

  NotchedClipper({this.notchRadius = 28});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double fabX = size.width / 2;
    const double notchMargin = 8;

    path.moveTo(0, 0);
    path.lineTo(fabX - notchRadius - notchMargin, 0);

    // courbe du notch
    path.quadraticBezierTo(
      fabX - notchRadius,
      -8,
      fabX,
      -8,
    );
    path.quadraticBezierTo(
      fabX + notchRadius,
      -8,
      fabX + notchRadius + notchMargin,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
