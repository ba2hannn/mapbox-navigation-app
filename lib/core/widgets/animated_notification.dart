// lib/core/widgets/animated_notification.dart
import 'package:flutter/material.dart';
import '../theme/app_design.dart';

class AnimatedNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const AnimatedNotification({
    super.key,
    required this.message,
    this.isError = false,
    required this.onDismiss,
  });

  @override
  State<AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<AnimatedNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;

  late Animation<double> _slideAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    try {
      if (!mounted) return;
      await _slideController.forward();
      
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      await _expandController.forward();
      
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;
      await _expandController.reverse();
      
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      await _slideController.reverse();
      
      if (mounted) {
        widget.onDismiss();
      }
    } catch (e) {
      debugPrint('Bildirim animasyon hatası: $e');
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  @override
  void dispose() {
    try {
      _slideController.stop(canceled: true);
      _slideController.dispose();
    } catch (e) {
      debugPrint('Slide controller dispose hatası: $e');
    }
    
    try {
      _expandController.stop(canceled: true);
      _expandController.dispose();
    } catch (e) {
      debugPrint('Expand controller dispose hatası: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _expandAnimation]),
      builder: (context, child) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: MediaQuery.of(context).size.width - 120);
        
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = screenWidth - 32;
        final messageWidth = (textPainter.width + 90).clamp(60.0, maxWidth);
        final currentWidth = 60.0 + ((messageWidth - 60.0) * _expandAnimation.value);

        const minHeight = 60.0;
        const maxHeight = 64.0;
        final currentHeight = minHeight + ((maxHeight - minHeight) * _expandAnimation.value);

        final borderRadius = (currentHeight / 2) - (2.0 * _expandAnimation.value);

        final topPosition = MediaQuery.of(context).padding.top + 16;
        final yOffset = -80 + (80 * _slideAnimation.value);

        return Positioned(
          top: topPosition + yOffset,
          left: (screenWidth - currentWidth) / 2,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5) {
                if (mounted && _expandController.isAnimating == false && _slideController.isAnimating == false) {
                  _expandController.reverse().catchError((e) => null);
                  _slideController.reverse().catchError((e) => null);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      widget.onDismiss();
                    }
                  });
                }
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: currentWidth,
                height: currentHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isError
                        ? [
                            const Color(0xFFEF5350),
                            const Color(0xFFE53935),
                          ]
                        : [
                            AppDesign.primaryColor,
                            AppDesign.primaryColor.withOpacity(0.85),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isError 
                          ? const Color(0xFFE53935) 
                          : AppDesign.primaryColor).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // İkon - Dikey ortalanmış
                    Positioned(
                      left: (currentHeight - 36) / 2,
                      top: (currentHeight - 36) / 2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    
                    // Mesaj - Yavaşça görünüyor
                    if (_expandAnimation.value > 0.2)
                      Positioned.fill(
                        left: currentHeight + 4,
                        right: 16,
                        child: Opacity(
                          opacity: (((_expandAnimation.value - 0.2) / 0.8).clamp(0.0, 1.0)),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                height: 1.3,
                                decoration: TextDecoration.none,
                              ),
                              child: Text(
                                widget.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationHelper {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => AnimatedNotification(
        message: message,
        isError: isError,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}
