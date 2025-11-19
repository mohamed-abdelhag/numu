enum LinkType {
  habit,
  task;

  String toMap() {
    return name;
  }

  static LinkType fromMap(String value) {
    return LinkType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LinkType.habit,
    );
  }
}

class ReminderLink {
  final LinkType type;
  final int entityId;
  final String entityName;
  final bool useDefaultText;

  const ReminderLink({
    required this.type,
    required this.entityId,
    required this.entityName,
    this.useDefaultText = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'link_type': type.toMap(),
      'link_entity_id': entityId,
      'link_entity_name': entityName,
      'use_default_text': useDefaultText ? 1 : 0,
    };
  }

  factory ReminderLink.fromMap(Map<String, dynamic> map) {
    return ReminderLink(
      type: LinkType.fromMap(map['link_type'] as String),
      entityId: map['link_entity_id'] as int,
      entityName: map['link_entity_name'] as String,
      useDefaultText: (map['use_default_text'] as int?) == 1,
    );
  }

  ReminderLink copyWith({
    LinkType? type,
    int? entityId,
    String? entityName,
    bool? useDefaultText,
  }) {
    return ReminderLink(
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      useDefaultText: useDefaultText ?? this.useDefaultText,
    );
  }
}
