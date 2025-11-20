# Requirements Document

## Introduction

This feature adds internationalization (i18n) support to the Numu app with Arabic language localization. The System will extract all hardcoded UI strings, generate localization files, and provide a language selector in the settings screen. Users will be able to switch between English and Arabic languages, with the app automatically adapting text direction (LTR/RTL) and displaying all UI elements in the selected language.

### Requirement 1

**User Story:** As a user, I want the app to support multiple languages, so that I can use the app in my preferred language

#### Acceptance Criteria

1. WHEN THE System starts, THE System SHALL load the user's previously selected language preference from persistent storage
2. WHEN no language preference exists, THE System SHALL default to English (en) locale
3. WHEN THE System loads a locale, THE System SHALL apply the corresponding language strings to all UI elements
4. WHEN THE System loads Arabic locale, THE System SHALL set text direction to RTL
5. WHEN THE System loads English locale, THE System SHALL set text direction to LTR

### Requirement 2

**User Story:** As a user, I want to select my preferred language from the settings screen, so that I can switch between English and Arabic

#### Acceptance Criteria

1. WHEN THE User navigates to the settings screen, THE System SHALL display a language selector option in the preferences section
2. WHEN THE User taps the language selector, THE System SHALL display a dialog with available language options (English and Arabic)
3. WHEN THE User selects a language, THE System SHALL save the language preference to persistent storage
4. WHEN THE User selects a language, THE System SHALL immediately apply the new language to all UI elements
5. WHEN THE User selects a language, THE System SHALL display a confirmation message in the newly selected language

### Requirement 3

**User Story:** As a developer, I want all hardcoded UI strings extracted and localized, so that the app can display text in multiple languages

#### Acceptance Criteria

1. THE System SHALL extract all hardcoded UI strings from Dart files using the provided Python scripts
2. THE System SHALL generate ARB files containing English translations for all extracted strings
3. THE System SHALL generate ARB files containing Arabic translations for all extracted strings
4. THE System SHALL replace all hardcoded strings in Dart files with localization references (context.l10n.keyName)
5. THE System SHALL generate Dart localization classes from ARB files using Flutter's gen-l10n tool

### Requirement 4

**User Story:** As a user, I want the app interface to adapt to my selected language, so that all text and layout elements are properly displayed

#### Acceptance Criteria

1. WHEN Arabic locale is active, THE System SHALL display all text in Arabic script
2. WHEN Arabic locale is active, THE System SHALL align text to the right
3. WHEN Arabic locale is active, THE System SHALL reverse the order of directional UI elements (e.g., back buttons, navigation)
4. WHEN English locale is active, THE System SHALL display all text in English
5. WHEN English locale is active, THE System SHALL align text to the left

### Requirement 5

**User Story:** As a developer, I want the localization system properly configured, so that adding new languages in the future is straightforward

#### Acceptance Criteria

1. THE System SHALL include flutter_localizations dependency in pubspec.yaml
2. THE System SHALL include intl dependency in pubspec.yaml
3. THE System SHALL configure l10n.yaml with proper ARB directory and template settings
4. THE System SHALL store ARB files in lib/l10n directory
5. THE System SHALL generate localization classes in .dart_tool/flutter_gen/gen_l10n directory
