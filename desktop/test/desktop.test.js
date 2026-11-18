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
