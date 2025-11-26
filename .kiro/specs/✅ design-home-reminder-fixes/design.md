# Design Document

## Overview

This design addresses three improvements to the numu habit tracking application:

1. **Habit Card Layout Redesign**: Restructure the habit card to move streak and score badges from the header row to a dedicated badge row, improving visual hierarchy and readability.

2. **Home Screen Real-time Updates**: Implement proper state management to ensure the home screen reflects habit completion changes immediately without requiring manual refresh.

3. **Notification Permission Settings**: Add a notifications section to the settings screen that displays permission status and allows users to enable notifications for reminders.

## Architecture

The changes follow the existing feature-first architecture:

```
lib/features/
├── habits/
│   └── widgets/
│       └── habit_card.dart          # Layout restructure
├── home/
│   ├── home_screen.dart             # Real-time update handling
│   ├── providers/
│   │   └── daily_items_provider.dart # State refresh logic
│   └── widgets/
│       └── daily_item_card.dart     # Callback propagation
├── settings/
│   └── settings_screen.dart         # Notification settings section
└── reminders/
    └── services/
        └── notification_service.dart # Permission checking (existing)
```

## Components and Interfaces

### 1. Habit Card Layout Changes

**Current Structure:**
```
┌─────────────────────────────────────────────────────┐
│ [Icon] Name/Description  [Value] [Streak] [Score] [+]│
│                                                      │
│ [Weekly Progress Dots/Bars]        [Circular %]     │
└─────────────────────────────────────────────────────┘
```

**New Structure:**
```
┌─────────────────────────────────────────────────────┐
│ [Icon] Name/Description                          [+]│
│                                                      │
│ [Value Badge]  [🔥 Streak]  [⚡ Score]              │
│                                                      │
│ [Weekly Progress Dots/Bars]        [Circular %]     │
└─────────────────────────────────────────────────────┘
```

**Widget Changes in `habit_card.dart`:**
- Remove streak badge, score badge, and value badge from header Row
- Add new `_buildBadgeRow()` method that renders badges in a horizontal Wrap widget
- Position badge row between header and progress sections with appropriate spacing

### 2. Home Screen Real-time Updates

**Problem:** The `DailyItemCard` calls `onActionComplete` which invalidates `dailyItemsProvider`, but the provider doesn't properly watch habit state changes.

**Solution:** 
- Ensure `DailyItemCard.onActionComplete` callback properly triggers provider refresh
- The existing `ref.invalidate(dailyItemsProvider)` should work, but we need to verify the callback chain is complete
- Add watch on relevant habit providers to trigger automatic rebuilds

**Flow:**
```
User taps complete → HabitQuickActionButton → habit_detail_provider updates
                                            ↓
                   onActionComplete callback → invalidate dailyItemsProvider
                                            ↓
                   dailyItemsProvider rebuilds → UI updates
```

### 3. Notification Permission Settings

**New Settings Section:**
```dart
Widget _buildNotificationsSection(BuildContext context, WidgetRef ref) {
  // Check current permission status
  // Display status indicator (enabled/disabled)
  // Provide action to request permissions or open settings
}
```

**Permission States:**
- `granted`: Show green checkmark, "Notifications enabled"
- `denied`: Show warning icon, "Tap to enable notifications"
- `permanentlyDenied`: Show error icon, "Open device settings to enable"

**Integration with NotificationService:**
- Use existing `areNotificationsEnabled()` method
- Use existing `requestPermissions()` method
- Add method to open app settings for permanently denied case

## Data Models

No new data models required. Existing models are sufficient:

- `Habit` - habit data with tracking type
- `DailyItem` - home screen item representation
- `Reminder` - notification scheduling data

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Header row excludes badges
*For any* habit card widget, the header row widget subtree SHALL NOT contain streak badge, score badge, or value badge widgets.
**Validates: Requirements 1.1**

### Property 2: Badge row contains all badges
*For any* habit card widget, the badge row SHALL contain the streak badge and score badge widgets, positioned between the header and progress sections.
**Validates: Requirements 1.2**

### Property 3: Value badge conditional rendering
*For any* habit with `trackingType == TrackingType.value`, the badge row SHALL include the value badge widget alongside streak and score badges.
**Validates: Requirements 1.3**

### Property 4: Completion percentage calculation
*For any* list of daily items with known completion states, the calculated completion percentage SHALL equal `(completedCount / totalCount) * 100` rounded to the nearest integer.
**Validates: Requirements 2.2**

### Property 5: Permission status display consistency
*For any* notification permission state (granted, denied, permanentlyDenied), the settings UI SHALL display the corresponding visual indicator matching that state.
**Validates: Requirements 3.2, 3.4, 3.6**

## Error Handling

### Habit Card
- Gracefully handle missing streak/score data with fallback values
- Handle color parsing errors with default theme color

### Home Screen Updates
- Handle provider refresh failures with error state display
- Maintain previous state if refresh fails

### Notification Permissions
- Handle platform-specific permission API differences
- Provide fallback UI if permission status cannot be determined
- Handle case where user navigates away during permission request

## Testing Strategy

### Unit Testing
- Test completion percentage calculation with various input combinations
- Test permission state to UI indicator mapping

### Property-Based Testing
Using `dart_quickcheck` or `glados` package for property-based tests:

1. **Badge Row Structure Property**: Generate random habits and verify badge row always contains expected badges based on tracking type
2. **Completion Percentage Property**: Generate random lists of daily items and verify percentage calculation is always correct
3. **Permission State Display Property**: Generate all permission states and verify correct UI indicator is displayed

Each property-based test will:
- Run minimum 100 iterations
- Be tagged with the corresponding correctness property reference
- Use format: `**Feature: design-home-reminder-fixes, Property {number}: {property_text}**`

### Widget Testing
- Test habit card renders correct structure
- Test settings screen displays notification section
- Test permission request flow triggers correct callbacks

### Integration Testing
- Test end-to-end habit completion flow updates home screen
- Test notification permission grant/deny flows

