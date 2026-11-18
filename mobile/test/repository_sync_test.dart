import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langkah_kecil/core/database/database_helper.dart';
import 'package:langkah_kecil/data/repositories/checklist_repository.dart';
import 'package:langkah_kecil/data/services/sync_service.dart';
import 'package:langkah_kecil/domain/models/models.dart';

Future<Database> createInMemoryDb() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await DatabaseHelper.createTables(db);
        await DatabaseHelper.seedDefaultData(db);
      },
    ),
  );
  return db;
}

void main() {
  group('ChecklistRepository', () {
    test('seeds default groups, tasks, and rewards', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      final groups = await repo.getGroups();
      expect(groups.length, 3);
      expect(groups.first.id, 'seed-group-pagi');

      final tasks = await repo.getTasks();
      expect(tasks.length, 10);

      final rewards = await repo.getRewards();
      expect(rewards.length, 4);

      await db.close();
    });

    test('toggling check updates points balance and marks dirty', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      const day = '2026-11-17';
      final tasks = await repo.getTasks();

      expect(await repo.getPointsBalance(), 0);

      await repo.toggleCheck(tasks[0].id, day, true);
      expect(await repo.getPointsBalance(), 1);

      final dirty = await repo.getDirtyChanges();
      expect((dirty['checks'] as List).length, 1);

      await repo.toggleCheck(tasks[0].id, day, false);
      expect(await repo.getPointsBalance(), 0);

      await db.close();
    });

    test('soft delete hides task from active list while preserving day log', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      const day = '2026-11-15';
      final tasks = await repo.getTasks();
      final target = tasks.first;

      await repo.toggleCheck(target.id, day, true);
      await repo.deactivateTask(target.id);

      final active = await repo.getTasks(includeInactive: false);
      expect(active.any((t) => t.id == target.id), false);

      final inactive = await repo.getInactiveItems();
      expect(inactive.tasks.any((t) => t.id == target.id), true);

      final log = await repo.getDayLog(day);
      final logTasks = log.groups.expand((g) => g.tasks).toList();
      final hist = logTasks.firstWhere((t) => t.id == target.id);
      expect(hist.done, true);
      expect(hist.isActive, false);

      await repo.reactivateTask(target.id);
      final reactivated = await repo.getTasks(includeInactive: false);
      expect(reactivated.any((t) => t.id == target.id), true);

      await db.close();
    });

    test('dashboard stats computes totals, streaks, and chart bars', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      final tasks = await repo.getTasks();

      await repo.toggleCheck(tasks[0].id, '2026-11-16', true);
      await repo.toggleCheck(tasks[0].id, '2026-11-17', true);
      await repo.toggleCheck(tasks[1].id, '2026-11-17', true);

      final stats = await repo.getDashboardStats('week', '2026-11-17');
      expect(stats.totalDone, 3);
      expect(stats.activeDays, 2);
      expect(stats.currentStreak, 2);
      expect(stats.dailyChart.length, 7);
      expect(stats.dailyChart.last.count, 2);

      await db.close();
    });

    test('LWW merge resolves conflicts by updated_at and device_id', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      await repo.setMeta('device_id', 'aaa-mobile');

      final tasks = await repo.getTasks();
      final target = tasks.first;
      await repo.saveTask(target.copyWith(name: 'Nama Lokal'));
      final localAfter = (await repo.getTasks()).firstWhere((t) => t.id == target.id);

      // Incoming older timestamp should NOT overwrite
      await repo.applyIncomingChanges({
        'tasks': [
          {
            'id': target.id,
            'group_id': target.groupId,
            'name': 'Nama Lama',
            'core': 0,
            'sort': 0,
            'is_active': 1,
            'deactivated_at': null,
            'updated_at': localAfter.updatedAt - 1000,
          }
        ]
      }, 'zzz-desktop');

      var current = (await repo.getTasks()).firstWhere((t) => t.id == target.id);
      expect(current.name, 'Nama Lokal');

      // Incoming newer timestamp SHOULD overwrite
      await repo.applyIncomingChanges({
        'tasks': [
          {
            'id': target.id,
            'group_id': target.groupId,
            'name': 'Nama Baru Desktop',
            'core': 1,
            'sort': 0,
            'is_active': 1,
            'deactivated_at': null,
            'updated_at': localAfter.updatedAt + 5000,
          }
        ]
      }, 'zzz-desktop');

      current = (await repo.getTasks()).firstWhere((t) => t.id == target.id);
      expect(current.name, 'Nama Baru Desktop');
      expect(current.core, true);

      await db.close();
    });
  });

  group('SyncService round-trip', () {
    test('pairs and syncs dirty changes against protocol server', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      final tasks = await repo.getTasks();
      await repo.toggleCheck(tasks.first.id, '2026-11-17', true);

      String? capturedAuth;
      Map<String, dynamic>? capturedSyncBody;

      final mockClient = MockClient((req) async {
        if (req.url.path == '/api/v1/pair') {
          final body = json.decode(req.body) as Map<String, dynamic>;
          if (body['code'] == '654321') {
            return http.Response(json.encode({'token': 'secret-tok'}), 200);
          }
          return http.Response(json.encode({'error': 'bad_code'}), 403);
        }

        if (req.url.path == '/api/v1/sync') {
          capturedAuth = req.headers['Authorization'];
          capturedSyncBody = json.decode(req.body) as Map<String, dynamic>;
          return http.Response(
            json.encode({
              'cursor': 42,
              'server_time': DateTime.now().millisecondsSinceEpoch,
              'changes': {
                'groups': [
                  {
                    'id': 'desktop-group-1',
                    'name': 'Dari Desktop',
                    'sort': 9,
                    'is_active': 1,
                    'deactivated_at': null,
                    'updated_at': DateTime.now().millisecondsSinceEpoch,
                  }
                ],
                'tasks': [],
                'rewards': [],
                'checks': [],
                'claims': [],
              }
            }),
            200,
          );
        }

        return http.Response('not found', 404);
      });

      final sync = SyncService(
        repository: repo,
        httpClient: mockClient,
        customDiscovery: () async => DiscoveredServer(
          host: '192.168.1.10',
          port: 47800,
          deviceId: 'desktop-1',
          deviceName: 'Desktop Test',
        ),
      );

      final paired = await sync.pair('654321');
      expect(paired, true);
      expect(capturedAuth, 'Bearer secret-tok');
      expect(((capturedSyncBody?['changes'] as Map)['checks'] as List).length, 1);

      // Dirty flags cleared & cursor saved
      final dirtyAfter = await repo.getDirtyChanges();
      expect((dirtyAfter['checks'] as List).length, 0);
      expect(await repo.getMeta('last_sync_cursor'), '42');

      // Desktop group imported
      final groups = await repo.getGroups();
      expect(groups.any((g) => g.id == 'desktop-group-1'), true);

      sync.dispose();
      await db.close();
    });

    test('desktop deactivation of seed task overwrites mobile seed task regardless of install order', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      final tasksBefore = await repo.getTasks();
      expect(tasksBefore.first.updatedAt, 1);

      // Simulate desktop deactivation that happened earlier (e.g. timestamp 1000)
      await repo.applyIncomingChanges({
        'tasks': [
          {
            'id': 'seed-task-p1',
            'group_id': 'seed-group-pagi',
            'name': 'Minum segelas air',
            'core': 1,
            'sort': 0,
            'is_active': 0,
            'deactivated_at': 1000,
            'updated_at': 1000,
          }
        ]
      }, 'desktop-1');

      final today = await repo.getTodayData('2026-11-17');
      final activeIds = today.expand((g) => g.tasks).map((t) => t.id).toList();
      expect(activeIds.contains('seed-task-p1'), false);

      await db.close();
    });

    test('expired token triggers SyncStatus.unauthorized and clears stored token', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      await repo.setMeta('paired_token', 'old-tok');
      await repo.setMeta(
        'token_expires_at',
        (DateTime.now().millisecondsSinceEpoch - 60000).toString(),
      );

      final sync = SyncService(
        repository: repo,
        customDiscovery: () async => DiscoveredServer(
          host: '192.168.1.10',
          port: 47800,
          deviceId: 'desktop-1',
          deviceName: 'Desktop Test',
        ),
      );

      final ok = await sync.sync();
      expect(ok, false);
      expect(sync.status, SyncStatus.unauthorized);
      expect(await repo.getMeta('paired_token'), '');

      sync.dispose();
      await db.close();
    });

    test('saves weekly & monthly schedules, filters getTodayData, and computes getMonthScheduleDots', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      // 2026-11-16 = Monday (ISO 1), 2026-11-17 = Tuesday (ISO 2)
      final weeklyTask = await repo.saveTask(TaskItem(
        id: '',
        groupId: 'seed-group-pagi',
        name: 'Olahraga Mingguan',
        freq: 'weekly',
        freqDays: const [1, 3],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final monthlyTask = await repo.saveTask(TaskItem(
        id: '',
        groupId: 'seed-group-pagi',
        name: 'Bayar Tagihan',
        freq: 'monthly',
        freqDays: const [17],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      expect(weeklyTask.freqLabel, 'Senin, Rabu');
      expect(monthlyTask.freqLabel, 'Tanggal 17');

      final monData = await repo.getTodayData('2026-11-16');
      final monTasks = monData.expand((g) => g.tasks).toList();
      expect(monTasks.firstWhere((t) => t.id == weeklyTask.id).scheduled, true);
      expect(monTasks.firstWhere((t) => t.id == monthlyTask.id).scheduled, false);

      final tueData = await repo.getTodayData('2026-11-17');
      final tueTasks = tueData.expand((g) => g.tasks).toList();
      expect(tueTasks.firstWhere((t) => t.id == weeklyTask.id).scheduled, false);
      expect(tueTasks.firstWhere((t) => t.id == monthlyTask.id).scheduled, true);

      final dots = await repo.getMonthScheduleDots(2026, 11);
      expect(dots['2026-11-16']?.hasWeekly, true);
      expect(dots['2026-11-16']?.hasMonthly, false);
      expect(dots['2026-11-17']?.hasWeekly, false);
      expect(dots['2026-11-17']?.hasMonthly, true);

      await db.close();
    });

    test('computes scheduled denominator in getDashboardStats and syncs freq fields', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      // Create weekly task for Mondays (ISO 1)
      final weeklyTask = await repo.saveTask(TaskItem(
        id: 'weekly-mon',
        groupId: 'seed-group-pagi',
        name: 'Evaluasi Senin',
        freq: 'weekly',
        freqDays: const [1],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      // 2026-11-16 is Monday within week ending 2026-11-22 (1 Monday in 7 days)
      await repo.toggleCheck(weeklyTask.id, '2026-11-16', true);

      final stats = await repo.getDashboardStats('week', '2026-11-22');
      final wt = stats.taskStats.firstWhere((t) => t.id == weeklyTask.id);
      expect(wt.totalDays, 1);
      expect(wt.done, 1);
      expect(wt.rate, 100);
      expect(wt.freq, 'weekly');

      // Check dirty changes include freq and freq_days
      final dirty = await repo.getDirtyChanges();
      final dirtyWeekly = (dirty['tasks'] as List).cast<Map<String, dynamic>>()
          .firstWhere((t) => t['id'] == 'weekly-mon');
      expect(dirtyWeekly['freq'], 'weekly');
      expect(dirtyWeekly['freq_days'], '[1]');

      // Incoming sync update changes monthly schedule
      await repo.applyIncomingChanges({
        'tasks': [
          {
            'id': 'sync-monthly',
            'group_id': 'seed-group-pagi',
            'name': 'Backup Bulanan',
            'core': 0,
            'sort': 5,
            'freq': 'monthly',
            'freq_days': '[1,15]',
            'is_active': 1,
            'updated_at': 500000,
          }
        ]
      }, 'desktop-1');

      final syncedTasks = await repo.getTasks();
      final syncedMonthly = syncedTasks.firstWhere((t) => t.id == 'sync-monthly');
      expect(syncedMonthly.freq, 'monthly');
      expect(syncedMonthly.freqDays, [1, 15]);
      expect(syncedMonthly.isScheduledOnDate(DateTime(2026, 11, 15)), true);
      expect(syncedMonthly.isScheduledOnDate(DateTime(2026, 11, 16)), false);

      await db.close();
    });

    test('moveGroup reorders active groups up and down and marks moved groups dirty', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      final before = await repo.getGroups();
      expect(before.length, 3);
      final firstId = before[0].id;
      final secondId = before[1].id;

      await repo.moveGroup(secondId, -1);
      final afterUp = await repo.getGroups();
      expect(afterUp[0].id, secondId);
      expect(afterUp[1].id, firstId);
      expect(afterUp[0].sort, 0);
      expect(afterUp[1].sort, 1);

      final dirty = await repo.getDirtyChanges();
      final dirtyGroupIds = (dirty['groups'] as List).cast<Map<String, dynamic>>()
          .map((g) => g['id'])
          .toList();
      expect(dirtyGroupIds.contains(firstId), true);
      expect(dirtyGroupIds.contains(secondId), true);

      // Moving down restores order
      await repo.moveGroup(secondId, 1);
      final restored = await repo.getGroups();
      expect(restored[0].id, firstId);
      expect(restored[1].id, secondId);

      await db.close();
    });

    test('Personal Life OS persists layout, computes module reports from actual data, and redacts audit logs', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      const today = '2026-11-18';

      // Default layout has all 7 modules
      final def = await repo.getDashboardLayout();
      expect(def.length, 7);

      // Custom layout persists and resets
      await repo.saveDashboardLayout([
        const DashboardWidgetConfig(id: 'w-fin', visible: true, size: 'l'),
        const DashboardWidgetConfig(id: 'w-prod', visible: false, size: 's'),
      ]);
      final savedLayout = await repo.getDashboardLayout();
      expect(savedLayout.length, 2);
      expect(savedLayout[0].id, 'w-fin');
      expect(savedLayout[1].visible, false);

      await repo.resetDashboardLayout();
      expect((await repo.getDashboardLayout()).length, 7);

      // Empty report returns zeros without fake data
      final emptyFin = await repo.getModuleReport(
        module: 'finance',
        range: 'week',
        todayStr: today,
      );
      expect(emptyFin.metrics['income'], 0);
      expect(emptyFin.entries.isEmpty, true);

      // Quick Add entries populate reports & dirty sync changes
      await repo.quickAdd('envelope', {'id': 'env-1', 'name': 'Makan', 'monthly_budget': 500000});
      await repo.quickAdd('finance', {'day': today, 'type': 'income', 'category': 'general', 'amount': 1200000});
      await repo.quickAdd('finance', {'day': today, 'type': 'expense', 'category': 'general', 'amount': 150000, 'envelope_id': 'env-1'});
      await repo.quickAdd('finance', {'day': today, 'type': 'expense', 'category': 'savings', 'amount': 300000});
      await repo.quickAdd('weight', {'day': today, 'value_num': 61.5});
      await repo.quickAdd('water', {'day': today, 'value_num': 600});
      await repo.quickAdd('mood', {'day': today, 'mood': 'Tenang', 'mood_score': 4, 'triggers_text': 'jalan pagi'});
      await repo.quickAdd('menstrual', {'day': today, 'phase': 'Menstruasi', 'cycle_day': 1, 'symptoms': ['Kram'], 'is_period_start': true, 'cycle_length': 28});
      await repo.quickAdd('note', {'day': today, 'title': 'Catatan Harian', 'body': 'Tiga kata saja', 'tags': ['jurnal']});
      await repo.quickAdd('project', {'id': 'proj-1', 'name': 'Life OS', 'progress': 70});
      await repo.quickAdd('focus', {'day': today, 'project_id': 'proj-1', 'minutes': 40});

      final finRep = await repo.getModuleReport(module: 'finance', range: 'week', todayStr: today);
      expect(finRep.metrics['income'], 1200000);
      expect(finRep.metrics['expense'], 450000);
      expect(finRep.metrics['savings'], 300000);
      expect(finRep.breakdown.first['used'], 150000);

      final healthRep = await repo.getModuleReport(module: 'health', range: 'week', todayStr: today);
      expect(healthRep.metrics['latestWeight'], 61.5);
      expect(healthRep.metrics['totalWaterMl'], 600);

      final wellRep = await repo.getModuleReport(module: 'wellness', range: 'week', todayStr: today);
      expect(wellRep.metrics['avgMood'], 4.0);
      expect(wellRep.tagsOrTriggers.first.name, 'jalan pagi');

      final mensRep = await repo.getModuleReport(module: 'menstrual', range: 'week', todayStr: today);
      expect(mensRep.metrics['avgCycleDuration'], 28);
      expect(mensRep.tagsOrTriggers.first.name, 'Kram');

      final noteRep = await repo.getModuleReport(module: 'notes', range: 'week', todayStr: today);
      expect(noteRep.metrics['count'], 1);
      expect(noteRep.metrics['totalWords'], 3);
      expect(noteRep.tagsOrTriggers.first.name, 'jurnal');

      final prodRep = await repo.getModuleReport(module: 'productivity', range: 'week', todayStr: today);
      expect(prodRep.metrics['focusMinutes'], 40);
      expect(prodRep.metrics['projectsCount'], 1);

      // Sync dirty export includes Life OS tables and never audit_logs
      final dirty = await repo.getDirtyChanges();
      expect((dirty['finance_entries'] as List).length, 3);
      expect((dirty['notes'] as List).length, 1);
      expect(dirty.containsKey('audit_logs'), false);

      // Audit Log redacts bearer secrets and logs cleanly
      await repo.logAudit(
        endpoint: 'POST /api/v1/sync',
        statusCode: 401,
        errorCode: 'unauthorized',
        message: 'Failed auth with Bearer mysecrettoken999',
        details: {'token': 'secret-val', 'host': '192.168.1.9'},
      );
      final logs = await repo.getAuditLogs(todayStr: today);
      expect(logs.length, 1);
      expect(logs.first.message.contains('mysecrettoken999'), false);
      expect(logs.first.details?['token'], '[REDACTED]');
      expect(logs.first.details?['host'], '192.168.1.9');

      await db.close();
    });
  });
}
