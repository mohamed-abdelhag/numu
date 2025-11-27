/// Model representing a city with coordinates for prayer time calculations.
class City {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String timezone;

  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  /// Display name including country
  String get displayName => '$name, $country';

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] as String,
      name: map['name'] as String,
      country: map['country'] as String,
      countryCode: map['country_code'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timezone: map['timezone'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'country_code': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'City($displayName)';
}

/// List of major world cities for manual selection.
/// Organized by region for easier browsing.
class MajorCities {
  MajorCities._();

  /// All available cities
  static List<City> get all => [
    ...middleEast,
    ...northAfrica,
    ...europe,
    ...asia,
    ...northAmerica,
    ...southAmerica,
    ...oceania,
    ...africa,
  ];

  /// Middle East cities
  static const List<City> middleEast = [
    City(
      id: 'mecca',
      name: 'Mecca',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      latitude: 21.4225,
      longitude: 39.8262,
      timezone: 'Asia/Riyadh',
    ),
    City(
      id: 'medina',
      name: 'Medina',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      latitude: 24.5247,
      longitude: 39.5692,
      timezone: 'Asia/Riyadh',
    ),
    City(
      id: 'riyadh',
      name: 'Riyadh',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      latitude: 24.7136,
      longitude: 46.6753,
      timezone: 'Asia/Riyadh',
    ),
    City(
      id: 'jeddah',
      name: 'Jeddah',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      latitude: 21.4858,
      longitude: 39.1925,
      timezone: 'Asia/Riyadh',
    ),
    City(
      id: 'dubai',
      name: 'Dubai',
      country: 'United Arab Emirates',
      countryCode: 'AE',
      latitude: 25.2048,
      longitude: 55.2708,
      timezone: 'Asia/Dubai',
    ),
    City(
      id: 'abu_dhabi',
      name: 'Abu Dhabi',
      country: 'United Arab Emirates',
      countryCode: 'AE',
      latitude: 24.4539,
      longitude: 54.3773,
      timezone: 'Asia/Dubai',
    ),
    City(
      id: 'doha',
      name: 'Doha',
      country: 'Qatar',
      countryCode: 'QA',
      latitude: 25.2854,
      longitude: 51.5310,
      timezone: 'Asia/Qatar',
    ),
    City(
      id: 'kuwait_city',
      name: 'Kuwait City',
      country: 'Kuwait',
      countryCode: 'KW',
      latitude: 29.3759,
      longitude: 47.9774,
      timezone: 'Asia/Kuwait',
    ),
    City(
      id: 'manama',
      name: 'Manama',
      country: 'Bahrain',
      countryCode: 'BH',
      latitude: 26.2285,
      longitude: 50.5860,
      timezone: 'Asia/Bahrain',
    ),
    City(
      id: 'muscat',
      name: 'Muscat',
      country: 'Oman',
      countryCode: 'OM',
      latitude: 23.5880,
      longitude: 58.3829,
      timezone: 'Asia/Muscat',
    ),
    City(
      id: 'amman',
      name: 'Amman',
      country: 'Jordan',
      countryCode: 'JO',
      latitude: 31.9454,
      longitude: 35.9284,
      timezone: 'Asia/Amman',
    ),
    City(
      id: 'beirut',
      name: 'Beirut',
      country: 'Lebanon',
      countryCode: 'LB',
      latitude: 33.8938,
      longitude: 35.5018,
      timezone: 'Asia/Beirut',
    ),
    City(
      id: 'damascus',
      name: 'Damascus',
      country: 'Syria',
      countryCode: 'SY',
      latitude: 33.5138,
      longitude: 36.2765,
      timezone: 'Asia/Damascus',
    ),
    City(
      id: 'baghdad',
      name: 'Baghdad',
      country: 'Iraq',
      countryCode: 'IQ',
      latitude: 33.3152,
      longitude: 44.3661,
      timezone: 'Asia/Baghdad',
    ),
    City(
      id: 'tehran',
      name: 'Tehran',
      country: 'Iran',
      countryCode: 'IR',
      latitude: 35.6892,
      longitude: 51.3890,
      timezone: 'Asia/Tehran',
    ),
    City(
      id: 'jerusalem',
      name: 'Jerusalem',
      country: 'Palestine',
      countryCode: 'PS',
      latitude: 31.7683,
      longitude: 35.2137,
      timezone: 'Asia/Jerusalem',
    ),
    City(
      id: 'sanaa',
      name: 'Sanaa',
      country: 'Yemen',
      countryCode: 'YE',
      latitude: 15.3694,
      longitude: 44.1910,
      timezone: 'Asia/Aden',
    ),
  ];

  /// North Africa cities
  static const List<City> northAfrica = [
    City(
      id: 'cairo',
      name: 'Cairo',
      country: 'Egypt',
      countryCode: 'EG',
      latitude: 30.0444,
      longitude: 31.2357,
      timezone: 'Africa/Cairo',
    ),
    City(
      id: 'alexandria',
      name: 'Alexandria',
      country: 'Egypt',
      countryCode: 'EG',
      latitude: 31.2001,
      longitude: 29.9187,
      timezone: 'Africa/Cairo',
    ),
    City(
      id: 'tripoli',
      name: 'Tripoli',
      country: 'Libya',
      countryCode: 'LY',
      latitude: 32.8872,
      longitude: 13.1913,
      timezone: 'Africa/Tripoli',
    ),
    City(
      id: 'tunis',
      name: 'Tunis',
      country: 'Tunisia',
      countryCode: 'TN',
      latitude: 36.8065,
      longitude: 10.1815,
      timezone: 'Africa/Tunis',
    ),
    City(
      id: 'algiers',
      name: 'Algiers',
      country: 'Algeria',
      countryCode: 'DZ',
      latitude: 36.7538,
      longitude: 3.0588,
      timezone: 'Africa/Algiers',
    ),
    City(
      id: 'casablanca',
      name: 'Casablanca',
      country: 'Morocco',
      countryCode: 'MA',
      latitude: 33.5731,
      longitude: -7.5898,
      timezone: 'Africa/Casablanca',
    ),
    City(
      id: 'rabat',
      name: 'Rabat',
      country: 'Morocco',
      countryCode: 'MA',
      latitude: 34.0209,
      longitude: -6.8416,
      timezone: 'Africa/Casablanca',
    ),
    City(
      id: 'khartoum',
      name: 'Khartoum',
      country: 'Sudan',
      countryCode: 'SD',
      latitude: 15.5007,
      longitude: 32.5599,
      timezone: 'Africa/Khartoum',
    ),
  ];

  /// Europe cities
  static const List<City> europe = [
    City(
      id: 'london',
      name: 'London',
      country: 'United Kingdom',
      countryCode: 'GB',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
    ),
    City(
      id: 'paris',
      name: 'Paris',
      country: 'France',
      countryCode: 'FR',
      latitude: 48.8566,
      longitude: 2.3522,
      timezone: 'Europe/Paris',
    ),
    City(
      id: 'berlin',
      name: 'Berlin',
      country: 'Germany',
      countryCode: 'DE',
      latitude: 52.5200,
      longitude: 13.4050,
      timezone: 'Europe/Berlin',
    ),
    City(
      id: 'amsterdam',
      name: 'Amsterdam',
      country: 'Netherlands',
      countryCode: 'NL',
      latitude: 52.3676,
      longitude: 4.9041,
      timezone: 'Europe/Amsterdam',
    ),
    City(
      id: 'brussels',
      name: 'Brussels',
      country: 'Belgium',
      countryCode: 'BE',
      latitude: 50.8503,
      longitude: 4.3517,
      timezone: 'Europe/Brussels',
    ),
    City(
      id: 'vienna',
      name: 'Vienna',
      country: 'Austria',
      countryCode: 'AT',
      latitude: 48.2082,
      longitude: 16.3738,
      timezone: 'Europe/Vienna',
    ),
    City(
      id: 'rome',
      name: 'Rome',
      country: 'Italy',
      countryCode: 'IT',
      latitude: 41.9028,
      longitude: 12.4964,
      timezone: 'Europe/Rome',
    ),
    City(
      id: 'madrid',
      name: 'Madrid',
      country: 'Spain',
      countryCode: 'ES',
      latitude: 40.4168,
      longitude: -3.7038,
      timezone: 'Europe/Madrid',
    ),
    City(
      id: 'istanbul',
      name: 'Istanbul',
      country: 'Turkey',
      countryCode: 'TR',
      latitude: 41.0082,
      longitude: 28.9784,
      timezone: 'Europe/Istanbul',
    ),
    City(
      id: 'ankara',
      name: 'Ankara',
      country: 'Turkey',
      countryCode: 'TR',
      latitude: 39.9334,
      longitude: 32.8597,
      timezone: 'Europe/Istanbul',
    ),
    City(
      id: 'moscow',
      name: 'Moscow',
      country: 'Russia',
      countryCode: 'RU',
      latitude: 55.7558,
      longitude: 37.6173,
      timezone: 'Europe/Moscow',
    ),
    City(
      id: 'stockholm',
      name: 'Stockholm',
      country: 'Sweden',
      countryCode: 'SE',
      latitude: 59.3293,
      longitude: 18.0686,
      timezone: 'Europe/Stockholm',
    ),
    City(
      id: 'oslo',
      name: 'Oslo',
      country: 'Norway',
      countryCode: 'NO',
      latitude: 59.9139,
      longitude: 10.7522,
      timezone: 'Europe/Oslo',
    ),
    City(
      id: 'copenhagen',
      name: 'Copenhagen',
      country: 'Denmark',
      countryCode: 'DK',
      latitude: 55.6761,
      longitude: 12.5683,
      timezone: 'Europe/Copenhagen',
    ),
  ];

  /// Asia cities
  static const List<City> asia = [
    City(
      id: 'karachi',
      name: 'Karachi',
      country: 'Pakistan',
      countryCode: 'PK',
      latitude: 24.8607,
      longitude: 67.0011,
      timezone: 'Asia/Karachi',
    ),
    City(
      id: 'lahore',
      name: 'Lahore',
      country: 'Pakistan',
      countryCode: 'PK',
      latitude: 31.5204,
      longitude: 74.3587,
      timezone: 'Asia/Karachi',
    ),
    City(
      id: 'islamabad',
      name: 'Islamabad',
      country: 'Pakistan',
      countryCode: 'PK',
      latitude: 33.6844,
      longitude: 73.0479,
      timezone: 'Asia/Karachi',
    ),
    City(
      id: 'dhaka',
      name: 'Dhaka',
      country: 'Bangladesh',
      countryCode: 'BD',
      latitude: 23.8103,
      longitude: 90.4125,
      timezone: 'Asia/Dhaka',
    ),
    City(
      id: 'mumbai',
      name: 'Mumbai',
      country: 'India',
      countryCode: 'IN',
      latitude: 19.0760,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
    ),
    City(
      id: 'delhi',
      name: 'Delhi',
      country: 'India',
      countryCode: 'IN',
      latitude: 28.7041,
      longitude: 77.1025,
      timezone: 'Asia/Kolkata',
    ),
    City(
      id: 'hyderabad_india',
      name: 'Hyderabad',
      country: 'India',
      countryCode: 'IN',
      latitude: 17.3850,
      longitude: 78.4867,
      timezone: 'Asia/Kolkata',
    ),
    City(
      id: 'jakarta',
      name: 'Jakarta',
      country: 'Indonesia',
      countryCode: 'ID',
      latitude: -6.2088,
      longitude: 106.8456,
      timezone: 'Asia/Jakarta',
    ),
    City(
      id: 'kuala_lumpur',
      name: 'Kuala Lumpur',
      country: 'Malaysia',
      countryCode: 'MY',
      latitude: 3.1390,
      longitude: 101.6869,
      timezone: 'Asia/Kuala_Lumpur',
    ),
    City(
      id: 'singapore',
      name: 'Singapore',
      country: 'Singapore',
      countryCode: 'SG',
      latitude: 1.3521,
      longitude: 103.8198,
      timezone: 'Asia/Singapore',
    ),
    City(
      id: 'bangkok',
      name: 'Bangkok',
      country: 'Thailand',
      countryCode: 'TH',
      latitude: 13.7563,
      longitude: 100.5018,
      timezone: 'Asia/Bangkok',
    ),
    City(
      id: 'tokyo',
      name: 'Tokyo',
      country: 'Japan',
      countryCode: 'JP',
      latitude: 35.6762,
      longitude: 139.6503,
      timezone: 'Asia/Tokyo',
    ),
    City(
      id: 'beijing',
      name: 'Beijing',
      country: 'China',
      countryCode: 'CN',
      latitude: 39.9042,
      longitude: 116.4074,
      timezone: 'Asia/Shanghai',
    ),
    City(
      id: 'shanghai',
      name: 'Shanghai',
      country: 'China',
      countryCode: 'CN',
      latitude: 31.2304,
      longitude: 121.4737,
      timezone: 'Asia/Shanghai',
    ),
    City(
      id: 'hong_kong',
      name: 'Hong Kong',
      country: 'China',
      countryCode: 'HK',
      latitude: 22.3193,
      longitude: 114.1694,
      timezone: 'Asia/Hong_Kong',
    ),
    City(
      id: 'seoul',
      name: 'Seoul',
      country: 'South Korea',
      countryCode: 'KR',
      latitude: 37.5665,
      longitude: 126.9780,
      timezone: 'Asia/Seoul',
    ),
    City(
      id: 'kabul',
      name: 'Kabul',
      country: 'Afghanistan',
      countryCode: 'AF',
      latitude: 34.5553,
      longitude: 69.2075,
      timezone: 'Asia/Kabul',
    ),
    City(
      id: 'tashkent',
      name: 'Tashkent',
      country: 'Uzbekistan',
      countryCode: 'UZ',
      latitude: 41.2995,
      longitude: 69.2401,
      timezone: 'Asia/Tashkent',
    ),
  ];

  /// North America cities
  static const List<City> northAmerica = [
    City(
      id: 'new_york',
      name: 'New York',
      country: 'United States',
      countryCode: 'US',
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: 'America/New_York',
    ),
    City(
      id: 'los_angeles',
      name: 'Los Angeles',
      country: 'United States',
      countryCode: 'US',
      latitude: 34.0522,
      longitude: -118.2437,
      timezone: 'America/Los_Angeles',
    ),
    City(
      id: 'chicago',
      name: 'Chicago',
      country: 'United States',
      countryCode: 'US',
      latitude: 41.8781,
      longitude: -87.6298,
      timezone: 'America/Chicago',
    ),
    City(
      id: 'houston',
      name: 'Houston',
      country: 'United States',
      countryCode: 'US',
      latitude: 29.7604,
      longitude: -95.3698,
      timezone: 'America/Chicago',
    ),
    City(
      id: 'detroit',
      name: 'Detroit',
      country: 'United States',
      countryCode: 'US',
      latitude: 42.3314,
      longitude: -83.0458,
      timezone: 'America/Detroit',
    ),
    City(
      id: 'toronto',
      name: 'Toronto',
      country: 'Canada',
      countryCode: 'CA',
      latitude: 43.6532,
      longitude: -79.3832,
      timezone: 'America/Toronto',
    ),
    City(
      id: 'montreal',
      name: 'Montreal',
      country: 'Canada',
      countryCode: 'CA',
      latitude: 45.5017,
      longitude: -73.5673,
      timezone: 'America/Montreal',
    ),
    City(
      id: 'vancouver',
      name: 'Vancouver',
      country: 'Canada',
      countryCode: 'CA',
      latitude: 49.2827,
      longitude: -123.1207,
      timezone: 'America/Vancouver',
    ),
    City(
      id: 'mexico_city',
      name: 'Mexico City',
      country: 'Mexico',
      countryCode: 'MX',
      latitude: 19.4326,
      longitude: -99.1332,
      timezone: 'America/Mexico_City',
    ),
  ];

  /// South America cities
  static const List<City> southAmerica = [
    City(
      id: 'sao_paulo',
      name: 'São Paulo',
      country: 'Brazil',
      countryCode: 'BR',
      latitude: -23.5505,
      longitude: -46.6333,
      timezone: 'America/Sao_Paulo',
    ),
    City(
      id: 'rio_de_janeiro',
      name: 'Rio de Janeiro',
      country: 'Brazil',
      countryCode: 'BR',
      latitude: -22.9068,
      longitude: -43.1729,
      timezone: 'America/Sao_Paulo',
    ),
    City(
      id: 'buenos_aires',
      name: 'Buenos Aires',
      country: 'Argentina',
      countryCode: 'AR',
      latitude: -34.6037,
      longitude: -58.3816,
      timezone: 'America/Argentina/Buenos_Aires',
    ),
    City(
      id: 'bogota',
      name: 'Bogotá',
      country: 'Colombia',
      countryCode: 'CO',
      latitude: 4.7110,
      longitude: -74.0721,
      timezone: 'America/Bogota',
    ),
    City(
      id: 'lima',
      name: 'Lima',
      country: 'Peru',
      countryCode: 'PE',
      latitude: -12.0464,
      longitude: -77.0428,
      timezone: 'America/Lima',
    ),
    City(
      id: 'santiago',
      name: 'Santiago',
      country: 'Chile',
      countryCode: 'CL',
      latitude: -33.4489,
      longitude: -70.6693,
      timezone: 'America/Santiago',
    ),
  ];

  /// Oceania cities
  static const List<City> oceania = [
    City(
      id: 'sydney',
      name: 'Sydney',
      country: 'Australia',
      countryCode: 'AU',
      latitude: -33.8688,
      longitude: 151.2093,
      timezone: 'Australia/Sydney',
    ),
    City(
      id: 'melbourne',
      name: 'Melbourne',
      country: 'Australia',
      countryCode: 'AU',
      latitude: -37.8136,
      longitude: 144.9631,
      timezone: 'Australia/Melbourne',
    ),
    City(
      id: 'auckland',
      name: 'Auckland',
      country: 'New Zealand',
      countryCode: 'NZ',
      latitude: -36.8485,
      longitude: 174.7633,
      timezone: 'Pacific/Auckland',
    ),
  ];

  /// Sub-Saharan Africa cities
  static const List<City> africa = [
    City(
      id: 'lagos',
      name: 'Lagos',
      country: 'Nigeria',
      countryCode: 'NG',
      latitude: 6.5244,
      longitude: 3.3792,
      timezone: 'Africa/Lagos',
    ),
    City(
      id: 'abuja',
      name: 'Abuja',
      country: 'Nigeria',
      countryCode: 'NG',
      latitude: 9.0765,
      longitude: 7.3986,
      timezone: 'Africa/Lagos',
    ),
    City(
      id: 'nairobi',
      name: 'Nairobi',
      country: 'Kenya',
      countryCode: 'KE',
      latitude: -1.2921,
      longitude: 36.8219,
      timezone: 'Africa/Nairobi',
    ),
    City(
      id: 'johannesburg',
      name: 'Johannesburg',
      country: 'South Africa',
      countryCode: 'ZA',
      latitude: -26.2041,
      longitude: 28.0473,
      timezone: 'Africa/Johannesburg',
    ),
    City(
      id: 'cape_town',
      name: 'Cape Town',
      country: 'South Africa',
      countryCode: 'ZA',
      latitude: -33.9249,
      longitude: 18.4241,
      timezone: 'Africa/Johannesburg',
    ),
    City(
      id: 'addis_ababa',
      name: 'Addis Ababa',
      country: 'Ethiopia',
      countryCode: 'ET',
      latitude: 8.9806,
      longitude: 38.7578,
      timezone: 'Africa/Addis_Ababa',
    ),
    City(
      id: 'dar_es_salaam',
      name: 'Dar es Salaam',
      country: 'Tanzania',
      countryCode: 'TZ',
      latitude: -6.7924,
      longitude: 39.2083,
      timezone: 'Africa/Dar_es_Salaam',
    ),
    City(
      id: 'mogadishu',
      name: 'Mogadishu',
      country: 'Somalia',
      countryCode: 'SO',
      latitude: 2.0469,
      longitude: 45.3182,
      timezone: 'Africa/Mogadishu',
    ),
    City(
      id: 'dakar',
      name: 'Dakar',
      country: 'Senegal',
      countryCode: 'SN',
      latitude: 14.7167,
      longitude: -17.4677,
      timezone: 'Africa/Dakar',
    ),
  ];

  /// Search cities by name
  static List<City> search(String query) {
    if (query.isEmpty) return all;
    final lowerQuery = query.toLowerCase();
    return all.where((city) {
      return city.name.toLowerCase().contains(lowerQuery) ||
          city.country.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get city by ID
  static City? getById(String id) {
    try {
      return all.firstWhere((city) => city.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get cities grouped by region
  static Map<String, List<City>> get byRegion => {
    'Middle East': middleEast,
    'North Africa': northAfrica,
    'Sub-Saharan Africa': africa,
    'Europe': europe,
    'Asia': asia,
    'North America': northAmerica,
    'South America': southAmerica,
    'Oceania': oceania,
  };
}
