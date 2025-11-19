import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Core centralized database service for ALL tables
class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();
  
  DatabaseService._init();

  // Table names
  static const String tasksTable = 'tasks';
  static const String categoriesTable = 'categories';
  static const String habitsTable = 'habits';
  static const String notesTable = 'notes';
  static const String userProfileTable = 'user_profile';
  static const String tutorialCardsTable = 'tutorial_cards';
  static const String remindersTable = 'reminders';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add habits and habit_events tables
      await _createHabitTables(db);
    }
    if (oldVersion < 3) {
      // Add habit_streaks table
      await _createStreakTables(db);
    }
    if (oldVersion < 4) {
      // Add habit_period_progress table
      await _createPeriodProgressTables(db);
    }
    if (oldVersion < 5) {
      // Add user_profile and tutorial_cards tables
      await _createProfileAndTutorialTables(db);
    }
    if (oldVersion < 6) {
      // Add category system enhancements
      await _upgradeCategorySystem(db);
    }
    if (oldVersion < 7) {
      // Enhance tasks table with title, description, due_date, and timestamps
      await _upgradeTasksTable(db);
    }
    if (oldVersion < 8) {
      // Convert timed habits to binary habits with time window enabled
      await _migrateTimedToBinaryHabits(db);
    }
    if (oldVersion < 9) {
      // Add reminders table
      await _createReminderTables(db);
    }
  }

  Future<void> _upgradeCategorySystem(Database db) async {
    // Add is_pinned_to_sidebar column to categories table
    await db.execute('''
      ALTER TABLE $categoriesTable ADD COLUMN is_pinned_to_sidebar INTEGER NOT NULL DEFAULT 0
    ''');

    // Add category_id column to tasks table
    await db.execute('''
      ALTER TABLE $tasksTable ADD COLUMN category_id INTEGER
    ''');

    // Add indexes for category_id columns
    await db.execute('''
      CREATE INDEX idx_habits_category_id ON $habitsTable (category_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_category_id ON $tasksTable (category_id)
    ''');
  }

  Future<void> _upgradeTasksTable(Database db) async {
    // Step 1: Create a new temporary table with the updated schema
    await db.execute('''
      CREATE TABLE tasks_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Step 2: Copy existing data from old table to new table
    // The 'text' column is renamed to 'title'
    await db.execute('''
      INSERT INTO tasks_new (id, title, isCompleted, category_id, created_at, updated_at)
      SELECT id, text, isCompleted, category_id, datetime('now'), datetime('now')
      FROM $tasksTable
    ''');

    // Step 3: Drop the old table
    await db.execute('DROP TABLE $tasksTable');

    // Step 4: Rename the new table to the original name
    await db.execute('ALTER TABLE tasks_new RENAME TO $tasksTable');

    // Step 5: Create index on due_date column for performance
    await db.execute('''
      CREATE INDEX idx_tasks_due_date ON $tasksTable (due_date)
    ''');

    // Step 6: Recreate the category_id index (it was dropped with the old table)
    await db.execute('''
      CREATE INDEX idx_tasks_category_id ON $tasksTable (category_id)
    ''');
  }

  Future<void> _migrateTimedToBinaryHabits(Database db) async {
    // Convert all timed habits to binary habits with time window enabled
    // This migration removes the 'timed' tracking type and converts it to 'binary'
    // with time_window_enabled set to true, preserving all time window configuration
    await db.execute('''
      UPDATE $habitsTable 
      SET tracking_type = 'binary',
          time_window_enabled = 1
      WHERE tracking_type = 'timed'
    ''');
  }

  // Create all tables here
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Future tables (ready when you need them)
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        is_system INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        is_pinned_to_sidebar INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $notesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL
      )
    ''');

    // Create habit tables
    await _createHabitTables(db);
    
    // Create streak tables
    await _createStreakTables(db);
    
    // Create period progress tables
    await _createPeriodProgressTables(db);
    
    // Create profile and tutorial tables
    await _createProfileAndTutorialTables(db);
    
    // Create reminder tables
    await _createReminderTables(db);
    
    // Create indexes for category relationships
    await _createCategoryIndexes(db);
  }

  Future<void> _createCategoryIndexes(Database db) async {
    // Add indexes for category_id columns
    await db.execute('''
      CREATE INDEX idx_habits_category_id ON $habitsTable (category_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_category_id ON $tasksTable (category_id)
    ''');

    // Add index for tasks due_date column
    await db.execute('''
      CREATE INDEX idx_tasks_due_date ON $tasksTable (due_date)
    ''');
  }

  Future<void> _createHabitTables(Database db) async {
    // Create habits table with all configuration fields
    await db.execute('''
      CREATE TABLE $habitsTable (
        habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category_id INTEGER,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        tracking_type TEXT NOT NULL,
        goal_type TEXT NOT NULL,
        target_value REAL,
        unit TEXT,
        frequency TEXT NOT NULL,
        custom_period_days INTEGER,
        period_start_date TEXT,
        active_days_mode TEXT NOT NULL,
        active_weekdays TEXT,
        require_mode TEXT NOT NULL,
        time_window_enabled INTEGER NOT NULL DEFAULT 0,
        time_window_start TEXT,
        time_window_end TEXT,
        time_window_mode TEXT,
        quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
        quality_layer_label TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_template INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT
      )
    ''');

    // Create habit_events table
    await db.execute('''
      CREATE TABLE habit_events (
        event_id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        event_date TEXT NOT NULL,
        event_timestamp TEXT NOT NULL,
        completed INTEGER,
        value REAL,
        value_delta REAL,
        time_recorded TEXT,
        within_time_window INTEGER,
        quality_achieved INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES $habitsTable (habit_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('''
      CREATE INDEX idx_habits_is_active ON $habitsTable (is_active)
    ''');

    await db.execute('''
      CREATE INDEX idx_habit_events_habit_id ON habit_events (habit_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_habit_events_event_date ON habit_events (event_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_habit_events_habit_date ON habit_events (habit_id, event_date)
    ''');
  }

  Future<void> _createStreakTables(Database db) async {
    // Create habit_streaks table
    await db.execute('''
      CREATE TABLE habit_streaks (
        streak_id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        streak_type TEXT NOT NULL,
        current_streak INTEGER NOT NULL DEFAULT 0,
        current_streak_start_date TEXT,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak_start_date TEXT,
        longest_streak_end_date TEXT,
        total_completions INTEGER NOT NULL DEFAULT 0,
        total_days_active INTEGER NOT NULL DEFAULT 0,
        consistency_rate REAL NOT NULL DEFAULT 0,
        last_calculated_at TEXT NOT NULL,
        last_event_date TEXT,
        FOREIGN KEY (habit_id) REFERENCES $habitsTable (habit_id) ON DELETE CASCADE,
        UNIQUE (habit_id, streak_type)
      )
    ''');

    // Create index for fast streak lookups
    await db.execute('''
      CREATE INDEX idx_habit_streaks_habit_type ON habit_streaks (habit_id, streak_type)
    ''');
  }

  Future<void> _createPeriodProgressTables(Database db) async {
    // Create habit_period_progress table
    await db.execute('''
      CREATE TABLE habit_period_progress (
        progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        period_type TEXT NOT NULL,
        period_start_date TEXT NOT NULL,
        period_end_date TEXT NOT NULL,
        target_value REAL NOT NULL,
        current_value REAL NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        completion_date TEXT,
        time_window_completions INTEGER NOT NULL DEFAULT 0,
        quality_completions INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES $habitsTable (habit_id) ON DELETE CASCADE
      )
    ''');

    // Create index for fast period progress lookups
    await db.execute('''
      CREATE INDEX idx_period_progress_habit ON habit_period_progress (habit_id, period_start_date)
    ''');
  }

  Future<void> _createProfileAndTutorialTables(Database db) async {
    // Create user_profile table
    await db.execute('''
      CREATE TABLE $userProfileTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        profile_picture_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create tutorial_cards table
    await db.execute('''
      CREATE TABLE $tutorialCardsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        content TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index for tutorial cards sort order
    await db.execute('''
      CREATE INDEX idx_tutorial_cards_sort_order ON $tutorialCardsTable (sort_order)
    ''');
  }

  Future<void> _createReminderTables(Database db) async {
    // Create reminders table
    await db.execute('''
      CREATE TABLE $remindersTable (
        reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        reminder_type TEXT NOT NULL,
        frequency TEXT NOT NULL,
        specific_date_time TEXT,
        time_of_day TEXT,
        active_weekdays TEXT,
        day_of_month INTEGER,
        minutes_before INTEGER,
        use_habit_time_window INTEGER NOT NULL DEFAULT 0,
        use_habit_active_days INTEGER NOT NULL DEFAULT 0,
        link_type TEXT,
        link_entity_id INTEGER,
        link_entity_name TEXT,
        use_default_text INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        next_trigger_time TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('''
      CREATE INDEX idx_reminders_active ON $remindersTable (is_active)
    ''');

    await db.execute('''
      CREATE INDEX idx_reminders_next_trigger ON $remindersTable (next_trigger_time)
    ''');

    await db.execute('''
      CREATE INDEX idx_reminders_habit_link ON $remindersTable (link_type, link_entity_id)
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
