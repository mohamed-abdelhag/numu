import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numu/features/settings/screens/theme_selector_screen.dart';
import 'package:numu/features/settings/models/theme_config.dart';
import 'package:numu/features/settings/providers/theme_config_provider.dart';
import 'package:numu/app/theme/theme_registry.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('ThemeSelectorScreen Widget Tests', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'color_scheme': 'blue',
        'theme_mode': 'light',
      });
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: ThemeSelectorScreen(),
        ),
      );
    }

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays grid of theme preview cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final allThemes = ThemeRegistry.getAllThemes();
      expect(find.byType(GridView), findsOneWidget);
      
      // Should display all available themes
      for (final theme in allThemes) {
        expect(find.text(theme.displayName), findsOneWidget);
      }
    });

    testWidgets('grid has 2 columns', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisCount, 2);
      expect(delegate.childAspectRatio, 0.8);
    });

    testWidgets('initially selects current theme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Blue theme should be selected initially
      final blueTheme = ThemeRegistry.getTheme('blue');
      expect(find.text(blueTheme.displayName), findsOneWidget);
      
      // Check icon should be visible for selected theme
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows Save button when theme is changed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no Save button visible
      expect(find.text('Save'), findsNothing);

      // Tap a different theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Save button should now be visible
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('previews theme instantly when tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap green theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Green theme should now show as selected
      final checkIcons = find.byIcon(Icons.check_circle);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('does not show Save button when same theme is selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the already selected theme (blue)
      final blueTheme = ThemeRegistry.getTheme('blue');
      await tester.tap(find.text(blueTheme.displayName));
      await tester.pumpAndSettle();

      // Save button should not appear
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('saves theme and navigates back on Save button tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Theme saved successfully'), findsOneWidget);
    });

    testWidgets('shows unsaved changes dialog when back button pressed with changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Try to go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should show unsaved changes dialog
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('You have unsaved theme changes. Do you want to discard them and go back?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('does not show dialog when back button pressed without changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to go back without making changes
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should not show dialog
      expect(find.text('Unsaved Changes'), findsNothing);
    });

    testWidgets('reverts theme when discarding changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Try to go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap Discard in dialog
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Theme should be reverted (verified by checking SharedPreferences)
      final savedTheme = prefs.getString('color_scheme');
      expect(savedTheme, 'blue'); // Should remain blue
    });

    testWidgets('stays on screen when canceling unsaved changes dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Try to go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should still be on theme selector screen
      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('displays loading indicator while loading config', (tester) async {
      // Create widget without waiting for initial load
      await tester.pumpWidget(createTestWidget());
      
      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
      
      // After loading, should show grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('disables Save button while saving', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      final greenTheme = ThemeRegistry.getTheme('green');
      await tester.tap(find.text(greenTheme.displayName));
      await tester.pumpAndSettle();

      // Start save
      await tester.tap(find.text('Save'));
      await tester.pump(); // Don't settle, check intermediate state

      // Save button should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('all themes are tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final allThemes = ThemeRegistry.getAllThemes();
      
      for (final theme in allThemes) {
        await tester.tap(find.text(theme.displayName));
        await tester.pumpAndSettle();
        
        // Should show as selected
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      }
    });

    testWidgets('maintains scroll position when previewing themes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(find.byType(GridView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Tap a theme
      final brownTheme = ThemeRegistry.getTheme('brown');
      await tester.tap(find.text(brownTheme.displayName));
      await tester.pumpAndSettle();

      // Grid should still be visible (not scrolled back to top)
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('handles rapid theme changes correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Rapidly tap different themes
      await tester.tap(find.text('Green'));
      await tester.pump();
      await tester.tap(find.text('Brown'));
      await tester.pump();
      await tester.tap(find.text('Cool Pink'));
      await tester.pumpAndSettle();

      // Last tapped theme should be selected
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('back button in app bar works correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap back button
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should not show unsaved changes dialog (no changes made)
      expect(find.text('Unsaved Changes'), findsNothing);
    });

    testWidgets('displays proper spacing between grid items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisSpacing, 16);
      expect(delegate.mainAxisSpacing, 16);
    });

    testWidgets('grid has proper padding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.padding, const EdgeInsets.all(16));
    });
  });

  group('UnsavedChangesDialog Tests', () {
    testWidgets('displays dialog content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnsavedChangesDialog(),
          ),
        ),
      );

      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('You have unsaved theme changes. Do you want to discard them and go back?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('Cancel button returns false', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const UnsavedChangesDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('Discard button returns true', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const UnsavedChangesDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
