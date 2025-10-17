import 'package:flutter/material.dart';
import '../theme/app_design.dart';

/// Standart harita kontrolü butonu (Apple Maps tarzı)
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final bool isActive; // Aktif durumu (örn: trafik açık/kapalı)

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? AppDesign.buttonSize;
    
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isActive 
              ? AppDesign.primaryColor // Aktifse primary renk
              : (backgroundColor ?? AppDesign.backgroundColor),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          boxShadow: AppDesign.buttonShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonSize / 2),
            onTap: onTap,
            child: Center(
              child: Icon(
                icon,
                color: isActive 
                    ? Colors.white // Aktifse beyaz ikon
                    : (iconColor ?? AppDesign.iconColor),
                size: AppDesign.buttonIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yan yana buton grubu
class MapControlButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const MapControlButtonGroup({
    super.key,
    required this.children,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.backgroundColor,
        borderRadius: BorderRadius.circular(AppDesign.buttonRadius),
        boxShadow: AppDesign.buttonShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AppDesign.dividerColor,
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing / 2,
                  vertical: spacing / 2,
                ),
                child: children[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alt yukarı çeken panel için tutamak
class PanelHandle extends StatelessWidget {
  const PanelHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: AppDesign.panelHandleWidth,
          height: AppDesign.panelHandleHeight,
          decoration: BoxDecoration(
            color: AppDesign.dividerColor,
            borderRadius: BorderRadius.circular(AppDesign.panelHandleHeight / 2),
          ),
        ),
      ),
    );
  }
}

/// Panel başlık widget'ı
class PanelHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const PanelHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.panelPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppDesign.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Animasyonlu buton (ölçek ile göster/gizle)
class AnimatedMapButton extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration? duration;

  const AnimatedMapButton({
    super.key,
    required this.visible,
    required this.child,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: duration ?? AppDesign.fastAnimation,
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
