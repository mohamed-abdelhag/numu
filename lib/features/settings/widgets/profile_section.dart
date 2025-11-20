import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/features/settings/models/user_profile.dart';
import 'package:numu/features/settings/providers/user_profile_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

/// ProfileSection widget displays and allows editing of user profile information
/// within the settings screen. It supports view and edit modes with inline editing.
class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({super.key});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  bool _isEditMode = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: profileAsync.when(
          data: (profile) => _isEditMode
              ? _buildEditMode(profile)
              : _buildViewMode(profile),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }
  
  /// Builds the view mode display showing profile information
  Widget _buildViewMode(UserProfile? profile) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                CoreLoggingUtility.info(
                  'ProfileSection',
                  '_buildViewMode',
                  'Entering edit mode',
                );
                _enterEditMode(profile);
              },
              tooltip: 'Edit profile',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Avatar placeholder
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'No name set',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? 'No email set',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Builds the edit mode with form fields for editing profile
  Widget _buildEditMode(UserProfile? profile) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            enabled: !_isSaving,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSaving,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                // Basic email validation
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : _cancelEdit,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveProfile(profile),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds loading state indicator
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      ),
    );
  }
  
  /// Builds error state with retry button
  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                CoreLoggingUtility.info(
                  'ProfileSection',
                  '_buildErrorState',
                  'Retrying profile load',
                );
                ref.invalidate(userProfileProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Enters edit mode and populates form fields with current profile data
  void _enterEditMode(UserProfile? profile) {
    setState(() {
      _isEditMode = true;
      _nameController.text = profile?.name ?? '';
      _emailController.text = profile?.email ?? '';
    });
  }
  
  /// Cancels edit mode and returns to view mode
  void _cancelEdit() {
    CoreLoggingUtility.info(
      'ProfileSection',
      '_cancelEdit',
      'Cancelling profile edit',
    );
    
    setState(() {
      _isEditMode = false;
      _nameController.clear();
      _emailController.clear();
    });
  }
  
  /// Saves the profile with validation and error handling
  Future<void> _saveProfile(UserProfile? existingProfile) async {
    if (!_formKey.currentState!.validate()) {
      CoreLoggingUtility.warning(
        'ProfileSection',
        '_saveProfile',
        'Form validation failed',
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      
      CoreLoggingUtility.info(
        'ProfileSection',
        '_saveProfile',
        'Saving profile: name=$name, email=$email',
      );
      
      if (existingProfile == null) {
        // Create new profile
        final newProfile = UserProfile(
          name: name,
          email: email.isEmpty ? null : email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await ref.read(userProfileProvider.notifier).createProfile(newProfile);
        
        CoreLoggingUtility.info(
          'ProfileSection',
          '_saveProfile',
          'Successfully created new profile',
        );
      } else {
        // Update existing profile
        final updatedProfile = existingProfile.copyWith(
          name: name,
          email: email.isEmpty ? null : email,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
        
        CoreLoggingUtility.info(
          'ProfileSection',
          '_saveProfile',
          'Successfully updated profile',
        );
      }
      
      // Exit edit mode on success
      if (mounted) {
        setState(() {
          _isEditMode = false;
          _isSaving = false;
        });
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile saved successfully'),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ProfileSection',
        '_saveProfile',
        'Failed to save profile: $e\n$stackTrace',
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        // Show error feedback with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Failed to save profile'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveProfile(existingProfile),
            ),
          ),
        );
      }
    }
  }
}
