import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';

class GamingCenterBottomSheet extends StatelessWidget {
  final Map<String, dynamic> center;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const GamingCenterBottomSheet({
    super.key,
    required this.center,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Gaming Center Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.videogame_asset,
                        color: AppColors.green,
                        size: 30,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Center Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            center['address'],
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Close Button
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Status and Rating
                Row(
                  children: [
                    // Open Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: center['isOpen'] 
                            ? AppColors.green.withValues(alpha: 0.2) 
                            : AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: center['isOpen'] 
                              ? AppColors.green 
                              : AppColors.error,
                        ),
                      ),
                      child: Text(
                        center['isOpen'] ? 'common.open_now'.tr() : 'common.closed'.tr(),
                        style: TextStyle(
                          color: center['isOpen'] 
                              ? AppColors.green 
                              : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          center['rating'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Distance
                    Text(
                      '${center['distance']} ${'map.km_away'.tr()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Consoles Available
                Text(
                  'map_bottom_sheet.available_consoles'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (center['consoles'] as List<String>).map((console) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        console,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Price Range
                Row(
                  children: [
                    Text(
                      'map_bottom_sheet.price_range'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      center['priceRange'],
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    // Open in Google Maps button
                    if (center['latitude'] != null && center['longitude'] != null)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final lat = center['latitude'];
                            final lng = center['longitude'];
                            final name = Uri.encodeComponent(center['name']);
                            // Try native maps app first
                            final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
                            if (await canLaunchUrl(geoUrl)) {
                              await launchUrl(geoUrl);
                            } else {
                              // Fallback to web browser
                              final webUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                              );
                              if (await canLaunchUrl(webUrl)) {
                                await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text('map_bottom_sheet.maps'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (center['latitude'] != null && center['longitude'] != null)
                      const SizedBox(width: 12),
                    // View Details button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'map_bottom_sheet.view_details'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
