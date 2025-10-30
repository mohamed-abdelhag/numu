class Task {
  final int? id;
  final String text;
  final bool isCompleted;

  const Task({
    this.id,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      text: map['text'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }

  Task copyWith({
    int? id,
    String? text,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}