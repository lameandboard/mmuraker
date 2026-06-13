// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ui/screens/console/console_page.dart';
import '../ui/screens/dashboard/dashboard_page.dart';
import '../ui/screens/overview/overview_page.dart';
import '../ui/screens/settings/settings_page.dart';
import '../ui/screens/settings/vpn_settings_page.dart';
import '../ui/screens/settings/printer_add_page.dart';

part 'app_router.g.dart';

/// Route name constants – use these instead of raw strings.
abstract class Routes {
  static const overview = '/';
  static const dashboard = '/dashboard';
  static const console = '/console';
  static const settings = '/settings';
  static const vpnSettings = '/settings/vpn';
  static const addPrinter = '/settings/add-printer';
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.overview,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: Routes.overview,
        name: 'overview',
        builder: (context, state) => const OverviewPage(),
      ),
      GoRoute(
        path: '${Routes.dashboard}/:machineId',
        name: 'dashboard',
        builder: (context, state) => DashboardPage(
          machineId: state.pathParameters['machineId']!,
        ),
        routes: [
          GoRoute(
            path: 'console',
            name: 'console',
            builder: (context, state) => ConsolePage(
              machineId: state.pathParameters['machineId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'vpn',
            name: 'vpnSettings',
            builder: (context, state) => const VpnSettingsPage(),
          ),
          GoRoute(
            path: 'add-printer',
            name: 'addPrinter',
            builder: (context, state) => const PrinterAddPage(),
          ),
        ],
      ),
    ],
  );
}
