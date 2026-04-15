// 系统设置项
class Setting {
  final String key;
  final String value;
  final String defaultValue;
  final String valueType;
  final String description;
  final int? updatedAt; // Unix 秒时间戳，后端有返回这个字段

  Setting({
    required this.key,
    required this.value,
    required this.defaultValue,
    required this.valueType,
    required this.description,
    this.updatedAt,
  });

  // 当前值是否跟默认值不同
  bool get isModified => value != defaultValue;

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'] ?? '',
      value: json['value']?.toString() ?? '',
      defaultValue: json['default_value']?.toString() ?? '',
      valueType: json['value_type'] ?? 'string',
      description: json['description'] ?? '',
      updatedAt: json['updated_at'],
    );
  }
}
