// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing notification permission status

@ProviderFor(NotificationPermission)
const notificationPermissionProvider = NotificationPermissionProvider._();

/// Provider for managing notification permission status
final class NotificationPermissionProvider
    extends
        $AsyncNotifierProvider<
          NotificationPermission,
          NotificationPermissionStatus
        > {
  /// Provider for managing notification permission status
  const NotificationPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionHash();

  @$internal
  @override
  NotificationPermission create() => NotificationPermission();
}

String _$notificationPermissionHash() =>
    r'ed58ee14abb5ed555ab847dd2de65736f4437a3b';

/// Provider for managing notification permission status

abstract class _$NotificationPermission
    extends $AsyncNotifier<NotificationPermissionStatus> {
  FutureOr<NotificationPermissionStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<NotificationPermissionStatus>,
              NotificationPermissionStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NotificationPermissionStatus>,
                NotificationPermissionStatus
              >,
              AsyncValue<NotificationPermissionStatus>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
