import 'package:flutter/material.dart';

class GreetingStyle {
  const GreetingStyle({
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.textColor,
    required this.skyPainter,
  });

  final String label;
  final LinearGradient gradient;
  final Color accentColor;
  final Color textColor;
  final CustomPainter skyPainter;
}
