enum TimeWindowMode {
  soft,
  hard;

  String toJson() => name;

  static TimeWindowMode fromJson(String json) {
    return TimeWindowMode.values.firstWhere((e) => e.name == json);
  }
}
