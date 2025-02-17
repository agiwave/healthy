class HealthRecord {
  final int? id;
  final String type; // 'blood_pressure' 或 'heart_rate'
  final double value;
  final double? systolic; // 收缩压
  final double? diastolic; // 舒张压
  final DateTime timestamp;

  HealthRecord({
    this.id,
    required this.type,
    required this.value,
    this.systolic,
    this.diastolic,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      type: map['type'],
      value: map['value'],
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 