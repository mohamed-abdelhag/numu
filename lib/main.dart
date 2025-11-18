import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/app.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // ...no FFI initialization needed for mobile...
  WidgetsFlutterBinding.ensureInitialized();
  
  // Basic debug print to show app started before the shared logging utility
  debugPrint('Initializing the core logging utility');
  CoreLoggingUtility.init();
  CoreLoggingUtility.info('main dart file','initialised the logging utility','main starting app runApp');
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(sharedPreferences);
  
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: const MyApp(),
    ),
  );
}

