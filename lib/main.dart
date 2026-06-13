// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmuraker/routing/app_router.dart';
import 'package:mmuraker/service/machine_service.dart';
import 'package:mmuraker/service/vpn_service.dart';
import 'package:mmuraker/ui/theme/theme_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
        Locale('it'),
        Locale('pl'),
        Locale('pt', 'BR'),
        Locale('ru'),
        Locale('uk'),
        Locale('zh', 'CN'),
      ],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      child: const ProviderScope(child: MmuRakerApp()),
    ),
  );
}

class MmuRakerApp extends HookConsumerWidget {
  const MmuRakerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Warm up services on first build.
    ref.watch(machineServiceProvider);
    ref.watch(vpnServiceProvider);

    final theme = buildLightTheme();
    final darkTheme = buildDarkTheme();

    return MaterialApp.router(
      title: 'mmuraker',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
