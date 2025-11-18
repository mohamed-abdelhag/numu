# Design Document: Profile, Onboarding & Help System

## Overview

This feature introduces four interconnected components that enhance the user experience: a splash screen animation, a first-time onboarding flow, comprehensive profile management, and an in-app help system. These components work together to welcome new users, provide guidance throughout the app lifecycle, and enable users to manage their personal information.

The design follows Flutter best practices and integrates seamlessly with the existing Numu app architecture, which uses Riverpod for state management, GoRouter for navigation, and SQLite for persistent storage.

## Architecture

### High-Level Component Structure

```
┌─────────────────────────────────────────────────────────┐
│                      App Launch                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Splash Screen                           │
│              (2 second animation)                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ First Launch?│
              └──────┬───────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
    ┌─────────┐           ┌──────────┐
    │Onboarding│          │   Home   │
    │  Flow   │          │  Screen  │
    └────┬────┘           └──────────┘
         │
         ▼
    ┌─────────┐
    │  Home   │
    │ Screen  │
    └─────────┘
```

### State Management Architecture

The design uses Riverpod providers for state management:

1. **UserProfileProvider**: Manages user profile data (name, email, profile picture)
2. **OnboardingStateProvider**: Tracks onboarding completion status
3. **TutorialCardsProvider**: Provides tutorial card content for help and onboarding

### Data Flow

```
User Action → Provider → Repository → Database Service → SQLite
                ↓
            UI Update
```

## Components and Interfaces

### 1. Splash Screen Component

**Purpose**: Display an animated emoji sequence during app initialization

**Design Decisions**:
- Uses a StatefulWidget with AnimatedSwitcher for smooth transitions
- 500ms per emoji ensures smooth animation without feeling rushed
- Total duration of 2 seconds provides adequate time for initialization
- Emoji sequence (🌱 → 🌿 → 🌳 → 🍎) represents growth, aligning with the app's habit-tracking purpose

**Interface**:
```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentEmojiIndex = 0;
  final List<String> _emojis = ['🌱', '🌿', '🌳', '🍎'];
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }
  
  Future<void> _startAnimation() async {
    // Cycle through emojis every 500ms
    // After 2 seconds, check onboarding status and navigate
  }
}
```

### 2. Onboarding Flow Component

**Purpose**: Guide first-time users through app features

**Design Decisions**:
- Uses PageView for swipeable card navigation
- Reuses tutorial card content from help system (DRY principle)
- Stores completion flag in SharedPreferences for fast access
- Provides Skip button for users who want to explore independently
- Shows progress indicator (e.g., "1 of 2") for clarity

**Interface**:
```dart
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  void _completeOnboarding() async {
    // Save completion flag
    // Navigate to home
  }
}
```

**Onboarding Cards**:
1. "What's this app?" - Explains the app's purpose
2. "How to use the app" - Provides basic usage instructions

### 3. Profile Management Component

**Purpose**: Allow users to view and edit their personal information

**Design Decisions**:
- Separates view and edit modes for cleaner UX
- Uses Form widget with TextFormField for validation
- Stores profile data in SQLite for persistence
- Updates side panel name in real-time using Riverpod
- Validates email format and required fields before saving

**Interface**:
```dart
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Save to database via provider
      // Update UI
    }
  }
}
```

**Profile Fields**:
- Name (required, max 50 characters)
- Email (optional, must be valid email format)
- Profile Picture (optional, stored as file path or URL)

### 4. Side Panel Enhancement

**Purpose**: Display user's name in the navigation drawer

**Design Decisions**:
- Updates existing NumuAppShell drawer header
- Listens to UserProfileProvider for real-time updates
- Shows "Welcome, Guest" as default when no name is set
- Maintains existing navigation structure

**Interface Update**:
```dart
// In NumuAppShell
DrawerHeader(
  child: Consumer(
    builder: (context, ref, child) {
      final userName = ref.watch(userProfileProvider).name;
      return Column(
        children: [
          Icon(Icons.account_circle, size: 64),
          Text(userName ?? 'Welcome, Guest'),
        ],
      );
    },
  ),
)
```

### 5. Help System Component

**Purpose**: Provide accessible tutorials and guidance

**Design Decisions**:
- Uses a list-detail navigation pattern
- Tutorial cards are stored as data models (not hardcoded)
- Allows for future expansion with more tutorial cards
- Shares content structure with onboarding for consistency

**Interface**:
```dart
class HelpScreen extends ConsumerWidget {
  const HelpScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorials = ref.watch(tutorialCardsProvider);
    
    return ListView.builder(
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        return TutorialCard(tutorial: tutorials[index]);
      },
    );
  }
}

class TutorialDetailScreen extends StatelessWidget {
  final TutorialCardModel tutorial;
  
  const TutorialDetailScreen({
    Key? key,
    required this.tutorial,
  }) : super(key: key);
}
```

**Tutorial Card Model**:
```dart
class TutorialCardModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final IconData icon;
  
  const TutorialCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
  });
}
```

**Initial Tutorial Cards**:
1. "What's this app?" - App overview and purpose
2. "Enjoy using the app" - Tips and encouragement
3. "How to add a habit" - Step-by-step habit creation
4. "How to add a task" - Step-by-step task creation
5. Placeholder card for future content

## Data Models

### User Profile Model

```dart
class UserProfile {
  final int? id;
  final String name;
  final String? email;
  final String? profilePicturePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserProfile({
    this.id,
    required this.name,
    this.email,
    this.profilePicturePath,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap();
  factory UserProfile.fromMap(Map<String, dynamic> map);
}
```

### Tutorial Card Model

```dart
class TutorialCardModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String iconName;
  final int sortOrder;
  
  TutorialCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.iconName,
    required this.sortOrder,
  });
  
  Map<String, dynamic> toMap();
  factory TutorialCardModel.fromMap(Map<String, dynamic> map);
}
```

### Onboarding State Model

```dart
class OnboardingState {
  final bool isCompleted;
  final DateTime? completedAt;
  
  OnboardingState({
    required this.isCompleted,
    this.completedAt,
  });
}
```

## Database Schema

### User Profile Table

```sql
CREATE TABLE user_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT,
  profile_picture_path TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Design Decision**: Single-user table since the app is designed for individual use. Only one profile record will exist.

### Tutorial Cards Table

```sql
CREATE TABLE tutorial_cards (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  content TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Design Decision**: Storing tutorial cards in the database allows for future customization and dynamic content updates.

### Onboarding Preferences

**Storage**: SharedPreferences (for fast access)

```dart
// Keys
static const String onboardingCompletedKey = 'onboarding_completed';
static const String onboardingCompletedAtKey = 'onboarding_completed_at';
```

**Design Decision**: SharedPreferences is used instead of SQLite for onboarding status because:
- It's checked on every app launch (needs to be fast)
- It's a simple boolean flag (doesn't need relational data)
- It's accessed before the database is fully initialized

## Repositories

### User Profile Repository

```dart
class UserProfileRepository {
  final DatabaseService _db;
  
  UserProfileRepository(this._db);
  
  Future<UserProfile?> getProfile();
  Future<void> createProfile(UserProfile profile);
  Future<void> updateProfile(UserProfile profile);
  Future<void> deleteProfile(int id);
}
```

### Tutorial Cards Repository

```dart
class TutorialCardsRepository {
  final DatabaseService _db;
  
  TutorialCardsRepository(this._db);
  
  Future<List<TutorialCardModel>> getAllTutorials();
  Future<TutorialCardModel?> getTutorialById(String id);
  Future<void> initializeDefaultTutorials();
}
```

### Onboarding Repository

```dart
class OnboardingRepository {
  final SharedPreferences _prefs;
  
  OnboardingRepository(this._prefs);
  
  Future<bool> isOnboardingCompleted();
  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
```

## Providers (Riverpod)

### User Profile Provider

```dart
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(ref.read(userProfileRepositoryProvider));
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserProfileRepository _repository;
  
  UserProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }
  
  Future<void> loadProfile();
  Future<void> updateProfile(UserProfile profile);
}
```

### Onboarding State Provider

```dart
final onboardingStateProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(onboardingRepositoryProvider);
  return await repository.isOnboardingCompleted();
});
```

### Tutorial Cards Provider

```dart
final tutorialCardsProvider = FutureProvider<List<TutorialCardModel>>((ref) async {
  final repository = ref.read(tutorialCardsRepositoryProvider);
  return await repository.getAllTutorials();
});
```

## Navigation Flow

### Router Updates

Add new routes to the existing GoRouter configuration:

```dart
// Outside ShellRoute (no drawer)
GoRoute(
  path: '/splash',
  name: 'splash',
  pageBuilder: (context, state) => NoTransitionPage(
    child: SplashScreen(),
  ),
),
GoRoute(
  path: '/onboarding',
  name: 'onboarding',
  pageBuilder: (context, state) => MaterialPage(
    child: OnboardingScreen(),
  ),
),

// Inside ShellRoute (with drawer)
GoRoute(
  path: '/help',
  name: 'help',
  pageBuilder: (context, state) => NoTransitionPage(
    child: HelpScreen(),
  ),
  routes: [
    GoRoute(
      path: ':tutorialId',
      name: 'tutorial-detail',
      pageBuilder: (context, state) {
        final tutorialId = state.pathParameters['tutorialId']!;
        return MaterialPage(
          child: TutorialDetailScreen(tutorialId: tutorialId),
        );
      },
    ),
  ],
),
```

### Initial Route Logic

Update `main.dart` to set splash screen as initial route:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',  // Changed from '/home'
    routes: [...]
  );
});
```

## Error Handling

### Profile Validation Errors

- **Empty Name**: Display "Name is required" error message
- **Invalid Email**: Display "Please enter a valid email address"
- **Database Error**: Display "Failed to save profile. Please try again."

### Onboarding Errors

- **SharedPreferences Failure**: Log error and proceed to home (fail gracefully)
- **Navigation Error**: Retry navigation or show error dialog

### Help System Errors

- **Failed to Load Tutorials**: Display empty state with retry button
- **Database Error**: Show error message and fallback to hardcoded tutorials

## Testing Strategy

### Unit Tests

1. **UserProfile Model**
   - Test toMap() and fromMap() conversions
   - Test validation logic

2. **Repositories**
   - Test CRUD operations with mock database
   - Test error handling

3. **Providers**
   - Test state transitions
   - Test async data loading

### Widget Tests

1. **Splash Screen**
   - Test emoji animation sequence
   - Test navigation after animation completes

2. **Onboarding Flow**
   - Test page navigation
   - Test skip functionality
   - Test completion and navigation to home

3. **Profile Screen**
   - Test edit mode toggle
   - Test form validation
   - Test save functionality

4. **Help Screen**
   - Test tutorial card list rendering
   - Test navigation to detail screen

### Integration Tests

1. **First Launch Flow**
   - Test splash → onboarding → home navigation
   - Test onboarding completion persistence

2. **Profile Update Flow**
   - Test profile edit and save
   - Test side panel name update

3. **Help System Flow**
   - Test tutorial card selection
   - Test navigation back to list

## Accessibility Considerations

- All interactive elements have semantic labels
- Form fields have proper labels and error messages
- Tutorial cards have sufficient contrast ratios
- Navigation supports keyboard and screen readers
- Focus management during onboarding flow

## Performance Considerations

- Splash screen animation uses AnimatedSwitcher for GPU-accelerated transitions
- Profile data is cached in memory after first load
- Tutorial cards are loaded once and cached
- SharedPreferences is used for fast onboarding status checks
- Database queries use indexes for optimal performance

## Future Enhancements

1. **Profile Picture Upload**: Add camera/gallery integration
2. **Tutorial Videos**: Embed video content in tutorial cards
3. **Interactive Tutorials**: Add step-by-step guided tours
4. **Customizable Onboarding**: Allow users to select which tutorials to view
5. **Multi-language Support**: Localize tutorial content
6. **Tutorial Search**: Add search functionality to help screen
7. **Tutorial Completion Tracking**: Track which tutorials users have viewed

## Migration Strategy

### Database Migration

Add migration in DatabaseService to create new tables:

```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 5) {
    await _createProfileTables(db);
    await _createTutorialTables(db);
  }
}
```

### Existing User Handling

- Existing users will see the splash screen on next launch
- Onboarding will be marked as completed for existing users (check if any habits/tasks exist)
- Profile screen will prompt users to create their profile on first visit

## Dependencies

### New Dependencies Required

```yaml
dependencies:
  shared_preferences: ^2.2.2  # For onboarding state
```

### Existing Dependencies Used

- flutter_riverpod: State management
- go_router: Navigation
- sqflite: Database
- path: File path utilities

## Implementation Notes

1. **Initialization Order**: Splash screen must check onboarding status before navigating
2. **Side Panel Update**: Use Consumer widget to listen to profile changes
3. **Tutorial Content**: Initialize default tutorials on first database creation
4. **Profile Singleton**: Ensure only one profile exists (enforce in repository)
5. **Navigation Guards**: Prevent back navigation from onboarding to splash screen
