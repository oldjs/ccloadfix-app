// JSON 值的类型安全转换
// Go 后端同一个字段可能返回 int / double / String，Dart 侧需要统一兜底

/// 安全转 int，null/double/String 都能处理
int safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// 安全转 int?，null 就返回 null
int? safeIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
