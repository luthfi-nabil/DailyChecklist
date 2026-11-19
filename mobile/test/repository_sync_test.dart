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
      final logs = await repo.getAuditLogs();
      expect(logs.length, 1);
      expect(logs.first.message.contains('mysecrettoken999'), false);
      expect(logs.first.details?['token'], '[REDACTED]');
      expect(logs.first.details?['host'], '192.168.1.9');

      await db.close();
    });

    test('Milestone 5 & 6: preferences, M6 workspaces, menstrual estimate, JSON export/restore & local IP lookup', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      const today = '2026-11-18';

      // Default White & Pink palette + User
      final defPrefs = await repo.getAppPreferences();
      expect(defPrefs.colorPalette, 'pink');
      expect(defPrefs.userName, 'User');
      expect(defPrefs.language, 'en');
      expect(defPrefs.showReportCharts, true);

      // Editable Your spaces custom labels persist in dashboard layout
      final savedSpaces = await repo.saveDashboardLayout([
        const DashboardWidgetConfig(id: 'w-fin', visible: true, label: 'My Money'),
        const DashboardWidgetConfig(id: 'w-hlth', visible: false, label: 'Wellness'),
      ]);
      expect(savedSpaces[0].label, 'My Money');
      final loadedSpaces = await repo.getDashboardLayout();
      expect(loadedSpaces[0].label, 'My Money');
      expect(loadedSpaces[1].visible, false);

      final savedPrefs = await repo.saveAppPreferences(
        colorPalette: 'teal',
        userName: 'Luthfi',
        language: 'id',
        showReportCharts: false,
      );
      expect(savedPrefs.colorPalette, 'teal');
      expect(savedPrefs.userName, 'Luthfi');
      expect(savedPrefs.language, 'id');
      expect(savedPrefs.showReportCharts, false);

      // Tasks priority & due_date + M6 workspaces
      final t = await repo.saveTask(TaskItem(
        id: 'm6-task-1',
        groupId: 'seed-group-pagi',
        name: 'Priority task',
        priority: 'high',
        dueDate: '2026-11-20',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      expect(t.priority, 'high');
      expect(t.dueDate, '2026-11-20');

      await repo.quickAdd('savings_goal', {'name': 'Vacation', 'target_amount': 5000000, 'current_amount': 1200000});
      await repo.quickAdd('recurring_bill', {'name': 'Electric', 'kind': 'bill', 'amount': 250000, 'due_day': 15});
      await repo.quickAdd('food', {'day': today, 'meal_slot': 'lunch', 'name': 'Bento', 'value_num': 550});
      await repo.quickAdd('measurement', {'day': today, 'name': 'Waist', 'value_num': 72, 'unit': 'cm'});
      await repo.quickAdd('mood', {'day': today, 'mood': 'Happy', 'mood_score': 5, 'gratitude_text': 'Coffee'});
      await repo.quickAdd('menstrual', {'day': today, 'phase': 'Menstrual', 'cycle_day': 1, 'is_period_start': 1, 'cycle_length': 28});
      await repo.quickAdd('note', {'day': today, 'title': 'Idea', 'body': 'Build calm tools', 'category': 'braindump', 'is_pinned': true});

      final finRep = await repo.getModuleReport(module: 'finance', range: 'week', todayStr: today);
      expect((finRep.metrics['savingsGoals'] as List).length, 1);
      expect((finRep.metrics['recurringBills'] as List).length, 1);

      final mensRep = await repo.getModuleReport(module: 'menstrual', range: 'week', todayStr: today);
      final est = mensRep.metrics['nextPeriodEstimate'] as Map<String, dynamic>?;
      expect(est?['isEstimate'], true);
      expect(est?['estimatedStartDay'], '2026-12-16');

      // JSON export + restore
      final backup = await repo.exportAllDataJson();
      final db2 = await createInMemoryDb();
      final repo2 = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db2));
      await repo2.importAllDataJson(backup);
      expect((await repo2.getAppPreferences()).userName, 'Luthfi');
      expect((await repo2.getSavingsGoals()).length, 1);
      await db2.close();

      // Local IP enumeration executes cleanly without throwing
      final sync = SyncService(repository: repo);
      final ips = await sync.getLocalIpAddresses();
      expect(ips, isA<List<({String iface, String address})>>());
      sync.dispose();

      await db.close();
    });

    test('Milestone 7: Manual IP address & port configuration pairs and syncs without auto-discovery', () async {
      expect(SyncService.normalizeHost('http://192.168.1.50:47850/'), '192.168.1.50');
      expect(SyncService.parsePort('47850'), 47850);
      expect(SyncService.parsePort('99999'), isNull);
      expect(SyncService.parsePort('abc'), isNull);

      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));

      var reachable = true;
      final requestedEndpoints = <String>[];
      final mockClient = MockClient((req) async {
        requestedEndpoints.add('${req.url.host}:${req.url.port}${req.url.path}');
        if (!reachable) return http.Response('unreachable', 503);
        if (req.url.path == '/api/v1/ping') {
          return http.Response(
            json.encode({'app': 'langkah-kecil', 'device_id': 'desk-m7', 'device_name': 'Desktop M7'}),
            200,
          );
        }
        if (req.url.path == '/api/v1/pair') {
          return http.Response(json.encode({'token': 'm7-token'}), 200);
        }
        if (req.url.path == '/api/v1/sync') {
          return http.Response(
            json.encode({
              'cursor': 10,
              'server_time': DateTime.now().millisecondsSinceEpoch,
              'changes': {'groups': [], 'tasks': [], 'rewards': [], 'checks': [], 'claims': []},
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      final sync = SyncService(repository: repo, httpClient: mockClient);
      await sync.init();

      await expectLater(
        sync.setManualEndpoint(enabled: true, host: '', port: 47800),
        throwsArgumentError,
      );
      await expectLater(
        sync.setManualEndpoint(enabled: true, host: '192.168.50.10', port: 70000),
        throwsArgumentError,
      );

      await sync.setManualEndpoint(enabled: true, host: 'http://192.168.50.10/', port: 47855);
      expect(sync.useManualEndpoint, true);
      expect(sync.manualHost, '192.168.50.10');
      expect(sync.manualPort, 47855);
      expect(await repo.getMeta(SyncService.metaManualEnabled), 'true');
      expect(await repo.getMeta(SyncService.metaManualHost), '192.168.50.10');
      expect(await repo.getMeta(SyncService.metaManualPort), '47855');

      final verified = await sync.connectManual();
      expect(verified, isNotNull);
      expect(verified!.host, '192.168.50.10');
      expect(verified.port, 47855);
      expect(requestedEndpoints.contains('192.168.50.10:47855/api/v1/ping'), true);

      final paired = await sync.pair('654321');
      expect(paired, true);
      expect(sync.status, SyncStatus.connected);
      expect(requestedEndpoints.contains('192.168.50.10:47855/api/v1/pair'), true);
      expect(requestedEndpoints.contains('192.168.50.10:47855/api/v1/sync'), true);

      // Unreachable manual endpoint reports error cleanly & logs discovery audit entry
      reachable = false;
      sync.currentServer = null;
      final unreachable = await sync.connectManual(host: '192.168.50.10', port: 47855);
      expect(unreachable, isNull);
      expect(sync.status, SyncStatus.notFound);
      final logs = await repo.getAuditLogs(category: 'discovery');
      expect(logs.any((l) => l.errorCode == 'MANUAL_UNREACHABLE'), true);

      sync.dispose();
      await db.close();
    });

    test('Milestone 8: pinned motivational reminder, envelope edit/delete, notes newest-first & task permanent deletion tombstone', () async {
      final db = await createInMemoryDb();
      final repo = ChecklistRepository(dbHelper: DatabaseHelper(customDb: db));
      const today = '2026-11-19';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Pinned motivational reminder + newest note always #1
      await repo.quickAdd('note', {
        'id': 'little-note-motivation',
        'day': '2026-11-10',
        'title': 'Motivational Reminder ♡',
        'body': 'Calm & steady progress',
        'category': 'gratitude',
        'is_pinned': true,
      });
      await repo.quickAdd('note', {
        'id': 'm8-top-note',
        'day': today,
        'title': 'Brand New Note',
        'body': 'Saved just now',
        'category': 'journal',
        'is_pinned': false,
      });
      await db.update('notes', {'updated_at': nowMs - 60000}, where: 'id = ?', whereArgs: ['little-note-motivation']);
      await db.update('notes', {'updated_at': nowMs + 60000}, where: 'id = ?', whereArgs: ['m8-top-note']);

      final sum = await repo.getLifeOsSummary(today);
      expect(sum.pinnedNoteId, 'little-note-motivation');
      expect(sum.pinnedNoteBody, 'Calm & steady progress');
      expect(sum.latestNoteTitle, 'Brand New Note');
      final rep = await repo.getModuleReport(module: 'notes', range: 'month', todayStr: today);
      expect(rep.entries.first['id'], 'm8-top-note');

      // 2. Envelope edit & delete
      await repo.quickAdd('envelope', {'id': 'm8-env', 'name': 'Transport', 'monthly_budget': 200000});
      await repo.quickAdd('envelope', {'id': 'm8-env', 'name': 'Commute', 'monthly_budget': 350000});
      final envsAfterEdit = await repo.getEnvelopes();
      expect(envsAfterEdit.where((e) => e['id'] == 'm8-env').length, 1);
      expect(envsAfterEdit.firstWhere((e) => e['id'] == 'm8-env')['name'], 'Commute');
      expect(envsAfterEdit.firstWhere((e) => e['id'] == 'm8-env')['monthly_budget'], 350000);
      await repo.softDeleteItem('finance_envelopes', 'm8-env');
      expect((await repo.getEnvelopes()).any((e) => e['id'] == 'm8-env'), false);

      // 3. Deactivate -> Delete Permanently + deleted_tasks sync tombstone
      await repo.saveGroup(GroupItem(id: 'm8-g', name: 'M8 Group', updatedAt: nowMs));
      const tid = 'm8-t-del';
      await repo.saveTask(TaskItem(id: tid, groupId: 'm8-g', name: 'Permanent Del Step', updatedAt: nowMs));
      await repo.toggleCheck(tid, today, true);
      await repo.deactivateTask(tid);
      expect((await repo.getInactiveItems()).tasks.any((t) => t.id == tid), true);

      await repo.deleteTaskPermanently(tid);
      expect((await repo.getInactiveItems()).tasks.any((t) => t.id == tid), false);
      expect((await db.query('checks', where: 'task_id = ?', whereArgs: [tid])).isEmpty, true);

      final dirty = await repo.getDirtyChanges();
      final deletedList = List<Map<String, dynamic>>.from(dirty['deleted_tasks'] as List);
      expect(deletedList.any((d) => d['id'] == tid), true);

      // Tombstone blocks older peer snapshot from resurrecting permanently deleted step
      await repo.applyIncomingChanges({
        'groups': [
          {'id': 'm8-g', 'name': 'M8 Group', 'sort_order': 0, 'is_active': 1, 'updated_at': nowMs}
        ],
        'tasks': [
          {
            'id': tid,
            'group_id': 'm8-g',
            'name': 'Resurrected',
            'is_core': 0,
            'sort_order': 0,
            'is_active': 0,
            'updated_at': nowMs - 50000,
          }
        ],
      }, 'peer-desk');
      expect((await db.query('tasks', where: 'id = ?', whereArgs: [tid])).isEmpty, true);

      // Receiving deleted_tasks removes an existing local task & its checks
      const peerTid = 'm8-t-peer';
      await repo.saveTask(TaskItem(id: peerTid, groupId: 'm8-g', name: 'Peer Deleted Step', updatedAt: nowMs));
      await repo.toggleCheck(peerTid, today, true);
      await repo.applyIncomingChanges({
        'deleted_tasks': [
          {'id': peerTid, 'deleted_at': nowMs + 5000}
        ],
      }, 'peer-desk');
      expect((await db.query('tasks', where: 'id = ?', whereArgs: [peerTid])).isEmpty, true);
      expect((await db.query('checks', where: 'task_id = ?', whereArgs: [peerTid])).isEmpty, true);

      await db.close();
    });
  });
}
