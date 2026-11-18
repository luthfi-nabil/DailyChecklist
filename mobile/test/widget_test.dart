import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langkah_kecil/core/database/database_helper.dart';
import 'package:langkah_kecil/data/repositories/checklist_repository.dart';
import 'package:langkah_kecil/data/services/sync_service.dart';
import 'package:langkah_kecil/main.dart';
import 'package:langkah_kecil/presentation/providers/checklist_provider.dart';

void main() {
  testWidgets('LangkahKecilApp renders navigation and allows checking a task', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    late Database db;
    late ChecklistProvider provider;

    await tester.runAsync(() async {
      sqfliteFfiInit();
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await DatabaseHelper.createTables(db);
            await DatabaseHelper.seedDefaultData(db);
          },
        ),
      );

      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      final sync = SyncService(
        repository: repo,
        customDiscovery: () async => null,
      );
      await sync.setAutoSync(false);

      provider = ChecklistProvider(repository: repo, syncService: sync);
      await provider.init();
    });

    await tester.pumpWidget(LangkahKecilApp(provider: provider, useGoogleFonts: false));
    await tester.pumpAndSettle();

    expect(find.text('Hari ini'), findsWidgets);
    expect(find.text('Dasbor'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.byKey(const Key('global_fab')), findsOneWidget);

    // Complete focus task via "Sudah selesai"
    expect(find.text('Sudah selesai'), findsOneWidget);
    await tester.runAsync(() async {
      await provider.toggleTaskCheck(provider.nextFocusTask!.id, true);
    });
    await tester.pumpAndSettle();

    expect(provider.pointsBalance, 1);

    // Toggle calendar visibility via 📅 chip (starts closed, opens on tap)
    expect(find.text('Mingguan'), findsNothing);
    await tester.tap(find.byKey(const Key('calendar_toggle_chip')));
    await tester.pumpAndSettle();
    expect(find.text('Mingguan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_toggle_chip')));
    await tester.pumpAndSettle();
    expect(find.text('Mingguan'), findsNothing);

    // Enter Ubah mode and verify frequency pill below input & group reorder
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    expect(find.text('Setiap hari'), findsWidgets);

    final firstGroupId = provider.todayGroups[0].id;
    final secondGroupId = provider.todayGroups[1].id;
    final moveDownFinder = find.byKey(Key('move_group_down_$firstGroupId'));
    expect(moveDownFinder, findsOneWidget);
    final moveDownBtn = tester.widget<IconButton>(moveDownFinder);
    expect(moveDownBtn.onPressed, isNotNull);
    await tester.runAsync(() async {
      moveDownBtn.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(provider.todayGroups[0].id, secondGroupId);
    expect(provider.todayGroups[1].id, firstGroupId);

    // Navigate to Dasbor tab (Customizable Personal Life OS Dashboard)
    await tester.tap(find.text('Dasbor').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('customize_dashboard_btn')), findsOneWidget);
    expect(find.text('Finance & Budget'), findsOneWidget);

    // Open Global Quick Add (+) sheet from any page
    await tester.tap(find.byKey(const Key('global_fab')));
    await tester.pumpAndSettle();
    expect(find.text('Add income/expense'), findsOneWidget);
    expect(find.text('Mood check-in'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss bottom sheet
    await tester.pumpAndSettle();

    // Navigate to Laporan tab (Individual Module Reports)
    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Menstrual'), findsOneWidget);

    // Open Workspace menu -> Jejak
    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Audit Log'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ws_tile_Jejak')));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat'), findsOneWidget);

    // Open Workspace menu -> Lainnya
    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('ws_tile_Lainnya')));
    await tester.tap(find.byKey(const Key('ws_tile_Lainnya')));
    await tester.pumpAndSettle();
    expect(find.text('Sinkronisasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tampilan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Tampilan'), findsOneWidget);

    // Verify Workspace sheet renders with zero overflow on narrow 360x640 mobile screen
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ws_tile_Productivity')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(null);

    // Unmount widget before disposing provider & db
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      provider.dispose();
      await db.close();
    });
  });
}
