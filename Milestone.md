# Milestones Planning — Daily Checklist (Langkah Kecil)

## Milestone 1: Core Design & Local Checklist Experience (`FirstDesign.html`)
**Goal:** Establish the visual design system, core user flows, and local-first functionality defined in [FirstDesign.html](Design/FirstDesign.html) across Desktop (Electron) and Mobile (Flutter).

### 1. Design System & Theming
- **Typography:** `Bricolage Grotesque` (display/headings) and `DM Sans` (body), with `tabular-nums` for counters and progress.
- **Color Tokens & Adaptive Theme:** Light and Dark mode support (`prefers-color-scheme` + manual theme override), using the slate/teal accent (`--accent`) and gold reward (`--gold`) palette.
- **Layout & Accessibility:** Narrow single-column layout (`max-width: 640px`), 44px+ touch targets, `focus-visible` outlines, reduced-motion support, and safe-area inset handling.

### 2. Core Features & Views
- **Header & Navigation:**
  - Localized current date display (`Hari, Tanggal Bulan`) and app title (`Langkah Kecil`).
  - `Ubah` (Edit Mode) toggle chip.
  - Two-tab navigation: **Hari ini** (Today) and **Hadiah** (Rewards).
- **Today Tab (`Hari ini`):**
  - **Progress Card:** Completed vs. total steps counter, percentage, animated progress bar, encouraging contextual status message, and **Hari berat** (Lite Mode) switch to filter to core (`★`) tasks only.
  - **Next-Step Focus Card (`Mulai dari sini`):** Highlights one uncompleted task at a time with **Sudah selesai** (Done) and **Lewati dulu** (Skip for now) actions, plus a completion state linking to Rewards.
  - **Grouped Checklist:** Collapsible/grouped task cards (default: *Pagi*, *Siang*, *Malam*) with group completion counters (`done/total`), custom checkboxes, strikethrough done state, and `★ inti` badges.
- **Rewards Tab (`Hadiah`):**
  - **Points Balance Card:** Displays available points (`earned - spent`); each checked task awards +1 point, and missed days never deduct points.
  - **Rewards List:** Reward cards with point cost, progress bar toward goal, and **Ambil** (Claim) button (or remaining points needed).
  - **Claim History (`Sudah diambil`):** Recent claimed rewards with formatted dates.
- **Edit Mode (`Ubah`) & Undo:**
  - Inline editing for group names, task names, core (`★`/`☆`) toggles, reward names, and point costs (`1–999`).
  - Add/delete groups, tasks, and rewards.
  - Bottom toast notification with **Urungkan** (Undo) snapshot restoration.
- **Local SQLite Persistence & Daily Rollover:**
  - Store tasks, groups, rewards, daily check history (up to 60 days), and claim history (up to 20 recent claims) in a local **SQLite** database on both Desktop (Electron) and Mobile (Flutter).
  - Automatic midnight/visibility rollover so daily checks reset for the new day while preserving points and definitions.
- **Desktop Background Startup & Auto-Sync:**
  - **Run on Startup (Background):** Desktop (Electron) app provides a user setting to launch automatically on OS startup and run in the background (system tray) to keep sync available without keeping the main window open.
  - **API Auto-Detection (Zero-Config):** Desktop hosts the local sync API and advertises itself on the local network (e.g., via mDNS/Bonjour or UDP broadcast) so the Mobile (Flutter) app automatically discovers and connects to it without manual IP configuration.
  - **Auto-Sync:** Automatic bidirectional synchronization between Desktop and Mobile apps when on the same local network (with timestamp/conflict resolution).

### 3. Acceptance Criteria
- [v] Visual parity with [FirstDesign.html](Design/FirstDesign.html) in both Light and Dark themes.
- [v] All Today, Focus, Lite Mode, Rewards, Edit Mode, and Undo flows work offline backed by local SQLite on both Desktop and Mobile.
- [v] Desktop app supports toggling "Run on startup (background/tray)" and stays reachable in the background.
- [v] Mobile app auto-detects the Desktop sync API on the local network without manual IP setup and auto-syncs changes.
- [v] Clean architecture / design pattern applied for both Electron (Desktop) and Flutter (Mobile) targets.

---

## Milestone 2: Log Tracking & Activity Dashboard
**Goal:** Provide historical activity logging, progress analytics, and an Activity Dashboard while preserving data integrity through soft deletion (deactivation).

### 1. Design & Mockup
- Create an `.html` UI mockup (e.g., `Design/SecondDesign.html`) following the **Langkah Kecil** design system (Light/Dark tokens, typography, and calm UX) for the Log Tracking & Activity Dashboard views.

### 2. Soft Delete (Deactivation) & Data Model
- **Deactivate Instead of Delete:** Removing an activity (task or group) in Edit Mode marks it as inactive (`is_active = 0`, `deactivated_at` timestamp) in SQLite instead of permanently deleting it.
- **Historical Integrity:** Deactivated activities no longer appear in the daily active checklist, but all past completion logs and points remain preserved for accurate reporting.
- *(Optional/Recommended)* Ability to view or reactivate deactivated activities if needed.

### 3. Log Tracking
- **Persistent Activity Logs:** Record timestamped completion/uncheck events and daily snapshots in SQLite (removing or extending the 60-day cap so historical logs are retained for tracking).
- **Daily / Date-Range Log View:** Browse past days' completed and missed activities, including activities that were later deactivated.
- **Sync Support:** Synchronize activity logs and deactivation states (`is_active`, `deactivated_at`) between Desktop (Electron) and Mobile (Flutter).

### 4. Activity Dashboard
- **Progress Overview:** Summary metrics such as completion rate, total completed steps, active days / streaks, and points earned over selectable periods (e.g., Weekly, Monthly).
- **Per-Activity & Per-Group Breakdown:** Visual progress/consistency indicators showing how often each activity or group is completed.
- **Deactivated Activity History:** Clearly label historical entries from deactivated activities so past trends remain transparent.

### 5. Acceptance Criteria
- [v] HTML mockup for Log Tracking & Activity Dashboard created and approved before implementation.
- [v] Deleting a task or group in SQLite sets it to deactivated (`is_active = 0`) and hides it from Today's checklist without erasing historical logs.
- [v] Users can inspect past daily logs and view summary analytics on the Activity Dashboard on both Desktop and Mobile.
- [v] Deactivation states and activity logs sync cleanly between Desktop and Mobile.

---

## Milestone 3: Scheduled Activities (Daily, Weekly & Monthly)
**Goal:** Allow users to configure and modify activity schedules (**Harian** / Daily, **Mingguan** / Weekly on specific days, **Bulanan** / Monthly on specific dates) so Today's checklist, Dashboard rates, and Log Tracking reflect recurring schedules accurately across Desktop (Electron) and Mobile (Flutter).

### 1. Design & Mockup
- Create an `.html` UI mockup (`Design/ThirdDesign.html`) following the **Langkah Kecil** design system (Light/Dark tokens, typography, Desktop & Mobile responsive views, and calm UX) for configuring, modifying, and viewing Daily, Weekly, and Monthly activities.

### 2. Data Model & Sync Protocol Extensions
- **Schedule Fields on `tasks`:** Extend the `tasks` table in SQLite (both Desktop and Mobile) with:
  - `freq TEXT NOT NULL DEFAULT 'daily'` (`'daily'` | `'weekly'` | `'monthly'`)
  - `freq_days TEXT` (JSON array of integers: `1–7` Mon–Sun for `'weekly'`, `1–31` day-of-month for `'monthly'`, `NULL` for `'daily'`).
- **Backward Compatibility:** Existing tasks migrate cleanly with `freq = 'daily'` and `freq_days = NULL`.
- **Sync Support:** Include `freq` and `freq_days` in `POST /api/v1/sync` (`Changes.tasks`) with row-level LWW merge by `updated_at` so schedule edits sync seamlessly between Desktop and Mobile.

### 3. Modifying Daily, Weekly & Monthly Activities (Edit Mode)
- **Schedule Picker in Edit Mode (`Ubah`):**
  - Each activity row displays an icon-only calendar button (`📅`, with the frequency text in `title` / `aria-label` alternate text, tinted by schedule type) and shows the current schedule text (`Setiap hari`, `Selasa, Jumat`, or `Tanggal 1, 17`) directly below the activity name input. Clicking `📅` opens the schedule editor.
  - **Harian (Daily):** Active every day (default).
  - **Mingguan (Weekly):** Multi-select weekday chips (`Sen`–`Min`, minimum 1 day).
  - **Bulanan (Monthly):** Multi-select date grid (`1–31`, minimum 1 date; dates beyond a month's length e.g. `31` in February can optionally trigger on the last day of the month or be skipped cleanly).
- **Edit All Active Tasks Anytime:** In Edit Mode (`Ubah`), all active tasks remain visible regardless of today's date so users can inspect or modify weekly and monthly tasks on any day.
- **Reorder Activity Groups:** In Edit Mode (`Ubah`), users can move activity groups up or down (`↑` / `↓`), persisting group `sort` order and syncing it across Desktop and Mobile.

### 4. Checklist Calendar & Dashboard/Log Integration
- **Activity Checklist Calendar (`Hari ini`):**
  - Interactive calendar widget in the checklist view (collapsible via `Kalender` chip on Mobile, and visible/toggleable in the right panel on Desktop).
  - Displays indicator dots on dates that have scheduled Weekly (accent dot) or Monthly (gold dot) activities.
  - Selecting any date loads that date's scheduled checklist: users can check/uncheck tasks for today or past dates, preview upcoming scheduled tasks for future dates, and jump back via a `Hari ini` shortcut.
- **Today View (`Hari ini`):**
  - Only tasks scheduled for the selected date's weekday/day-of-month appear in the active checklist, Focus Card (`Mulai dari sini`), and progress counter (`done/total`).
  - Non-daily tasks due on that date show a subtle frequency badge (e.g., `Mingguan`, `Bulanan`).
- **Activity Dashboard (`Dasbor`):**
  - Completion rates (`% selesai`, per-group, and per-activity) calculate against **scheduled days** in the selected period rather than raw calendar days (e.g., a weekly task completed on 2/2 scheduled days shows `100%`).
- **Log Tracking (`Riwayat`):**
  - Historical day logs only show tasks that were scheduled (or completed) on that specific date.

### 5. Acceptance Criteria
- [v] HTML mockup (`Design/ThirdDesign.html`) created and approved before implementation.
- [v] Users can create and modify activities as Daily, Weekly (specific days), or Monthly (specific dates) in Edit Mode on both Desktop and Mobile.
- [v] Users can reorder activity groups up/down in Edit Mode on both Desktop and Mobile.
- [v] Users can browse an interactive Calendar inside the activity checklist to inspect or check activities for any selected date, with indicator dots for weekly/monthly schedules.
- [v] Today's checklist, Focus Card, Dashboard completion rates, and historical Day Logs accurately respect each task's schedule.
- [v] Schedule fields (`freq`, `freq_days`) migrate cleanly on existing databases and synchronize between Desktop and Mobile.

---

## Milestone 4+: Personal Life OS (Implemented)
**Status:** Design approved and implemented across Sync Protocol, Desktop (Electron), and Mobile (Flutter).  
**Mockup:** [Design/PersonalLifeOS.html](Design/PersonalLifeOS.html) (interactive Desktop + Mobile, Light + Dark, Simulated vs Empty `0`-data state).

### 1. Design Direction: Soft Pastel Minimalist
- **Design System Tokens (Light & Dark):** Warm porcelain canvas (`#F8F7F4` light / `#15171A` dark), elevated cards with `20px` radius and subtle `1px` borders, `Bricolage Grotesque` display headings + `Plus Jakarta Sans` UI body (`tabular-nums`), and accessible muted pastel accents per domain:
  - **Productivity:** Sage (`#DCECE4` / `#235340`)
  - **Finance & Rewards:** Butter (`#F6ECD2` / `#6D5214`)
  - **Health:** Sky (`#DCEBF5` / `#22536F`)
  - **Wellness:** Lavender (`#EAE3F6` / `#4A396B`)
  - **Menstrual Cycle:** Blush (`#F6DFE4` / `#723140`)
  - **Notes & Journal:** Peach (`#F7E5DA` / `#713F26`)

### 2. Responsive Navigation Architecture
- **Desktop:** Collapsible sidebar (`248px` labeled ↔ `74px` icon rail) grouping Core (`Dasbor`, `Laporan`, `Ceklis Harian`), Workspace Modules (`Productivity`, `Finance`, `Health`, `Wellness`, `Menstrual`, `Notes & Journal`, `Rewards`), and persistent `+ Quick Add` trigger.
- **Mobile:** 4-tab Bottom Navigation (`Dasbor`, `Tugas`, `Laporan`, `Workspace`) with touch-friendly `50px+` targets; `Workspace` opens a clean 2-column grid menu giving 1-tap access to all 7 modules and their reports; floating `+` Quick Add button sits cleanly above the bottom bar (`bottom: 78px`) with scroll clearance (`padding-bottom: 148px`).

### 3. Fully Customizable Dashboard (`Dasbor`)
- Dynamic widget grid backed by persisted layout preferences (JSON in local DB/meta synced or per-device preference):
  - **Widgets across all 7 modules:** Productivity, Finance, Health, Wellness, Menstrual Cycle, Notes & Journal, Rewards.
  - **Capabilities:** Add/remove widgets via Catalog modal, HTML5 drag-and-drop + accessible `↑` / `↓` reorder controls, per-widget visibility toggle, widget resizing (`S` 1/3 col, `M` 1/2 col, `L` full-width on Desktop; full-width stacked on Mobile), persistent layout saving, and one-click **Reset to default layout**.
  - **Live Computed Values:** Widgets compute strictly from stored user records (no hardcoded dummy values).

### 4. Individual Module Reports (`Laporan`)
- Dedicated Report view per module with **Weekly (`Mingguan`)**, **Monthly (`Bulanan`)**, **Yearly (`Tahunan`)**, and **Custom Date Range (`Rentang Kustom`)** filters:
  - **Productivity:** Task completion rate, completed vs total, focus minutes logged, project progress bars.
  - **Finance:** Income, expenses, envelope budget usage, savings, debt payments.
  - **Health:** Weight history, calorie intake, water intake (`ml`), workouts, body measurements.
  - **Wellness:** Mood average, energy, stress, sleep duration, emotional triggers log.
  - **Menstrual Cycle:** Cycle history, average cycle duration, symptoms, period history.
  - **Notes & Journal:** Writing activity count, unique tags breakdown, entry history.
- Every KPI, bar, and log list is computed strictly from stored rows in the selected range, showing an honest empty state when zero records exist.

### 5. Global Quick Add (`+`)
- Floating Action Button (`+`) present across all main views on both Desktop and Mobile, opening 9 contextual inline forms without navigating away:
  1. `Add task`
  2. `Add income/expense`
  3. `Add food entry`
  4. `Add weight entry`
  5. `Add water intake`
  6. `Add workout`
  7. `Mood check-in`
  8. `Menstrual symptom entry`
  9. `Create quick note`

### 6. Audit Log (API & Sync Error Diagnostics)
- **Purpose:** Record API errors, local discovery timeouts, auth/pairing rejections (`401 token_expired`), and failed-to-sync events locally on Desktop and Mobile so sync issues can be diagnosed without guessing.
- **Proposed Local Schema (`audit_logs`, per-device SQLite — not synced to prevent sync-failure loops):**
  - `id TEXT PRIMARY KEY`, `created_at INTEGER`, `day TEXT`, `source TEXT` (`'desktop'|'mobile'`), `category TEXT` (`'sync'|'api'|'auth'|'discovery'`), `level TEXT` (`'error'|'warn'|'info'`), `endpoint TEXT`, `status_code INTEGER`, `error_code TEXT`, `message TEXT`, `details_json TEXT`.
- **Privacy & Retention:** Strip bearer tokens and pairing secrets before persistence; auto-prune rows older than 30 days (or cap at 500 recent rows); allow user-initiated clear or export.
- **Navigation Placement:** Accessible from **Sistem → Audit Log** in Desktop's collapsible sidebar (with active error badge) and from the **Workspace** menu on Mobile.

### 7. Proposed Incremental Rollout (Upon Approval)
- **Milestone 4A — Life OS Shell, Quick Add, Audit Log & Customizable Dashboard Foundation:** Soft Pastel Minimalist theme tokens, Desktop collapsible sidebar + Mobile Workspace menu, `dashboard_layouts` persistence + widget customization engine, `audit_logs` API/sync error capture + viewer, and Global Quick Add launcher wired to existing Tasks + initial log tables.
- **Milestone 4B — Finance, Health & Wellness Modules + Reports + LAN Sync:** Local SQLite schema extensions (`finance_entries`, `envelopes`, `food_logs`, `body_logs`, `water_logs`, `workout_logs`, `wellness_logs`), `/api/v1/sync` table extensions, and per-module Reports with Weekly/Monthly/Yearly/Custom filters.
- **Milestone 4C — Menstrual Cycle, Notes & Journal, Focus Timer & Project Progress:** `menstrual_logs`, `notes`, `focus_sessions`, `projects` SQLite tables + sync + remaining module Reports & Dashboard widgets.

### 8. Acceptance Criteria
- [v] Review and approve [Design/PersonalLifeOS.html](Design/PersonalLifeOS.html) (Desktop & Mobile, Light & Dark).
- [v] Approve proposed `Milestone 4A–4C` split and SQLite/sync scope before database/code changes begin.
- [v] Implement Soft Pastel Minimalist theme tokens, collapsible Desktop sidebar, Mobile Bottom Nav + Workspace menu, and Global Quick Add (`+`) with 9 inline forms.
- [v] Implement Customizable Dashboard (`Dasbor`) with add/remove, drag-and-drop, reorder, visibility, resize (Desktop `S/M/L`), persistence, and reset across all 7 modules.
- [v] Implement Individual Module Reports (Productivity, Finance, Health, Wellness, Menstrual, Notes & Journal) with Weekly/Monthly/Yearly/Custom filters computed strictly from stored rows.
- [v] Implement per-device Audit Log (`audit_logs`) with token redaction and automatic API/sync error capture.

---

## Milestone 5: Phone Local IP & Sync Network Diagnostics (Completed — V0.3.0)
**Goal:** Display the phone's current local Wi-Fi/LAN IP address inside Mobile's **Sinkronisasi** card (in `Lainnya`) and refresh it cleanly so users can verify both Desktop and Mobile are on the same subnet when troubleshooting discovery or firewall issues.

### 1. Permissions Assessment
- **Android:** **No new permissions required.** Reading local non-loopback IPv4 addresses via `NetworkInterface.list()` only requires the install-time network permissions already declared in `mobile/android/app/src/main/AndroidManifest.xml` (`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`). Runtime Location (`ACCESS_FINE_LOCATION`) or Nearby Wi-Fi permissions are *not* required because only the IP address is read (not the Wi-Fi SSID/BSSID).
- **iOS:** **No new permissions required.** `NSLocalNetworkUsageDescription` is already declared in `mobile/ios/Runner/Info.plist`.

### 2. Proposed Changes
- **Mobile IP Helper (`SyncService` / `ChecklistProvider`):** Read non-loopback IPv4 addresses via `NetworkInterface.list(type: InternetAddressType.IPv4)`, prioritizing Wi-Fi/LAN interfaces (`wlan*`, `en*`) and falling back cleanly when offline (`Tidak terhubung ke Wi-Fi/LAN`).
- **Mobile Sync Card (`more_view.dart`):** Add an **IP Ponsel** row (plus discovered Desktop `host:port` when connected) and refresh on app resume / manual sync.
- **(Optional) Audit Log Context:** Include the phone's local IPv4 address (if available) in failed discovery/sync `audit_logs` details for faster subnet mismatch diagnosis.

### 3. Acceptance Criteria
- [v] Mobile displays current non-loopback LAN IPv4 address in the **Sinkronisasi** card without requesting any runtime permission dialogs.
- [v] Displays a clean fallback label when offline/disconnected and updates on refresh/resume.
- [v] Unit tests cover interface selection (Wi-Fi preference, offline fallback, cellular/VPN exclusion or ordering).

---

## Milestone 6: Personal Life OS Redesign v3 & Complete Module Workspaces (Completed — V0.3.0)
**References:** [Progress/Milestone6Draft.md](Progress/Milestone6Draft.md) and [Design/DesignRevisionM6.html](Design/DesignRevisionM6.html).

### 1. Visual System & Color Palette Picker (Default = M6 White & Pink)
- **Default Design Revision Palette (`White & Pink` v3):**
  - Background: `#FFFFFF`, Card: `#FFFFFF`, Soft surface: `#FFF7FA`, Primary pink button/accent: `#ED9FBD`, Pink highlight: `#FFF0F5`, Rose active/dark: `#B85F83`, Text: `#493640`, Muted text: `#A18C96`, Border: `#F2E5EB`, subtle shadow `0 3px 14px rgba(141,96,112,0.03)`.
- **Color Palette Picker in Settings (`Appearance` / `Options`):**
  - Persisted user preference (`color_palette` in `meta`, defaulting to `'pink'`) allowing instant switching across:
    1. **White & Pink (Default — M6 Revision):** `#FFFFFF` bg, `#ED9FBD` accent, `#FFF0F5` highlight, `#493640` ink
    2. **Soft Pastel Sage (V0.2):** `#F8F7F4` bg, `#3F7E68` accent, `#DCECE4` highlight, `#242A30` ink
    3. **Calm Slate Teal (V0.1):** `#F2F5F7` bg, `#1D7487` accent, `#DDEEF2` highlight, `#1B2730` ink
    4. **Lavender Mist:** `#FAF8FF` bg, `#8E7AB5` accent, `#EFEAF9` highlight, `#2F283D` ink
    5. **Warm Peach:** `#FFFDF9` bg, `#E29578` accent, `#FBECE6` highlight, `#3D2C26` ink
  - Supports Light mode (white cards) and Dark mode variants.

### 2. Core Interaction Principle — Full Category Workspaces
Each category is a self-contained workspace combining **inline input/edit controls**, **current data**, **searchable/editable history**, and **embedded module reports** on a single coherent page (Quick Add `+` remains an optional shortcut, never the only way to enter or edit data):
1. **Home / Dashboard:**
   - PC: Left sidebar (`Home`, `Productivity`, `Finance`, `Health`, `Wellness`, `Menstrual`, `Notes & Journal`, `Rewards`, `Settings`), greeting header + search, gentle banner, 3-column `Your spaces` category shortcut grid, `Today's tasks`, month calendar, quick mood check-in, and `Little note` quick save.
   - HP: Preserves mobile stacked cards and fixed bottom navigation (`Home`, `Tasks`, `Money`, `Health`, `More` sheet).
   - Direct inline dashboard editing (reorder, resize, show/hide, add/restore widgets without visiting Settings).
2. **Productivity Workspace:**
   - Task list with checkboxes, **priority badge**, **due date**, and inline add/edit/remove.
   - Calendar view + daily routines grouped by Morning / Afternoon / Evening (*Pagi / Siang / Malam*).
   - Project tracker (`In progress` / `Someday` backlog) and interactive **25:00 Focus / Pomodoro timer**.
   - Embedded *Insights & review* report (completion rate, most productive day, active projects, optional charts).
3. **Finance Workspace:**
   - Available balance, monthly income, and monthly expenses stat strip.
   - Inline *New transaction* form (`Expense`/`Income`, amount, description, category/envelope) + *Recent transactions* with search/filter and edit/delete.
   - Editable *Envelope budget* allocations, *Savings goals* with target progress bar, and *Bills & debt* tracker (recurring bills & installments).
   - Embedded *Monthly report* (income vs expense, envelope breakdown, savings & debt progress).
4. **Health Workspace:**
   - Current weight, water today, and movement minutes stat strip.
   - *Weight progress* (current vs goal weight) + *Body measurements* (`Waist`, `Hip`, `Chest`, `Arm`, `Thigh`).
   - *Food diary* by meal (`Breakfast`, `Lunch`, `Dinner`, `Snacks`) with calorie estimates.
   - Interactive *Water tracker* (`+ Add a glass` / target glasses) and *Workout* log.
   - Embedded *Health insights* report (weight change, average calories, workout time, optional charts).
5. **Wellness Workspace:**
   - Emoji mood check-in + Energy (`Low`/`Medium`/`High`) and Stress (`Low`/`Medium`/`High`) selectors.
   - *Daily journal*, *Sleep* hours logger, *Emotional triggers* reflection, and *Small gratitude* note.
   - Embedded *Weekly mental wellness review* (common mood, average energy, average sleep; gentle non-judgmental summaries).
6. **Menstrual Cycle Workspace:**
   - *Cycle calendar* highlighting period days and today, clearly labeling predictions as estimates (`Predictions are estimates, not medical certainty`).
   - *Next period estimate* card, *Cycle history* (average cycle length, average period length, recorded cycles), selectable *Today's symptoms* chips (`cramps`, `bloating`, `headache`, `fatigue`, `acne` + custom notes), and *Mood during cycle*.
   - Embedded *Cycle insights* & configurable reminder preferences.
7. **Notes & Journal Workspace:**
   - Search bar, category filters (`All notes`, `Daily journal`, `Brain dump`, `Gratitude`, `Pinned`), *Pinned notes* cards, and PC split-view / Mobile simple screen *Quick editor* (title, body, category, pin/unpin, archive/delete).
8. **Rewards Workspace:**
   - Points banner (`Missed days never take points away`), 3-column reward cards with `Redeem` button, *Achievements* milestones (`First step`, `Consistency week`, `Little by little`), and *Reward history*.
9. **Settings:**
   - App-level preferences only: **Profile & Appearance** (**Display Name (`user_name`)** updating the top `Hello, <Name> ♡` greeting, Theme mode, **Color Palette Picker** defaulting to *White & Pink*, Language selector, Dashboard density), **Reports & data** (`Show charts in reports` optional toggle, Local LAN Sync status, Automatic backup, Export/Restore data).

### 3. Confirmed Revision Decisions
- [v] **Revision Check 1 — Sync & Storage Architecture:** Keep local SQLite + zero-config LAN auto-discovery (`mDNS` / `UDP` per `CLAUDE.md`) and add local automatic pre-migration backup + JSON export/restore in Settings.
- [v] **Revision Check 2 — UI Language:** Add a Language selector in Settings (`English` / `Bahasa Indonesia`, persisted in `meta`).
- [v] **Revision Check 3 — Mobile Bottom Navigation Tabs:** Use the 5-tab layout from [Design/DesignRevisionM6.html](Design/DesignRevisionM6.html) (`Home`, `Tasks`, `Money`, `Health`, `More` bottom sheet with `Wellness`, `Menstrual`, `Notes`, `Rewards`, `Audit Log`, `Settings`).

---

## Milestone 7: Manual Sync IP Address & Port Connection (Completed — V0.3.1)
**Goal:** Enable users to manually configure and connect to an explicit sync IP address and port when mDNS/UDP broadcast is restricted by routers, VPNs, guest networks, or custom firewall ports—while keeping zero-config LAN auto-discovery as the default.

### 1. Mobile Sync Client Override
- **Local Endpoint Storage (`meta` table):** Store local-only `manual_sync_enabled` (`'true'`/`'false'`), `manual_sync_host` (normalized IPv4/host), and `manual_sync_port` (integer `1..65535`, default `47800`) without modifying synced tables.
- **`SyncService` Direct Verification & Discovery Override:**
  - `SyncService.setManualEndpoint(...)` and `SyncService.connectManual(...)` sanitize pasted URLs/hosts (`http://host:port` -> `host`), validate port `1..65535`, verify `/api/v1/ping`, persist `last_sync_host`/`last_sync_port`/`last_sync_device_id`, and log `MANUAL_UNREACHABLE` audit diagnostics if unreachable.
  - `discoverDesktop()` routes straight to `connectManual()` when `manual_sync_enabled` is active so both `pair()` and `sync()` use the configured endpoint deterministically.
- **Mobile Settings UI (`MoreView` -> Network & Sync card):** Add *Manual IP & Port* switch, `Desktop IP` input, `Port` input (`47800`), **Save & Connect** action (triggering pairing dialog automatically if unpaired), and **Use Auto LAN** reset.

### 2. Desktop Sync Server Listen IP & Port
- **Configurable Bind IP & Port (`meta` table + `SyncServer` / `DiscoveryService`):**
  - Store `sync_bind_ip` (default `'0.0.0.0'`) and `sync_port` (default `'47800'`), validate bind IP (`0.0.0.0`, `localhost`, or IPv4) and port (`1..65535`), gracefully restart `SyncServer` live without app restart (`settings:set-network`), and update mDNS/UDP discovery announcements (`DiscoveryService.updatePort()`).
- **Desktop Settings UI (`Settings` -> Local LAN Sync card):** Add *Manual Listen IP & Port* (`Bind IP` with LAN interface suggestions + `Port` + **Apply** + **Reset 47800**).

### 3. Acceptance Criteria
- [v] Mobile can save an explicit IP & port, connect directly to `/api/v1/ping`, pair with the 6-digit code, and complete two-way LWW sync without relying on mDNS or UDP broadcast.
- [v] Desktop can reconfigure its Sync Server bind IP and port live in Settings, persist across restarts, and roll back cleanly on bind failure.
- [v] Invalid ports or empty hosts are rejected safely without breaking local auto-discovery mode.

---

## Milestone 8: Bug Fixes, QoL & Indonesian Language Audit (Completed — V0.3.1)
**Goal:** Improve daily usability and visual comfort across Desktop and Mobile through pinned motivational reminders, full Envelope Budget management, newest-first comfortable Mobile Notes, permanent task step cleanup, and a complete Bahasa Indonesia consistency audit.

### 1. Priorities & Improvements
1. **Little Note as Pinned Motivational Reminder:**
   - Transform Home's **Little Note** (*Catatan Kecil*) into a persistent **Pinned Motivational Reminder** stored in SQLite (`notes` with `is_pinned = 1`, synced across Desktop & Mobile).
   - prominently display the saved motivational quote inside a soft pink pinned reminder card (with a calm default fallback until customized) and allow editing/updating it inline without clutter.
2. **Envelope Budget Edit & Delete:**
   - Enable inline editing (name & monthly budget limit) and soft deletion of **Envelope Budget** items on both **Desktop** (`Finance` workspace) and **Mobile** (`FinanceWorkspaceView`), preserving existing transaction references cleanly.
3. **Mobile Notes Ordering & Readable Typography:**
   - Sort notes strictly newest-saved first (`updated_at DESC, day DESC`) so newly created or edited notes immediately appear at position #1 at the top of the list regardless of pinned status.
   - Increase font sizes, line height, and input comfort in `NotesWorkspaceView` (editor title/body fields, pinned reminder box, and saved note preview cards).
4. **Restore & Delete Permanently for Deactivated Task Steps:**
   - Add **Delete Permanently** (*Hapus Permanen*) alongside **Restore** (*Pulihkan*) for deactivated task steps in **Inactive** views on both Desktop (`#v-off`) and Mobile (`MoreView`), complete with confirmation prompts, check cleanup, and sync tombstone propagation (`deleted_tasks`) so permanently deleted steps do not reappear on subsequent LAN syncs.
5. **Bahasa Indonesia & Bilingual Consistency Audit:**
   - Audit and complete English (`en`) and Bahasa Indonesia (`id`) copy across all Desktop (`lifeos.js`, `app.js`, `index.html`) and Mobile (`AppStrings`, workspaces, Home, Tasks, Trail, Rewards, Settings, Quick Add, Audit Log) views so zero untranslated mixed strings remain in either language.

### 2. Acceptance Criteria
- [v] Home Little Note displays and persists a pinned motivational reminder across reloads and LAN sync.
- [v] Envelopes can be created, edited (name & monthly budget), and deleted on both Desktop and Mobile.
- [v] Saving/editing a note on Mobile places it at the top of the notes list with comfortable readable typography.
- [v] Deactivated task steps support both Restore and confirmed Delete Permanently across Desktop, Mobile, and LAN sync tombstones.
- [v] Switching language between English (`EN`) and Bahasa Indonesia (`ID`) updates headers, workspaces, buttons, dialogs, and status messages consistently across both platforms.
- [v] **Revision Check 4 — Color Palette Picker Options:** Approved the 5 palettes in [Design/DesignRevisionM6.html](Design/DesignRevisionM6.html) (*White & Pink* default, *Soft Pastel Sage*, *Calm Slate Teal*, *Lavender Mist*, *Warm Peach*) + Light/Dark mode.

### 4. Proposed Phased Implementation Plan (Once Revisions Confirmed)
- **Phase 6A — Backup, Schema Migration & Theme/Palette Engine:** Automatic SQLite backup before migration; add fields/tables for task priority/due-date, savings goals, recurring bills, meal slots, body measurements (`waist/hip/chest/arm/thigh`), note categories/pinned state, and achievements; implement `color_palette` & `show_report_charts` preferences across Desktop and Mobile.
- **Phase 6B — Home Dashboard v3 & Full Productivity/Rewards Workspaces:** Update Desktop & Mobile navigation shells, `Your spaces` shortcuts, inline task/routine/project/Pomodoro workspace, and Rewards + Achievements.
- **Phase 6C — Full Finance, Health, Wellness, Menstrual & Notes Workspaces:** Replace report-only views with complete inline-entry + history + embedded report workspaces for all remaining modules, honoring the optional charts toggle.
- **Phase 6D — Data Export/Backup & End-to-End Verification:** JSON/SQLite backup & export in Settings, plus Desktop (`node --test`) and Mobile (`flutter analyze` / `flutter test`) verification.
