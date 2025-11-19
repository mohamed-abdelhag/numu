// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing the list of reminders
/// Handles CRUD operations and scheduling with automatic state refresh

@ProviderFor(ReminderNotifier)
const reminderProvider = ReminderNotifierProvider._();

/// Provider for managing the list of reminders
/// Handles CRUD operations and scheduling with automatic state refresh
final class ReminderNotifierProvider
    extends $AsyncNotifierProvider<ReminderNotifier, List<Reminder>> {
  /// Provider for managing the list of reminders
  /// Handles CRUD operations and scheduling with automatic state refresh
  const ReminderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderNotifierHash();

  @$internal
  @override
  ReminderNotifier create() => ReminderNotifier();
}

String _$reminderNotifierHash() => r'68683e4f80febe002798a92a878a72e5f28a9fe4';

/// Provider for managing the list of reminders
/// Handles CRUD operations and scheduling with automatic state refresh

abstract class _$ReminderNotifier extends $AsyncNotifier<List<Reminder>> {
  FutureOr<List<Reminder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Reminder>>, List<Reminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Reminder>>, List<Reminder>>,
              AsyncValue<List<Reminder>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for filtering only active reminders

@ProviderFor(activeReminders)
const activeRemindersProvider = ActiveRemindersProvider._();

/// Provider for filtering only active reminders

final class ActiveRemindersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          FutureOr<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $FutureProvider<List<Reminder>> {
  /// Provider for filtering only active reminders
  const ActiveRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRemindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRemindersHash();

  @$internal
  @override
  $FutureProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Reminder>> create(Ref ref) {
    return activeReminders(ref);
  }
}

String _$activeRemindersHash() => r'890b1366fa304aa3b9d10738b03ebfb9021f5758';

/// Provider for fetching reminders linked to a specific habit

@ProviderFor(habitReminders)
const habitRemindersProvider = HabitRemindersFamily._();

/// Provider for fetching reminders linked to a specific habit

final class HabitRemindersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          FutureOr<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $FutureProvider<List<Reminder>> {
  /// Provider for fetching reminders linked to a specific habit
  const HabitRemindersProvider._({
    required HabitRemindersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'habitRemindersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitRemindersHash();

  @override
  String toString() {
    return r'habitRemindersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Reminder>> create(Ref ref) {
    final argument = this.argument as int;
    return habitReminders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitRemindersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitRemindersHash() => r'8f9a26edf00d26b672a601f9dbd783aeff965cee';

/// Provider for fetching reminders linked to a specific habit

final class HabitRemindersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Reminder>>, int> {
  const HabitRemindersFamily._()
    : super(
        retry: null,
        name: r'habitRemindersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for fetching reminders linked to a specific habit

  HabitRemindersProvider call(int habitId) =>
      HabitRemindersProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitRemindersProvider';
}

/// Provider for fetching reminders linked to a specific task

@ProviderFor(taskReminders)
const taskRemindersProvider = TaskRemindersFamily._();

/// Provider for fetching reminders linked to a specific task

final class TaskRemindersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          FutureOr<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $FutureProvider<List<Reminder>> {
  /// Provider for fetching reminders linked to a specific task
  const TaskRemindersProvider._({
    required TaskRemindersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'taskRemindersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskRemindersHash();

  @override
  String toString() {
    return r'taskRemindersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Reminder>> create(Ref ref) {
    final argument = this.argument as int;
    return taskReminders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskRemindersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskRemindersHash() => r'8523bef22fbd9bb0022806667c07ae4bdf629364';

/// Provider for fetching reminders linked to a specific task

final class TaskRemindersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Reminder>>, int> {
  const TaskRemindersFamily._()
    : super(
        retry: null,
        name: r'taskRemindersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for fetching reminders linked to a specific task

  TaskRemindersProvider call(int taskId) =>
      TaskRemindersProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskRemindersProvider';
}
