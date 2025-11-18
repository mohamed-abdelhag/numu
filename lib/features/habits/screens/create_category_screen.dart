import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/exceptions/category_exception.dart';
import '../providers/categories_provider.dart';
import '../widgets/forms/icon_picker.dart';
import '../widgets/forms/color_picker.dart';
import '../../../core/utils/core_logging_utility.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  ConsumerState<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = '📁';
  String _selectedColor = '0xFF64B5F6';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

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
        'CreateCategoryScreen',
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

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      final category = Category(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        createdAt: now,
      );

      CoreLoggingUtility.info(
        'CreateCategoryScreen',
        'saveCategory',
        'Creating category: ${category.name}',
      );

      await ref.read(categoriesProvider.notifier).addCategory(category);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        CoreLoggingUtility.info(
          'CreateCategoryScreen',
          'saveCategory',
          'Category created successfully',
        );
        
        context.pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CreateCategoryScreen',
        'saveCategory',
        'Failed to create category: $e\n$stackTrace',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Failed to create category. Please try again.';
        bool showRetry = true;
        
        if (e is CategoryValidationException) {
          errorMessage = e.message;
          showRetry = false; // Validation errors don't need retry
        } else if (e is CategoryDatabaseException) {
          errorMessage = 'Database error. Please try again.';
          if (e.originalError != null) {
            CoreLoggingUtility.error(
              'CreateCategoryScreen',
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
          title: const Text('Create Category'),
        ),
        body: _isLoading
            ? Center(
                child: Semantics(
                  label: 'Creating category',
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
                        autofocus: true,
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
                      label: 'Create category button',
                      button: true,
                      enabled: !_isLoading,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCategory,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Create Category'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
