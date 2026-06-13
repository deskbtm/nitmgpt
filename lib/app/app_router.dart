import 'package:go_router/go_router.dart';
import 'package:nitmgpt/app/app_navigator.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/pages/add_rules/add_rules_page.dart';
import 'package:nitmgpt/pages/home/home_page.dart';
import 'package:nitmgpt/pages/index/index_page.dart';
import 'package:nitmgpt/pages/settings/settings_page.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppScopeHost(child: child),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return IndexPage(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HomePage(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.settings,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: SettingsPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.rules,
          builder: (context, state) => const AddRulesPage(),
        ),
      ],
    ),
  ],
);
