import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/app.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  // ...no FFI initialization needed for mobile...
  WidgetsFlutterBinding.ensureInitialized();
  // Basic debug print to show app started before the shared logging utility
  debugPrint('Initializing the core logging utility');
  CoreLoggingUtility.init();
  CoreLoggingUtility.info('main dart file','initialised the logging utility','main starting app runApp');
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

