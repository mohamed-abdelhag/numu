import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/features/settings/widgets/profile_section.dart';
import 'package:numu/features/settings/models/user_profile.dart';
import 'package:numu/features/settings/providers/user_profile_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('ProfileSection Widget Tests', () {
    late UserProfile testProfile;

    setUp(() {
      testProfile = UserProfile(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        startOfWeek: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    Widget createTestWidget({
      required AsyncValue<UserProfile?> profileState,
      _TestUserProfileNotifier? notifier,
    }) {
      return ProviderScope(
        overrides: [
          if (notifier != null)
            userProfileProvider.overrideWith(() => notifier)
          else
            userProfileProvider.overrideWith(() {
              return _MockUserProfileNotifier(profileState);
            }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileSection(),
            ),
          ),
        ),
      );
    }

    testWidgets('displays loading state while profile is loading', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: const AsyncValue.loading(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading profile...'), findsOneWidget);
    });

    testWidgets('displays error state when profile fails to load', (tester) async {
      const errorMessage = 'Failed to load profile';
      
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.error(
            Exception(errorMessage),
            StackTrace.current,
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays profile in view mode with data', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays default text when profile has no data', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: const AsyncValue.data(null),
        ),
      );

      expect(find.text('No name set'), findsOneWidget);
      expect(find.text('No email set'), findsOneWidget);
    });

    testWidgets('enters edit mode when edit button is tapped', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      // Verify view mode
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Verify edit mode
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('populates form fields with existing profile data in edit mode', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Verify form fields are populated
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Clear name field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('validates email format when provided', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).last, 'invalid-email');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('allows empty email field', (tester) async {
      final notifier = _TestUserProfileNotifier(AsyncValue.data(testProfile));
      
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
          notifier: notifier,
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Clear email field
      await tester.enterText(find.byType(TextFormField).last, '');
      await tester.pumpAndSettle();

      // Save should work
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify no validation error for empty email
      expect(find.text('Please enter a valid email address'), findsNothing);
    });

    testWidgets('cancels edit mode and returns to view mode', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);

      // Cancel edit
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify back in view mode
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows success snackbar after successful save', (tester) async {
      final notifier = _TestUserProfileNotifier(AsyncValue.data(testProfile));
      
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
          notifier: notifier,
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Modify name
      await tester.enterText(find.byType(TextFormField).first, 'Updated Name');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.text('Profile saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays CircleAvatar with person icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('disables form fields while saving', (tester) async {
      final notifier = _TestUserProfileNotifier(
        AsyncValue.data(testProfile),
        saveDelay: const Duration(seconds: 2),
      );
      
      await tester.pumpWidget(
        createTestWidget(
          profileState: AsyncValue.data(testProfile),
          notifier: notifier,
        ),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Start save
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Verify saving state
      expect(find.text('Saving...'), findsOneWidget);
      
      // Verify form fields are disabled
      final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(nameField.enabled, isFalse);
    });
  });
}

/// Mock notifier that returns a fixed state
class _MockUserProfileNotifier extends UserProfileNotifier {
  final AsyncValue<UserProfile?> _initialState;

  _MockUserProfileNotifier(this._initialState) {
    // Set the state immediately
    state = _initialState;
  }

  @override
  Future<UserProfile?> build() async {
    // Return the data from the initial state
    if (_initialState.hasValue) {
      return _initialState.value;
    } else if (_initialState.hasError) {
      throw _initialState.error!;
    } else {
      // Loading state - just wait a bit
      await Future.delayed(const Duration(milliseconds: 100));
      return null;
    }
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    state = AsyncValue.data(profile);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    state = AsyncValue.data(profile);
  }
}

/// Test notifier with controllable behavior
class _TestUserProfileNotifier extends UserProfileNotifier {
  final AsyncValue<UserProfile?> _initialState;
  final Duration? saveDelay;

  _TestUserProfileNotifier(this._initialState, {this.saveDelay}) {
    // Set the state immediately
    state = _initialState;
  }

  @override
  Future<UserProfile?> build() async {
    // Return the data from the initial state
    if (_initialState.hasValue) {
      return _initialState.value;
    } else if (_initialState.hasError) {
      throw _initialState.error!;
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      return null;
    }
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    if (saveDelay != null) {
      await Future.delayed(saveDelay!);
    }
    state = AsyncValue.data(profile);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (saveDelay != null) {
      await Future.delayed(saveDelay!);
    }
    state = AsyncValue.data(profile);
  }
}
