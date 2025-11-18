# Implementation Plan

- [x] 1. Set up data models and database schema
  - Create UserProfile model with toMap/fromMap methods
  - Create TutorialCardModel with toMap/fromMap methods
  - Create OnboardingState model
  - Add database migration to create user_profile and tutorial_cards tables in DatabaseService
  - _Requirements: 3.5, 5.5, 6.1_

- [x] 2. Implement repositories and data layer
  - [x] 2.1 Create UserProfileRepository with CRUD operations
    - Implement getProfile() to fetch user profile
    - Implement createProfile() to create new profile
    - Implement updateProfile() to save profile changes
    - Ensure only one profile exists (singleton pattern)
    - _Requirements: 3.5, 4.4_
  
  - [x] 2.2 Create OnboardingRepository using SharedPreferences
    - Implement isOnboardingCompleted() to check status
    - Implement markOnboardingCompleted() to save completion
    - Implement resetOnboarding() for testing
    - _Requirements: 2.2, 2.5, 2.7_
  
  - [x] 2.3 Create TutorialCardsRepository
    - Implement getAllTutorials() to fetch all cards
    - Implement getTutorialById() to fetch specific card
    - Implement initializeDefaultTutorials() to seed initial content
    - _Requirements: 5.2, 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 3. Create Riverpod providers for state management
  - Create userProfileProvider (StateNotifierProvider) for profile state
  - Create onboardingStateProvider (FutureProvider) for onboarding status
  - Create tutorialCardsProvider (FutureProvider) for tutorial cards
  - Create repository providers for dependency injection
  - _Requirements: 3.2, 4.2, 4.5_

- [x] 4. Implement Splash Screen with animation
  - Create SplashScreen StatefulWidget
  - Implement emoji animation sequence (🌱 → 🌿 → 🌳 → 🍎) with 500ms intervals
  - Add navigation logic to check onboarding status after 2 seconds
  - Navigate to onboarding if first launch, otherwise to home
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.7_

- [x] 5. Build Onboarding Flow screens
  - [x] 5.1 Create OnboardingScreen with PageView
    - Implement page controller for navigation
    - Add progress indicator showing current page (e.g., "1 of 2")
    - Add Next and Skip buttons
    - Implement Skip functionality to navigate to home
    - _Requirements: 2.3, 2.4, 7.3, 7.4, 7.5_
  
  - [x] 5.2 Create OnboardingCard widget
    - Display tutorial card content (title, description, full content)
    - Reuse TutorialCardModel for content
    - Style consistently with help screen cards
    - _Requirements: 7.1, 7.2_
  
  - [x] 5.3 Implement onboarding completion logic
    - Save completion flag to SharedPreferences when user finishes
    - Navigate to home screen after completion
    - _Requirements: 2.5, 2.6_

- [x] 6. Implement Profile Screen with edit functionality
  - [x] 6.1 Create ProfileScreen StatefulWidget
    - Add view mode displaying name, email, and profile picture placeholder
    - Add Edit button to toggle edit mode
    - Display profile data from userProfileProvider
    - _Requirements: 3.1, 3.2_
  
  - [x] 6.2 Implement edit mode with form validation
    - Create Form with TextFormField for name and email
    - Add validation for required name field
    - Add email format validation
    - Add Save and Cancel buttons in edit mode
    - _Requirements: 3.3, 3.4, 3.6_
  
  - [x] 6.3 Implement save functionality
    - Call userProfileProvider to update profile
    - Handle validation errors with error messages
    - Show success feedback after save
    - Exit edit mode after successful save
    - _Requirements: 3.5, 3.6_

- [ ] 7. Update Side Panel to display user name
  - Modify NumuAppShell drawer header to use Consumer widget
  - Display user name from userProfileProvider
  - Show "Welcome, Guest" as default when no name is set
  - Ensure real-time updates when profile changes
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 8. Build Help Screen with tutorial cards
  - [ ] 8.1 Create HelpScreen with tutorial card list
    - Display list of tutorial cards from tutorialCardsProvider
    - Create TutorialCardWidget for list items
    - Show title and description for each card
    - Make cards tappable to navigate to detail view
    - _Requirements: 5.1, 5.2, 5.4, 6.1_
  
  - [ ] 8.2 Create TutorialDetailScreen
    - Display full tutorial content
    - Add back button to return to list
    - Style content for readability
    - _Requirements: 5.3, 6.6_
  
  - [ ] 8.3 Initialize default tutorial content
    - Create 5 default tutorial cards with placeholder content
    - "What's this app?" card
    - "Enjoy using the app" card
    - "How to add a habit" card
    - "How to add a task" card
    - One additional placeholder card
    - _Requirements: 5.2, 6.2, 6.3, 6.4, 6.5_

- [ ] 9. Update navigation and routing
  - [ ] 9.1 Add new routes to GoRouter
    - Add /splash route (outside ShellRoute)
    - Add /onboarding route (outside ShellRoute)
    - Add /help route (inside ShellRoute)
    - Add /help/:tutorialId route for detail view
    - _Requirements: 1.5, 2.1, 2.6, 2.7, 5.3_
  
  - [ ] 9.2 Update initial route to splash screen
    - Change initialLocation in routerProvider to '/splash'
    - Ensure splash screen is first screen on app launch
    - _Requirements: 1.1, 2.1_
  
  - [ ] 9.3 Add Help navigation to side panel
    - Add Help list item to drawer in NumuAppShell
    - Add appropriate icon (Icons.help_outline)
    - Navigate to /help on tap
    - _Requirements: 5.1_



- [ ] 10. Implement error handling and loading states
  - Add error handling for database operations in repositories
  - Add loading indicators in profile screen while saving
  - Add error messages for validation failures
  - Add retry functionality for failed tutorial card loading
  - Handle SharedPreferences failures gracefully
  - _Requirements: 3.6_
