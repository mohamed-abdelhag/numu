class UserProfile {
  final int? id;
  final String name;
  final String? email;
  final String? profilePicturePath;
  final int startOfWeek; // 1 = Monday, 7 = Sunday
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    required this.name,
    this.email,
    this.profilePicturePath,
    this.startOfWeek = 1, // Default to Monday
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      profilePicturePath: map['profile_picture_path'] as String?,
      startOfWeek: map['start_of_week'] as int? ?? 1, // Default to Monday
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'profile_picture_path': profilePicturePath,
      'start_of_week': startOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePicturePath,
    int? startOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Validate startOfWeek if provided
    if (startOfWeek != null && (startOfWeek < 1 || startOfWeek > 7)) {
      throw ArgumentError('startOfWeek must be between 1 and 7');
    }
    
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      startOfWeek: startOfWeek ?? this.startOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
