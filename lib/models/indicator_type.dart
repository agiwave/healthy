class IndicatorType {
  final int? id;
  final String code;  // 唯一标识符
  final String name;  // 显示名称
  final String unit;  // 单位
  final bool isMultiValue;  // 是否有多个值（如血压）
  final String? secondaryName;  // 第二个值的名称（如舒张压）

  IndicatorType({
    this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.isMultiValue = false,
    this.secondaryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'unit': unit,
      'is_multi_value': isMultiValue ? 1 : 0,
      'secondary_name': secondaryName,
    };
  }

  factory IndicatorType.fromMap(Map<String, dynamic> map) {
    return IndicatorType(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      unit: map['unit'],
      isMultiValue: map['is_multi_value'] == 1,
      secondaryName: map['secondary_name'],
    );
  }
} 