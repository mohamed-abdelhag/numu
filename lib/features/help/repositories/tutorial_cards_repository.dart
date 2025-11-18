import 'package:numu/core/services/database_service.dart';
import 'package:numu/features/help/models/tutorial_card_model.dart';

class TutorialCardsRepository {
  final DatabaseService _db;

  TutorialCardsRepository(this._db);

  /// Fetch all tutorial cards ordered by sort_order
  Future<List<TutorialCardModel>> getAllTutorials() async {
    final database = await _db.database;
    final results = await database.query(
      DatabaseService.tutorialCardsTable,
      orderBy: 'sort_order ASC',
    );

    return results.map((map) => TutorialCardModel.fromMap(map)).toList();
  }

  /// Fetch a specific tutorial card by id
  Future<TutorialCardModel?> getTutorialById(String id) async {
    final database = await _db.database;
    final results = await database.query(
      DatabaseService.tutorialCardsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return TutorialCardModel.fromMap(results.first);
  }

  /// Initialize default tutorial cards
  /// This should be called on first app launch or when the table is empty
  Future<void> initializeDefaultTutorials() async {
    final database = await _db.database;

    // Check if tutorials already exist
    final existing = await getAllTutorials();
    if (existing.isNotEmpty) {
      return; // Already initialized
    }

    final now = DateTime.now();
    final defaultTutorials = [
      TutorialCardModel(
        id: 'whats-this-app',
        title: "What's this app?",
        description: 'Learn about the purpose and features of this app',
        content: '''
# Welcome to Numu! 🌱

Numu is your personal growth companion designed to help you build better habits and achieve your goals.

## Key Features:

- **Habit Tracking**: Create and track habits with flexible scheduling
- **Task Management**: Organize your daily tasks and to-dos
- **Progress Visualization**: See your growth over time with streaks and statistics
- **Customization**: Personalize your experience with themes and settings

Start your journey to a better you today!
''',
        iconName: 'info',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      TutorialCardModel(
        id: 'enjoy-using-app',
        title: 'Enjoy using the app',
        description: 'Tips and encouragement for getting the most out of Numu',
        content: '''
# Make the Most of Numu 🌿

Here are some tips to help you succeed:

## Getting Started:

1. **Start Small**: Begin with just 1-2 habits to build momentum
2. **Be Consistent**: Regular small actions lead to big results
3. **Track Daily**: Check in every day to maintain your streaks
4. **Celebrate Wins**: Acknowledge your progress, no matter how small

## Pro Tips:

- Set realistic goals that fit your lifestyle
- Use the quality layer to track how well you performed
- Review your progress weekly to stay motivated
- Don't be too hard on yourself - progress isn't always linear

Remember: Building habits is a journey, not a destination. Enjoy the process!
''',
        iconName: 'favorite',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      TutorialCardModel(
        id: 'how-to-add-habit',
        title: 'How to add a habit',
        description: 'Step-by-step guide to creating your first habit',
        content: '''
# Creating Your First Habit 🌳

Follow these steps to add a new habit:

## Step 1: Navigate to Habits
Tap on the "Habits" tab in the bottom navigation bar.

## Step 2: Add New Habit
Tap the "+" button to create a new habit.

## Step 3: Configure Your Habit

1. **Name**: Give your habit a clear, actionable name
2. **Icon & Color**: Choose an icon and color to make it recognizable
3. **Tracking Type**: Select how you want to track (checkbox, counter, timer)
4. **Frequency**: Choose how often you want to do this habit
5. **Goal**: Set your target (e.g., "3 times per week")

## Step 4: Advanced Options (Optional)

- **Active Days**: Specify which days this habit applies
- **Time Window**: Set a specific time range for the habit
- **Quality Layer**: Track not just completion, but how well you did

## Step 5: Save
Tap "Save" and start tracking your new habit!

Pro tip: Start with simple habits and add complexity as you get comfortable.
''',
        iconName: 'add_circle',
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
      TutorialCardModel(
        id: 'how-to-add-task',
        title: 'How to add a task',
        description: 'Step-by-step guide to creating tasks',
        content: '''
# Creating Tasks 🍎

Tasks help you manage your daily to-dos alongside your habits.

## Step 1: Navigate to Tasks
Tap on the "Tasks" tab in the bottom navigation bar.

## Step 2: Add New Task
Tap the "+" button or the input field at the top.

## Step 3: Enter Task Details
Type in what you need to do. Be specific and actionable!

## Step 4: Save
Press enter or tap the save button to add your task.

## Managing Tasks:

- **Complete**: Tap the checkbox when you finish a task
- **Edit**: Tap on the task text to modify it
- **Delete**: Swipe left on a task to remove it

## Tips for Effective Task Management:

1. Break large tasks into smaller, actionable steps
2. Prioritize your most important tasks
3. Review and update your task list daily
4. Don't overload - focus on what's achievable today

Remember: Tasks are for one-time actions, habits are for recurring behaviors!
''',
        iconName: 'check_circle',
        sortOrder: 4,
        createdAt: now,
        updatedAt: now,
      ),
      TutorialCardModel(
        id: 'getting-help',
        title: 'Getting Help',
        description: 'How to find support and additional resources',
        content: '''
# Need Help? We're Here! 💚

## Finding Answers:

You can always return to this Help section by tapping the Help icon in the side menu.

## Common Questions:

**Q: How do I edit a habit?**
A: Tap on the habit in your list, then tap the edit icon.

**Q: What's the difference between habits and tasks?**
A: Habits are recurring behaviors you want to build. Tasks are one-time actions you need to complete.

**Q: How are streaks calculated?**
A: Streaks count consecutive days you've completed your habit based on its frequency settings.

**Q: Can I customize the app's appearance?**
A: Yes! Go to Settings to change themes and customize your experience.

## Tips for Success:

- Explore all the features at your own pace
- Don't hesitate to experiment with different settings
- Remember that consistency matters more than perfection

Happy tracking! 🌟
''',
        iconName: 'help',
        sortOrder: 5,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // Insert all default tutorials
    for (final tutorial in defaultTutorials) {
      await database.insert(
        DatabaseService.tutorialCardsTable,
        tutorial.toMap(),
      );
    }
  }

  /// Create a new tutorial card
  Future<void> createTutorial(TutorialCardModel tutorial) async {
    final database = await _db.database;
    await database.insert(
      DatabaseService.tutorialCardsTable,
      tutorial.toMap(),
    );
  }

  /// Update an existing tutorial card
  Future<void> updateTutorial(TutorialCardModel tutorial) async {
    final database = await _db.database;
    await database.update(
      DatabaseService.tutorialCardsTable,
      tutorial.toMap(),
      where: 'id = ?',
      whereArgs: [tutorial.id],
    );
  }

  /// Delete a tutorial card
  Future<void> deleteTutorial(String id) async {
    final database = await _db.database;
    await database.delete(
      DatabaseService.tutorialCardsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
