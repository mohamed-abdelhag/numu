class Category {
  final int? id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    this.icon,
    required this.color,
    this.isSystem = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String,
      isSystem: (map['is_system'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_system': isSystem ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isSystem,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
