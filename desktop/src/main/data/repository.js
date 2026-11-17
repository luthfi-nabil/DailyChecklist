const crypto = require('node:crypto');

function formatLocalDay(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function parseLocalDay(dayStr) {
  const [y, m, d] = dayStr.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function getIsoDow(date) {
  const w = date.getDay();
  return w === 0 ? 7 : w; // 1=Mon..7=Sun
}

function parseFreqDays(raw) {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw.map(Number).filter(n => !Number.isNaN(n));
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.map(Number).filter(n => !Number.isNaN(n)) : [];
  } catch (_) {
    return [];
  }
}

function serializeFreqDays(freq, rawDays) {
  if (freq !== 'weekly' && freq !== 'monthly') return null;
  const arr = parseFreqDays(rawDays);
  const unique = [...new Set(arr)].sort((a, b) => a - b);
  return JSON.stringify(unique);
}

function isTaskScheduledOnDate(task, dateObj) {
  const freq = task.freq || 'daily';
  if (freq === 'daily') return true;
  const days = parseFreqDays(task.freq_days);
  if (days.length === 0) return true;
  if (freq === 'weekly') return days.includes(getIsoDow(dateObj));
  if (freq === 'monthly') return days.includes(dateObj.getDate());
  return true;
}

function countScheduledDaysInRange(task, startDateStr, endDateStr) {
  const freq = task.freq || 'daily';
  const start = parseLocalDay(startDateStr);
  const end = parseLocalDay(endDateStr);
  if (freq === 'daily') {
    return Math.max(1, Math.round((end - start) / 86400000) + 1);
  }
  let count = 0;
  const cur = new Date(start);
  while (cur <= end) {
    if (isTaskScheduledOnDate(task, cur)) count++;
    cur.setDate(cur.getDate() + 1);
  }
  return count;
}

class Repository {
  constructor(db) {
    this.db = db;
    this.sqlite = db.sqlite;
  }

  // --- GROUPS ---
  getGroups(includeInactive = false) {
    const sql = includeInactive
      ? 'SELECT * FROM groups ORDER BY sort ASC, rowid ASC'
      : 'SELECT * FROM groups WHERE is_active = 1 ORDER BY sort ASC, rowid ASC';
    return this.sqlite.prepare(sql).all();
  }

  saveGroup(group) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    const id = group.id || crypto.randomUUID();
    const is_active = group.is_active !== undefined ? group.is_active : 1;
    const deactivated_at = group.deactivated_at !== undefined ? group.deactivated_at : null;
    const sort = group.sort || 0;

    const existing = this.sqlite.prepare('SELECT id FROM groups WHERE id = ?').get(id);
    if (existing) {
      this.sqlite.prepare(`
        UPDATE groups SET name = ?, sort = ?, is_active = ?, deactivated_at = ?, updated_at = ?, seq = ?
        WHERE id = ?
      `).run(group.name, sort, is_active, deactivated_at, now, seq, id);
    } else {
      this.sqlite.prepare(`
        INSERT INTO groups (id, name, sort, is_active, deactivated_at, updated_at, seq)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(id, group.name, sort, is_active, deactivated_at, now, seq);
    }
    return this.sqlite.prepare('SELECT * FROM groups WHERE id = ?').get(id);
  }

  moveGroup(id, delta) {
    const groups = this.getGroups(false);
    const idx = groups.findIndex(g => g.id === id);
    const targetIdx = idx + delta;
    if (idx < 0 || targetIdx < 0 || targetIdx >= groups.length) return false;

    const reordered = [...groups];
    [reordered[idx], reordered[targetIdx]] = [reordered[targetIdx], reordered[idx]];

    const now = Date.now();
    const stmt = this.sqlite.prepare('UPDATE groups SET sort = ?, updated_at = ?, seq = ? WHERE id = ?');
    for (let i = 0; i < reordered.length; i++) {
      if (reordered[i].sort !== i || i === idx || i === targetIdx) {
        stmt.run(i, now, this.db.nextSeq(), reordered[i].id);
      }
    }
    return true;
  }

  deactivateGroup(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE groups SET is_active = 0, deactivated_at = ?, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, now, seq, id);

    // Also deactivate associated active tasks
    const tasks = this.sqlite.prepare('SELECT id FROM tasks WHERE group_id = ? AND is_active = 1').all(id);
    for (const t of tasks) {
      const tSeq = this.db.nextSeq();
      this.sqlite.prepare(`
        UPDATE tasks SET is_active = 0, deactivated_at = ?, updated_at = ?, seq = ? WHERE id = ?
      `).run(now, now, tSeq, t.id);
    }
  }

  reactivateGroup(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE groups SET is_active = 1, deactivated_at = NULL, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, seq, id);

    const tasks = this.sqlite.prepare('SELECT id FROM tasks WHERE group_id = ? AND is_active = 0').all(id);
    for (const t of tasks) {
      const tSeq = this.db.nextSeq();
      this.sqlite.prepare(`
        UPDATE tasks SET is_active = 1, deactivated_at = NULL, updated_at = ?, seq = ? WHERE id = ?
      `).run(now, tSeq, t.id);
    }
  }

  // --- TASKS ---
  getTasks(includeInactive = false) {
    const sql = includeInactive
      ? 'SELECT * FROM tasks ORDER BY sort ASC, rowid ASC'
      : 'SELECT * FROM tasks WHERE is_active = 1 ORDER BY sort ASC, rowid ASC';
    return this.sqlite.prepare(sql).all();
  }

  saveTask(task) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    const id = task.id || crypto.randomUUID();
    const core = task.core ? 1 : 0;
    const sort = task.sort || 0;
    const freq = (task.freq === 'weekly' || task.freq === 'monthly') ? task.freq : 'daily';
    const freq_days = serializeFreqDays(freq, task.freq_days);
    const is_active = task.is_active !== undefined ? task.is_active : 1;
    const deactivated_at = task.deactivated_at !== undefined ? task.deactivated_at : null;

    const existing = this.sqlite.prepare('SELECT id FROM tasks WHERE id = ?').get(id);
    if (existing) {
      this.sqlite.prepare(`
        UPDATE tasks SET group_id = ?, name = ?, core = ?, sort = ?, freq = ?, freq_days = ?, is_active = ?, deactivated_at = ?, updated_at = ?, seq = ?
        WHERE id = ?
      `).run(task.group_id, task.name, core, sort, freq, freq_days, is_active, deactivated_at, now, seq, id);
    } else {
      this.sqlite.prepare(`
        INSERT INTO tasks (id, group_id, name, core, sort, freq, freq_days, is_active, deactivated_at, updated_at, seq)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(id, task.group_id, task.name, core, sort, freq, freq_days, is_active, deactivated_at, now, seq);
    }
    return this.sqlite.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
  }

  deactivateTask(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE tasks SET is_active = 0, deactivated_at = ?, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, now, seq, id);
  }

  reactivateTask(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE tasks SET is_active = 1, deactivated_at = NULL, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, seq, id);
  }

  // --- CHECKS ---
  getChecksForDay(day) {
    const rows = this.sqlite.prepare('SELECT * FROM checks WHERE day = ?').all(day);
    const map = {};
    for (const r of rows) {
      if (r.checked === 1) map[r.task_id] = r;
    }
    return map;
  }

  toggleCheck(taskId, day, checked) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    const chk = checked ? 1 : 0;
    this.sqlite.prepare(`
      INSERT INTO checks (task_id, day, checked, updated_at, seq)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(task_id, day) DO UPDATE SET
        checked = excluded.checked,
        updated_at = excluded.updated_at,
        seq = excluded.seq
    `).run(taskId, day, chk, now, seq);
  }

  // --- REWARDS ---
  getRewards(includeInactive = false) {
    const sql = includeInactive
      ? 'SELECT * FROM rewards ORDER BY sort ASC, rowid ASC'
      : 'SELECT * FROM rewards WHERE is_active = 1 ORDER BY sort ASC, rowid ASC';
    return this.sqlite.prepare(sql).all();
  }

  saveReward(reward) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    const id = reward.id || crypto.randomUUID();
    const cost = Math.max(1, Math.min(999, parseInt(reward.cost || 10, 10) || 10));
    const sort = reward.sort || 0;
    const is_active = reward.is_active !== undefined ? reward.is_active : 1;
    const deactivated_at = reward.deactivated_at !== undefined ? reward.deactivated_at : null;

    const existing = this.sqlite.prepare('SELECT id FROM rewards WHERE id = ?').get(id);
    if (existing) {
      this.sqlite.prepare(`
        UPDATE rewards SET name = ?, cost = ?, sort = ?, is_active = ?, deactivated_at = ?, updated_at = ?, seq = ?
        WHERE id = ?
      `).run(reward.name, cost, sort, is_active, deactivated_at, now, seq, id);
    } else {
      this.sqlite.prepare(`
        INSERT INTO rewards (id, name, cost, sort, is_active, deactivated_at, updated_at, seq)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).run(id, reward.name, cost, sort, is_active, deactivated_at, now, seq);
    }
    return this.sqlite.prepare('SELECT * FROM rewards WHERE id = ?').get(id);
  }

  deactivateReward(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE rewards SET is_active = 0, deactivated_at = ?, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, now, seq, id);
  }

  reactivateReward(id) {
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`
      UPDATE rewards SET is_active = 1, deactivated_at = NULL, updated_at = ?, seq = ? WHERE id = ?
    `).run(now, seq, id);
  }

  // --- CLAIMS ---
  claimReward(rewardId, day) {
    const reward = this.sqlite.prepare('SELECT * FROM rewards WHERE id = ?').get(rewardId);
    if (!reward) throw new Error('Reward not found');

    const bal = this.getPointsBalance();
    if (bal < reward.cost) throw new Error('Not enough points');

    const now = Date.now();
    const seq = this.db.nextSeq();
    const id = crypto.randomUUID();

    this.sqlite.prepare(`
      INSERT INTO claims (id, reward_id, name, cost, day, claimed_at, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(id, reward.id, reward.name, reward.cost, day, now, now, seq);

    return { id, reward_id: reward.id, name: reward.name, cost: reward.cost, day, claimed_at: now, updated_at: now };
  }

  undoClaim(claimId) {
    const claim = this.sqlite.prepare('SELECT * FROM claims WHERE id = ?').get(claimId);
    if (!claim) return false;
    const pairedDevices = JSON.parse(this.db.getMeta('paired_devices') || '[]');
    const maxSync = pairedDevices.reduce((max, d) => Math.max(max, d.last_synced_at || 0), 0);
    if (maxSync >= claim.updated_at) {
      return false; // Already synced
    }
    this.sqlite.prepare('DELETE FROM claims WHERE id = ?').run(claimId);
    return true;
  }

  getClaims() {
    return this.sqlite.prepare('SELECT * FROM claims ORDER BY claimed_at DESC').all();
  }

  getPointsBalance() {
    const earnedRow = this.sqlite.prepare('SELECT COUNT(*) as total FROM checks WHERE checked = 1').get();
    const spentRow = this.sqlite.prepare('SELECT COALESCE(SUM(cost), 0) as total FROM claims').get();
    const earned = earnedRow ? earnedRow.total : 0;
    const spent = spentRow ? spentRow.total : 0;
    return Math.max(0, earned - spent);
  }

  // --- COMBINED TODAY VIEW DATA ---
  getTodayData(day) {
    const groups = this.getGroups(false);
    const tasks = this.getTasks(false);
    const checks = this.getChecksForDay(day);
    const balance = this.getPointsBalance();
    const dateObj = parseLocalDay(day);

    const groupsWithTasks = groups.map(g => {
      const gTasks = tasks.filter(t => t.group_id === g.id);
      return {
        ...g,
        tasks: gTasks.map(t => ({
          ...t,
          freq: t.freq || 'daily',
          freq_days: parseFreqDays(t.freq_days),
          scheduled: isTaskScheduledOnDate(t, dateObj),
          done: !!checks[t.id]
        }))
      };
    });

    return {
      day,
      balance,
      groups: groupsWithTasks
    };
  }

  getMonthScheduleDots(year, month) {
    const tasks = this.getTasks(false);
    const daysInMonth = new Date(year, month, 0).getDate();
    const dots = {};
    for (let d = 1; d <= daysInMonth; d++) {
      const dateObj = new Date(year, month - 1, d);
      const dayStr = formatLocalDay(dateObj);
      let hasWeekly = false;
      let hasMonthly = false;
      for (const t of tasks) {
        if (t.freq === 'weekly' && isTaskScheduledOnDate(t, dateObj)) hasWeekly = true;
        if (t.freq === 'monthly' && isTaskScheduledOnDate(t, dateObj)) hasMonthly = true;
      }
      if (hasWeekly || hasMonthly) {
        dots[dayStr] = { hasWeekly, hasMonthly };
      }
    }
    return dots;
  }

  // --- INACTIVE VIEW DATA ---
  getInactiveItems() {
    const tasks = this.sqlite.prepare(`
      SELECT t.*, g.name as group_name,
        (SELECT COUNT(*) FROM checks c WHERE c.task_id = t.id AND c.checked = 1) as completed_count
      FROM tasks t
      LEFT JOIN groups g ON t.group_id = g.id
      WHERE t.is_active = 0
      ORDER BY t.deactivated_at DESC
    `).all();

    const groups = this.sqlite.prepare(`
      SELECT g.*,
        (SELECT COUNT(*) FROM tasks t WHERE t.group_id = g.id) as task_count
      FROM groups g
      WHERE g.is_active = 0
      ORDER BY g.deactivated_at DESC
    `).all();

    return { tasks, groups };
  }

  // --- ANALYTICS / DASHBOARD ---
  getDashboardStats(period = 'week', refDateStr = null) {
    const today = refDateStr || formatLocalDay(new Date());
    const refDate = parseLocalDay(today);

    let startDateStr;
    let label;
    let daysCount = 7;

    if (period === 'week') {
      const start = new Date(refDate);
      start.setDate(refDate.getDate() - 6);
      startDateStr = formatLocalDay(start);
      label = '7 hari terakhir';
      daysCount = 7;
    } else if (period === 'month') {
      const start = new Date(refDate.getFullYear(), refDate.getMonth(), 1);
      startDateStr = formatLocalDay(start);
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      label = `1–${refDate.getDate()} ${months[refDate.getMonth()]}`;
      daysCount = refDate.getDate();
    } else {
      const earliest = this.sqlite.prepare('SELECT MIN(day) as minDay FROM checks').get()?.minDay || today;
      startDateStr = earliest;
      const start = parseLocalDay(earliest);
      daysCount = Math.max(1, Math.round((refDate - start) / (1000 * 60 * 60 * 24)) + 1);
      label = `Sejak ${earliest}`;
    }

    const checksInRange = this.sqlite.prepare(`
      SELECT day, COUNT(*) as done
      FROM checks
      WHERE day >= ? AND day <= ? AND checked = 1
      GROUP BY day
    `).all(startDateStr, today);

    const checksMap = {};
    for (const c of checksInRange) {
      checksMap[c.day] = c.done;
    }

    const activeDays = checksInRange.filter(c => c.done > 0).length;
    const totalDone = checksInRange.reduce((acc, c) => acc + c.done, 0);
    const pointsEarned = totalDone;

    // Streak calculation (consecutive days with >= 1 check up to today or yesterday)
    let currentStreak = 0;
    const cur = new Date(refDate);
    const checkCountStmt = this.sqlite.prepare('SELECT COUNT(*) as count FROM checks WHERE day = ? AND checked = 1');
    for (let guard = 0; guard < 3650; guard++) {
      const dStr = formatLocalDay(cur);
      const doneOnD = checkCountStmt.get(dStr)?.count || 0;
      if (doneOnD > 0) {
        currentStreak++;
        cur.setDate(cur.getDate() - 1);
      } else if (dStr === today && currentStreak === 0) {
        cur.setDate(cur.getDate() - 1);
      } else {
        break;
      }
    }

    const activeTasksAll = this.sqlite.prepare('SELECT id, group_id, freq, freq_days FROM tasks WHERE is_active = 1').all();
    const maxPossible = activeTasksAll.reduce((sum, t) => sum + countScheduledDaysInRange(t, startDateStr, today), 0);
    const rate = maxPossible > 0 ? Math.min(100, Math.round((totalDone / maxPossible) * 100)) : 0;

    // Chart daily bars (last 7 days up to refDate)
    const dailyChart = [];
    const dowNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(refDate);
      d.setDate(refDate.getDate() - i);
      const dStr = formatLocalDay(d);
      const count = checksMap[dStr] || 0;
      dailyChart.push({
        day: dStr,
        dow: i === 0 ? 'Hari ini' : dowNames[d.getDay()],
        count,
        isToday: i === 0
      });
    }

    // Per group breakdown
    const groups = this.sqlite.prepare('SELECT id, name FROM groups WHERE is_active = 1 ORDER BY sort ASC').all();
    const groupDoneStmt = this.sqlite.prepare(`
      SELECT COUNT(*) as c FROM checks c
      JOIN tasks t ON c.task_id = t.id
      WHERE t.group_id = ? AND c.day >= ? AND c.day <= ? AND c.checked = 1
    `);
    const groupStats = groups.map(g => {
      const gActiveTasks = activeTasksAll.filter(t => t.group_id === g.id);
      const done = groupDoneStmt.get(g.id, startDateStr, today)?.c || 0;
      const possible = gActiveTasks.reduce((sum, t) => sum + countScheduledDaysInRange(t, startDateStr, today), 0);
      const gRate = possible > 0 ? Math.min(100, Math.round((done / possible) * 100)) : 0;
      return { id: g.id, name: g.name, rate: gRate, done, possible };
    });

    // Per task breakdown (include deactivated tasks that have checks or were active in range)
    const allTasks = this.sqlite.prepare('SELECT id, name, freq, freq_days, is_active, deactivated_at FROM tasks').all();
    const taskDoneStmt = this.sqlite.prepare(`
      SELECT COUNT(*) as c FROM checks
      WHERE day >= ? AND day <= ? AND checked = 1 AND task_id = ?
    `);
    const taskStats = allTasks.map(t => {
      const done = taskDoneStmt.get(startDateStr, today, t.id)?.c || 0;
      const scheduledDays = Math.max(done, countScheduledDaysInRange(t, startDateStr, today));
      return {
        id: t.id,
        name: t.name,
        freq: t.freq || 'daily',
        freqDays: parseFreqDays(t.freq_days),
        isActive: t.is_active === 1,
        deactivatedAt: t.deactivated_at,
        done,
        totalDays: scheduledDays,
        rate: scheduledDays > 0 ? Math.min(100, Math.round((done / scheduledDays) * 100)) : 0
      };
    }).filter(t => t.isActive || t.done > 0).sort((a, b) => b.done - a.done);

    return {
      period,
      label,
      rate,
      totalDone,
      activeDays,
      daysCount,
      currentStreak,
      pointsEarned,
      dailyChart,
      groupStats,
      taskStats
    };
  }

  // --- DAY LOG ---
  getDayLog(day) {
    const checks = this.sqlite.prepare('SELECT * FROM checks WHERE day = ?').all(day);
    const checksMap = {};
    for (const c of checks) {
      checksMap[c.task_id] = c;
    }

    const groups = this.sqlite.prepare('SELECT * FROM groups ORDER BY sort ASC').all();
    const tasks = this.sqlite.prepare('SELECT * FROM tasks ORDER BY sort ASC').all();

    let totalTasks = 0;
    let completedTasks = 0;
    const dayDate = parseLocalDay(day);
    const dayEndMs = dayDate.getTime() + 86399999;

    const groupLogs = groups.map(g => {
      const gTasks = tasks.filter(t => {
        if (t.group_id !== g.id) return false;
        if (checksMap[t.id]) return true;
        const wasActive = t.is_active === 1 || (t.deactivated_at && t.deactivated_at > dayEndMs);
        return wasActive && isTaskScheduledOnDate(t, dayDate);
      });

      const taskLogs = gTasks.map(t => {
        totalTasks++;
        const chk = checksMap[t.id];
        const isDone = !!(chk && chk.checked === 1);
        if (isDone) completedTasks++;

        let timeStr = 'terlewat';
        if (isDone && chk.updated_at) {
          const d = new Date(chk.updated_at);
          timeStr = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
        }

        return {
          id: t.id,
          name: t.name,
          isActive: t.is_active === 1,
          deactivatedAt: t.deactivated_at,
          done: isDone,
          time: timeStr
        };
      });

      return {
        id: g.id,
        name: g.name,
        doneCount: taskLogs.filter(t => t.done).length,
        totalCount: taskLogs.length,
        tasks: taskLogs
      };
    }).filter(g => g.tasks.length > 0);

    return {
      day,
      totalTasks,
      completedTasks,
      rate: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0,
      groups: groupLogs
    };
  }

  // --- MONTH ACTIVITY (CALENDAR HEATMAP) ---
  getMonthActivity(year, month) {
    const mStr = String(month).padStart(2, '0');
    const prefix = `${year}-${mStr}`;

    const rows = this.sqlite.prepare(`
      SELECT day, COUNT(*) as count
      FROM checks
      WHERE day LIKE ? AND checked = 1
      GROUP BY day
    `).all(`${prefix}%`);

    const activityMap = {};
    for (const r of rows) {
      let level = 1;
      if (r.count >= 8) level = 3;
      else if (r.count >= 4) level = 2;
      activityMap[r.day] = { count: r.count, level };
    }

    return activityMap;
  }

  // --- SYNC EXPORT & IMPORT ---
  getChangesSince(since, excludeKeys = null) {
    let groups = this.sqlite.prepare('SELECT id, name, sort, is_active, deactivated_at, updated_at FROM groups WHERE seq > ?').all(since);
    let tasks = this.sqlite.prepare('SELECT id, group_id, name, core, sort, freq, freq_days, is_active, deactivated_at, updated_at FROM tasks WHERE seq > ?').all(since);
    let rewards = this.sqlite.prepare('SELECT id, name, cost, sort, is_active, deactivated_at, updated_at FROM rewards WHERE seq > ?').all(since);
    let checks = this.sqlite.prepare('SELECT task_id, day, checked, updated_at FROM checks WHERE seq > ?').all(since);
    let claims = this.sqlite.prepare('SELECT id, reward_id, name, cost, day, claimed_at, updated_at FROM claims WHERE seq > ?').all(since);

    if (excludeKeys) {
      groups = groups.filter(g => !excludeKeys.groups.has(g.id));
      tasks = tasks.filter(t => !excludeKeys.tasks.has(t.id));
      rewards = rewards.filter(r => !excludeKeys.rewards.has(r.id));
      checks = checks.filter(c => !excludeKeys.checks.has(`${c.task_id}|${c.day}`));
      claims = claims.filter(cl => !excludeKeys.claims.has(cl.id));
    }

    return { groups, tasks, rewards, checks, claims };
  }

  applyChanges(changes, clientDeviceId = '') {
    const myDeviceId = this.db.getMeta('device_id') || '';
    const acceptedKeys = {
      groups: new Set(),
      tasks: new Set(),
      rewards: new Set(),
      checks: new Set(),
      claims: new Set()
    };

    const shouldOverwrite = (incomingUpdatedAt, existingUpdatedAt) => {
      if (incomingUpdatedAt > existingUpdatedAt) return true;
      if (incomingUpdatedAt < existingUpdatedAt) return false;
      return clientDeviceId > myDeviceId;
    };

    if (changes.groups && Array.isArray(changes.groups)) {
      for (const g of changes.groups) {
        const existing = this.sqlite.prepare('SELECT updated_at FROM groups WHERE id = ?').get(g.id);
        if (!existing || shouldOverwrite(g.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          this.sqlite.prepare(`
            INSERT INTO groups (id, name, sort, is_active, deactivated_at, updated_at, seq)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              name = excluded.name,
              sort = excluded.sort,
              is_active = excluded.is_active,
              deactivated_at = excluded.deactivated_at,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(g.id, g.name, g.sort || 0, g.is_active, g.deactivated_at ?? null, g.updated_at, seq);
          acceptedKeys.groups.add(g.id);
        }
      }
    }

    if (changes.tasks && Array.isArray(changes.tasks)) {
      for (const t of changes.tasks) {
        const existing = this.sqlite.prepare('SELECT updated_at FROM tasks WHERE id = ?').get(t.id);
        if (!existing || shouldOverwrite(t.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          const freq = (t.freq === 'weekly' || t.freq === 'monthly') ? t.freq : 'daily';
          const freqDays = serializeFreqDays(freq, t.freq_days);
          this.sqlite.prepare(`
            INSERT INTO tasks (id, group_id, name, core, sort, freq, freq_days, is_active, deactivated_at, updated_at, seq)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              group_id = excluded.group_id,
              name = excluded.name,
              core = excluded.core,
              sort = excluded.sort,
              freq = excluded.freq,
              freq_days = excluded.freq_days,
              is_active = excluded.is_active,
              deactivated_at = excluded.deactivated_at,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(t.id, t.group_id, t.name, t.core || 0, t.sort || 0, freq, freqDays, t.is_active, t.deactivated_at ?? null, t.updated_at, seq);
          acceptedKeys.tasks.add(t.id);
        }
      }
    }

    if (changes.rewards && Array.isArray(changes.rewards)) {
      for (const r of changes.rewards) {
        const existing = this.sqlite.prepare('SELECT updated_at FROM rewards WHERE id = ?').get(r.id);
        if (!existing || shouldOverwrite(r.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          this.sqlite.prepare(`
            INSERT INTO rewards (id, name, cost, sort, is_active, deactivated_at, updated_at, seq)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              name = excluded.name,
              cost = excluded.cost,
              sort = excluded.sort,
              is_active = excluded.is_active,
              deactivated_at = excluded.deactivated_at,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(r.id, r.name, r.cost, r.sort || 0, r.is_active, r.deactivated_at ?? null, r.updated_at, seq);
          acceptedKeys.rewards.add(r.id);
        }
      }
    }

    if (changes.checks && Array.isArray(changes.checks)) {
      for (const c of changes.checks) {
        const existing = this.sqlite.prepare('SELECT updated_at FROM checks WHERE task_id = ? AND day = ?').get(c.task_id, c.day);
        if (!existing || shouldOverwrite(c.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          this.sqlite.prepare(`
            INSERT INTO checks (task_id, day, checked, updated_at, seq)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(task_id, day) DO UPDATE SET
              checked = excluded.checked,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(c.task_id, c.day, c.checked, c.updated_at, seq);
          acceptedKeys.checks.add(`${c.task_id}|${c.day}`);
        }
      }
    }

    if (changes.claims && Array.isArray(changes.claims)) {
      for (const cl of changes.claims) {
        const existing = this.sqlite.prepare('SELECT updated_at FROM claims WHERE id = ?').get(cl.id);
        if (!existing || shouldOverwrite(cl.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          this.sqlite.prepare(`
            INSERT INTO claims (id, reward_id, name, cost, day, claimed_at, updated_at, seq)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              name = excluded.name,
              cost = excluded.cost,
              day = excluded.day,
              claimed_at = excluded.claimed_at,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(cl.id, cl.reward_id ?? null, cl.name, cl.cost, cl.day, cl.claimed_at, cl.updated_at, seq);
          acceptedKeys.claims.add(cl.id);
        }
      }
    }

    return acceptedKeys;
  }
}

module.exports = { Repository };
