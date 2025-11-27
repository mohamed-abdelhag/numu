# Requirements Document

## Introduction

The Islamic Prayer System is a dedicated feature for tracking the five daily prayers (Salah) in the numu app. This system operates separately from regular habits with its own data models and tables, while leveraging existing algorithms for streaks, scoring, and consistency tracking. Prayer times are dynamically fetched from an API based on user location, and each prayer has a 30-minute completion window. The feature integrates with the home screen, reminder system, and can be enabled/disabled through settings, profile, and onboarding flows.

## Glossary

- **Salah**: The five obligatory daily prayers in Islam
- **Fajr**: Dawn prayer, performed before sunrise
- **Dhuhr**: Noon prayer, performed after the sun passes its zenith
- **Asr**: Afternoon prayer, performed in the late afternoon
- **Maghrib**: Sunset prayer, performed just after sunset
- **Isha**: Night prayer, performed after twilight disappears
- **Jamaah (جماعة)**: Congregational prayer, praying in a group
- **Prayer Time API**: External service providing accurate prayer times based on geographic location and calculation method
- **Calculation Method**: Mathematical method used to determine prayer times (e.g., Muslim World League, ISNA, Egyptian General Authority)
- **Time Window**: The 30-minute period after a prayer's start time during which completion is tracked
- **Prayer Score**: A metric measuring prayer consistency and quality over time
- **Islamic Prayer System**: The complete feature module for prayer tracking
- **Location Permission**: Device permission required to determine user's geographic coordinates for prayer time calculation

## Requirements

### Requirement 1: Prayer Time Retrieval

**User Story:** As a Muslim user, I want the app to automatically fetch accurate prayer times for my location, so that I know when each prayer begins.

#### Acceptance Criteria

1. WHEN the Islamic Prayer System is enabled AND the user grants location permission, THEN the Islamic Prayer System SHALL fetch prayer times from a prayer time API using the user's geographic coordinates.
2. WHEN prayer times are successfully fetched, THEN the Islamic Prayer System SHALL store the prayer schedule locally for offline access.
3. WHEN the user's location changes significantly (more than 10 kilometers), THEN the Islamic Prayer System SHALL refresh the prayer times for the new location.
4. WHEN the prayer time API is unavailable, THEN the Islamic Prayer System SHALL use the most recently cached prayer times and display a notification indicating offline mode.
5. WHEN a new day begins, THEN the Islamic Prayer System SHALL automatically fetch updated prayer times for the current date.
6. WHEN fetching prayer times, THEN the Islamic Prayer System SHALL support multiple calculation methods (Muslim World League, ISNA, Egyptian General Authority, Umm Al-Qura).

### Requirement 2: Prayer Tracking

**User Story:** As a Muslim user, I want to log each of my five daily prayers, so that I can track my prayer consistency.

#### Acceptance Criteria

1. WHEN a user marks a prayer as completed, THEN the Islamic Prayer System SHALL record the prayer event with timestamp and prayer type.
2. WHEN a user logs a prayer, THEN the Islamic Prayer System SHALL allow the user to specify the actual time the prayer was performed.
3. WHEN a user logs a prayer, THEN the Islamic Prayer System SHALL capture whether the prayer was performed in congregation (Jamaah) or individually.
4. WHEN a prayer's time window (30 minutes after start time) expires without logging, THEN the Islamic Prayer System SHALL mark the prayer as missed for that day.
5. WHEN displaying prayer status, THEN the Islamic Prayer System SHALL show one of three states: completed, pending, or missed.
6. WHEN a user attempts to log a prayer for a future time, THEN the Islamic Prayer System SHALL prevent the action and display a validation message.

### Requirement 3: Prayer Data Storage

**User Story:** As a developer, I want prayer data stored in dedicated tables separate from regular habits, so that the systems remain decoupled and maintainable.

#### Acceptance Criteria

1. WHEN storing prayer data, THEN the Islamic Prayer System SHALL use a dedicated prayers table separate from the habits table.
2. WHEN storing prayer events, THEN the Islamic Prayer System SHALL use a dedicated prayer_events table separate from habit_events.
3. WHEN storing prayer schedules, THEN the Islamic Prayer System SHALL use a dedicated prayer_schedules table containing daily prayer times.
4. WHEN the database is initialized, THEN the Islamic Prayer System SHALL create all required tables with appropriate foreign key constraints.
5. WHEN the Islamic Prayer System is disabled, THEN the database tables SHALL remain intact to preserve historical data.

### Requirement 4: Prayer Score and Statistics

**User Story:** As a Muslim user, I want to see my prayer consistency score and streaks, so that I can measure my spiritual progress.

#### Acceptance Criteria

1. WHEN calculating prayer score, THEN the Islamic Prayer System SHALL use the existing streak calculation algorithms from the habits feature.
2. WHEN displaying statistics, THEN the Islamic Prayer System SHALL show an overall prayer score across all five prayers.
3. WHEN displaying statistics, THEN the Islamic Prayer System SHALL show individual scores for each of the five prayers.
4. WHEN calculating streaks, THEN the Islamic Prayer System SHALL track current streak and longest streak for each prayer type.
5. WHEN a prayer is logged with congregation (Jamaah), THEN the Islamic Prayer System SHALL apply a quality multiplier to the prayer score calculation.
6. WHEN displaying weekly statistics, THEN the Islamic Prayer System SHALL show completion percentage for each prayer across the week.

### Requirement 5: Prayer Reminders

**User Story:** As a Muslim user, I want to receive reminders for each prayer, so that I do not miss my prayer times.

#### Acceptance Criteria

1. WHEN the user enables prayer reminders, THEN the Islamic Prayer System SHALL integrate with the existing reminder system to schedule notifications.
2. WHEN scheduling prayer reminders, THEN the Islamic Prayer System SHALL allow the user to set reminder offset (minutes before prayer time).
3. WHEN prayer times change (new day or location change), THEN the Islamic Prayer System SHALL automatically reschedule all prayer reminders.
4. WHEN a prayer reminder is triggered, THEN the Islamic Prayer System SHALL display a notification with the prayer name and time.
5. WHEN the user taps a prayer reminder notification, THEN the Islamic Prayer System SHALL navigate to the prayer tracking screen.
6. WHEN configuring reminders, THEN the Islamic Prayer System SHALL allow enabling or disabling reminders for each prayer individually.

### Requirement 6: Islamic Prayer Screen

**User Story:** As a Muslim user, I want a dedicated screen showing all five prayers and my prayer statistics, so that I can manage my daily prayers in one place.

#### Acceptance Criteria

1. WHEN the user navigates to the Islamic Prayer Screen, THEN the Islamic Prayer System SHALL display all five prayers with their current status (completed, pending, missed).
2. WHEN displaying prayers, THEN the Islamic Prayer System SHALL show the prayer time for each prayer based on the fetched schedule.
3. WHEN displaying prayers, THEN the Islamic Prayer System SHALL show the remaining time until the next pending prayer.
4. WHEN the user taps a prayer card, THEN the Islamic Prayer System SHALL display a logging dialog to mark the prayer as completed.
5. WHEN displaying the screen header, THEN the Islamic Prayer System SHALL show the overall daily prayer score and completion count (e.g., "3/5 prayers completed").
6. WHEN displaying statistics, THEN the Islamic Prayer System SHALL show current streak and weekly completion rate.

### Requirement 7: Home Screen Integration

**User Story:** As a user, I want to see my prayer status on the home screen alongside habits and tasks, so that I have a unified daily overview.

#### Acceptance Criteria

1. WHEN the Islamic Prayer System is enabled, THEN the home screen SHALL display prayer items in the daily items list.
2. WHEN displaying prayer items on home screen, THEN the Islamic Prayer System SHALL show the next pending prayer prominently.
3. WHEN a user completes a prayer from the home screen, THEN the Islamic Prayer System SHALL update the prayer status immediately.
4. WHEN the Islamic Prayer System is disabled, THEN the home screen SHALL hide all prayer-related items.
5. WHEN displaying daily progress, THEN the home screen SHALL include prayer completion in the overall daily progress calculation.

### Requirement 8: Settings and Configuration

**User Story:** As a user, I want to enable or disable the Islamic Prayer System and configure its settings, so that I can customize my app experience.

#### Acceptance Criteria

1. WHEN the user accesses settings, THEN the Islamic Prayer System SHALL provide a toggle to enable or disable the feature.
2. WHEN the Islamic Prayer System is disabled via settings, THEN the system SHALL hide all prayer-related UI elements without deleting stored data.
3. WHEN the Islamic Prayer System is enabled, THEN the settings screen SHALL display prayer-specific configuration options.
4. WHEN configuring the Islamic Prayer System, THEN the user SHALL be able to select their preferred calculation method for prayer times.
5. WHEN configuring the Islamic Prayer System, THEN the user SHALL be able to set the time window duration (default 30 minutes).
6. WHEN the user has not granted location permission, THEN the settings screen SHALL prompt the user to grant permission with an explanation.

### Requirement 9: Profile Integration

**User Story:** As a user, I want to manage my Islamic Prayer System preference from my profile, so that I can quickly toggle the feature.

#### Acceptance Criteria

1. WHEN viewing the profile screen, THEN the Islamic Prayer System SHALL display a toggle for enabling or disabling the feature.
2. WHEN the user toggles the Islamic Prayer System from profile, THEN the change SHALL take effect immediately across the app.
3. WHEN the Islamic Prayer System is enabled in profile, THEN the profile screen SHALL display a summary of prayer statistics.

### Requirement 10: Onboarding Integration

**User Story:** As a new user, I want to be asked about enabling the Islamic Prayer System during onboarding, so that I can set up the feature from the start.

#### Acceptance Criteria

1. WHEN a user goes through onboarding, THEN the onboarding flow SHALL include a step asking if the user wants to enable the Islamic Prayer System.
2. WHEN the user enables the Islamic Prayer System during onboarding, THEN the system SHALL request location permission with a clear explanation.
3. WHEN the user skips the Islamic Prayer System during onboarding, THEN the feature SHALL remain disabled but accessible through settings.

### Requirement 11: Location Permission Handling

**User Story:** As a user, I want the app to properly request and handle location permissions, so that prayer times can be calculated accurately.

#### Acceptance Criteria

1. WHEN the Islamic Prayer System requires location, THEN the system SHALL request location permission using the platform-appropriate method (iOS/Android).
2. WHEN location permission is denied, THEN the Islamic Prayer System SHALL display a message explaining why location is needed and provide a link to app settings.
3. WHEN location permission is granted, THEN the Islamic Prayer System SHALL fetch the user's coordinates and retrieve prayer times.
4. WHEN the app is launched with the Islamic Prayer System enabled, THEN the system SHALL check location permission status and handle accordingly.
5. WHEN location permission status changes, THEN the Islamic Prayer System SHALL update its behavior immediately.

### Requirement 12: Sidebar Navigation

**User Story:** As a user, I want to access the Islamic Prayer System from the app navigation, so that I can quickly view and manage my prayers.

#### Acceptance Criteria

1. WHEN the Islamic Prayer System is enabled, THEN the app navigation SHALL display a prayer menu item.
2. WHEN the user taps the prayer navigation item, THEN the app SHALL navigate to the Islamic Prayer Screen.
3. WHEN the Islamic Prayer System is disabled, THEN the navigation SHALL hide the prayer menu item.
