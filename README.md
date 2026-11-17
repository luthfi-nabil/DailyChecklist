# Langkah Kecil — Daily Checklist

**Version: V0.1 (`0.1.0`)**

A calm, local-first daily checklist and habit-tracking suite for **Desktop (Electron)** and **Mobile (Flutter)** with zero-configuration local network synchronization.

---

## Features

- **Core Checklist & Rewards (Milestone 1):**
  - Grouped daily tasks (*Pagi*, *Siang*, *Malam*) with progress tracking, **Hari berat** (Lite Mode for core `★` tasks only), and a single next-step Focus Card (*Mulai dari sini*).
  - Points balance (`+1` per completed step, never deducted for missed days) and redeemable Rewards (*Hadiah*).
  - Inline Edit Mode (*Ubah*) with undo support and Light / Dark / Auto themes.
  - Desktop system tray background mode & optional "Run on Startup".
- **Log Tracking & Activity Dashboard (Milestone 2):**
  - Soft delete (*Nonaktifkan*) preserves historical logs and allows reactivation anytime.
  - Activity Dashboard with completion rate, streaks, 7-day chart, and per-group / per-step breakdowns across *Minggu ini*, *Bulan ini*, and *Semua*.
  - Monthly calendar heatmap & detailed daily completion logs with timestamps.
- **Zero-Config LAN Sync:**
  - Desktop hosts the local sync HTTP server (`47800`) and advertises via mDNS (`_langkahkecil._tcp`) and UDP broadcast (`47899`).
  - Mobile discovers Desktop automatically without manual IP setup, pairs once with a 6-digit code, and syncs via Last-Writer-Wins (LWW) with configurable `3–7` day token validity.
- **Scheduled Activities & Group Ordering (Milestone 3):**
  - Configure activities as **Harian** (Daily), **Mingguan** (specific days `Sen–Min`), or **Bulanan** (specific dates `1–31`) with persistent `freq`/`freq_days` fields synced across Desktop and Mobile.
  - Interactive collapsible checklist calendar in *Hari ini* showing Weekly and Monthly indicator dots, date inspection, and read-only preview for future dates.
  - Edit Mode (*Ubah*) displays high-contrast frequency badges below each input, an icon-only `📅` schedule picker button, off-day visibility, and `↑` / `↓` controls to reorder activity groups.
  - Activity Dashboard calculates completion rates against scheduled days in range, and Day Logs only list tasks scheduled (or completed) on that date.

---

## Repository Structure

```
DailyChecklist/
├── desktop/            # Electron desktop app (main, preload, renderer, node:sqlite, tests)
├── mobile/             # Flutter mobile app (clean architecture, sqflite, tests)
├── Design/             # Interactive HTML UI mockups (DesktopDesign.html, MobileDesign.html, ThirdDesign.html)
├── docs/               # Shared SyncProtocol.md contract
├── Milestone.md        # Milestone 1–3 planning & acceptance criteria
├── CLAUDE.md           # Project rules & constraints
└── README.md           # This file
```

---

## Quick Start

### Desktop (Electron)
```powershell
cd desktop
npm.cmd install
npm.cmd test          # Run unit & sync server tests
npm.cmd start         # Launch desktop app
npm.cmd run dist:win  # Build Windows NSIS installer (.exe in desktop/dist/)
```
> **Note:** When closing the window (**X**), the app hides to the system tray so sync stays available. Use **Aplikasi → Keluar (Exit)** on the toolbar, the sidebar **Keluar** button, or the tray menu to stop the server and exit completely.

### Mobile (Flutter)
```powershell
cd mobile
flutter pub get
flutter analyze       # Static analysis
flutter test          # Unit & widget tests (sqflite_common_ffi)
flutter build apk --release
```
> Output APK: `mobile/build/app/outputs/flutter-apk/app-release.apk`. Run `flutter doctor --android-licenses` once before your first Android build if prompted.

---

## Versioning & Changelog

This project uses semantic versioning starting from **V0.1 (`0.1.0`)**, tracked in:
- [desktop/package.json](desktop/package.json) (`version`)
- [mobile/pubspec.yaml](mobile/pubspec.yaml) (`version`)

### V0.1 (`0.1.0`) — 2026-11-17
- Initial release implementing **Milestone 1** (Checklist, Focus Card, Lite Mode, Rewards, Edit Mode, Local SQLite, Desktop Tray/Startup, Zero-Config LAN Sync), **Milestone 2** (Activity Dashboard, Calendar & Day Logs, Soft Delete / Reactivate), and **Milestone 3** (Scheduled Activities & Group Reordering).
- Added desktop tray hide on window close (**X**) and full process/server exit via **Keluar (Exit)**.
- Fixed deterministic seed timestamps (`updated_at = 1`) and cursor resets so Desktop/Mobile deactivation state syncs cleanly regardless of install order.
- Added configurable `3–7` day mobile pairing token expiration (default `7` days).
- Implemented **Milestone 3: Scheduled Activities & Group Reordering** across Desktop (Electron) and Mobile (Flutter) per [Milestone.md](Milestone.md) and [Design/ThirdDesign.html](Design/ThirdDesign.html):
  - Extended SQLite schemas (`tasks.freq`, `tasks.freq_days`) and `/api/v1/sync` LWW protocol with automatic migration for existing databases.
  - Added collapsible checklist calendar in *Hari ini* with Weekly/Monthly indicator dots, past/future date banners (`Kembali ke hari ini`), and read-only preview for upcoming dates.
  - Updated Edit Mode (*Ubah*) with an icon-only `📅` schedule button (tooltip/alternate text), high-contrast frequency pills below activity inputs, schedule modal/bottom sheet (`Harian` / `Mingguan` / `Bulanan`), and `↑` / `↓` group reordering synced between Desktop and Mobile.
  - Updated Activity Dashboard completion rates to use scheduled days as the denominator and filtered Day Logs by scheduled tasks.
