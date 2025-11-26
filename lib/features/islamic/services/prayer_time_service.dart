import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_schedule.dart';
import '../models/enums/calculation_method.dart';
import '../repositories/prayer_repository.dart';

/// Exception thrown when prayer time API operations fail.
class PrayerTimeException implements Exception {
  final String message;
  final bool isNetworkError;

  const PrayerTimeException(this.message, {this.isNetworkError = false});

  @override
  String toString() => 'PrayerTimeException: $message';
}

/// Service for fetching and caching prayer times from the Aladhan API.
///
/// **Validates: Requirements 1.1, 1.2, 1.4, 1.5, 1.6**
class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  /// Base URL for the Aladhan API.
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  /// HTTP client for making API requests.
  /// Can be overridden for testing.
  http.Client? _httpClient;

  /// Repository for caching prayer schedules.
  final PrayerRepository _repository = PrayerRepository();

  /// Set a custom HTTP client (useful for testing).
  void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// Get the HTTP client, creating a default one if not set.
  http.Client get _client => _httpClient ?? http.Client();

  /// Fetch prayer times for a specific date and location from the API.
  ///
  /// **Validates: Requirements 1.1, 1.6**
  Future<PrayerSchedule> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
  }) async {
    try {
      CoreLoggingUtility.info(
        'PrayerTimeService',
        'fetchPrayerTimes',
        'Fetching prayer times for $date at ($latitude, $longitude) using ${method.displayName}',
      );

      final response = await _fetchFromApi(
        latitude: latitude,
        longitude: longitude,
        date: date,
        method: method,
      );

      // Cache the schedule locally
      final savedSchedule = await _repository.savePrayerSchedule(response);

      CoreLoggingUtility.info(
        'PrayerTimeService',
        'fetchPrayerTimes',
        'Successfully fetched and cached prayer times for $date',
      );

      return savedSchedule;
    } on PrayerTimeException {
      rethrow;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerTimeService',
        'fetchPrayerTimes',
        'Failed to fetch prayer times: $e',
      );
      rethrow;
    }
  }


  /// Fetch prayer times from the Aladhan API.
  Future<PrayerSchedule> _fetchFromApi({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
  }) async {
    // Format date as DD-MM-YYYY for the API
    final dateStr = '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';

    final uri = Uri.parse(
      '$_baseUrl/timings/$dateStr'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&method=${_getApiMethodValue(method)}',
    );

    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw PrayerTimeException(
            'Request timed out',
            isNetworkError: true,
          );
        },
      );

      if (response.statusCode != 200) {
        throw PrayerTimeException(
          'API returned status code ${response.statusCode}',
          isNetworkError: true,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['code'] != 200 || json['status'] != 'OK') {
        throw PrayerTimeException(
          'API returned error: ${json['status']}',
        );
      }

      return _parseApiResponse(json, date, latitude, longitude, method);
    } on PrayerTimeException {
      rethrow;
    } on FormatException catch (e) {
      throw PrayerTimeException('Invalid API response format: $e');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('ClientException')) {
        throw PrayerTimeException(
          'Network error: $e',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Parse the API response into a PrayerSchedule.
  PrayerSchedule _parseApiResponse(
    Map<String, dynamic> json,
    DateTime date,
    double latitude,
    double longitude,
    CalculationMethod method,
  ) {
    final data = json['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;

    // Parse time strings (format: "HH:mm") into DateTime
    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length < 2) {
        throw PrayerTimeException('Invalid time format: $timeStr');
      }
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]); // Handle "(+1)" suffix
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return PrayerSchedule(
      date: date,
      latitude: latitude,
      longitude: longitude,
      method: method,
      fajrTime: parseTime(timings['Fajr'] as String),
      dhuhrTime: parseTime(timings['Dhuhr'] as String),
      asrTime: parseTime(timings['Asr'] as String),
      maghribTime: parseTime(timings['Maghrib'] as String),
      ishaTime: parseTime(timings['Isha'] as String),
      sunrise: parseTime(timings['Sunrise'] as String),
      createdAt: DateTime.now(),
    );
  }

  /// Convert CalculationMethod enum to API method value.
  /// Aladhan API uses specific integer values for each method.
  int _getApiMethodValue(CalculationMethod method) {
    return switch (method) {
      CalculationMethod.muslimWorldLeague => 3,
      CalculationMethod.isna => 2,
      CalculationMethod.egyptian => 5,
      CalculationMethod.ummAlQura => 4,
      CalculationMethod.karachi => 1,
      CalculationMethod.tehran => 7,
      CalculationMethod.gulf => 8,
    };
  }


  /// Get cached prayer times for a specific date.
  /// Returns null if no cached schedule exists.
  ///
  /// **Validates: Requirements 1.2**
  Future<PrayerSchedule?> getCachedSchedule(DateTime date) async {
    try {
      return await _repository.getPrayerSchedule(date);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerTimeService',
        'getCachedSchedule',
        'Failed to get cached schedule: $e',
      );
      return null;
    }
  }

  /// Check if the cache is valid for the current location.
  /// Cache is considered invalid if the location has changed significantly (>10km).
  ///
  /// **Validates: Requirements 1.3**
  Future<bool> isCacheValid(
    DateTime date,
    double latitude,
    double longitude,
  ) async {
    try {
      final cached = await getCachedSchedule(date);
      if (cached == null) {
        return false;
      }

      // Check if location has changed significantly
      final distance = _calculateDistance(
        cached.latitude,
        cached.longitude,
        latitude,
        longitude,
      );

      // Cache is valid if distance is less than 10km
      return distance < 10.0;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerTimeService',
        'isCacheValid',
        'Failed to check cache validity: $e',
      );
      return false;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula.
  /// Returns distance in kilometers.
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;


  /// Get prayer times for today, using cache if valid or fetching from API.
  /// Falls back to cached data if API is unavailable.
  ///
  /// **Validates: Requirements 1.4, 1.5**
  Future<PrayerSchedule> getPrayerTimesForToday({
    required double latitude,
    required double longitude,
    required CalculationMethod method,
  }) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    try {
      // Check if we have valid cached data
      final cacheValid = await isCacheValid(todayDate, latitude, longitude);
      if (cacheValid) {
        final cached = await getCachedSchedule(todayDate);
        if (cached != null) {
          CoreLoggingUtility.info(
            'PrayerTimeService',
            'getPrayerTimesForToday',
            'Using cached prayer times for today',
          );
          return cached;
        }
      }

      // Fetch fresh data from API
      return await fetchPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: todayDate,
        method: method,
      );
    } on PrayerTimeException catch (e) {
      // If network error, try to use cached data
      if (e.isNetworkError) {
        final cached = await getCachedSchedule(todayDate);
        if (cached != null) {
          CoreLoggingUtility.warning(
            'PrayerTimeService',
            'getPrayerTimesForToday',
            'API unavailable, using cached data: ${e.message}',
          );
          return cached;
        }
      }
      rethrow;
    }
  }

  /// Get prayer times for a specific date, using cache if available.
  /// Falls back to cached data if API is unavailable.
  ///
  /// **Validates: Requirements 1.2, 1.4**
  Future<PrayerSchedule> getPrayerTimesForDate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required CalculationMethod method,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    try {
      // Check if we have valid cached data
      final cacheValid = await isCacheValid(dateOnly, latitude, longitude);
      if (cacheValid) {
        final cached = await getCachedSchedule(dateOnly);
        if (cached != null) {
          CoreLoggingUtility.info(
            'PrayerTimeService',
            'getPrayerTimesForDate',
            'Using cached prayer times for $dateOnly',
          );
          return cached;
        }
      }

      // Fetch fresh data from API
      return await fetchPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: dateOnly,
        method: method,
      );
    } on PrayerTimeException catch (e) {
      // If network error, try to use cached data
      if (e.isNetworkError) {
        final cached = await getCachedSchedule(dateOnly);
        if (cached != null) {
          CoreLoggingUtility.warning(
            'PrayerTimeService',
            'getPrayerTimesForDate',
            'API unavailable, using cached data: ${e.message}',
          );
          return cached;
        }
      }
      rethrow;
    }
  }

  /// Clean up old cached schedules to prevent database bloat.
  /// Keeps schedules for the last 7 days.
  Future<void> cleanupOldSchedules() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      await _repository.deleteOldSchedules(cutoffDate);

      CoreLoggingUtility.info(
        'PrayerTimeService',
        'cleanupOldSchedules',
        'Cleaned up schedules older than $cutoffDate',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerTimeService',
        'cleanupOldSchedules',
        'Failed to cleanup old schedules: $e',
      );
    }
  }

  /// Check if the service can reach the API.
  /// Useful for displaying connectivity status to the user.
  Future<bool> isApiReachable() async {
    try {
      final uri = Uri.parse('$_baseUrl/currentTime?zone=UTC');
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
