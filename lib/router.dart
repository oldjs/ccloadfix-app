import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'widgets/main_shell.dart';
import 'pages/login/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/channels/channels_page.dart';
import 'pages/channels/channel_detail_page.dart';
import 'pages/logs/logs_page.dart';
import 'pages/stats/stats_page.dart';
import 'pages/tokens/tokens_page.dart';
import 'pages/settings/settings_page.dart';

// 路由配置
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    // 根据登录状态重定向
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoginPage = state.matchedLocation == '/login';

      // 没登录 & 不在登录页 → 踢到登录页
      if (!isLoggedIn && !isLoginPage) return '/login';
      // 已登录 & 在登录页 → 跳到首页
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      // 登录页（不在底部导航里）
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      // 底部导航壳
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: 仪表盘
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Tab 1: 渠道
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/channels',
                builder: (context, state) => const ChannelsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ChannelDetailPage(channelId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: 日志
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/logs',
                builder: (context, state) => const LogsPage(),
              ),
            ],
          ),
          // Tab 3: 统计
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),
        ],
      ),
      // 抽屉里的独立页面
      GoRoute(
        path: '/tokens',
        builder: (context, state) => const TokensPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
