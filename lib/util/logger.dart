// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:talker_flutter/talker_flutter.dart';

/// Global [Talker] logger instance.
///
/// Import this and call [appLogger.info], [appLogger.warning],
/// [appLogger.error], etc.
final appLogger = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: true,
    useHistory: true,
    maxHistoryItems: 500,
  ),
);

@Deprecated('Use appLogger instead.')
final logger = appLogger;
