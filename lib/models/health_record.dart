class HealthRecord {
  final int? id;
  final String type;
  final double value1;  // 主要值（血压时为收缩压，心率时为心率值）
  final double? value2; // 次要值（血压时为舒张压，心率时为null）
  final DateTime timestamp;

  HealthRecord({
    this.id,
    required this.type,
    required this.value1,
    this.value2,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value1': value1,
      'value2': value2,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      type: map['type'],
      value1: map['value1'],
      value2: map['value2'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 