import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_state.dart';
import '../repositories/onboarding_repository.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'onboarding_provider.g.dart';

/// Provider for SharedPreferences instance
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// Provider for OnboardingRepository
@riverpod
Future<OnboardingRepository> onboardingRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return OnboardingRepository(prefs);
}

/// Provider for checking onboarding completion status
/// Returns true if onboarding has been completed, false otherwise
/// Fails gracefully by returning false if SharedPreferences is unavailable
@riverpod
Future<bool> onboardingCompleted(Ref ref) async {
  try {
    final repository = await ref.watch(onboardingRepositoryProvider.future);
    final isCompleted = await repository.isOnboardingCompleted();
    CoreLoggingUtility.info(
      'OnboardingProvider',
      'onboardingCompleted',
      'Onboarding completion status: $isCompleted',
    );
    return isCompleted;
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'OnboardingProvider',
      'onboardingCompleted',
      'Failed to check onboarding status, defaulting to false: $e\n$stackTrace',
    );
    // Fail gracefully - if we can't check, assume onboarding is not completed
    // This ensures users see the onboarding rather than getting stuck
    return false;
  }
}

/// Provider for full onboarding state including completion date
/// Fails gracefully by returning incomplete state if SharedPreferences is unavailable
@riverpod
Future<OnboardingState> onboardingState(Ref ref) async {
  try {
    final repository = await ref.watch(onboardingRepositoryProvider.future);
    final isCompleted = await repository.isOnboardingCompleted();
    final completedAt = await repository.getOnboardingCompletedAt();
    
    final state = OnboardingState(
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
    
    CoreLoggingUtility.info(
      'OnboardingProvider',
      'onboardingState',
      'Loaded onboarding state: completed=$isCompleted, completedAt=$completedAt',
    );
    
    return state;
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'OnboardingProvider',
      'onboardingState',
      'Failed to load onboarding state, returning default: $e\n$stackTrace',
    );
    // Fail gracefully - return incomplete state
    return const OnboardingState(
      isCompleted: false,
      completedAt: null,
    );
  }
}

/// Notifier for managing onboarding state changes
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  late OnboardingRepository _repository;

  @override
  Future<OnboardingState> build() async {
    final repository = await ref.watch(onboardingRepositoryProvider.future);
    _repository = repository;
    
    final isCompleted = await _repository.isOnboardingCompleted();
    final completedAt = await _repository.getOnboardingCompletedAt();
    
    return OnboardingState(
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }

  /// Mark onboarding as completed
  /// Handles SharedPreferences failures gracefully
  Future<void> markCompleted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.markOnboardingCompleted();
        final completedAt = await _repository.getOnboardingCompletedAt();
        
        CoreLoggingUtility.info(
          'OnboardingNotifier',
          'markCompleted',
          'Successfully marked onboarding as completed',
        );
        
        return OnboardingState(
          isCompleted: true,
          completedAt: completedAt,
        );
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'OnboardingNotifier',
          'markCompleted',
          'Failed to mark onboarding as completed: $e\n$stackTrace',
        );
        // Even if saving fails, we'll mark it as completed in memory
        // to allow the user to proceed
        CoreLoggingUtility.info(
          'OnboardingNotifier',
          'markCompleted',
          'Proceeding with in-memory completion despite save failure',
        );
        return OnboardingState(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }
    });
  }

  /// Reset onboarding status (for testing)
  Future<void> reset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.resetOnboarding();
        
        CoreLoggingUtility.info(
          'OnboardingNotifier',
          'reset',
          'Successfully reset onboarding status',
        );
        
        return const OnboardingState(
          isCompleted: false,
          completedAt: null,
        );
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'OnboardingNotifier',
          'reset',
          'Failed to reset onboarding: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }
}
