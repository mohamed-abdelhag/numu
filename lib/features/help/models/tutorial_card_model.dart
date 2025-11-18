class TutorialCardModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String iconName;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TutorialCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.iconName,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TutorialCardModel.fromMap(Map<String, dynamic> map) {
    return TutorialCardModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      content: map['content'] as String,
      iconName: map['icon_name'] as String,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TutorialCardModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? iconName,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TutorialCardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
