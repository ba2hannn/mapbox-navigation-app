import 'package:flutter/material.dart';
import '../theme/app_design.dart';

/// Özel animasyonlu bildirim sistemi - Top gibi düşen ve genişleyen bildirim
class AnimatedNotification {
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
      duration: const Duration(milliseconds: 800),
    );

    // Animasyonlar
    final dropAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.bounceOut),
    ));

    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.1, 0.4, curve: Curves.elasticOut),
    ));

    final widthAnimation = Tween<double>(
      begin: 60.0,
      end: MediaQuery.of(context).size.width - 32,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    ));

    final contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
    ));

    _currentOverlay = OverlayEntry(
      builder: (context) => _AnimatedNotificationWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        dropAnimation: dropAnimation,
        scaleAnimation: scaleAnimation,
        widthAnimation: widthAnimation,
        contentFadeAnimation: contentFadeAnimation,
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
        await _startDismissAnimation(animationController);
      }
    });
  }

  /// Kapanma animasyonu başlat
  static Future<void> _startDismissAnimation(AnimationController controller) async {
    // Basit fade out ve yukarı çıkma animasyonu
    await controller.reverse();
    controller.dispose();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Tüm bildirimleri temizle
  static void dismissAll() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _AnimatedNotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Animation<double> dropAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> widthAnimation;
  final Animation<double> contentFadeAnimation;
  final VoidCallback onDismiss;

  const _AnimatedNotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.dropAnimation,
    required this.scaleAnimation,
    required this.widthAnimation,
    required this.contentFadeAnimation,
    required this.onDismiss,
  });

  @override
  State<_AnimatedNotificationWidget> createState() => _AnimatedNotificationWidgetState();
}

class _AnimatedNotificationWidgetState extends State<_AnimatedNotificationWidget>
    with TickerProviderStateMixin {

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Drop animasyonu bittiğinde bounce başlat
    widget.dropAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20 + widget.dropAnimation.value,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.scaleAnimation,
          widget.widthAnimation,
          widget.contentFadeAnimation,
          _bounceAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.scaleAnimation.value,
            child: Container(
              width: widget.widthAnimation.value,
              height: 70,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.1),
                    BlendMode.srcOver,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon
                        FadeTransition(
                          opacity: widget.contentFadeAnimation,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Mesaj
                        Expanded(
                          child: FadeTransition(
                            opacity: widget.contentFadeAnimation,
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Kapat butonu
                        FadeTransition(
                          opacity: widget.contentFadeAnimation,
                          child: GestureDetector(
                            onTap: widget.onDismiss,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}