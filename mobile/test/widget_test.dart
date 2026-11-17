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
    expect(find.text('Hadiah'), findsOneWidget);
    expect(find.text('Jejak'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);

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

    // Navigate to Jejak tab
    await tester.tap(find.text('Jejak'));
    await tester.pumpAndSettle();
    expect(find.text('Dasbor'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    // Navigate to Lainnya tab
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Sinkronisasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tampilan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Tampilan'), findsOneWidget);

    // Unmount widget before disposing provider & db
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      provider.dispose();
      await db.close();
    });
  });
}
