# Langkah Kecil — Daily Checklist & Personal Life OS

**Version: V0.2.0 (`0.2.0`)**

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
- **Personal Life OS & Audit Log (Milestone 4A–4C):**
  - **Soft Pastel Minimalist** theme system (Light & Dark) across a collapsible Desktop sidebar and Mobile Bottom Navigation + Workspace Grid Menu.
  - **Customizable Dashboard (*Dasbor*):** Add/remove, drag-and-drop or step-reorder, resize (`S`/`M`/`L` on Desktop), toggle visibility, persist layout preferences, and reset to default across all 7 modules (Productivity, Finance, Health, Wellness, Menstrual Cycle, Notes & Journal, Rewards).
  - **Individual Module Reports (*Laporan*):** Dedicated Weekly, Monthly, Yearly, and Custom Date Range reports for Productivity, Finance, Health, Wellness, Menstrual Cycle, and Notes & Journal—computed strictly from stored records.
  - **Global Quick Add (`+`):** Persistent floating `+` action across all main pages with 9 inline forms (Task, Income/Expense, Food, Weight, Water, Workout, Mood check-in, Menstrual symptom, Quick note).
  - **Audit Log (`audit_logs`):** Per-device local diagnostics logging API errors, discovery timeouts, `401` auth issues, and failed/recovered sync attempts with token/secret redaction.

---

## Repository Structure

```
DailyChecklist/
├── desktop/            # Electron desktop app (main, preload, renderer, node:sqlite, tests)
├── mobile/             # Flutter mobile app (clean architecture, sqflite, tests)
├── Design/             # Interactive HTML UI mockups (DesktopDesign.html, MobileDesign.html, ThirdDesign.html, PersonalLifeOS.html)
├── docs/               # Shared SyncProtocol.md contract
├── Milestone.md        # Milestone 1–4+ planning & acceptance criteria
├── CHANGELOG.md        # Full release changelog by version
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

This project uses semantic versioning starting from **V0.1 (`0.1.0`)**.

- **Current Version:** `V0.2.0` (`0.2.0`)
- **Version Manifests:**
  - Desktop: [desktop/package.json](desktop/package.json) (`"version": "0.2.0"`)
  - Mobile: [mobile/pubspec.yaml](mobile/pubspec.yaml) (`version: 0.2.0+2`)
- **Versions Overview** *(see full release notes in [CHANGELOG.md](CHANGELOG.md))*:
  - **V0.2.0 (`0.2.0`) — 2026-11-18:** Personal Life OS (Customizable 7-module Dashboard, Soft Pastel Minimalist theme, Collapsible Sidebar & Mobile Workspace navigation, 6 Module Reports with range filters, Global Quick Add `+`, and per-device API/Sync Audit Log).
  - **V0.1 (`0.1.0`) — 2026-11-17:** Core Daily Checklist & Rewards (Milestone 1), Log Tracking & Activity Dashboard (Milestone 2), Scheduled Activities & Group Ordering (Milestone 3), Desktop Tray & 3–7 day Zero-Config LAN Sync.
