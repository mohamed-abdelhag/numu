import 'dart:math';
import 'package:glados/glados.dart';
import 'package:numu/features/islamic/services/prayer_location_service.dart';

/// Custom generators for location tests
extension LocationGenerators on Any {
  /// Generator for valid latitude values (-90 to 90)
  Generator<double> get latitude => doubleInRange(-90.0, 90.0);

  /// Generator for valid longitude values (-180 to 180)
  Generator<double> get longitude => doubleInRange(-180.0, 180.0);

  /// Generator for a coordinate pair
  Generator<LocationCoordinates> get coordinates =>
      latitude.bind((lat) => longitude.map((lng) => LocationCoordinates(
            latitude: lat,
            longitude: lng,
          )));
}

/// Reference implementation of Haversine distance for verification.
/// This is an independent implementation to verify the service's calculation.
double referenceHaversineDistance(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadiusKm = 6371.0;

  final lat1Rad = lat1 * (pi / 180.0);
  final lat2Rad = lat2 * (pi / 180.0);
  final deltaLat = (lat2 - lat1) * (pi / 180.0);
  final deltaLng = (lng2 - lng1) * (pi / 180.0);

  final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

void main() {
  group('PrayerLocationService Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 3: Location Change Detection**
    /// **Validates: Requirements 1.3**
    ///
    /// *For any* two coordinate pairs (lat1, lng1) and (lat2, lng2), the location
    /// change detection function SHALL return true if and only if the Haversine
    /// distance between the points exceeds 10 kilometers.
    Glados2(any.coordinates, any.coordinates).test(
      'Property 3: Location Change Detection - returns true iff distance > 10km',
      (coord1, coord2) {
        // Calculate distance using the service
        final serviceDistance = PrayerLocationService.calculateHaversineDistance(
          coord1.latitude,
          coord1.longitude,
          coord2.latitude,
          coord2.longitude,
        );

        // Check if it exceeds threshold using the service
        final exceedsThreshold =
            PrayerLocationService.exceedsLocationChangeThreshold(serviceDistance);

        // Verify the threshold check is correct
        final expectedExceedsThreshold =
            serviceDistance > PrayerLocationService.locationChangeThresholdKm;

        expect(
          exceedsThreshold,
          equals(expectedExceedsThreshold),
          reason: 'exceedsLocationChangeThreshold should return true iff '
              'distance ($serviceDistance km) > threshold '
              '(${PrayerLocationService.locationChangeThresholdKm} km)',
        );
      },
    );

    /// Additional property: Haversine distance calculation is consistent
    /// with reference implementation
    Glados2(any.coordinates, any.coordinates).test(
      'Haversine distance calculation matches reference implementation',
      (coord1, coord2) {
        final serviceDistance = PrayerLocationService.calculateHaversineDistance(
          coord1.latitude,
          coord1.longitude,
          coord2.latitude,
          coord2.longitude,
        );

        final referenceDistance = referenceHaversineDistance(
          coord1.latitude,
          coord1.longitude,
          coord2.latitude,
          coord2.longitude,
        );

        // Allow small floating point tolerance
        expect(
          serviceDistance,
          closeTo(referenceDistance, 0.0001),
          reason: 'Service distance should match reference implementation',
        );
      },
    );

    /// Property: Distance is always non-negative
    Glados2(any.coordinates, any.coordinates).test(
      'Haversine distance is always non-negative',
      (coord1, coord2) {
        final distance = PrayerLocationService.calculateHaversineDistance(
          coord1.latitude,
          coord1.longitude,
          coord2.latitude,
          coord2.longitude,
        );

        expect(
          distance,
          greaterThanOrEqualTo(0),
          reason: 'Distance should never be negative',
        );
      },
    );

    /// Property: Distance from a point to itself is zero
    Glados(any.coordinates).test(
      'Distance from a point to itself is zero',
      (coord) {
        final distance = PrayerLocationService.calculateHaversineDistance(
          coord.latitude,
          coord.longitude,
          coord.latitude,
          coord.longitude,
        );

        expect(
          distance,
          closeTo(0.0, 0.0001),
          reason: 'Distance from a point to itself should be zero',
        );
      },
    );

    /// Property: Distance is symmetric (A to B equals B to A)
    Glados2(any.coordinates, any.coordinates).test(
      'Haversine distance is symmetric',
      (coord1, coord2) {
        final distanceAtoB = PrayerLocationService.calculateHaversineDistance(
          coord1.latitude,
          coord1.longitude,
          coord2.latitude,
          coord2.longitude,
        );

        final distanceBtoA = PrayerLocationService.calculateHaversineDistance(
          coord2.latitude,
          coord2.longitude,
          coord1.latitude,
          coord1.longitude,
        );

        expect(
          distanceAtoB,
          closeTo(distanceBtoA, 0.0001),
          reason: 'Distance A to B should equal distance B to A',
        );
      },
    );
  });

  group('PrayerLocationService Unit Tests', () {
    test('Known distance: Mecca to Medina is approximately 340 km', () {
      // Mecca coordinates
      const meccaLat = 21.4225;
      const meccaLng = 39.8262;

      // Medina coordinates
      const medinaLat = 24.5247;
      const medinaLng = 39.5692;

      final distance = PrayerLocationService.calculateHaversineDistance(
        meccaLat,
        meccaLng,
        medinaLat,
        medinaLng,
      );

      // Known distance is approximately 340 km
      expect(distance, closeTo(340, 20));
    });

    test('Known distance: New York to Los Angeles is approximately 3940 km', () {
      // New York coordinates
      const nyLat = 40.7128;
      const nyLng = -74.0060;

      // Los Angeles coordinates
      const laLat = 34.0522;
      const laLng = -118.2437;

      final distance = PrayerLocationService.calculateHaversineDistance(
        nyLat,
        nyLng,
        laLat,
        laLng,
      );

      // Known distance is approximately 3940 km
      expect(distance, closeTo(3940, 50));
    });

    test('Distance less than 10km should not exceed threshold', () {
      // Two points approximately 5 km apart
      const lat1 = 40.7128;
      const lng1 = -74.0060;
      const lat2 = 40.7580; // ~5km north
      const lng2 = -74.0060;

      final distance = PrayerLocationService.calculateHaversineDistance(
        lat1,
        lng1,
        lat2,
        lng2,
      );

      expect(distance, lessThan(10));
      expect(
        PrayerLocationService.exceedsLocationChangeThreshold(distance),
        isFalse,
      );
    });

    test('Distance greater than 10km should exceed threshold', () {
      // Two points approximately 15 km apart
      const lat1 = 40.7128;
      const lng1 = -74.0060;
      const lat2 = 40.8500; // ~15km north
      const lng2 = -74.0060;

      final distance = PrayerLocationService.calculateHaversineDistance(
        lat1,
        lng1,
        lat2,
        lng2,
      );

      expect(distance, greaterThan(10));
      expect(
        PrayerLocationService.exceedsLocationChangeThreshold(distance),
        isTrue,
      );
    });

    test('LocationCoordinates equality works correctly', () {
      const coord1 = LocationCoordinates(latitude: 40.7128, longitude: -74.0060);
      const coord2 = LocationCoordinates(latitude: 40.7128, longitude: -74.0060);
      const coord3 = LocationCoordinates(latitude: 34.0522, longitude: -118.2437);

      expect(coord1, equals(coord2));
      expect(coord1, isNot(equals(coord3)));
    });

    test('LocationCoordinates toString provides readable output', () {
      const coord = LocationCoordinates(latitude: 40.7128, longitude: -74.0060);
      expect(coord.toString(), contains('40.7128'));
      expect(coord.toString(), contains('-74.006'));
    });

    test('Threshold constant is 10 km', () {
      expect(PrayerLocationService.locationChangeThresholdKm, equals(10.0));
    });
  });
}
