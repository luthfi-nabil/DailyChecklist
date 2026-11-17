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
