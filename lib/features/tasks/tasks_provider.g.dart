// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TasksNotifier)
const tasksProvider = TasksNotifierProvider._();

final class TasksNotifierProvider
    extends $AsyncNotifierProvider<TasksNotifier, List<Task>> {
  const TasksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasksNotifierHash();

  @$internal
  @override
  TasksNotifier create() => TasksNotifier();
}

String _$tasksNotifierHash() => r'b1be5889c0e3d59bf1a65484d87349514b5f7a87';

abstract class _$TasksNotifier extends $AsyncNotifier<List<Task>> {
  FutureOr<List<Task>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(taskDetail)
const taskDetailProvider = TaskDetailFamily._();

final class TaskDetailProvider
    extends $FunctionalProvider<AsyncValue<Task?>, Task?, FutureOr<Task?>>
    with $FutureModifier<Task?>, $FutureProvider<Task?> {
  const TaskDetailProvider._({
    required TaskDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'taskDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskDetailHash();

  @override
  String toString() {
    return r'taskDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Task?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Task?> create(Ref ref) {
    final argument = this.argument as int;
    return taskDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskDetailHash() => r'977d3ddeb77ba11acfc94f4098c713573b245038';

final class TaskDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Task?>, int> {
  const TaskDetailFamily._()
    : super(
        retry: null,
        name: r'taskDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaskDetailProvider call(int taskId) =>
      TaskDetailProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskDetailProvider';
}
