// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh

@ProviderFor(HabitsNotifier)
const habitsProvider = HabitsNotifierProvider._();

/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh
final class HabitsNotifierProvider
    extends $AsyncNotifierProvider<HabitsNotifier, List<Habit>> {
  /// Provider for managing the list of active habits
  /// Handles CRUD operations and event logging with automatic state refresh
  const HabitsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsNotifierHash();

  @$internal
  @override
  HabitsNotifier create() => HabitsNotifier();
}

String _$habitsNotifierHash() => r'50406c2b65068d88be72fca89830ae6537dabc6d';

/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh

abstract class _$HabitsNotifier extends $AsyncNotifier<List<Habit>> {
  FutureOr<List<Habit>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Habit>>, List<Habit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Habit>>, List<Habit>>,
              AsyncValue<List<Habit>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
