enum RequireMode {
  each,
  any,
  total;

  String toJson() => name;

  static RequireMode fromJson(String json) {
    return RequireMode.values.firstWhere((e) => e.name == json);
  }
}
