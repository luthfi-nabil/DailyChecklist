import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/sync_service.dart';
import '../../domain/models/models.dart';

class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepository repository;
  final SyncService syncService;

  String currentDay = formatLocalDay(DateTime.now());
  String selectedDate = formatLocalDay(DateTime.now());
  bool showCalendar = false;
  int checklistCalYear = DateTime.now().year;
  int checklistCalMonth = DateTime.now().month;
  Map<String, ({bool hasWeekly, bool hasMonthly})> monthScheduleDots = {};

  bool liteMode = false;
  bool editMode = false;
  ThemeMode themeMode = ThemeMode.system;

  List<GroupItem> todayGroups = [];
  List<RewardItem> rewards = [];
  List<ClaimItem> claims = [];
  int pointsBalance = 0;

  List<InactiveTaskInfo> inactiveTasks = [];
  List<InactiveGroupInfo> inactiveGroups = [];

  String dashPeriod = 'week';
  DashboardStats? dashboardStats;

  int calYear = DateTime.now().year;
  int calMonth = DateTime.now().month;
  String selectedLogDay = formatLocalDay(DateTime.now());
  Map<String, int> monthActivity = {};
  DayLog? selectedDayLog;

  // --- PERSONAL LIFE OS & AUDIT LOG STATE ---
  bool customizeDashboard = false;
  AppPreferences prefs = const AppPreferences();
  String? localIp;
  List<({String iface, String address})> localIps = const [];
  LifeOsSummary? lifeOsSummary;
  String reportModule = 'productivity';
  String reportRange = 'week';
  String? customReportStart;
  String? customReportEnd;
  ModuleReportData? moduleReport;
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> envelopes = [];
  List<Map<String, dynamic>> savingsGoals = [];
  List<Map<String, dynamic>> recurringBills = [];
  String auditFilter = 'all';
  List<AuditLogEntry> auditLogs = [];

  final Set<String> _skippedFocusIds = {};
  StreamSubscription<SyncStatus>? _syncSub;
  Timer? _rolloverTimer;

  ChecklistProvider({
    required this.repository,
    required this.syncService,
  });

  Future<void> init() async {
    final savedLite = await repository.getMeta('lite_mode');
    liteMode = savedLite == 'true';

    final savedTheme = await repository.getMeta('theme_mode');
    if (savedTheme == 'light') {
      themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    await syncService.init();
    await refreshLocalIp();
    _syncSub = syncService.statusStream.listen((st) {
      if (st == SyncStatus.connected) {
        refreshAll();
      } else {
        notifyListeners();
      }
    });

    await refreshAll();

    // Auto-sync on start (non-blocking)
    if (syncService.autoSyncEnabled) {
      unawaited(syncService.sync());
    }

    _rolloverTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkRollover();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _rolloverTimer?.cancel();
    syncService.dispose();
    super.dispose();
  }

  void checkRollover() {
    final newDay = formatLocalDay(DateTime.now());
    if (newDay != currentDay) {
      final wasOnToday = selectedDate == currentDay;
      currentDay = newDay;
      if (wasOnToday) {
        selectedDate = newDay;
        final d = DateTime.now();
        checklistCalYear = d.year;
        checklistCalMonth = d.month;
      }
      selectedLogDay = newDay;
      _skippedFocusIds.clear();
      refreshAll();
    }
  }

  void onAppResumed() {
    checkRollover();
    if (syncService.autoSyncEnabled) {
      unawaited(syncService.sync());
    }
  }

  Future<void> refreshAll() async {
    todayGroups = await repository.getTodayData(selectedDate);
    monthScheduleDots =
        await repository.getMonthScheduleDots(checklistCalYear, checklistCalMonth);
    rewards = await repository.getRewards();
    claims = await repository.getClaims();
    pointsBalance = await repository.getPointsBalance();
    final inactive = await repository.getInactiveItems();
    inactiveTasks = inactive.tasks;
    inactiveGroups = inactive.groups;
    dashboardStats = await repository.getDashboardStats(dashPeriod, currentDay);
    monthActivity = await repository.getMonthActivity(calYear, calMonth);
    selectedDayLog = await repository.getDayLog(selectedLogDay);
    lifeOsSummary = await repository.getLifeOsSummary(currentDay);
    prefs = await repository.getAppPreferences();
    projects = await repository.getProjects();
    envelopes = await repository.getEnvelopes();
    savingsGoals = await repository.getSavingsGoals();
    recurringBills = await repository.getRecurringBills();
    moduleReport = await repository.getModuleReport(
      module: reportModule,
      range: reportRange,
      customStart: customReportStart,
      customEnd: customReportEnd,
      todayStr: currentDay,
    );
    auditLogs = await repository.getAuditLogs(
      category: auditFilter,
      range: reportRange,
      todayStr: currentDay,
    );
    notifyListeners();
  }

  // --- TODAY & CALENDAR HELPERS ---
  bool get isFutureSelectedDate => selectedDate.compareTo(currentDay) > 0;
  bool get isPastSelectedDate => selectedDate.compareTo(currentDay) < 0;

  List<TaskItem> get countedTasks {
    final out = <TaskItem>[];
    for (final g in todayGroups) {
      for (final t in g.tasks) {
        if (t.scheduled && (!liteMode || t.core)) out.add(t);
      }
    }
    return out;
  }

  int get offDayCount {
    var count = 0;
    for (final g in todayGroups) {
      for (final t in g.tasks) {
        if (!t.scheduled) count++;
      }
    }
    return count;
  }

  void toggleCalendar() {
    showCalendar = !showCalendar;
    notifyListeners();
  }

  Future<void> selectChecklistDate(String day) async {
    if (selectedDate == day) return;
    selectedDate = day;
    final parsed = parseLocalDay(day);
    checklistCalYear = parsed.year;
    checklistCalMonth = parsed.month;
    _skippedFocusIds.clear();
    todayGroups = await repository.getTodayData(selectedDate);
    monthScheduleDots =
        await repository.getMonthScheduleDots(checklistCalYear, checklistCalMonth);
    notifyListeners();
  }

  Future<void> backToToday() async {
    await selectChecklistDate(currentDay);
  }

  Future<void> changeChecklistCalMonth(int delta) async {
    var m = checklistCalMonth + delta;
    var y = checklistCalYear;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    checklistCalYear = y;
    checklistCalMonth = m;
    monthScheduleDots =
        await repository.getMonthScheduleDots(checklistCalYear, checklistCalMonth);
    notifyListeners();
  }

  int get doneCount => countedTasks.where((t) => t.done).length;
  int get totalCount => countedTasks.length;

  TaskItem? get nextFocusTask {
    final uncompleted = countedTasks.where((t) => !t.done).toList();
    if (uncompleted.isEmpty) return null;
    final fresh = uncompleted.where((t) => !_skippedFocusIds.contains(t.id)).toList();
    if (fresh.isEmpty) {
      _skippedFocusIds.clear();
      return uncompleted.first;
    }
    return fresh.first;
  }

  void skipFocusTask(String taskId) {
    _skippedFocusIds.add(taskId);
    notifyListeners();
  }

  Future<void> toggleLiteMode() async {
    liteMode = !liteMode;
    await repository.setMeta('lite_mode', liteMode ? 'true' : 'false');
    notifyListeners();
  }

  void toggleEditMode() {
    editMode = !editMode;
    notifyListeners();
  }

  void setEditMode(bool value) {
    if (editMode != value) {
      editMode = value;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCheck(String taskId, bool checked) async {
    if (isFutureSelectedDate) return;
    await repository.toggleCheck(taskId, selectedDate, checked);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  // --- EDIT MODE MUTATIONS ---
  Future<TaskItem> addTask(String groupId, {String name = 'Langkah baru'}) async {
    final g = todayGroups.firstWhere((x) => x.id == groupId);
    final task = await repository.saveTask(TaskItem(
      id: '',
      groupId: groupId,
      name: name,
      sort: g.tasks.length,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await refreshAll();
    syncService.triggerDebouncedSync();
    return task;
  }

  Future<void> updateTaskName(TaskItem task, String name) async {
    await repository.saveTask(task.copyWith(name: name));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> updateTaskSchedule(
      TaskItem task, String freq, List<int> freqDays) async {
    TaskItem target = task;
    for (final g in todayGroups) {
      for (final t in g.tasks) {
        if (t.id == task.id) {
          target = t;
          break;
        }
      }
    }
    await repository.saveTask(target.copyWith(freq: freq, freqDays: freqDays));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> toggleTaskCore(TaskItem task) async {
    await repository.saveTask(task.copyWith(core: !task.core));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> deactivateTask(String id) async {
    await repository.deactivateTask(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> reactivateTask(String id) async {
    await repository.reactivateTask(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> deleteTaskPermanently(String id) async {
    await repository.deleteTaskPermanently(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<GroupItem> addGroup({String name = 'Kelompok baru'}) async {
    final group = await repository.saveGroup(GroupItem(
      id: '',
      name: name,
      sort: todayGroups.length,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await refreshAll();
    syncService.triggerDebouncedSync();
    return group;
  }

  Future<void> updateGroupName(GroupItem group, String name) async {
    await repository.saveGroup(group.copyWith(name: name));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> moveGroup(String groupId, int delta) async {
    await repository.moveGroup(groupId, delta);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> deactivateGroup(String id) async {
    await repository.deactivateGroup(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> reactivateGroup(String id) async {
    await repository.reactivateGroup(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  // --- REWARDS & CLAIMS ---
  Future<RewardItem> addReward({String name = 'Hadiah baru', int cost = 10}) async {
    final r = await repository.saveReward(RewardItem(
      id: '',
      name: name,
      cost: cost,
      sort: rewards.length,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await refreshAll();
    syncService.triggerDebouncedSync();
    return r;
  }

  Future<void> updateReward(RewardItem reward, {String? name, int? cost}) async {
    await repository.saveReward(RewardItem(
      id: reward.id,
      name: name ?? reward.name,
      cost: cost ?? reward.cost,
      sort: reward.sort,
      isActive: reward.isActive,
      deactivatedAt: reward.deactivatedAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> deactivateReward(String id) async {
    await repository.deactivateReward(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> reactivateReward(String id) async {
    await repository.reactivateReward(id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<ClaimItem> claimReward(String rewardId) async {
    final claim = await repository.claimReward(rewardId, currentDay);
    await refreshAll();
    syncService.triggerDebouncedSync();
    return claim;
  }

  Future<bool> undoClaim(String claimId) async {
    final ok = await repository.undoClaim(claimId);
    if (ok) {
      await refreshAll();
      syncService.triggerDebouncedSync();
    }
    return ok;
  }

  // --- DASHBOARD & LOG ---
  Future<void> setDashPeriod(String period) async {
    dashPeriod = period;
    dashboardStats = await repository.getDashboardStats(dashPeriod, currentDay);
    notifyListeners();
  }

  Future<void> changeCalendarMonth(int delta) async {
    calMonth += delta;
    if (calMonth < 1) {
      calMonth = 12;
      calYear--;
    } else if (calMonth > 12) {
      calMonth = 1;
      calYear++;
    }
    monthActivity = await repository.getMonthActivity(calYear, calMonth);
    notifyListeners();
  }

  Future<void> selectLogDay(String day) async {
    selectedLogDay = day;
    selectedDayLog = await repository.getDayLog(day);
    notifyListeners();
  }

  // --- SETTINGS & SYNC ---
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final val = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.dark ? 'dark' : 'auto');
    await repository.setMeta('theme_mode', val);
    notifyListeners();
  }

  Future<void> setAutoSync(bool enabled) async {
    await syncService.setAutoSync(enabled);
    notifyListeners();
  }

  Future<bool> pairWithDesktop(String code) async {
    final ok = await syncService.pair(code);
    await refreshAll();
    return ok;
  }

  Future<bool> syncNow() async {
    final ok = await syncService.sync();
    await refreshAll();
    return ok;
  }

  Future<({DiscoveredServer? server, bool synced})> configureManualSync({
    required bool enabled,
    required String host,
    required int port,
    bool testAndSync = false,
  }) async {
    await syncService.setManualEndpoint(enabled: enabled, host: host, port: port);
    DiscoveredServer? found;
    bool synced = false;
    if (enabled && testAndSync) {
      found = await syncService.connectManual(host: host, port: port);
      if (found != null) {
        final token = await repository.getMeta('paired_token');
        if (token != null && token.isNotEmpty) {
          synced = await syncService.sync();
        } else {
          syncService.status = SyncStatus.unauthorized;
        }
      }
    }
    await refreshAll();
    return (server: found, synced: synced);
  }

  // --- PERSONAL LIFE OS & AUDIT LOG ACTIONS ---
  void toggleCustomizeDashboard() {
    customizeDashboard = !customizeDashboard;
    notifyListeners();
  }

  void setCustomizeDashboard(bool value) {
    if (customizeDashboard != value) {
      customizeDashboard = value;
      notifyListeners();
    }
  }

  Future<void> moveDashboardWidget(String id, int delta) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    final idx = layout.indexWhere((w) => w.id == id);
    final next = idx + delta;
    if (idx < 0 || next < 0 || next >= layout.length) return;
    final item = layout.removeAt(idx);
    layout.insert(next, item);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> reorderDashboardWidgetIndices(int oldIdx, int newIdx) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    if (oldIdx < 0 || oldIdx >= layout.length) return;
    var target = newIdx;
    if (oldIdx < target) target -= 1;
    if (target < 0 || target >= layout.length) return;
    final item = layout.removeAt(oldIdx);
    layout.insert(target, item);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> toggleWidgetVisible(String id) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    final idx = layout.indexWhere((w) => w.id == id);
    if (idx < 0) return;
    layout[idx] = layout[idx].copyWith(visible: !layout[idx].visible);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> renameDashboardWidget(String id, String newLabel) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    final idx = layout.indexWhere((w) => w.id == id);
    if (idx < 0) return;
    final clean = newLabel.trim();
    layout[idx] = clean.isEmpty
        ? layout[idx].copyWith(clearLabel: true)
        : layout[idx].copyWith(label: clean.length > 32 ? clean.substring(0, 32) : clean);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> addWidgetToDashboard(String id) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    if (layout.any((w) => w.id == id)) return;
    final def = defaultDashboardLayout.firstWhere(
      (w) => w.id == id,
      orElse: () => DashboardWidgetConfig(id: id),
    );
    layout.add(def);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> removeWidgetFromDashboard(String id) async {
    final layout = List<DashboardWidgetConfig>.from(
        lifeOsSummary?.layout ?? defaultDashboardLayout);
    layout.removeWhere((w) => w.id == id);
    await repository.saveDashboardLayout(layout);
    await refreshAll();
  }

  Future<void> resetDashboardLayout() async {
    await repository.resetDashboardLayout();
    await refreshAll();
  }

  Future<void> setReportFilter({
    String? module,
    String? range,
    String? start,
    String? end,
  }) async {
    if (module != null) reportModule = module;
    if (range != null) reportRange = range;
    if (start != null) customReportStart = start;
    if (end != null) customReportEnd = end;
    moduleReport = await repository.getModuleReport(
      module: reportModule,
      range: reportRange,
      customStart: customReportStart,
      customEnd: customReportEnd,
      todayStr: currentDay,
    );
    notifyListeners();
  }

  Future<void> saveQuickAdd(String kind, Map<String, dynamic> data) async {
    await repository.quickAdd(kind, {'day': currentDay, ...data});
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> setAuditFilter(String filter) async {
    auditFilter = filter;
    auditLogs = await repository.getAuditLogs(
      category: auditFilter,
      range: reportRange,
      todayStr: currentDay,
    );
    notifyListeners();
  }

  Future<void> clearAuditLogs() async {
    await repository.clearAuditLogs();
    await refreshAll();
  }

  Future<void> refreshLocalIp() async {
    localIps = await syncService.getLocalIpAddresses();
    localIp = localIps.isNotEmpty ? localIps.first.address : null;
    notifyListeners();
  }

  Future<void> updateAppPreferences({
    String? colorPalette,
    String? userName,
    String? language,
    bool? showReportCharts,
    bool? periodReminders,
    int? waterGoalGlasses,
    String? weightGoalKg,
  }) async {
    prefs = await repository.saveAppPreferences(
      colorPalette: colorPalette,
      userName: userName,
      language: language,
      showReportCharts: showReportCharts,
      periodReminders: periodReminders,
      waterGoalGlasses: waterGoalGlasses,
      weightGoalKg: weightGoalKg,
    );
    await refreshAll();
  }

  Future<void> updateTaskMeta(TaskItem task, {String? priority, String? dueDate, bool clearDueDate = false}) async {
    await repository.saveTask(task.copyWith(
      priority: priority,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
    ));
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<void> softDeleteItem(String table, String id) async {
    await repository.softDeleteItem(table, id);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }

  Future<Map<String, dynamic>> exportAllDataJson() => repository.exportAllDataJson();

  Future<void> importAllDataJson(Map<String, dynamic> payload) async {
    await repository.importAllDataJson(payload);
    await refreshAll();
    syncService.triggerDebouncedSync();
  }
}
