// 所有 API 路径常量，跟 ccLoadFix 后端一一对应
class ApiEndpoints {
  // --- 认证 ---
  static const login = '/login';
  static const logout = '/logout';

  // --- 仪表盘 ---
  static const publicSummary = '/public/summary';
  static const publicVersion = '/public/version';
  static const publicChannelTypes = '/public/channel-types';
  static const health = '/health';

  // --- 渠道 ---
  static const channels = '/admin/channels';
  static String channel(int id) => '/admin/channels/$id';
  static String channelKeys(int id) => '/admin/channels/$id/keys';
  static String channelKey(int id, int keyIndex) => '/admin/channels/$id/keys/$keyIndex';
  static String channelModels(int id) => '/admin/channels/$id/models';
  static String channelUrlStats(int id) => '/admin/channels/$id/url-stats';
  static String channelCooldown(int id) => '/admin/channels/$id/cooldown';
  static String channelKeyCooldown(int id, int keyIndex) =>
      '/admin/channels/$id/keys/$keyIndex/cooldown';
  static String channelTest(int id) => '/admin/channels/$id/test';
  static String channelTestUrl(int id) => '/admin/channels/$id/test-url';
  static String channelModelsFetch(int id) => '/admin/channels/$id/models/fetch';
  static String channelNoThinking(int id) => '/admin/channels/$id/no-thinking';
  static const channelsBatchPriority = '/admin/channels/batch-priority';
  static const channelsBatchEnabled = '/admin/channels/batch-enabled';
  static const channelsUrlSummary = '/admin/channels/url-summary';
  static const channelsExport = '/admin/channels/export';
  static const channelsImport = '/admin/channels/import';
  static const channelsModelsFetch = '/admin/channels/models/fetch';
  static const channelsModelsRefreshBatch = '/admin/channels/models/refresh-batch';

  // --- 日志 ---
  static const logs = '/admin/logs';

  // --- 统计 ---
  static const metrics = '/admin/metrics';
  static const stats = '/admin/stats';
  static const cooldownStats = '/admin/cooldown/stats';
  static const models = '/admin/models';
  static const activeRequests = '/admin/active-requests';

  // --- API Token ---
  static const authTokens = '/admin/auth-tokens';
  static String authToken(int id) => '/admin/auth-tokens/$id';

  // --- 设置 ---
  static const settings = '/admin/settings';
  static String setting(String key) => '/admin/settings/$key';
  static String settingReset(String key) => '/admin/settings/$key/reset';
  static const settingsBatch = '/admin/settings/batch';
}
