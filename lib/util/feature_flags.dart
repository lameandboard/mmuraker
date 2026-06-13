// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

/// All features in mmuraker are free and unlocked for every user.
///
/// Unlike mobileraker (which has a "Pro" / supporter tier), mmuraker is a
/// community fork where nothing is gated behind a paywall, subscription, or
/// any other purchase. Every flag in this class returns [true] unconditionally.
///
/// If you ever see an [isPro] / [isSupporterTier] / [isFeatureUnlocked] check
/// somewhere in the codebase, the answer is always **yes**.
abstract class FeatureFlags {
  // ─── Remote / connectivity ────────────────────────────────────────────────

  /// Built-in WireGuard auto-VPN for free remote access. Always enabled.
  static const bool autoVpn = true;

  /// Support for multiple simultaneous printer connections. Always enabled.
  static const bool multiPrinter = true;

  // ─── Dashboard & monitoring ───────────────────────────────────────────────

  /// Temperature history graphs. Always enabled.
  static const bool temperatureGraphs = true;

  /// Webcam / camera streams on the dashboard. Always enabled.
  static const bool webcam = true;

  /// Customisable dashboard card layout. Always enabled.
  static const bool customisableDashboard = true;

  // ─── MMU features ─────────────────────────────────────────────────────────

  /// MMU tool selector and per-tool controls on the dashboard. Always enabled.
  static const bool mmuDashboardCard = true;

  /// MMU print metadata display (colours, tool count, filament info). Always enabled.
  static const bool mmuPrintMetadata = true;

  // ─── Console / developer tools ────────────────────────────────────────────

  /// Full G-code console. Always enabled.
  static const bool gcodeConsole = true;

  /// Macro execution from the dashboard. Always enabled.
  static const bool macros = true;

  /// G-code file management and upload. Always enabled.
  static const bool fileManager = true;

  // ─── Notifications ────────────────────────────────────────────────────────

  /// Print progress / completion notifications. Always enabled.
  static const bool notifications = true;

  // ─── Nag / monetisation popups ────────────────────────────────────────────

  /// mmuraker shows NO "support the developer" popups, rating prompts,
  /// donation nags, "buy me a coffee" dialogs, or any other interrupting
  /// call-to-action.  This is a community fork — users should never be
  /// asked for money or redirected to a payment flow.
  // ignore: constant_identifier_names
  static const bool SUPPORT_POPUPS_ENABLED = false;

  /// No "rate this app" / app-store review prompt is ever shown.
  // ignore: constant_identifier_names
  static const bool RATE_APP_PROMPT_ENABLED = false;

  // ─── Ads ──────────────────────────────────────────────────────────────────

  /// mmuraker contains NO advertisements of any kind.
  ///
  /// There is no AdMob, no Google Mobile Ads SDK, no banner, interstitial,
  /// rewarded, or native ad unit anywhere in this codebase.  No ad-consent
  /// dialog is shown.  No ad-tracking identifier is collected or transmitted.
  ///
  /// This constant is `false` so that any accidental ad-related call sites
  /// fail loudly at compile time if ever introduced.
  // ignore: constant_identifier_names
  static const bool ADS_ENABLED = false;

  // ─── Misc ─────────────────────────────────────────────────────────────────

  /// Spoolman filament manager integration. Always enabled.
  static const bool spoolman = true;

  /// Print history and statistics. Always enabled.
  static const bool printHistory = true;
}
