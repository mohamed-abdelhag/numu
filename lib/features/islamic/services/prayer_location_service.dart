import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Represents geographic coordinates.
class LocationCoordinates {
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'LocationCoordinates(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Service for handling location permissions and coordinate retrieval
/// for the Islamic Prayer System.
///
/// **Validates: Requirements 1.3, 11.1, 11.2, 11.3, 11.4, 11.5**
class PrayerLocationService {
  static final PrayerLocationService _instance =
      PrayerLocationService._internal();
  factory PrayerLocationService() => _instance;
  PrayerLocationService._internal();

  /// Earth's radius in kilometers for Haversine calculation.
  static const double _earthRadiusKm = 6371.0;

  /// Threshold distance in kilometers for significant location change.
  static const double locationChangeThresholdKm = 10.0;

  /// Check if location permission is granted.
  ///
  /// **Validates: Requirements 11.4**
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      final hasPermission = status.isGranted;

      CoreLoggingUtility.info(
        'PrayerLocationService',
        'hasLocationPermission',
        'Location permission status: $status, granted: $hasPermission',
      );

      return hasPermission;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'hasLocationPermission',
        'Failed to check location permission: $e',
      );
      return false;
    }
  }

  /// Check if location permission is permanently denied.
  ///
  /// **Validates: Requirements 11.2**
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'isLocationPermissionPermanentlyDenied',
        'Failed to check permanent denial status: $e',
      );
      return false;
    }
  }

  /// Request location permission using the platform-appropriate method.
  ///
  /// **Validates: Requirements 11.1**
  Future<bool> requestLocationPermission() async {
    try {
      // First check if already granted
      final currentStatus = await Permission.location.status;
      if (currentStatus.isGranted) {
        CoreLoggingUtility.info(
          'PrayerLocationService',
          'requestLocationPermission',
          'Location permission already granted',
        );
        return true;
      }

      // Request permission
      final status = await Permission.location.request();
      final granted = status.isGranted;

      CoreLoggingUtility.info(
        'PrayerLocationService',
        'requestLocationPermission',
        'Location permission request result: $status, granted: $granted',
      );

      return granted;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'requestLocationPermission',
        'Failed to request location permission: $e',
      );
      return false;
    }
  }

  /// Get current location coordinates.
  /// Returns null if permission is not granted or location is unavailable.
  ///
  /// **Validates: Requirements 11.3**
  Future<LocationCoordinates?> getCurrentLocation() async {
    try {
      // Check permission first
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        CoreLoggingUtility.warning(
          'PrayerLocationService',
          'getCurrentLocation',
          'Location permission not granted',
        );
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CoreLoggingUtility.warning(
          'PrayerLocationService',
          'getCurrentLocation',
          'Location services are disabled',
        );
        return null;
      }

      // Get current position with reasonable accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final coordinates = LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      CoreLoggingUtility.info(
        'PrayerLocationService',
        'getCurrentLocation',
        'Got location: $coordinates',
      );

      return coordinates;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'getCurrentLocation',
        'Failed to get current location: $e',
      );
      return null;
    }
  }

  /// Check if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'isLocationServiceEnabled',
        'Failed to check location service status: $e',
      );
      return false;
    }
  }

  /// Open app settings for the user to grant location permission.
  ///
  /// **Validates: Requirements 11.2**
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'openLocationSettings',
        'Failed to open app settings: $e',
      );
      return false;
    }
  }

  /// Check if location has changed significantly (>10km) from the last known location.
  ///
  /// **Validates: Requirements 1.3**
  Future<bool> hasLocationChanged(double lastLat, double lastLng) async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        CoreLoggingUtility.warning(
          'PrayerLocationService',
          'hasLocationChanged',
          'Could not get current location to compare',
        );
        return false;
      }

      final distance = calculateHaversineDistance(
        lastLat,
        lastLng,
        currentLocation.latitude,
        currentLocation.longitude,
      );

      final hasChanged = distance > locationChangeThresholdKm;

      CoreLoggingUtility.info(
        'PrayerLocationService',
        'hasLocationChanged',
        'Distance from last location: ${distance.toStringAsFixed(2)} km, '
            'threshold: $locationChangeThresholdKm km, changed: $hasChanged',
      );

      return hasChanged;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerLocationService',
        'hasLocationChanged',
        'Failed to check location change: $e',
      );
      return false;
    }
  }

  /// Calculate the Haversine distance between two geographic coordinates.
  /// Returns the distance in kilometers.
  ///
  /// The Haversine formula determines the great-circle distance between
  /// two points on a sphere given their longitudes and latitudes.
  ///
  /// **Validates: Requirements 1.3**
  static double calculateHaversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Convert degrees to radians
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final deltaLat = _degreesToRadians(lat2 - lat1);
    final deltaLng = _degreesToRadians(lng2 - lng1);

    // Haversine formula
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Convert degrees to radians.
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Check if a distance exceeds the location change threshold.
  ///
  /// **Validates: Requirements 1.3**
  static bool exceedsLocationChangeThreshold(double distanceKm) {
    return distanceKm > locationChangeThresholdKm;
  }
}
