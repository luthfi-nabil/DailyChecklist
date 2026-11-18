import 'dart:convert';

List<int> parseFreqDays(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw.map((e) => (e as num).toInt()).toList();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {}
  }
  return const [];
}

String formatFreqLabel(String freq, List<int> days) {
  const dowFull = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  if (freq == 'weekly' && days.isNotEmpty) {
    return days.map((d) => d >= 1 && d <= 7 ? dowFull[d] : '$d').join(', ');
  }
  if (freq == 'monthly' && days.isNotEmpty) {
    return 'Tanggal ${days.join(', ')}';
  }
  return 'Setiap hari';
}

class GroupItem {
  final String id;
  final String name;
  final int sort;
  final bool isActive;
  final int? deactivatedAt;
  final int updatedAt;
  final List<TaskItem> tasks;

  GroupItem({
    required this.id,
    required this.name,
    this.sort = 0,
    this.isActive = true,
    this.deactivatedAt,
    required this.updatedAt,
    this.tasks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort': sort,
      'is_active': isActive ? 1 : 0,
      'deactivated_at': deactivatedAt,
      'updated_at': updatedAt,
    };
  }

  factory GroupItem.fromMap(Map<String, dynamic> map, {List<TaskItem> tasks = const []}) {
    return GroupItem(
      id: map['id'] as String,
      name: map['name'] as String,
      sort: (map['sort'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      deactivatedAt: (map['deactivated_at'] as num?)?.toInt(),
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      tasks: tasks,
    );
  }

  GroupItem copyWith({
    String? name,
    int? sort,
    bool? isActive,
    int? deactivatedAt,
    int? updatedAt,
    List<TaskItem>? tasks,
  }) {
    return GroupItem(
      id: id,
      name: name ?? this.name,
      sort: sort ?? this.sort,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TaskItem {
  final String id;
  final String groupId;
  final String name;
  final bool core;
  final int sort;
  final String freq;
  final List<int> freqDays;
  final bool isActive;
  final int? deactivatedAt;
  final int updatedAt;
  final bool done;
  final bool scheduled;

  TaskItem({
    required this.id,
    required this.groupId,
    required this.name,
    this.core = false,
    this.sort = 0,
    this.freq = 'daily',
    this.freqDays = const [],
    this.isActive = true,
    this.deactivatedAt,
    required this.updatedAt,
    this.done = false,
    this.scheduled = true,
  });

  bool isScheduledOnDate(DateTime date) {
    if (freq == 'daily' || freqDays.isEmpty) return true;
    if (freq == 'weekly') return freqDays.contains(date.weekday);
    if (freq == 'monthly') return freqDays.contains(date.day);
    return true;
  }

  String get freqLabel => formatFreqLabel(freq, freqDays);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'core': core ? 1 : 0,
      'sort': sort,
      'freq': freq,
      'freq_days': (freq == 'weekly' || freq == 'monthly') ? json.encode(freqDays) : null,
      'is_active': isActive ? 1 : 0,
      'deactivated_at': deactivatedAt,
      'updated_at': updatedAt,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map, {bool done = false, bool scheduled = true}) {
    final freqRaw = map['freq'] as String?;
    final freq = (freqRaw == 'weekly' || freqRaw == 'monthly') ? freqRaw! : 'daily';
    return TaskItem(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      name: map['name'] as String,
      core: (map['core'] as num?)?.toInt() == 1,
      sort: (map['sort'] as num?)?.toInt() ?? 0,
      freq: freq,
      freqDays: parseFreqDays(map['freq_days']),
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      deactivatedAt: (map['deactivated_at'] as num?)?.toInt(),
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      done: done,
      scheduled: scheduled,
    );
  }

  TaskItem copyWith({
    String? name,
    bool? core,
    int? sort,
    String? freq,
    List<int>? freqDays,
    bool? isActive,
    int? deactivatedAt,
    int? updatedAt,
    bool? done,
    bool? scheduled,
  }) {
    return TaskItem(
      id: id,
      groupId: groupId,
      name: name ?? this.name,
      core: core ?? this.core,
      sort: sort ?? this.sort,
      freq: freq ?? this.freq,
      freqDays: freqDays ?? this.freqDays,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      done: done ?? this.done,
      scheduled: scheduled ?? this.scheduled,
    );
  }
}

class RewardItem {
  final String id;
  final String name;
  final int cost;
  final int sort;
  final bool isActive;
  final int? deactivatedAt;
  final int updatedAt;

  RewardItem({
    required this.id,
    required this.name,
    required this.cost,
    this.sort = 0,
    this.isActive = true,
    this.deactivatedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'sort': sort,
      'is_active': isActive ? 1 : 0,
      'deactivated_at': deactivatedAt,
      'updated_at': updatedAt,
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map) {
    return RewardItem(
      id: map['id'] as String,
      name: map['name'] as String,
      cost: (map['cost'] as num?)?.toInt() ?? 10,
      sort: (map['sort'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      deactivatedAt: (map['deactivated_at'] as num?)?.toInt(),
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class CheckItem {
  final String taskId;
  final String day;
  final bool checked;
  final int updatedAt;

  CheckItem({
    required this.taskId,
    required this.day,
    required this.checked,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'day': day,
      'checked': checked ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  factory CheckItem.fromMap(Map<String, dynamic> map) {
    return CheckItem(
      taskId: map['task_id'] as String,
      day: map['day'] as String,
      checked: (map['checked'] as num?)?.toInt() == 1,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClaimItem {
  final String id;
  final String? rewardId;
  final String name;
  final int cost;
  final String day;
  final int claimedAt;
  final int updatedAt;

  ClaimItem({
    required this.id,
    this.rewardId,
    required this.name,
    required this.cost,
    required this.day,
    required this.claimedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reward_id': rewardId,
      'name': name,
      'cost': cost,
      'day': day,
      'claimed_at': claimedAt,
      'updated_at': updatedAt,
    };
  }

  factory ClaimItem.fromMap(Map<String, dynamic> map) {
    return ClaimItem(
      id: map['id'] as String,
      rewardId: map['reward_id'] as String?,
      name: map['name'] as String,
      cost: (map['cost'] as num?)?.toInt() ?? 0,
      day: map['day'] as String,
      claimedAt: (map['claimed_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class InactiveTaskInfo {
  final String id;
  final String name;
  final String groupName;
  final int? deactivatedAt;
  final int completedCount;

  InactiveTaskInfo({
    required this.id,
    required this.name,
    required this.groupName,
    this.deactivatedAt,
    required this.completedCount,
  });
}

class InactiveGroupInfo {
  final String id;
  final String name;
  final int? deactivatedAt;
  final int taskCount;

  InactiveGroupInfo({
    required this.id,
    required this.name,
    this.deactivatedAt,
    required this.taskCount,
  });
}

class DashboardDayBar {
  final String day;
  final String dow;
  final int count;
  final bool isToday;

  DashboardDayBar({
    required this.day,
    required this.dow,
    required this.count,
    required this.isToday,
  });
}

class DashboardGroupStat {
  final String id;
  final String name;
  final int rate;
  final int done;
  final int possible;

  DashboardGroupStat({
    required this.id,
    required this.name,
    required this.rate,
    required this.done,
    required this.possible,
  });
}

class DashboardTaskStat {
  final String id;
  final String name;
  final String freq;
  final List<int> freqDays;
  final bool isActive;
  final int? deactivatedAt;
  final int done;
  final int totalDays;
  final int rate;

  DashboardTaskStat({
    required this.id,
    required this.name,
    this.freq = 'daily',
    this.freqDays = const [],
    required this.isActive,
    this.deactivatedAt,
    required this.done,
    required this.totalDays,
    required this.rate,
  });

  String get freqLabel => formatFreqLabel(freq, freqDays);
}

class DashboardStats {
  final String period;
  final String label;
  final int rate;
  final int totalDone;
  final int activeDays;
  final int daysCount;
  final int currentStreak;
  final int pointsEarned;
  final List<DashboardDayBar> dailyChart;
  final List<DashboardGroupStat> groupStats;
  final List<DashboardTaskStat> taskStats;

  DashboardStats({
    required this.period,
    required this.label,
    required this.rate,
    required this.totalDone,
    required this.activeDays,
    required this.daysCount,
    required this.currentStreak,
    required this.pointsEarned,
    required this.dailyChart,
    required this.groupStats,
    required this.taskStats,
  });
}

class DayLogTask {
  final String id;
  final String name;
  final bool isActive;
  final int? deactivatedAt;
  final bool done;
  final String time;

  DayLogTask({
    required this.id,
    required this.name,
    required this.isActive,
    this.deactivatedAt,
    required this.done,
    required this.time,
  });
}

class DayLogGroup {
  final String id;
  final String name;
  final int doneCount;
  final int totalCount;
  final List<DayLogTask> tasks;

  DayLogGroup({
    required this.id,
    required this.name,
    required this.doneCount,
    required this.totalCount,
    required this.tasks,
  });
}

class DayLog {
  final String day;
  final int totalTasks;
  final int completedTasks;
  final int rate;
  final List<DayLogGroup> groups;

  DayLog({
    required this.day,
    required this.totalTasks,
    required this.completedTasks,
    required this.rate,
    required this.groups,
  });
}

// --- PERSONAL LIFE OS & AUDIT LOG MODELS ---

class DashboardWidgetConfig {
  final String id;
  final bool visible;
  final String size; // 's' | 'm' | 'l'

  const DashboardWidgetConfig({
    required this.id,
    this.visible = true,
    this.size = 'm',
  });

  DashboardWidgetConfig copyWith({bool? visible, String? size}) =>
      DashboardWidgetConfig(
        id: id,
        visible: visible ?? this.visible,
        size: size ?? this.size,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'visible': visible,
        'size': size,
      };

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> m) =>
      DashboardWidgetConfig(
        id: m['id'] as String,
        visible: m['visible'] != false,
        size: (m['size'] as String?) ?? 'm',
      );
}

const defaultDashboardLayout = [
  DashboardWidgetConfig(id: 'w-prod', visible: true, size: 'm'),
  DashboardWidgetConfig(id: 'w-fin', visible: true, size: 'm'),
  DashboardWidgetConfig(id: 'w-hlth', visible: true, size: 's'),
  DashboardWidgetConfig(id: 'w-well', visible: true, size: 's'),
  DashboardWidgetConfig(id: 'w-mens', visible: true, size: 's'),
  DashboardWidgetConfig(id: 'w-note', visible: true, size: 'm'),
  DashboardWidgetConfig(id: 'w-rew', visible: true, size: 'm'),
];

class LifeOsSummary {
  final List<DashboardWidgetConfig> layout;
  final int prodDone;
  final int prodTotal;
  final int focusMinutesToday;
  final int financeIncome;
  final int financeExpense;
  final int financeBalance;
  final int financeCount;
  final double? latestWeight;
  final double waterTodayMl;
  final double kcalToday;
  final String? latestMood;
  final int? latestEnergy;
  final int? latestStress;
  final double? latestSleepHours;
  final String? latestMenstrualPhase;
  final int? latestCycleDay;
  final List<String> latestSymptoms;
  final int notesCount;
  final String? latestNoteTitle;
  final int rewardsBalance;
  final int activeRewardsCount;
  final int errorAuditCount;

  LifeOsSummary({
    required this.layout,
    required this.prodDone,
    required this.prodTotal,
    required this.focusMinutesToday,
    required this.financeIncome,
    required this.financeExpense,
    required this.financeBalance,
    required this.financeCount,
    this.latestWeight,
    required this.waterTodayMl,
    required this.kcalToday,
    this.latestMood,
    this.latestEnergy,
    this.latestStress,
    this.latestSleepHours,
    this.latestMenstrualPhase,
    this.latestCycleDay,
    this.latestSymptoms = const [],
    required this.notesCount,
    this.latestNoteTitle,
    required this.rewardsBalance,
    required this.activeRewardsCount,
    required this.errorAuditCount,
  });
}

class ModuleReportData {
  final String module;
  final String start;
  final String end;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> breakdown;
  final List<Map<String, dynamic>> entries;
  final List<({String name, int count})> tagsOrTriggers;

  ModuleReportData({
    required this.module,
    required this.start,
    required this.end,
    required this.metrics,
    this.breakdown = const [],
    this.entries = const [],
    this.tagsOrTriggers = const [],
  });
}

class AuditLogEntry {
  final String id;
  final int createdAt;
  final String day;
  final String source;
  final String category;
  final String level;
  final String endpoint;
  final int? statusCode;
  final String? errorCode;
  final String message;
  final Map<String, dynamic>? details;

  AuditLogEntry({
    required this.id,
    required this.createdAt,
    required this.day,
    required this.source,
    required this.category,
    required this.level,
    required this.endpoint,
    this.statusCode,
    this.errorCode,
    required this.message,
    this.details,
  });
}
