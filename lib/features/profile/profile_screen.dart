import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import 'package:numu/features/profile/providers/user_profile_provider.dart';
import 'package:numu/features/profile/models/user_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the errors in the form'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Saving profile...'),
            ],
          ),
          duration: Duration(minutes: 1), // Will be dismissed manually
        ),
      );
    }

    final currentProfile = ref.read(userProfileProvider).value;
    final now = DateTime.now();

    try {
      final updatedProfile = currentProfile?.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        updatedAt: now,
      ) ?? UserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      if (currentProfile == null) {
        await ref.read(userProfileProvider.notifier).createProfile(updatedProfile);
      } else {
        await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
      }

      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Profile saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Exit edit mode
        _toggleEditMode();
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'ProfileScreen',
        '_saveProfile',
        'Failed to save profile: $e',
      );

      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show user-friendly error message
        String errorMessage = 'Failed to save profile';
        if (e.toString().contains('already exists')) {
          errorMessage = 'A profile already exists';
        } else if (e.toString().contains('without an id')) {
          errorMessage = 'Invalid profile data';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'Profile not found. Please try again.';
        } else if (e.toString().contains('database')) {
          errorMessage = 'Database error. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('ProfileScreen', 'build', 'Building profile screen');
    
    final profileAsync = ref.watch(userProfileProvider);

    return Column(
      children: [
        const NumuAppBar(
          title: 'Profile',
        ),
        Expanded(
          child: profileAsync.when(
            data: (profile) {
              // Update controllers when profile data is available
              if (profile != null && !_isEditMode) {
                _nameController.text = profile.name;
                _emailController.text = profile.email ?? '';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Profile Picture Placeholder
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Profile Information
                    if (_isEditMode)
                      _buildEditMode(context)
                    else
                      _buildViewMode(context, profile),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) {
              CoreLoggingUtility.error(
                'ProfileScreen',
                'build',
                'Error loading profile: $error\n$stack',
              );
              
              // Determine user-friendly error message
              String errorMessage = 'Unable to load profile';
              if (error.toString().contains('database')) {
                errorMessage = 'Database error occurred';
              } else if (error.toString().contains('Failed to fetch')) {
                errorMessage = 'Could not retrieve profile data';
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
                      const SizedBox(height: 24),
                      Text(
                        errorMessage,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again or contact support if the problem persists',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(userProfileProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleEditMode,
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Name',
              value: profile?.name ?? 'Not set',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: 'Email',
              value: profile?.email ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length > 50) {
                    return 'Name must be 50 characters or less';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email (optional)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
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
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Reset form and exit edit mode
                      _formKey.currentState?.reset();
                      final profile = ref.read(userProfileProvider).value;
                      if (profile != null) {
                        _nameController.text = profile.name;
                        _emailController.text = profile.email ?? '';
                      }
                      _toggleEditMode();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveProfile,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
