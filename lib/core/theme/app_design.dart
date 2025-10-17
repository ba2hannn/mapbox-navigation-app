import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılacak tasarım sabitleri
class AppDesign {
  AppDesign._();

  // Renkler
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color backgroundColor = Colors.white;
  static const Color overlayColor = Color(0xF5F5F5FF);
  static const Color shadowColor = Colors.black;
  static const Color iconColor = Color(0xFF1E88E5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Boyutlar
  static const double buttonSize = 44.0;
  static const double buttonRadius = 22.0;
  static const double buttonIconSize = 22.0;
  static const double buttonPadding = 16.0;
  
  static const double panelRadius = 24.0;
  static const double panelHandleWidth = 40.0;
  static const double panelHandleHeight = 5.0;
  static const double panelPadding = 16.0;

  // Gölgeler
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get panelShadow => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ];

  // Animasyon süreleri
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 400);
}
