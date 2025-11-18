import 'package:flutter/material.dart';

/// Represents a navigation item in the app's side panel
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final bool isHome;
  final bool isEnabled;
  final int order;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.isHome,
    required this.isEnabled,
    required this.order,
  });

  /// Returns true if this item cannot be disabled or reordered
  /// (Home and Settings items are locked)
  bool get isLocked => isHome || id == 'settings';

  /// Creates a copy of this NavigationItem with the given fields replaced
  NavigationItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    String? route,
    bool? isHome,
    bool? isEnabled,
    int? order,
  }) {
    return NavigationItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      isHome: isHome ?? this.isHome,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }

  /// Converts this NavigationItem to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon.codePoint,
      'route': route,
      'isHome': isHome,
      'isEnabled': isEnabled,
      'order': order,
    };
  }

  /// Creates a NavigationItem from a JSON map
  factory NavigationItem.fromJson(Map<String, dynamic> json) {
    return NavigationItem(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      route: json['route'] as String,
      isHome: json['isHome'] as bool,
      isEnabled: json['isEnabled'] as bool,
      order: json['order'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NavigationItem &&
        other.id == id &&
        other.label == label &&
        other.icon == icon &&
        other.route == route &&
        other.isHome == isHome &&
        other.isEnabled == isEnabled &&
        other.order == order;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      icon,
      route,
      isHome,
      isEnabled,
      order,
    );
  }

  @override
  String toString() {
    return 'NavigationItem(id: $id, label: $label, route: $route, isHome: $isHome, isEnabled: $isEnabled, order: $order)';
  }
}
