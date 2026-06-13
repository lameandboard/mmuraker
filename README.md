# mmuraker

> **Attribution notice**  
> mmuraker is a community derivative app inspired by the architecture, design language, and UI
> patterns of **[mobileraker](https://github.com/Clon1998/mobileraker)** by
> **[Patrick Schmidt](https://mobileraker.com)** (© 2024 Patrick Schmidt, Mobileraker License v2).  
> This project carries that same **non-commercial license** — see [LICENSE](LICENSE) and
> [NOTICE](NOTICE) for full attribution and terms.  
> WireGuard® is a registered trademark of Jason A. Donenfeld.  
> See [NOTICE](NOTICE) for all third-party package attributions.

A mobileraker-derived Flutter app for Klipper/Moonraker 3D printers, with added support for
**Multi-Material Units (MMU)** and a **built-in WireGuard auto-VPN** for hassle-free remote access.

## Features

### Core (mobileraker-inspired)
- Full Moonraker API integration via WebSocket & REST
- Real-time printer status dashboard
- Temperature monitoring & control
- Extruder / tool control
- G-code console
- Multi-printer management
- Riverpod state management + GoRouter navigation
- Light & dark theme (flex_color_scheme)
- Localization (English default, easily extendable)

### MMU Support
- **Automatic MMU detection** – checks printer objects and macros (`T0`, `T1`, …) to detect an MMU-capable setup
- **Tool selector card** – compact MMU tool selector on the dashboard, only shown when MMU is detected
- **Per-tool load / unload** – calls standard MMU macros
- **MMU state display** – shows active tool, filament colours, and error status in the dashboard
- **Print metadata** – surfaces MMU print info (`mmuPrint`, `referencedTools`, `filamentColors`) from G-code file metadata

### No ads, no paywalls, no tracking
- **No ads, no paywalls, no tracking, no popups** — no AdMob, no subscriptions, no "support the dev" nags, no rating prompts, no donation dialogs, no analytics phoning home

### Auto-VPN (WireGuard)
- **Local-first** – the app always tries to reach the printer on the LAN first
- **Auto-connect** – if the printer is unreachable locally AND a WireGuard config has been saved, the VPN tunnel starts automatically
- **Zero-cost** – uses the open-source WireGuard protocol; no subscription or third-party relay required
- **Self-hosted** – works with any WireGuard server you control (e.g. PiVPN, a VPS, or a router with WireGuard support)
- **Settings screen** – paste your WireGuard `.conf` block, save, and the app handles everything else
- **Status indicator** – VPN badge visible in the app bar when the tunnel is active

## Getting started

### Prerequisites
- Flutter ≥ 3.22
- Android SDK (for APK builds) — min SDK 25
- A Klipper printer running Moonraker

### Downloading a pre-built APK

Go to the [Releases page](../../releases) and download the `.apk` file from the latest release's **Assets** section.
Every time a new version tag (e.g. `v1.0.0`) is pushed, GitHub Actions automatically builds the APK and attaches it to the release.

### Publishing a new release (maintainers)

1. Tag the commit you want to release:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. The [Release APK](.github/workflows/release.yml) workflow triggers automatically, builds the debug APK, and creates a GitHub Release with the APK attached under **Assets**.
3. Users can download `mmuraker-v1.0.0-debug.apk` directly from the release page.

### Building locally

```bash
flutter pub get
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

### Remote access via WireGuard (auto-VPN)

1. Set up a WireGuard server on your home network or a VPS (e.g. [PiVPN](https://www.pivpn.io/)).
2. Generate a client config (`.conf` file).
3. In the app → **Settings → Remote Access (VPN)** → paste the config.
4. The app will connect automatically whenever your printer is not reachable on the local network.

## Architecture

```
lib/
├── data/
│   ├── dto/           # Immutable data transfer objects (freezed)
│   │   ├── machine/   # Printer, Toolhead, Extruder, Klippy state
│   │   │   └── mmu/   # MmuState, MmuTool
│   │   └── files/     # GCodeFile (with MMU metadata)
│   ├── model/         # Persistent models stored in Hive
│   └── adapters/      # Hive type adapters
├── service/
│   ├── moonraker/     # Moonraker WebSocket + REST services
│   │   ├── printer_service.dart
│   │   └── mmu_service.dart
│   ├── machine_service.dart
│   ├── network_service.dart  # Local reachability checks
│   └── vpn_service.dart      # WireGuard auto-VPN
├── routing/           # GoRouter configuration
└── ui/
    ├── components/    # Shared widgets
    ├── screens/
    │   ├── dashboard/ # Main dashboard + cards (including MMU card)
    │   ├── overview/  # Printer list
    │   ├── console/   # G-code console
    │   └── settings/  # Settings + VPN config page
    └── theme/         # flex_color_scheme setup
```

## Upstream reference

Design language and architecture inspired by [mobileraker](https://github.com/Clon1998/mobileraker) by Patrick Schmidt.  
This is an independent derivative project focused on MMU support.

## License

Mobileraker License v2 (non-commercial) — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
