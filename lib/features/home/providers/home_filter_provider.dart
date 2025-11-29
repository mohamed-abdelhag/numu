import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'home_filter_provider.g.dart';

/// Filter options for showing/hiding item types on home screen
enum HomeFilterType {
  habits,
  tasks,
  prayers,
  sunnah, // Nafila prayers
}

/// Sort options for organizing items on home screen
enum HomeSortType {
  time,       // Sort by scheduled time
  type,       // Group by item type (habits, tasks, prayers, sunnah)
  category,   // Group Islamic items together, non-Islamic items together
}

/// State class for home screen filter and sort preferences
class HomeFilterState {
  final Set<HomeFilterType> visibleTypes;
  final HomeSortType sortType;
  
  const HomeFilterState({
    this.visibleTypes = const {
      HomeFilterType.habits,
      HomeFilterType.tasks,
      HomeFilterType.prayers,
      HomeFilterType.sunnah,
    },
    this.sortType = HomeSortType.time,
  });
  
  HomeFilterState copyWith({
    Set<HomeFilterType>? visibleTypes,
    HomeSortType? sortType,
  }) {
    return HomeFilterState(
      visibleTypes: visibleTypes ?? this.visibleTypes,
      sortType: sortType ?? this.sortType,
    );
  }
  
  /// Check if a specific type is visible
  bool isVisible(HomeFilterType type) => visibleTypes.contains(type);
  
  /// Check if all types are visible
  bool get allVisible => visibleTypes.length == HomeFilterType.values.length;
  
  /// Get a display name for the current sort type
  String get sortDisplayName {
    switch (sortType) {
      case HomeSortType.time:
        return 'Time';
      case HomeSortType.type:
        return 'Type';
      case HomeSortType.category:
        return 'Category';
    }
  }
}

/// Provider for managing home screen filter and sort preferences
@riverpod
class HomeFilterNotifier extends _$HomeFilterNotifier {
  @override
  HomeFilterState build() {
    CoreLoggingUtility.info(
      'HomeFilterProvider',
      'build',
      'Initializing home filter state',
    );
    return const HomeFilterState();
  }
  
  /// Toggle visibility of a specific item type
  void toggleFilter(HomeFilterType type) {
    final currentTypes = Set<HomeFilterType>.from(state.visibleTypes);
    
    if (currentTypes.contains(type)) {
      // Don't allow hiding all types - keep at least one visible
      if (currentTypes.length > 1) {
        currentTypes.remove(type);
      }
    } else {
      currentTypes.add(type);
    }
    
    CoreLoggingUtility.info(
      'HomeFilterProvider',
      'toggleFilter',
      'Toggled filter: $type, visible: ${currentTypes.contains(type)}',
    );
    
    state = state.copyWith(visibleTypes: currentTypes);
  }
  
  /// Set visibility for a specific type
  void setFilterVisible(HomeFilterType type, bool visible) {
    final currentTypes = Set<HomeFilterType>.from(state.visibleTypes);
    
    if (visible) {
      currentTypes.add(type);
    } else {
      // Don't allow hiding all types
      if (currentTypes.length > 1) {
        currentTypes.remove(type);
      }
    }
    
    state = state.copyWith(visibleTypes: currentTypes);
  }
  
  /// Set the sort type
  void setSortType(HomeSortType sortType) {
    CoreLoggingUtility.info(
      'HomeFilterProvider',
      'setSortType',
      'Setting sort type to: $sortType',
    );
    state = state.copyWith(sortType: sortType);
  }
  
  /// Show all item types
  void showAll() {
    state = state.copyWith(
      visibleTypes: Set.from(HomeFilterType.values),
    );
  }
  
  /// Reset to default settings
  void reset() {
    state = const HomeFilterState();
  }
}

/// Extension to get display names for filter types
extension HomeFilterTypeExtension on HomeFilterType {
  String get displayName {
    switch (this) {
      case HomeFilterType.habits:
        return 'Habits';
      case HomeFilterType.tasks:
        return 'Tasks';
      case HomeFilterType.prayers:
        return 'Prayers';
      case HomeFilterType.sunnah:
        return 'Sunnah';
    }
  }
  
  String get iconName {
    switch (this) {
      case HomeFilterType.habits:
        return 'repeat';
      case HomeFilterType.tasks:
        return 'task_alt';
      case HomeFilterType.prayers:
        return 'mosque';
      case HomeFilterType.sunnah:
        return 'star_outline';
    }
  }
}

/// Extension to get display names for sort types
extension HomeSortTypeExtension on HomeSortType {
  String get displayName {
    switch (this) {
      case HomeSortType.time:
        return 'Time';
      case HomeSortType.type:
        return 'Type';
      case HomeSortType.category:
        return 'Category';
    }
  }
  
  String get description {
    switch (this) {
      case HomeSortType.time:
        return 'Sort by scheduled time';
      case HomeSortType.type:
        return 'Group by habits, tasks, prayers';
      case HomeSortType.category:
        return 'Group Islamic items together';
    }
  }
}
