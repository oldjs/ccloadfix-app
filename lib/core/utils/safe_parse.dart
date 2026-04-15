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

/// 安全把时间戳字段转成 Unix 秒
/// Go 的 time.Time 序列化成 RFC3339 字符串，int64 就是 Unix 秒/毫秒
int safeTimestamp(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    // 先试 Unix 秒数字字符串
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    // 再试 RFC3339 / ISO8601 时间字符串
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
  }
  return 0;
}
