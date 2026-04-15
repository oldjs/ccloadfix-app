import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/auth_token.dart';

// Token 列表
final tokenListProvider = FutureProvider<List<AuthToken>>((ref) async {
  final response = await DioClient.instance.get(ApiEndpoints.authTokens);
  final data = response.data as Map<String, dynamic>;
  final list = (data['tokens'] as List?) ?? [];
  return list.map((e) => AuthToken.fromJson(e)).toList();
});

// Token 操作
class TokenActions {
  // 创建 Token
  static Future<AuthToken> create({required String description, List<String>? allowedModels, double? costLimitUsd}) async {
    final body = <String, dynamic>{'description': description};
    if (allowedModels != null && allowedModels.isNotEmpty) body['allowed_models'] = allowedModels;
    if (costLimitUsd != null) body['cost_limit_usd'] = costLimitUsd;

    final response = await DioClient.instance.post(ApiEndpoints.authTokens, data: body);
    return AuthToken.fromJson(response.data);
  }

  // 更新 Token
  static Future<void> update(int id, {bool? isActive, String? description, double? costLimitUsd}) async {
    final body = <String, dynamic>{};
    if (isActive != null) body['is_active'] = isActive;
    if (description != null) body['description'] = description;
    if (costLimitUsd != null) body['cost_limit_usd'] = costLimitUsd;

    await DioClient.instance.put(ApiEndpoints.authToken(id), data: body);
  }

  // 删除 Token
  static Future<void> delete(int id) async {
    await DioClient.instance.delete(ApiEndpoints.authToken(id));
  }
}
