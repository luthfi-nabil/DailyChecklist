# Langkah Kecil — Data Model & Sync Protocol v1

Shared contract between **desktop** (Electron, `desktop/`) and **mobile** (Flutter, `mobile/`). Both apps MUST follow it exactly so they interoperate.

## 1. Principles
- Local-first: each app works fully offline on its own SQLite DB. Sync is best-effort.
- **Desktop is the sync server** (HTTP on LAN). **Mobile is always the client/initiator** (mobile OSes cannot be pushed to when asleep). Desktop never needs mobile's IP.
- Row-level **last-writer-wins (LWW)** by `updated_at` (epoch ms, writer's clock). Tie-break: larger `device_id` string wins.
- No hard deletes. Removing a group/task/reward = `is_active=0` + `deactivated_at=<ms>` (soft delete). Reactivation sets `is_active=1, deactivated_at=NULL`. Every change bumps `updated_at`.
- **Points are derived, never stored as a counter** (counters conflict on merge):
  `balance = COUNT(checks WHERE checked=1) - SUM(claims.cost)`, min 0 for display. Missed days never deduct.
- History is never capped (no 60-day / 20-claim limits in the DB; UI may show only recent claims).
- IDs are UUID v4 strings generated client-side.
- Day key = local date `YYYY-MM-DD` of the device when the action happened.

## 2. SQLite schema (identical on both apps; table/column names fixed)
```sql
CREATE TABLE groups   (id TEXT PRIMARY KEY, name TEXT NOT NULL, sort INTEGER NOT NULL DEFAULT 0,
                       is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL);
CREATE TABLE tasks    (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, name TEXT NOT NULL, core INTEGER NOT NULL DEFAULT 0,
                       sort INTEGER NOT NULL DEFAULT 0, freq TEXT NOT NULL DEFAULT 'daily', freq_days TEXT,
                       priority TEXT NOT NULL DEFAULT 'normal', due_date TEXT,
                       is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL);
CREATE TABLE rewards  (id TEXT PRIMARY KEY, name TEXT NOT NULL, cost INTEGER NOT NULL, sort INTEGER NOT NULL DEFAULT 0,
                       is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL);
CREATE TABLE checks   (task_id TEXT NOT NULL, day TEXT NOT NULL, checked INTEGER NOT NULL, updated_at INTEGER NOT NULL,
                       PRIMARY KEY (task_id, day));            -- unchecking sets checked=0 (row kept); updated_at = time of last toggle (the "completed at" shown in the log)
CREATE TABLE claims   (id TEXT PRIMARY KEY, reward_id TEXT, name TEXT NOT NULL, cost INTEGER NOT NULL, day TEXT NOT NULL,
                       claimed_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);   -- append-only (see undo semantics below)
CREATE TABLE projects (id TEXT PRIMARY KEY, name TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'active',
                       progress INTEGER NOT NULL DEFAULT 0, is_someday INTEGER NOT NULL DEFAULT 0,
                       is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE focus_sessions (id TEXT PRIMARY KEY, task_id TEXT, project_id TEXT, day TEXT NOT NULL,
                             minutes INTEGER NOT NULL, note TEXT, updated_at INTEGER NOT NULL);
CREATE TABLE finance_envelopes (id TEXT PRIMARY KEY, name TEXT NOT NULL, monthly_budget INTEGER NOT NULL DEFAULT 0,
                                is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE finance_entries (id TEXT PRIMARY KEY, day TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL DEFAULT 'general',
                              amount INTEGER NOT NULL, envelope_id TEXT, note TEXT, is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE savings_goals   (id TEXT PRIMARY KEY, name TEXT NOT NULL, target_amount INTEGER NOT NULL DEFAULT 0,
                              current_amount INTEGER NOT NULL DEFAULT 0, deadline TEXT,
                              is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE recurring_bills (id TEXT PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL DEFAULT 'bill',
                              amount INTEGER NOT NULL DEFAULT 0, due_day INTEGER NOT NULL DEFAULT 1,
                              is_paid INTEGER NOT NULL DEFAULT 0, last_paid_month TEXT,
                              is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE health_entries  (id TEXT PRIMARY KEY, day TEXT NOT NULL, kind TEXT NOT NULL, name TEXT,
                              meal_slot TEXT, value_num REAL NOT NULL, value_num2 REAL, unit TEXT, note TEXT,
                              is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE wellness_entries (id TEXT PRIMARY KEY, day TEXT NOT NULL, mood TEXT NOT NULL, mood_score INTEGER NOT NULL,
                               energy INTEGER NOT NULL, stress INTEGER NOT NULL, sleep_hours REAL NOT NULL,
                               triggers_text TEXT, gratitude_text TEXT, note TEXT, is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE menstrual_entries (id TEXT PRIMARY KEY, day TEXT NOT NULL, phase TEXT NOT NULL, cycle_day INTEGER NOT NULL DEFAULT 1,
                                flow TEXT, symptoms_json TEXT, is_period_start INTEGER NOT NULL DEFAULT 0,
                                cycle_length INTEGER, note TEXT, is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE notes    (id TEXT PRIMARY KEY, day TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL,
                       tags_json TEXT, category TEXT NOT NULL DEFAULT 'journal', is_pinned INTEGER NOT NULL DEFAULT 0,
                       is_active INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL);
CREATE TABLE audit_logs (id TEXT PRIMARY KEY, created_at INTEGER NOT NULL, day TEXT NOT NULL, source TEXT NOT NULL,
                         category TEXT NOT NULL, level TEXT NOT NULL, endpoint TEXT NOT NULL, status_code INTEGER,
                         error_code TEXT, message TEXT NOT NULL, details_json TEXT); -- local-only per device, never synced
CREATE TABLE meta     (key TEXT PRIMARY KEY, value TEXT);      -- device_id, device_name, last_sync_cursor, paired_token, dashboard_layout_v1, color_palette, user_name, language, show_report_charts, etc.
```
Extra local-only bookkeeping columns are allowed (e.g. `dirty INTEGER` on mobile, `seq INTEGER` on desktop) but are NOT part of the wire format.

Local-only UI state (NOT synced): Lite mode ("Hari berat"), theme, skipped focus items, `dashboard_layout_v1` (device-specific widget sizing/order), and `audit_logs` (API/sync error history per device).

Seed data on first run (only when DB is empty and nothing has been synced): groups Pagi/Siang/Malam, tasks and rewards exactly as in `Design/DesktopDesign.html` / `Design/MobileDesign.html`. If the first sync finds the server already has data, the client should adopt it and **not** double-seed (mobile: if never synced, it may keep its seed rows; to avoid duplicate default groups, seed rows use **deterministic IDs**: `seed-group-pagi`, `seed-task-p1`, `seed-reward-1`, etc., and a fixed initial timestamp `updated_at = 1` so any real edit/deactivation on either device always wins regardless of install order).

Undo semantics (UI): undo of deactivate → set `is_active=1` with new `updated_at`. Undo of claim → delete the claim row **locally** only if its `updated_at` is newer than the last successful sync; otherwise insert a compensating behaviour is out of scope — simply disallow undo once synced. Undo of check → toggle again.

## 3. Wire format (JSON, snake_case, ints for booleans)
Entity shapes = the table columns above (no bookkeeping columns):
- `group`: `{id,name,sort,is_active,deactivated_at,updated_at}`
- `task`: `{id,group_id,name,core,sort,freq,freq_days,priority,due_date,is_active,deactivated_at,updated_at}` (`freq`: `'daily'|'weekly'|'monthly'`, `freq_days`: JSON array string e.g. `"[1,3,5]"` or `null`, `priority`: `'low'|'normal'|'high'`, `due_date`: `YYYY-MM-DD` or `null`)
- `reward`: `{id,name,cost,sort,is_active,deactivated_at,updated_at}`
- `check`: `{task_id,day,checked,updated_at}`
- `claim`: `{id,reward_id,name,cost,day,claimed_at,updated_at}`
- `project`: `{id,name,status,progress,is_someday,is_active,updated_at}`
- `focus_session`: `{id,task_id,project_id,day,minutes,note,updated_at}`
- `finance_envelope`: `{id,name,monthly_budget,is_active,updated_at}`
- `finance_entry`: `{id,day,type,category,amount,envelope_id,note,is_active,updated_at}`
- `savings_goal`: `{id,name,target_amount,current_amount,deadline,is_active,updated_at}`
- `recurring_bill`: `{id,name,kind,amount,due_day,is_paid,last_paid_month,is_active,updated_at}`
- `health_entry`: `{id,day,kind,name,meal_slot,value_num,value_num2,unit,note,is_active,updated_at}` (`kind`: `'food'|'weight'|'water'|'workout'|'measurement'`)
- `wellness_entry`: `{id,day,mood,mood_score,energy,stress,sleep_hours,triggers_text,gratitude_text,note,is_active,updated_at}`
- `menstrual_entry`: `{id,day,phase,cycle_day,flow,symptoms_json,is_period_start,cycle_length,note,is_active,updated_at}`
- `note`: `{id,day,title,body,tags_json,category,is_pinned,is_active,updated_at}`

`Changes` object: `{ "groups":[...], "tasks":[...], "rewards":[...], "checks":[...], "claims":[...], "projects":[...], "focus_sessions":[...], "finance_envelopes":[...], "finance_entries":[...], "savings_goals":[...], "recurring_bills":[...], "health_entries":[...], "wellness_entries":[...], "menstrual_entries":[...], "notes":[...] }` (any key may be omitted/empty).

## 4. HTTP API (desktop server, default port **47800**, plain HTTP, JSON, UTF-8)
Server binds `0.0.0.0`. If 47800 is busy it tries 47801…47809 and advertises the real port.

| Method & path | Auth | Request | Response |
|---|---|---|---|
| `GET /api/v1/ping` | none | – | `{"app":"langkah-kecil","v":1,"device_id":"…","device_name":"…","paired":true|false}` |
| `POST /api/v1/pair` | none | `{"code":"123456","device_id":"…","device_name":"…"}` | `200 {"token":"<random 32+ chars>","expires_at":<ms>}` or `403 {"error":"bad_code"}` |
| `POST /api/v1/sync` | `Authorization: Bearer <token>` | `{"since":<int cursor>,"device_id":"…","changes":Changes}` | `{"cursor":<int>,"changes":Changes,"server_time":<ms>,"token_expires_at":<ms>}` |

**Pairing:** desktop Settings shows a 6-digit pairing code (regenerates after each successful pairing and on request) and a token validity selector (`3–7` days, default `7` days). Mobile prompts for the code once, then stores `paired_token` and `token_expires_at` in `meta`. Tokens are stored on desktop in `meta` (list of paired devices `{device_id,device_name,token,paired_at,expires_at}`; show them in Settings with a "Putuskan" (revoke) action). Invalid or expired token → `401 {"error":"unauthorized"|"token_expired"}` → mobile clears token and asks to pair again. Rate-limit bad codes (e.g. 5 attempts/min).

**Sync semantics (`POST /api/v1/sync`):**
1. Server applies each incoming row with LWW (`incoming.updated_at > existing.updated_at`, tie → larger `device_id`; rows that don't exist are inserted). For `checks` key is `(task_id,day)`. For `claims`, insert if id missing (ignore otherwise, except `updated_at` newer wins).
2. Every row that the server writes (from local edits OR accepted from a client) gets `seq = ++server_seq` (monotonic integer kept on desktop in a local `seq` column per table + counter in `meta`).
3. Server responds with all rows whose `seq > since` **excluding rows it just accepted from this same request**, plus `cursor = current server_seq`. Client stores `cursor` as `last_sync_cursor` and uses it as `since` next time. `since=0` returns everything (initial sync).
4. Client pushes only rows changed locally since last successful sync (mobile: `dirty=1`; clear flags only after a 200 response) and applies returned rows with the same LWW rule (not marking them dirty).
5. Idempotent: repeating a request is safe.

## 5. Discovery (zero config — user never types an IP)
Desktop advertises; mobile discovers. Implement BOTH, mobile tries mDNS first (≈3 s) then UDP fallback:
1. **mDNS / DNS-SD**: service type `_langkahkecil._tcp`, instance name = device name, port = server port, TXT `{id:<device_id>, v:"1"}`.
2. **UDP broadcast fallback**: desktop listens on UDP port **47899**. Mobile sends datagram `LANGKAH_DISCOVER?v=1` to `255.255.255.255:47899` (and subnet broadcast if easy). Desktop replies (unicast to sender) with JSON `{"app":"langkah-kecil","v":1,"device_id":"…","device_name":"…","port":47800}`. Host = sender address of the reply.
After discovery mobile calls `GET /api/v1/ping` to verify `app=="langkah-kecil"`. Mobile remembers the last good host:port and device_id and tries it first, then re-discovers if it fails (IP can change; match by `device_id`).

## 6. When mobile syncs
On app start/resume, ~2 s after any local change (debounced), every 60 s while foregrounded, and on manual "Sinkronkan sekarang". Show status: connected / syncing / last synced time / "Desktop tidak ditemukan". Failures never block the UI. Desktop UI refreshes automatically when a sync brings in changes (and shows "Sinkron aktif · <device> · <time ago>").

## 7. Desktop background behaviour
- Setting "Jalankan saat komputer menyala" → `app.setLoginItemSettings({openAtLogin, args:['--hidden']})`; with `--hidden` start minimized to tray (no window).
- Setting "Tetap jalan saat jendela ditutup" (default on) → closing the window hides to tray; tray menu: Buka, Sinkron aktif status, Keluar. Sync server + discovery keep running while hidden. Single-instance lock.
- Windows Firewall will prompt on first run; document it in README.

## 8. Security notes
LAN-only plain HTTP + bearer token from pairing. Do not log tokens. Mobile Android needs cleartext HTTP allowed (network security config / `usesCleartextTraffic`) plus `INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`; iOS needs `NSLocalNetworkUsageDescription` and `NSBonjourServices = [_langkahkecil._tcp]`.
