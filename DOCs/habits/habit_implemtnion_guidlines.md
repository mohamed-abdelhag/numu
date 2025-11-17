# Habit Tracking App - Database Architecture Guide

---

## 📋 Overview

This document defines the complete database structure and calculation logic for a habit tracking application. The system supports simple yes/no habits as well as complex value tracking with time windows, quality layers, and flexible scheduling.

**Design Principles:**

- Single user system (no multi-user support needed)
- Raw event data stored permanently
- Expensive calculations cached in separate tables
- Support for both simple and advanced habit configurations
- Pre-made habit templates for quick onboarding

---

## 🗄️ Database Tables

### Table 1: HABITS

Main table storing all habit definitions and configurations.

**Fields:**

**Identity & Basic Info:**

- `habit_id` - Primary key, unique identifier
- `name` - Habit name (e.g., "Morning Exercise")
- `description` - Optional detailed description
- `category_id` - Foreign key to CATEGORIES table
- `icon` - Emoji or icon identifier
- `color` - Hex color code for UI display

**Tracking Configuration:**

- `tracking_type` - ENUM: 'binary', 'value', 'timed'
    - binary: Simple yes/no checkbox
    - value: Track numerical values (glasses of water, minutes exercised)
    - timed: Track with timestamp (when you did it)
- `goal_type` - ENUM: 'none', 'minimum', 'maximum'
    - none: Just track it, no target
    - minimum: Must reach at least X (exercise 30 minutes)
    - maximum: Must stay under X (smoke less than 5 cigarettes)
- `target_value` - Number, the goal value (nullable if goal_type is 'none')
- `unit` - String, unit label (e.g., "glasses", "minutes", "km", "times")

**Frequency Configuration:**

- `frequency` - ENUM: 'daily', 'weekly', 'monthly', 'custom'
    - daily: Check completion each day
    - weekly: Aggregate across the week
    - monthly: Aggregate across the month
    - custom: User-defined period length
- `custom_period_days` - Number of days in custom period (nullable, only for custom frequency)
- `period_start_date` - Date when custom period cycle begins (nullable, only for custom frequency)

**Active Days Configuration:**

- `active_days_mode` - ENUM: 'all', 'selected'
    - all: Habit applies every day
    - selected: Only applies on specific weekdays
- `active_weekdays` - JSON array of weekday numbers [1,2,3,4,5,6,7] where 1=Monday, 7=Sunday
- `require_mode` - ENUM: 'each', 'any', 'total'
    - each: Must hit target on EACH active day individually
    - any: Must hit target ONCE across ANY of the active days
    - total: Cumulative total across all active days must hit target

**Time Window Configuration (Optional Layer):**

- `time_window_enabled` - Boolean, whether time tracking is active
- `time_window_start` - Time, start of preferred time window (e.g., 05:00)
- `time_window_end` - Time, end of preferred time window (e.g., 09:00)
- `time_window_mode` - ENUM: 'soft', 'hard'
    - soft: Preference window, completion still counts if outside
    - hard: Required window, completion doesn't count if outside

**Quality Layer Configuration (Optional):**

- `quality_layer_enabled` - Boolean, whether quality tracking is active
- `quality_layer_label` - String, custom label (e.g., "Stretched", "Took Notes", "Cold Shower")

**Metadata:**

- `is_active` - Boolean, whether habit is currently active
- `is_template` - Boolean, whether this is a pre-made template habit
- `sort_order` - Integer, for custom ordering in UI
- `created_at` - Timestamp, when habit was created
- `updated_at` - Timestamp, last modification time
- `archived_at` - Timestamp, when habit was archived (nullable)

---

### Table 2: HABIT_EVENTS

Records every completion or tracking entry for habits.

**Fields:**

**Identity:**

- `event_id` - Primary key, unique identifier
- `habit_id` - Foreign key to HABITS table

**Event Timing:**

- `event_date` - Date, which day this event counts toward (supports backfilling)
- `event_timestamp` - Timestamp, when user actually recorded this event

**Tracking Data:**

- `completed` - Boolean, for binary habits (true/false)
- `value` - Decimal, for measurable habits (actual amount recorded)
- `value_delta` - Decimal, the incremental change this event represents (+2, -1, etc.)

**Optional Layer Data:**

- `time_recorded` - Time, specific time of day when habit was done (for timed habits)
- `within_time_window` - Boolean, calculated field indicating if time_recorded falls within habit's time window
- `quality_achieved` - Boolean, whether quality layer was met (stretched, meditated, etc.)

**Metadata:**

- `notes` - Text, optional user notes about this event
- `created_at` - Timestamp, when event record was created
- `updated_at` - Timestamp, last modification time

**Key Design Notes:**

- `event_date` vs `event_timestamp`: event_date determines which day it counts for (can be in the past), event_timestamp tracks when user logged it
- `value_delta`: Stores the change, allows for audit trail and undo functionality
- Each tap/increment creates a new event row

---

### Table 3: CATEGORIES

Organizational groups for habits.

**Fields:**

- `category_id` - Primary key, unique identifier
- `name` - Category name (e.g., "Health & Fitness", "Productivity")
- `description` - Optional detailed description
- `icon` - Icon identifier for UI
- `color` - Hex color code
- `is_system` - Boolean, true for built-in categories, false for user-created
- `sort_order` - Integer, display order
- `created_at` - Timestamp, creation time

**System Category Examples:**

- Health & Fitness
- Productivity
- Learning & Growth
- Social & Relationships
- Mindfulness & Mental Health
- Finance & Money
- Creativity & Hobbies
- Bad Habits to Break
- Morning Routine
- Evening Routine

---

### Table 4: HABIT_STREAKS

Cached streak calculations for performance.

**Fields:**

**Identity:**

- `streak_id` - Primary key, unique identifier
- `habit_id` - Foreign key to HABITS table
- `streak_type` - ENUM: 'completion', 'time_window', 'quality', 'perfect'
    - completion: Basic streak, did you complete the habit?
    - time_window: Did you complete within preferred time window?
    - quality: Did you complete with quality layer achieved?
    - perfect: All layers achieved (completion + time + quality)

**Current Streak Data:**

- `current_streak` - Integer, consecutive successful periods
- `current_streak_start_date` - Date, when current streak began

**Historical Best Streak:**

- `longest_streak` - Integer, best streak ever achieved
- `longest_streak_start_date` - Date, when longest streak started
- `longest_streak_end_date` - Date, when longest streak ended

**Summary Statistics:**

- `total_completions` - Integer, total number of successful completions
- `total_days_active` - Integer, days since habit was created (excluding archived periods)
- `consistency_rate` - Decimal, percentage (total_completions / total_days_active × 100)

**Metadata:**

- `last_calculated_at` - Timestamp, when streak was last computed
- `last_event_date` - Date, last day included in streak calculation

**Why This Table Exists:**

- Streak calculations are expensive (scanning all events backwards)
- Cache results here instead of calculating on every query
- Recalculate only when new events are added or habits modified

---

### Table 5: HABIT_PERIOD_PROGRESS

Tracks progress within weekly, monthly, or custom periods.

**Fields:**

**Identity:**

- `progress_id` - Primary key, unique identifier
- `habit_id` - Foreign key to HABITS table

**Period Definition:**

- `period_type` - ENUM: 'daily', 'weekly', 'monthly', 'custom'
- `period_start_date` - Date, first day of this period
- `period_end_date` - Date, last day of this period

**Progress Tracking:**

- `target_value` - Decimal, what needs to be achieved this period
- `current_value` - Decimal, what has been achieved so far
- `completed` - Boolean, whether target was met
- `completion_date` - Timestamp, when target was first reached (nullable)

**Optional Layer Progress:**

- `time_window_completions` - Integer, how many completions were within time window
- `quality_completions` - Integer, how many completions had quality achieved

**Metadata:**

- `created_at` - Timestamp, when period started
- `updated_at` - Timestamp, last update to progress

**Why This Table Exists:**

- For weekly/monthly habits, need to track "this week's total"
- Enables queries like "Show all weekly habits and their current progress"
- Can display: "You're at 6/10 km this week" without summing events each time

---

### Table 6: HABIT_TEMPLATES

Pre-made habits users can instantly add.

**Fields:**

**Identity & Display:**

- `template_id` - Primary key, unique identifier
- `name` - Template name
- `description` - What this habit is for, why it's useful
- `category_id` - Foreign key to CATEGORIES table
- `icon` - Icon identifier
- `color` - Hex color code

**Configuration (Same as HABITS table):**

- `tracking_type` - binary/value/timed
- `goal_type` - none/minimum/maximum
- `target_value` - Recommended target
- `unit` - Unit label
- `frequency` - daily/weekly/monthly/custom
- `custom_period_days` - If custom frequency
- `active_days_mode` - all/selected
- `active_weekdays` - Recommended active days
- `require_mode` - each/any/total
- `time_window_enabled` - Whether to include time tracking
- `time_window_start` - Recommended start time
- `time_window_end` - Recommended end time
- `time_window_mode` - soft/hard
- `quality_layer_enabled` - Whether to include quality layer
- `quality_layer_label` - Quality label text

**Template Metadata:**

- `popularity_score` - Integer, number of times this template was used
- `tags` - JSON array of tags ["beginner", "advanced", "morning", "health"]
- `tutorial_steps` - JSON array of tutorial text/images
- `is_featured` - Boolean, show on featured templates list
- `created_at` - Timestamp, when template was added

**Template Examples:**

**Simple Templates:**

- "Drink Water" - Daily, minimum 8 glasses
- "Exercise" - Daily, binary yes/no
- "Meditate" - Daily, binary, 5-9am time window

**Intermediate Templates:**

- "Run Weekly" - Weekly, minimum 10km total
- "Read Daily" - Daily, minimum 30 minutes, with quality layer "Took notes"
- "Sleep 8 Hours" - Daily, minimum 8 hours

**Advanced Templates:**

- "Quit Smoking" - Daily, maximum 0 cigarettes (tracking towards zero)
- "Study Schedule" - Custom period, Monday/Wednesday/Friday, each day 2 hours minimum
- "Morning Routine" - Daily, timed 6-8am, with quality layer "Full routine completed"

---

### Table 7: USER_HABIT_SETTINGS

User-specific customizations and preferences.

**Fields:**

**Identity:**

- `setting_id` - Primary key, unique identifier
- `habit_id` - Foreign key to HABITS table

**User Customizations:**

- `custom_target` - Decimal, override template's target value (nullable)
- `custom_unit` - String, override unit label (nullable)
- `reminder_enabled` - Boolean, whether reminders are on
- `reminder_times` - JSON array of time values for daily reminders
- `notes` - Text, user's personal notes about this habit

**UI Preferences:**

- `widget_last_config` - JSON, remembers last widget state (what time was selected, etc.)
- `show_in_dashboard` - Boolean, whether to display on main dashboard
- `pinned` - Boolean, pin to top of habit list

**Metadata:**

- `created_at` - Timestamp, when settings were created
- `updated_at` - Timestamp, last modification

**Why This Table Exists:**

- Separates user preferences from core habit definition
- Same template can have different settings for different instances
- Preserves widget state between uses

---

## 🧮 Calculation Logic

### 1. Daily Habit Completion Check

**Purpose:** Determine if a habit was completed on a specific day.

**Process:**

1. **Retrieve Habit Configuration**
    
    - Get habit record from HABITS table
    - Extract: target_value, goal_type, tracking_type
2. **Gather Events for Target Day**
    
    - Query HABIT_EVENTS where habit_id matches and event_date equals target day
    - For value tracking: sum all value_delta fields
3. **Evaluate Completion Based on Goal Type**
    
    - If goal_type = 'minimum': Is sum >= target_value?
    - If goal_type = 'maximum': Is sum <= target_value?
    - If goal_type = 'none': Does any event exist?
    - If tracking_type = 'binary': Is completed = true for any event?
4. **Check Optional Layers (if enabled)**
    
    - Time Window Layer:
        - Is time_window_enabled = true?
        - Does any event have within_time_window = true?
    - Quality Layer:
        - Is quality_layer_enabled = true?
        - Does any event have quality_achieved = true?
5. **Return Results**
    
    - Completion status: true/false
    - Time window status: true/false/null
    - Quality status: true/false/null

**Example Scenarios:**

**Binary Habit - "Exercise Today"**

- Target: Just complete it once
- Check: Any event with completed = true?
- Result: Yes → Habit completed

**Value Habit - "Drink 8 Glasses Water"**

- Target: minimum 8 glasses
- Events: +2, +3, +2, +1 = 8 total
- Check: 8 >= 8?
- Result: Yes → Habit completed

**Timed Habit - "Meditate Before 9am"**

- Target: Complete within 5am-9am window
- Event: Completed at 7:30am
- Check: 7:30 between 5:00 and 9:00?
- Result: Yes → Both completion and time window met

---

### 2. Weekly/Monthly/Custom Period Progress

**Purpose:** Calculate cumulative progress for habits that aggregate over longer periods.

**Process:**

1. **Determine Period Boundaries**
    
    - Weekly: Calculate Monday-Sunday of target week
    - Monthly: Calculate first day to last day of target month
    - Custom: Use period_start_date + custom_period_days to find current cycle
2. **Identify Active Days Within Period**
    
    - If active_days_mode = 'all': All days count
    - If active_days_mode = 'selected': Only days in active_weekdays count
    - Build list of relevant dates in period
3. **Calculate Adjusted Target**
    
    - If require_mode = 'each':
        - Target = target_value × number_of_active_days
        - Example: 30 minutes daily, 5 active days = 150 minutes total target
    - If require_mode = 'any':
        - Target = target_value (single completion needed)
    - If require_mode = 'total':
        - Target = target_value (cumulative target)
4. **Sum Events Across Period**
    
    - Query HABIT_EVENTS for all dates within period boundaries
    - Filter to only active days if active_days_mode = 'selected'
    - Sum all value_delta fields
5. **Evaluate Completion**
    
    - If goal_type = 'minimum': current_sum >= adjusted_target?
    - If goal_type = 'maximum': current_sum <= adjusted_target?
6. **Update or Insert HABIT_PERIOD_PROGRESS**
    
    - Store: period boundaries, target, current value, completion status
    - Mark completion_date if target was just reached

**Example Scenarios:**

**Weekly Habit - "Run 10km Per Week" (Total Mode)**

- Frequency: weekly
- Target: 10km minimum
- Require mode: total
- Events this week: Monday 3km, Wednesday 4km, Saturday 5km = 12km
- Adjusted target: 10km (not multiplied, just cumulative)
- Check: 12 >= 10?
- Result: Week completed

**Weekly Habit - "Exercise Monday/Wednesday/Friday" (Each Mode)**

- Frequency: weekly
- Target: 30 minutes minimum per day
- Active days: Monday, Wednesday, Friday
- Require mode: each
- Events: Monday 40min, Wednesday 25min, Friday 35min
- Check each day: Mon ✓, Wed ✗ (under 30), Fri ✓
- Result: Week NOT completed (didn't hit each day)

**Weekly Habit - "Study Any 3 Days" (Any Mode)**

- Frequency: weekly
- Target: 1 completion
- Active days: Monday-Friday
- Require mode: any
- Events: Studied on Tuesday
- Check: Any day completed? Yes
- Result: Week completed

---

### 3. Streak Calculation

**Purpose:** Calculate consecutive successful completions.

**Process:**

1. **Initialize Streak Counter**
    
    - Start at 0
    - Set current_date to today
2. **Walk Backwards Through Days**
    
    - For each day going backwards from today:
3. **Check if Day is Relevant**
    
    - If active_days_mode = 'selected':
        - Is current_date's weekday in active_weekdays?
        - If no: Skip this day, continue to previous
    - If frequency is weekly/monthly/custom:
        - Check completion at period level instead of day level
        - Use HABIT_PERIOD_PROGRESS table to see if period was completed
4. **Evaluate Day/Period Success**
    
    - For daily habits:
        - Run daily completion check for current_date
        - Did habit meet target? (Use logic from section 1)
    - For weekly/monthly/custom:
        - Look up period in HABIT_PERIOD_PROGRESS
        - Was period completed = true?
5. **Update Streak Counter**
    
    - If success: Increment counter, continue to previous day/period
    - If failure: STOP, current streak ends here
6. **Record Current Streak**
    
    - Current streak length = final counter value
    - Streak start date = date where we stopped
7. **Calculate Historical Best**
    
    - Scan all historical data to find longest streak ever achieved
    - This can be done incrementally: only recalculate if current > longest
8. **Calculate Multiple Streak Types**
    
    - **Completion Streak:** Basic completion (did you do it?)
    - **Time Window Streak:** Only count days where within_time_window = true
    - **Quality Streak:** Only count days where quality_achieved = true
    - **Perfect Streak:** Only count days where ALL layers met
9. **Update HABIT_STREAKS Table**
    
    - Store results for each streak_type
    - Update last_calculated_at timestamp

**Example Scenarios:**

**Simple Daily Streak**

- Habit: Exercise daily
- Check backwards: Today ✓, Yesterday ✓, 2 days ago ✓, 3 days ago ✗
- Current streak: 3 days

**Weekly Habit Streak**

- Habit: Run 10km per week
- Check backwards: This week ✓, Last week ✓, 2 weeks ago ✗
- Current streak: 2 weeks

**Skip Inactive Days**

- Habit: Study on weekdays only
- Active days: Monday-Friday
- Check backwards: Friday ✓, Thursday ✓, Wednesday ✓ (skip weekend), previous Friday ✗
- Current streak: 3 days (weekend doesn't break streak)

**Time Window Streak**

- Habit: Meditate before 9am
- Completion streak: 10 days (did it every day)
- Time window streak: 7 days (only 7 were before 9am)
- Two separate streak counters maintained

---

### 4. Consistency Score Calculation

**Purpose:** Measure long-term adherence as a percentage.

**Formula:**

```
consistency_rate = (total_completions / total_days_active) × 100
```

**Process:**

1. **Calculate Total Days Active**
    
    - If habit is daily:
        - Days from created_at to today
        - Minus any days where habit was archived
    - If active_days_mode = 'selected':
        - Only count days that fall on active_weekdays
        - Example: 30 calendar days, only Monday/Wednesday/Friday = ~12 active days
2. **Calculate Total Completions**
    
    - Count number of days/periods where goal was met
    - For daily: Count successful days
    - For weekly: Count successful weeks
    - For monthly: Count successful months
3. **Compute Percentage**
    
    - Divide completions by active days
    - Multiply by 100 for percentage
4. **Store in HABIT_STREAKS Table**
    
    - Update consistency_rate field
    - Recalculate whenever new events are added

**Example Scenarios:**

**Daily Habit - 30 Days Old**

- Habit created 30 days ago
- Completed 24 out of 30 days
- Consistency: (24 / 30) × 100 = 80%

**Weekday Only Habit - 30 Days Old**

- Habit applies Monday-Friday only
- 30 calendar days contains ~21 weekdays
- Completed 18 out of 21 weekdays
- Consistency: (18 / 21) × 100 = 85.7%

**Weekly Habit - 12 Weeks Old**

- Habit created 12 weeks ago
- Completed 10 out of 12 weeks
- Consistency: (10 / 12) × 100 = 83.3%

---

### 5. Require Mode Logic Details

**Purpose:** Handle different ways of requiring completion across multiple days.

#### "Each" Mode

**Definition:** Must hit target on EACH active day individually.

**Calculation:**

- Check each active day separately
- ALL must meet target for period to be complete
- If any single day fails, entire period fails

**Example:**

- Habit: Exercise 30 minutes
- Frequency: Weekly
- Active days: Monday, Wednesday, Friday
- Require mode: each
- Target: 30 minutes (per day)

**Week Results:**

- Monday: 35 minutes ✓
- Wednesday: 25 minutes ✗ (under 30)
- Friday: 40 minutes ✓

**Outcome:** Week NOT completed (Wednesday failed)

---

#### "Any" Mode

**Definition:** Must hit target ONCE across ANY of the active days.

**Calculation:**

- Check if target was met on at least one active day
- Only one successful day needed
- Period completes as soon as any active day succeeds

**Example:**

- Habit: Go to gym
- Frequency: Weekly
- Active days: Monday, Wednesday, Friday, Saturday, Sunday
- Require mode: any
- Target: 1 completion

**Week Results:**

- Monday: No
- Wednesday: Yes ✓
- Friday: No
- Saturday: No
- Sunday: No

**Outcome:** Week completed (hit Wednesday)

---

#### "Total" Mode

**Definition:** Cumulative total across all active days must hit target.

**Calculation:**

- Sum values from all active days in period
- Check if sum meets target
- Individual day performance doesn't matter, only total

**Example:**

- Habit: Study
- Frequency: Weekly
- Active days: All days (7 days)
- Require mode: total
- Target: 10 hours

**Week Results:**

- Monday: 2 hours
- Tuesday: 0 hours
- Wednesday: 3 hours
- Thursday: 1 hour
- Friday: 0 hours
- Saturday: 4 hours
- Sunday: 1 hour
- **Total: 11 hours**

**Outcome:** Week completed (11 >= 10)

---

**Key Differences:**

|Mode|Target Multiplier|Calculation Method|Fails If|
|---|---|---|---|
|each|target × active_days|Check each day individually|Any day fails|
|any|target (no multiplier)|Check if any day succeeds|All days fail|
|total|target (no multiplier)|Sum across all days|Sum under target|

---

## 🔄 When to Recalculate

### Trigger Events for Recalculation

**Event Added or Modified:**

1. Recalculate daily progress for that habit and date
2. Update HABIT_PERIOD_PROGRESS if habit is weekly/monthly/custom
3. Recalculate all streak types (completion, time, quality, perfect)
4. Update consistency_rate in HABIT_STREAKS
5. Update longest_streak if current > longest

**Event Deleted:**

1. Same as above (need to recalculate everything affected)

**Habit Configuration Changed:**

1. If target_value changed: Recalculate all historical progress
2. If frequency changed: Rebuild all HABIT_PERIOD_PROGRESS rows
3. If active_weekdays changed: Recalculate streaks (some days now excluded)
4. If time_window changed: Recalculate time_window streaks
5. Mark all cached calculations as stale

**Period Boundary Crossed:**

1. At midnight (daily): Check all daily habits for today
2. At week start (Monday): Finalize last week's progress, create new period rows
3. At month start (1st): Finalize last month, create new period rows
4. Custom period rollover: Calculate based on period_start_date + custom_period_days

**User Requests Stats:**

1. Check last_calculated_at timestamps
2. If data is stale (> 1 hour old), recalculate
3. Otherwise serve from cache

---

## 📊 Database Indexes

**Purpose:** Optimize query performance for common operations.

**Required Indexes:**

```
HABIT_EVENTS table:
- Index on (habit_id, event_date) - Fast lookup of events for a habit on specific dates
- Index on (event_date) - Fast queries for "today's events"
- Index on (habit_id, event_timestamp) - Time-ordered event retrieval

HABITS table:
- Index on (is_active) - Filter active habits quickly
- Index on (category_id) - Group by category
- Index on (is_template) - Separate templates from user habits

HABIT_PERIOD_PROGRESS table:
- Index on (habit_id, period_start_date) - Find current period for a habit
- Index on (period_start_date, period_end_date) - Date range queries

HABIT_STREAKS table:
- Index on (habit_id, streak_type) - Lookup specific streak for a habit
```

---

## 💾 Data Management Best Practices

### Event Storage

**Keep Forever:**

- Never delete events unless user explicitly requests
- Users want to see historical data and trends
- Events are relatively small (few KB each)

**Archiving:**

- Instead of deleting habits, set archived_at timestamp
- Archived habits don't count toward streak calculations
- Can be restored by clearing archived_at

### Calculated Data

**Cache Strategy:**

- Store expensive calculations in separate tables
- Include last_calculated_at timestamp on all cached data
- Recalculate only when source data changes or cache is stale

**Invalidation Rules:**

- When event added/modified: Invalidate habit's cached data
- When habit modified: Invalidate all related cached data
- Stale threshold: 1 hour for non-critical, immediate for user-visible

### Performance Considerations

**Query Optimization:**

- Always use indexed columns in WHERE clauses
- Limit result sets (don't fetch all events at once)
- Use date ranges to narrow queries

**Batch Operations:**

- When user adds multiple events (backfilling), batch insert
- Recalculate once after all events inserted, not per event
- Use database transactions for consistency

---

## 🎯 Summary

### Core Tables

- **HABITS:** Definitions and configurations
- **HABIT_EVENTS:** Raw completion data

### Calculated Tables

- **HABIT_STREAKS:** Cached streak calculations
- **HABIT_PERIOD_PROGRESS:** Weekly/monthly progress tracking

### Reference Tables

- **CATEGORIES:** Organizational groups
- **HABIT_TEMPLATES:** Pre-made habits
- **USER_HABIT_SETTINGS:** Customizations

### Key Features Supported

**Tracking Types:**

- ✅ Binary (yes/no)
- ✅ Value tracking (measurable numbers)
- ✅ Timed (timestamp awareness)

**Goal Types:**

- ✅ No target (just track)
- ✅ Minimum target (reach at least X)
- ✅ Maximum limit (stay under X)

**Frequencies:**

- ✅ Daily
- ✅ Weekly
- ✅ Monthly
- ✅ Custom periods

**Advanced Features:**

- ✅ Time windows (preferred completion times)
- ✅ Quality layer (extra achievement tracking)
- ✅ Multiple streak types
- ✅ Flexible scheduling (each/any/total modes)
- ✅ Active day selection
- ✅ Backfilling past days
- ✅ Pre-made templates

---

**End of Document**