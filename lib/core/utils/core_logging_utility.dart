import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';

/// A service for logging throughout the application.
/// This wrapper around flutter_logs ensures a consistent API and handles initialization.
class CoreLoggingUtility {
  static bool _initialized = false;
  
  /// Initialize logs
  static Future<void> init() async {
    if (kIsWeb) {
      // Logging not supported on web
      _initialized = true;
      return;
    }
    if (_initialized) return;
    
    try {
      await FlutterLogs.initLogs(
        logLevelsEnabled: [
          LogLevel.INFO,
          LogLevel.WARNING,
          LogLevel.ERROR,
          LogLevel.SEVERE
        ],
        timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
        directoryStructure: DirectoryStructure.FOR_DATE,
        logTypesEnabled: ["device", "network", "errors"],
        logFileExtension: LogFileExtension.LOG,
        logsWriteDirectoryName: "ZKRLogs",
        logsExportDirectoryName: "ZKRLogs/Exported",
        debugFileOperations: true,
        isDebuggable: true,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('ERROR [SharedLoggingUtility]: Failed to initialize logs: $e');
    }
  }

  /// Log info message
  static void info(String tag, String subTag, String message) {
    if (kIsWeb) {
      debugPrint('INFO [WEB][$tag:$subTag]: $message');
      return;
    }
    _ensureInitialized();
    try {
      FlutterLogs.logInfo(tag, subTag, message);
    } catch (e) {
      // Fallback to debugPrint if FlutterLogs fails
      debugPrint('INFO [$tag:$subTag]: $message');
    }
  }
  
  /// Log warning message
  static void warning(String tag, String subTag, String message) {
    if (kIsWeb) {
      debugPrint('WARNING [WEB][$tag:$subTag]: $message');
      return;
    }
    _ensureInitialized();
    try {
      FlutterLogs.logWarn(tag, subTag, message);
    } catch (e) {
      // Fallback to debugPrint if FlutterLogs fails
      debugPrint('WARNING [$tag:$subTag]: $message');
    }
  }
  
  /// Log error message
  static void error(String tag, String subTag, String message) {
    if (kIsWeb) {
      debugPrint('ERROR [WEB][$tag:$subTag]: $message');
      return;
    }
    _ensureInitialized();
    try {
      FlutterLogs.logError(tag, subTag, message);
    } catch (e) {
      // Fallback to debugPrint if FlutterLogs fails
      debugPrint('ERROR [$tag:$subTag]: $message');
    }
  }
  
  /// Ensure logs are initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      // Use init as a Future to avoid blocking
      init();
    }
  }
} 
