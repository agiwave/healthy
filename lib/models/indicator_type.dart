class IndicatorType {
  final int? id;
  final String code;  // 唯一标识符
  final String name;  // 显示名称
  final String unit;  // 单位
  final bool isMultiValue;  // 是否有多个值（如血压）
  final String value1Name;    // 新增
  final String? value2Name;   // 重命名

  IndicatorType({
    this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.isMultiValue,
    required this.value1Name,  // 新增
    this.value2Name,          // 重命名
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'unit': unit,
      'is_multi_value': isMultiValue ? 1 : 0,
      'value1_name': value1Name,     // 新增
      'value2_name': value2Name,     // 重命名
    };
  }

  factory IndicatorType.fromMap(Map<String, dynamic> map) {
    return IndicatorType(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      unit: map['unit'],
      isMultiValue: map['is_multi_value'] == 1,
      value1Name: map['value1_name'],    // 新增
      value2Name: map['value2_name'],    // 重命名
    );
  }
} 