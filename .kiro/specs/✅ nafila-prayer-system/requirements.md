# Requirements Document

## Introduction

This document specifies the requirements for adding a Nafila (Sunnah/voluntary) prayer tracking system to the existing Islamic Prayer feature in the numu app. The system will allow users to track optional prayers that complement the five obligatory daily prayers, including defined Sunnah prayers (Sunnah Fajr, Duha, Shaf'i/Witr) and custom Nafila prayers. The feature will display these prayers in the prayer screen, track statistics, and optionally show them on the home screen.

## Glossary

- **Nafila**: Voluntary/optional prayers beyond the five obligatory prayers
- **Sunnah Prayer**: Recommended prayers based on the Prophet's practice
- **Sunnah Fajr**: 2 rakats prayed after Fajr azan but before the obligatory Fajr prayer
- **Duha Prayer**: 2-12 rakats prayed after sunrise until before Dhuhr time
- **Shaf'i/Witr**: Night prayers prayed after Isha (Shaf'i is even rakats, Witr is odd)
- **Rakat**: A unit of prayer consisting of standing, bowing, and prostrating
- **Prayer Schedule**: The calculated times for daily prayers based on location
- **Time Window**: The valid period during which a specific prayer can be performed
- **Nafila Event**: A logged instance of completing a Nafila prayer

## Requirements

### Requirement 1

**User Story:** As a Muslim user, I want to track defined Sunnah prayers (Sunnah Fajr, Duha, Shaf'i/Witr), so that I can monitor my voluntary worship alongside obligatory prayers.

#### Acceptance Criteria

1. WHEN the prayer screen loads THEN the Nafila_System SHALL display three defined Sunnah prayer slots: Sunnah Fajr (between Fajr azan and Fajr prayer), Duha (after sunrise until before Dhuhr), and Shaf'i/Witr (after Isha)
2. WHEN a user taps on a defined Sunnah prayer card THEN the Nafila_System SHALL open a logging dialog allowing the user to record the number of rakats prayed
3. WHEN a user logs a Sunnah Fajr prayer THEN the Nafila_System SHALL validate that the time is between Fajr azan time and the scheduled Fajr prayer time from the prayer schedule
4. WHEN a user logs a Duha prayer THEN the Nafila_System SHALL validate that the time is after sunrise plus 15 minutes and before Dhuhr time minus 15 minutes
5. WHEN a user logs Shaf'i/Witr prayers THEN the Nafila_System SHALL validate that the time is after Isha prayer time and before Fajr azan time of the next day

### Requirement 2

**User Story:** As a Muslim user, I want to log custom Nafila prayers at any time, so that I can track additional voluntary prayers beyond the defined Sunnah prayers.

#### Acceptance Criteria

1. WHEN a user taps the "Add Nafila" button in the prayer screen THEN the Nafila_System SHALL display a dialog to log custom Nafila prayers with rakat count and optional time selection
2. WHEN a user submits a custom Nafila prayer THEN the Nafila_System SHALL store the event with the number of rakats, timestamp, and associate it with the appropriate time period
3. WHEN displaying custom Nafila prayers THEN the Nafila_System SHALL show them as small cards positioned between the relevant obligatory prayers based on their logged time

### Requirement 3

**User Story:** As a Muslim user, I want to see Nafila prayers displayed in the prayer screen, so that I can view my voluntary prayers alongside obligatory prayers.

#### Acceptance Criteria

1. WHEN the prayer screen displays prayers THEN the Nafila_System SHALL show defined Sunnah prayers as thin green indicator cards between the relevant obligatory prayer cards
2. WHEN a defined Sunnah prayer is completed THEN the Nafila_System SHALL display a checkmark and the number of rakats on the indicator card
3. WHEN custom Nafila prayers exist for the day THEN the Nafila_System SHALL display them as small cards in chronological order between the appropriate obligatory prayers
4. WHEN no Nafila prayers are logged for a time slot THEN the Nafila_System SHALL display the indicator card in a muted/inactive state

### Requirement 4

**User Story:** As a Muslim user, I want a dedicated prayer statistics screen showing all prayer types, so that I can track my complete prayer journey including obligatory and voluntary prayers.

#### Acceptance Criteria

1. WHEN a user navigates to the prayer statistics screen THEN the Statistics_Screen SHALL display a calendar view showing prayer completion for each day
2. WHEN displaying the calendar view THEN the Statistics_Screen SHALL show indicators for all five obligatory prayers and three defined Sunnah prayers for each day
3. WHEN a user scrolls below the calendar THEN the Statistics_Screen SHALL display detailed statistics graphs/charts for all prayer types
4. WHEN displaying statistics THEN the Statistics_Screen SHALL show completion rates, streaks, and trends for Fajr, Dhuhr, Asr, Maghrib, Isha, Sunnah Fajr, Duha, and Shaf'i/Witr
5. WHEN displaying Nafila-specific statistics THEN the Statistics_Screen SHALL show total rakats prayed and average rakats per session for each Sunnah type
6. WHEN displaying custom Nafila statistics THEN the Statistics_Screen SHALL show total custom Nafila prayers logged over time

### Requirement 5

**User Story:** As a Muslim user, I want to optionally see Nafila prayer status on the home screen, so that I can quickly check my voluntary prayer progress for the day.

#### Acceptance Criteria

1. WHEN the "Show Nafila at Home" setting is enabled THEN the Home_Screen SHALL display Nafila prayer completion status cards alongside obligatory prayer items
2. WHEN displaying Nafila on the home screen THEN the Home_Screen SHALL show only completion status (done/not done) without detailed rakat information
3. WHEN the "Show Nafila at Home" setting is disabled THEN the Home_Screen SHALL hide all Nafila prayer cards from the daily items list
4. WHEN a user taps a Nafila card on the home screen THEN the Home_Screen SHALL navigate to the prayer screen for detailed logging

### Requirement 8

**User Story:** As a Muslim user, I want to access the prayer statistics screen from the prayer screen, so that I can easily view my prayer history and progress.

#### Acceptance Criteria

1. WHEN a user is on the prayer screen THEN the Prayer_Screen SHALL display a button/icon to navigate to the statistics screen
2. WHEN a user taps the statistics button THEN the Prayer_Screen SHALL navigate to the dedicated prayer statistics screen
3. WHEN the statistics screen loads THEN the Statistics_Screen SHALL display the calendar view at the top followed by detailed statistics below

### Requirement 6

**User Story:** As a Muslim user, I want to configure Nafila display preferences in settings, so that I can customize how voluntary prayers appear in the app.

#### Acceptance Criteria

1. WHEN a user opens prayer settings THEN the Settings_Screen SHALL display a "Show Nafila at Home" toggle option
2. WHEN a user toggles the "Show Nafila at Home" setting THEN the Settings_Repository SHALL persist the preference and the Home_Screen SHALL update immediately
3. WHEN the app launches THEN the Settings_Repository SHALL load the Nafila display preference and apply it to the home screen

### Requirement 7

**User Story:** As a developer, I want Nafila data stored in separate database tables, so that the existing prayer system remains unmodified and data integrity is maintained.

#### Acceptance Criteria

1. WHEN the database initializes THEN the Database_Service SHALL create a nafila_events table with columns for event_id, nafila_type, event_date, event_timestamp, rakat_count, actual_prayer_time, notes, created_at, and updated_at
2. WHEN the database initializes THEN the Database_Service SHALL create a nafila_scores table with columns for nafila_type, score, current_streak, longest_streak, total_rakats, calculated_at, and last_event_date
3. WHEN storing Nafila events THEN the Nafila_Repository SHALL use the nafila_events table without modifying the existing prayer_events table
4. WHEN serializing Nafila events to the database THEN the Nafila_Repository SHALL convert NafilaEvent objects to map format and parse them back correctly
5. WHEN deserializing Nafila events from the database THEN the Nafila_Repository SHALL convert map data to NafilaEvent objects with all fields populated correctly
