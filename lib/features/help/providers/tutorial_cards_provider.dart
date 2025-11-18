import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/tutorial_card_model.dart';
import '../repositories/tutorial_cards_repository.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'tutorial_cards_provider.g.dart';

/// Provider for TutorialCardsRepository
@riverpod
TutorialCardsRepository tutorialCardsRepository(Ref ref) {
  final db = DatabaseService.instance;
  return TutorialCardsRepository(db);
}

/// Provider for fetching all tutorial cards
/// Returns a list of tutorial cards ordered by sort_order
@riverpod
Future<List<TutorialCardModel>> allTutorialCards(Ref ref) async {
  try {
    final repository = ref.watch(tutorialCardsRepositoryProvider);
    
    // Initialize default tutorials if needed
    await repository.initializeDefaultTutorials();
    
    final tutorials = await repository.getAllTutorials();
    CoreLoggingUtility.info(
      'TutorialCardsProvider',
      'allTutorialCards',
      'Successfully loaded ${tutorials.length} tutorial cards',
    );
    return tutorials;
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'TutorialCardsProvider',
      'allTutorialCards',
      'Failed to load tutorial cards: $e\n$stackTrace',
    );
    rethrow;
  }
}

/// Provider for fetching a specific tutorial card by ID
@riverpod
Future<TutorialCardModel?> tutorialCardById(
  Ref ref,
  String id,
) async {
  try {
    final repository = ref.watch(tutorialCardsRepositoryProvider);
    final tutorial = await repository.getTutorialById(id);
    
    CoreLoggingUtility.info(
      'TutorialCardsProvider',
      'tutorialCardById',
      tutorial != null
          ? 'Successfully loaded tutorial card: ${tutorial.title}'
          : 'Tutorial card not found with ID: $id',
    );
    
    return tutorial;
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'TutorialCardsProvider',
      'tutorialCardById',
      'Failed to load tutorial card with ID $id: $e\n$stackTrace',
    );
    rethrow;
  }
}

/// Notifier for managing tutorial cards state
/// Handles CRUD operations with automatic state refresh
@riverpod
class TutorialCardsNotifier extends _$TutorialCardsNotifier {
  late final TutorialCardsRepository _repository;

  @override
  Future<List<TutorialCardModel>> build() async {
    _repository = ref.read(tutorialCardsRepositoryProvider);
    
    try {
      // Initialize default tutorials if needed
      await _repository.initializeDefaultTutorials();
      
      final tutorials = await _repository.getAllTutorials();
      CoreLoggingUtility.info(
        'TutorialCardsNotifier',
        'build',
        'Successfully loaded ${tutorials.length} tutorial cards',
      );
      return tutorials;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'TutorialCardsNotifier',
        'build',
        'Failed to load tutorial cards: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Create a new tutorial card and refresh the list
  Future<void> createTutorial(TutorialCardModel tutorial) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.createTutorial(tutorial);
        CoreLoggingUtility.info(
          'TutorialCardsNotifier',
          'createTutorial',
          'Successfully created tutorial card: ${tutorial.title}',
        );
        return await _repository.getAllTutorials();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'TutorialCardsNotifier',
          'createTutorial',
          'Failed to create tutorial card "${tutorial.title}": $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Update an existing tutorial card and refresh the list
  Future<void> updateTutorial(TutorialCardModel tutorial) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.updateTutorial(tutorial);
        CoreLoggingUtility.info(
          'TutorialCardsNotifier',
          'updateTutorial',
          'Successfully updated tutorial card: ${tutorial.title}',
        );
        return await _repository.getAllTutorials();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'TutorialCardsNotifier',
          'updateTutorial',
          'Failed to update tutorial card "${tutorial.title}": $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Delete a tutorial card and refresh the list
  Future<void> deleteTutorial(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.deleteTutorial(id);
        CoreLoggingUtility.info(
          'TutorialCardsNotifier',
          'deleteTutorial',
          'Successfully deleted tutorial card with ID: $id',
        );
        return await _repository.getAllTutorials();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'TutorialCardsNotifier',
          'deleteTutorial',
          'Failed to delete tutorial card with ID $id: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Initialize default tutorial cards
  Future<void> initializeDefaults() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.initializeDefaultTutorials();
        CoreLoggingUtility.info(
          'TutorialCardsNotifier',
          'initializeDefaults',
          'Successfully initialized default tutorial cards',
        );
        return await _repository.getAllTutorials();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'TutorialCardsNotifier',
          'initializeDefaults',
          'Failed to initialize default tutorial cards: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }
}
