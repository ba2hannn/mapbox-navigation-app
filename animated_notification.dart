// lib/widgets/animated_notification.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    // 1. Yukarıdan kayma animasyonu - daha yumuşak
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    );

    // 2. Yuvarlaktan genişlemeye animasyon - daha smooth
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    // Animasyon sırası
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    try {
      // 1. Kayma animasyonu - yukarıdan gelme
      if (!mounted) return;
      await _slideController.forward();
      
      // Kısa bir duraklama
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 2. Genişleme animasyonu - top -> mesaj
      if (!mounted) return;
      await _expandController.forward();
      
      // 3. 2.5 saniye bekle - mesaj okunuyor
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // 4. Kapanma animasyonu - mesaj -> top
      if (!mounted) return;
      await _expandController.reverse();
      
      // Kısa bir duraklama
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 5. Yukarı kayma - top yukarı gidiyor
      if (!mounted) return;
      await _slideController.reverse();
      
      // 6. Bildirimi kaldır
      if (mounted) {
        widget.onDismiss();
      }
    } catch (e) {
      // Animasyon hatalarını yakala ve görmezden gel
      debugPrint('Bildirim animasyon hatası (normal): $e');
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  @override
  void dispose() {
    // Animasyonları güvenli şekilde durdur ve dispose et
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
        // Mesaj uzunluğuna göre optimal genişlik hesapla
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
        
        // Genişlik animasyonu: 60px (top) -> mesaja uygun genişlik
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = screenWidth - 32; // 16px margin her yandan
        // Mesaj genişliği + ikon (60px) + sağ padding (20px) + biraz marj (10px)
        final messageWidth = (textPainter.width + 90).clamp(60.0, maxWidth);
        final currentWidth = 60.0 + ((messageWidth - 60.0) * _expandAnimation.value);

        // Yükseklik animasyonu: Mesaj tam yuvarlak içine sığsın
        const minHeight = 60.0;
        const maxHeight = 64.0; // Biraz daha yüksek
        final currentHeight = minHeight + ((maxHeight - minHeight) * _expandAnimation.value);

        // Border radius: Tam yuvarlak -> çok yuvarlak köşeler (oval)
        final borderRadius = (currentHeight / 2) - (2.0 * _expandAnimation.value); // Dinamik yuvarlak

        // Y pozisyonu
        final topPosition = MediaQuery.of(context).padding.top + 16;
        final yOffset = -80 + (80 * _slideAnimation.value);

        return Positioned(
          top: topPosition + yOffset,
          left: (screenWidth - currentWidth) / 2,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5) {
                // Yukarı kaydırma - hızlı kapat
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
            child: Container(
              width: currentWidth,
              height: currentHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias, // İçeriği kırp, taşma olmasın
              child: Stack(
                children: [
                  // İkon - Dikey ortalanmış, yuvarlak
                  Positioned(
                    left: (currentHeight - 32) / 2, // Yüksekliğe göre ortala
                    top: (currentHeight - 32) / 2, // Yüksekliğe göre ortala
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle, // Tam yuvarlak
                      ),
                      child: Icon(
                        widget.isError
                            ? CupertinoIcons.info_circle_fill
                            : CupertinoIcons.checkmark_alt_circle_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  
                  // Mesaj - Yavaşça görünüyor, tam ortalanmış
                  if (_expandAnimation.value > 0.2)
                    Positioned.fill(
                      left: currentHeight + 4, // İkondan sonra başla
                      right: 16,
                      child: Opacity(
                        opacity: (((_expandAnimation.value - 0.2) / 0.8).clamp(0.0, 1.0)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Bildirim gösterme helper fonksiyonu
class NotificationHelper {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Mevcut bildirimi kaldır
    _currentEntry?.remove();
    _currentEntry = null;

    // Yeni bildirimi oluştur
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
