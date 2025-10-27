import 'package:flutter/material.dart';
import '../theme/app_design.dart';

/// Özel animasyonlu bildirim sistemi
class CustomNotification {
  static OverlayEntry? _currentOverlay;
  
  /// Başarı bildirimi göster
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFF4CAF50),
      duration: duration,
    );
  }
  
  /// Hata bildirimi göster
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: const Color(0xFFF44336),
      duration: duration,
    );
  }
  
  /// Bilgi bildirimi göster
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: AppDesign.primaryColor,
      duration: duration,
    );
  }
  
  /// Uyarı bildirimi göster
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: const Color(0xFFFF9800),
      duration: duration,
    );
  }
  
  /// Özel bildirim göster
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Önceki bildirimi kaldır
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 400),
    );
    
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        slideAnimation: slideAnimation,
        fadeAnimation: fadeAnimation,
        onDismiss: () {
          animationController.dispose();
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );
    
    overlay.insert(_currentOverlay!);
    animationController.forward();
    
    // Otomatik kapanma
    Future.delayed(duration, () async {
      if (_currentOverlay != null) {
        await animationController.reverse();
        animationController.dispose();
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }
}

class _NotificationWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // İkon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Mesaj
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Kapat butonu
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
