import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

part 'categories_provider.g.dart';

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  late final CategoryRepository _repository;

  @override
  Future<List<Category>> build() async {
    _repository = CategoryRepository();
    
    // Seed default categories on first load
    await _repository.seedDefaultCategories();
    
    return await _repository.getCategories();
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createCategory(category);
      return await _repository.getCategories();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getCategories();
    });
  }
}
