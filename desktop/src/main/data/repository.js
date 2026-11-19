const crypto = require('node:crypto');
const {
  DEFAULT_DASHBOARD_LAYOUT,
  VALID_PALETTES,
  LIFEOS_SYNC_TABLES,
  sanitizeAuditDetails,
  parseJsonArray,
  resolveReportBounds,
} = require('./lifeOsHelpers');

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
    const priority = ['low', 'normal', 'high'].includes(task.priority) ? task.priority : 'normal';
    const due_date = task.due_date ? String(task.due_date).slice(0, 10) : null;
    const is_active = task.is_active !== undefined ? task.is_active : 1;
    const deactivated_at = task.deactivated_at !== undefined ? task.deactivated_at : null;

    const existing = this.sqlite.prepare('SELECT id FROM tasks WHERE id = ?').get(id);
    if (existing) {
      this.sqlite.prepare(`
        UPDATE tasks SET group_id = ?, name = ?, core = ?, sort = ?, freq = ?, freq_days = ?, priority = ?, due_date = ?, is_active = ?, deactivated_at = ?, updated_at = ?, seq = ?
        WHERE id = ?
      `).run(task.group_id, task.name, core, sort, freq, freq_days, priority, due_date, is_active, deactivated_at, now, seq, id);
    } else {
      this.sqlite.prepare(`
        INSERT INTO tasks (id, group_id, name, core, sort, freq, freq_days, priority, due_date, is_active, deactivated_at, updated_at, seq)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(id, task.group_id, task.name, core, sort, freq, freq_days, priority, due_date, is_active, deactivated_at, now, seq);
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

  deleteTaskPermanently(id) {
    if (!id) return false;
    const now = Date.now();
    let tombs = {};
    try {
      const raw = this.db.getMeta('deleted_task_tombstones');
      if (raw) tombs = JSON.parse(raw) || {};
    } catch (_) {}
    tombs[id] = now;
    const bounded = Object.entries(tombs).sort((a, b) => b[1] - a[1]).slice(0, 500);
    this.db.setMeta('deleted_task_tombstones', JSON.stringify(Object.fromEntries(bounded)));
    this.db.nextSeq();
    this.sqlite.prepare('DELETE FROM checks WHERE task_id = ?').run(id);
    this.sqlite.prepare('DELETE FROM tasks WHERE id = ?').run(id);
    return true;
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
    let tasks = this.sqlite.prepare('SELECT id, group_id, name, core, sort, freq, freq_days, priority, due_date, is_active, deactivated_at, updated_at FROM tasks WHERE seq > ?').all(since);
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

    const result = { groups, tasks, rewards, checks, claims };
    let tombs = {};
    try {
      const raw = this.db.getMeta('deleted_task_tombstones');
      if (raw) tombs = JSON.parse(raw) || {};
    } catch (_) {}
    const deletedTasks = Object.entries(tombs)
      .filter(([, ts]) => since === 0 || ts > since)
      .map(([id, deleted_at]) => ({ id, deleted_at }));
    if (deletedTasks.length > 0) {
      result.deleted_tasks = deletedTasks;
    }
    for (const tbl of LIFEOS_SYNC_TABLES) {
      let rows = this.sqlite.prepare(`SELECT ${tbl.cols.join(', ')} FROM ${tbl.name} WHERE seq > ?`).all(since);
      if (excludeKeys && excludeKeys[tbl.name]) {
        rows = rows.filter(r => !excludeKeys[tbl.name].has(r.id));
      }
      result[tbl.name] = rows;
    }

    return result;
  }

  applyChanges(changes, clientDeviceId = '') {
    const myDeviceId = this.db.getMeta('device_id') || '';
    let tombs = {};
    let tombsDirty = false;
    try {
      const raw = this.db.getMeta('deleted_task_tombstones');
      if (raw) tombs = JSON.parse(raw) || {};
    } catch (_) {}

    if (changes.deleted_tasks && Array.isArray(changes.deleted_tasks)) {
      for (const d of changes.deleted_tasks) {
        if (!d || !d.id) continue;
        const delAt = Number(d.deleted_at) || 0;
        const existing = this.sqlite.prepare('SELECT updated_at FROM tasks WHERE id = ?').get(d.id);
        if (!existing || delAt >= (existing.updated_at || 0)) {
          this.sqlite.prepare('DELETE FROM checks WHERE task_id = ?').run(d.id);
          this.sqlite.prepare('DELETE FROM tasks WHERE id = ?').run(d.id);
          tombs[d.id] = Math.max(tombs[d.id] || 0, delAt);
          tombsDirty = true;
          this.db.nextSeq();
        }
      }
    }

    const acceptedKeys = {
      groups: new Set(),
      tasks: new Set(),
      rewards: new Set(),
      checks: new Set(),
      claims: new Set()
    };
    for (const tbl of LIFEOS_SYNC_TABLES) {
      acceptedKeys[tbl.name] = new Set();
    }

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
        if (tombs[t.id] && tombs[t.id] >= (t.updated_at || 0)) {
          continue;
        }
        if (tombs[t.id] && (t.updated_at || 0) > tombs[t.id]) {
          delete tombs[t.id];
          tombsDirty = true;
        }
        const existing = this.sqlite.prepare('SELECT updated_at FROM tasks WHERE id = ?').get(t.id);
        if (!existing || shouldOverwrite(t.updated_at, existing.updated_at)) {
          const seq = this.db.nextSeq();
          const freq = (t.freq === 'weekly' || t.freq === 'monthly') ? t.freq : 'daily';
          const freqDays = serializeFreqDays(freq, t.freq_days);
          const priority = ['low', 'normal', 'high'].includes(t.priority) ? t.priority : 'normal';
          const dueDate = t.due_date ? String(t.due_date).slice(0, 10) : null;
          this.sqlite.prepare(`
            INSERT INTO tasks (id, group_id, name, core, sort, freq, freq_days, priority, due_date, is_active, deactivated_at, updated_at, seq)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              group_id = excluded.group_id,
              name = excluded.name,
              core = excluded.core,
              sort = excluded.sort,
              freq = excluded.freq,
              freq_days = excluded.freq_days,
              priority = excluded.priority,
              due_date = excluded.due_date,
              is_active = excluded.is_active,
              deactivated_at = excluded.deactivated_at,
              updated_at = excluded.updated_at,
              seq = excluded.seq
          `).run(t.id, t.group_id, t.name, t.core || 0, t.sort || 0, freq, freqDays, priority, dueDate, t.is_active, t.deactivated_at ?? null, t.updated_at, seq);
          acceptedKeys.tasks.add(t.id);
        }
      }
    }

    if (tombsDirty) {
      const bounded = Object.entries(tombs).sort((a, b) => b[1] - a[1]).slice(0, 500);
      this.db.setMeta('deleted_task_tombstones', JSON.stringify(Object.fromEntries(bounded)));
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

    const notNullDefaults = {
      status: 'active',
      progress: 0,
      is_someday: 0,
      monthly_budget: 0,
      category: 'general',
      target_amount: 0,
      current_amount: 0,
      kind: 'bill',
      amount: 0,
      due_day: 1,
      is_paid: 0,
      is_pinned: 0,
      is_active: 1,
      cycle_day: 1,
      is_period_start: 0,
    };

    for (const tbl of LIFEOS_SYNC_TABLES) {
      const list = changes[tbl.name];
      if (!list || !Array.isArray(list)) continue;
      const placeholders = tbl.cols.map(() => '?').join(', ');
      const updateSet = tbl.cols.filter(c => c !== 'id').map(c => `${c} = excluded.${c}`).join(', ');
      const findStmt = this.sqlite.prepare(`SELECT updated_at FROM ${tbl.name} WHERE id = ?`);
      const upsertStmt = this.sqlite.prepare(`
        INSERT INTO ${tbl.name} (${tbl.cols.join(', ')}, seq)
        VALUES (${placeholders}, ?)
        ON CONFLICT(id) DO UPDATE SET ${updateSet}, seq = excluded.seq
      `);

      for (const row of list) {
        if (!row || !row.id) continue;
        const existing = findStmt.get(row.id);
        if (!existing || shouldOverwrite(row.updated_at || 0, existing.updated_at)) {
          const seq = this.db.nextSeq();
          const vals = tbl.cols.map(c => {
            if (row[c] !== undefined && row[c] !== null) return row[c];
            if (tbl.name === 'notes' && c === 'category') return 'journal';
            if (c in notNullDefaults) return notNullDefaults[c];
            return null;
          });
          upsertStmt.run(...vals, seq);
          acceptedKeys[tbl.name].add(row.id);
        }
      }
    }

    return acceptedKeys;
  }

  // --- PERSONAL LIFE OS: LAYOUT & CRUD ---
  getDashboardLayout() {
    const raw = this.db.getMeta('dashboard_layout_v1');
    if (raw) {
      const parsed = parseJsonArray(raw);
      if (parsed.length > 0) return parsed;
    }
    return DEFAULT_DASHBOARD_LAYOUT.map(x => ({ ...x }));
  }

  saveDashboardLayout(layout) {
    const safe = Array.isArray(layout) ? layout.map(w => ({
      id: String(w.id),
      visible: w.visible !== false,
      size: ['s', 'm', 'l'].includes(w.size) ? w.size : 'm',
      ...(w.label ? { label: String(w.label).trim().slice(0, 32) } : {}),
    })) : DEFAULT_DASHBOARD_LAYOUT;
    this.db.setMeta('dashboard_layout_v1', JSON.stringify(safe));
    return safe;
  }

  resetDashboardLayout() {
    const def = DEFAULT_DASHBOARD_LAYOUT.map(x => ({ ...x }));
    this.db.setMeta('dashboard_layout_v1', JSON.stringify(def));
    return def;
  }

  getAppPreferences() {
    const palette = this.db.getMeta('color_palette');
    const lang = this.db.getMeta('language');
    return {
      colorPalette: VALID_PALETTES.includes(palette) ? palette : 'pink',
      userName: (this.db.getMeta('user_name') || 'User').trim() || 'User',
      language: lang === 'id' ? 'id' : 'en',
      showReportCharts: this.db.getMeta('show_report_charts') !== 'false',
      periodReminders: this.db.getMeta('period_reminders') === 'true',
      waterGoalGlasses: Math.max(1, parseInt(this.db.getMeta('water_goal_glasses') || '8', 10) || 8),
      weightGoalKg: this.db.getMeta('weight_goal_kg') || '',
    };
  }

  saveAppPreferences(prefs = {}) {
    if (prefs.colorPalette && VALID_PALETTES.includes(prefs.colorPalette)) {
      this.db.setMeta('color_palette', prefs.colorPalette);
    }
    if (typeof prefs.userName === 'string') {
      const clean = prefs.userName.trim().slice(0, 40);
      if (clean) {
        this.db.setMeta('user_name', clean);
        this.db.setMeta('user_name_customized', 'true');
      }
    }
    if (prefs.language === 'en' || prefs.language === 'id') {
      this.db.setMeta('language', prefs.language);
    }
    if (typeof prefs.showReportCharts === 'boolean') {
      this.db.setMeta('show_report_charts', prefs.showReportCharts ? 'true' : 'false');
    }
    if (typeof prefs.periodReminders === 'boolean') {
      this.db.setMeta('period_reminders', prefs.periodReminders ? 'true' : 'false');
    }
    if (prefs.waterGoalGlasses !== undefined) {
      const glasses = Math.max(1, Math.min(30, parseInt(prefs.waterGoalGlasses, 10) || 8));
      this.db.setMeta('water_goal_glasses', String(glasses));
    }
    if (prefs.weightGoalKg !== undefined) {
      const val = prefs.weightGoalKg === '' || prefs.weightGoalKg === null ? '' : String(Number(prefs.weightGoalKg) || '');
      this.db.setMeta('weight_goal_kg', val);
    }
    return this.getAppPreferences();
  }

  _softDeleteRow(table, id) {
    const allowed = new Set([
      'projects', 'finance_envelopes', 'finance_entries',
      'savings_goals', 'recurring_bills', 'health_entries',
      'wellness_entries', 'menstrual_entries', 'notes',
    ]);
    if (!allowed.has(table) || !id) return false;
    const now = Date.now();
    const seq = this.db.nextSeq();
    this.sqlite.prepare(`UPDATE ${table} SET is_active = 0, updated_at = ?, seq = ? WHERE id = ?`).run(now, seq, id);
    return true;
  }

  getProjects() {
    return this.sqlite.prepare('SELECT * FROM projects WHERE is_active = 1 ORDER BY is_someday ASC, updated_at DESC').all();
  }

  saveProject(p) {
    const id = p.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const progress = Math.max(0, Math.min(100, parseInt(p.progress || 0, 10) || 0));
    const status = p.status === 'done' || progress >= 100 ? 'done' : 'active';
    const isSomeday = p.is_someday ? 1 : 0;
    const isActive = p.is_active !== undefined ? p.is_active : 1;
    this.sqlite.prepare(`
      INSERT INTO projects (id, name, status, progress, is_someday, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET name = excluded.name, status = excluded.status, progress = excluded.progress, is_someday = excluded.is_someday, is_active = excluded.is_active, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, p.name || 'Project', status, progress, isSomeday, isActive, now, seq);
    return this.sqlite.prepare('SELECT * FROM projects WHERE id = ?').get(id);
  }

  saveFocusSession(fs) {
    const id = fs.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = fs.day || formatLocalDay(new Date());
    const minutes = Math.max(1, parseInt(fs.minutes || 25, 10) || 25);
    this.sqlite.prepare(`
      INSERT INTO focus_sessions (id, task_id, project_id, day, minutes, note, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET task_id = excluded.task_id, project_id = excluded.project_id, day = excluded.day, minutes = excluded.minutes, note = excluded.note, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, fs.task_id ?? null, fs.project_id ?? null, day, minutes, fs.note ?? null, now, seq);
    return this.sqlite.prepare('SELECT * FROM focus_sessions WHERE id = ?').get(id);
  }

  getEnvelopes() {
    return this.sqlite.prepare('SELECT * FROM finance_envelopes WHERE is_active = 1 ORDER BY name ASC').all();
  }

  saveEnvelope(env) {
    const id = env.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const budget = Math.max(0, parseInt(env.monthly_budget || 0, 10) || 0);
    this.sqlite.prepare(`
      INSERT INTO finance_envelopes (id, name, monthly_budget, is_active, updated_at, seq)
      VALUES (?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET name = excluded.name, monthly_budget = excluded.monthly_budget, is_active = excluded.is_active, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, env.name || 'Envelope', budget, now, seq);
    return this.sqlite.prepare('SELECT * FROM finance_envelopes WHERE id = ?').get(id);
  }

  saveFinanceEntry(entry) {
    const id = entry.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = entry.day || formatLocalDay(new Date());
    const type = entry.type === 'income' ? 'income' : 'expense';
    const category = ['general', 'savings', 'debt'].includes(entry.category) ? entry.category : 'general';
    const amount = Math.max(0, Math.round(Number(entry.amount) || 0));
    this.sqlite.prepare(`
      INSERT INTO finance_entries (id, day, type, category, amount, envelope_id, note, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET day = excluded.day, type = excluded.type, category = excluded.category, amount = excluded.amount, envelope_id = excluded.envelope_id, note = excluded.note, is_active = excluded.is_active, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, day, type, category, amount, entry.envelope_id ?? null, entry.note ?? null, now, seq);
    return this.sqlite.prepare('SELECT * FROM finance_entries WHERE id = ?').get(id);
  }

  getSavingsGoals() {
    return this.sqlite.prepare('SELECT * FROM savings_goals WHERE is_active = 1 ORDER BY updated_at DESC').all();
  }

  saveSavingsGoal(goal) {
    const id = goal.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const target = Math.max(0, Math.round(Number(goal.target_amount) || 0));
    const current = Math.max(0, Math.round(Number(goal.current_amount) || 0));
    this.sqlite.prepare(`
      INSERT INTO savings_goals (id, name, target_amount, current_amount, deadline, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET name = excluded.name, target_amount = excluded.target_amount, current_amount = excluded.current_amount, deadline = excluded.deadline, is_active = excluded.is_active, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, goal.name || 'Savings Goal', target, current, goal.deadline || null, now, seq);
    return this.sqlite.prepare('SELECT * FROM savings_goals WHERE id = ?').get(id);
  }

  getRecurringBills() {
    return this.sqlite.prepare('SELECT * FROM recurring_bills WHERE is_active = 1 ORDER BY due_day ASC, updated_at DESC').all();
  }

  saveRecurringBill(bill) {
    const id = bill.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const kind = bill.kind === 'debt' ? 'debt' : 'bill';
    const amount = Math.max(0, Math.round(Number(bill.amount) || 0));
    const dueDay = Math.max(1, Math.min(31, parseInt(bill.due_day || 1, 10) || 1));
    const isPaid = bill.is_paid ? 1 : 0;
    this.sqlite.prepare(`
      INSERT INTO recurring_bills (id, name, kind, amount, due_day, is_paid, last_paid_month, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET name = excluded.name, kind = excluded.kind, amount = excluded.amount, due_day = excluded.due_day, is_paid = excluded.is_paid, last_paid_month = excluded.last_paid_month, is_active = excluded.is_active, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, bill.name || 'Recurring', kind, amount, dueDay, isPaid, bill.last_paid_month || null, now, seq);
    return this.sqlite.prepare('SELECT * FROM recurring_bills WHERE id = ?').get(id);
  }

  saveHealthEntry(entry) {
    const id = entry.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = entry.day || formatLocalDay(new Date());
    const kind = ['food', 'weight', 'water', 'workout', 'measurement'].includes(entry.kind) ? entry.kind : 'water';
    const mealSlot = ['breakfast', 'lunch', 'dinner', 'snacks'].includes(entry.meal_slot) ? entry.meal_slot : null;
    const v1 = Number(entry.value_num) || 0;
    const v2 = entry.value_num2 !== undefined && entry.value_num2 !== null && entry.value_num2 !== '' ? Number(entry.value_num2) : null;
    this.sqlite.prepare(`
      INSERT INTO health_entries (id, day, kind, name, meal_slot, value_num, value_num2, unit, note, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET day = excluded.day, kind = excluded.kind, name = excluded.name, meal_slot = excluded.meal_slot, value_num = excluded.value_num, value_num2 = excluded.value_num2, unit = excluded.unit, note = excluded.note, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, day, kind, entry.name ?? null, mealSlot, v1, v2, entry.unit ?? null, entry.note ?? null, now, seq);
    return this.sqlite.prepare('SELECT * FROM health_entries WHERE id = ?').get(id);
  }

  saveWellnessEntry(entry) {
    const id = entry.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = entry.day || formatLocalDay(new Date());
    const clamp5 = (n, def) => Math.max(1, Math.min(5, parseInt(n || def, 10) || def));
    this.sqlite.prepare(`
      INSERT INTO wellness_entries (id, day, mood, mood_score, energy, stress, sleep_hours, triggers_text, gratitude_text, note, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET day = excluded.day, mood = excluded.mood, mood_score = excluded.mood_score, energy = excluded.energy, stress = excluded.stress, sleep_hours = excluded.sleep_hours, triggers_text = excluded.triggers_text, gratitude_text = excluded.gratitude_text, note = excluded.note, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, day, entry.mood || 'Calm', clamp5(entry.mood_score, 4), clamp5(entry.energy, 3), clamp5(entry.stress, 2), Number(entry.sleep_hours) || 7, entry.triggers_text ?? null, entry.gratitude_text ?? null, entry.note ?? null, now, seq);
    return this.sqlite.prepare('SELECT * FROM wellness_entries WHERE id = ?').get(id);
  }

  saveMenstrualEntry(entry) {
    const id = entry.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = entry.day || formatLocalDay(new Date());
    const syms = Array.isArray(entry.symptoms) ? JSON.stringify(entry.symptoms) : (entry.symptoms_json || '[]');
    this.sqlite.prepare(`
      INSERT INTO menstrual_entries (id, day, phase, cycle_day, flow, symptoms_json, is_period_start, cycle_length, note, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET day = excluded.day, phase = excluded.phase, cycle_day = excluded.cycle_day, flow = excluded.flow, symptoms_json = excluded.symptoms_json, is_period_start = excluded.is_period_start, cycle_length = excluded.cycle_length, note = excluded.note, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, day, entry.phase || 'Menstrual', parseInt(entry.cycle_day || 1, 10) || 1, entry.flow ?? null, syms, entry.is_period_start ? 1 : 0, entry.cycle_length ? parseInt(entry.cycle_length, 10) : null, entry.note ?? null, now, seq);
    return this.sqlite.prepare('SELECT * FROM menstrual_entries WHERE id = ?').get(id);
  }

  saveNote(n) {
    const id = n.id || crypto.randomUUID();
    const now = Date.now();
    const seq = this.db.nextSeq();
    const day = n.day || formatLocalDay(new Date());
    const category = ['journal', 'braindump', 'gratitude', 'quick'].includes(n.category) ? n.category : 'journal';
    const isPinned = n.is_pinned ? 1 : 0;
    const tags = Array.isArray(n.tags)
      ? JSON.stringify(n.tags.map(t => String(t).trim()).filter(Boolean))
      : (typeof n.tags_text === 'string'
        ? JSON.stringify(n.tags_text.split(',').map(t => t.trim()).filter(Boolean))
        : (n.tags_json || '[]'));
    this.sqlite.prepare(`
      INSERT INTO notes (id, day, title, body, tags_json, category, is_pinned, is_active, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET day = excluded.day, title = excluded.title, body = excluded.body, tags_json = excluded.tags_json, category = excluded.category, is_pinned = excluded.is_pinned, updated_at = excluded.updated_at, seq = excluded.seq
    `).run(id, day, n.title || 'Quick Note', n.body || '', tags, category, isPinned, now, seq);
    return this.sqlite.prepare('SELECT * FROM notes WHERE id = ?').get(id);
  }

  quickAdd(payload) {
    const kind = payload?.kind;
    const data = payload?.data || {};
    const day = data.day || formatLocalDay(new Date());
    if (kind === 'task') {
      const groups = this.getGroups(false);
      const gid = data.group_id || (groups[0] && groups[0].id) || 'seed-group-pagi';
      return this.saveTask({
        group_id: gid,
        name: data.name || 'New step',
        core: data.core ? 1 : 0,
        sort: 99,
        freq: data.freq || 'daily',
        freq_days: data.freq_days,
        priority: data.priority || 'normal',
        due_date: data.due_date || null,
      });
    }
    if (kind === 'finance') return this.saveFinanceEntry({ ...data, day });
    if (['food', 'weight', 'water', 'workout', 'measurement'].includes(kind)) {
      return this.saveHealthEntry({ ...data, kind, day });
    }
    if (kind === 'mood') return this.saveWellnessEntry({ ...data, day });
    if (kind === 'menstrual') return this.saveMenstrualEntry({ ...data, day });
    if (kind === 'note') return this.saveNote({ ...data, day });
    if (kind === 'project') return this.saveProject(data);
    if (kind === 'focus') return this.saveFocusSession({ ...data, day });
    if (kind === 'envelope') return this.saveEnvelope(data);
    if (kind === 'savings_goal') return this.saveSavingsGoal(data);
    if (kind === 'recurring_bill') return this.saveRecurringBill(data);
    throw new Error(`Unknown quickAdd kind: ${kind}`);
  }

  getDerivedAchievements(todayStr) {
    const totalChecks = this.sqlite.prepare('SELECT COUNT(*) as c FROM checks WHERE checked = 1').get().c;
    const totalClaims = this.sqlite.prepare('SELECT COUNT(*) as c FROM claims').get().c;
    const stats = this.getDashboardStats('week', todayStr || formatLocalDay(new Date()));
    const focusMin = this.sqlite.prepare('SELECT COALESCE(SUM(minutes), 0) as m FROM focus_sessions').get().m;
    return [
      { id: 'first-step', unlocked: totalChecks >= 1, progress: Math.min(1, totalChecks), target: 1 },
      { id: 'streak-7', unlocked: stats.currentStreak >= 7, progress: Math.min(7, stats.currentStreak), target: 7 },
      { id: 'checks-25', unlocked: totalChecks >= 25, progress: Math.min(25, totalChecks), target: 25 },
      { id: 'focus-60', unlocked: focusMin >= 60, progress: Math.min(60, focusMin), target: 60 },
      { id: 'self-care-1', unlocked: totalClaims >= 1, progress: Math.min(1, totalClaims), target: 1 },
    ];
  }

  exportAllDataJson() {
    const snapshot = this.getChangesSince(0);
    return {
      version: '0.3.1',
      exportedAt: Date.now(),
      prefs: this.getAppPreferences(),
      dashboardLayout: this.getDashboardLayout(),
      changes: snapshot,
    };
  }

  importAllDataJson(payload) {
    if (!payload || typeof payload !== 'object' || !payload.changes) {
      throw new Error('Invalid backup JSON format');
    }
    this.db.createBackupSnapshot(`pre-restore-${Date.now()}`);
    const accepted = this.applyChanges(payload.changes, 'import-restore');
    if (payload.prefs && typeof payload.prefs === 'object') {
      this.saveAppPreferences(payload.prefs);
    }
    if (Array.isArray(payload.dashboardLayout) && payload.dashboardLayout.length > 0) {
      this.saveDashboardLayout(payload.dashboardLayout);
    }
    const counts = {};
    for (const [k, set] of Object.entries(accepted)) {
      counts[k] = set.size;
    }
    return { ok: true, restoredCounts: counts };
  }

  getLifeOsSummary(dayStr) {
    const todayData = this.getTodayData(dayStr);
    const scheduled = todayData.groups.flatMap(g => g.tasks).filter(t => t.scheduled);
    const prodDone = scheduled.filter(t => t.done).length;
    const prodTotal = scheduled.length;
    const focusToday = this.sqlite.prepare('SELECT COALESCE(SUM(minutes), 0) as mins FROM focus_sessions WHERE day = ?').get(dayStr).mins;

    const finInc = this.sqlite.prepare("SELECT COALESCE(SUM(amount), 0) as s FROM finance_entries WHERE is_active = 1 AND type = 'income'").get().s;
    const finExp = this.sqlite.prepare("SELECT COALESCE(SUM(amount), 0) as s FROM finance_entries WHERE is_active = 1 AND type = 'expense'").get().s;
    const finCount = this.sqlite.prepare('SELECT COUNT(*) as c FROM finance_entries WHERE is_active = 1').get().c;
    const billsCount = this.sqlite.prepare('SELECT COUNT(*) as c FROM recurring_bills WHERE is_active = 1 AND is_paid = 0').get().c;
    const goalsCount = this.sqlite.prepare('SELECT COUNT(*) as c FROM savings_goals WHERE is_active = 1').get().c;

    const latestWeight = this.sqlite.prepare("SELECT value_num, value_num2, day FROM health_entries WHERE is_active = 1 AND kind = 'weight' ORDER BY day DESC, updated_at DESC LIMIT 1").get();
    const waterToday = this.sqlite.prepare("SELECT COALESCE(SUM(value_num), 0) as ml FROM health_entries WHERE is_active = 1 AND kind = 'water' AND day = ?").get(dayStr).ml;
    const kcalToday = this.sqlite.prepare("SELECT COALESCE(SUM(value_num), 0) as kcal FROM health_entries WHERE is_active = 1 AND kind = 'food' AND day = ?").get(dayStr).kcal;

    const latestWell = this.sqlite.prepare('SELECT mood, mood_score, energy, stress, sleep_hours, gratitude_text, day FROM wellness_entries WHERE is_active = 1 ORDER BY day DESC, updated_at DESC LIMIT 1').get();
    const latestMens = this.sqlite.prepare('SELECT phase, cycle_day, symptoms_json, is_period_start, cycle_length, day FROM menstrual_entries WHERE is_active = 1 ORDER BY day DESC, updated_at DESC LIMIT 1').get();
    const notesCount = this.sqlite.prepare('SELECT COUNT(*) as c FROM notes WHERE is_active = 1').get().c;
    const latestNote = this.sqlite.prepare('SELECT title, category, day FROM notes WHERE is_active = 1 ORDER BY updated_at DESC, day DESC LIMIT 1').get();
    const pinnedReminder = this.sqlite.prepare(
      "SELECT id, title, body, category, day, updated_at FROM notes WHERE is_active = 1 AND is_pinned = 1 ORDER BY (id = 'little-note-motivation') DESC, updated_at DESC LIMIT 1"
    ).get() || null;
    const activeRewards = this.sqlite.prepare('SELECT COUNT(*) as c FROM rewards WHERE is_active = 1').get().c;
    const errorAuditCount = this.sqlite.prepare("SELECT COUNT(*) as c FROM audit_logs WHERE level IN ('error','warn')").get().c;

    return {
      layout: this.getDashboardLayout(),
      prefs: this.getAppPreferences(),
      productivity: { done: prodDone, total: prodTotal, focusMinutesToday: focusToday },
      finance: { income: finInc, expense: finExp, balance: finInc - finExp, count: finCount, unpaidBills: billsCount, savingsGoalsCount: goalsCount },
      health: { latestWeight: latestWeight ? latestWeight.value_num : null, waterTodayMl: waterToday, kcalToday },
      wellness: latestWell || null,
      menstrual: latestMens ? { ...latestMens, symptoms: parseJsonArray(latestMens.symptoms_json) } : null,
      notes: { count: notesCount, latestTitle: latestNote ? latestNote.title : null, latestDay: latestNote ? latestNote.day : null, pinnedReminder },
      rewards: { balance: todayData.balance, activeCount: activeRewards },
      achievements: this.getDerivedAchievements(dayStr),
      errorAuditCount,
    };
  }

  getModuleReport({ module, range = 'week', customStart = null, customEnd = null, today }) {
    const todayStr = today || formatLocalDay(new Date());
    const { start, end } = resolveReportBounds(range, customStart, customEnd, todayStr);

    if (module === 'productivity') {
      const daysCount = Math.max(1, Math.round((parseLocalDay(end) - parseLocalDay(start)) / 86400000) + 1);
      const stats = this.getDashboardStats(range === 'month' ? 'month' : (range === 'year' ? 'all' : 'week'), end);
      const focusRows = this.sqlite.prepare('SELECT * FROM focus_sessions WHERE day >= ? AND day <= ? ORDER BY day DESC, updated_at DESC').all(start, end);
      const focusMinutes = focusRows.reduce((a, b) => a + (b.minutes || 0), 0);
      const projects = this.getProjects();
      const tasks = this.getTasks(false);
      let scheduledSlots = 0;
      let doneSlots = 0;
      const checkedRows = this.sqlite.prepare('SELECT task_id, day FROM checks WHERE checked = 1 AND day >= ? AND day <= ?').all(start, end);
      const checkedSet = new Set(checkedRows.map(r => `${r.task_id}|${r.day}`));
      for (const t of tasks) {
        const sched = countScheduledDaysInRange(t, start, end);
        scheduledSlots += sched;
        for (let i = 0; i < daysCount; i++) {
          const d = parseLocalDay(start);
          d.setDate(d.getDate() + i);
          const ds = formatLocalDay(d);
          if (checkedSet.has(`${t.id}|${ds}`)) doneSlots++;
        }
      }
      const completionRate = scheduledSlots > 0 ? Math.round((doneSlots / scheduledSlots) * 100) : stats.rate;
      return {
        module, start, end,
        completionRate, doneCount: doneSlots, scheduledCount: scheduledSlots,
        focusMinutes, focusSessions: focusRows, projects,
        taskBreakdown: stats.taskStats,
        dailyChart: stats.dailyChart,
      };
    }

    if (module === 'finance') {
      const entries = this.sqlite.prepare('SELECT * FROM finance_entries WHERE is_active = 1 AND day >= ? AND day <= ? ORDER BY day DESC, updated_at DESC').all(start, end);
      const envelopes = this.getEnvelopes();
      const savingsGoals = this.getSavingsGoals();
      const recurringBills = this.getRecurringBills();
      const income = entries.filter(e => e.type === 'income').reduce((a, b) => a + b.amount, 0);
      const expense = entries.filter(e => e.type === 'expense').reduce((a, b) => a + b.amount, 0);
      const savings = entries.filter(e => e.category === 'savings').reduce((a, b) => a + b.amount, 0);
      const debt = entries.filter(e => e.category === 'debt').reduce((a, b) => a + b.amount, 0);
      const envelopeUsage = envelopes.map(env => {
        const used = entries.filter(e => e.type === 'expense' && e.envelope_id === env.id).reduce((a, b) => a + b.amount, 0);
        const pct = env.monthly_budget > 0 ? Math.min(100, Math.round((used / env.monthly_budget) * 100)) : 0;
        return { ...env, used, pct };
      });
      return {
        module, start, end, income, expense, net: income - expense,
        savings, debt, envelopeUsage, savingsGoals, recurringBills, entries,
      };
    }

    if (module === 'health') {
      const rows = this.sqlite.prepare('SELECT * FROM health_entries WHERE is_active = 1 AND day >= ? AND day <= ? ORDER BY day DESC, updated_at DESC').all(start, end);
      const prefs = this.getAppPreferences();
      const weightHistory = rows.filter(r => r.kind === 'weight');
      const foodLogs = rows.filter(r => r.kind === 'food');
      const waterLogs = rows.filter(r => r.kind === 'water');
      const workoutLogs = rows.filter(r => r.kind === 'workout');
      const measurementLogs = rows.filter(r => r.kind === 'measurement');
      const totalCalories = Math.round(foodLogs.reduce((a, b) => a + b.value_num, 0));
      const totalWaterMl = Math.round(waterLogs.reduce((a, b) => a + b.value_num, 0));
      const totalWorkoutMin = Math.round(workoutLogs.reduce((a, b) => a + b.value_num, 0));
      const latestMeasurements = {};
      for (const m of measurementLogs) {
        const key = (m.name || 'Other').trim();
        if (!latestMeasurements[key]) latestMeasurements[key] = m;
      }
      return {
        module, start, end,
        latestWeight: weightHistory[0] ? weightHistory[0].value_num : null,
        weightGoalKg: prefs.weightGoalKg,
        waterGoalGlasses: prefs.waterGoalGlasses,
        totalCalories, totalWaterMl, totalWorkoutMin,
        weightHistory, foodLogs, waterLogs, workoutLogs, measurementLogs, latestMeasurements,
      };
    }

    if (module === 'wellness') {
      const entries = this.sqlite.prepare('SELECT * FROM wellness_entries WHERE is_active = 1 AND day >= ? AND day <= ? ORDER BY day DESC, updated_at DESC').all(start, end);
      const count = entries.length;
      const avg = (k) => count > 0 ? Number((entries.reduce((a, b) => a + Number(b[k] || 0), 0) / count).toFixed(1)) : 0;
      const triggerMap = {};
      for (const e of entries) {
        if (!e.triggers_text) continue;
        for (const raw of e.triggers_text.split(',')) {
          const t = raw.trim();
          if (t) triggerMap[t] = (triggerMap[t] || 0) + 1;
        }
      }
      const triggers = Object.entries(triggerMap).map(([name, cnt]) => ({ name, count: cnt })).sort((a, b) => b.count - a.count);
      return {
        module, start, end, count,
        avgMood: avg('mood_score'), avgEnergy: avg('energy'), avgStress: avg('stress'), avgSleep: avg('sleep_hours'),
        triggers, entries,
      };
    }

    if (module === 'menstrual') {
      const entries = this.sqlite.prepare('SELECT * FROM menstrual_entries WHERE is_active = 1 AND day >= ? AND day <= ? ORDER BY day DESC, updated_at DESC').all(start, end)
        .map(r => ({ ...r, symptoms: parseJsonArray(r.symptoms_json) }));
      const allStarts = this.sqlite.prepare('SELECT day, cycle_length FROM menstrual_entries WHERE is_active = 1 AND is_period_start = 1 ORDER BY day DESC').all();
      const lengths = entries.map(e => e.cycle_length).filter(n => typeof n === 'number' && n > 0);
      const avgCycleDuration = lengths.length ? Math.round(lengths.reduce((a, b) => a + b, 0) / lengths.length) : null;
      let nextPeriodEstimate = null;
      if (allStarts.length > 0) {
        const lastStart = parseLocalDay(allStarts[0].day);
        const estCycleDays = allStarts[0].cycle_length || avgCycleDuration || 28;
        const estNext = new Date(lastStart);
        estNext.setDate(estNext.getDate() + estCycleDays);
        const estOvulation = new Date(estNext);
        estOvulation.setDate(estOvulation.getDate() - 14);
        nextPeriodEstimate = {
          lastStartDay: allStarts[0].day,
          estimatedStartDay: formatLocalDay(estNext),
          estimatedOvulationDay: formatLocalDay(estOvulation),
          cycleLengthUsed: estCycleDays,
          isEstimate: true,
        };
      }
      const symptomMap = {};
      for (const e of entries) {
        for (const s of e.symptoms) symptomMap[s] = (symptomMap[s] || 0) + 1;
      }
      const symptomSummary = Object.entries(symptomMap).map(([name, cnt]) => ({ name, count: cnt })).sort((a, b) => b.count - a.count);
      return {
        module, start, end, count: entries.length,
        avgCycleDuration, periodCount: entries.filter(e => e.is_period_start === 1).length,
        latestPhase: entries[0] ? entries[0].phase : null,
        nextPeriodEstimate,
        symptomSummary, entries,
      };
    }

    // notes (newest saved first)
    const entries = this.sqlite.prepare('SELECT * FROM notes WHERE is_active = 1 AND day >= ? AND day <= ? ORDER BY updated_at DESC, day DESC').all(start, end)
      .map(n => ({ ...n, tags: parseJsonArray(n.tags_json) }));
    const tagMap = {};
    let totalWords = 0;
    for (const n of entries) {
      totalWords += n.body ? n.body.trim().split(/\s+/).filter(Boolean).length : 0;
      for (const t of n.tags) tagMap[t] = (tagMap[t] || 0) + 1;
    }
    const tags = Object.entries(tagMap).map(([name, cnt]) => ({ name, count: cnt })).sort((a, b) => b.count - a.count);
    return { module: 'notes', start, end, count: entries.length, totalWords, uniqueTags: tags.length, tags, entries };
  }

  // --- AUDIT LOG (LOCAL-ONLY API & SYNC DIAGNOSTICS) ---
  logAudit({ source = 'Desktop', category = 'sync', level = 'error', endpoint = '', statusCode = null, errorCode = '', message = '', details = null }) {
    const id = crypto.randomUUID();
    const now = Date.now();
    const day = formatLocalDay(new Date(now));
    const safeDetails = details !== null && details !== undefined ? JSON.stringify(sanitizeAuditDetails(details)) : null;
    const safeMsg = sanitizeAuditDetails(String(message || 'Unknown error'));
    this.sqlite.prepare(`
      INSERT INTO audit_logs (id, created_at, day, source, category, level, endpoint, status_code, error_code, message, details_json)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(id, now, day, source, category, level, endpoint, statusCode, errorCode || null, safeMsg, safeDetails);

    // Retention: prune >30 days and keep newest 500
    const cutoff = now - 30 * 24 * 60 * 60 * 1000;
    this.sqlite.prepare('DELETE FROM audit_logs WHERE created_at < ?').run(cutoff);
    this.sqlite.prepare('DELETE FROM audit_logs WHERE id NOT IN (SELECT id FROM audit_logs ORDER BY created_at DESC LIMIT 500)').run();
    return id;
  }

  getAuditLogs({ category = 'all', source = 'all', range = 'week', customStart = null, customEnd = null, today = null } = {}) {
    const todayStr = today || formatLocalDay(new Date());
    const { start, end } = resolveReportBounds(range, customStart, customEnd, todayStr);
    let rows = this.sqlite.prepare('SELECT * FROM audit_logs WHERE day >= ? AND day <= ? ORDER BY created_at DESC').all(start, end);
    if (category && category !== 'all') {
      if (category === 'sync') rows = rows.filter(r => (r.category === 'sync' || r.category === 'discovery') && r.level === 'error');
      else if (category === 'auth') rows = rows.filter(r => r.category === 'auth' || r.status_code === 401);
      else if (category === 'info') rows = rows.filter(r => r.level === 'info');
      else rows = rows.filter(r => r.category === category);
    }
    if (source && source !== 'all') {
      rows = rows.filter(r => r.source.toLowerCase().includes(source.toLowerCase()));
    }
    return rows.map(r => {
      let details = null;
      if (r.details_json) {
        try { details = JSON.parse(r.details_json); } catch (_) { details = r.details_json; }
      }
      return { ...r, details };
    });
  }

  clearAuditLogs() {
    this.sqlite.exec('DELETE FROM audit_logs');
    return true;
  }
}

module.exports = { Repository };
