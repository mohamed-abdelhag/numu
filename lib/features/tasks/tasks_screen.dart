import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import 'package:numu/features/tasks/tasks_provider.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/habits/providers/categories_provider.dart';
import 'package:numu/features/habits/models/category.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _textController = TextEditingController();
  int? _selectedCategoryId;
  int? _addTaskCategoryId;
  Task? _editingTask;

  @override
  void initState() {
    super.initState();
    CoreLoggingUtility.info('tasks screen', 'TasksScreen instance created', 'Constructor called');
  }

  @override
  Widget build(BuildContext context) {
    try {
      CoreLoggingUtility.info('TasksScreen', 'build', 'Building tasks screen');
      CoreLoggingUtility.info('tasks screen', 'Building tasks screen widget', 'build method started');
      
      final tasksAsync = ref.watch(tasksProvider);
      final categoriesAsync = ref.watch(categoriesProvider);
      
      return Column(
        children: [
          NumuAppBar(
            title: 'Tasks',
            actions: [
              categoriesAsync.when(
                data: (categories) => _buildCategoryFilter(categories),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          // Add/Edit task section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _editingTask != null ? 'Edit task...' : 'Enter a task...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_editingTask != null) ...[
                      ElevatedButton(
                        onPressed: () {
                          try {
                            CoreLoggingUtility.info('tasks screen', 'Update task button pressed', 'User attempting to update task');
                            
                            final text = _textController.text;
                            if (text.isNotEmpty && _editingTask != null) {
                              final updatedTask = _editingTask!.copyWith(
                                text: text,
                                categoryId: _addTaskCategoryId,
                              );
                              ref.read(tasksProvider.notifier).updateTask(updatedTask);
                              _textController.clear();
                              setState(() {
                                _editingTask = null;
                                _addTaskCategoryId = null;
                              });
                              
                              CoreLoggingUtility.info('tasks screen', 'Task updated successfully', 'Task: $text');
                            } else {
                              CoreLoggingUtility.warning('tasks screen', 'Empty task text', 'User tried to update with empty task');
                            }
                          } catch (e, stackTrace) {
                            CoreLoggingUtility.error('tasks screen', 'Error: $e', stackTrace.toString());
                          }
                        },
                        child: const Text('Update'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingTask = null;
                            _addTaskCategoryId = null;
                            _textController.clear();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ] else
                      ElevatedButton(
                        onPressed: () {
                          try {
                            CoreLoggingUtility.info('tasks screen', 'Add task button pressed', 'User attempting to add task');
                            
                            final text = _textController.text;
                            if (text.isNotEmpty) {
                              ref.read(tasksProvider.notifier).addTask(text, _addTaskCategoryId);
                              _textController.clear();
                              setState(() {
                                _addTaskCategoryId = null;
                              });
                              
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
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) => _buildCategorySelector(categories),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
                
                final filteredTasks = _filterTasks(tasks);
                
                if (tasks.isEmpty) {
                  CoreLoggingUtility.info('tasks screen', 'No tasks to display', 'Empty state shown');
                  return const Center(
                    child: Text('No tasks yet. Add one above!'),
                  );
                }

                if (filteredTasks.isEmpty && _selectedCategoryId != null) {
                  return _buildEmptyFilterState();
                }

                return Column(
                  children: [
                    if (_selectedCategoryId != null) _buildFilterIndicator(filteredTasks.length),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          try {
                            final task = filteredTasks[index];
                            return _buildTaskListItem(task, categoriesAsync.value ?? []);
                          } catch (e, stackTrace) {
                            CoreLoggingUtility.error('tasks screen', 'Error building list item Index: $index, Error: $e', stackTrace.toString());
                            return const ListTile(
                              title: Text('Error loading task'),
                            );
                          }
                        },
                      ),
                    ),
                  ],
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

  /// Filter tasks based on selected category
  List<Task> _filterTasks(List<Task> tasks) {
    if (_selectedCategoryId == null) {
      return tasks;
    }
    return tasks.where((task) => task.categoryId == _selectedCategoryId).toList();
  }

  /// Build category filter dropdown
  Widget _buildCategoryFilter(List<Category> categories) {
    return Semantics(
      label: _selectedCategoryId != null 
        ? 'Category filter active. Tap to change filter.' 
        : 'Filter tasks by category',
      button: true,
      child: PopupMenuButton<int?>(
        icon: Icon(
          _selectedCategoryId != null ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: _selectedCategoryId != null ? Theme.of(context).colorScheme.primary : null,
        ),
        tooltip: 'Filter by category',
        onSelected: (categoryId) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
        CoreLoggingUtility.info(
          'TasksScreen',
          '_buildCategoryFilter',
          'Category filter changed to: ${categoryId ?? "All"}',
        );
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<int?>(
            value: null,
            child: Row(
              children: [
                Icon(
                  Icons.clear_all,
                  color: _selectedCategoryId == null 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'All',
                  style: TextStyle(
                    fontWeight: _selectedCategoryId == null ? FontWeight.bold : null,
                    color: _selectedCategoryId == null 
                      ? Theme.of(context).colorScheme.primary 
                      : null,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...categories.map((category) {
            final isSelected = _selectedCategoryId == category.id;
            return PopupMenuItem<int?>(
              value: category.id,
              child: Row(
                children: [
                  if (category.icon != null)
                    Text(
                      category.icon!,
                      style: const TextStyle(fontSize: 20),
                    )
                  else
                    Icon(
                      Icons.category,
                      color: _getCategoryColor(category.color),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    ));
  }

  /// Build filter indicator showing active filter and count
  Widget _buildFilterIndicator(int count) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        final selectedCategory = categories.firstWhere(
          (cat) => cat.id == _selectedCategoryId,
          orElse: () => Category(
            name: 'Unknown',
            color: '#808080',
            createdAt: DateTime.now(),
          ),
        );
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              if (selectedCategory.icon != null)
                Text(
                  selectedCategory.icon!,
                  style: const TextStyle(fontSize: 16),
                )
              else
                Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filtered by ${selectedCategory.name} ($count ${count == 1 ? 'task' : 'tasks'})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Semantics(
                label: 'Clear category filter',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    CoreLoggingUtility.info(
                      'TasksScreen',
                      '_buildFilterIndicator',
                      'Filter cleared',
                    );
                  },
                  tooltip: 'Clear filter',
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build empty state when filter returns no results
  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks in this category',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category or clear the filter',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Clear category filter',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category selector dropdown for add/edit task
  Widget _buildCategorySelector(List<Category> categories) {
    return Semantics(
      label: 'Select category for task, optional',
      child: DropdownButtonFormField<int?>(
        decoration: const InputDecoration(
          labelText: 'Category (optional)',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: _addTaskCategoryId,
        items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('None'),
        ),
        ...categories.map((category) {
          return DropdownMenuItem<int?>(
            value: category.id,
            child: Row(
              children: [
                if (category.icon != null) ...[
                  Text(category.icon!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(category.name),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _addTaskCategoryId = value;
        });
        CoreLoggingUtility.info(
          'TasksScreen',
          '_buildCategorySelector',
          'Category selection changed to: ${value ?? "None"}',
        );
      },
      ),
    );
  }

  /// Build task list item with category badge and edit functionality
  Widget _buildTaskListItem(Task task, List<Category> categories) {
    final category = task.categoryId != null
        ? categories.firstWhere(
            (cat) => cat.id == task.categoryId,
            orElse: () => Category(
              name: 'Unknown',
              color: '#808080',
              createdAt: DateTime.now(),
            ),
          )
        : null;

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.text,
            style: TextStyle(
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (category.icon != null) ...[
                  Text(
                    category.icon!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Edit task: ${task.text}',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                setState(() {
                  _editingTask = task;
                  _textController.text = task.text;
                  _addTaskCategoryId = task.categoryId;
                });
                CoreLoggingUtility.info('tasks screen', 'Task edit initiated', 'Task ID: ${task.id}');
              },
              tooltip: 'Edit task',
            ),
          ),
          Semantics(
            label: 'Delete task: ${task.text}',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
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
              tooltip: 'Delete task',
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely create Color from string
  Color _getCategoryColor(String colorString) {
    return Color(int.parse(colorString.replaceFirst('0x', ''), radix: 16));
  }
}