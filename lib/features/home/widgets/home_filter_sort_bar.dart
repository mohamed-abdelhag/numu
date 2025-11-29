import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_filter_provider.dart';

/// Filter and sort controls for the home screen.
/// Provides a compact UI to filter item types and change sort order.
class HomeFilterSortBar extends ConsumerWidget {
  const HomeFilterSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(homeFilterProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter button
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HomeFilterType.values.map((type) {
                  final isVisible = filterState.isVisible(type);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: isVisible,
                      onSelected: (selected) {
                        ref.read(homeFilterProvider.notifier).toggleFilter(type);
                      },
                      avatar: Icon(
                        _getIconForType(type),
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort button
          PopupMenuButton<HomeSortType>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  filterState.sortDisplayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            onSelected: (sortType) {
              ref.read(homeFilterProvider.notifier).setSortType(sortType);
            },
            itemBuilder: (context) => HomeSortType.values.map((type) {
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getSortIcon(type),
                      size: 20,
                      color: filterState.sortType == type
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontWeight: filterState.sortType == type
                                  ? FontWeight.bold
                                  : null,
                              color: filterState.sortType == type
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          Text(
                            type.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filterState.sortType == type)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(HomeFilterType type) {
    switch (type) {
      case HomeFilterType.habits:
        return Icons.repeat;
      case HomeFilterType.tasks:
        return Icons.task_alt;
      case HomeFilterType.prayers:
        return Icons.mosque;
      case HomeFilterType.sunnah:
        return Icons.star_outline;
    }
  }

  IconData _getSortIcon(HomeSortType type) {
    switch (type) {
      case HomeSortType.time:
        return Icons.schedule;
      case HomeSortType.type:
        return Icons.category;
      case HomeSortType.category:
        return Icons.mosque;
    }
  }
}

/// A more compact filter toggle for inline use
class HomeFilterToggle extends ConsumerWidget {
  final HomeFilterType filterType;
  
  const HomeFilterToggle({
    super.key,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(homeFilterProvider);
    final isVisible = filterState.isVisible(filterType);
    final theme = Theme.of(context);

    return IconButton(
      icon: Icon(
        _getIconForType(filterType),
        color: isVisible 
            ? theme.colorScheme.primary 
            : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      ),
      onPressed: () {
        ref.read(homeFilterProvider.notifier).toggleFilter(filterType);
      },
      tooltip: '${isVisible ? 'Hide' : 'Show'} ${filterType.displayName}',
    );
  }

  IconData _getIconForType(HomeFilterType type) {
    switch (type) {
      case HomeFilterType.habits:
        return Icons.repeat;
      case HomeFilterType.tasks:
        return Icons.task_alt;
      case HomeFilterType.prayers:
        return Icons.mosque;
      case HomeFilterType.sunnah:
        return Icons.star_outline;
    }
  }
}
