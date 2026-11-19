import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../providers/checklist_provider.dart';
import 'views/home_dashboard_v3_view.dart';
import 'views/today_view.dart';
import 'views/workspace_views.dart';
import 'views/rewards_view.dart';
import 'views/trail_view.dart';
import 'views/more_view.dart';
import 'views/audit_log_view.dart';
import 'views/quick_add_sheet.dart';

const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _daysId = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatIndonesianDate(String dayStr) => formatMobileDate(dayStr, 'id');

String formatMobileDate(String dayStr, String lang) {
  final parts = dayStr.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1], parts[2]);
  final dayNames = lang == 'id' ? _daysId : _daysEn;
  return '${dayNames[d.weekday - 1]}, ${parts[2]} ${_monthsShort[parts[1] - 1]}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ChecklistProvider>().onAppResumed();
    }
  }

  void _selectTab(ChecklistProvider provider, int idx) {
    provider.setEditMode(false);
    const idxToMod = {
      2: 'finance',
      3: 'health',
      4: 'wellness',
      5: 'menstrual',
      6: 'notes',
    };
    final mod = idxToMod[idx];
    if (mod != null) {
      provider.setReportFilter(module: mod, range: 'month');
    }
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final titles = [
      '${s.hello}, ${provider.prefs.userName} ♡', // 0: Home
      s.navTasks, // 1: Tasks
      s.navMoney, // 2: Money
      s.navHealth, // 3: Health
      s.wellness, // 4: Wellness
      s.menstrual, // 5: Menstrual
      s.notes, // 6: Notes
      s.rewards, // 7: Rewards
      s.history, // 8: History / Trail
      s.auditLog, // 9: Audit Log
      s.settings, // 10: Settings & IP
    ];
    final subtitles = [
      s.tr('A little progress is still progress.', 'Kemajuan kecil tetaplah kemajuan.'), // 0: Home
      s.tr('A gentle place for your plans and priorities.', 'Ruang tenang untuk rencana dan prioritasmu.'), // 1: Tasks
      s.tr('Keep track without making it complicated.', 'Catat keuangan tanpa membuatnya rumit.'), // 2: Money
      s.tr('Track gently. Progress, not perfection.', 'Catat perlahan. Progres, bukan kesempurnaan.'), // 3: Health
      s.tr('Notice how you feel, without judging it.', 'Kenali perasaanmu tanpa menghakimi.'), // 4: Wellness
      s.tr('Personal cycle notes and estimates.', 'Catatan siklus pribadi dan prakiraan.'), // 5: Menstrual
      s.tr('A quiet space to write things down.', 'Ruang tenang untuk menuliskan segalanya.'), // 6: Notes
      s.tr('Earn points for showing up for yourself.', 'Kumpulkan poin dengan merawat dirimu.'), // 7: Rewards
      '', // 8: History / Trail
      '', // 9: Audit Log
      '', // 10: Settings & IP
    ];
    final canEdit = _selectedIndex == 1 || _selectedIndex == 7;
    final inactiveTotal = provider.inactiveTasks.length + provider.inactiveGroups.length;
    final auditErrCount = provider.lifeOsSummary?.errorAuditCount ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatMobileDate(
                                _selectedIndex == 1 ? provider.selectedDate : provider.currentDay,
                                provider.prefs.language,
                              ),
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              titles[_selectedIndex],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.displayStyle(context, fontSize: 26),
                            ),
                            if (subtitles[_selectedIndex].isNotEmpty)
                              Text(
                                subtitles[_selectedIndex],
                                style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                              ),
                          ],
                        ),
                      ),
                      if (_selectedIndex == 1) ...[
                        Tooltip(
                          message: s.tr('Schedule calendar', 'Kalender jadwal'),
                          child: GestureDetector(
                            key: const Key('calendar_toggle_chip'),
                            onTap: () => provider.toggleCalendar(),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: provider.showCalendar ? AppColors.accentSoft(context) : AppColors.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: provider.showCalendar ? AppColors.accent(context) : AppColors.line(context),
                                ),
                              ),
                              child: const Text('📅', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (canEdit)
                        GestureDetector(
                          onTap: () => provider.toggleEditMode(),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: provider.editMode ? AppColors.accent(context) : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: provider.editMode ? AppColors.accent(context) : AppColors.line(context),
                              ),
                            ),
                            child: Text(
                              provider.editMode ? s.done : s.editBtn,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: provider.editMode ? AppColors.accentInk(context) : AppColors.ink(context),
                              ),
                            ),
                          ),
                        ),
                      if (_selectedIndex == 9)
                        TextButton(
                          onPressed: () => provider.clearAuditLogs(),
                          child: Text(s.tr('Clear', 'Bersihkan')),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      HomeDashboardV3View(
                        onNavigateTab: (idx) => _selectTab(provider, idx),
                        onOpenModule: (mod) {
                          const modToIdx = {'wellness': 4, 'menstrual': 5, 'notes': 6};
                          _selectTab(provider, modToIdx[mod] ?? 0);
                        },
                      ),
                      TodayView(onGoRewards: () => _selectTab(provider, 7)),
                      const FinanceWorkspaceView(),
                      const HealthWorkspaceView(),
                      const WellnessWorkspaceView(),
                      const MenstrualWorkspaceView(),
                      const NotesWorkspaceView(),
                      const RewardsView(),
                      const TrailView(),
                      const AuditLogView(),
                      const MoreView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('global_quick_add_fab'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.accentInk(context),
        elevation: 3,
        tooltip: 'Quick Add Global',
        onPressed: () => showQuickAddSheet(context, provider),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(top: BorderSide(color: AppColors.line(context))),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    _NavButton(
                      icon: '⌂',
                      label: s.navHome,
                      selected: _selectedIndex == 0,
                      onTap: () => _selectTab(provider, 0),
                    ),
                    _NavButton(
                      icon: '☀',
                      label: s.navTasks,
                      badge: '${provider.doneCount}/${provider.totalCount}',
                      selected: _selectedIndex == 1,
                      onTap: () => _selectTab(provider, 1),
                    ),
                    _NavButton(
                      icon: r'$',
                      label: s.navMoney,
                      selected: _selectedIndex == 2,
                      onTap: () => _selectTab(provider, 2),
                    ),
                    _NavButton(
                      icon: '♥',
                      label: s.navHealth,
                      selected: _selectedIndex == 3,
                      onTap: () => _selectTab(provider, 3),
                    ),
                    _NavButton(
                      icon: '☰',
                      label: s.navMore,
                      badge: (auditErrCount + inactiveTotal) > 0
                          ? '${auditErrCount > 0 ? auditErrCount : inactiveTotal}'
                          : null,
                      selected: _selectedIndex >= 4,
                      onTap: () => _openMoreSheet(context, provider, s),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMoreSheet(BuildContext context, ChecklistProvider provider, AppStrings s) {
    final sum = provider.lifeOsSummary;
    final phoneIp = provider.localIp ?? s.tr('Offline', 'Luring');
    final items = [
      (icon: '◐', title: s.wellness, sub: sum?.latestMood ?? s.tr('Mood & Sleep', 'Suasana hati & tidur'), idx: 4, badge: null),
      (icon: '✿', title: s.menstrual, sub: sum?.latestMenstrualPhase ?? s.tr('Cycle tracker', 'Pemantau siklus'), idx: 5, badge: null),
      (icon: '✎', title: s.notes, sub: '${sum?.notesCount ?? 0} ${s.tr('notes', 'catatan')}', idx: 6, badge: null),
      (icon: '★', title: s.rewards, sub: '${provider.pointsBalance} ${s.tr('pts', 'poin')}', idx: 7, badge: null),
      (icon: '📆', title: s.history, sub: s.tr('Monthly activity log', 'Riwayat aktivitas bulanan'), idx: 8, badge: null),
      (icon: '⚠', title: s.auditLog, sub: s.tr('Sync & API errors', 'Log error API & sinkron'), idx: 9, badge: (sum?.errorAuditCount ?? 0) > 0 ? '${sum!.errorAuditCount}' : null),
      (icon: '⚙', title: s.settings, sub: '${s.tr('Palette', 'Palet')} · ${s.phoneIp}: $phoneIp', idx: 10, badge: null),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.moreSpaces, style: AppTheme.displayStyle(sheetCtx, fontSize: 18)),
                Text(
                  '${s.phoneIp}: $phoneIp',
                  style: TextStyle(fontSize: 12, color: AppColors.muted(sheetCtx)),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 66,
                  ),
                  itemBuilder: (ctx, idx) {
                    final it = items[idx];
                    return InkWell(
                      key: Key('ws_tile_${it.idx}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _selectTab(provider, it.idx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bg(sheetCtx),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line(sheetCtx)),
                        ),
                        child: Row(
                          children: [
                            Text(it.icon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(it.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted(sheetCtx))),
                                ],
                              ),
                            ),
                            if (it.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accentSoft(sheetCtx), borderRadius: BorderRadius.circular(999)),
                                child: Text(it.badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentDeep(sheetCtx))),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final String icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.accentSoft(context) : Colors.transparent;
    final fgColor = selected ? AppColors.accentDeep(context) : AppColors.muted(context);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: TextStyle(fontSize: 17, color: fgColor)),
                    const SizedBox(height: 2),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fgColor)),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.tabBg(context), borderRadius: BorderRadius.circular(9)),
                      child: Text(badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink(context))),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
