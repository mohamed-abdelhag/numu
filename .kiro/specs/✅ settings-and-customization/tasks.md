# Implementation Plan

- [x] 1. Set up foundation - Settings Repository and Data Models
  - Create `lib/core/services/settings_repository.dart` with SharedPreferences integration
  - Implement methods for theme mode storage (getThemeMode, saveThemeMode)
  - Implement methods for navigation preferences storage (getNavigationItemsVisibility, saveNavigationItemsVisibility, getNavigationOrder, saveNavigationOrder)
  - Add error handling with try-catch blocks and default value fallbacks
  - Add logging using CoreLoggingUtility for all operations
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 1.1 Create NavigationItem data model
  - Create `lib/core/models/navigation_item.dart` with all required fields (id, label, icon, route, isHome, isEnabled, order)
  - Implement toJson() and fromJson() methods for serialization
  - Add computed property `isLocked` that returns true for home and settings items
  - Add copyWith method for immutable updates
  - _Requirements: 2.1, 2.4, 3.3_

- [x] 2. Implement Theme System
  - Create `lib/core/providers/theme_provider.dart` using Riverpod code generation
  - Implement ThemeNotifier that extends AsyncNotifier<ThemeMode>
  - Load initial theme from SettingsRepository in build() method
  - Implement setThemeMode() method that updates state and persists to repository
  - Create settingsRepositoryProvider for dependency injection
  - _Requirements: 1.1, 1.3, 1.4_

- [x] 2.1 Define Light and Dark themes
  - Update `lib/app/app.dart` to include _buildLightTheme() and _buildDarkTheme() methods
 - use exsinth color theme file in app/theme there is 5 fiils in the folder aque green blue brown cool pink fancy green normal green all should be options in the settings screen as well as dark light options all saves to prefrences also 
  - _Requirements: 1.2_

- [x] 2.2 Integrate theme provider into MyApp
  - Update MyApp widget to watch themeNotifierProvider
  - Pass theme and darkTheme to MaterialApp.router
  - Set themeMode from provider state with fallback to ThemeMode.light
  - Handle AsyncValue loading and error states gracefully
  - _Requirements: 1.2, 1.4_

- [x] 3. Implement Navigation Customization System
  - Create `lib/core/providers/navigation_provider.dart` using Riverpod code generation
  - Define default navigation items list with all screens (Home, Tasks, Habits, Profile, Settings)
  - Implement NavigationNotifier that extends AsyncNotifier<List<NavigationItem>>
  - Load navigation preferences from repository and merge with defaults in build()
  - Implement toggleItemVisibility() method with validation to prevent disabling locked items
  - Implement reorderItems() method with validation to keep Home first
  - Implement saveChanges() method to persist to repository
  - Implement resetToDefaults() method
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Update NumuAppShell for dynamic navigation
  - Update `lib/core/widgets/shell/numu_app_shell.dart` to ConsumerWidget
  - Watch navigationNotifierProvider to get navigation items
  - Filter items to show only enabled items
  - Sort items by order property
  - Dynamically generate ListTile widgets for each enabled navigation item
  - Maintain existing drawer header and divider structure
  - _Requirements: 2.3, 2.6, 3.5_

- [x] 5. Build Settings Screen UI - Theme Section
  - Update `lib/features/settings/settings_screen.dart` to ConsumerWidget
  - Create scrollable Column layout with sections
  - Add "Appearance" section header
  - Implement theme toggle using SegmentedButton or RadioListTile for Light/Dark/System options
  - Watch themeNotifierProvider to display current selection
  - Call themeNotifier.setThemeMode() on selection change
  - Add visual feedback for theme changes
  - _Requirements: 1.1, 1.2, 5.3, 5.4_

- [x] 6. Build Settings Screen UI - Navigation Customization Section
  - Add "Navigation" section header in SettingsScreen
  - Create ReorderableListView for navigation items
  - Watch navigationNotifierProvider to get current items
  - Create NavigationItemTile widget with drag handle, checkbox, and label
  - Disable checkbox for locked items (Home, Settings) with visual indicator
  - Implement onReorder callback to call navigationNotifier.reorderItems()
  - Implement checkbox onChanged to call navigationNotifier.toggleItemVisibility()
  - Add "Save Navigation Changes" ElevatedButton
  - Implement save button onPressed to call navigationNotifier.saveChanges()
  - Show loading indicator during save operation
  - _Requirements: 2.1, 2.2, 2.4, 3.1, 3.2, 3.4, 5.3, 5.4, 5.5_

- [ ] 7. Implement error handling and user feedback
  - Add error state handling in SettingsScreen for AsyncValue errors
  - Display SnackBar with error message when save operations fail
  - Add retry mechanism for failed save operations
  - Display success SnackBar after successful save
  - Handle storage initialization errors in repository with graceful fallbacks
  - Add error logging for all exception scenarios
  - _Requirements: 4.4, 4.5_

- [ ] 8. Add validation and business logic
  - Implement validation in NavigationNotifier.saveChanges() to ensure Home is first
  - Validate that Home and Settings items are always enabled before saving
  - Validate that at least one navigation item is enabled
  - Validate order values are unique and sequential
  - Add data repair logic in SettingsRepository for corrupted stored data
  - _Requirements: 2.4, 3.3_

- [-] 9. Add SharedPreferences dependency and generate code
  - Add `shared_preferences` package to pubspec.yaml
  - Run `flutter pub get` to install dependencies
  - Run `dart run build_runner build --delete-conflicting-outputs` to generate Riverpod code
  - Verify generated files are created (.g.dart files)
  - _Requirements: 4.1, 4.2_

- [ ] 10. Integration and polish
  - Test theme switching across all screens
  - Test navigation customization with various configurations
  - Verify persistence by restarting app after changes
  - Test error scenarios (storage failures, corrupted data)
  - Ensure Settings navigation item is accessible from all screens
  - Add semantic labels for accessibility
  - Test with screen readers and keyboard navigation
  - Verify touch targets meet minimum size requirements (48x48 dp)
  - _Requirements: 1.4, 2.6, 3.5, 4.2, 5.1, 5.2, 5.5_
