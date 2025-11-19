import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/reminder_scheduler_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../models/reminder_type.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'reminder_provider.g.dart';

/// Provider for managing the list of reminders
/// Handles CRUD operations and scheduling with automatic state refresh
@riverpod
class ReminderNotifier extends _$ReminderNotifier {
  late final ReminderRepository _repository;
  late final ReminderSchedulerService _schedulerService;
  late final NotificationService _notificationService;
  late final AlarmService _alarmService;

  @override
  Future<List<Reminder>> build() async {
    _repository = ReminderRepository();
    _notificationService = NotificationService();
    _alarmService = AlarmService();
    _schedulerService = ReminderSchedulerService(
      reminderRepository: _repository,
      notificationService: _notificationService,
      alarmService: _alarmService,
    );

    try {
      return await _repository.getAllReminders();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ReminderProvider',
        'build',
        'Failed to load reminders: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Create a new reminder and schedule it
  Future<void> createReminder(Reminder reminder) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        // Create reminder in repository
        final id = await _repository.createReminder(reminder);
        
        CoreLoggingUtility.info(
          'ReminderProvider',
          'createReminder',
          'Successfully created reminder: ${reminder.title} (ID: $id)',
        );

        // Schedule the reminder
        final reminderWithId = reminder.copyWith(id: id);
        await _schedulerService.scheduleReminder(reminderWithId);

        CoreLoggingUtility.info(
          'ReminderProvider',
          'createReminder',
          'Successfully scheduled reminder: ${reminder.title} (ID: $id)',
        );

        // Refresh the list
        return await _repository.getAllReminders();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ReminderProvider',
          'createReminder',
          'Failed to create reminder "${reminder.title}": $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Update an existing reminder and reschedule it
  Future<void> updateReminder(Reminder reminder) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        // Update reminder in repository
        await _repository.updateReminder(reminder);

        CoreLoggingUtility.info(
          'ReminderProvider',
          'updateReminder',
          'Successfully updated reminder: ${reminder.title} (ID: ${reminder.id})',
        );

        // Reschedule the reminder
        await _schedulerService.rescheduleReminder(reminder);

        CoreLoggingUtility.info(
          'ReminderProvider',
          'updateReminder',
          'Successfully rescheduled reminder: ${reminder.title} (ID: ${reminder.id})',
        );

        // Refresh the list
        return await _repository.getAllReminders();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ReminderProvider',
          'updateReminder',
          'Failed to update reminder "${reminder.title}" (ID: ${reminder.id}): $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Delete a reminder and cancel scheduled notifications
  Future<void> deleteReminder(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        // Get the reminder to determine its type
        final reminder = await _repository.getReminderById(id);
        
        if (reminder != null) {
          // Cancel scheduled notifications/alarms
          if (reminder.type == ReminderType.notification) {
            await _notificationService.cancelNotification(id);
          } else {
            await _alarmService.cancelAlarm(id);
          }

          CoreLoggingUtility.info(
            'ReminderProvider',
            'deleteReminder',
            'Successfully cancelled scheduled reminder with ID: $id',
          );
        }

        // Delete from repository
        await _repository.deleteReminder(id);

        CoreLoggingUtility.info(
          'ReminderProvider',
          'deleteReminder',
          'Successfully deleted reminder with ID: $id',
        );

        // Refresh the list
        return await _repository.getAllReminders();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ReminderProvider',
          'deleteReminder',
          'Failed to delete reminder with ID $id: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Toggle reminder active/inactive state
  Future<void> toggleReminderActive(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        // Get the current reminder
        final reminder = await _repository.getReminderById(id);
        
        if (reminder == null) {
          throw Exception('Reminder with ID $id not found');
        }

        // Toggle active state
        final updatedReminder = reminder.copyWith(
          isActive: !reminder.isActive,
          updatedAt: DateTime.now(),
        );

        // Update in repository
        await _repository.updateReminder(updatedReminder);

        CoreLoggingUtility.info(
          'ReminderProvider',
          'toggleReminderActive',
          'Successfully toggled reminder active state: ${reminder.title} (ID: $id) - Active: ${updatedReminder.isActive}',
        );

        // If activating, schedule the reminder; if deactivating, cancel it
        if (updatedReminder.isActive) {
          await _schedulerService.scheduleReminder(updatedReminder);
        } else {
          if (reminder.type == ReminderType.notification) {
            await _notificationService.cancelNotification(id);
          } else {
            await _alarmService.cancelAlarm(id);
          }
        }

        // Refresh the list
        return await _repository.getAllReminders();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ReminderProvider',
          'toggleReminderActive',
          'Failed to toggle reminder active state for ID $id: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Refresh the reminder list from database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        CoreLoggingUtility.info(
          'ReminderProvider',
          'refresh',
          'Refreshing reminder list',
        );
        return await _repository.getAllReminders();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ReminderProvider',
          'refresh',
          'Failed to refresh reminders: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }
}

/// Provider for filtering only active reminders
@riverpod
Future<List<Reminder>> activeReminders(Ref ref) async {
  final repository = ReminderRepository();
  
  try {
    return await repository.getActiveReminders();
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'ReminderProvider',
      'activeReminders',
      'Failed to load active reminders: $e\n$stackTrace',
    );
    rethrow;
  }
}

/// Provider for fetching reminders linked to a specific habit
@riverpod
Future<List<Reminder>> habitReminders(Ref ref, int habitId) async {
  final repository = ReminderRepository();
  
  try {
    return await repository.getRemindersByHabitId(habitId);
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'ReminderProvider',
      'habitReminders',
      'Failed to load reminders for habit ID $habitId: $e\n$stackTrace',
    );
    rethrow;
  }
}

/// Provider for fetching reminders linked to a specific task
@riverpod
Future<List<Reminder>> taskReminders(Ref ref, int taskId) async {
  final repository = ReminderRepository();
  
  try {
    return await repository.getRemindersByTaskId(taskId);
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'ReminderProvider',
      'taskReminders',
      'Failed to load reminders for task ID $taskId: $e\n$stackTrace',
    );
    rethrow;
  }
}
