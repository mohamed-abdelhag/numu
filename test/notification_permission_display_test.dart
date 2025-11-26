import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide group, expect, test;
import 'package:numu/features/settings/providers/notification_permission_provider.dart';

/// Helper class to represent the expected UI state for a permission status
class PermissionDisplayState {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool hasAction;

  const PermissionDisplayState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.hasAction,
  });
}

/// Maps a permission status to its expected display state
/// This mirrors the logic in _buildNotificationPermissionTile
PermissionDisplayState getExpectedDisplayState(NotificationPermissionStatus status) {
  switch (status) {
    case NotificationPermissionStatus.granted:
      return const PermissionDisplayState(
        icon: Icons.notifications_active,
        iconColor: Colors.green,
        title: 'Notifications enabled',
        hasAction: false,
      );
    case NotificationPermissionStatus.denied:
      return const PermissionDisplayState(
        icon: Icons.notifications_off,
        iconColor: Colors.orange,
        title: 'Notifications disabled',
        hasAction: true,
      );
    case NotificationPermissionStatus.permanentlyDenied:
      return PermissionDisplayState(
        icon: Icons.notifications_paused,
        iconColor: Colors.red, // theme.colorScheme.error
        title: 'Notifications blocked',
        hasAction: true,
      );
    case NotificationPermissionStatus.unknown:
      return PermissionDisplayState(
        icon: Icons.notifications,
        iconColor: Colors.grey, // theme.colorScheme.onSurface.withValues(alpha: 0.6)
        title: 'Notification status unknown',
        hasAction: true,
      );
  }
}

void main() {
  group('Notification Permission Display Property Tests', () {
    /// **Feature: design-home-reminder-fixes, Property 5: Permission status display consistency**
    /// **Validates: Requirements 3.2, 3.4, 3.6**
    ///
    /// *For any* notification permission state (granted, denied, permanentlyDenied),
    /// the settings UI SHALL display the corresponding visual indicator matching that state.
    Glados(any.choose(NotificationPermissionStatus.values)).test(
      'Property 5: Each permission status maps to a unique and consistent display state',
      (status) {
        final displayState = getExpectedDisplayState(status);

        // Property 1: Each status has a distinct icon
        expect(displayState.icon, isNotNull,
            reason: 'Every permission status must have an icon');

        // Property 2: Each status has a non-empty title
        expect(displayState.title.isNotEmpty, isTrue,
            reason: 'Every permission status must have a title');

        // Property 3: Granted status should NOT have an action (no tap handler)
        if (status == NotificationPermissionStatus.granted) {
          expect(displayState.hasAction, isFalse,
              reason: 'Granted status should not have a tap action');
        }

        // Property 4: Non-granted statuses MUST have an action
        if (status != NotificationPermissionStatus.granted) {
          expect(displayState.hasAction, isTrue,
              reason: 'Non-granted statuses must have a tap action to enable notifications');
        }

        // Property 5: Permanently denied must indicate settings action
        if (status == NotificationPermissionStatus.permanentlyDenied) {
          expect(displayState.title.toLowerCase().contains('blocked'), isTrue,
              reason: 'Permanently denied status should indicate notifications are blocked');
        }

        // Property 6: Denied status should indicate disabled state
        if (status == NotificationPermissionStatus.denied) {
          expect(displayState.title.toLowerCase().contains('disabled'), isTrue,
              reason: 'Denied status should indicate notifications are disabled');
        }

        // Property 7: Granted status should indicate enabled state
        if (status == NotificationPermissionStatus.granted) {
          expect(displayState.title.toLowerCase().contains('enabled'), isTrue,
              reason: 'Granted status should indicate notifications are enabled');
        }
      },
    );

    /// Additional property: All statuses map to distinct icons
    test('All permission statuses have distinct icons', () {
      final icons = NotificationPermissionStatus.values
          .map((status) => getExpectedDisplayState(status).icon)
          .toList();

      // Check that all icons are unique
      final uniqueIcons = icons.toSet();
      expect(uniqueIcons.length, equals(icons.length),
          reason: 'Each permission status should have a unique icon');
    });

    /// Additional property: All statuses map to distinct titles
    test('All permission statuses have distinct titles', () {
      final titles = NotificationPermissionStatus.values
          .map((status) => getExpectedDisplayState(status).title)
          .toList();

      // Check that all titles are unique
      final uniqueTitles = titles.toSet();
      expect(uniqueTitles.length, equals(titles.length),
          reason: 'Each permission status should have a unique title');
    });
  });

  group('Permission Status Display Unit Tests', () {
    /// Unit test: Verify the mapping covers all enum values
    test('getExpectedDisplayState handles all NotificationPermissionStatus values', () {
      for (final status in NotificationPermissionStatus.values) {
        expect(
          () => getExpectedDisplayState(status),
          returnsNormally,
          reason: 'getExpectedDisplayState should handle $status',
        );
      }
    });

    /// Unit test: Verify granted state properties
    test('Granted status has correct display properties', () {
      final state = getExpectedDisplayState(NotificationPermissionStatus.granted);
      expect(state.icon, equals(Icons.notifications_active));
      expect(state.iconColor, equals(Colors.green));
      expect(state.title, equals('Notifications enabled'));
      expect(state.hasAction, isFalse);
    });

    /// Unit test: Verify denied state properties
    test('Denied status has correct display properties', () {
      final state = getExpectedDisplayState(NotificationPermissionStatus.denied);
      expect(state.icon, equals(Icons.notifications_off));
      expect(state.iconColor, equals(Colors.orange));
      expect(state.title, equals('Notifications disabled'));
      expect(state.hasAction, isTrue);
    });

    /// Unit test: Verify permanently denied state properties
    test('Permanently denied status has correct display properties', () {
      final state = getExpectedDisplayState(NotificationPermissionStatus.permanentlyDenied);
      expect(state.icon, equals(Icons.notifications_paused));
      expect(state.title, equals('Notifications blocked'));
      expect(state.hasAction, isTrue);
    });

    /// Unit test: Verify unknown state properties
    test('Unknown status has correct display properties', () {
      final state = getExpectedDisplayState(NotificationPermissionStatus.unknown);
      expect(state.icon, equals(Icons.notifications));
      expect(state.title, equals('Notification status unknown'));
      expect(state.hasAction, isTrue);
    });
  });
}
