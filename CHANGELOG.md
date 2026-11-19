# Changelog — Langkah Kecil

All notable changes to **Langkah Kecil (Desktop & Mobile)** are documented in this file.  
Versioning follows semantic versioning (`MAJOR.MINOR.PATCH`) starting from **V0.1 (`0.1.0`)**.

---

## [V0.3.1] (`0.3.1`) — 2026-11-19
### Added
- **Manual Sync IP Address & Port Configuration (Milestone 7):**
  - **Mobile Client Override (`SyncService` + Settings UI):** Added configurable manual Desktop IP/host and Port (`default: 47800`) inside *Local Network & Sync* with URL normalization (`http://host:port` -> `host`), port validation (`1–65535`), SQLite persistence (`manual_sync_enabled`, `manual_sync_host`, `manual_sync_port`), **Save & Connect** `/api/v1/ping` verification (automatically launching the pairing code dialog when unpaired), and one-tap **Use Auto LAN** fallback.
  - **Desktop Server Listen IP & Port (`SyncServer` + `DiscoveryService` + Settings UI):** Added configurable **Bind IP** (`0.0.0.0` or specific LAN interface IPv4) and custom **Port** (`1–65535`) inside *Local LAN Sync* with live `SyncServer` restart, automatic mDNS/UDP discovery port update, safe rollback on bind errors, and persistence across launches (`sync_bind_ip`, `sync_port`).
- **Permanent Deletion for Deactivated Task Steps (Milestone 8):**
  - Added **Delete Permanently** (*Hapus Permanen*) alongside **Restore** (*Pulihkan*) inside the *Inactive* view on both Desktop and Mobile, with explicit confirmation prompts, local completion-check cleanup, and synced tombstone propagation (`deleted_tasks` / `deleted_task_tombstones`) across Desktop and Mobile LAN sync so permanently removed steps never resurrect.

### Changed
- **Rebrand to Lifolio & Application Icon Update:**
  - Renamed display application identity to **Lifolio** across Electron (`productName`, window title, sidebar brand header, tray tooltip & context menu, paired device prompts, JSON export filenames) and Flutter (`AndroidManifest.xml`, iOS `Info.plist`, `MaterialApp.title`, Settings footer).
  - Updated Desktop (`.ico`, `.png`, tray PNG, sidebar favicon/logo), Android (`mipmap-*`), iOS (`AppIcon.appiconset` opaque squircle icons), and Mobile in-app assets using `icon/MinimalistIcon.png`.
- **Bug Fixes, QoL & Bahasa Indonesia Audit (`V0.3.1` Milestone 8):**
  - **Little Note Pinned Motivational Reminder:** Converted Home's *Little note* card on both Desktop and Mobile into a *Pinned Motivational Reminder* (`is_pinned = 1`, `category = gratitude`, synced ID `little-note-motivation`) displaying the active pinned quote (or calm default motivational copy) with inline edit & persistence.
  - **Editable & Deletable Finance Envelopes:** Added envelope editing (name & monthly budget update in-place via existing record ID) and soft deletion with confirmation across both Desktop and Mobile *Finance* workspaces.
  - **Mobile Notes Save Ordering & Comfortable Typography:** Updated *Notes* queries across Desktop & Mobile repositories to sort newest saved/updated notes strictly at the very top (`updated_at DESC, day DESC`) regardless of older pinned entries, placed Mobile's saved notes list directly beneath the Quick Editor with the Pinned Reminder card below, and enlarged editor/preview/card text sizes (`16px` title, `15px` body input, comfortable note cards) for relaxed reading and writing.
  - **English / Bahasa Indonesia Consistency Audit:** Audited and standardized `EN` and `ID` labels, navigation headers, workspace actions (`Simpan`, `Ubah`, `Hapus`, `Pulihkan`, `Hapus Permanen`, `Nonaktif`, `Batal`), dialogs, and date formatting across Electron Desktop (`index.html`, `app.js`, `lifeos.js`) and Flutter Mobile (`AppStrings`, Home, Today, Workspaces, Rewards, Trail, Audit Log, Quick Add, Settings).
- **DesignRevisionM6 v3 Alignment Across Desktop & Mobile Workspaces & Rewards:**
  - Unified *Productivity*, *Finance*, *Health*, *Wellness*, *Menstrual*, *Notes & Journal*, and *Rewards* across both Electron Desktop and Flutter Mobile to match `Design/DesignRevisionM6.html` White & Pink styling (soft `#FFF7FA` stat boxes and panels, `#ED9FBD` rose primary buttons, `#F2E5EB` subtle borders, visual period/cycle calendar, emoji mood selector, symptom toggle pills, pinned notes boxes, and pink Rewards cards replacing legacy yellow/gold styling).
  - Removed redundant module switcher/filter bars from Desktop workspace headers, integrating period filters cleanly inside each bottom insights/report card.
  - Replaced radio-button-style double rings in the Settings palette chooser with clean solid single circular color swatches (`✓` active state).
  - Made **Your spaces** on Home directly editable (inline rename, reorder, show/hide, reset) persisted in SQLite (`dashboard_layout_v1`).
  - Changed the default greeting display name from `'Ara'` to `'User'` (migrating uncustomized `'Ara'` -> `'User'` while preserving user-customized names).

---

## [V0.3.0] (`0.3.0`) — 2026-11-18
### Added
- **Phone Local IP & Network Diagnostics (Milestone 5):**
  - Displays Mobile's current local Wi-Fi/LAN IPv4 address (and discovered Desktop server IP) in both the **More** workspace bottom sheet and **Settings**, with instant manual Refresh and no extra OS permissions required.
- **Personal Life OS Redesign v3 & Complete Module Workspaces (Milestone 6):**
  - **White & Pink Default Palette + 5-Color Palette Picker:** Defaults to clean *White & Pink* (`#FFFFFF` / `#ED9FBD`) and lets users switch instantly in Settings across **White & Pink**, **Pastel Sage**, **Slate Teal**, **Lavender Mist**, and **Warm Peach** in both Light and Dark modes.
  - **Profile Display Name, Language (`EN` / `ID`) & Optional Report Charts Toggle:** Personalized greeting (`Hello, <Name> ♡`) configurable in Settings, bilingual English / Bahasa Indonesia labels, and toggleable bar charts in reports.
  - **5-Tab Mobile Bottom Navigation & Coherent Workspaces:** Mobile features `Home`, `Tasks`, `Money`, `Health`, `More` (with `Wellness`, `Menstrual`, `Notes`, `Rewards`, `History`, `Audit Log`, `Settings`), while Desktop and Mobile turn every category into a complete interactive workspace combining inline forms, searchable/editable history, Pomodoro timer, savings goals, recurring bills & debt, meal slots, water cup tracker, body measurements, gratitude notes, cycle estimates with clear non-medical disclaimers, split/filterable Notes, and dynamically computed Achievements.
  - **Automatic Pre-Migration SQLite Backup & JSON Export/Restore:** Automatically creates `.pre-m6.bak` SQLite backups before schema upgrades and provides JSON backup export & restore in Settings on Desktop and Mobile.

---

## [V0.2.0] (`0.2.0`) — 2026-11-18
### Added
  - **Personal Life OS & Audit Log (Milestones 4A–4C)** per [Design/PersonalLifeOS.html](Design/PersonalLifeOS.html) and [Milestone.md](Milestone.md):
  - **Soft Pastel Minimalist Design System:** Updated Light and Dark color tokens, typography (`Bricolage Grotesque` + `DM Sans` / `Plus Jakarta Sans`), and muted module pastel accents across Desktop and Mobile.
  - **Responsive Navigation:**
    - **Desktop:** Collapsible sidebar (`⇄`) with Workspace module links (*Productivity*, *Finance*, *Health*, *Wellness*, *Menstrual*, *Notes*), *Audit Log*, and persistent `+ Quick Add`.
    - **Mobile:** 4-tab Bottom Navigation (*Hari ini*, *Dasbor*, *Laporan*, *Workspace*), touch-friendly Workspace Grid Menu, and Floating Quick Add (`+`) positioned safely above bottom navigation.
  - **Customizable Dashboard (*Dasbor*):** Dynamic 7-module widget grid (*Productivity*, *Finance*, *Health*, *Wellness*, *Menstrual Cycle*, *Notes & Journal*, *Rewards*) with add/remove catalog, drag-and-drop and `↑`/`↓` reordering, per-widget visibility toggles, Desktop `S`/`M`/`L` column resizing, SQLite layout persistence (`dashboard_layout_v1`), and reset to default layout.
  - **Individual Module Reports (*Laporan*):** Dedicated report views for *Productivity* (completion rate, focus time, project progress), *Finance* (income, expenses, envelope usage, savings, debt), *Health* (weight history, calories, water intake, workout, body measurements), *Wellness* (mood, energy, stress, sleep, emotional triggers), *Menstrual Cycle* (cycle history, cycle duration, symptoms, period history), and *Notes & Journal* (writing activity, entry history, tags) with *Mingguan*, *Bulanan*, *Tahunan*, and *Rentang Kustom* date filters computed strictly from actual stored rows.
  - **Global Quick Add (`+`):** 9 inline forms accessible from every page without navigating away (*Add task*, *Add income/expense*, *Add food entry*, *Add weight entry*, *Add water intake*, *Add workout*, *Mood check-in*, *Menstrual symptom entry*, *Create quick note*).
  - **SQLite v3 & LAN Sync Protocol:** Added LWW-synced tables (`projects`, `focus_sessions`, `finance_envelopes`, `finance_entries`, `health_entries`, `wellness_entries`, `menstrual_entries`, `notes`) in [docs/SyncProtocol.md](docs/SyncProtocol.md), Desktop, and Mobile.
  - **Audit Log (`audit_logs`):** Per-device local SQLite diagnostics recording API errors, discovery timeouts, `401` auth rejections, failed syncs, and recovery events, with automatic bearer/secret redaction, 30-day / 500-row retention, and Audit Log UI views on Desktop and Mobile.

---

## [V0.1] (`0.1.0`) — 2026-11-17
### Added
- **Milestone 1 (Core Checklist & Sync):** Grouped daily tasks (*Pagi*, *Siang*, *Malam*), progress card, **Hari berat** (Lite Mode for core `★` tasks), single next-step Focus Card (*Mulai dari sini*), points balance (`+1` per check), redeemable Rewards (*Hadiah*), inline Edit Mode (*Ubah*) with undo support, Light / Dark / Auto themes, Desktop system tray background mode & optional Run on Startup, and zero-config LAN sync via mDNS (`_langkahkecil._tcp`) and UDP broadcast (`47899`).
- **Milestone 2 (Log Tracking & Activity Dashboard):** Soft delete (*Nonaktifkan*) / reactivation preserving historical logs, Activity Dashboard metrics/streaks/charts (*Minggu ini*, *Bulan ini*, *Semua*), monthly calendar heatmap, and timestamped daily completion logs.
- **Milestone 3 (Scheduled Activities & Group Ordering):**
  - Added Daily, Weekly (`1–7` ISO weekdays), and Monthly (`1–31` dates) recurring activity schedules (`tasks.freq`, `tasks.freq_days`) synced via `/api/v1/sync` with automatic SQLite migration.
  - Added toggleable schedule calendar in *Hari ini* with Weekly/Monthly indicator dots, past/future date banners (`Kembali ke hari ini`), and read-only preview for upcoming dates.
  - Updated Edit Mode (*Ubah*) with icon-only `📅` schedule button (`title`/`aria-label` alternate text), high-contrast frequency pills below inputs, schedule editor modal/bottom sheet, and `↑` / `↓` activity group reordering.
  - Updated Dashboard completion rates to use scheduled days as the denominator and filtered historical Day Logs by scheduled tasks.
- Added configurable `3–7` day mobile pairing token expiration (default `7` days).

### Fixed
- Desktop window close (**X**) hides to the system tray instead of terminating the sync server; full exit is available via **Keluar (Exit)** / tray menu.
- Normalized deterministic seed timestamps (`updated_at = 1`) and cursor resets so Desktop/Mobile deactivation state synchronizes cleanly regardless of install order.
