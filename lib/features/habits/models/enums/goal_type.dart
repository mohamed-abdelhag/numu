enum GoalType {
  none,
  minimum,
  maximum;

  String toJson() => name;

  static GoalType fromJson(String json) {
    return GoalType.values.firstWhere((e) => e.name == json);
  }
}
