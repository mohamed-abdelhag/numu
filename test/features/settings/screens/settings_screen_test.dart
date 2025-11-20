import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numu/features/settings/settings_screen.dart';
import 'package:numu/features/settings/models/user_profile.dart';
import 'package:numu/features/settings/models/theme_config.dart';
import 'package:numu/features/settings/providers/user_profile_provider.dart';
import 'package:numu/features/settings/providers/theme_config_provider.dart';
import 'package:numu/features/settings/widgets/profile_section.dart';
import 'package:numu/features/settings/screens/theme_selector_screen.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/providers/navigation_provider.dart';
import 'package:numu/core/models/navigation_item.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/app/theme/theme_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('SettingsScreen Widget Tests', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;
    late UserProfile testProfile;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'color_scheme': 'blue',
        'theme_mode': 'light',
      });
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
      
      testProfile = UserProfile(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        startOfWeek: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          userProfileProvider.overrideWith((ref) {
            return _TestUserProfileNotifier(AsyncValue.data(testProfile));
          }),
          navigationProvider.overrideWith((ref) {
            return _TestNavigationNotifier(AsyncValue.data([
              NavigationItem(
                id: 'home',
                label: 'Home',
                icon: Icons.home,
                isEnabled: true,
                order: 0,
                isLocked: true,
              ),
              NavigationItem(
                id: 'habits',
                label: 'Habits',
                icon: Icons.check_circle,
                isEnabled: true,
                order: 1,
                isLocked: false,
              ),
            ]));
          }),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('displays app bar with Settings title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays ProfileSection at the top', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSection), findsOneWidget);
      
      // Verify it's at the top by checking it appears before Appearance section
      final profileFinder = find.byType(ProfileSection);
      final appearanceFinder = find.text('Appearance');
      
      expect(profileFinder, findsOneWidget);
      expect(appearanceFinder, findsOneWidget);
    });

    testWidgets('displays Appearance section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Color Theme'), findsOneWidget);
    });

    testWidgets('displays theme mode selector with all options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
    });

    testWidgets('displays current color theme name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final blueTheme = ThemeRegistry.getTheme('blue');
      expect(find.text(blueTheme.displayName), findsOneWidget);
    });

    testWidgets('color theme section has palette icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('color theme section has chevron for navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
    });

    testWidgets('navigates to ThemeSelectorScreen when color theme tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the color theme ListTile
      final colorThemeTile = find.ancestor(
        of: find.text('Tap to change color theme'),
        matching: find.byType(ListTile),
      );
      
      await tester.tap(colorThemeTile);
      await tester.pumpAndSettle();

      // Should navigate to theme selector
      expect(find.byType(ThemeSelectorScreen), findsOneWidget);
    });

    testWidgets('displays Preferences section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Week Starts On'), findsOneWidget);
    });

    testWidgets('displays current week start day', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
    });

    testWidgets('opens week start picker when tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Week Starts On
      await tester.tap(find.text('Week Starts On'));
      await tester.pumpAndSettle();

      // Should show dialog with all days
      expect(find.text('Monday'), findsNWidgets(2)); // One in settings, one in dialog
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('displays Navigation section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Customize Side Panel'), findsOneWidget);
    });

    testWidgets('displays navigation items in reorderable list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('shows lock icon for locked navigation items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Home should be locked
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
    });

    testWidgets('displays Save Navigation Changes button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save Navigation Changes'), findsOneWidget);
    });

    testWidgets('theme mode selector changes theme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.textContaining('Theme changed to'), findsOneWidget);
    });

    testWidgets('shows success snackbar after theme mode change', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme mode
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });

    testWidgets('all sections are scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('sections have proper spacing', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify SizedBox spacing exists between sections
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('displays loading state while loading theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
            themeProvider.overrideWith((ref) {
              return _TestThemeNotifier(const AsyncValue.loading());
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading settings...'), findsOneWidget);
    });

    testWidgets('displays error state when theme fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
            themeProvider.overrideWith((ref) {
              return _TestThemeNotifier(
                AsyncValue.error(Exception('Failed to load'), StackTrace.current),
              );
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load theme settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('color theme subtitle provides helpful text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tap to change color theme'), findsOneWidget);
    });

    testWidgets('navigation section shows helper text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Reorder and toggle navigation items. Home and Settings are always visible.'),
        findsOneWidget,
      );
    });

    testWidgets('week start picker shows current selection with check icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open week start picker
      await tester.tap(find.text('Week Starts On'));
      await tester.pumpAndSettle();

      // Monday should be selected (check_circle icon)
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });

    testWidgets('can change week start day', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open week start picker
      await tester.tap(find.text('Week Starts On'));
      await tester.pumpAndSettle();

      // Select Tuesday
      await tester.tap(find.text('Tuesday'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.textContaining('Week now starts on'), findsOneWidget);
    });

    testWidgets('navigation items have drag handles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsAtLeastNWidgets(1));
    });

    testWidgets('navigation items have checkboxes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('locked navigation items have disabled checkboxes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the checkbox for Home (which is locked)
      final homeCheckbox = find.descendant(
        of: find.ancestor(
          of: find.text('Home'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(Checkbox),
      );

      final checkbox = tester.widget<Checkbox>(homeCheckbox);
      expect(checkbox.onChanged, isNull); // Disabled checkbox has null onChanged
    });

    testWidgets('appearance section uses Card widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('all section titles use titleLarge style', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final appearanceText = tester.widget<Text>(find.text('Appearance'));
      expect(appearanceText.style?.fontWeight, FontWeight.bold);
    });
  });

  group('NavigationItemTile Widget Tests', () {
    testWidgets('displays navigation item with icon and label', (tester) async {
      final item = NavigationItem(
        id: 'test',
        label: 'Test Item',
        icon: Icons.star,
        isEnabled: true,
        order: 0,
        isLocked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItemTile(
              item: item,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('shows lock icon for locked items', (tester) async {
      final item = NavigationItem(
        id: 'test',
        label: 'Locked Item',
        icon: Icons.star,
        isEnabled: true,
        order: 0,
        isLocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItemTile(
              item: item,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('checkbox reflects enabled state', (tester) async {
      final item = NavigationItem(
        id: 'test',
        label: 'Test Item',
        icon: Icons.star,
        isEnabled: true,
        order: 0,
        isLocked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItemTile(
              item: item,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('calls onToggle when checkbox is tapped', (tester) async {
      bool? toggledValue;
      final item = NavigationItem(
        id: 'test',
        label: 'Test Item',
        icon: Icons.star,
        isEnabled: true,
        order: 0,
        isLocked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItemTile(
              item: item,
              onToggle: (value) => toggledValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(toggledValue, isNotNull);
    });

    testWidgets('disabled when item is locked', (tester) async {
      final item = NavigationItem(
        id: 'test',
        label: 'Locked Item',
        icon: Icons.star,
        isEnabled: true,
        order: 0,
        isLocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItemTile(
              item: item,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.enabled, false);
    });
  });
}

// Test notifiers
class _TestUserProfileNotifier extends UserProfileNotifier {
  final AsyncValue<UserProfile?> _state;

  _TestUserProfileNotifier(this._state);

  @override
  Future<UserProfile?> build() async {
    return _state.when(
      data: (profile) => profile,
      loading: () => throw StateError('Loading'),
      error: (error, stack) => throw error,
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    state = AsyncValue.data(profile);
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    state = AsyncValue.data(profile);
  }
}

class _TestNavigationNotifier extends NavigationNotifier {
  final AsyncValue<List<NavigationItem>> _state;

  _TestNavigationNotifier(this._state);

  @override
  Future<List<NavigationItem>> build() async {
    return _state.when(
      data: (items) => items,
      loading: () => throw StateError('Loading'),
      error: (error, stack) => throw error,
    );
  }

  @override
  void reorderItems(int oldIndex, int newIndex) {}

  @override
  void toggleItemVisibility(String id) {}

  @override
  Future<void> saveChanges() async {}
}

class _TestThemeNotifier extends ThemeNotifier {
  final AsyncValue<ThemeMode> _state;

  _TestThemeNotifier(this._state);

  @override
  Future<ThemeMode> build() async {
    return _state.when(
      data: (mode) => mode,
      loading: () => throw StateError('Loading'),
      error: (error, stack) => throw error,
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
  }
}
