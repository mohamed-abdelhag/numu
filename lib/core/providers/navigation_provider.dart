import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/navigation_item.dart';
import '../services/settings_repository.dart';
import '../utils/core_logging_utility.dart';
import 'theme_provider.dart';

part 'navigation_provider.g.dart';

/// Notifier for managing navigation items state
@riverpod
class NavigationNotifier extends _$NavigationNotifier {
  late final SettingsRepository _repository;

  /// Default navigation items for the app
  static final List<NavigationItem> _defaultItems = [
    const NavigationItem(
      id: 'home',
      label: 'Home',
      icon: Icons.home,
      route: '/home',
      isHome: true,
      isEnabled: true,
      order: 0,
    ),
    const NavigationItem(
      id: 'tasks',
      label: 'Tasks',
      icon: Icons.task,
      route: '/tasks',
      isHome: false,
      isEnabled: true,
      order: 1,
    ),
    const NavigationItem(
      id: 'habits',
      label: 'Habits',
      icon: Icons.track_changes,
      route: '/habits',
      isHome: false,
      isEnabled: true,
      order: 2,
    ),
    const NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person,
      route: '/profile',
      isHome: false,
      isEnabled: true,
      order: 3,
    ),
    const NavigationItem(
      id: 'help',
      label: 'Help',
      icon: Icons.help_outline,
      route: '/help',
      isHome: false,
      isEnabled: true,
      order: 4,
    ),
    const NavigationItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings,
      route: '/settings',
      isHome: false,
      isEnabled: true,
      order: 5,
    ),
  ];

  @override
  Future<List<NavigationItem>> build() async {
    _repository = ref.read(settingsRepositoryProvider);
    CoreLoggingUtility.info(
      'NavigationNotifier',
      'build',
      'Loading navigation items',
    );
    return await _loadNavigationItems();
  }

  /// Loads navigation items from storage and merges with defaults
  Future<List<NavigationItem>> _loadNavigationItems() async {
    try {
      final visibility = await _repository.getNavigationItemsVisibility();
      final order = await _repository.getNavigationOrder();

      CoreLoggingUtility.info(
        'NavigationNotifier',
        '_loadNavigationItems',
        'Loaded visibility: $visibility, order: $order',
      );

      // Start with default items
      List<NavigationItem> items = List.from(_defaultItems);

      // Apply saved visibility preferences
      if (visibility.isNotEmpty) {
        items = items.map((item) {
          final savedEnabled = visibility[item.id];
          if (savedEnabled != null) {
            return item.copyWith(isEnabled: savedEnabled);
          }
          return item;
        }).toList();
      }

      // Apply saved order preferences
      if (order.isNotEmpty) {
        // Create a map for quick lookup
        final itemsMap = {for (var item in items) item.id: item};
        
        // Reorder based on saved order
        final reorderedItems = <NavigationItem>[];
        for (int i = 0; i < order.length; i++) {
          final id = order[i];
          final item = itemsMap[id];
          if (item != null) {
            reorderedItems.add(item.copyWith(order: i));
            itemsMap.remove(id);
          }
        }
        
        // Add any items not in saved order (new items added to app)
        final remainingItems = itemsMap.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        for (var item in remainingItems) {
          reorderedItems.add(item.copyWith(order: reorderedItems.length));
        }
        
        items = reorderedItems;
      }

      // Validate loaded data and repair if necessary
      items = _repairNavigationData(items);

      CoreLoggingUtility.info(
        'NavigationNotifier',
        '_loadNavigationItems',
        'Successfully loaded ${items.length} navigation items',
      );

      return items;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        '_loadNavigationItems',
        'Failed to load navigation items: $e\nStack trace: $stackTrace',
      );
      // Return defaults on error (graceful fallback)
      CoreLoggingUtility.info(
        'NavigationNotifier',
        '_loadNavigationItems',
        'Using default navigation items due to error',
      );
      return List.from(_defaultItems);
    }
  }

  /// Repairs corrupted navigation data by ensuring critical items are valid
  List<NavigationItem> _repairNavigationData(List<NavigationItem> items) {
    try {
      // Ensure Home item exists and is first
      final homeIndex = items.indexWhere((item) => item.isHome);
      if (homeIndex == -1) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          '_repairNavigationData',
          'Home item missing, adding default',
        );
        items.insert(0, _defaultItems.firstWhere((item) => item.isHome));
      } else if (homeIndex != 0) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          '_repairNavigationData',
          'Home item not first, moving to first position',
        );
        final homeItem = items.removeAt(homeIndex);
        items.insert(0, homeItem);
      }

      // Ensure Home is enabled
      if (!items.first.isEnabled) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          '_repairNavigationData',
          'Home item disabled, enabling it',
        );
        items[0] = items.first.copyWith(isEnabled: true);
      }

      // Ensure Settings item exists and is enabled
      final settingsIndex = items.indexWhere((item) => item.id == 'settings');
      if (settingsIndex == -1) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          '_repairNavigationData',
          'Settings item missing, adding default',
        );
        items.add(_defaultItems.firstWhere((item) => item.id == 'settings'));
      } else if (!items[settingsIndex].isEnabled) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          '_repairNavigationData',
          'Settings item disabled, enabling it',
        );
        items[settingsIndex] = items[settingsIndex].copyWith(isEnabled: true);
      }

      // Fix order values to be sequential
      for (int i = 0; i < items.length; i++) {
        if (items[i].order != i) {
          items[i] = items[i].copyWith(order: i);
        }
      }

      CoreLoggingUtility.info(
        'NavigationNotifier',
        '_repairNavigationData',
        'Navigation data repair completed',
      );

      return items;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        '_repairNavigationData',
        'Failed to repair navigation data: $e\nStack trace: $stackTrace',
      );
      // Return defaults if repair fails
      return List.from(_defaultItems);
    }
  }

  /// Toggles the visibility of a navigation item
  /// Locked items (Home and Settings) cannot be disabled
  void toggleItemVisibility(String itemId) {
    if (!state.hasValue) {
      CoreLoggingUtility.warning(
        'NavigationNotifier',
        'toggleItemVisibility',
        'Cannot toggle visibility: state not loaded',
      );
      return;
    }
    
    final currentState = state.requireValue;

    try {
      final updatedItems = currentState.map((item) {
        if (item.id == itemId) {
          // Prevent disabling locked items
          if (item.isLocked) {
            CoreLoggingUtility.warning(
              'NavigationNotifier',
              'toggleItemVisibility',
              'Cannot disable locked item: $itemId',
            );
            return item;
          }
          
          CoreLoggingUtility.info(
            'NavigationNotifier',
            'toggleItemVisibility',
            'Toggling visibility for $itemId: ${item.isEnabled} -> ${!item.isEnabled}',
          );
          
          return item.copyWith(isEnabled: !item.isEnabled);
        }
        return item;
      }).toList();

      state = AsyncValue.data(updatedItems);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        'toggleItemVisibility',
        'Failed to toggle visibility: $e',
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reorders navigation items
  /// Home item must always remain first
  void reorderItems(int oldIndex, int newIndex) {
    if (!state.hasValue) {
      CoreLoggingUtility.warning(
        'NavigationNotifier',
        'reorderItems',
        'Cannot reorder: state not loaded',
      );
      return;
    }
    
    final currentState = state.requireValue;

    try {
      // Prevent moving Home from first position
      final homeItem = currentState.firstWhere((item) => item.isHome);
      if (homeItem.order == oldIndex && newIndex != 0) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          'reorderItems',
          'Cannot move Home item from first position',
        );
        return;
      }

      // Prevent moving any item to position 0 (Home's position)
      if (newIndex == 0 && oldIndex != 0) {
        CoreLoggingUtility.warning(
          'NavigationNotifier',
          'reorderItems',
          'Cannot move item to first position (reserved for Home)',
        );
        return;
      }

      CoreLoggingUtility.info(
        'NavigationNotifier',
        'reorderItems',
        'Reordering item from $oldIndex to $newIndex',
      );

      final items = List<NavigationItem>.from(currentState);
      
      // Adjust newIndex if moving down
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      // Move the item
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      // Update order values
      final updatedItems = items.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();

      state = AsyncValue.data(updatedItems);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        'reorderItems',
        'Failed to reorder items: $e',
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Saves current navigation preferences to storage
  Future<void> saveChanges() async {
    if (!state.hasValue) {
      CoreLoggingUtility.warning(
        'NavigationNotifier',
        'saveChanges',
        'Cannot save: state not loaded',
      );
      throw Exception('Navigation state not loaded');
    }
    
    final currentState = state.requireValue;

    try {
      // Validate before saving
      _validateNavigationState(currentState);

      CoreLoggingUtility.info(
        'NavigationNotifier',
        'saveChanges',
        'Saving navigation preferences',
      );

      // Prepare visibility map
      final visibility = {
        for (var item in currentState) item.id: item.isEnabled
      };

      // Prepare order list
      final order = currentState.map((item) => item.id).toList();

      // Save to repository
      await _repository.saveNavigationItemsVisibility(visibility);
      await _repository.saveNavigationOrder(order);

      CoreLoggingUtility.info(
        'NavigationNotifier',
        'saveChanges',
        'Successfully saved navigation preferences',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        'saveChanges',
        'Failed to save navigation preferences: $e',
      );
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Resets navigation items to default configuration
  void resetToDefaults() {
    try {
      CoreLoggingUtility.info(
        'NavigationNotifier',
        'resetToDefaults',
        'Resetting navigation items to defaults',
      );

      state = AsyncValue.data(List.from(_defaultItems));
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NavigationNotifier',
        'resetToDefaults',
        'Failed to reset to defaults: $e',
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Validates navigation state before saving
  void _validateNavigationState(List<NavigationItem> items) {
    // Ensure Home is first
    if (items.isEmpty || !items.first.isHome) {
      throw Exception('Home item must be first');
    }

    // Ensure Home is enabled
    final homeItem = items.firstWhere((item) => item.isHome);
    if (!homeItem.isEnabled) {
      throw Exception('Home item must be enabled');
    }

    // Ensure Settings is enabled
    final settingsItem = items.firstWhere((item) => item.id == 'settings');
    if (!settingsItem.isEnabled) {
      throw Exception('Settings item must be enabled');
    }

    // Ensure at least one item is enabled
    final enabledCount = items.where((item) => item.isEnabled).length;
    if (enabledCount == 0) {
      throw Exception('At least one navigation item must be enabled');
    }

    // Ensure order values are unique and sequential
    final orders = items.map((item) => item.order).toList();
    final uniqueOrders = orders.toSet();
    if (orders.length != uniqueOrders.length) {
      throw Exception('Order values must be unique');
    }

    for (int i = 0; i < items.length; i++) {
      if (items[i].order != i) {
        throw Exception('Order values must be sequential starting from 0');
      }
    }

    CoreLoggingUtility.info(
      'NavigationNotifier',
      '_validateNavigationState',
      'Navigation state validation passed',
    );
  }
}
