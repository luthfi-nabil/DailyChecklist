import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../providers/checklist_provider.dart';
import 'views/today_view.dart';
import 'views/lifeos_dashboard_view.dart';
import 'views/reports_view.dart';
import 'views/rewards_view.dart';
import 'views/trail_view.dart';
import 'views/more_view.dart';
import 'views/audit_log_view.dart';
import 'views/quick_add_sheet.dart';

const _daysId = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _monthsId = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String formatIndonesianDate(String dayStr) {
  final parts = dayStr.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1], parts[2]);
  return '${_daysId[d.weekday - 1]}, ${parts[2]} ${_monthsId[parts[1] - 1]}';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final titles = [
      'Hari ini',
      'Dasbor',
      'Laporan',
      'Hadiah',
      'Jejak',
      'Lainnya',
      'Audit Log',
    ];
    final canEdit = _selectedIndex == 0 || _selectedIndex == 3;
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
                // Top Header matching MobileDesign.html
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
                              formatIndonesianDate(_selectedIndex == 0
                                  ? provider.selectedDate
                                  : provider.currentDay),
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              titles[_selectedIndex],
                              style: AppTheme.displayStyle(context, fontSize: 28),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedIndex == 0) ...[
                        Tooltip(
                          message: 'Kalender jadwal',
                          child: GestureDetector(
                            key: const Key('calendar_toggle_chip'),
                            onTap: () => provider.toggleCalendar(),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: provider.showCalendar
                                    ? AppColors.accentSoft(context)
                                    : AppColors.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: provider.showCalendar
                                      ? AppColors.accent(context)
                                      : AppColors.line(context),
                                ),
                              ),
                              child: const Text(
                                '📅',
                                style: TextStyle(fontSize: 16),
                              ),
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
                              color: provider.editMode
                                  ? AppColors.accent(context)
                                  : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: provider.editMode
                                    ? AppColors.accent(context)
                                    : AppColors.line(context),
                              ),
                            ),
                            child: Text(
                              provider.editMode ? 'Selesai mengubah' : 'Ubah',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: provider.editMode
                                    ? AppColors.accentInk(context)
                                    : AppColors.ink(context),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Main Content View
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      TodayView(onGoRewards: () {
                        provider.setEditMode(false);
                        setState(() => _selectedIndex = 3);
                      }),
                      LifeOsDashboardView(
                        onOpenReport: (mod) {
                          provider.setReportFilter(module: mod);
                          setState(() => _selectedIndex = 2);
                        },
                      ),
                      const ReportsView(),
                      const RewardsView(),
                      const TrailView(),
                      const MoreView(),
                      const AuditLogView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('global_fab'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.accentInk(context),
        elevation: 3,
        tooltip: 'Quick Add',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _NavButton(
                  icon: '☀',
                  label: 'Hari ini',
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavButton(
                  icon: '▦',
                  label: 'Dasbor',
                  selected: _selectedIndex == 1,
                  onTap: () {
                    provider.setEditMode(false);
                    setState(() => _selectedIndex = 1);
                  },
                ),
                _NavButton(
                  icon: '▥',
                  label: 'Laporan',
                  selected: _selectedIndex == 2,
                  onTap: () {
                    provider.setEditMode(false);
                    setState(() => _selectedIndex = 2);
                  },
                ),
                _NavButton(
                  icon: '⊞',
                  label: 'Workspace',
                  badge: auditErrCount > 0 ? '$auditErrCount' : null,
                  badgeGold: false,
                  selected: _selectedIndex >= 3,
                  onTap: () => _openWorkspaceSheet(context, provider, inactiveTotal, auditErrCount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWorkspaceSheet(
    BuildContext context,
    ChecklistProvider provider,
    int inactiveTotal,
    int auditErrCount,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final items = [
          (icon: '✓', title: 'Productivity', sub: 'Task & Fokus', idx: 2, mod: 'productivity', badge: null as String?),
          (icon: 'Rp', title: 'Finance', sub: 'Cashflow & Amplop', idx: 2, mod: 'finance', badge: null as String?),
          (icon: '♥', title: 'Health', sub: 'Berat, Air, Kalori', idx: 2, mod: 'health', badge: null as String?),
          (icon: '◐', title: 'Wellness', sub: 'Mood, Stres, Tidur', idx: 2, mod: 'wellness', badge: null as String?),
          (icon: '✿', title: 'Menstrual', sub: 'Siklus & Gejala', idx: 2, mod: 'menstrual', badge: null as String?),
          (icon: '✎', title: 'Notes', sub: 'Jurnal & Tags', idx: 2, mod: 'notes', badge: null as String?),
          (icon: '★', title: 'Hadiah', sub: '${provider.pointsBalance} poin', idx: 3, mod: null as String?, badge: '${provider.pointsBalance}'),
          (icon: '☰', title: 'Jejak', sub: 'Analitik & Riwayat', idx: 4, mod: null as String?, badge: null as String?),
          (icon: '⚠', title: 'Audit Log', sub: 'API & Sync Error', idx: 6, mod: null as String?, badge: auditErrCount > 0 ? '$auditErrCount' : null),
          (icon: '⚙', title: 'Lainnya', sub: 'Sinkron & Tema', idx: 5, mod: null as String?, badge: inactiveTotal > 0 ? '$inactiveTotal' : null),
        ];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Workspace Menu',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted(sheetCtx))),
                const SizedBox(height: 2),
                Text('Pilih Modul, Laporan & Sistem',
                    style: AppTheme.displayStyle(sheetCtx, fontSize: 20)),
                const SizedBox(height: 14),
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
                      key: Key('ws_tile_${it.title}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        provider.setEditMode(false);
                        if (it.mod != null) {
                          provider.setReportFilter(module: it.mod);
                        }
                        setState(() => _selectedIndex = it.idx);
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
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(it.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(it.sub,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: AppColors.muted(sheetCtx))),
                                ],
                              ),
                            ),
                            if (it.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft(sheetCtx),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(it.badge!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent(sheetCtx))),
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
  final bool badgeGold;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeGold = false,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.accentSoft(context) : Colors.transparent;
    final fgColor = selected ? AppColors.accent(context) : AppColors.muted(context);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: TextStyle(fontSize: 18, color: fgColor)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeGold
                            ? AppColors.gold(context)
                            : AppColors.tabBg(context),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeGold
                              ? const Color(0xFF2A1B02)
                              : AppColors.ink(context),
                        ),
                      ),
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
