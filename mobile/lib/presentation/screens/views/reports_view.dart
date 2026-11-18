import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/checklist_repository.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';
import 'quick_add_sheet.dart';

String _fmtRp(int amount) {
  final str = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp ${buf.toString()}';
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  static const _modules = [
    (id: 'productivity', label: 'Productivity'),
    (id: 'finance', label: 'Finance'),
    (id: 'health', label: 'Health'),
    (id: 'wellness', label: 'Wellness'),
    (id: 'menstrual', label: 'Menstrual'),
    (id: 'notes', label: 'Notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final rep = provider.moduleReport;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Module Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _modules.map((m) {
              final selected = provider.reportModule == m.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m.label),
                  selected: selected,
                  selectedColor: AppColors.accentSoft(context),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.accent(context)
                        : AppColors.ink(context),
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.accent(context)
                        : AppColors.line(context),
                  ),
                  onSelected: (_) => provider.setReportFilter(module: m.id),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Date Range Filter
        CalmSegmentedControl<String>(
          items: const [
            (value: 'week', label: 'Mingguan'),
            (value: 'month', label: 'Bulanan'),
            (value: 'year', label: 'Tahunan'),
            (value: 'custom', label: 'Kustom'),
          ],
          selected: provider.reportRange,
          onChanged: (r) async {
            if (r == 'custom') {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: now,
                initialDateRange: DateTimeRange(
                  start: now.subtract(const Duration(days: 6)),
                  end: now,
                ),
              );
              if (picked != null) {
                await provider.setReportFilter(
                  range: 'custom',
                  start: formatLocalDay(picked.start),
                  end: formatLocalDay(picked.end),
                );
              }
            } else {
              await provider.setReportFilter(range: r);
            }
          },
        ),
        if (rep != null) ...[
          const SizedBox(height: 8),
          Text(
            'Periode aktual: ${rep.start} s/d ${rep.end}',
            style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
          ),
        ],
        const SizedBox(height: 14),

        if (rep == null)
          const Center(child: CircularProgressIndicator())
        else
          _buildModuleContent(context, provider, rep),
      ],
    );
  }

  Widget _buildModuleContent(
    BuildContext context,
    ChecklistProvider provider,
    ModuleReportData rep,
  ) {
    final m = rep.metrics;
    switch (rep.module) {
      case 'productivity':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              ('Completion Rate', '${m['completionRate']}%'),
              ('Tugas Selesai', '${m['doneCount']}/${m['scheduledCount']}'),
              ('Focus Time', '${m['focusMinutes']} mnt'),
              ('Proyek Aktif', '${m['projectsCount']}'),
            ]),
            const SizedBox(height: 14),
            CalmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Project Progress',
                          style: AppTheme.displayStyle(context, fontSize: 17)),
                      TextButton(
                        onPressed: () => showQuickAddFormModal(
                            context, provider, 'project'),
                        child: const Text('+ Proyek'),
                      ),
                    ],
                  ),
                  if (rep.breakdown.isEmpty)
                    Text('Belum ada proyek tersimpan.',
                        style: TextStyle(color: AppColors.muted(context)))
                  else
                    ...rep.breakdown.map((p) {
                      final prog = (p['progress'] as num).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p['name'] as String),
                                Text('$prog%',
                                    style: TextStyle(
                                        color: AppColors.muted(context))),
                              ],
                            ),
                            const SizedBox(height: 5),
                            CalmProgressBar(percent: prog, height: 8),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );

      case 'finance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              ('Income', _fmtRp((m['income'] as num).toInt())),
              ('Expenses', _fmtRp((m['expense'] as num).toInt())),
              ('Savings', _fmtRp((m['savings'] as num).toInt())),
              ('Debt', _fmtRp((m['debt'] as num).toInt())),
            ]),
            const SizedBox(height: 14),
            CalmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Envelope Usage',
                          style: AppTheme.displayStyle(context, fontSize: 17)),
                      TextButton(
                        onPressed: () => showQuickAddFormModal(
                            context, provider, 'envelope'),
                        child: const Text('+ Amplop'),
                      ),
                    ],
                  ),
                  if (rep.breakdown.isEmpty)
                    Text('Belum ada amplop anggaran tersimpan.',
                        style: TextStyle(color: AppColors.muted(context)))
                  else
                    ...rep.breakdown.map((e) => Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e['name'] as String),
                                  Text(
                                    '${_fmtRp((e['used'] as num).toInt())} / ${_fmtRp((e['budget'] as num).toInt())}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted(context)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              CalmProgressBar(
                                  percent: (e['pct'] as num).toInt(),
                                  height: 8),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _historyCard(
              context,
              'Transaksi (${rep.entries.length})',
              rep.entries
                  .map((e) => (
                        title: (e['note'] as String?) ??
                            (e['category'] as String),
                        sub: '${e['day']}',
                        tail:
                            '${e['type'] == 'income' ? '+' : '-'}${_fmtRp((e['amount'] as num).toInt())}',
                      ))
                  .toList(),
            ),
          ],
        );

      case 'health':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              (
                'Latest Weight',
                m['latestWeight'] != null ? '${m['latestWeight']} kg' : '—'
              ),
              ('Calories', '${m['totalCalories']} kkal'),
              ('Water Intake', '${m['totalWaterMl']} ml'),
              ('Workout', '${m['totalWorkoutMin']} mnt'),
            ]),
            const SizedBox(height: 14),
            _historyCard(
              context,
              'Riwayat Health (${rep.entries.length})',
              rep.entries
                  .map((e) => (
                        title:
                            '${(e['kind'] as String).toUpperCase()}: ${(e['name'] as String?) ?? ''}',
                        sub: '${e['day']}',
                        tail:
                            '${e['value_num']} ${(e['unit'] as String?) ?? ''}',
                      ))
                  .toList(),
            ),
          ],
        );

      case 'wellness':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              ('Rata-rata Mood', '${m['avgMood']} / 5'),
              ('Energi', '${m['avgEnergy']} / 5'),
              ('Stres', '${m['avgStress']} / 5'),
              ('Tidur', '${m['avgSleep']} jam'),
            ]),
            if (rep.tagsOrTriggers.isNotEmpty) ...[
              const SizedBox(height: 14),
              CalmCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: rep.tagsOrTriggers
                      .map((t) => Chip(label: Text('${t.name} (${t.count})')))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _historyCard(
              context,
              'Check-in Wellness (${rep.entries.length})',
              rep.entries
                  .map((e) => (
                        title: '${e['mood']} (${e['mood_score']}/5)',
                        sub:
                            '${e['day']} · ${(e['triggers_text'] as String?) ?? ''}',
                        tail: 'Tidur ${e['sleep_hours']}j',
                      ))
                  .toList(),
            ),
          ],
        );

      case 'menstrual':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              ('Total Entri', '${m['count']}'),
              (
                'Durasi Siklus',
                m['avgCycleDuration'] != null
                    ? '${m['avgCycleDuration']} hr'
                    : '—'
              ),
              ('Period History', '${m['periodCount']}'),
              ('Fase Terkini', '${m['latestPhase'] ?? '—'}'),
            ]),
            if (rep.tagsOrTriggers.isNotEmpty) ...[
              const SizedBox(height: 14),
              CalmCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: rep.tagsOrTriggers
                      .map((t) => Chip(label: Text('${t.name} (${t.count})')))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _historyCard(
              context,
              'Riwayat Siklus (${rep.entries.length})',
              rep.entries
                  .map((e) => (
                        title: '${e['phase']} · Hari ke-${e['cycle_day']}',
                        sub: '${e['day']}',
                        tail: (e['flow'] as String?) ?? '',
                      ))
                  .toList(),
            ),
          ],
        );

      case 'notes':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(context, [
              ('Entri Catatan', '${m['count']}'),
              ('Total Kata', '${m['totalWords']}'),
              ('Unique Tags', '${m['uniqueTags']}'),
              (
                'Terbaru',
                rep.entries.isNotEmpty ? rep.entries.first['day'] as String : '—'
              ),
            ]),
            if (rep.tagsOrTriggers.isNotEmpty) ...[
              const SizedBox(height: 14),
              CalmCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: rep.tagsOrTriggers
                      .map((t) => Chip(label: Text('#${t.name} (${t.count})')))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _historyCard(
              context,
              'Riwayat Catatan (${rep.entries.length})',
              rep.entries
                  .map((e) => (
                        title: e['title'] as String,
                        sub: e['body'] as String,
                        tail: e['day'] as String,
                      ))
                  .toList(),
            ),
          ],
        );
    }
  }

  Widget _kpiGrid(BuildContext context, List<(String, String)> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (ctx, i) {
        final it = items[i];
        return CalmCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(it.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(context))),
              const SizedBox(height: 4),
              Text(
                it.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.displayStyle(context, fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyCard(
    BuildContext context,
    String title,
    List<({String title, String sub, String tail})> rows,
  ) {
    return CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.displayStyle(context, fontSize: 17)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('Belum ada data pada rentang ini.',
                style: TextStyle(color: AppColors.muted(context)))
          else
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            if (r.sub.isNotEmpty)
                              Text(r.sub,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted(context))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(r.tail,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted(context))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
