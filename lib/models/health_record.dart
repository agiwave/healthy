class HealthRecord {
  final int? id;
  final String type;
  final double majorValue;  // Updated field name
  final double? minorValue; // Updated field name
  final DateTime timestamp;

  HealthRecord({
    this.id,
    required this.type,
    required this.majorValue,  // Updated field name
    this.minorValue,          // Updated field name
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'major_value': majorValue,  // Updated field name
      'minor_value': minorValue,    // Updated field name
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      type: map['type'],
      majorValue: map['major_value'],  // Updated field name
      minorValue: map['minor_value'],    // Updated field name
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 