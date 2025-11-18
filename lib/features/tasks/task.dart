class Task {
  final int? id;
  final String text;
  final bool isCompleted;
  final int? categoryId;

  const Task({
    this.id,
    required this.text,
    this.isCompleted = false,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted ? 1 : 0,
      'category_id': categoryId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      text: map['text'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      categoryId: map['category_id'] as int?,
    );
  }

  Task copyWith({
    int? id,
    String? text,
    bool? isCompleted,
    int? categoryId,
  }) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}