class BusinessHours {
  final Map<String, DaySchedule> schedule;

  BusinessHours({
    required this.schedule,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {};
    schedule.forEach((key, value) {
      data[key] = value.toMap();
    });
    return {
      'schedule': data,
    };
  }

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    final Map<String, DaySchedule> scheduleData = {};
    final scheduleMap = map['schedule'] as Map<String, dynamic>?;
    if (scheduleMap != null) {
      scheduleMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          scheduleData[key] = DaySchedule.fromMap(value);
        } else {
          print('Warning: Invalid schedule data for day $key: $value');
        }
      });
    }
    return BusinessHours(schedule: scheduleData);
  }
}

class DaySchedule {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  DaySchedule({
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isOpen: map['isOpen'] as bool? ?? false,
      openTime: map['openTime'] as String?,
      closeTime: map['closeTime'] as String?,
    );
  }
} 