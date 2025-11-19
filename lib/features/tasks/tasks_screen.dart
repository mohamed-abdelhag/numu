import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import 'package:numu/features/tasks/tasks_provider.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/widgets/task_list_item.dart';
import 'package:numu/features/habits/providers/categories_provider.dart';
import 'package:numu/features/habits/models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sort options enum
enum TaskSortOption {
  dueDate,
  createdDate,
  alphabetical,
}

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int? _selectedCategoryId;
  TaskSortOption _sortOption = TaskSortOption.createdDate;

  @override
  void initState() {
    super.initState();
    CoreLoggingUtility.info('tasks screen', 'TasksScreen instance created', 'Constructor called');
    _loadSortPreference();
  }

  /// Load saved sort preference from SharedPreferences
  Future<void> _loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSort = prefs.getString('task_sort_option');
      if (savedSort != null && mounted) {
        setState(() {
          _sortOption = TaskSortOption.values.firstWhere(
            (e) => e.name == savedSort,
            orElse: () => TaskSortOption.createdDate,
          );
        });
        CoreLoggingUtility.info(
          'TasksScreen',
          '_loadSortPreference',
          'Loaded sort preference: $savedSort',
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'TasksScreen',
        '_loadSortPreference',
        'Failed to load sort preference: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// Save sort preference to SharedPreferences
  Future<void> _saveSortPreference(TaskSortOption option) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('task_sort_option', option.name);
      CoreLoggingUtility.info(
        'TasksScreen',
        '_saveSortPreference',
        'Saved sort preference: ${option.name}',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'TasksScreen',
        '_saveSortPreference',
        'Failed to save sort preference: $e\nStack trace: $stackTrace',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      CoreLoggingUtility.info('TasksScreen', 'build', 'Building tasks screen');
      
      final tasksAsync = ref.watch(tasksProvider);
      final categoriesAsync = ref.watch(categoriesProvider);
      
      return Column(
        children: [
          NumuAppBar(
            title: 'Tasks',
            actions: [
                // Sort menu
                Semantics(
                  label: 'Sort tasks',
                  button: true,
                  child: PopupMenuButton<TaskSortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort tasks',
                    onSelected: (option) {
                      setState(() {
                        _sortOption = option;
                      });
                      _saveSortPreference(option);
                      CoreLoggingUtility.info(
                        'TasksScreen',
                        'build',
                        'Sort option changed to: ${option.name}',
                      );
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: TaskSortOption.dueDate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              color: _sortOption == TaskSortOption.dueDate
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontWeight: _sortOption == TaskSortOption.dueDate
                                    ? FontWeight.bold
                                    : null,
                                color: _sortOption == TaskSortOption.dueDate
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskSortOption.createdDate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: _sortOption == TaskSortOption.createdDate
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Created Date',
                              style: TextStyle(
                                fontWeight: _sortOption == TaskSortOption.createdDate
                                    ? FontWeight.bold
                                    : null,
                                color: _sortOption == TaskSortOption.createdDate
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskSortOption.alphabetical,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort_by_alpha,
                              color: _sortOption == TaskSortOption.alphabetical
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Alphabetical',
                              style: TextStyle(
                                fontWeight: _sortOption == TaskSortOption.alphabetical
                                    ? FontWeight.bold
                                    : null,
                                color: _sortOption == TaskSortOption.alphabetical
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Category filter
                categoriesAsync.when(
                  data: (categories) => _buildCategoryFilter(categories),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),

            // Tasks list
            Expanded(
              child: Stack(
                children: [
                  tasksAsync.when(
                    data: (tasks) {
                      CoreLoggingUtility.info('tasks screen', 'Tasks data loaded', 'Loaded ${tasks.length} tasks');
                      
                      final filteredTasks = _filterTasks(tasks);
                      final sortedTasks = _sortTasks(filteredTasks);
                      
                      if (tasks.isEmpty) {
                        CoreLoggingUtility.info('tasks screen', 'No tasks to display', 'Empty state shown');
                        return _buildEmptyState();
                      }

                      if (filteredTasks.isEmpty && _selectedCategoryId != null) {
                        return _buildEmptyFilterState();
                      }

                      return Column(
                        children: [
                          if (_selectedCategoryId != null) _buildFilterIndicator(filteredTasks.length),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                try {
                                  final task = sortedTasks[index];
                                  final category = task.categoryId != null
                                      ? categoriesAsync.value?.firstWhere(
                                          (cat) => cat.id == task.categoryId,
                                          orElse: () => Category(
                                            name: 'Unknown',
                                            color: '#808080',
                                            createdAt: DateTime.now(),
                                          ),
                                        )
                                      : null;
                                  
                                  return TaskListItem(
                                    task: task,
                                    category: category,
                                    onTap: () {
                                      CoreLoggingUtility.info(
                                        'TasksScreen',
                                        'build',
                                        'Task tapped: ${task.id}',
                                      );
                                      context.push('/tasks/${task.id}');
                                    },
                                    onToggleComplete: (_) {
                                      try {
                                        CoreLoggingUtility.info(
                                          'tasks screen',
                                          'Task toggle initiated',
                                          'Task ID: ${task.id}',
                                        );
                                        ref.read(tasksProvider.notifier).toggleTask(task);
                                        CoreLoggingUtility.info(
                                          'tasks screen',
                                          'Task toggled successfully',
                                          'Task ID: ${task.id}',
                                        );
                                      } catch (e, stackTrace) {
                                        CoreLoggingUtility.error(
                                          'tasks screen',
                                          'Failed to toggle Task ID: ${task.id}, Error: $e',
                                          stackTrace.toString(),
                                        );
                                      }
                                    },
                                  );
                                } catch (e, stackTrace) {
                                  CoreLoggingUtility.error(
                                    'tasks screen',
                                    'Error building list item Index: $index, Error: $e',
                                    stackTrace.toString(),
                                  );
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
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Semantics(
                      label: 'Add new task',
                      button: true,
                      child: FloatingActionButton(
                        onPressed: () {
                          CoreLoggingUtility.info(
                            'TasksScreen',
                            'build',
                            'Add task button pressed',
                          );
                          context.push('/tasks/add');
                        },
                        tooltip: 'Add Task',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                ],
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

  /// Sort tasks based on selected sort option
  List<Task> _sortTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    
    switch (_sortOption) {
      case TaskSortOption.dueDate:
        sortedTasks.sort((a, b) {
          // Tasks without due dates go to the end
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOption.createdDate:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSortOption.alphabetical:
        sortedTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    
    return sortedTasks;
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
        
        return Semantics(
          label: 'Filtered by ${selectedCategory.name}. Showing $count ${count == 1 ? 'task' : 'tasks'}',
          child: Container(
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
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Helper method to safely create Color from string
  Color _getCategoryColor(String colorString) {
    try {
      // Handle both formats: "0xFFRRGGBB" and "#RRGGBB"
      if (colorString.startsWith('#')) {
        colorString = '0xFF${colorString.substring(1)}';
      } else if (!colorString.startsWith('0x')) {
        colorString = '0xFF$colorString';
      }
      return Color(int.parse(colorString.replaceFirst('0x', ''), radix: 16));
    } catch (e) {
      // Fallback to grey if parsing fails
      return const Color(0xFF808080);
    }
  }

  /// Build empty state when no tasks exist
  Widget _buildEmptyState() {
    return Semantics(
      label: 'No tasks yet. Tap the add button to create your first task',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create your first task',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state when filter returns no results
  Widget _buildEmptyFilterState() {
    return Semantics(
      label: 'No tasks in this category. Try selecting a different category or clear the filter',
      child: Center(
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
      ),
    );
  }


}