# Implementation Plan

- [x] 1. Move profile code to settings feature
  - Move `lib/features/settings/models/user_profile.dart` to `lib/features/settings/models/user_profile.dart`
  - Move `lib/features/settings/providers/user_profile_provider.dart` and `.g.dart` to `lib/features/settings/providers/`
  - Move `lib/features/settings/repositories/user_profile_repository.dart` to `lib/features/settings/repositories/`
  - Update all import statements across the codebase to reference new paths
  - Delete the `lib/features/settings/` directory
  - _Requirements: 1.1, 1.6_

- [x] 2. Create theme configuration infrastructure
  - [x] 2.1 Create ThemeConfigModel in `lib/features/settings/models/theme_config.dart`
    - Implement model with colorSchemeId and themeMode fields
    - Add toJson/fromJson serialization methods
    - Add copyWith method for immutable updates
    - _Requirements: 2.4, 7.1_
  
  - [x] 2.2 Create ThemeRegistry in `lib/app/theme/theme_registry.dart`
    - Define ThemeInfo class with id, displayName, themeBuilder, and previewColor
    - Register all 6 existing themes (blue, green, fancy_green, aqua_green, brown, cool_pink)
    - Implement getTheme, getAllThemes, and isValidThemeId methods
    - _Requirements: 2.1, 2.2_
  
  - [x] 2.3 Update SettingsRepository with color scheme persistence
    - Add getColorScheme method with default fallback to 'blue'
    - Add saveColorScheme method with validation
    - Add error handling and logging
    - _Requirements: 2.4, 7.1, 7.2_
  
  - [x] 2.4 Create ThemeConfigProvider in `lib/features/settings/providers/theme_config_provider.dart`
    - Implement Riverpod provider to load theme configuration from repository
    - Add setColorScheme method to update color scheme
    - Add saveConfig method to persist complete configuration
    - Integrate with existing ThemeProvider
    - _Requirements: 2.3, 6.1, 6.2, 7.1_

- [x] 3. Update theme provider and app integration
  - [x] 3.1 Modify ThemeProvider to use ThemeConfigProvider
    - Update build method to read from ThemeConfigProvider
    - Use ThemeRegistry to get appropriate theme builder
    - Maintain backward compatibility with existing theme mode functionality
    - _Requirements: 2.2, 2.3, 6.1, 6.2_
  
  - [x] 3.2 Update MyApp to use dynamic theme from registry
    - Modify _buildLightTheme to use theme from ThemeConfigProvider
    - Modify _buildDarkTheme to use theme from ThemeConfigProvider
    - Ensure smooth theme transitions without flickering
    - _Requirements: 2.3, 6.3, 6.4, 6.5_

- [x] 4. Create profile section widget
  - [x] 4.1 Implement ProfileSection widget in `lib/features/settings/widgets/profile_section.dart`
    - Create stateful widget with view and edit modes
    - Implement profile display with name, email, and avatar placeholder
    - Add edit button to toggle edit mode
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 4.2 Implement profile editing functionality
    - Add form with TextEditingControllers for name and email
    - Implement form validation (required name, optional valid email)
    - Add save and cancel buttons
    - Implement save operation with error handling
    - Show loading states and success/error feedback
    - _Requirements: 1.3, 1.4, 9.3_

- [x] 5. Create theme preview card widget
  - Implement ThemePreviewCard in `lib/features/settings/widgets/theme_preview_card.dart`
  - Display color swatches for primary, secondary, and tertiary colors
  - Show theme display name
  - Add selection indicator (border and check icon)
  - Handle tap interaction to select theme
  - Ensure accessibility with semantic labels
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6. Implement theme selector screen
  - [x] 6.1 Create ThemeSelectorScreen in `lib/features/settings/screens/theme_selector_screen.dart`
    - Set up scaffold with app bar, save button, and back button
    - Implement WillPopScope for unsaved changes handling
    - Store original theme ID for revert capability
    - Track preview theme ID and unsaved changes state
    - _Requirements: 3.2, 3.4, 4.4, 10.2_
  
  - [x] 6.2 Build theme grid layout
    - Create GridView with 2 columns for theme previews
    - Use ThemePreviewCard for each theme
    - Implement theme preview on tap (instant visual feedback)
    - Highlight currently selected theme
    - _Requirements: 4.2, 4.3, 5.5_
  
  - [x] 6.3 Implement save and navigation logic
    - Add save button handler to persist selected theme
    - Implement back button handler with unsaved changes check
    - Create UnsavedChangesDialog widget for confirmation
    - Navigate back to settings after successful save
    - Revert to original theme if user cancels
    - _Requirements: 4.4, 4.5, 10.3, 10.4, 10.5_

- [x] 7. Update settings screen
  - [x] 7.1 Integrate ProfileSection at the top
    - Add ProfileSection as first section in settings screen
    - Remove any references to standalone profile screen
    - Ensure proper spacing and layout
    - _Requirements: 1.1, 8.1_
  
  - [x] 7.2 Update appearance section with color theme selection
    - Keep existing theme mode selector (Light/Dark/System)
    - Add "Color Theme" subsection below theme mode
    - Display current color theme name from ThemeConfigProvider
    - Add ListTile with navigation to ThemeSelectorScreen
    - Show theme icon and chevron for navigation affordance
    - _Requirements: 3.1, 3.3, 8.2, 8.3, 10.1_
  
  - [x] 7.3 Update navigation configuration
    - Remove profile navigation item from side panel
    - Update navigation provider to exclude profile
    - Ensure settings remains accessible
    - _Requirements: 1.5_

- [x] 8. Add error handling and loading states
  - Add error handling for theme loading failures with retry buttons
  - Add error handling for theme saving failures with snackbar feedback
  - Add loading indicators for async operations
  - Implement graceful fallbacks for missing or corrupted data
  - Add comprehensive logging for debugging
  - _Requirements: 7.3, 7.4, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 9. Implement theme persistence and initialization
  - Ensure color scheme persists to SharedPreferences on save
  - Load saved color scheme on app initialization
  - Apply default theme (blue, light mode) if no saved preferences exist
  - Handle storage errors gracefully without crashing
  - Verify theme persists across app restarts
  - _Requirements: 2.4, 2.5, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 10. Write unit tests for theme system
  - Write tests for ThemeRegistry (getTheme, getAllThemes, isValidThemeId)
  - Write tests for ThemeConfigModel (serialization, copyWith, theme mode parsing)
  - Write tests for SettingsRepository color scheme methods
  - Write tests for ThemeConfigProvider state management
  - _Requirements: All_

- [x] 11. Write widget tests
  - Write tests for ProfileSection (view mode, edit mode, validation, save)
  - Write tests for ThemePreviewCard (selection state, tap interaction, color display)
  - Write tests for ThemeSelectorScreen (grid rendering, preview, save, unsaved changes)
  - Write tests for updated SettingsScreen sections
  - _Requirements: All_

- [x] 12. Perform integration testing
  - Test complete theme selection flow (navigate, preview, save, verify persistence)
  - Test profile editing flow from settings
  - Test theme mode + color theme independence
  - Test app restart with saved preferences
  - Test error scenarios and recovery
  - _Requirements: All_
