// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing today's prayer schedule and next prayer identification.
///
/// **Validates: Requirements 6.2, 6.3**

@ProviderFor(PrayerScheduleNotifier)
const prayerScheduleProvider = PrayerScheduleNotifierProvider._();

/// Provider for managing today's prayer schedule and next prayer identification.
///
/// **Validates: Requirements 6.2, 6.3**
final class PrayerScheduleNotifierProvider
    extends
        $AsyncNotifierProvider<PrayerScheduleNotifier, PrayerScheduleState> {
  /// Provider for managing today's prayer schedule and next prayer identification.
  ///
  /// **Validates: Requirements 6.2, 6.3**
  const PrayerScheduleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerScheduleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerScheduleNotifierHash();

  @$internal
  @override
  PrayerScheduleNotifier create() => PrayerScheduleNotifier();
}

String _$prayerScheduleNotifierHash() =>
    r'f479c683fc02434ed799701b7de727227f908ec4';

/// Provider for managing today's prayer schedule and next prayer identification.
///
/// **Validates: Requirements 6.2, 6.3**

abstract class _$PrayerScheduleNotifier
    extends $AsyncNotifier<PrayerScheduleState> {
  FutureOr<PrayerScheduleState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PrayerScheduleState>, PrayerScheduleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrayerScheduleState>, PrayerScheduleState>,
              AsyncValue<PrayerScheduleState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for getting just the next prayer type

@ProviderFor(nextPrayer)
const nextPrayerProvider = NextPrayerProvider._();

/// Provider for getting just the next prayer type

final class NextPrayerProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerType?>,
          PrayerType?,
          FutureOr<PrayerType?>
        >
    with $FutureModifier<PrayerType?>, $FutureProvider<PrayerType?> {
  /// Provider for getting just the next prayer type
  const NextPrayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextPrayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextPrayerHash();

  @$internal
  @override
  $FutureProviderElement<PrayerType?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrayerType?> create(Ref ref) {
    return nextPrayer(ref);
  }
}

String _$nextPrayerHash() => r'db4d87deb9c3adea6cdfbce1316ffee6fbec3426';

/// Provider for getting the prayer schedule for today

@ProviderFor(todayPrayerSchedule)
const todayPrayerScheduleProvider = TodayPrayerScheduleProvider._();

/// Provider for getting the prayer schedule for today

final class TodayPrayerScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerSchedule?>,
          PrayerSchedule?,
          FutureOr<PrayerSchedule?>
        >
    with $FutureModifier<PrayerSchedule?>, $FutureProvider<PrayerSchedule?> {
  /// Provider for getting the prayer schedule for today
  const TodayPrayerScheduleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayPrayerScheduleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayPrayerScheduleHash();

  @$internal
  @override
  $FutureProviderElement<PrayerSchedule?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrayerSchedule?> create(Ref ref) {
    return todayPrayerSchedule(ref);
  }
}

String _$todayPrayerScheduleHash() =>
    r'c3ad9bdb04a297d7e99d317739f6100337f15de6';
