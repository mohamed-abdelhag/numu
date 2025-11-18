# Settings and Customization - Design Document

## Overview

This feature introduces comprehensive settings and customization capabilities to the Numu app, enabling users to personalize their experience through theme selection (Dark/Light mode) and side panel navigation customization. The design follows Flutter best practices using Riverpod for state management and SharedPreferences for persistent storage.

The implementation will transform the current static app shell into a dynamic, user-configurable interface while maintaining the existing architecture patterns used throughout the Numu app.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         MyApp                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         ThemeProvider (Riverpod)                      │  │
│  │  - Manages theme mode (Dark/Light)                    │  │
│  │  - Loads/saves theme preference                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         MaterialApp.router                            │  │
│  │  - theme: lightTheme                                  │  │
│  │  - darkTheme: darkTheme                               │  │
│  │  - themeMode: from ThemeProvider                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    NumuAppShell                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │    NavigationProvider (Riverpod)                      │  │
│  │  - Manages navigation items visibility & order        │  │
│  │  - Loads/saves navigation preferences                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Drawer (Side Panel)                           │  │
│  │  - Dynamically renders enabled navigation items       │  │
│  │  - Displays items in user-defined order               │  │
│  │  - Home always visible and first                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   SettingsScreen                             │
│  - Theme toggle section                                      │
│  - Navigation customization section                          │
│  - Save button for navigation changes                        │
│  - Error handling UI                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              SettingsRepository                              │
│  - SharedPreferences wrapper                                 │
│  - Key-value storage for preferences                         │
│  - Error handling for storage operations                     │
└─────────────────────────────────────────────────────────────┘
```

### Design Rationale

**Why SharedPreferences over SQLite?**
- Settings data is simple key-value pairs, not relational
- SharedPreferences provides faster read/write for small data
- No need for complex queries or relationships
- Consistent with Flutter best practices for app preferences
- The existing DatabaseService is optimized for structured data (habits, tasks)

**Why Riverpod for State Management?**
- Already used throughout the app (habits, tasks providers)
- Provides reactive updates when settings change
- Easy to test and maintain
- Supports async initialization for loading preferences

**Why Separate Providers for Theme and Navigation?**
- Single Responsibility Principle
- Theme changes are immediate, navigation changes require save action
- Different update frequencies and lifecycles

## Components and Interfaces

### 1. Settings Repository

**Purpose:** Abstracts persistent storage operations for settings data.

```dart
class SettingsRepository {
  final SharedPreferences _prefs;
  
  // Keys
  static const String _themeKey = 'theme_mode';
  static const String _navItemsKey = 'navigation_items';
  static const String _navOrderKey = 'navigation_order';
  
  // Theme operations
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  
  // Navigation operations
  Future<Map<String, bool>> getNavigationItemsVisibility();
  Future<void> saveNavigationItemsVisibility(Map<String, bool> items);
  Future<List<String>> getNavigationOrder();
  Future<void> saveNavigationOrder(List<String> order);
  
  // Error handling
  // Returns default values if storage fails
  // Logs errors for debugging
}
```

**Design Decision:** Repository pattern isolates storage logic, making it easy to swap SharedPreferences for another solution if needed.

### 2. Theme Provider

**Purpose:** Manages theme state and persistence.

```dart
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  late final SettingsRepository _repository;
  
  @override
  Future<ThemeMode> build() async {
    _repository = ref.read(settingsRepositoryProvider);
    return await _repository.getThemeMode();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await _repository.saveThemeMode(mode);
  }
}
```

**Design Decision:** Theme changes are immediate (no save button) because users expect instant visual feedback when toggling themes.

### 3. Navigation Provider

**Purpose:** Manages navigation items configuration.

```dart
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final bool isHome;
  final bool isEnabled;
  final int order;
}

@riverpod
class NavigationNotifier extends _$NavigationNotifier {
  late final SettingsRepository _repository;
  
  // Default navigation items
  static final List<NavigationItem> _defaultItems = [
    NavigationItem(id: 'home', label: 'Home', icon: Icons.home, 
                   route: '/home', isHome: true, isEnabled: true, order: 0),
    NavigationItem(id: 'tasks', label: 'Tasks', icon: Icons.task, 
                   route: '/tasks', isHome: false, isEnabled: true, order: 1),
    NavigationItem(id: 'habits', label: 'Habits', icon: Icons.track_changes, 
                   route: '/habits', isHome: false, isEnabled: true, order: 2),
    NavigationItem(id: 'profile', label: 'Profile', icon: Icons.person, 
                   route: '/profile', isHome: false, isEnabled: true, order: 3),
    NavigationItem(id: 'settings', label: 'Settings', icon: Icons.settings, 
                   route: '/settings', isHome: false, isEnabled: true, order: 4),
  ];
  
  @override
  Future<List<NavigationItem>> build() async {
    _repository = ref.read(settingsRepositoryProvider);
    return await _loadNavigationItems();
  }
  
  Future<List<NavigationItem>> _loadNavigationItems();
  void toggleItemVisibility(String itemId);
  void reorderItems(int oldIndex, int newIndex);
  Future<void> saveChanges();
  void resetToDefaults();
}
```

**Design Decision:** 
- Navigation changes require explicit save action to prevent accidental modifications
- Home item is always enabled and first (enforced in business logic)
- Settings item is always visible to prevent users from locking themselves out

### 4. Settings Screen

**Purpose:** User interface for configuring app preferences.

**Layout Structure:**
```
┌─────────────────────────────────────────────────────┐
│  NumuAppBar: "Settings"                             │
├─────────────────────────────────────────────────────┤
│  ScrollView                                         │
│  ┌───────────────────────────────────────────────┐ │
│  │ Appearance Section                            │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │ Theme Mode                              │ │ │
│  │  │  ○ Light  ● Dark                        │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ Navigation Section                            │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │ Customize Side Panel                    │ │ │
│  │  │                                         │ │ │
│  │  │ [≡] Home          [✓] (locked)         │ │ │
│  │  │ [≡] Tasks         [✓]                  │ │ │
│  │  │ [≡] Habits        [✓]                  │ │ │
│  │  │ [≡] Profile       [ ]                  │ │ │
│  │  │ [≡] Settings      [✓] (locked)         │ │ │
│  │  │                                         │ │ │
│  │  │ [Save Navigation Changes]               │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ Error Message (if any)                        │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Widgets:**
- `ThemeToggleSection`: Radio buttons or switch for theme selection
- `NavigationCustomizationSection`: Reorderable list with checkboxes
- `NavigationItemTile`: Individual navigation item with drag handle and checkbox
- Error snackbar for storage failures

**Design Decision:** 
- Separate sections for clarity
- Reorderable list uses Flutter's ReorderableListView for native feel
- Save button only for navigation (theme is instant)
- Visual indicators for locked items (Home, Settings)

### 5. Updated MyApp Component

**Purpose:** Apply theme from provider.

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeNotifierProvider).valueOrNull ?? ThemeMode.light;
    
    return MaterialApp.router(
      title: 'Numu App',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
  
  ThemeData _buildLightTheme() { /* ... */ }
  ThemeData _buildDarkTheme() { /* ... */ }
}
```

**Design Decision:** Theme definitions centralized in MyApp for consistency across the app.

### 6. Updated NumuAppShell Component

**Purpose:** Render dynamic navigation based on user preferences.

```dart
class NumuAppShell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationItems = ref.watch(navigationNotifierProvider).valueOrNull ?? [];
    final enabledItems = navigationItems.where((item) => item.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            _buildDrawerHeader(context),
            ...enabledItems.map((item) => _buildNavigationTile(context, item)),
          ],
        ),
      ),
      body: child,
    );
  }
}
```

**Design Decision:** Shell watches navigation provider and rebuilds when preferences change, ensuring immediate UI updates after saving.

## Data Models

### NavigationItem Model

```dart
class NavigationItem {
  final String id;           // Unique identifier (e.g., 'home', 'tasks')
  final String label;        // Display name
  final IconData icon;       // Icon to display
  final String route;        // GoRouter route path
  final bool isHome;         // True if this is the home screen
  final bool isEnabled;      // User-controlled visibility
  final int order;           // Display order (0-based)
  
  // Computed properties
  bool get isLocked => isHome || id == 'settings';
  
  // Serialization for SharedPreferences
  Map<String, dynamic> toJson();
  factory NavigationItem.fromJson(Map<String, dynamic> json);
}
```

### Storage Format

**SharedPreferences Keys and Values:**

```dart
// Theme storage
'theme_mode': 'light' | 'dark' | 'system'

// Navigation visibility (JSON string)
'navigation_items': '{"home": true, "tasks": true, "habits": false, ...}'

// Navigation order (JSON array)
'navigation_order': '["home", "tasks", "habits", "profile", "settings"]'
```

**Design Decision:** JSON strings for complex data structures, simple strings for enums. This balances readability with SharedPreferences' limitations.

## Error Handling

### Storage Errors

**Scenarios:**
1. SharedPreferences initialization fails
2. Read operation fails
3. Write operation fails
4. Corrupted data in storage

**Handling Strategy:**
```dart
class SettingsRepository {
  Future<ThemeMode> getThemeMode() async {
    try {
      final value = _prefs.getString(_themeKey);
      return _parseThemeMode(value);
    } catch (e) {
      CoreLoggingUtility.error('SettingsRepository', 'getThemeMode', 
                               'Failed to load theme: $e');
      return ThemeMode.light; // Default fallback
    }
  }
  
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await _prefs.setString(_themeKey, mode.name);
    } catch (e) {
      CoreLoggingUtility.error('SettingsRepository', 'saveThemeMode', 
                               'Failed to save theme: $e');
      throw SettingsException('Failed to save theme preference');
    }
  }
}
```

**UI Error Handling:**
- Read errors: Use default values, log error, continue silently
- Write errors: Show SnackBar with error message, allow retry
- Never crash the app due to settings failures

**Design Decision:** Graceful degradation - app remains functional even if settings can't be persisted.

### Navigation Validation

**Validation Rules:**
1. Home item must always be enabled
2. Home item must always be first
3. Settings item must always be enabled
4. At least one navigation item must be enabled
5. Order values must be unique and sequential

**Enforcement:**
- Validation in NavigationNotifier before saving
- UI prevents invalid states (disabled checkboxes for locked items)
- Repository validates data on load and repairs if corrupted

## Testing Strategy

### Unit Tests

**SettingsRepository Tests:**
- ✓ Save and retrieve theme mode
- ✓ Save and retrieve navigation visibility
- ✓ Save and retrieve navigation order
- ✓ Handle missing keys (return defaults)
- ✓ Handle corrupted data (return defaults)
- ✓ Handle storage exceptions

**ThemeNotifier Tests:**
- ✓ Load initial theme from repository
- ✓ Update theme and persist
- ✓ Handle repository errors gracefully

**NavigationNotifier Tests:**
- ✓ Load navigation items with saved preferences
- ✓ Toggle item visibility (except locked items)
- ✓ Reorder items (except Home)
- ✓ Save changes to repository
- ✓ Validate before saving
- ✓ Reset to defaults

### Widget Tests

**SettingsScreen Tests:**
- ✓ Display current theme mode
- ✓ Toggle theme updates provider
- ✓ Display navigation items with correct state
- ✓ Reorder navigation items
- ✓ Toggle navigation item visibility
- ✓ Save button persists changes
- ✓ Locked items cannot be modified
- ✓ Error messages display correctly

**NumuAppShell Tests:**
- ✓ Render only enabled navigation items
- ✓ Render items in correct order
- ✓ Home always appears first
- ✓ Navigation items route correctly

### Integration Tests

- ✓ Change theme, restart app, verify theme persists
- ✓ Customize navigation, restart app, verify changes persist
- ✓ Disable navigation item, verify it disappears from drawer
- ✓ Reorder items, verify new order in drawer
- ✓ Storage failure shows error, app continues functioning

## Implementation Phases

### Phase 1: Foundation (Repository & Models)
- Create SettingsRepository with SharedPreferences
- Define NavigationItem model
- Implement serialization/deserialization
- Add error handling and logging

### Phase 2: Theme System
- Create ThemeNotifier provider
- Define light and dark themes
- Update MyApp to use theme provider
- Add theme toggle to SettingsScreen

### Phase 3: Navigation Customization
- Create NavigationNotifier provider
- Update NumuAppShell to use navigation provider
- Build navigation customization UI in SettingsScreen
- Implement reordering and visibility toggle

### Phase 4: Persistence & Polish
- Wire up save functionality
- Add validation logic
- Implement error handling UI
- Add loading states

### Phase 5: Testing & Documentation
- Write unit tests
- Write widget tests
- Write integration tests
- Update user documentation

## Performance Considerations

**Initialization:**
- SharedPreferences loads asynchronously on app start
- Use AsyncValue in providers to handle loading states
- Show splash screen or loading indicator during initialization

**Memory:**
- Navigation items list is small (<10 items), minimal memory impact
- SharedPreferences caches values in memory after first load

**Rebuild Optimization:**
- Theme changes trigger full app rebuild (unavoidable with theme switching)
- Navigation changes only rebuild NumuAppShell drawer
- Use const constructors where possible to minimize rebuilds

## Accessibility Considerations

**Theme:**
- Support system theme preference (ThemeMode.system)
- Ensure sufficient contrast in both light and dark themes
- Test with platform accessibility features (large text, high contrast)

**Navigation:**
- Semantic labels for screen readers
- Drag handles have sufficient touch targets (48x48 dp minimum)
- Keyboard navigation support for reordering

**Settings Screen:**
- Clear section headings for screen readers
- Toggle controls have descriptive labels
- Error messages are announced to screen readers

## Security & Privacy

**Data Storage:**
- SharedPreferences stores data unencrypted (acceptable for UI preferences)
- No sensitive user data in settings
- Settings are device-local, not synced

**Validation:**
- Validate all data loaded from storage
- Sanitize user input (though minimal user input in this feature)
- Prevent injection attacks through proper JSON parsing

## Future Enhancements

**Potential additions not in current scope:**
- Custom color schemes beyond light/dark
- Font size preferences
- Language/localization settings
- Export/import settings
- Cloud sync of preferences
- Per-screen customization (e.g., default habit view)
- Gesture customization
- Notification preferences

These can be added incrementally without major architectural changes due to the modular design.
