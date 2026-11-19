import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/checklist_repository.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';
import '../home_screen.dart';

const _monthsShortEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsShortId = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _fmtMs(int? ms, AppStrings s) {
  if (ms == null) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final arr = s.isId ? _monthsShortId : _monthsShortEn;
  return '${d.day} ${arr[d.month - 1]}';
}

class TrailView extends StatefulWidget {
  const TrailView({super.key});

  @override
  State<TrailView> createState() => _TrailViewState();
}

class _TrailViewState extends State<TrailView> {
  String _subTab = 'dash';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(context.watch<ChecklistProvider>().prefs.language);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        CalmSegmentedControl<String>(
          items: [
            (value: 'dash', label: s.tr('Overview', 'Dasbor')),
            (value: 'log', label: s.tr('History', 'Riwayat')),
          ],
          selected: _subTab,
          onChanged: (val) => setState(() => _subTab = val),
        ),
        const SizedBox(height: 16),
        if (_subTab == 'dash') const _DashboardSection() else const _LogSection(),
      ],
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final stats = provider.dashboardStats;
    if (stats == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final maxChart = max(5, stats.dailyChart.fold<int>(0, (m, d) => max(m, d.count)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalmSegmentedControl<String>(
          items: [
            (value: 'week', label: s.tr('This week', 'Minggu ini')),
            (value: 'month', label: s.tr('This month', 'Bulan ini')),
            (value: 'all', label: s.tr('All', 'Semua')),
          ],
          selected: provider.dashPeriod,
          onChanged: (p) => provider.setDashPeriod(p),
        ),
        const SizedBox(height: 16),

        // Hero card
        CalmCard(
          color: AppColors.accentSoft(context),
          borderColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: '${stats.rate}',
                  style: AppTheme.displayStyle(context, fontSize: 32),
                  children: [
                    TextSpan(
                      text: '% selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CalmProgressBar(percent: stats.rate, height: 10),
              const SizedBox(height: 10),
              Text(
                'Hari yang terlewat tidak apa-apa. Yang dihitung hanya langkah yang kamu ambil.',
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2x2 Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.75,
          children: [
            _MetricCard(value: '${stats.totalDone}', label: 'langkah selesai'),
            _MetricCard(value: '${stats.activeDays}', sub: '/${stats.daysCount}', label: 'hari aktif'),
            _MetricCard(value: '${stats.currentStreak}', sub: ' hari', label: 'beruntun saat ini'),
            _MetricCard(
              value: '+${stats.pointsEarned}',
              label: 'poin didapat',
              gold: true,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Daily bar chart
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Langkah per hari', style: AppTheme.displayStyle(context, fontSize: 17)),
                  Text('maks $maxChart', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 124,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: stats.dailyChart.map((bar) {
                    final h = bar.count == 0 ? 4.0 : max(8.0, (bar.count / maxChart) * 96.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: h,
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 36),
                              decoration: BoxDecoration(
                                color: bar.isToday
                                    ? AppColors.gold(context)
                                    : AppColors.accent(context),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bar.dow,
                              style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per Group Breakdown
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Per kelompok', style: AppTheme.displayStyle(context, fontSize: 17)),
              const SizedBox(height: 4),
              if (stats.groupStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Belum ada kelompok.', style: TextStyle(color: AppColors.muted(context))),
                ),
              ...List.generate(stats.groupStats.length, (i) {
                final g = stats.groupStats[i];
                return Column(
                  children: [
                    if (i > 0) Divider(height: 1, color: AppColors.line(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(g.name),
                              Text('${g.rate}%', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          CalmProgressBar(percent: g.rate, height: 10),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per Task Breakdown
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Per langkah', style: AppTheme.displayStyle(context, fontSize: 17)),
                  Text('paling sering dulu', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              ...List.generate(min(8, stats.taskStats.length), (i) {
                final t = stats.taskStats[i];
                return Column(
                  children: [
                    if (i > 0) Divider(height: 1, color: AppColors.line(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(t.name),
                                    if (t.freq != 'daily')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: t.freq == 'weekly'
                                              ? AppColors.accentSoft(context)
                                              : AppColors.goldSoft(context),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          t.freqLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: t.freq == 'weekly'
                                                ? AppColors.accent(context)
                                                : AppColors.goldInk(context),
                                          ),
                                        ),
                                      ),
                                    if (!t.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.tabBg(context),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${s.tr('Inactive since', 'Nonaktif sejak')} ${_fmtMs(t.deactivatedAt, s)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.muted(context),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${t.done}/${t.totalDays}',
                                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          CalmProgressBar(
                            percent: t.rate,
                            height: 10,
                            barColor: t.isActive ? null : AppColors.boxLine(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Langkah nonaktif tetap dihitung pada hari ketika masih aktif, supaya tren tidak berubah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String? sub;
  final String label;
  final bool gold;

  const _MetricCard({
    required this.value,
    this.sub,
    required this.label,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return CalmCard(
      padding: const EdgeInsets.all(12),
      color: gold ? AppColors.goldSoft(context) : AppColors.surface(context),
      borderColor: gold ? Colors.transparent : AppColors.line(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: AppTheme.displayStyle(
                context,
                fontSize: 24,
                color: gold ? AppColors.goldInk(context) : AppColors.ink(context),
              ),
              children: [
                if (sub != null)
                  TextSpan(
                    text: sub,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final year = provider.calYear;
    final month = provider.calMonth;
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final todayStr = formatLocalDay(now);

    final firstDow = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun
    final offset = firstDow - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = offset + daysInMonth;

    final dayLog = provider.selectedDayLog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calendar card
        CalmCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(s.isId ? _monthsShortId : _monthsShortEn)[month - 1]} $year',
                    style: AppTheme.displayStyle(context, fontSize: 17),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: AppColors.line(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => provider.changeCalendarMonth(-1),
                        child: const Text('‹', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: AppColors.line(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isCurrentMonth ? null : () => provider.changeCalendarMonth(1),
                        child: const Text('›', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted(context),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: totalCells,
                itemBuilder: (context, idx) {
                  if (idx < offset) return const SizedBox.shrink();
                  final dayNum = idx - offset + 1;
                  final dStr = formatLocalDay(DateTime(year, month, dayNum));
                  final isFuture = dStr.compareTo(todayStr) > 0;
                  final level = provider.monthActivity[dStr] ?? 0;
                  final isSelected = dStr == provider.selectedLogDay;

                  Color bg = AppColors.surface(context);
                  Color fg = AppColors.ink(context);
                  if (level == 1) {
                    bg = AppColors.accentSoft(context);
                  } else if (level == 2) {
                    bg = Color.lerp(AppColors.surface(context), AppColors.accent(context), 0.45)!;
                  } else if (level == 3) {
                    bg = AppColors.accent(context);
                    fg = AppColors.accentInk(context);
                  }

                  return GestureDetector(
                    onTap: isFuture ? null : () => provider.selectLogDay(dStr),
                    child: Opacity(
                      opacity: isFuture ? 0.35 : 1.0,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: isSelected ? 2 : 1,
                            color: isSelected ? AppColors.ink(context) : AppColors.line(context),
                          ),
                        ),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (dayLog != null) ...[
          CalmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatIndonesianDate(dayLog.day).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.muted(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${dayLog.completedTasks}',
                        style: AppTheme.displayStyle(context, fontSize: 32),
                        children: [
                          TextSpan(
                            text: ' dari ${dayLog.totalTasks} langkah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${dayLog.completedTasks} poin',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CalmProgressBar(percent: dayLog.rate),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (dayLog.groups.isEmpty)
            CalmCard(
              child: Text('Tidak ada catatan pada hari ini.', style: TextStyle(color: AppColors.muted(context))),
            )
          else
            ...dayLog.groups.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CalmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.name, style: AppTheme.displayStyle(context, fontSize: 17)),
                            Text(
                              '${g.doneCount}/${g.totalCount}',
                              style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...List.generate(g.tasks.length, (i) {
                          final t = g.tasks[i];
                          return Column(
                            children: [
                              if (i > 0) Divider(height: 1, color: AppColors.line(context)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: t.done
                                            ? AppColors.accent(context)
                                            : AppColors.missSoft(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.done ? '✓' : '–',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: t.done
                                              ? AppColors.accentInk(context)
                                              : AppColors.miss(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            t.name,
                                            style: TextStyle(
                                              color: t.done
                                                  ? AppColors.ink(context)
                                                  : AppColors.muted(context),
                                            ),
                                          ),
                                          if (!t.isActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.tabBg(context),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${s.tr('Inactive since', 'Nonaktif sejak')} ${_fmtMs(t.deactivatedAt, s)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.muted(context),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.time,
                                      style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                )),
        ],
      ],
    );
  }
}
