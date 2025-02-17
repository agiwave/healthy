class IndicatorType {
  final int? id;
  final String code;  // 唯一标识符
  final String name;  // 显示名称
  final String unit;  // 单位
  final bool isMultiValue;  // 是否有多个值（如血压）
  final String majorValueName;    // 新增
  final String? minorValueName;   // 重命名

  IndicatorType({
    this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.isMultiValue,
    required this.majorValueName,  // 新增
    this.minorValueName,          // 重命名
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'unit': unit,
      'is_multi_value': isMultiValue ? 1 : 0,
      'major_value_name': majorValueName,     // 新增
      'minor_value_name': minorValueName,     // 重命名
    };
  }

  factory IndicatorType.fromMap(Map<String, dynamic> map) {
    return IndicatorType(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      unit: map['unit'],
      isMultiValue: map['is_multi_value'] == 1,
      majorValueName: map['major_value_name'],    // 新增
      minorValueName: map['minor_value_name'],    // 重命名
    );
  }
} 