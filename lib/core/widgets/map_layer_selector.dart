import 'package:flutter/material.dart';
import '../theme/app_design.dart';

/// Harita katman seçici dialog'u
class MapLayerSelector extends StatelessWidget {
  final String currentLayer;
  final Function(String) onLayerSelected;

  const MapLayerSelector({
    super.key,
    required this.currentLayer,
    required this.onLayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppDesign.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.panelRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.panelPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Harita Katmanı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Aktif katmanlar
            _buildLayerItem(
              'Standard',
              'Varsayılan harita',
              'STANDARD',
              Icons.map,
            ),
            _buildLayerItem(
              'Standard Satellite',
              'Uydu görünümü ile',
              'STANDARD_SATELLITE',
              Icons.satellite_alt,
            ),
            
            const Divider(height: 24),
            
            // Legacy katmanlar
            const Text(
              'Eski Katmanlar',
              style: TextStyle(
                fontSize: 14,
                color: AppDesign.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildLayerItem(
              'Streets',
              'Sokak haritası',
              'MAPBOX_STREETS',
              Icons.location_city,
            ),
            _buildLayerItem(
              'Light',
              'Açık tema',
              'LIGHT',
              Icons.light_mode,
            ),
            _buildLayerItem(
              'Dark',
              'Koyu tema',
              'DARK',
              Icons.dark_mode,
            ),
            _buildLayerItem(
              'Outdoors',
              'Açık hava aktiviteleri',
              'OUTDOORS',
              Icons.terrain,
            ),
            _buildLayerItem(
              'Satellite',
              'Sadece uydu',
              'SATELLITE',
              Icons.satellite,
            ),
            _buildLayerItem(
              'Satellite Streets',
              'Uydu + sokaklar',
              'SATELLITE_STREETS',
              Icons.map_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerItem(String title, String subtitle, String layerKey, IconData icon) {
    final isSelected = currentLayer == layerKey;
    
    return InkWell(
      onTap: () => onLayerSelected(layerKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppDesign.primaryColor.withValues(alpha: 0.1) : AppDesign.overlayColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppDesign.primaryColor : AppDesign.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppDesign.primaryColor : AppDesign.iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppDesign.primaryColor : AppDesign.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppDesign.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppDesign.primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
