// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing a single category's detail view
/// Loads category data, associated habits, and associated tasks

@ProviderFor(CategoryDetailNotifier)
const categoryDetailProvider = CategoryDetailNotifierFamily._();

/// Provider for managing a single category's detail view
/// Loads category data, associated habits, and associated tasks
final class CategoryDetailNotifierProvider
    extends
        $AsyncNotifierProvider<CategoryDetailNotifier, CategoryDetailState> {
  /// Provider for managing a single category's detail view
  /// Loads category data, associated habits, and associated tasks
  const CategoryDetailNotifierProvider._({
    required CategoryDetailNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'categoryDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryDetailNotifierHash();

  @override
  String toString() {
    return r'categoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CategoryDetailNotifier create() => CategoryDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is CategoryDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryDetailNotifierHash() =>
    r'6d5cb0e8ca99255f75026bb9b32340a5ac03d1d9';

/// Provider for managing a single category's detail view
/// Loads category data, associated habits, and associated tasks

final class CategoryDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CategoryDetailNotifier,
          AsyncValue<CategoryDetailState>,
          CategoryDetailState,
          FutureOr<CategoryDetailState>,
          int
        > {
  const CategoryDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'categoryDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for managing a single category's detail view
  /// Loads category data, associated habits, and associated tasks

  CategoryDetailNotifierProvider call(int categoryId) =>
      CategoryDetailNotifierProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'categoryDetailProvider';
}

/// Provider for managing a single category's detail view
/// Loads category data, associated habits, and associated tasks

abstract class _$CategoryDetailNotifier
    extends $AsyncNotifier<CategoryDetailState> {
  late final _$args = ref.$arg as int;
  int get categoryId => _$args;

  FutureOr<CategoryDetailState> build(int categoryId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<CategoryDetailState>, CategoryDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CategoryDetailState>, CategoryDetailState>,
              AsyncValue<CategoryDetailState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
