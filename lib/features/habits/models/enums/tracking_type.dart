enum TrackingType {
  binary,
  value;

  String toJson() => name;

  static TrackingType fromJson(String json) {
    return TrackingType.values.firstWhere((e) => e.name == json);
  }
}
