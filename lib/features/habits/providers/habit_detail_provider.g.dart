// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing a single habit's detail view
/// Loads habit data, events, and streak information

@ProviderFor(HabitDetailNotifier)
const habitDetailProvider = HabitDetailNotifierFamily._();

/// Provider for managing a single habit's detail view
/// Loads habit data, events, and streak information
final class HabitDetailNotifierProvider
    extends $AsyncNotifierProvider<HabitDetailNotifier, HabitDetailState> {
  /// Provider for managing a single habit's detail view
  /// Loads habit data, events, and streak information
  const HabitDetailNotifierProvider._({
    required HabitDetailNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'habitDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitDetailNotifierHash();

  @override
  String toString() {
    return r'habitDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HabitDetailNotifier create() => HabitDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is HabitDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitDetailNotifierHash() =>
    r'90b22487035a3efdacf0754f0cb261596fb9dd83';

/// Provider for managing a single habit's detail view
/// Loads habit data, events, and streak information

final class HabitDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          HabitDetailNotifier,
          AsyncValue<HabitDetailState>,
          HabitDetailState,
          FutureOr<HabitDetailState>,
          int
        > {
  const HabitDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'habitDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for managing a single habit's detail view
  /// Loads habit data, events, and streak information

  HabitDetailNotifierProvider call(int habitId) =>
      HabitDetailNotifierProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitDetailProvider';
}

/// Provider for managing a single habit's detail view
/// Loads habit data, events, and streak information

abstract class _$HabitDetailNotifier extends $AsyncNotifier<HabitDetailState> {
  late final _$args = ref.$arg as int;
  int get habitId => _$args;

  FutureOr<HabitDetailState> build(int habitId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<HabitDetailState>, HabitDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HabitDetailState>, HabitDetailState>,
              AsyncValue<HabitDetailState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
