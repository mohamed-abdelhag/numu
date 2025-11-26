/// Mathematical methods used to determine prayer times.
/// Different methods are used in different regions based on local religious authorities.
enum CalculationMethod {
  muslimWorldLeague,
  isna,
  egyptian,
  ummAlQura,
  karachi,
  tehran,
  gulf;

  /// Human-readable display name for the calculation method.
  String get displayName => switch (this) {
    CalculationMethod.muslimWorldLeague => 'Muslim World League',
    CalculationMethod.isna => 'ISNA (North America)',
    CalculationMethod.egyptian => 'Egyptian General Authority',
    CalculationMethod.ummAlQura => 'Umm Al-Qura (Makkah)',
    CalculationMethod.karachi => 'University of Karachi',
    CalculationMethod.tehran => 'Institute of Geophysics, Tehran',
    CalculationMethod.gulf => 'Gulf Region',
  };

  /// API value used when calling prayer time APIs.
  int get apiValue => index;

  String toJson() => name;

  static CalculationMethod fromJson(String json) {
    return CalculationMethod.values.firstWhere((e) => e.name == json);
  }
}
