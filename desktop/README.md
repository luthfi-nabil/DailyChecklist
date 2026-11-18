# Langkah Kecil — Desktop App (Electron)

A calm, distraction-free daily checklist and habit tracking desktop app with zero-configuration local network sync.

## Features
- **Local-first Persistence**: Backed by SQLite via Node.js native `node:sqlite`.
- **Milestone 1 Core Flow**: Grouped tasks (Pagi, Siang, Malam), single next-step focus card, "Hari berat" (lite mode), rewards shop with point balance, inline edit mode with undo toast.
- **Milestone 2 Dashboard & Logging**: Activity dashboard (weekly, monthly, all-time metrics, streaks, daily bar chart), calendar activity heatmap, past day logs with timestamps, soft deletion (deactivation) preserving historical trends.
- **Milestone 3 Scheduled Activities & Group Ordering**: Daily/Weekly/Monthly activity schedules (`freq`, `freq_days`), interactive checklist calendar with indicator dots, schedule editor modal, scheduled-day dashboard rates, and `↑` / `↓` group reordering.
- **Milestone 4+ Personal Life OS & Audit Log**: Soft Pastel Minimalist theme, collapsible sidebar, customizable 7-module Dashboard, Individual Module Reports (Productivity, Finance, Health, Wellness, Menstrual, Notes & Journal) with range filters, Global Quick Add (`+`), and local `audit_logs` API/sync diagnostics.
- **Zero-Config Sync Server**: Built-in HTTP sync server with mDNS (`_langkahkecil._tcp`) and UDP 47899 discovery.
- **Desktop Background Mode**: Single-instance lock, system tray icon with background operation, toggleable autostart with `--hidden` launch.

## Architecture
- `src/main/main.js`: Main process lifecycle, single-instance enforcement, system tray, window management.
- `src/main/data/db.js`: Database initialization, deterministic seed data, monotonic `seq` tracking.
- `src/main/data/repository.js`: CRUD, soft deletion/reactivation, points derivation, dashboard analytics, LWW sync export/import.
- `src/main/services/syncServer.js`: HTTP API (`/api/v1/ping`, `/pair`, `/sync`), token-based authentication, rate limiting.
- `src/main/services/discoveryService.js`: mDNS service advertiser + UDP 47899 discovery responder.
- `src/main/ipc/handlers.js`: Electron IPC bridge.
- `src/preload/preload.js`: Secure `contextBridge` isolation.
- `src/renderer/`: Pure HTML + CSS + ES Module frontend matching `Design/DesktopDesign.html`.

## Running & Building Installer
```bash
# Run unit tests
npm.cmd test

# Launch Electron application
npm.cmd start

# Build Windows NSIS installer (.exe in desktop/dist/)
npm.cmd run dist:win
```

### Windows Firewall Note
When first launched, Windows Defender Firewall may display a prompt to allow network communication for Node.js/Electron. Check "Private networks" to allow discovery and sync with the mobile app over local Wi-Fi.
