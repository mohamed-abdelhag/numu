import 'package:flutter/material.dart';

/// Helper class to convert icon strings to IconData
/// Uses predefined constant icons to support tree-shaking
class IconHelper {
  /// Map of common Material icon codes to their IconData
  static const Map<int, IconData> _iconMap = {
    0xe047: Icons.check_circle_outline,
    0xe163: Icons.favorite_outline,
    0xe39d: Icons.star_outline,
    0xe3c9: Icons.local_fire_department_outlined,
    0xe5d2: Icons.fitness_center_outlined,
    0xe56c: Icons.school_outlined,
    0xe54e: Icons.restaurant_outlined,
    0xe2bf: Icons.bedtime_outlined,
    0xe4eb: Icons.psychology_outlined,
    0xe866: Icons.self_improvement_outlined,
    0xe53f: Icons.book_outlined,
    0xe3a7: Icons.sports_esports_outlined,
    0xe39f: Icons.work_outline,
    0xe0be: Icons.brush_outlined,
    0xe3fc: Icons.music_note_outlined,
    0xe531: Icons.directions_run_outlined,
    0xe7e9: Icons.water_drop_outlined,
    0xe3e2: Icons.lightbulb_outline,
    0xe145: Icons.eco_outlined,
    0xe8f4: Icons.pets_outlined,
    0xe559: Icons.shopping_bag_outlined,
    0xe0af: Icons.attach_money_outlined,
    0xe7fd: Icons.savings_outlined,
    0xe7f4: Icons.casino_outlined,
    0xe0c8: Icons.camera_alt_outlined,
    0xe3b8: Icons.notifications_outlined,
    0xe8b8: Icons.code_outlined,
    0xe30a: Icons.computer_outlined,
    0xe30b: Icons.phone_android_outlined,
    0xe32a: Icons.dashboard_outlined,
    0xe87c: Icons.cookie_outlined,
    0xe3ab: Icons.flight_outlined,
    0xe0c9: Icons.camera_outlined,
    0xe7ee: Icons.beach_access_outlined,
    0xe558: Icons.palette_outlined,
    0xe80b: Icons.celebration_outlined,
    0xe7ef: Icons.science_outlined,
    0xe1b3: Icons.build_outlined,
    0xe23c: Icons.handyman_outlined,
    0xe3ae: Icons.sailing_outlined,
    0xe566: Icons.hiking_outlined,
    0xe55b: Icons.forest_outlined,
    0xe1a3: Icons.emoji_events_outlined,
    0xe8d3: Icons.military_tech_outlined,
    0xe8ea: Icons.all_inclusive_outlined,
    0xe88a: Icons.balance_outlined,
    0xe0d0: Icons.spa_outlined,
    0xe87d: Icons.favorite_border,
    0xe7f5: Icons.health_and_safety_outlined,
    0xe3ba: Icons.medical_services_outlined,
    0xe412: Icons.monitor_heart_outlined,
    0xe3af: Icons.directions_bike_outlined,
    0xe52f: Icons.pool_outlined,
    0xe536: Icons.sports_soccer_outlined,
    0xe539: Icons.sports_basketball_outlined,
    0xe4f4: Icons.sports_tennis_outlined,
    0xe19c: Icons.downhill_skiing_outlined,
    0xe30f: Icons.surfing_outlined,
    0xe19d: Icons.kayaking_outlined,
    0xe1a4: Icons.rowing_outlined,
    0xe032: Icons.sports_martial_arts_outlined,
    0xe21f: Icons.golf_course_outlined,
    0xe5cc: Icons.sports_cricket_outlined,
    0xe3a3: Icons.sports_volleyball_outlined,
    0xe3a4: Icons.sports_handball_outlined,
    0xe3a5: Icons.sports_rugby_outlined,
    0xe3a6: Icons.sports_hockey_outlined,
    0xe8dd: Icons.yard_outlined,
    0xe30d: Icons.dining_outlined,
    0xe56d: Icons.fastfood_outlined,
    0xe7e4: Icons.bakery_dining_outlined,
    0xe7e7: Icons.ramen_dining_outlined,
    0xe7f1: Icons.lunch_dining_outlined,
    0xe7eb: Icons.brunch_dining_outlined,
    0xe7f0: Icons.icecream_outlined,
    0xe7e8: Icons.cake_outlined,
    0xe7e3: Icons.emoji_food_beverage_outlined,
    0xe0e5: Icons.local_bar_outlined,
    0xe544: Icons.wine_bar_outlined,
    0xe30e: Icons.nightlife_outlined,
    0xe7f6: Icons.coffee_outlined,
    0xe7ea: Icons.liquor_outlined,
  };

  /// Get IconData from string representation
  /// Supports hex format (e.g., "0xe047") and named icons
  static IconData getIcon(String iconString) {
    try {
      // Try to parse as hex code
      if (iconString.startsWith('0x')) {
        final codePoint = int.parse(iconString);
        // Return from map if available, otherwise return default
        return _iconMap[codePoint] ?? Icons.check_circle_outline;
      }
    } catch (e) {
      // If parsing fails, return default
    }
    return Icons.check_circle_outline;
  }

  /// Get all available icons as a list for selection
  static List<IconData> get availableIcons => _iconMap.values.toList();

  /// Get the string representation of an icon
  static String getIconString(IconData icon) {
    // Find the codepoint in our map
    for (final entry in _iconMap.entries) {
      if (entry.value == icon) {
        return '0x${entry.key.toRadixString(16)}';
      }
    }
    // Default
    return '0xe047';
  }
}
