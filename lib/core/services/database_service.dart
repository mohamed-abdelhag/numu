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
      version: 3,
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
  }

  // Create all tables here
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Future tables (ready when you need them)
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
