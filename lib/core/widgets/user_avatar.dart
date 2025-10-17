import 'package:flutter/material.dart';
import '../theme/app_design.dart';

/// Kullanıcı profil avatarı
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials; // İsim soy isim baş harfleri (örn: "AB")
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.primaryColor,
              AppDesign.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesign.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
        ),
        child: ClipOval(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Eğer profil resmi varsa onu göster
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Resim yüklenemezse initials göster
          return _buildInitials();
        },
      );
    }
    
    // Profil resmi yoksa initials göster
    return _buildInitials();
  }

  Widget _buildInitials() {
    final displayText = initials?.toUpperCase() ?? '?';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppDesign.primaryColor,
            AppDesign.primaryColor.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
