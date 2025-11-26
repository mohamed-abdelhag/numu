// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_score_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for fetching and managing habit scores
/// Exposes score as AsyncValue with loading and error states
///
/// **Validates: Requirements 4.3**

@ProviderFor(HabitScoreNotifier)
const habitScoreProvider = HabitScoreNotifierFamily._();

/// Provider for fetching and managing habit scores
/// Exposes score as AsyncValue with loading and error states
///
/// **Validates: Requirements 4.3**
final class HabitScoreNotifierProvider
    extends $AsyncNotifierProvider<HabitScoreNotifier, HabitScore?> {
  /// Provider for fetching and managing habit scores
  /// Exposes score as AsyncValue with loading and error states
  ///
  /// **Validates: Requirements 4.3**
  const HabitScoreNotifierProvider._({
    required HabitScoreNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'habitScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitScoreNotifierHash();

  @override
  String toString() {
    return r'habitScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HabitScoreNotifier create() => HabitScoreNotifier();

  @override
  bool operator ==(Object other) {
    return other is HabitScoreNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitScoreNotifierHash() =>
    r'1e0ed281a0636e104b251b89d23eca48654fc0fe';

/// Provider for fetching and managing habit scores
/// Exposes score as AsyncValue with loading and error states
///
/// **Validates: Requirements 4.3**

final class HabitScoreNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          HabitScoreNotifier,
          AsyncValue<HabitScore?>,
          HabitScore?,
          FutureOr<HabitScore?>,
          int
        > {
  const HabitScoreNotifierFamily._()
    : super(
        retry: null,
        name: r'habitScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for fetching and managing habit scores
  /// Exposes score as AsyncValue with loading and error states
  ///
  /// **Validates: Requirements 4.3**

  HabitScoreNotifierProvider call(int habitId) =>
      HabitScoreNotifierProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitScoreProvider';
}

/// Provider for fetching and managing habit scores
/// Exposes score as AsyncValue with loading and error states
///
/// **Validates: Requirements 4.3**

abstract class _$HabitScoreNotifier extends $AsyncNotifier<HabitScore?> {
  late final _$args = ref.$arg as int;
  int get habitId => _$args;

  FutureOr<HabitScore?> build(int habitId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<HabitScore?>, HabitScore?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HabitScore?>, HabitScore?>,
              AsyncValue<HabitScore?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
