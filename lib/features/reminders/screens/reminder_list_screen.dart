import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../models/reminder_type.dart';
import '../models/reminder_link.dart';

/// Filter options for reminders
enum ReminderFilter {
  all,
  active,
  inactive;
}

/// Main screen displaying the list of reminders
/// Handles loading, error, and empty states with filtering options
class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  ReminderFilter _filter = ReminderFilter.all;

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('ReminderListScreen', 'build', 'Building reminder list screen');
    final remindersAsync = ref.watch(reminderProvider);

    return Column(
      children: [
        NumuAppBar(
          title: 'Reminders',
          actions: [
            _buildFilterMenu(),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              remindersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _buildErrorState(context, error),
                data: (reminders) {
                  final filteredReminders = _filterReminders(reminders);
                  
                  if (reminders.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filteredReminders.isEmpty && _filter != ReminderFilter.all) {
                    return _buildEmptyFilterState();
                  }

                  return Column(
                    children: [
                      if (_filter != ReminderFilter.all) 
                        _buildFilterIndicator(filteredReminders.length),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReminders.length,
                          itemBuilder: (context, index) {
                            return _buildReminderListItem(
                              context,
                              filteredReminders[index],
                            );
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
                  label: 'Add new reminder',
                  button: true,
                  child: FloatingActionButton(
                    onPressed: () => context.push('/reminders/create'),
                    tooltip: 'Add new reminder',
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

  /// Filter reminders based on selected filter
  List<Reminder> _filterReminders(List<Reminder> reminders) {
    switch (_filter) {
      case ReminderFilter.all:
        return reminders;
      case ReminderFilter.active:
        return reminders.where((r) => r.isActive).toList();
      case ReminderFilter.inactive:
        return reminders.where((r) => !r.isActive).toList();
    }
  }

  /// Build filter menu
  Widget _buildFilterMenu() {
    return Semantics(
      label: _filter != ReminderFilter.all 
        ? 'Filter active. Tap to change filter.' 
        : 'Filter reminders',
      button: true,
      child: PopupMenuButton<ReminderFilter>(
        icon: Icon(
          _filter != ReminderFilter.all ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: _filter != ReminderFilter.all ? Theme.of(context).colorScheme.primary : null,
        ),
        tooltip: 'Filter reminders',
        onSelected: (filter) {
          setState(() {
            _filter = filter;
          });
          CoreLoggingUtility.info(
            'ReminderListScreen',
            '_buildFilterMenu',
            'Filter changed to: ${filter.name}',
          );
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: ReminderFilter.all,
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: _filter == ReminderFilter.all
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'All',
                  style: TextStyle(
                    fontWeight: _filter == ReminderFilter.all ? FontWeight.bold : null,
                    color: _filter == ReminderFilter.all
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ReminderFilter.active,
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: _filter == ReminderFilter.active
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Active',
                  style: TextStyle(
                    fontWeight: _filter == ReminderFilter.active ? FontWeight.bold : null,
                    color: _filter == ReminderFilter.active
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ReminderFilter.inactive,
            child: Row(
              children: [
                Icon(
                  Icons.notifications_off,
                  color: _filter == ReminderFilter.inactive
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Inactive',
                  style: TextStyle(
                    fontWeight: _filter == ReminderFilter.inactive ? FontWeight.bold : null,
                    color: _filter == ReminderFilter.inactive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter indicator showing active filter and count
  Widget _buildFilterIndicator(int count) {
    String filterText = '';
    IconData filterIcon = Icons.filter_alt;
    
    switch (_filter) {
      case ReminderFilter.active:
        filterText = 'Active';
        filterIcon = Icons.notifications_active;
        break;
      case ReminderFilter.inactive:
        filterText = 'Inactive';
        filterIcon = Icons.notifications_off;
        break;
      case ReminderFilter.all:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            filterIcon,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$filterText reminders ($count)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Semantics(
            label: 'Clear filter',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                setState(() {
                  _filter = ReminderFilter.all;
                });
                CoreLoggingUtility.info(
                  'ReminderListScreen',
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
  }

  /// Build individual reminder list item with swipe actions
  Widget _buildReminderListItem(BuildContext context, Reminder reminder) {
    return Dismissible(
      key: Key('reminder_${reminder.id}'),
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        icon: Icons.edit,
        color: Colors.blue,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        icon: Icons.delete,
        color: Colors.red,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          context.push('/reminders/edit/${reminder.id}');
          return false;
        } else {
          // Delete action - show confirmation
          return await _showDeleteConfirmation(context, reminder);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: _buildReminderIcon(reminder),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isActive ? null : TextDecoration.lineThrough,
              color: reminder.isActive 
                ? null 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminder.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  reminder.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  if (reminder.link != null) ...[
                    _buildLinkBadge(reminder.link!),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _formatNextTriggerTime(reminder.nextTriggerTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Switch(
            value: reminder.isActive,
            onChanged: (value) {
              CoreLoggingUtility.info(
                'ReminderListScreen',
                '_buildReminderListItem',
                'Toggling reminder ${reminder.id} to ${value ? "active" : "inactive"}',
              );
              ref.read(reminderProvider.notifier).toggleReminderActive(reminder.id!);
            },
          ),
          onTap: () {
            CoreLoggingUtility.info(
              'ReminderListScreen',
              '_buildReminderListItem',
              'Reminder tapped: ${reminder.id}',
            );
            context.push('/reminders/edit/${reminder.id}');
          },
        ),
      ),
    );
  }

  /// Build swipe action background
  Widget _buildSwipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }

  /// Build icon indicating reminder type
  Widget _buildReminderIcon(Reminder reminder) {
    IconData icon;
    Color? color;

    if (reminder.type == ReminderType.notification) {
      icon = Icons.notifications;
      color = Theme.of(context).colorScheme.primary;
    } else {
      icon = Icons.alarm;
      color = Theme.of(context).colorScheme.error;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }

  /// Build badge for linked entity
  Widget _buildLinkBadge(ReminderLink link) {
    IconData icon;
    String label;

    if (link.type == LinkType.habit) {
      icon = Icons.track_changes;
      label = link.entityName;
    } else {
      icon = Icons.task_alt;
      label = link.entityName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Format next trigger time in human-readable format
  String _formatNextTriggerTime(DateTime? nextTriggerTime) {
    if (nextTriggerTime == null) {
      return 'Not scheduled';
    }

    final now = DateTime.now();
    final difference = nextTriggerTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    }

    if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    }

    if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    }

    // Format as date without intl package
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[nextTriggerTime.month - 1];
    final day = nextTriggerTime.day;
    final year = nextTriggerTime.year;
    final hour = nextTriggerTime.hour > 12 ? nextTriggerTime.hour - 12 : (nextTriggerTime.hour == 0 ? 12 : nextTriggerTime.hour);
    final minute = nextTriggerTime.minute.toString().padLeft(2, '0');
    final period = nextTriggerTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year $hour:$minute $period';
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context, Reminder reminder) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              ref.read(reminderProvider.notifier).deleteReminder(reminder.id!);
              CoreLoggingUtility.info(
                'ReminderListScreen',
                '_showDeleteConfirmation',
                'Reminder deleted: ${reminder.id}',
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Build empty state when no reminders exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No reminders yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first reminder to get started!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/reminders/create'),
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
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
              'No ${_filter.name} reminders',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different filter',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Clear filter',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _filter = ReminderFilter.all;
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

  /// Build error state with retry button
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load reminders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'An unexpected error occurred. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(reminderProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
