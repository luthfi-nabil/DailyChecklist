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

    int countScheduledDays(TaskItem task, String startStr, String endStr) {
      if (task.freq == 'daily') return daysCount;
      final start = parseLocalDay(startStr);
      final end = parseLocalDay(endStr);
      int c = 0;
      DateTime d = start;
      while (!d.isAfter(end)) {
        if (task.isScheduledOnDate(d)) c++;
        d = d.add(const Duration(days: 1));
      }
      return c;
    }

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

    return {
      'groups': groups.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'tasks': tasks.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'rewards': rewards.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'checks': checks.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
      'claims': claims.map((r) => Map<String, dynamic>.from(r)..remove('dirty')).toList(),
    };
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

    await batch.commit(noResult: true);
  }

  Future<void> applyIncomingChanges(Map<String, dynamic> changes, String serverDeviceId) async {
    final db = await _db;
    final myDeviceId = await getMeta('device_id') ?? '';

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
          'is_active': t['is_active'],
          'deactivated_at': t['deactivated_at'],
          'updated_at': t['updated_at'],
          'dirty': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

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
