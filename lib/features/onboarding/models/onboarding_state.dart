class OnboardingState {
  final bool isCompleted;
  final DateTime? completedAt;

  const OnboardingState({
    required this.isCompleted,
    this.completedAt,
  });

  OnboardingState copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
