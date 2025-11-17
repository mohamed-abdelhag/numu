enum ActiveDaysMode {
  all,
  selected;

  String toJson() => name;

  static ActiveDaysMode fromJson(String json) {
    return ActiveDaysMode.values.firstWhere((e) => e.name == json);
  }
}
