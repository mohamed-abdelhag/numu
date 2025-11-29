import 'enums/calculation_method.dart';
import 'enums/prayer_type.dart';
import 'city.dart';

/// Model representing user preferences for the Islamic Prayer System.
/// Includes enabled state, calculation method, time window, and reminder settings.
class PrayerSettings {
  final int? id;
  final bool isEnabled;
  final CalculationMethod calculationMethod;
  final int timeWindowMinutes; // Default 30
  final double? lastLatitude;
  final double? lastLongitude;
  final String? selectedCityId; // Manual city selection
  final bool useManualLocation; // Whether to use manual city instead of GPS
  final bool showNafilaAtHome; // Whether to show Nafila prayers on home screen
  final Map<PrayerType, bool> reminderEnabled;
  final Map<PrayerType, int> reminderOffsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrayerSettings({
    this.id,
    this.isEnabled = false,
    this.calculationMethod = CalculationMethod.muslimWorldLeague,
    this.timeWindowMinutes = 30,
    this.lastLatitude,
    this.lastLongitude,
    this.selectedCityId,
    this.useManualLocation = false,
    this.showNafilaAtHome = true,
    this.reminderEnabled = const {
      PrayerType.fajr: true,
      PrayerType.dhuhr: true,
      PrayerType.asr: true,
      PrayerType.maghrib: true,
      PrayerType.isha: true,
    },
    this.reminderOffsetMinutes = const {
      PrayerType.fajr: 15,
      PrayerType.dhuhr: 15,
      PrayerType.asr: 15,
      PrayerType.maghrib: 15,
      PrayerType.isha: 15,
    },
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Get the selected city if one is set
  City? get selectedCity {
    if (selectedCityId == null) return null;
    return MajorCities.getById(selectedCityId!);
  }
  
  /// Get the effective latitude (from manual city or GPS)
  double? get effectiveLatitude {
    if (useManualLocation && selectedCity != null) {
      return selectedCity!.latitude;
    }
    return lastLatitude;
  }
  
  /// Get the effective longitude (from manual city or GPS)
  double? get effectiveLongitude {
    if (useManualLocation && selectedCity != null) {
      return selectedCity!.longitude;
    }
    return lastLongitude;
  }
  
  /// Check if location is available (either from GPS or manual selection)
  bool get hasLocation {
    return effectiveLatitude != null && effectiveLongitude != null;
  }

  /// Create default settings
  factory PrayerSettings.defaults() {
    final now = DateTime.now();
    return PrayerSettings(
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PrayerSettings.fromMap(Map<String, dynamic> map) {
    return PrayerSettings(
      id: map['id'] as int?,
      isEnabled: (map['is_enabled'] as int) == 1,
      calculationMethod: CalculationMethod.fromJson(map['calculation_method'] as String),
      timeWindowMinutes: map['time_window_minutes'] as int,
      lastLatitude: map['last_latitude'] as double?,
      lastLongitude: map['last_longitude'] as double?,
      selectedCityId: map['selected_city_id'] as String?,
      useManualLocation: (map['use_manual_location'] as int?) == 1,
      showNafilaAtHome: (map['show_nafila_at_home'] as int?) == 1,
      reminderEnabled: {
        PrayerType.fajr: (map['reminder_fajr_enabled'] as int) == 1,
        PrayerType.dhuhr: (map['reminder_dhuhr_enabled'] as int) == 1,
        PrayerType.asr: (map['reminder_asr_enabled'] as int) == 1,
        PrayerType.maghrib: (map['reminder_maghrib_enabled'] as int) == 1,
        PrayerType.isha: (map['reminder_isha_enabled'] as int) == 1,
      },
      reminderOffsetMinutes: {
        PrayerType.fajr: map['reminder_fajr_offset'] as int,
        PrayerType.dhuhr: map['reminder_dhuhr_offset'] as int,
        PrayerType.asr: map['reminder_asr_offset'] as int,
        PrayerType.maghrib: map['reminder_maghrib_offset'] as int,
        PrayerType.isha: map['reminder_isha_offset'] as int,
      },
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'is_enabled': isEnabled ? 1 : 0,
      'calculation_method': calculationMethod.toJson(),
      'time_window_minutes': timeWindowMinutes,
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'selected_city_id': selectedCityId,
      'use_manual_location': useManualLocation ? 1 : 0,
      'show_nafila_at_home': showNafilaAtHome ? 1 : 0,
      'reminder_fajr_enabled': (reminderEnabled[PrayerType.fajr] ?? true) ? 1 : 0,
      'reminder_dhuhr_enabled': (reminderEnabled[PrayerType.dhuhr] ?? true) ? 1 : 0,
      'reminder_asr_enabled': (reminderEnabled[PrayerType.asr] ?? true) ? 1 : 0,
      'reminder_maghrib_enabled': (reminderEnabled[PrayerType.maghrib] ?? true) ? 1 : 0,
      'reminder_isha_enabled': (reminderEnabled[PrayerType.isha] ?? true) ? 1 : 0,
      'reminder_fajr_offset': reminderOffsetMinutes[PrayerType.fajr] ?? 15,
      'reminder_dhuhr_offset': reminderOffsetMinutes[PrayerType.dhuhr] ?? 15,
      'reminder_asr_offset': reminderOffsetMinutes[PrayerType.asr] ?? 15,
      'reminder_maghrib_offset': reminderOffsetMinutes[PrayerType.maghrib] ?? 15,
      'reminder_isha_offset': reminderOffsetMinutes[PrayerType.isha] ?? 15,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PrayerSettings copyWith({
    int? id,
    bool? isEnabled,
    CalculationMethod? calculationMethod,
    int? timeWindowMinutes,
    double? lastLatitude,
    double? lastLongitude,
    String? selectedCityId,
    bool? useManualLocation,
    bool? showNafilaAtHome,
    Map<PrayerType, bool>? reminderEnabled,
    Map<PrayerType, int>? reminderOffsetMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerSettings(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      timeWindowMinutes: timeWindowMinutes ?? this.timeWindowMinutes,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      useManualLocation: useManualLocation ?? this.useManualLocation,
      showNafilaAtHome: showNafilaAtHome ?? this.showNafilaAtHome,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if reminder is enabled for a specific prayer
  bool isReminderEnabled(PrayerType type) {
    return reminderEnabled[type] ?? true;
  }

  /// Get reminder offset for a specific prayer
  int getReminderOffset(PrayerType type) {
    return reminderOffsetMinutes[type] ?? 15;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrayerSettings) return false;
    
    // Compare maps manually
    bool mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (a[key] != b[key]) return false;
      }
      return true;
    }

    return other.id == id &&
        other.isEnabled == isEnabled &&
        other.calculationMethod == calculationMethod &&
        other.timeWindowMinutes == timeWindowMinutes &&
        other.lastLatitude == lastLatitude &&
        other.lastLongitude == lastLongitude &&
        other.selectedCityId == selectedCityId &&
        other.useManualLocation == useManualLocation &&
        other.showNafilaAtHome == showNafilaAtHome &&
        mapsEqual(other.reminderEnabled, reminderEnabled) &&
        mapsEqual(other.reminderOffsetMinutes, reminderOffsetMinutes) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isEnabled,
      calculationMethod,
      timeWindowMinutes,
      lastLatitude,
      lastLongitude,
      selectedCityId,
      useManualLocation,
      showNafilaAtHome,
      Object.hashAll(reminderEnabled.entries),
      Object.hashAll(reminderOffsetMinutes.entries),
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'PrayerSettings(id: $id, isEnabled: $isEnabled, calculationMethod: $calculationMethod, timeWindowMinutes: $timeWindowMinutes)';
  }
}
