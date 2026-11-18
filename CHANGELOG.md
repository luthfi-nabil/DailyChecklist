# Changelog — Langkah Kecil

All notable changes to **Langkah Kecil (Desktop & Mobile)** are documented in this file.  
Versioning follows semantic versioning (`MAJOR.MINOR.PATCH`) starting from **V0.1 (`0.1.0`)**.

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
