import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/tasks_repository.dart';
import 'package:numu/features/reminders/models/reminder.dart';
import 'package:numu/features/reminders/models/reminder_type.dart';
import 'package:numu/features/reminders/models/reminder_schedule.dart';
import 'package:numu/features/reminders/models/reminder_link.dart';
import 'package:numu/features/reminders/repositories/reminder_repository.dart';
import 'package:numu/features/reminders/services/reminder_scheduler_service.dart';

part 'tasks_provider.g.dart';

@riverpod
class TasksNotifier extends _$TasksNotifier {
  final _repository = TasksRepository();
  final _reminderRepository = ReminderRepository();
  final _schedulerService = ReminderSchedulerService();

  @override
  Future<List<Task>> build() async {
    return await _repository.getTasks();
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int? categoryId,
    bool reminderEnabled = false,
    int reminderMinutesBefore = 60,
  }) async {
    if (title.trim().isEmpty) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final newTask = Task(
        title: title,
        description: description,
        dueDate: dueDate,
        categoryId: categoryId,
      );
      final createdTask = await _repository.createTask(newTask);
      
      // Create reminder if enabled and task has due date
      if (reminderEnabled && createdTask.id != null && dueDate != null) {
        await _createTaskReminder(
          createdTask.id!,
          title,
          dueDate,
          reminderMinutesBefore,
        );
      }
      
      return await _repository.getTasks();
    });
  }

  Future<void> updateTask(
    Task task, {
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final oldTask = await _repository.getTaskById(task.id!);
      await _repository.updateTask(task);
      
      // Handle reminder updates if reminder parameters are provided
      if (reminderEnabled != null && task.id != null) {
        final existingReminders = await _reminderRepository.getRemindersByTaskId(task.id!);
        
        if (reminderEnabled && task.dueDate != null) {
          // Create or update reminder
          if (existingReminders.isEmpty) {
            await _createTaskReminder(
              task.id!,
              task.title,
              task.dueDate!,
              reminderMinutesBefore ?? 60,
            );
          } else {
            // Update existing reminder
            final existingReminder = existingReminders.first;
            final updatedReminder = existingReminder.copyWith(
              title: task.title,
              isActive: true,
              schedule: existingReminder.schedule.copyWith(
                minutesBefore: reminderMinutesBefore ?? existingReminder.schedule.minutesBefore,
              ),
              updatedAt: DateTime.now(),
            );
            await _reminderRepository.updateReminder(updatedReminder);
            await _schedulerService.rescheduleReminder(updatedReminder);
          }
        } else if (!reminderEnabled && existingReminders.isNotEmpty) {
          // Disable reminder
          for (final reminder in existingReminders) {
            final updatedReminder = reminder.copyWith(
              isActive: false,
              updatedAt: DateTime.now(),
            );
            await _reminderRepository.updateReminder(updatedReminder);
          }
        }
      }
      
      // If due date changed, trigger reminder update
      if (oldTask != null && oldTask.dueDate != task.dueDate && task.id != null) {
        await _schedulerService.handleTaskUpdate(task.id!);
      }
      
      return await _repository.getTasks();
    });
  }

  Future<void> toggleTask(Task task) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await _repository.updateTask(updated);
      
      // Handle reminders when task completion status changes
      if (task.id != null) {
        await _schedulerService.handleTaskUpdate(task.id!);
      }
      
      return await _repository.getTasks();
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Delete associated reminders first
      await _reminderRepository.deleteRemindersByTaskId(id);
      
      // Then delete the task
      await _repository.deleteTask(id);
      return await _repository.getTasks();
    });
  }

  /// Helper method to create a task reminder
  Future<void> _createTaskReminder(
    int taskId,
    String taskTitle,
    DateTime dueDate,
    int minutesBefore,
  ) async {
    final reminder = Reminder(
      title: taskTitle,
      description: 'Task reminder',
      type: ReminderType.notification,
      schedule: ReminderSchedule(
        frequency: ScheduleFrequency.none,
        minutesBefore: minutesBefore,
      ),
      link: ReminderLink(
        type: LinkType.task,
        entityId: taskId,
        entityName: taskTitle,
        useDefaultText: true,
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final reminderId = await _reminderRepository.createReminder(reminder);
    final reminderWithId = reminder.copyWith(id: reminderId);
    await _schedulerService.scheduleReminder(reminderWithId);
  }
}

// Provider for fetching a single task by ID
@riverpod
Future<Task?> taskDetail(Ref ref, int taskId) async {
  final repository = TasksRepository();
  return await repository.getTaskById(taskId);
}