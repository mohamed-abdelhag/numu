# Error Handling Implementation

This document describes the comprehensive error handling and loading states implemented for the settings, profile, and theme integration feature.

## Overview

All components now include:
- Try-catch blocks with detailed logging
- Graceful fallbacks for missing or corrupted data
- Loading indicators for async operations
- Retry mechanisms with user feedback
- Comprehensive error messages

## Components

### 1. SettingsRepository

**Error Handling:**
- All methods wrapped in try-catch blocks
- Graceful fallbacks to default values on errors
- Corrupted data detection and automatic cleanup
- Detailed logging for all operations
- Custom `SettingsException` for operation failures

**Corrupted Data Handling:**
- `_clearCorruptedData()`: Automatically removes corrupted preferences
- Format exception handling for JSON parsing errors
- Invalid theme ID detection and cleanup
- Invalid theme mode detection and cleanup

**New Methods:**
- `validateStorageHealth()`: Validates all stored settings and returns diagnostic info
- `clearAllSettings()`: Emergency recovery method to clear all settings

**Graceful Fallbacks:**
- Theme mode: Defaults to `ThemeMode.light`
- Color scheme: Defaults to `'blue'`
- Navigation items: Defaults to empty map (uses app defaults)
- Navigation order: Defaults to empty list (uses app defaults)

### 2. ThemeRegistry

**Error Handling:**
- `getTheme()`: Returns default theme instead of throwing on invalid ID
- `getThemeStrict()`: New method that throws for strict validation
- All theme IDs validated before use

**Graceful Fallbacks:**
- Invalid theme IDs automatically fall back to 'blue' theme
- No crashes from missing theme definitions

### 3. ThemeConfigProvider

**Error Handling:**
- State rollback on save failures
- Detailed logging for all operations
- Re-throws errors for UI handling
- Validates theme IDs before saving

**Loading States:**
- AsyncValue states properly handled
- Previous state preserved during updates
- Automatic provider invalidation on changes

### 4. ThemeSelectorScreen

**Error Handling:**
- Preview failures show snackbar with retry option
- Save failures show snackbar with retry option
- Loading state prevents multiple save operations
- Unsaved changes dialog on back navigation

**Loading States:**
- Save button shows loading indicator
- Grid shows loading state while config loads
- Error state with retry button for config load failures

**User Feedback:**
- Success snackbars for saved themes
- Error snackbars with detailed messages
- Retry actions on all error snackbars

### 5. ThemePreviewCard

**Error Handling:**
- Try-catch around theme building
- Error state card shown on build failures
- Detailed logging of theme build errors

**Graceful Fallbacks:**
- Shows error card with theme name and "Failed to load" message
- Still allows tap interaction for retry

### 6. ProfileSection

**Error Handling:**
- Form validation with inline error messages
- Save failures show snackbar with retry option
- Loading state prevents multiple save operations
- Error state with retry button for profile load failures

**Loading States:**
- Loading indicator while profile loads
- Save button shows loading state
- Form fields disabled during save

**User Feedback:**
- Success snackbars for saved profiles
- Error snackbars with detailed messages and retry
- Validation errors shown inline

### 7. SettingsScreen

**Error Handling:**
- Separate error states for each section
- Retry buttons for all failed loads
- Theme mode change failures with retry
- Week start preference failures with retry
- Navigation save failures with retry

**Loading States:**
- Loading indicators for theme provider
- Loading indicators for profile provider
- Loading indicators for navigation provider
- Loading indicators for theme config provider

**User Feedback:**
- Success snackbars for all save operations
- Error snackbars with detailed messages
- Retry actions on all error snackbars
- Color-coded feedback (green for success, red for errors)

## Error Types Handled

### 1. Storage Errors
- SharedPreferences write failures
- SharedPreferences read failures
- Corrupted JSON data
- Missing keys

### 2. Validation Errors
- Invalid theme IDs
- Invalid theme modes
- Invalid email formats
- Empty required fields

### 3. Theme Building Errors
- Theme builder exceptions
- Missing theme definitions
- Color scheme extraction failures

### 4. Network/Async Errors
- Async operation timeouts
- Concurrent modification issues
- State management errors

### 5. User Input Errors
- Form validation failures
- Invalid data entry
- Unsaved changes

## Logging Strategy

All components use `CoreLoggingUtility` with:
- **Info logs**: Successful operations, state changes
- **Warning logs**: Recoverable issues, fallbacks used
- **Error logs**: Failures with full stack traces

Log format:
```dart
CoreLoggingUtility.error(
  'ComponentName',
  'methodName',
  'Detailed error message: $error\nStack trace: $stackTrace',
);
```

## User Feedback Patterns

### Success Feedback
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 12),
        Text('Operation successful'),
      ],
    ),
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.green,
  ),
);
```

### Error Feedback with Retry
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Text('Operation failed'),
          ],
        ),
        SizedBox(height: 4),
        Text(error.toString(), style: TextStyle(fontSize: 12)),
      ],
    ),
    duration: Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.red,
    action: SnackBarAction(
      label: 'Retry',
      textColor: Colors.white,
      onPressed: retryFunction,
    ),
  ),
);
```

## Testing Error Scenarios

To test error handling:

1. **Corrupted Data**: Manually edit SharedPreferences with invalid JSON
2. **Invalid Theme ID**: Set color_scheme to non-existent theme
3. **Storage Failures**: Simulate SharedPreferences failures
4. **Theme Build Failures**: Test with malformed theme definitions
5. **Network Issues**: Test with slow/failing async operations

## Recovery Mechanisms

### Automatic Recovery
- Corrupted data automatically cleared
- Invalid values replaced with defaults
- Failed operations logged and retried

### Manual Recovery
- Retry buttons on all error states
- Clear all settings option (via `clearAllSettings()`)
- Storage health validation (via `validateStorageHealth()`)

## Requirements Coverage

This implementation satisfies all requirements from task 8:

✅ **7.3**: Theme persistence handles storage errors gracefully without crashing
✅ **7.4**: Preferences Repository handles storage errors with fallbacks
✅ **9.1**: Theme loading failures show error messages with retry buttons
✅ **9.2**: Theme saving failures show snackbars with error details and retry
✅ **9.3**: Profile loading failures show error in section with retry capability
✅ **9.4**: All errors logged with context for debugging
✅ **9.5**: Database unavailability shows user-friendly messages

## Additional Features

Beyond the requirements, we also implemented:

- Storage health validation
- Corrupted data detection and cleanup
- Comprehensive logging throughout
- Loading states for all async operations
- Graceful fallbacks for all error scenarios
- Retry mechanisms on all failures
- User-friendly error messages
- Color-coded feedback (green/red)
