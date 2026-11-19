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
  testWidgets('Milestone 5 & 6: 5-tab nav, workspaces, palette picker, name update & Phone IP', (tester) async {
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

    // Home renders DesignRevisionM6 White & Pink greeting, hero banner, editable spaces & widgets
    expect(find.text('Hello, User ♡'), findsOneWidget);
    expect(find.text('Take it one step at a time.'), findsOneWidget);
    expect(find.byKey(const Key('edit_spaces_btn')), findsOneWidget);
    expect(find.byKey(const Key('space_card_w-fin')), findsOneWidget);

    // Toggle Your spaces visibility + custom rename, verifying persistence after Done
    await tester.tap(find.byKey(const Key('edit_spaces_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('space_vis_w-fin')), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('space_vis_w-fin')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_spaces_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('space_card_w-fin')), findsNothing);

    await tester.tap(find.byKey(const Key('edit_spaces_btn')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('space_vis_w-fin')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await provider.renameDashboardWidget('w-fin', 'My Wallet');
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_spaces_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('space_card_w-fin')), findsOneWidget);
    expect(find.text('My Wallet'), findsOneWidget);

    final homeScroll = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text("Today's tasks"), 200, scrollable: homeScroll);
    expect(find.text("Today's tasks"), findsOneWidget);

    await tester.scrollUntilVisible(find.text('How are you feeling?'), 200, scrollable: homeScroll);
    expect(find.text('How are you feeling?'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Little note'), 200, scrollable: homeScroll);
    expect(find.text('Little note'), findsOneWidget);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const Key('global_quick_add_fab')), findsOneWidget);

    // Navigate to Tasks tab
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();

    // Toggle calendar visibility via 📅 chip before scrolling down
    await tester.tap(find.byKey(const Key('calendar_toggle_chip')));
    await tester.pumpAndSettle();
    expect(find.text('Mingguan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_toggle_chip')));
    await tester.pumpAndSettle();
    expect(find.text('Mingguan'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Focus Pomodoro'),
      300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
    );
    expect(find.text('Focus Pomodoro'), findsOneWidget);

    await tester.runAsync(() async {
      await provider.toggleTaskCheck(provider.nextFocusTask!.id, true);
    });
    await tester.pumpAndSettle();
    expect(provider.pointsBalance, 1);

    // Navigate to Money workspace
    await tester.runAsync(() async {
      await tester.tap(find.text('Money').last);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Income'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Log Transaction'),
      250,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Log Transaction'), findsOneWidget);

    // Navigate to Health workspace
    await tester.runAsync(() async {
      await tester.tap(find.text('Health').last);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Water Intake'), findsOneWidget);

    // Open More bottom sheet -> verify Phone IP subtitle & open Settings
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ws_tile_10')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ws_tile_10')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('palette_pink')), findsOneWidget);
    expect(find.byKey(const Key('palette_lavender')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('phone_ip_value')),
      250,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.byKey(const Key('phone_ip_value')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('manual_connect_btn')),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.byKey(const Key('manual_sync_switch')), findsOneWidget);
    expect(find.byKey(const Key('manual_ip_input')), findsOneWidget);
    expect(find.byKey(const Key('manual_port_input')), findsOneWidget);

    await tester.runAsync(() async {
      await provider.configureManualSync(enabled: true, host: '192.168.1.99', port: 47850);
    });
    await tester.pumpAndSettle();
    expect(provider.syncService.useManualEndpoint, true);
    expect(provider.syncService.manualHost, '192.168.1.99');
    expect(provider.syncService.manualPort, 47850);
    await tester.runAsync(() async {
      await provider.configureManualSync(enabled: false, host: '192.168.1.99', port: 47850);
    });

    // Switch color palette & update display name
    await tester.runAsync(() async {
      await provider.updateAppPreferences(colorPalette: 'lavender', userName: 'Luthfi');
    });
    await tester.pumpAndSettle();
    expect(provider.prefs.colorPalette, 'lavender');
    expect(provider.prefs.userName, 'Luthfi');

    // Return Home and verify updated greeting
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Luthfi ♡'), findsOneWidget);

    // Verify 360x640 mobile viewport has zero overflow on Home, More sheet & M6 workspaces
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpAndSettle();

    Future<void> openFromMore(String keyName) async {
      final moreBtn = tester.any(find.text('More')) ? find.text('More') : find.text('Lainnya');
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(Key(keyName)));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
    }

    await openFromMore('ws_tile_4'); // Wellness
    expect(find.text('How are you today?'), findsOneWidget);

    await openFromMore('ws_tile_5'); // Menstrual
    expect(find.text('NEXT PERIOD ESTIMATE'), findsOneWidget);

    await openFromMore('ws_tile_6'); // Notes
    expect(find.text('Quick editor'), findsOneWidget);

    await openFromMore('ws_tile_7'); // Rewards
    expect(find.text('YOUR POINTS'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ws_tile_10')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Navigate back to Home tab before testing Milestone 8 Home & tab flows
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Milestone 8: Home Little Note as Pinned Motivational Reminder
    await tester.scrollUntilVisible(
      find.byKey(const Key('little_note_edit_btn')),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.textContaining('Pinned reminder'), findsOneWidget);
    await tester.tap(find.byKey(const Key('little_note_edit_btn')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('little_note_save_btn')),
      150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.enterText(find.byKey(const Key('little_note_input')), 'Focus on calm progress today ♡');
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('little_note_save_btn')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Focus on calm progress today ♡'), findsOneWidget);

    // Milestone 8: Finance Envelope Edit & Delete at narrow 360x640 viewport
    await tester.runAsync(() async {
      await tester.tap(find.text('Money').last);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('env_name_input')),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.enterText(find.byKey(const Key('env_name_input')), 'Coffee');
    await tester.enterText(find.byKey(const Key('env_budget_input')), '250000');
    await tester.ensureVisible(find.byKey(const Key('env_save_btn')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('env_save_btn')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    final envId = provider.envelopes.firstWhere((e) => e['name'] == 'Coffee')['id'] as String;
    await tester.scrollUntilVisible(
      find.byKey(Key('env_edit_$envId')),
      150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.byKey(Key('env_edit_$envId')));
    await tester.tap(find.byKey(Key('env_edit_$envId')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('env_name_input')), 'Coffee & Tea');
    await tester.enterText(find.byKey(const Key('env_budget_input')), '300000');
    await tester.ensureVisible(find.byKey(const Key('env_save_btn')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('env_save_btn')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Coffee & Tea'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(Key('env_del_$envId')),
      150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.byKey(Key('env_del_$envId')));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(Key('env_del_$envId')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Coffee & Tea'), findsNothing);

    // Milestone 8: Notes save appears #1 & larger comfortable typography
    await openFromMore('ws_tile_6');
    await tester.enterText(find.byKey(const Key('note_title_input')), 'Top Saved Note');
    await tester.enterText(find.byKey(const Key('note_body_input')), 'Readable comfortable note body');
    await tester.ensureVisible(find.byKey(const Key('note_save_btn')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('note_save_btn')));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Top Saved Note'),
      150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Top Saved Note'), findsOneWidget);

    // Milestone 8: Deactivated step Restore & Delete Permanently + Indonesian consistency check
    await tester.runAsync(() async {
      await provider.updateAppPreferences(language: 'id');
      await provider.saveQuickAdd('task', {'name': 'Step For Delete'});
      final tid = provider.todayGroups.expand((g) => g.tasks).firstWhere((t) => t.name == 'Step For Delete').id;
      await provider.deactivateTask(tid);
    });
    await tester.pumpAndSettle();
    await openFromMore('ws_tile_10');
    final targetTaskId = provider.inactiveTasks.firstWhere((t) => t.name == 'Step For Delete').id;
    await tester.scrollUntilVisible(
      find.text('Lifolio v0.3.1'),
      250,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.byKey(Key('delete_perm_task_$targetTaskId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('restore_task_$targetTaskId')), findsOneWidget);
    expect(find.byKey(Key('delete_perm_task_$targetTaskId')), findsOneWidget);
    expect(find.text('Pulihkan'), findsWidgets);
    expect(find.text('Hapus Permanen'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(Key('delete_perm_task_$targetTaskId')));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirm_delete_perm_btn')));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (provider.inactiveTasks.any((t) => t.id == targetTaskId) && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(provider.inactiveTasks.any((t) => t.id == targetTaskId), false);
    expect(find.text('Step For Delete'), findsNothing);

    await tester.binding.setSurfaceSize(null);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      provider.dispose();
      await db.close();
    });
  });
}
