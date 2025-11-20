// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing navigation items state

@ProviderFor(NavigationNotifier)
const navigationProvider = NavigationNotifierProvider._();

/// Notifier for managing navigation items state
final class NavigationNotifierProvider
    extends $AsyncNotifierProvider<NavigationNotifier, List<NavigationItem>> {
  /// Notifier for managing navigation items state
  const NavigationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationNotifierHash();

  @$internal
  @override
  NavigationNotifier create() => NavigationNotifier();
}

String _$navigationNotifierHash() =>
    r'31cd78c13031ffa4a57c8714705dadaddc02dc5d';

/// Notifier for managing navigation items state

abstract class _$NavigationNotifier
    extends $AsyncNotifier<List<NavigationItem>> {
  FutureOr<List<NavigationItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<NavigationItem>>, List<NavigationItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<NavigationItem>>,
                List<NavigationItem>
              >,
              AsyncValue<List<NavigationItem>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
