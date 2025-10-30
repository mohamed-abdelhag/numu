import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/features/tasks/tasks_provider.dart';

class TasksScreen extends ConsumerWidget {
  TasksScreen({super.key}) {
    CoreLoggingUtility.info('tasks screen', 'TasksScreen instance created', 'Constructor called');
  }

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      CoreLoggingUtility.info('tasks screen', 'Building tasks screen widget', 'build method started');
      
      final tasksAsync = ref.watch(tasksProvider);
      
      return Column(
        children: [
          // Add task section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    try {
                      CoreLoggingUtility.info('tasks screen', 'Add task button pressed', 'User attempting to add task');
                      
                      final text = _textController.text;
                      if (text.isNotEmpty) {
                        ref.read(tasksProvider.notifier).addTask(text);
                        _textController.clear();
                        
                        CoreLoggingUtility.info('tasks screen', 'Task added successfully', 'Task: $text');
                      } else {
                        CoreLoggingUtility.warning('tasks screen', 'Empty task text', 'User tried to add empty task');
                      }
                    } catch (e, stackTrace) {
                      CoreLoggingUtility.error('tasks screen', 'Error: $e', stackTrace.toString());
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tasks list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                CoreLoggingUtility.info('tasks screen', 'Tasks data loaded', 'Loaded ${tasks.length} tasks');
                
                if (tasks.isEmpty) {
                  CoreLoggingUtility.info('tasks screen', 'No tasks to display', 'Empty state shown');
                  return const Center(
                    child: Text('No tasks yet. Add one above!'),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    try {
                      final task = tasks[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (_) {
                            try {
                              CoreLoggingUtility.info('tasks screen', 'Task toggle initiated', 'Task ID: ${task.id}');
                              ref.read(tasksProvider.notifier).toggleTask(task);
                              CoreLoggingUtility.info('tasks screen', 'Task toggled successfully', 'Task ID: ${task.id}');
                            } catch (e, stackTrace) {
                              CoreLoggingUtility.error('tasks screen', 'Failed to toggle Task ID: ${task.id}, Error: $e', stackTrace.toString());
                            }
                          },
                        ),
                        title: Text(
                          task.text,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            try {
                              CoreLoggingUtility.info('tasks screen', 'Task deletion initiated', 'Task ID: ${task.id}');
                              
                              if (task.id != null) {
                                ref.read(tasksProvider.notifier).deleteTask(task.id!);
                                CoreLoggingUtility.info('tasks screen', 'Task deleted successfully', 'Task ID: ${task.id}');
                              } else {
                                CoreLoggingUtility.warning('tasks screen', 'Cannot delete task with null ID', 'Task: ${task.text}');
                              }
                            } catch (e, stackTrace) {
                              CoreLoggingUtility.error('tasks screen', 'Failed to delete task Task ID: ${task.id}, Error: $e', stackTrace.toString());
                            }
                          },
                        ),
                      );
                    } catch (e, stackTrace) {
                      CoreLoggingUtility.error('tasks screen', 'Error building list item Index: $index, Error: $e', stackTrace.toString());
                      return const ListTile(
                        title: Text('Error loading task'),
                      );
                    }
                  },
                );
              },
              loading: () {
                CoreLoggingUtility.info('tasks screen', 'Loading tasks', 'Showing loading indicator');
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (error, stack) {
                CoreLoggingUtility.error('tasks screen', 'Error loading tasks Error: $error', stack.toString());
                return Center(
                  child: Text('Error: $error'),
                );
              },
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error('tasks screen', 'Critical error in build method Error: $e', stackTrace.toString());
      return const Center(
        child: Text('Something went wrong. Please try again.'),
      );
    }
  }
}