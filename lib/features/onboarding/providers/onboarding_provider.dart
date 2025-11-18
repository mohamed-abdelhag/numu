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
      'Failed to check onboarding status: $e\n$stackTrace',
    );
    rethrow;
  }
}

/// Provider for full onboarding state including completion date
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
      'Failed to load onboarding state: $e\n$stackTrace',
    );
    rethrow;
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
        rethrow;
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
