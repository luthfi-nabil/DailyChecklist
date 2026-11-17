# Langkah Kecil — Mobile App (Flutter)

Cross-platform Flutter mobile app for **Langkah Kecil**, designed around a calm single-column layout (`Design/MobileDesign.html`) with local SQLite persistence and zero-config LAN sync to the Electron desktop server.

## Architecture
- `lib/core/`: Color tokens (`app_colors.dart`), theme (`app_theme.dart`), SQLite database & seed initialization (`database_helper.dart`).
- `lib/domain/models/`: Immutable domain models (`GroupItem`, `TaskItem`, `RewardItem`, `CheckItem`, `ClaimItem`, `DashboardStats`, `DayLog`).
- `lib/data/repositories/`: `ChecklistRepository` implementing local persistence, soft deletes, analytics queries, and LWW merge.
- `lib/data/services/`: `SyncService` implementing mDNS (`_langkahkecil._tcp`) + UDP port 47899 fallback discovery, 6-digit pairing, and periodic/debounced HTTP sync.
- `lib/presentation/`: `ChecklistProvider` (`ChangeNotifier`) + bottom-nav screens (`TodayView`, `RewardsView`, `TrailView`, `MoreView`).

## Running, Testing & Building APK
```bash
# Static analysis
flutter analyze

# Unit & widget tests (uses sqflite_common_ffi)
flutter test

# Build debug APK (for quick testing)
flutter build apk --debug

# Build release APK (installable on Android phones)
flutter build apk --release
```
Output APK path: `build/app/outputs/flutter-apk/app-release.apk` (or `app-debug.apk`).
