enum ReminderType {
  notification,
  fullScreenAlarm;

  String toMap() {
    return name;
  }

  static ReminderType fromMap(String value) {
    return ReminderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReminderType.notification,
    );
  }
}
