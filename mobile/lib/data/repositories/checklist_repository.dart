import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/models.dart';

String formatLocalDay(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseLocalDay(String dayStr) {
  final parts = dayStr.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

int countScheduledDaysInRange(TaskItem task, String startStr, String endStr) {
  final start = parseLocalDay(startStr);
  final end = parseLocalDay(endStr);
  if (task.freq == 'daily') {
    return max(1, end.difference(start).inDays + 1);
  }
  int c = 0;
  DateTime d = start;
  while (!d.isAfter(end)) {
    if (task.isScheduledOnDate(d)) c++;
    d = d.add(const Duration(days: 1));
  }
  return c;
}

const _lifeOsSyncTables = [
  'projects',
  'focus_sessions',
  'finance_envelopes',
  'finance_entries',
  'savings_goals',
  'recurring_bills',
  'health_entries',
  'wellness_entries',
  'menstrual_entries',
  'notes',
];

const _validPalettes = ['pink', 'sage', 'teal', 'lavender', 'peach'];

final _sensitiveAuditKeyRe =
    RegExp(r'^(authorization|token|paired_token|code|pairing_code|secret)$', caseSensitive: false);
final _bearerRe = RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false);

dynamic _sanitizeAuditValue(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map(_sanitizeAuditValue).toList();
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      final keyStr = k.toString();
      out[keyStr] = _sensitiveAuditKeyRe.hasMatch(keyStr) ? '[REDACTED]' : _sanitizeAuditValue(v);
    });
    return out;
  }
  if (value is String) {
    return value.replaceAll(_bearerRe, 'Bearer [REDACTED]');
  }
  return value;
}

class ChecklistRepository {
  final DatabaseHelper dbHelper;

  ChecklistRepository({required this.dbHelper});

  Future<Database> get _db async => await dbHelper.database;

  // --- GROUPS ---
  Future<List<GroupItem>> getGroups({bool includeInactive = false}) async {
    final db = await _db;
    final rows = await db.query(
      'groups',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'sort ASC, rowid ASC',
    );
    return rows.map((r) => GroupItem.fromMap(r)).toList();
  }

  Future<GroupItem> saveGroup(GroupItem group) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = group.id.isEmpty ? const Uuid().v4() : group.id;

    final existing = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      await db.update(
        'groups',
        {
          'name': group.name,
          'sort': group.sort,
          'is_active': group.isActive ? 1 : 0,
          'deactivated_at': group.deactivatedAt,
          'updated_at': now,
          'dirty': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('groups', {
        'id': id,
        'name': group.name,
        'sort': group.sort,
        'is_active': group.isActive ? 1 : 0,
        'deactivated_at': group.deactivatedAt,
        'updated_at': now,
        'dirty': 1,
      });
    }

    final res = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    return GroupItem.fromMap(res.first);
  }

  Future<void> moveGroup(String id, int delta) async {
    final db = await _db;
    final groups = await getGroups(includeInactive: false);
    final idx = groups.indexWhere((g) => g.id == id);
    final targetIdx = idx + delta;
    if (idx < 0 || targetIdx < 0 || targetIdx >= groups.length) return;

    final reordered = List<GroupItem>.from(groups);
    final swapped = reordered[idx];
    reordered[idx] = reordered[targetIdx];
    reordered[targetIdx] = swapped;

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (var i = 0; i < reordered.length; i++) {
        if (reordered[i].sort != i || i == idx || i == targetIdx) {
          await txn.update(
            'groups',
            {'sort': i, 'updated_at': now, 'dirty': 1},
            where: 'id = ?',
            whereArgs: [reordered[i].id],
          );
        }
      }
    });
  }

  Future<void> deactivateGroup(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'groups',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      'tasks',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now, 'dirty': 1},
      where: 'group_id = ? AND is_active = 1',
      whereArgs: [id],
    );
  }

  Future<void> reactivateGroup(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'groups',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      'tasks',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now, 'dirty': 1},
      where: 'group_id = ? AND is_active = 0',
      whereArgs: [id],
    );
  }

  // --- TASKS ---
  Future<List<TaskItem>> getTasks({bool includeInactive = false}) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'sort ASC, rowid ASC',
    );
    return rows.map((r) => TaskItem.fromMap(r)).toList();
  }

  Future<TaskItem> saveTask(TaskItem task) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = task.id.isEmpty ? const Uuid().v4() : task.id;
    final freq = (task.freq == 'weekly' || task.freq == 'monthly') ? task.freq : 'daily';
    final freqDaysStr = (freq == 'weekly' || freq == 'monthly')
        ? json.encode((task.freqDays.toSet().toList()..sort()))
        : null;
    final priority = (task.priority == 'low' || task.priority == 'high') ? task.priority : 'normal';
    final dueDate = (task.dueDate != null && task.dueDate!.isNotEmpty) ? task.dueDate!.substring(0, min(10, task.dueDate!.length)) : null;

    final existing = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      await db.update(
        'tasks',
        {
          'group_id': task.groupId,
          'name': task.name,
          'core': task.core ? 1 : 0,
          'sort': task.sort,
          'freq': freq,
          'freq_days': freqDaysStr,
          'priority': priority,
          'due_date': dueDate,
          'is_active': task.isActive ? 1 : 0,
          'deactivated_at': task.deactivatedAt,
          'updated_at': now,
          'dirty': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('tasks', {
        'id': id,
        'group_id': task.groupId,
        'name': task.name,
        'core': task.core ? 1 : 0,
        'sort': task.sort,
        'freq': freq,
        'freq_days': freqDaysStr,
        'priority': priority,
        'due_date': dueDate,
        'is_active': task.isActive ? 1 : 0,
        'deactivated_at': task.deactivatedAt,
        'updated_at': now,
        'dirty': 1,
      });
    }

    final res = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return TaskItem.fromMap(res.first);
  }

  Future<void> deactivateTask(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'tasks',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reactivateTask(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'tasks',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, Map<String, dynamic>>> _readDeletedTaskTombstones() async {
    final raw = await getMeta('deleted_task_tombstones_v1');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeDeletedTaskTombstones(Map<String, Map<String, dynamic>> tombs) async {
    final sorted = tombs.entries.toList()
      ..sort((a, b) => ((b.value['deleted_at'] as num?) ?? 0).compareTo((a.value['deleted_at'] as num?) ?? 0));
    final bounded = Map<String, Map<String, dynamic>>.fromEntries(sorted.take(500));
    await setMeta('deleted_task_tombstones_v1', json.encode(bounded));
  }

  Future<bool> deleteTaskPermanently(String id) async {
    if (id.isEmpty) return false;
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final tombs = await _readDeletedTaskTombstones();
    tombs[id] = {'deleted_at': now, 'dirty': 1};
    await _writeDeletedTaskTombstones(tombs);
    await db.delete('checks', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // --- CHECKS ---
  Future<Map<String, CheckItem>> getChecksForDay(String day) async {
    final db = await _db;
    final rows = await db.query('checks', where: 'day = ? AND checked = 1', whereArgs: [day]);
    final map = <String, CheckItem>{};
    for (final r in rows) {
      final c = CheckItem.fromMap(r);
      map[c.taskId] = c;
    }
    return map;
  }

  Future<void> toggleCheck(String taskId, String day, bool checked) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'checks',
      where: 'task_id = ? AND day = ?',
      whereArgs: [taskId, day],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'checks',
        {'checked': checked ? 1 : 0, 'updated_at': now, 'dirty': 1},
        where: 'task_id = ? AND day = ?',
        whereArgs: [taskId, day],
      );
    } else {
      await db.insert('checks', {
        'task_id': taskId,
        'day': day,
        'checked': checked ? 1 : 0,
        'updated_at': now,
        'dirty': 1,
      });
    }
  }

  // --- REWARDS ---
  Future<List<RewardItem>> getRewards({bool includeInactive = false}) async {
    final db = await _db;
    final rows = await db.query(
      'rewards',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'sort ASC, rowid ASC',
    );
    return rows.map((r) => RewardItem.fromMap(r)).toList();
  }

  Future<RewardItem> saveReward(RewardItem reward) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = reward.id.isEmpty ? const Uuid().v4() : reward.id;
    final cost = reward.cost.clamp(1, 999);

    final existing = await db.query('rewards', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      await db.update(
        'rewards',
        {
          'name': reward.name,
          'cost': cost,
          'sort': reward.sort,
          'is_active': reward.isActive ? 1 : 0,
          'deactivated_at': reward.deactivatedAt,
          'updated_at': now,
          'dirty': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('rewards', {
        'id': id,
        'name': reward.name,
        'cost': cost,
        'sort': reward.sort,
        'is_active': reward.isActive ? 1 : 0,
        'deactivated_at': reward.deactivatedAt,
        'updated_at': now,
        'dirty': 1,
      });
    }

    final res = await db.query('rewards', where: 'id = ?', whereArgs: [id]);
    return RewardItem.fromMap(res.first);
  }

  Future<void> deactivateReward(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'rewards',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reactivateReward(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'rewards',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CLAIMS ---
  Future<ClaimItem> claimReward(String rewardId, String day) async {
    final db = await _db;
    final rRows = await db.query('rewards', where: 'id = ?', whereArgs: [rewardId]);
    if (rRows.isEmpty) throw Exception('Reward not found');

    final reward = RewardItem.fromMap(rRows.first);
    final bal = await getPointsBalance();
    if (bal < reward.cost) throw Exception('Not enough points');

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();

    final claim = ClaimItem(
      id: id,
      rewardId: reward.id,
      name: reward.name,
      cost: reward.cost,
      day: day,
      claimedAt: now,
      updatedAt: now,
    );

    await db.insert('claims', {
      ...claim.toMap(),
      'dirty': 1,
    });

    return claim;
  }

  Future<bool> undoClaim(String claimId) async {
    final db = await _db;
    final rows = await db.query('claims', where: 'id = ?', whereArgs: [claimId]);
    if (rows.isEmpty) return false;
    final claim = rows.first;
    final lastSyncStr = await getMeta('last_sync_time');
    final lastSync = int.tryParse(lastSyncStr ?? '0') ?? 0;
    final updatedAt = (claim['updated_at'] as num?)?.toInt() ?? 0;
    if (lastSync >= updatedAt && (claim['dirty'] as num?)?.toInt() == 0) {
      return false;
    }
    await db.delete('claims', where: 'id = ?', whereArgs: [claimId]);
    return true;
  }

  Future<List<ClaimItem>> getClaims() async {
    final db = await _db;
    final rows = await db.query('claims', orderBy: 'claimed_at DESC');
    return rows.map((r) => ClaimItem.fromMap(r)).toList();
  }

  Future<int> getPointsBalance() async {
    final db = await _db;
    final earnedRes = await db.rawQuery('SELECT COUNT(*) as count FROM checks WHERE checked = 1');
    final spentRes = await db.rawQuery('SELECT COALESCE(SUM(cost), 0) as count FROM claims');

    final earned = (earnedRes.first['count'] as num?)?.toInt() ?? 0;
    final spent = (spentRes.first['count'] as num?)?.toInt() ?? 0;
    return max(0, earned - spent);
  }

  // --- COMBINED TODAY VIEW ---
  Future<List<GroupItem>> getTodayData(String day) async {
    final groups = await getGroups(includeInactive: false);
    final tasks = await getTasks(includeInactive: false);
    final checks = await getChecksForDay(day);
    final dateObj = parseLocalDay(day);

    return groups.map((g) {
      final gTasks = tasks.where((t) => t.groupId == g.id).map((t) {
        return t.copyWith(
          done: checks.containsKey(t.id),
          scheduled: t.isScheduledOnDate(dateObj),
        );
      }).toList();
      return g.copyWith(tasks: gTasks);
    }).toList();
  }

  Future<Map<String, ({bool hasWeekly, bool hasMonthly})>> getMonthScheduleDots(int year, int month) async {
    final tasks = await getTasks(includeInactive: false);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dots = <String, ({bool hasWeekly, bool hasMonthly})>{};
    for (int d = 1; d <= daysInMonth; d++) {
      final dateObj = DateTime(year, month, d);
      final dayStr = formatLocalDay(dateObj);
      bool hasWeekly = false;
      bool hasMonthly = false;
      for (final t in tasks) {
        if (t.freq == 'weekly' && t.isScheduledOnDate(dateObj)) hasWeekly = true;
        if (t.freq == 'monthly' && t.isScheduledOnDate(dateObj)) hasMonthly = true;
      }
      if (hasWeekly || hasMonthly) {
        dots[dayStr] = (hasWeekly: hasWeekly, hasMonthly: hasMonthly);
      }
    }
    return dots;
  }

  // --- INACTIVE DATA ---
  Future<({List<InactiveTaskInfo> tasks, List<InactiveGroupInfo> groups})> getInactiveItems() async {
    final db = await _db;
    final tasksRes = await db.rawQuery('''
      SELECT t.id, t.name, t.deactivated_at, g.name as group_name,
        (SELECT COUNT(*) FROM checks c WHERE c.task_id = t.id AND c.checked = 1) as completed_count
      FROM tasks t
      LEFT JOIN groups g ON t.group_id = g.id
      WHERE t.is_active = 0
      ORDER BY t.deactivated_at DESC
    ''');

    final groupsRes = await db.rawQuery('''
      SELECT g.id, g.name, g.deactivated_at,
        (SELECT COUNT(*) FROM tasks t WHERE t.group_id = g.id) as task_count
      FROM groups g
      WHERE g.is_active = 0
      ORDER BY g.deactivated_at DESC
    ''');

    return (
      tasks: tasksRes
          .map((r) => InactiveTaskInfo(
                id: r['id'] as String,
                name: r['name'] as String,
                groupName: (r['group_name'] as String?) ?? 'Lainnya',
                deactivatedAt: (r['deactivated_at'] as num?)?.toInt(),
                completedCount: (r['completed_count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      groups: groupsRes
          .map((r) => InactiveGroupInfo(
                id: r['id'] as String,
                name: r['name'] as String,
                deactivatedAt: (r['deactivated_at'] as num?)?.toInt(),
                taskCount: (r['task_count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
    );
  }

  // --- ANALYTICS / DASHBOARD ---
  Future<DashboardStats> getDashboardStats(String period, String today) async {
    final db = await _db;
    final refDate = parseLocalDay(today);
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    String startDateStr;
    String label;
    int daysCount;

    if (period == 'week') {
      final start = refDate.subtract(const Duration(days: 6));
      startDateStr = formatLocalDay(start);
      label = '7 hari terakhir';
      daysCount = 7;
    } else if (period == 'month') {
      final start = DateTime(refDate.year, refDate.month, 1);
      startDateStr = formatLocalDay(start);
      label = '1–${refDate.day} ${months[refDate.month - 1]}';
      daysCount = refDate.day;
    } else {
      final earliestRes = await db.rawQuery('SELECT MIN(day) as minDay FROM checks');
      final earliest = earliestRes.first['minDay'] as String? ?? today;
      startDateStr = earliest;
      final start = parseLocalDay(earliest);
      daysCount = max(1, refDate.difference(start).inDays + 1);
      label = 'Sejak $earliest';
    }

    final checksInRange = await db.rawQuery('''
      SELECT day, COUNT(*) as done
      FROM checks
      WHERE day >= ? AND day <= ? AND checked = 1
      GROUP BY day
    ''', [startDateStr, today]);

    final checksMap = <String, int>{};
    for (final c in checksInRange) {
      checksMap[c['day'] as String] = (c['done'] as num).toInt();
    }

    final activeDays = checksInRange.where((c) => (c['done'] as num).toInt() > 0).length;
    final totalDone = checksInRange.fold<int>(0, (sum, c) => sum + (c['done'] as num).toInt());

    int currentStreak = 0;
    DateTime cur = refDate;
    for (int guard = 0; guard < 3650; guard++) {
      final dStr = formatLocalDay(cur);
      final countRes = await db.rawQuery(
        'SELECT COUNT(*) as count FROM checks WHERE day = ? AND checked = 1',
        [dStr],
      );
      final count = (countRes.first['count'] as num?)?.toInt() ?? 0;
      if (count > 0) {
        currentStreak++;
        cur = cur.subtract(const Duration(days: 1));
      } else if (dStr == today && currentStreak == 0) {
        cur = cur.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    int countScheduledDays(TaskItem task, String startStr, String endStr) =>
        countScheduledDaysInRange(task, startStr, endStr);

    final activeTasks = await getTasks(includeInactive: false);
    final maxPossible = activeTasks.fold<int>(0, (sum, t) => sum + countScheduledDays(t, startDateStr, today));
    final rate = maxPossible > 0 ? min(100, ((totalDone / maxPossible) * 100).round()) : 0;

    const dowNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dailyChart = <DashboardDayBar>[];
    for (int i = 6; i >= 0; i--) {
      final d = refDate.subtract(Duration(days: i));
      final dStr = formatLocalDay(d);
      final count = checksMap[dStr] ?? 0;
      dailyChart.add(DashboardDayBar(
        day: dStr,
        dow: i == 0 ? 'Hari ini' : dowNames[d.weekday - 1],
        count: count,
        isToday: i == 0,
      ));
    }

    final groups = await db.query('groups', where: 'is_active = 1', orderBy: 'sort ASC');
    final groupStats = <DashboardGroupStat>[];
    for (final g in groups) {
      final gId = g['id'] as String;
      final gActiveTasks = activeTasks.where((t) => t.groupId == gId).toList();
      final gDoneRes = await db.rawQuery('''
        SELECT COUNT(*) as c FROM checks c
        JOIN tasks t ON c.task_id = t.id
        WHERE t.group_id = ? AND c.day >= ? AND c.day <= ? AND c.checked = 1
      ''', [gId, startDateStr, today]);
      final gDone = (gDoneRes.first['c'] as num?)?.toInt() ?? 0;
      final possible = gActiveTasks.fold<int>(0, (sum, t) => sum + countScheduledDays(t, startDateStr, today));
      final gRate = possible > 0 ? min(100, ((gDone / possible) * 100).round()) : 0;
      groupStats.add(DashboardGroupStat(
        id: gId,
        name: g['name'] as String,
        rate: gRate,
        done: gDone,
        possible: possible,
      ));
    }

    final allTaskRows = await db.query('tasks');
    final taskStats = <DashboardTaskStat>[];
    for (final tRow in allTaskRows) {
      final t = TaskItem.fromMap(tRow);
      final tDoneRes = await db.rawQuery('''
        SELECT COUNT(*) as c FROM checks
        WHERE day >= ? AND day <= ? AND checked = 1 AND task_id = ?
      ''', [startDateStr, today, t.id]);
      final tDone = (tDoneRes.first['c'] as num?)?.toInt() ?? 0;
      if (!t.isActive && tDone == 0) continue;
      final schedDays = max(tDone, countScheduledDays(t, startDateStr, today));
      taskStats.add(DashboardTaskStat(
        id: t.id,
        name: t.name,
        freq: t.freq,
        freqDays: t.freqDays,
        isActive: t.isActive,
        deactivatedAt: t.deactivatedAt,
        done: tDone,
        totalDays: schedDays,
        rate: schedDays > 0 ? min(100, ((tDone / schedDays) * 100).round()) : 0,
      ));
    }
    taskStats.sort((a, b) => b.done.compareTo(a.done));

    return DashboardStats(
      period: period,
      label: label,
      rate: rate,
      totalDone: totalDone,
      activeDays: activeDays,
      daysCount: daysCount,
      currentStreak: currentStreak,
      pointsEarned: totalDone,
      dailyChart: dailyChart,
      groupStats: groupStats,
      taskStats: taskStats,
    );
  }

  // --- DAY LOG ---
  Future<DayLog> getDayLog(String day) async {
    final db = await _db;
    final checks = await db.query('checks', where: 'day = ?', whereArgs: [day]);
    final checksMap = {for (var c in checks) c['task_id'] as String: c};

    final groups = await db.query('groups', orderBy: 'sort ASC');
    final tasks = await db.query('tasks', orderBy: 'sort ASC');

    int totalTasks = 0;
    int completedTasks = 0;

    final groupLogs = <DayLogGroup>[];
    final refDate = parseLocalDay(day);
    final dayEndMs = DateTime(refDate.year, refDate.month, refDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    for (final g in groups) {
      final gId = g['id'] as String;
      final gTasks = tasks.where((t) {
        if (t['group_id'] != gId) return false;
        if (checksMap.containsKey(t['id'])) return true;
        final deact = (t['deactivated_at'] as num?)?.toInt();
        final wasActive = (t['is_active'] as num).toInt() == 1 || (deact != null && deact > dayEndMs);
        if (!wasActive) return false;
        return TaskItem.fromMap(t).isScheduledOnDate(refDate);
      }).toList();

      if (gTasks.isEmpty) continue;

      final taskLogs = <DayLogTask>[];
      for (final t in gTasks) {
        totalTasks++;
        final tId = t['id'] as String;
        final chk = checksMap[tId];
        final isDone = chk != null && (chk['checked'] as num).toInt() == 1;
        if (isDone) completedTasks++;

        String timeStr = 'terlewat';
        if (isDone && chk['updated_at'] != null) {
          final d = DateTime.fromMillisecondsSinceEpoch((chk['updated_at'] as num).toInt());
          timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        }

        taskLogs.add(DayLogTask(
          id: tId,
          name: t['name'] as String,
          isActive: (t['is_active'] as num).toInt() == 1,
          deactivatedAt: (t['deactivated_at'] as num?)?.toInt(),
          done: isDone,
          time: timeStr,
        ));
      }

      groupLogs.add(DayLogGroup(
        id: gId,
        name: g['name'] as String,
        doneCount: taskLogs.where((t) => t.done).length,
        totalCount: taskLogs.length,
        tasks: taskLogs,
      ));
    }

    final rate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
    return DayLog(
      day: day,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      rate: rate,
      groups: groupLogs,
    );
  }

  // --- MONTH ACTIVITY HEATMAP ---
  Future<Map<String, int>> getMonthActivity(int year, int month) async {
    final db = await _db;
    final mStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$mStr';

    final rows = await db.rawQuery('''
      SELECT day, COUNT(*) as count
      FROM checks
      WHERE day LIKE ? AND checked = 1
      GROUP BY day
    ''', ['$prefix%']);

    final activity = <String, int>{};
    for (final r in rows) {
      final count = (r['count'] as num).toInt();
      int level = 1;
      if (count >= 8) {
        level = 3;
      } else if (count >= 4) {
        level = 2;
      }
      activity[r['day'] as String] = level;
    }
    return activity;
  }

  // --- SYNC EXPORT & IMPORT ---
  Future<Map<String, dynamic>> getDirtyChanges() async {
    final db = await _db;
    final groups = await db.query('groups', where: 'dirty = 1');
    final tasks = await db.query('tasks', where: 'dirty = 1');
    final rewards = await db.query('rewards', where: 'dirty = 1');
    final checks = await db.query('checks', where: 'dirty = 1');
    final claims = await db.query('claims', where: 'dirty = 1');

    final out = <String, dynamic>{
      'groups': groups.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'tasks': tasks.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'rewards': rewards.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'checks': checks.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'claims': claims.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
    };
    for (final tbl in _lifeOsSyncTables) {
      final rows = await db.query(tbl, where: 'dirty = 1');
      out[tbl] = rows.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList();
    }
    final tombs = await _readDeletedTaskTombstones();
    final dirtyTombs = tombs.entries
        .where((e) => (e.value['dirty'] as num?)?.toInt() == 1)
        .map((e) => {'id': e.key, 'deleted_at': (e.value['deleted_at'] as num?)?.toInt() ?? 0})
        .toList();
    if (dirtyTombs.isNotEmpty) {
      out['deleted_tasks'] = dirtyTombs;
    }
    return out;
  }

  Future<void> clearDirtyFlags(Map<String, dynamic> sentChanges) async {
    final db = await _db;
    final batch = db.batch();

    for (final g in sentChanges['groups'] ?? []) {
      batch.update('groups', {'dirty': 0}, where: 'id = ? AND updated_at <= ?', whereArgs: [g['id'], g['updated_at']]);
    }
    for (final t in sentChanges['tasks'] ?? []) {
      batch.update('tasks', {'dirty': 0}, where: 'id = ? AND updated_at <= ?', whereArgs: [t['id'], t['updated_at']]);
    }
    for (final r in sentChanges['rewards'] ?? []) {
      batch.update('rewards', {'dirty': 0}, where: 'id = ? AND updated_at <= ?', whereArgs: [r['id'], r['updated_at']]);
    }
    for (final c in sentChanges['checks'] ?? []) {
      batch.update('checks', {'dirty': 0}, where: 'task_id = ? AND day = ? AND updated_at <= ?', whereArgs: [c['task_id'], c['day'], c['updated_at']]);
    }
    for (final cl in sentChanges['claims'] ?? []) {
      batch.update('claims', {'dirty': 0}, where: 'id = ? AND updated_at <= ?', whereArgs: [cl['id'], cl['updated_at']]);
    }
    for (final tbl in _lifeOsSyncTables) {
      for (final row in sentChanges[tbl] ?? []) {
        batch.update(tbl, {'dirty': 0}, where: 'id = ? AND updated_at <= ?', whereArgs: [row['id'], row['updated_at']]);
      }
    }

    await batch.commit(noResult: true);

    final sentTombs = sentChanges['deleted_tasks'] as List? ?? [];
    if (sentTombs.isNotEmpty) {
      final tombs = await _readDeletedTaskTombstones();
      bool changed = false;
      for (final d in sentTombs) {
        final id = d['id'] as String?;
        final ts = (d['deleted_at'] as num?)?.toInt() ?? 0;
        if (id != null && tombs.containsKey(id)) {
          final curTs = (tombs[id]!['deleted_at'] as num?)?.toInt() ?? 0;
          if (curTs <= ts) {
            tombs[id]!['dirty'] = 0;
            changed = true;
          }
        }
      }
      if (changed) await _writeDeletedTaskTombstones(tombs);
    }
  }

  Future<void> applyIncomingChanges(Map<String, dynamic> changes, String serverDeviceId) async {
    final db = await _db;
    final myDeviceId = await getMeta('device_id') ?? '';
    final tombs = await _readDeletedTaskTombstones();
    bool tombsChanged = false;

    for (final d in (changes['deleted_tasks'] as List? ?? [])) {
      final id = d['id'] as String?;
      if (id == null) continue;
      final delAt = (d['deleted_at'] as num?)?.toInt() ?? 0;
      final existing = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
      if (existing.isEmpty || delAt >= ((existing.first['updated_at'] as num?)?.toInt() ?? 0)) {
        await db.delete('checks', where: 'task_id = ?', whereArgs: [id]);
        await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
        final prevTs = (tombs[id]?['deleted_at'] as num?)?.toInt() ?? 0;
        tombs[id] = {'deleted_at': max(prevTs, delAt), 'dirty': 0};
        tombsChanged = true;
      }
    }

    bool shouldOverwrite(int incUpdatedAt, int existUpdatedAt) {
      if (incUpdatedAt > existUpdatedAt) return true;
      if (incUpdatedAt < existUpdatedAt) return false;
      return serverDeviceId.compareTo(myDeviceId) > 0;
    }

    for (final g in (changes['groups'] as List? ?? [])) {
      final existing = await db.query('groups', where: 'id = ?', whereArgs: [g['id']]);
      if (existing.isEmpty || shouldOverwrite((g['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
        await db.insert('groups', {
          'id': g['id'],
          'name': g['name'],
          'sort': g['sort'] ?? 0,
          'is_active': g['is_active'],
          'deactivated_at': g['deactivated_at'],
          'updated_at': g['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    for (final t in (changes['tasks'] as List? ?? [])) {
      final tId = t['id'] as String?;
      final tUpd = (t['updated_at'] as num?)?.toInt() ?? 0;
      if (tId != null && tombs.containsKey(tId)) {
        final delTs = (tombs[tId]!['deleted_at'] as num?)?.toInt() ?? 0;
        if (delTs >= tUpd) continue;
        tombs.remove(tId);
        tombsChanged = true;
      }
      final existing = await db.query('tasks', where: 'id = ?', whereArgs: [t['id']]);
      if (existing.isEmpty || shouldOverwrite((t['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
        final freqRaw = t['freq'] as String?;
        final freq = (freqRaw == 'weekly' || freqRaw == 'monthly') ? freqRaw! : 'daily';
        String? freqDaysStr;
        if (freq == 'weekly' || freq == 'monthly') {
          final parsed = parseFreqDays(t['freq_days']);
          freqDaysStr = json.encode(parsed);
        }
        await db.insert('tasks', {
          'id': t['id'],
          'group_id': t['group_id'],
          'name': t['name'],
          'core': t['core'] ?? 0,
          'sort': t['sort'] ?? 0,
          'freq': freq,
          'freq_days': freqDaysStr,
          'priority': (t['priority'] == 'low' || t['priority'] == 'high') ? t['priority'] : 'normal',
          'due_date': t['due_date'],
          'is_active': t['is_active'],
          'deactivated_at': t['deactivated_at'],
          'updated_at': t['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    if (tombsChanged) await _writeDeletedTaskTombstones(tombs);

    for (final r in (changes['rewards'] as List? ?? [])) {
      final existing = await db.query('rewards', where: 'id = ?', whereArgs: [r['id']]);
      if (existing.isEmpty || shouldOverwrite((r['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
        await db.insert('rewards', {
          'id': r['id'],
          'name': r['name'],
          'cost': r['cost'],
          'sort': r['sort'] ?? 0,
          'is_active': r['is_active'],
          'deactivated_at': r['deactivated_at'],
          'updated_at': r['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    for (final c in (changes['checks'] as List? ?? [])) {
      final existing = await db.query('checks', where: 'task_id = ? AND day = ?', whereArgs: [c['task_id'], c['day']]);
      if (existing.isEmpty || shouldOverwrite((c['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
        await db.insert('checks', {
          'task_id': c['task_id'],
          'day': c['day'],
          'checked': c['checked'],
          'updated_at': c['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    for (final cl in (changes['claims'] as List? ?? [])) {
      final existing = await db.query('claims', where: 'id = ?', whereArgs: [cl['id']]);
      if (existing.isEmpty || shouldOverwrite((cl['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
        await db.insert('claims', {
          'id': cl['id'],
          'reward_id': cl['reward_id'],
          'name': cl['name'],
          'cost': cl['cost'],
          'day': cl['day'],
          'claimed_at': cl['claimed_at'],
          'updated_at': cl['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    for (final tbl in _lifeOsSyncTables) {
      for (final row in (changes[tbl] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = m['id'] as String?;
        if (id == null) continue;
        if (tbl == 'projects') {
          m['is_someday'] ??= 0;
        } else if (tbl == 'notes') {
          m['category'] ??= 'journal';
          m['is_pinned'] ??= 0;
        }
        final existing = await db.query(tbl, where: 'id = ?', whereArgs: [id]);
        if (existing.isEmpty ||
            shouldOverwrite((m['updated_at'] as num).toInt(), (existing.first['updated_at'] as num).toInt())) {
          m['dirty'] = 0;
          await db.insert(tbl, m, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }

  // --- PERSONAL LIFE OS: LAYOUT, QUICK ADD, REPORTS & AUDIT LOG ---
  Future<List<DashboardWidgetConfig>> getDashboardLayout() async {
    final raw = await getMeta('dashboard_layout_v1');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw) as List;
        if (decoded.isNotEmpty) {
          return decoded.map((e) => DashboardWidgetConfig.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      } catch (_) {}
    }
    return List<DashboardWidgetConfig>.from(defaultDashboardLayout);
  }

  Future<List<DashboardWidgetConfig>> saveDashboardLayout(List<DashboardWidgetConfig> layout) async {
    await setMeta('dashboard_layout_v1', json.encode(layout.map((w) => w.toJson()).toList()));
    return layout;
  }

  Future<List<DashboardWidgetConfig>> resetDashboardLayout() async {
    final def = List<DashboardWidgetConfig>.from(defaultDashboardLayout);
    await saveDashboardLayout(def);
    return def;
  }

  Future<AppPreferences> getAppPreferences() async {
    final palette = await getMeta('color_palette');
    final userName = (await getMeta('user_name') ?? 'User').trim();
    final lang = await getMeta('language');
    final showCharts = await getMeta('show_report_charts');
    final periodRem = await getMeta('period_reminders');
    final waterGoal = int.tryParse(await getMeta('water_goal_glasses') ?? '8') ?? 8;
    final weightGoal = await getMeta('weight_goal_kg') ?? '';
    return AppPreferences(
      colorPalette: _validPalettes.contains(palette) ? palette! : 'pink',
      userName: userName.isNotEmpty ? userName : 'User',
      language: lang == 'id' ? 'id' : 'en',
      showReportCharts: showCharts != 'false',
      periodReminders: periodRem == 'true',
      waterGoalGlasses: waterGoal.clamp(1, 30),
      weightGoalKg: weightGoal,
    );
  }

  Future<AppPreferences> saveAppPreferences({
    String? colorPalette,
    String? userName,
    String? language,
    bool? showReportCharts,
    bool? periodReminders,
    int? waterGoalGlasses,
    String? weightGoalKg,
  }) async {
    if (colorPalette != null && _validPalettes.contains(colorPalette)) {
      await setMeta('color_palette', colorPalette);
    }
    if (userName != null) {
      final clean = userName.trim();
      if (clean.isNotEmpty) {
        await setMeta('user_name', clean.length > 40 ? clean.substring(0, 40) : clean);
        await setMeta('user_name_customized', 'true');
      }
    }
    if (language == 'en' || language == 'id') {
      await setMeta('language', language!);
    }
    if (showReportCharts != null) {
      await setMeta('show_report_charts', showReportCharts ? 'true' : 'false');
    }
    if (periodReminders != null) {
      await setMeta('period_reminders', periodReminders ? 'true' : 'false');
    }
    if (waterGoalGlasses != null) {
      await setMeta('water_goal_glasses', waterGoalGlasses.clamp(1, 30).toString());
    }
    if (weightGoalKg != null) {
      await setMeta('weight_goal_kg', weightGoalKg.trim());
    }
    return getAppPreferences();
  }

  Future<bool> softDeleteItem(String table, String id) async {
    const allowed = {
      'projects',
      'finance_envelopes',
      'finance_entries',
      'savings_goals',
      'recurring_bills',
      'health_entries',
      'wellness_entries',
      'menstrual_entries',
      'notes',
    };
    if (!allowed.contains(table) || id.isEmpty) return false;
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(table, {'is_active': 0, 'updated_at': now, 'dirty': 1}, where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await _db;
    return db.query('projects', where: 'is_active = 1', orderBy: 'is_someday ASC, updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> getEnvelopes() async {
    final db = await _db;
    return db.query('finance_envelopes', where: 'is_active = 1', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final db = await _db;
    return db.query('savings_goals', where: 'is_active = 1', orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> getRecurringBills() async {
    final db = await _db;
    return db.query('recurring_bills', where: 'is_active = 1', orderBy: 'due_day ASC, updated_at DESC');
  }

  Future<void> quickAdd(String kind, Map<String, dynamic> data) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final day = (data['day'] as String?) ?? formatLocalDay(DateTime.now());
    final rawId = data['id'] as String?;
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : const Uuid().v4();

    if (kind == 'task') {
      final groups = await getGroups();
      final gid = (data['group_id'] as String?) ?? (groups.isNotEmpty ? groups.first.id : 'seed-group-pagi');
      await saveTask(TaskItem(
        id: rawId ?? '',
        groupId: gid,
        name: (data['name'] as String?)?.trim().isNotEmpty == true ? (data['name'] as String).trim() : 'New step',
        core: data['core'] == true,
        sort: (data['sort'] as num?)?.toInt() ?? 99,
        freq: (data['freq'] as String?) ?? 'daily',
        freqDays: parseFreqDays(data['freq_days']),
        priority: (data['priority'] as String?) ?? 'normal',
        dueDate: data['due_date'] as String?,
        updatedAt: now,
      ));
      return;
    }

    if (kind == 'project') {
      final progress = ((data['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);
      await db.insert('projects', {
        'id': id,
        'name': (data['name'] as String?) ?? 'Project',
        'status': progress >= 100 ? 'done' : 'active',
        'progress': progress,
        'is_someday': (data['is_someday'] == true || data['is_someday'] == 1) ? 1 : 0,
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'focus') {
      await db.insert('focus_sessions', {
        'id': id,
        'task_id': data['task_id'],
        'project_id': data['project_id'],
        'day': day,
        'minutes': ((data['minutes'] as num?)?.toInt() ?? 25).clamp(1, 600),
        'note': data['note'],
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'envelope') {
      await db.insert('finance_envelopes', {
        'id': id,
        'name': (data['name'] as String?) ?? 'Envelope',
        'monthly_budget': (data['monthly_budget'] as num?)?.toInt() ?? 0,
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'finance') {
      final type = data['type'] == 'income' ? 'income' : 'expense';
      final cat = ['general', 'savings', 'debt'].contains(data['category']) ? data['category'] : 'general';
      await db.insert('finance_entries', {
        'id': id,
        'day': day,
        'type': type,
        'category': cat,
        'amount': ((data['amount'] as num?)?.round() ?? 0).clamp(0, 1000000000),
        'envelope_id': data['envelope_id'],
        'note': data['note'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'savings_goal') {
      await db.insert('savings_goals', {
        'id': id,
        'name': (data['name'] as String?) ?? 'Savings Goal',
        'target_amount': ((data['target_amount'] as num?)?.round() ?? 0).clamp(0, 1000000000),
        'current_amount': ((data['current_amount'] as num?)?.round() ?? 0).clamp(0, 1000000000),
        'deadline': data['deadline'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'recurring_bill') {
      await db.insert('recurring_bills', {
        'id': id,
        'name': (data['name'] as String?) ?? 'Recurring',
        'kind': data['kind'] == 'debt' ? 'debt' : 'bill',
        'amount': ((data['amount'] as num?)?.round() ?? 0).clamp(0, 1000000000),
        'due_day': ((data['due_day'] as num?)?.toInt() ?? 1).clamp(1, 31),
        'is_paid': (data['is_paid'] == true || data['is_paid'] == 1) ? 1 : 0,
        'last_paid_month': data['last_paid_month'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (['food', 'weight', 'water', 'workout', 'measurement'].contains(kind)) {
      final slot = ['breakfast', 'lunch', 'dinner', 'snacks'].contains(data['meal_slot']) ? data['meal_slot'] : null;
      await db.insert('health_entries', {
        'id': id,
        'day': day,
        'kind': kind,
        'name': data['name'],
        'meal_slot': slot,
        'value_num': (data['value_num'] as num?)?.toDouble() ?? 0.0,
        'value_num2': (data['value_num2'] as num?)?.toDouble(),
        'unit': data['unit'],
        'note': data['note'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'mood') {
      await db.insert('wellness_entries', {
        'id': id,
        'day': day,
        'mood': (data['mood'] as String?) ?? 'Calm',
        'mood_score': ((data['mood_score'] as num?)?.toInt() ?? 4).clamp(1, 5),
        'energy': ((data['energy'] as num?)?.toInt() ?? 3).clamp(1, 5),
        'stress': ((data['stress'] as num?)?.toInt() ?? 2).clamp(1, 5),
        'sleep_hours': (data['sleep_hours'] as num?)?.toDouble() ?? 7.0,
        'triggers_text': data['triggers_text'],
        'gratitude_text': data['gratitude_text'],
        'note': data['note'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'menstrual') {
      final syms = data['symptoms'] is List ? json.encode(data['symptoms']) : (data['symptoms_json'] ?? '[]');
      await db.insert('menstrual_entries', {
        'id': id,
        'day': day,
        'phase': (data['phase'] as String?) ?? 'Menstrual',
        'cycle_day': ((data['cycle_day'] as num?)?.toInt() ?? 1).clamp(1, 90),
        'flow': data['flow'],
        'symptoms_json': syms,
        'is_period_start': data['is_period_start'] == true || data['is_period_start'] == 1 ? 1 : 0,
        'cycle_length': (data['cycle_length'] as num?)?.toInt(),
        'note': data['note'],
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (kind == 'note') {
      String tagsJson = '[]';
      if (data['tags'] is List) {
        tagsJson = json.encode((data['tags'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList());
      } else if (data['tags_text'] is String) {
        tagsJson = json.encode((data['tags_text'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
      } else if (data['tags_json'] is String) {
        tagsJson = data['tags_json'] as String;
      }
      final cat = ['journal', 'braindump', 'gratitude', 'quick'].contains(data['category']) ? data['category'] : 'journal';
      final isPinned = (data['is_pinned'] == true || data['is_pinned'] == 1) ? 1 : 0;
      await db.insert('notes', {
        'id': id,
        'day': day,
        'title': (data['title'] as String?)?.trim().isNotEmpty == true ? (data['title'] as String).trim() : 'Quick Note',
        'body': (data['body'] as String?) ?? '',
        'tags_json': tagsJson,
        'category': cat,
        'is_pinned': isPinned,
        'is_active': 1,
        'updated_at': now,
        'dirty': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  ({String start, String end}) _resolveRangeBounds(
    String range,
    String? customStart,
    String? customEnd,
    String todayStr,
  ) {
    final end = (range == 'custom' && customEnd != null && customEnd.isNotEmpty) ? customEnd : todayStr;
    if (range == 'custom') {
      final s = (customStart != null && customStart.isNotEmpty && customStart.compareTo(end) <= 0)
          ? customStart
          : end;
      return (start: s, end: end);
    }
    final dt = parseLocalDay(todayStr);
    final back = range == 'month' ? 29 : (range == 'year' ? 364 : 6);
    return (start: formatLocalDay(dt.subtract(Duration(days: back))), end: end);
  }

  Future<List<AchievementItem>> getDerivedAchievements(String dayStr) async {
    final db = await _db;
    final checksRow = await db.rawQuery('SELECT COUNT(*) as c FROM checks WHERE checked = 1');
    final claimsRow = await db.rawQuery('SELECT COUNT(*) as c FROM claims');
    final focusRow = await db.rawQuery('SELECT COALESCE(SUM(minutes), 0) as m FROM focus_sessions');
    final stats = await getDashboardStats('week', dayStr);
    final totalChecks = (checksRow.first['c'] as num).toInt();
    final totalClaims = (claimsRow.first['c'] as num).toInt();
    final focusMin = (focusRow.first['m'] as num).toInt();
    return [
      AchievementItem(id: 'first-step', unlocked: totalChecks >= 1, progress: min(1, totalChecks), target: 1),
      AchievementItem(id: 'streak-7', unlocked: stats.currentStreak >= 7, progress: min(7, stats.currentStreak), target: 7),
      AchievementItem(id: 'checks-25', unlocked: totalChecks >= 25, progress: min(25, totalChecks), target: 25),
      AchievementItem(id: 'focus-60', unlocked: focusMin >= 60, progress: min(60, focusMin), target: 60),
      AchievementItem(id: 'self-care-1', unlocked: totalClaims >= 1, progress: min(1, totalClaims), target: 1),
    ];
  }

  Future<Map<String, dynamic>> exportAllDataJson() async {
    final db = await _db;
    Future<List<Map<String, dynamic>>> dump(String table) async {
      final rows = await db.query(table);
      return rows.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList();
    }
    final prefs = await getAppPreferences();
    final layout = await getDashboardLayout();
    return {
      'version': '0.3.1',
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'prefs': {
        'colorPalette': prefs.colorPalette,
        'userName': prefs.userName,
        'language': prefs.language,
        'showReportCharts': prefs.showReportCharts,
        'periodReminders': prefs.periodReminders,
        'waterGoalGlasses': prefs.waterGoalGlasses,
        'weightGoalKg': prefs.weightGoalKg,
      },
      'dashboardLayout': layout.map((w) => w.toJson()).toList(),
      'changes': {
        'groups': await dump('groups'),
        'tasks': await dump('tasks'),
        'rewards': await dump('rewards'),
        'checks': await dump('checks'),
        'claims': await dump('claims'),
        for (final tbl in _lifeOsSyncTables) tbl: await dump(tbl),
      },
    };
  }

  Future<void> importAllDataJson(Map<String, dynamic> payload) async {
    final changes = payload['changes'];
    if (changes is! Map) throw Exception('Invalid backup JSON');
    await applyIncomingChanges(Map<String, dynamic>.from(changes), 'import-restore');
    final prefs = payload['prefs'];
    if (prefs is Map) {
      await saveAppPreferences(
        colorPalette: prefs['colorPalette'] as String?,
        userName: prefs['userName'] as String?,
        language: prefs['language'] as String?,
        showReportCharts: prefs['showReportCharts'] as bool?,
        periodReminders: prefs['periodReminders'] as bool?,
        waterGoalGlasses: (prefs['waterGoalGlasses'] as num?)?.toInt(),
        weightGoalKg: prefs['weightGoalKg']?.toString(),
      );
    }
    final layout = payload['dashboardLayout'];
    if (layout is List && layout.isNotEmpty) {
      await saveDashboardLayout(
        layout.map((e) => DashboardWidgetConfig.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    }
  }

  Future<LifeOsSummary> getLifeOsSummary(String dayStr) async {
    final db = await _db;
    final layout = await getDashboardLayout();
    final groups = await getTodayData(dayStr);
    final scheduled = groups.expand((g) => g.tasks).where((t) => t.scheduled).toList();
    final prodDone = scheduled.where((t) => t.done).length;
    final focusRow = await db.rawQuery('SELECT COALESCE(SUM(minutes), 0) as m FROM focus_sessions WHERE day = ?', [dayStr]);
    final focusMin = (focusRow.first['m'] as num).toInt();

    final incRow = await db.rawQuery("SELECT COALESCE(SUM(amount), 0) as s FROM finance_entries WHERE is_active = 1 AND type = 'income'");
    final expRow = await db.rawQuery("SELECT COALESCE(SUM(amount), 0) as s FROM finance_entries WHERE is_active = 1 AND type = 'expense'");
    final cntRow = await db.rawQuery('SELECT COUNT(*) as c FROM finance_entries WHERE is_active = 1');
    final billsRow = await db.rawQuery('SELECT COUNT(*) as c FROM recurring_bills WHERE is_active = 1 AND is_paid = 0');
    final goalsRow = await db.rawQuery('SELECT COUNT(*) as c FROM savings_goals WHERE is_active = 1');
    final finInc = (incRow.first['s'] as num).toInt();
    final finExp = (expRow.first['s'] as num).toInt();
    final finCount = (cntRow.first['c'] as num).toInt();

    final weightRows = await db.query('health_entries', where: "is_active = 1 AND kind = 'weight'", orderBy: 'day DESC, updated_at DESC', limit: 1);
    final waterRow = await db.rawQuery("SELECT COALESCE(SUM(value_num), 0) as s FROM health_entries WHERE is_active = 1 AND kind = 'water' AND day = ?", [dayStr]);
    final kcalRow = await db.rawQuery("SELECT COALESCE(SUM(value_num), 0) as s FROM health_entries WHERE is_active = 1 AND kind = 'food' AND day = ?", [dayStr]);

    final wellRows = await db.query('wellness_entries', where: 'is_active = 1', orderBy: 'day DESC, updated_at DESC', limit: 1);
    final mensRows = await db.query('menstrual_entries', where: 'is_active = 1', orderBy: 'day DESC, updated_at DESC', limit: 1);
    final notesCntRow = await db.rawQuery('SELECT COUNT(*) as c FROM notes WHERE is_active = 1');
    final noteLatest = await db.query('notes', where: 'is_active = 1', orderBy: 'updated_at DESC, day DESC', limit: 1);
    final pinnedReminderRows = await db.rawQuery(
      "SELECT id, title, body FROM notes WHERE is_active = 1 AND is_pinned = 1 ORDER BY (id = 'little-note-motivation') DESC, updated_at DESC LIMIT 1",
    );
    final rewCntRow = await db.rawQuery('SELECT COUNT(*) as c FROM rewards WHERE is_active = 1');
    final audCntRow = await db.rawQuery("SELECT COUNT(*) as c FROM audit_logs WHERE level IN ('error', 'warn')");

    List<String> syms = [];
    if (mensRows.isNotEmpty && mensRows.first['symptoms_json'] != null) {
      try {
        syms = (json.decode(mensRows.first['symptoms_json'] as String) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return LifeOsSummary(
      layout: layout,
      prodDone: prodDone,
      prodTotal: scheduled.length,
      focusMinutesToday: focusMin,
      financeIncome: finInc,
      financeExpense: finExp,
      financeBalance: finInc - finExp,
      financeCount: finCount,
      unpaidBillsCount: (billsRow.first['c'] as num).toInt(),
      savingsGoalsCount: (goalsRow.first['c'] as num).toInt(),
      latestWeight: weightRows.isNotEmpty ? (weightRows.first['value_num'] as num).toDouble() : null,
      waterTodayMl: (waterRow.first['s'] as num).toDouble(),
      kcalToday: (kcalRow.first['s'] as num).toDouble(),
      latestMood: wellRows.isNotEmpty ? wellRows.first['mood'] as String : null,
      latestEnergy: wellRows.isNotEmpty ? (wellRows.first['energy'] as num).toInt() : null,
      latestStress: wellRows.isNotEmpty ? (wellRows.first['stress'] as num).toInt() : null,
      latestSleepHours: wellRows.isNotEmpty ? (wellRows.first['sleep_hours'] as num).toDouble() : null,
      latestGratitude: wellRows.isNotEmpty ? wellRows.first['gratitude_text'] as String? : null,
      latestMenstrualPhase: mensRows.isNotEmpty ? mensRows.first['phase'] as String : null,
      latestCycleDay: mensRows.isNotEmpty ? (mensRows.first['cycle_day'] as num).toInt() : null,
      latestSymptoms: syms,
      notesCount: (notesCntRow.first['c'] as num).toInt(),
      latestNoteTitle: noteLatest.isNotEmpty ? noteLatest.first['title'] as String : null,
      pinnedNoteId: pinnedReminderRows.isNotEmpty ? pinnedReminderRows.first['id'] as String : null,
      pinnedNoteTitle: pinnedReminderRows.isNotEmpty ? pinnedReminderRows.first['title'] as String : null,
      pinnedNoteBody: pinnedReminderRows.isNotEmpty ? pinnedReminderRows.first['body'] as String : null,
      rewardsBalance: await getPointsBalance(),
      activeRewardsCount: (rewCntRow.first['c'] as num).toInt(),
      errorAuditCount: (audCntRow.first['c'] as num).toInt(),
      achievements: await getDerivedAchievements(dayStr),
    );
  }

  Future<ModuleReportData> getModuleReport({
    required String module,
    required String range,
    String? customStart,
    String? customEnd,
    required String todayStr,
  }) async {
    final db = await _db;
    final b = _resolveRangeBounds(range, customStart, customEnd, todayStr);

    if (module == 'productivity') {
      final tasks = await getTasks();
      final checks = await db.query('checks', where: 'checked = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end]);
      final checkedSet = checks.map((c) => '${c['task_id']}|${c['day']}').toSet();
      final daysCount = parseLocalDay(b.end).difference(parseLocalDay(b.start)).inDays + 1;
      int schedSlots = 0;
      int doneSlots = 0;
      for (final t in tasks) {
        schedSlots += countScheduledDaysInRange(t, b.start, b.end);
        for (int i = 0; i < daysCount; i++) {
          final ds = formatLocalDay(parseLocalDay(b.start).add(Duration(days: i)));
          if (checkedSet.contains('${t.id}|$ds')) doneSlots++;
        }
      }
      final rate = schedSlots > 0 ? ((doneSlots / schedSlots) * 100).round() : 0;
      final focusRows = await db.query('focus_sessions', where: 'day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'day DESC, updated_at DESC');
      final focusMin = focusRows.fold<int>(0, (sum, r) => sum + (r['minutes'] as num).toInt());
      final projects = await getProjects();
      return ModuleReportData(
        module: module,
        start: b.start,
        end: b.end,
        metrics: {
          'completionRate': rate,
          'doneCount': doneSlots,
          'scheduledCount': schedSlots,
          'focusMinutes': focusMin,
          'projectsCount': projects.length,
        },
        breakdown: projects,
        entries: focusRows,
      );
    }

    if (module == 'finance') {
      final entries = await db.query('finance_entries', where: 'is_active = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'day DESC, updated_at DESC');
      final envs = await getEnvelopes();
      final goals = await getSavingsGoals();
      final bills = await getRecurringBills();
      int inc = 0, exp = 0, sav = 0, debt = 0;
      for (final e in entries) {
        final amt = (e['amount'] as num).toInt();
        if (e['type'] == 'income') {
          inc += amt;
        } else {
          exp += amt;
        }
        if (e['category'] == 'savings') sav += amt;
        if (e['category'] == 'debt') debt += amt;
      }
      final envUsage = envs.map((env) {
        final used = entries.where((e) => e['type'] == 'expense' && e['envelope_id'] == env['id']).fold<int>(0, (s, e) => s + (e['amount'] as num).toInt());
        final bud = (env['monthly_budget'] as num).toInt();
        final pct = bud > 0 ? ((used / bud) * 100).round().clamp(0, 100) : 0;
        return {'id': env['id'], 'name': env['name'], 'used': used, 'budget': bud, 'pct': pct};
      }).toList();
      return ModuleReportData(
        module: module,
        start: b.start,
        end: b.end,
        metrics: {
          'income': inc,
          'expense': exp,
          'savings': sav,
          'debt': debt,
          'savingsGoals': goals,
          'recurringBills': bills,
        },
        breakdown: envUsage,
        entries: entries,
      );
    }

    if (module == 'health') {
      final rows = await db.query('health_entries', where: 'is_active = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'day DESC, updated_at DESC');
      final prefs = await getAppPreferences();
      final weights = rows.where((r) => r['kind'] == 'weight').toList();
      final kcal = rows.where((r) => r['kind'] == 'food').fold<double>(0, (s, r) => s + (r['value_num'] as num).toDouble()).round();
      final water = rows.where((r) => r['kind'] == 'water').fold<double>(0, (s, r) => s + (r['value_num'] as num).toDouble()).round();
      final woMin = rows.where((r) => r['kind'] == 'workout').fold<double>(0, (s, r) => s + (r['value_num'] as num).toDouble()).round();
      final latestMeas = <String, Map<String, dynamic>>{};
      for (final m in rows.where((r) => r['kind'] == 'measurement')) {
        final k = (m['name'] as String? ?? 'Other').trim();
        latestMeas.putIfAbsent(k, () => m);
      }
      return ModuleReportData(
        module: module,
        start: b.start,
        end: b.end,
        metrics: {
          'latestWeight': weights.isNotEmpty ? (weights.first['value_num'] as num).toDouble() : null,
          'weightGoalKg': prefs.weightGoalKg,
          'waterGoalGlasses': prefs.waterGoalGlasses,
          'totalCalories': kcal,
          'totalWaterMl': water,
          'totalWorkoutMin': woMin,
          'latestMeasurements': latestMeas,
        },
        breakdown: weights,
        entries: rows,
      );
    }

    if (module == 'wellness') {
      final rows = await db.query('wellness_entries', where: 'is_active = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'day DESC, updated_at DESC');
      double avg(String k) => rows.isEmpty ? 0 : double.parse((rows.fold<double>(0, (s, r) => s + (r[k] as num).toDouble()) / rows.length).toStringAsFixed(1));
      final trigMap = <String, int>{};
      for (final r in rows) {
        final raw = r['triggers_text'] as String?;
        if (raw == null || raw.isEmpty) continue;
        for (final t in raw.split(',')) {
          final k = t.trim();
          if (k.isNotEmpty) trigMap[k] = (trigMap[k] ?? 0) + 1;
        }
      }
      final trigs = trigMap.entries.map((e) => (name: e.key, count: e.value)).toList()..sort((a, b) => b.count.compareTo(a.count));
      return ModuleReportData(
        module: module,
        start: b.start,
        end: b.end,
        metrics: {
          'count': rows.length,
          'avgMood': avg('mood_score'),
          'avgEnergy': avg('energy'),
          'avgStress': avg('stress'),
          'avgSleep': avg('sleep_hours'),
        },
        entries: rows,
        tagsOrTriggers: trigs,
      );
    }

    if (module == 'menstrual') {
      final rows = await db.query('menstrual_entries', where: 'is_active = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'day DESC, updated_at DESC');
      final allStarts = await db.query('menstrual_entries', where: 'is_active = 1 AND is_period_start = 1', orderBy: 'day DESC');
      final periods = rows.where((r) => r['is_period_start'] == 1).length;
      final lens = rows.map((r) => r['cycle_length']).whereType<num>().where((n) => n > 0).map((n) => n.toInt()).toList();
      final avgDur = lens.isEmpty ? null : (lens.reduce((a, b) => a + b) / lens.length).round();
      Map<String, dynamic>? nextEstimate;
      if (allStarts.isNotEmpty) {
        final lastStart = parseLocalDay(allStarts.first['day'] as String);
        final cycLen = ((allStarts.first['cycle_length'] as num?)?.toInt()) ?? avgDur ?? 28;
        final estNext = lastStart.add(Duration(days: cycLen));
        final estOv = estNext.subtract(const Duration(days: 14));
        nextEstimate = {
          'lastStartDay': allStarts.first['day'],
          'estimatedStartDay': formatLocalDay(estNext),
          'estimatedOvulationDay': formatLocalDay(estOv),
          'cycleLengthUsed': cycLen,
          'isEstimate': true,
        };
      }
      final symMap = <String, int>{};
      for (final r in rows) {
        final raw = r['symptoms_json'] as String?;
        if (raw == null) continue;
        try {
          for (final s in (json.decode(raw) as List)) {
            final k = s.toString().trim();
            if (k.isNotEmpty) symMap[k] = (symMap[k] ?? 0) + 1;
          }
        } catch (_) {}
      }
      final syms = symMap.entries.map((e) => (name: e.key, count: e.value)).toList()..sort((a, b) => b.count.compareTo(a.count));
      return ModuleReportData(
        module: module,
        start: b.start,
        end: b.end,
        metrics: {
          'count': rows.length,
          'avgCycleDuration': avgDur,
          'periodCount': periods,
          'latestPhase': rows.isNotEmpty ? rows.first['phase'] : null,
          'nextPeriodEstimate': nextEstimate,
        },
        entries: rows,
        tagsOrTriggers: syms,
      );
    }

    // notes
    final rows = await db.query('notes', where: 'is_active = 1 AND day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'updated_at DESC, day DESC');
    int words = 0;
    final tagMap = <String, int>{};
    for (final r in rows) {
      final body = (r['body'] as String? ?? '').trim();
      if (body.isNotEmpty) words += body.split(RegExp(r'\s+')).length;
      final raw = r['tags_json'] as String?;
      if (raw != null) {
        try {
          for (final t in (json.decode(raw) as List)) {
            final k = t.toString().trim();
            if (k.isNotEmpty) tagMap[k] = (tagMap[k] ?? 0) + 1;
          }
        } catch (_) {}
      }
    }
    final tags = tagMap.entries.map((e) => (name: e.key, count: e.value)).toList()..sort((a, b) => b.count.compareTo(a.count));
    return ModuleReportData(
      module: 'notes',
      start: b.start,
      end: b.end,
      metrics: {'count': rows.length, 'totalWords': words, 'uniqueTags': tags.length},
      entries: rows,
      tagsOrTriggers: tags,
    );
  }

  Future<void> logAudit({
    String source = 'Mobile',
    String category = 'sync',
    String level = 'error',
    required String endpoint,
    int? statusCode,
    String? errorCode,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final day = formatLocalDay(DateTime.fromMillisecondsSinceEpoch(now));
    final safeDetails = details != null ? json.encode(_sanitizeAuditValue(details)) : null;
    final safeMsg = _sanitizeAuditValue(message).toString();

    await db.insert('audit_logs', {
      'id': const Uuid().v4(),
      'created_at': now,
      'day': day,
      'source': source,
      'category': category,
      'level': level,
      'endpoint': endpoint,
      'status_code': statusCode,
      'error_code': errorCode,
      'message': safeMsg,
      'details_json': safeDetails,
    });

    final cutoff = now - 30 * 24 * 60 * 60 * 1000;
    await db.delete('audit_logs', where: 'created_at < ?', whereArgs: [cutoff]);
    await db.execute('DELETE FROM audit_logs WHERE id NOT IN (SELECT id FROM audit_logs ORDER BY created_at DESC LIMIT 500)');
  }

  Future<List<AuditLogEntry>> getAuditLogs({
    String category = 'all',
    String range = 'week',
    String? todayStr,
  }) async {
    final db = await _db;
    final today = todayStr ?? formatLocalDay(DateTime.now());
    final b = _resolveRangeBounds(range, null, null, today);
    final rows = await db.query('audit_logs', where: 'day >= ? AND day <= ?', whereArgs: [b.start, b.end], orderBy: 'created_at DESC');

    final list = <AuditLogEntry>[];
    for (final r in rows) {
      final cat = r['category'] as String;
      final lv = r['level'] as String;
      final sc = (r['status_code'] as num?)?.toInt();
      if (category == 'sync' && !((cat == 'sync' || cat == 'discovery') && lv == 'error')) continue;
      if (category == 'auth' && !(cat == 'auth' || sc == 401)) continue;
      if (category == 'info' && lv != 'info') continue;

      Map<String, dynamic>? details;
      if (r['details_json'] != null) {
        try {
          details = Map<String, dynamic>.from(json.decode(r['details_json'] as String) as Map);
        } catch (_) {}
      }
      list.add(AuditLogEntry(
        id: r['id'] as String,
        createdAt: (r['created_at'] as num).toInt(),
        day: r['day'] as String,
        source: r['source'] as String,
        category: cat,
        level: lv,
        endpoint: r['endpoint'] as String,
        statusCode: sc,
        errorCode: r['error_code'] as String?,
        message: r['message'] as String,
        details: details,
      ));
    }
    return list;
  }

  Future<void> clearAuditLogs() async {
    final db = await _db;
    await db.delete('audit_logs');
  }

  // --- META ---
  Future<String?> getMeta(String key) async {
    final db = await _db;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await _db;
    await db.insert(
      'meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
