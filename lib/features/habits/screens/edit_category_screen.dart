import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/exceptions/category_exception.dart';
import '../providers/categories_provider.dart';
import '../providers/category_detail_provider.dart';
import '../widgets/forms/icon_picker.dart';
import '../widgets/forms/color_picker.dart';
import '../../../core/utils/core_logging_utility.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final int categoryId;

  const EditCategoryScreen({
    super.key,
    required this.categoryId,
  });

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  
  String? _selectedIcon;
  String? _selectedColor;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  Category? _originalCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      CoreLoggingUtility.warning(
        'EditCategoryScreen',
        'saveCategory',
        'Form validation failed',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the errors in the form'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_originalCategory == null) {
      CoreLoggingUtility.error(
        'EditCategoryScreen',
        'saveCategory',
        'Original category is null',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCategory = _originalCategory!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      );

      CoreLoggingUtility.info(
        'EditCategoryScreen',
        'saveCategory',
        'Updating category: ${updatedCategory.name} (ID: ${widget.categoryId})',
      );

      await ref.read(categoriesProvider.notifier).updateCategory(updatedCategory);

      // Refresh the category detail provider if it's being watched
      ref.invalidate(categoryDetailProvider(widget.categoryId));

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        CoreLoggingUtility.info(
          'EditCategoryScreen',
          'saveCategory',
          'Category updated successfully',
        );
        
        context.pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'EditCategoryScreen',
        'saveCategory',
        'Failed to update category: $e\n$stackTrace',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Failed to update category. Please try again.';
        bool showRetry = true;
        
        if (e is CategoryValidationException) {
          errorMessage = e.message;
          showRetry = false; // Validation errors don't need retry
        } else if (e is CategoryNotFoundException) {
          errorMessage = 'Category not found. It may have been deleted.';
          showRetry = false;
        } else if (e is CategoryDatabaseException) {
          errorMessage = 'Database error. Please try again.';
          if (e.originalError != null) {
            CoreLoggingUtility.error(
              'EditCategoryScreen',
              'saveCategory',
              'Original error: ${e.originalError}',
            );
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: showRetry
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _saveCategory,
                  )
                : SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryDetailAsync = ref.watch(categoryDetailProvider(widget.categoryId));

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Category'),
        ),
        body: categoryDetailAsync.when(
          loading: () => Center(
            child: Semantics(
              label: 'Loading category details',
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) {
            CoreLoggingUtility.error(
              'EditCategoryScreen',
              'build',
              'Error loading category: $error',
            );
            
            String title = 'Failed to load category';
            String message = 'An unexpected error occurred.';
            bool showRetry = true;
            
            if (error is CategoryNotFoundException) {
              title = 'Category Not Found';
              message = 'This category no longer exists or has been deleted.';
              showRetry = false;
            } else if (error is CategoryDatabaseException) {
              title = 'Database Error';
              message = 'There was a problem accessing the database.';
            }
            
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Go back to categories list',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Go Back'),
                          ),
                        ),
                        if (showRetry) ...[
                          const SizedBox(width: 12),
                          Semantics(
                            label: 'Retry loading category',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref.invalidate(categoryDetailProvider(widget.categoryId));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          data: (categoryDetail) {
            // Initialize form fields with category data on first load
            if (_originalCategory == null) {
              _originalCategory = categoryDetail.category;
              _nameController.text = categoryDetail.category.name;
              _descriptionController.text = categoryDetail.category.description ?? '';
              _selectedIcon = categoryDetail.category.icon;
              _selectedColor = categoryDetail.category.color;
            }

            return _isLoading
                ? Center(
                    child: Semantics(
                      label: 'Saving category changes',
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Semantics(
                          label: 'Category name input field',
                          textField: true,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                              hintText: 'e.g., Health, Work, Personal',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a category name';
                              }
                              if (value.trim().length > 50) {
                                return 'Category name must be 50 characters or less';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => _markAsChanged(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Category description input field, optional',
                          textField: true,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              hintText: 'Add more details about this category',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            maxLength: 200,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value != null && value.trim().length > 200) {
                                return 'Description must be 200 characters or less';
                              }
                              return null;
                            },
                            onChanged: (_) => _markAsChanged(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Icon',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        IconPicker(
                          selectedIcon: _selectedIcon,
                          onIconSelected: (icon) {
                            setState(() {
                              _selectedIcon = icon;
                            });
                            _markAsChanged();
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Color',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ColorPicker(
                          selectedColor: _selectedColor,
                          onColorSelected: (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                            _markAsChanged();
                          },
                        ),
                        const SizedBox(height: 32),
                        Semantics(
                          label: 'Save category changes button',
                          button: true,
                          enabled: !_isLoading,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveCategory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }
}
