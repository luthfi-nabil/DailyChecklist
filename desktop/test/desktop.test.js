const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { Database } = require('../src/main/data/db');
const { Repository } = require('../src/main/data/repository');
const { SyncServer } = require('../src/main/services/syncServer');

test('Database and Repository operations', async (t) => {
  const db = new Database(':memory:');
  const repo = new Repository(db);

  await t.test('seeds initial groups and tasks with deterministic IDs', () => {
    const groups = repo.getGroups();
    assert.strictEqual(groups.length, 3);
    assert.strictEqual(groups[0].id, 'seed-group-pagi');
    assert.strictEqual(groups[0].name, 'Pagi');

    const tasks = repo.getTasks();
    assert.strictEqual(tasks.length, 10);
  });

  await t.test('toggle check updates points balance', () => {
    const day = '2026-11-17';
    const tasks = repo.getTasks();
    const t1 = tasks[0];

    assert.strictEqual(repo.getPointsBalance(), 0);

    repo.toggleCheck(t1.id, day, true);
    assert.strictEqual(repo.getPointsBalance(), 1);

    const checks = repo.getChecksForDay(day);
    assert.ok(checks[t1.id]);
    assert.strictEqual(checks[t1.id].checked, 1);

    repo.toggleCheck(t1.id, day, false);
    assert.strictEqual(repo.getPointsBalance(), 0);
  });

  await t.test('soft delete hides item without deleting row and preserves day log', () => {
    const day = '2026-11-15';
    const tasks = repo.getTasks();
    const t1 = tasks[0];

    repo.toggleCheck(t1.id, day, true);
    repo.deactivateTask(t1.id);

    const activeTasks = repo.getTasks(false);
    assert.ok(!activeTasks.find(t => t.id === t1.id));

    const allTasks = repo.getTasks(true);
    const deactivated = allTasks.find(t => t.id === t1.id);
    assert.ok(deactivated);
    assert.strictEqual(deactivated.is_active, 0);
    assert.ok(deactivated.deactivated_at > 0);

    // Day log still contains the historical check with isActive: false
    const log = repo.getDayLog(day);
    const logTasks = log.groups.flatMap(g => g.tasks);
    const histTask = logTasks.find(t => t.id === t1.id);
    assert.ok(histTask);
    assert.strictEqual(histTask.done, true);
    assert.strictEqual(histTask.isActive, false);

    repo.reactivateTask(t1.id);
    const reactivated = repo.getTasks(false).find(t => t.id === t1.id);
    assert.ok(reactivated);
    assert.strictEqual(reactivated.is_active, 1);
  });

  await t.test('claiming rewards deducts points and undoClaim restores if unsynced', () => {
    const day = '2026-11-17';
    const tasks = repo.getTasks();

    for (let i = 0; i < 6; i++) {
      repo.toggleCheck(tasks[i].id, day, true);
    }
    const balBefore = repo.getPointsBalance();
    const rewards = repo.getRewards();
    const r5 = rewards.find(r => r.cost === 5);

    const claim = repo.claimReward(r5.id, day);
    assert.ok(claim.id);
    assert.strictEqual(repo.getPointsBalance(), balBefore - r5.cost);

    const undone = repo.undoClaim(claim.id);
    assert.strictEqual(undone, true);
    assert.strictEqual(repo.getPointsBalance(), balBefore);
  });

  await t.test('dashboard statistics calculates rate, streaks, and daily chart', () => {
    const tasks = repo.getTasks();
    repo.toggleCheck(tasks[0].id, '2026-11-16', true);
    repo.toggleCheck(tasks[0].id, '2026-11-17', true);

    const stats = repo.getDashboardStats('week', '2026-11-17');
    assert.strictEqual(stats.period, 'week');
    assert.ok(stats.totalDone >= 2);
    assert.ok(stats.currentStreak >= 2);
    assert.strictEqual(stats.dailyChart.length, 7);
    assert.strictEqual(stats.dailyChart[6].dow, 'Hari ini');
  });

  db.close();
});

test('Sync Server API and LWW Merge', async (t) => {
  const db = new Database(':memory:');
  const repo = new Repository(db);
  const server = new SyncServer(db, repo);
  const port = await server.start(0);

  function request(method, path, headers = {}, body = null) {
    return new Promise((resolve, reject) => {
      const req = http.request({
        hostname: '127.0.0.1',
        port,
        path,
        method,
        headers
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, json: data ? JSON.parse(data) : {} });
          } catch (e) {
            resolve({ status: res.statusCode, data });
          }
        });
      });
      req.on('error', reject);
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  }

  await t.test('GET /api/v1/ping returns server info', async () => {
    const res = await request('GET', '/api/v1/ping');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.json.app, 'langkah-kecil');
    assert.strictEqual(res.json.v, 1);
  });

  let token = '';
  await t.test('POST /api/v1/pair rejects wrong code and pairs with valid code', async () => {
    const bad = await request('POST', '/api/v1/pair', { 'Content-Type': 'application/json' }, {
      code: '000000',
      device_id: 'phone-test-1'
    });
    assert.strictEqual(bad.status, 403);

    const code = db.getMeta('pairing_code');
    const res = await request('POST', '/api/v1/pair', { 'Content-Type': 'application/json' }, {
      code,
      device_id: 'phone-test-1',
      device_name: 'Ponsel Luthfi'
    });
    assert.strictEqual(res.status, 200);
    assert.ok(res.json.token);
    assert.ok(res.json.expires_at > Date.now() + 2 * 24 * 60 * 60 * 1000);
    assert.ok(res.json.expires_at <= Date.now() + 8 * 24 * 60 * 60 * 1000);
    token = res.json.token;
  });

  await t.test('POST /api/v1/sync merges changes with LWW and excludes just-accepted rows', async () => {
    const now = Date.now();
    const phoneGroupId = 'group-from-phone';
    const phoneChanges = {
      groups: [
        {
          id: phoneGroupId,
          name: 'Kelompok Ponsel',
          sort: 10,
          is_active: 1,
          deactivated_at: null,
          updated_at: now
        }
      ]
    };

    const res = await request('POST', '/api/v1/sync', {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }, {
      since: 0,
      device_id: 'phone-test-1',
      changes: phoneChanges
    });

    assert.strictEqual(res.status, 200);
    assert.ok(res.json.cursor > 0);
    assert.ok(res.json.changes.groups.length >= 3);
    // Excluded the group the phone just pushed
    assert.ok(!res.json.changes.groups.find(g => g.id === phoneGroupId));

    const groups = repo.getGroups();
    const found = groups.find(g => g.id === phoneGroupId);
    assert.ok(found);
    assert.strictEqual(found.name, 'Kelompok Ponsel');
  });

  await t.test('POST /api/v1/sync handles since > server_seq and sends deactivated seed tasks', async () => {
    repo.deactivateTask('seed-task-p1');
    const res = await request('POST', '/api/v1/sync', {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }, {
      since: 99999,
      device_id: 'phone-test-1',
      changes: {}
    });

    assert.strictEqual(res.status, 200);
    const p1 = res.json.changes.tasks.find(x => x.id === 'seed-task-p1');
    assert.ok(p1);
    assert.strictEqual(p1.is_active, 0);
    assert.ok(p1.updated_at > 1);
  });

  await t.test('POST /api/v1/sync rejects expired token with 401 token_expired', async () => {
    const paired = JSON.parse(db.getMeta('paired_devices'));
    paired[0].expires_at = Date.now() - 1000;
    db.setMeta('paired_devices', JSON.stringify(paired));

    const res = await request('POST', '/api/v1/sync', {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }, {
      since: 0,
      device_id: 'phone-test-1',
      changes: {}
    });

    assert.strictEqual(res.status, 401);
    assert.strictEqual(res.json.error, 'token_expired');
  });

  await server.stop();
  db.close();
});

test('Milestone 3: Weekly & Monthly task scheduling, stats, and sync', async (t) => {
  const db = new Database(':memory:');
  const repo = new Repository(db);

  await t.test('saves weekly & monthly schedules and filters getTodayData + getMonthScheduleDots', () => {
    // 2026-11-17 is Tuesday (ISO dow = 2, dom = 17)
    // 2026-11-21 is Saturday (ISO dow = 6, dom = 21)
    const weeklyTask = repo.saveTask({
      group_id: 'seed-group-pagi',
      name: 'Olahraga Selasa & Sabtu',
      freq: 'weekly',
      freq_days: [2, 6]
    });
    const monthlyTask = repo.saveTask({
      group_id: 'seed-group-siang',
      name: 'Cek tagihan tanggal 17',
      freq: 'monthly',
      freq_days: [17]
    });

    const tuesday = repo.getTodayData('2026-11-17');
    const tueTasks = tuesday.groups.flatMap(g => g.tasks);
    assert.strictEqual(tueTasks.find(x => x.id === weeklyTask.id).scheduled, true);
    assert.strictEqual(tueTasks.find(x => x.id === monthlyTask.id).scheduled, true);

    const wednesday = repo.getTodayData('2026-11-18');
    const wedTasks = wednesday.groups.flatMap(g => g.tasks);
    assert.strictEqual(wedTasks.find(x => x.id === weeklyTask.id).scheduled, false);
    assert.strictEqual(wedTasks.find(x => x.id === monthlyTask.id).scheduled, false);

    const dots = repo.getMonthScheduleDots(2026, 11);
    assert.strictEqual(dots['2026-11-17'].hasWeekly, true);
    assert.strictEqual(dots['2026-11-17'].hasMonthly, true);
    assert.strictEqual(dots['2026-11-21'].hasWeekly, true);
    assert.strictEqual(dots['2026-11-21'].hasMonthly, false);
    assert.strictEqual(dots['2026-11-18'], undefined);

    // Dashboard calculates scheduled denominator (1/1 = 100% for monthly task in week ending 2026-11-17)
    repo.toggleCheck(monthlyTask.id, '2026-11-17', true);
    const stats = repo.getDashboardStats('week', '2026-11-17');
    const mStat = stats.taskStats.find(x => x.id === monthlyTask.id);
    assert.strictEqual(mStat.done, 1);
    assert.strictEqual(mStat.totalDays, 1);
    assert.strictEqual(mStat.rate, 100);
  });

  await t.test('syncs freq and freq_days via applyChanges and getChangesSince', () => {
    repo.applyChanges({
      tasks: [
        {
          id: 'phone-sched-1',
          group_id: 'seed-group-malam',
          name: 'Ganti seprai',
          core: 0,
          sort: 5,
          freq: 'monthly',
          freq_days: '[1,15]',
          is_active: 1,
          deactivated_at: null,
          updated_at: Date.now()
        }
      ]
    }, 'phone-1');

    const exported = repo.getChangesSince(0);
    const found = exported.tasks.find(x => x.id === 'phone-sched-1');
    assert.ok(found);
    assert.strictEqual(found.freq, 'monthly');
    assert.strictEqual(found.freq_days, '[1,15]');
  });

  await t.test('moveGroup reorders active groups up/down and persists sort values', () => {
    const before = repo.getGroups().map(g => g.id);
    assert.strictEqual(before.length >= 3, true);
    const secondId = before[1];
    const firstId = before[0];

    const movedUp = repo.moveGroup(secondId, -1);
    assert.strictEqual(movedUp, true);

    const afterUp = repo.getGroups().map(g => g.id);
    assert.strictEqual(afterUp[0], secondId);
    assert.strictEqual(afterUp[1], firstId);

    // Moving first item further up is a no-op returning false
    assert.strictEqual(repo.moveGroup(secondId, -1), false);

    // Move back down restores order
    assert.strictEqual(repo.moveGroup(secondId, 1), true);
    const restored = repo.getGroups().map(g => g.id);
    assert.strictEqual(restored[0], firstId);
    assert.strictEqual(restored[1], secondId);
  });

  db.close();
});

test('Milestone 4: Personal Life OS dashboard layout, quickAdd, module reports, sync & audit log', async (t) => {
  const db = new Database(':memory:');
  const repo = new Repository(db);
  const server = new SyncServer(db, repo);
  const port = await server.start(0);

  await t.test('persists customizable dashboard layout and resets to default', () => {
    const def = repo.getDashboardLayout();
    assert.strictEqual(def.length, 7);

    const custom = [{ id: 'w-fin', visible: true, size: 'l' }, { id: 'w-prod', visible: false, size: 's' }];
    repo.saveDashboardLayout(custom);
    const saved = repo.getDashboardLayout();
    assert.strictEqual(saved.length, 2);
    assert.strictEqual(saved[0].id, 'w-fin');
    assert.strictEqual(saved[0].size, 'l');
    assert.strictEqual(saved[1].visible, false);

    const reset = repo.resetDashboardLayout();
    assert.strictEqual(reset.length, 7);
    assert.strictEqual(repo.getDashboardLayout().length, 7);
  });

  await t.test('reports compute strictly from actual stored records (no fake defaults)', () => {
    const today = '2026-11-18';
    const emptyFin = repo.getModuleReport({ module: 'finance', range: 'week', today });
    assert.strictEqual(emptyFin.income, 0);
    assert.strictEqual(emptyFin.expense, 0);
    assert.strictEqual(emptyFin.entries.length, 0);

    const env = repo.quickAdd({ kind: 'envelope', data: { name: 'Makan', monthly_budget: 500000 } });
    repo.quickAdd({ kind: 'finance', data: { day: today, type: 'income', category: 'general', amount: 1000000, note: 'Gaji' } });
    repo.quickAdd({ kind: 'finance', data: { day: today, type: 'expense', category: 'general', amount: 100000, envelope_id: env.id, note: 'Makan siang' } });
    repo.quickAdd({ kind: 'finance', data: { day: today, type: 'expense', category: 'savings', amount: 200000, note: 'Tabungan' } });
    repo.quickAdd({ kind: 'finance', data: { day: today, type: 'expense', category: 'debt', amount: 150000, note: 'Cicilan' } });

    const finRep = repo.getModuleReport({ module: 'finance', range: 'week', today });
    assert.strictEqual(finRep.income, 1000000);
    assert.strictEqual(finRep.expense, 450000);
    assert.strictEqual(finRep.savings, 200000);
    assert.strictEqual(finRep.debt, 150000);
    assert.strictEqual(finRep.envelopeUsage[0].used, 100000);
    assert.strictEqual(finRep.envelopeUsage[0].pct, 20);

    // Health, Wellness, Menstrual, Notes, Project & Focus
    repo.quickAdd({ kind: 'food', data: { day: today, name: 'Salad', value_num: 350 } });
    repo.quickAdd({ kind: 'weight', data: { day: today, value_num: 62.5, value_num2: 75 } });
    repo.quickAdd({ kind: 'water', data: { day: today, value_num: 500 } });
    repo.quickAdd({ kind: 'workout', data: { day: today, name: 'Jogging', value_num: 30 } });
    repo.quickAdd({ kind: 'mood', data: { day: today, mood: 'Tenang', mood_score: 4, energy: 4, stress: 2, sleep_hours: 7.5, triggers_text: 'tidur cukup' } });
    repo.quickAdd({ kind: 'menstrual', data: { day: today, phase: 'Menstruasi', cycle_day: 1, symptoms: ['Kram'], is_period_start: true, cycle_length: 28 } });
    repo.quickAdd({ kind: 'note', data: { day: today, title: 'Refleksi', body: 'Hari ini cukup tenang', tags: ['refleksi'] } });
    const proj = repo.quickAdd({ kind: 'project', data: { name: 'Life OS', progress: 60 } });
    repo.quickAdd({ kind: 'focus', data: { day: today, project_id: proj.id, minutes: 45 } });

    const healthRep = repo.getModuleReport({ module: 'health', range: 'week', today });
    assert.strictEqual(healthRep.latestWeight, 62.5);
    assert.strictEqual(healthRep.totalCalories, 350);
    assert.strictEqual(healthRep.totalWaterMl, 500);
    assert.strictEqual(healthRep.totalWorkoutMin, 30);

    const wellRep = repo.getModuleReport({ module: 'wellness', range: 'week', today });
    assert.strictEqual(wellRep.avgMood, 4);
    assert.strictEqual(wellRep.triggers[0].name, 'tidur cukup');

    const mensRep = repo.getModuleReport({ module: 'menstrual', range: 'week', today });
    assert.strictEqual(mensRep.avgCycleDuration, 28);
    assert.strictEqual(mensRep.symptomSummary[0].name, 'Kram');

    const noteRep = repo.getModuleReport({ module: 'notes', range: 'week', today });
    assert.strictEqual(noteRep.count, 1);
    assert.strictEqual(noteRep.tags[0].name, 'refleksi');

    const prodRep = repo.getModuleReport({ module: 'productivity', range: 'week', today });
    assert.strictEqual(prodRep.focusMinutes, 45);
    assert.strictEqual(prodRep.projects[0].progress, 60);
  });

  await t.test('syncs Life OS tables via applyChanges/getChangesSince and excludes audit_logs', () => {
    repo.applyChanges({
      notes: [{
        id: 'mob-note-1',
        day: '2026-11-18',
        title: 'Catatan Ponsel',
        body: 'Disinkronkan',
        tags_json: '["mobile"]',
        is_active: 1,
        updated_at: Date.now()
      }]
    }, 'mobile-1');

    const exported = repo.getChangesSince(0);
    assert.ok(exported.notes.find(n => n.id === 'mob-note-1'));
    assert.strictEqual(exported.audit_logs, undefined);
  });

  await t.test('audit_logs redacts secrets and logs API/sync failures from SyncServer', async () => {
    repo.logAudit({
      source: 'Desktop',
      category: 'sync',
      level: 'error',
      endpoint: 'POST /api/v1/sync',
      statusCode: 401,
      errorCode: 'unauthorized',
      message: 'Failed with Bearer supersecret123',
      details: { token: 'abc123', host: '192.168.1.5' }
    });

    const http = require('node:http');
    await new Promise((resolve) => {
      const req = http.request({
        hostname: '127.0.0.1', port, path: '/api/v1/sync', method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer invalid-tok' }
      }, (res) => { res.resume(); res.on('end', resolve); });
      req.end('{}');
    });

    const logs = repo.getAuditLogs({ range: 'week' });
    assert.ok(logs.length >= 2);
    assert.ok(logs.some(l => l.error_code === 'unauthorized' && l.status_code === 401));
    const secretEntry = logs.find(l => l.details && l.details.host === '192.168.1.5');
    assert.ok(secretEntry);
    assert.strictEqual(secretEntry.details.token, '[REDACTED]');
    assert.strictEqual(secretEntry.message.includes('supersecret123'), false);

    repo.clearAuditLogs();
    assert.strictEqual(repo.getAuditLogs({ range: 'week' }).length, 0);
  });

  await server.stop();
  db.close();
});

test('Milestone 5 & 6: Palette defaults, preferences, v3 workspaces, pre-M6 backup & JSON export/restore', async (t) => {
  const fs = require('node:fs');
  const os = require('node:os');
  const path = require('node:path');
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'lk-m6-test-'));
  const dbPath = path.join(tmpDir, 'test.db');

  // Create a minimal pre-M6 database first to verify automatic backup & column migration
  const { DatabaseSync } = require('node:sqlite');
  const oldSqlite = new DatabaseSync(dbPath);
  oldSqlite.exec(`
    CREATE TABLE groups (id TEXT PRIMARY KEY, name TEXT NOT NULL, sort INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL, seq INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE tasks (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, name TEXT NOT NULL, core INTEGER NOT NULL DEFAULT 0, sort INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL, seq INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE rewards (id TEXT PRIMARY KEY, name TEXT NOT NULL, cost INTEGER NOT NULL, sort INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, deactivated_at INTEGER, updated_at INTEGER NOT NULL, seq INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE checks (task_id TEXT NOT NULL, day TEXT NOT NULL, checked INTEGER NOT NULL, updated_at INTEGER NOT NULL, seq INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (task_id, day));
    CREATE TABLE claims (id TEXT PRIMARY KEY, reward_id TEXT, name TEXT NOT NULL, cost INTEGER NOT NULL, day TEXT NOT NULL, claimed_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, seq INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
  `);
  oldSqlite.prepare("INSERT INTO groups (id, name, sort, is_active, updated_at, seq) VALUES ('g1', 'Morning', 0, 1, 100, 1)").run();
  oldSqlite.close();

  const db = new Database(dbPath);
  const repo = new Repository(db);

  await t.test('creates pre-migration backup once and migrates M6 columns + tables', () => {
    assert.strictEqual(fs.existsSync(`${dbPath}.pre-m6.bak`), true);
    const taskCols = db.sqlite.prepare('PRAGMA table_info(tasks)').all().map(c => c.name);
    assert.ok(taskCols.includes('priority'));
    assert.ok(taskCols.includes('due_date'));
  });

  await t.test('persists White & Pink default palette, userName, language & chart visibility', () => {
    const def = repo.getAppPreferences();
    assert.strictEqual(def.colorPalette, 'pink');
    assert.strictEqual(def.userName, 'User');
    assert.strictEqual(def.language, 'en');
    assert.strictEqual(def.showReportCharts, true);

    const savedLayout = repo.saveDashboardLayout([
      { id: 'w-fin', visible: true, size: 'full', label: 'My Wallet' },
      { id: 'w-hlth', visible: false, size: 'half', label: 'Health Hub' },
    ]);
    assert.strictEqual(savedLayout[0].label, 'My Wallet');
    assert.strictEqual(repo.getDashboardLayout()[1].label, 'Health Hub');
    assert.strictEqual(repo.getDashboardLayout()[1].visible, false);

    const updated = repo.saveAppPreferences({
      colorPalette: 'lavender',
      userName: 'Luthfi',
      language: 'id',
      showReportCharts: false,
      waterGoalGlasses: 10,
      weightGoalKg: '60',
    });
    assert.strictEqual(updated.colorPalette, 'lavender');
    assert.strictEqual(updated.userName, 'Luthfi');
    assert.strictEqual(updated.language, 'id');
    assert.strictEqual(updated.showReportCharts, false);
    assert.strictEqual(updated.waterGoalGlasses, 10);
    assert.strictEqual(updated.weightGoalKg, '60');
    assert.strictEqual(db.getMeta('user_name_customized'), 'true');
  });

  await t.test('supports savings goals, recurring bills, meal slots, gratitude, note pin, and JSON restore', () => {
    const today = '2026-11-18';
    const goal = repo.saveSavingsGoal({ name: 'Emergency Fund', target_amount: 1000000, current_amount: 250000 });
    const bill = repo.saveRecurringBill({ name: 'Internet', kind: 'bill', amount: 300000, due_day: 20 });
    repo.saveHealthEntry({ day: today, kind: 'food', meal_slot: 'breakfast', name: 'Oats', value_num: 320 });
    repo.saveHealthEntry({ day: today, kind: 'measurement', name: 'Waist', value_num: 74, unit: 'cm' });
    repo.saveWellnessEntry({ day: today, mood: 'Calm', mood_score: 4, energy: 4, stress: 2, sleep_hours: 7.5, gratitude_text: 'Quiet morning' });
    repo.saveMenstrualEntry({ day: today, phase: 'Menstrual', cycle_day: 1, is_period_start: 1, cycle_length: 28 });
    const note = repo.saveNote({ day: today, title: 'Pinned Note', body: 'Hello world', category: 'braindump', is_pinned: 1 });

    const finRep = repo.getModuleReport({ module: 'finance', range: 'week', today });
    assert.strictEqual(finRep.savingsGoals.length, 1);
    assert.strictEqual(finRep.savingsGoals[0].id, goal.id);
    assert.strictEqual(finRep.recurringBills.length, 1);
    assert.strictEqual(finRep.recurringBills[0].id, bill.id);

    const hlthRep = repo.getModuleReport({ module: 'health', range: 'week', today });
    assert.strictEqual(hlthRep.foodLogs[0].meal_slot, 'breakfast');
    assert.strictEqual(hlthRep.latestMeasurements.Waist.value_num, 74);

    const mensRep = repo.getModuleReport({ module: 'menstrual', range: 'week', today });
    assert.ok(mensRep.nextPeriodEstimate);
    assert.strictEqual(mensRep.nextPeriodEstimate.isEstimate, true);
    assert.strictEqual(mensRep.nextPeriodEstimate.estimatedStartDay, '2026-12-16');

    const exported = repo.exportAllDataJson();
    assert.strictEqual(exported.prefs.userName, 'Luthfi');
    assert.ok(exported.changes.savings_goals.some(s => s.id === goal.id));
    assert.ok(exported.changes.notes.some(n => n.id === note.id && n.is_pinned === 1));

    const freshDb = new Database(':memory:');
    const freshRepo = new Repository(freshDb);
    const restored = freshRepo.importAllDataJson(exported);
    assert.strictEqual(restored.ok, true);
    assert.strictEqual(freshRepo.getAppPreferences().userName, 'Luthfi');
    assert.strictEqual(freshRepo.getSavingsGoals().length, 1);
    freshDb.close();
  });

  await t.test('Milestone 7: SyncServer binds custom IP & live-restarts on custom port', async () => {
    const srv = new SyncServer(db, repo);
    const p1 = await srv.start(9288, '127.0.0.1', { fallbackRange: false });
    assert.strictEqual(p1, 9288);
    assert.strictEqual(srv.host, '127.0.0.1');

    const p2 = await srv.restart(9289, '127.0.0.1', { fallbackRange: false });
    assert.strictEqual(p2, 9289);
    const ping = await new Promise((resolve, reject) => {
      const req = http.get({ hostname: '127.0.0.1', port: 9289, path: '/api/v1/ping', agent: false }, res => {
        let raw = '';
        res.on('data', c => raw += c);
        res.on('end', () => resolve({ status: res.statusCode, json: JSON.parse(raw) }));
      });
      req.on('error', reject);
    });
    assert.strictEqual(ping.status, 200);
    assert.strictEqual(ping.json.app, 'langkah-kecil');
    await srv.stop();
  });

  await t.test('Milestone 8: pinned motivational reminder, envelope edit/delete, notes newest-first & task permanent deletion tombstone', () => {
    const today = '2026-11-19';
    // 1. Little Note pinned motivational reminder + Notes newest-first ordering
    const mot = repo.saveNote({
      id: 'little-note-motivation',
      day: '2026-11-10',
      title: 'Motivational Reminder ♡',
      body: 'Keep going steadily',
      category: 'gratitude',
      is_pinned: 1,
    });
    const newerNote = repo.saveNote({
      day: today,
      title: 'Just Saved Top Note',
      body: 'Appears first above older pinned notes',
      category: 'journal',
      is_pinned: 0,
    });
    db.sqlite.prepare('UPDATE notes SET updated_at = ? WHERE id = ?').run(Date.now() - 50000, mot.id);
    db.sqlite.prepare('UPDATE notes SET updated_at = ? WHERE id = ?').run(Date.now() + 50000, newerNote.id);
    const sum = repo.getLifeOsSummary(today);
    assert.ok(sum.notes.pinnedReminder);
    assert.strictEqual(sum.notes.pinnedReminder.id, 'little-note-motivation');
    assert.strictEqual(sum.notes.latestTitle, 'Just Saved Top Note');
    const notesRep = repo.getModuleReport({ module: 'notes', range: 'month', today });
    assert.strictEqual(notesRep.entries[0].id, newerNote.id);

    // 2. Finance Envelope edit & delete
    const env = repo.saveEnvelope({ name: 'Jajan', monthly_budget: 300000 });
    const envEdited = repo.saveEnvelope({ id: env.id, name: 'Jajan & Kopi', monthly_budget: 450000 });
    assert.strictEqual(envEdited.id, env.id);
    assert.strictEqual(envEdited.name, 'Jajan & Kopi');
    assert.strictEqual(envEdited.monthly_budget, 450000);
    assert.strictEqual(repo.getEnvelopes().filter(e => e.id === env.id).length, 1);
    repo._softDeleteRow('finance_envelopes', env.id);
    assert.strictEqual(repo.getEnvelopes().some(e => e.id === env.id), false);

    // 3. Permanent deletion of deactivated task step + deleted_tasks sync tombstone
    const g = repo.saveGroup({ name: 'M8 Group' });
    const step = repo.saveTask({ group_id: g.id, name: 'Delete Me Forever' });
    repo.toggleCheck(step.id, today, true);
    repo.deactivateTask(step.id);
    assert.strictEqual(repo.getInactiveItems().tasks.some(x => x.id === step.id), true);

    const delRes = repo.deleteTaskPermanently(step.id);
    assert.strictEqual(delRes, true);
    assert.strictEqual(repo.getInactiveItems().tasks.some(x => x.id === step.id), false);
    assert.strictEqual(db.sqlite.prepare('SELECT COUNT(*) as c FROM checks WHERE task_id = ?').get(step.id).c, 0);

    const outChanges = repo.getChangesSince(0);
    assert.ok(outChanges.deleted_tasks.some(d => d.id === step.id));

    // Tombstone blocks stale re-creation from older device snapshot
    repo.applyChanges({
      groups: [{ id: g.id, name: g.name, sort_order: 0, is_active: 1, updated_at: Date.now() }],
      tasks: [{ id: step.id, group_id: g.id, name: 'Resurrected?', is_core: 0, sort_order: 0, is_active: 0, updated_at: Date.now() - 10000 }],
      rewards: [],
      checks: [],
      claims: [],
    });
    assert.strictEqual(db.sqlite.prepare('SELECT COUNT(*) as c FROM tasks WHERE id = ?').get(step.id).c, 0);

    // Receiving deleted_tasks from peer removes a local task & its checks
    const peerStep = repo.saveTask({ group_id: g.id, name: 'Peer Deleted' });
    repo.toggleCheck(peerStep.id, today, true);
    repo.applyChanges({ deleted_tasks: [{ id: peerStep.id, deleted_at: Date.now() + 1000 }] });
    assert.strictEqual(db.sqlite.prepare('SELECT COUNT(*) as c FROM tasks WHERE id = ?').get(peerStep.id).c, 0);
    assert.strictEqual(db.sqlite.prepare('SELECT COUNT(*) as c FROM checks WHERE task_id = ?').get(peerStep.id).c, 0);
  });

  db.close();
  fs.rmSync(tmpDir, { recursive: true, force: true });
});
