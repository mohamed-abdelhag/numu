enum TrackingType {
  binary,
  value,
  timed;

  String toJson() => name;

  static TrackingType fromJson(String json) {
    return TrackingType.values.firstWhere((e) => e.name == json);
  }
}
