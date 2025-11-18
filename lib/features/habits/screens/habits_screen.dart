import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import '../providers/habits_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/empty_habits_state.dart';
import '../widgets/habit_list_item.dart';
import '../models/exceptions/habit_exception.dart';
import '../models/category.dart';
import '../models/habit.dart';

/// Main screen displaying the list of active habits
/// Handles loading, error, and empty states
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('HabitsScreen', 'build', 'Building habits screen');
    final habitsAsync = ref.watch(habitsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        NumuAppBar(
          title: 'Habits',
          actions: [
            categoriesAsync.when(
              data: (categories) => _buildCategoryFilter(categories),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              habitsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _buildErrorState(context, error),
                data: (habits) {
                  final filteredHabits = _filterHabits(habits);
                  
                  if (habits.isEmpty) {
                    return const EmptyHabitsState();
                  }

                  if (filteredHabits.isEmpty && _selectedCategoryId != null) {
                    return _buildEmptyFilterState();
                  }

                  return Column(
                    children: [
                      if (_selectedCategoryId != null) _buildFilterIndicator(filteredHabits.length),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHabits.length,
                          itemBuilder: (context, index) {
                            return HabitListItem(habit: filteredHabits[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Semantics(
                  label: 'Add new habit',
                  button: true,
                  child: FloatingActionButton(
                    onPressed: () => context.push('/habits/add'),
                    tooltip: 'Add new habit',
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Filter habits based on selected category
  List<Habit> _filterHabits(List<Habit> habits) {
    if (_selectedCategoryId == null) {
      return habits;
    }
    return habits.where((habit) => habit.categoryId == _selectedCategoryId).toList();
  }

  /// Build category filter dropdown
  Widget _buildCategoryFilter(List<Category> categories) {
    return Semantics(
      label: _selectedCategoryId != null 
        ? 'Category filter active. Tap to change filter.' 
        : 'Filter habits by category',
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
          'HabitsScreen',
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
                    Icon(
                      IconData(
                        int.parse(category.icon!),
                        fontFamily: 'MaterialIcons',
                      ),
                      color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)),
                    )
                  else
                    Icon(
                      Icons.category,
                      color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16)),
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
      ),
    );
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
                Icon(
                  IconData(
                    int.parse(selectedCategory.icon!),
                    fontFamily: 'MaterialIcons',
                  ),
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  'Filtered by ${selectedCategory.name} ($count ${count == 1 ? 'habit' : 'habits'})',
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
                      'HabitsScreen',
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
              'No habits in this category',
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

  /// Build error state with specific error messages and retry button
  Widget _buildErrorState(BuildContext context, Object error) {
    String title = 'Failed to load habits';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = Icons.error_outline;

    // Customize message based on error type
    if (error is HabitValidationException) {
      title = 'Validation Error';
      message = error.message;
      icon = Icons.warning_amber_outlined;
    } else if (error is HabitDatabaseException) {
      title = 'Database Error';
      message = 'There was a problem accessing the database. Please try again.';
      icon = Icons.storage_outlined;
    } else if (error is HabitNotFoundException) {
      title = 'Habit Not Found';
      message = error.message;
      icon = Icons.search_off_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(habitsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
