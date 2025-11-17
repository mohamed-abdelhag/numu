enum Frequency {
  daily,
  weekly,
  monthly,
  custom;

  String toJson() => name;

  static Frequency fromJson(String json) {
    return Frequency.values.firstWhere((e) => e.name == json);
  }
}
