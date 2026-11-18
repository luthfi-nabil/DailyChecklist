import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

class _WidgetMeta {
  final String id;
  final String module;
  final String title;
  final String? reportMod;

  const _WidgetMeta({
    required this.id,
    required this.module,
    required this.title,
    this.reportMod,
  });
}

const _widgetCatalog = [
  _WidgetMeta(id: 'w-prod', module: 'Productivity', title: 'Productivity & Fokus', reportMod: 'productivity'),
  _WidgetMeta(id: 'w-fin', module: 'Finance', title: 'Finance & Budget', reportMod: 'finance'),
  _WidgetMeta(id: 'w-hlth', module: 'Health', title: 'Health & Hydration', reportMod: 'health'),
  _WidgetMeta(id: 'w-well', module: 'Wellness', title: 'Wellness Check-in', reportMod: 'wellness'),
  _WidgetMeta(id: 'w-mens', module: 'Menstrual Cycle', title: 'Menstrual Cycle', reportMod: 'menstrual'),
  _WidgetMeta(id: 'w-note', module: 'Notes & Journal', title: 'Notes & Journal', reportMod: 'notes'),
  _WidgetMeta(id: 'w-rew', module: 'Rewards', title: 'Rewards & Poin', reportMod: null),
];

({Color bg, Color fg}) _pastelForWidget(BuildContext context, String id) {
  switch (id) {
    case 'w-prod':
      return (bg: AppColors.accentSoft(context), fg: AppColors.accent(context));
    case 'w-fin':
    case 'w-rew':
      return (bg: AppColors.goldSoft(context), fg: AppColors.goldInk(context));
    case 'w-hlth':
      return (bg: AppColors.pastelSky(context), fg: AppColors.pastelSkyInk(context));
    case 'w-well':
      return (bg: AppColors.pastelLavender(context), fg: AppColors.pastelLavenderInk(context));
    case 'w-mens':
      return (bg: AppColors.pastelBlush(context), fg: AppColors.pastelBlushInk(context));
    case 'w-note':
      return (bg: AppColors.pastelPeach(context), fg: AppColors.pastelPeachInk(context));
    default:
      return (bg: AppColors.tabBg(context), fg: AppColors.muted(context));
  }
}

String _fmtRp(int amount) {
  final str = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp ${buf.toString()}';
}

class LifeOsDashboardView extends StatelessWidget {
  final ValueChanged<String> onOpenReport;

  const LifeOsDashboardView({super.key, required this.onOpenReport});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final summary = provider.lifeOsSummary;
    final layout = summary?.layout ?? defaultDashboardLayout;
    final displayList =
        layout.where((w) => provider.customizeDashboard || w.visible).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Customize / Toolbar Card
        Row(
          children: [
            Expanded(
              child: Text(
                'Ringkasan Modul (${layout.where((w) => w.visible).length}/${layout.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted(context),
                ),
              ),
            ),
            if (provider.customizeDashboard) ...[
              TextButton.icon(
                onPressed: () => _showCatalogSheet(context, provider),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Widget'),
              ),
              TextButton(
                onPressed: () => provider.resetDashboardLayout(),
                child: const Text('Reset'),
              ),
            ],
            OutlinedButton.icon(
              key: const Key('customize_dashboard_btn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: provider.customizeDashboard
                    ? AppColors.accentSoft(context)
                    : AppColors.surface(context),
                side: BorderSide(
                  color: provider.customizeDashboard
                      ? AppColors.accent(context)
                      : AppColors.line(context),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => provider.toggleCustomizeDashboard(),
              icon: Icon(
                provider.customizeDashboard ? Icons.check : Icons.tune,
                size: 16,
                color: provider.customizeDashboard
                    ? AppColors.accent(context)
                    : AppColors.ink(context),
              ),
              label: Text(
                provider.customizeDashboard ? 'Selesai' : 'Atur Widget',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: provider.customizeDashboard
                      ? AppColors.accent(context)
                      : AppColors.ink(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (provider.customizeDashboard) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pastelLavender(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Mode atur aktif. Seret atau ketuk ↑/↓ untuk mengurutkan, sembunyikan/tampilkan, atau tambah/hapus modul.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.pastelLavenderInk(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (displayList.isEmpty)
          CalmCard(
            child: Column(
              children: [
                Text(
                  'Semua widget disembunyikan.',
                  style: TextStyle(color: AppColors.muted(context)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.resetDashboardLayout(),
                  child: const Text('Reset ke tata letak bawaan'),
                ),
              ],
            ),
          )
        else if (provider.customizeDashboard)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: displayList.length,
            onReorder: (oldIndex, newIndex) =>
                provider.reorderDashboardWidgetIndices(oldIndex, newIndex),
            itemBuilder: (ctx, i) {
              final cfg = displayList[i];
              return Padding(
                key: ValueKey(cfg.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWidgetCard(
                  context,
                  provider,
                  cfg,
                  summary,
                  i,
                  displayList.length,
                  reorderIndex: i,
                ),
              );
            },
          )
        else
          ...List.generate(displayList.length, (i) {
            final cfg = displayList[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidgetCard(
                context,
                provider,
                cfg,
                summary,
                i,
                displayList.length,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWidgetCard(
    BuildContext context,
    ChecklistProvider provider,
    DashboardWidgetConfig cfg,
    LifeOsSummary? summary,
    int idx,
    int count, {
    int? reorderIndex,
  }) {
    final meta = _widgetCatalog.firstWhere(
      (m) => m.id == cfg.id,
      orElse: () => _WidgetMeta(id: cfg.id, module: 'Modul', title: cfg.id),
    );
    final pastel = _pastelForWidget(context, cfg.id);

    return Opacity(
      opacity: cfg.visible ? 1.0 : 0.55,
      child: CalmCard(
        borderColor: provider.customizeDashboard
            ? AppColors.accent(context).withAlpha(120)
            : AppColors.line(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: pastel.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meta.module,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pastel.fg,
                    ),
                  ),
                ),
                const Spacer(),
                if (!provider.customizeDashboard && meta.reportMod != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => onOpenReport(meta.reportMod!),
                    child: Text(
                      'Laporan →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent(context),
                      ),
                    ),
                  )
                else if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.drag_handle,
                          color: AppColors.muted(context)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(meta.title, style: AppTheme.displayStyle(context, fontSize: 17)),
            const SizedBox(height: 8),
            _buildWidgetMetrics(context, cfg.id, summary),
            if (provider.customizeDashboard) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.line(context)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    key: Key('widget_up_${cfg.id}'),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: idx == 0
                        ? null
                        : () => provider.moveDashboardWidget(cfg.id, -1),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    tooltip: 'Geser naik',
                  ),
                  IconButton(
                    key: Key('widget_down_${cfg.id}'),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: idx == count - 1
                        ? null
                        : () => provider.moveDashboardWidget(cfg.id, 1),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    tooltip: 'Geser turun',
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => provider.toggleWidgetVisible(cfg.id),
                    icon: Icon(
                      cfg.visible ? Icons.visibility : Icons.visibility_off,
                      size: 16,
                    ),
                    label: Text(cfg.visible ? 'Tampil' : 'Tersembunyi',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () =>
                        provider.removeWidgetFromDashboard(cfg.id),
                    icon: Icon(Icons.close,
                        size: 18, color: AppColors.miss(context)),
                    tooltip: 'Hapus dari dasbor',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetMetrics(
      BuildContext context, String id, LifeOsSummary? s) {
    if (s == null) {
      return Text('Memuat data...', style: TextStyle(color: AppColors.muted(context)));
    }
    switch (id) {
      case 'w-prod':
        final pct = s.prodTotal > 0
            ? ((s.prodDone / s.prodTotal) * 100).round()
            : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.prodDone}/${s.prodTotal} langkah',
                style: AppTheme.displayStyle(context, fontSize: 22)),
            const SizedBox(height: 6),
            CalmProgressBar(percent: pct, height: 8),
            const SizedBox(height: 6),
            Text(
              '$pct% selesai · ${s.focusMinutesToday} menit fokus hari ini',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-fin':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fmtRp(s.financeBalance),
                style: AppTheme.displayStyle(context, fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              'Masuk ${_fmtRp(s.financeIncome)} · Keluar ${_fmtRp(s.financeExpense)} (${s.financeCount} entri)',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-hlth':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.latestWeight != null ? '${s.latestWeight} kg' : '—',
              style: AppTheme.displayStyle(context, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              'Air hari ini: ${s.waterTodayMl.round()} ml · Kalori: ${s.kcalToday.round()} kkal',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-well':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.latestMood ?? 'Belum ada check-in',
                style: AppTheme.displayStyle(context, fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              s.latestMood != null
                  ? 'Energi ${s.latestEnergy}/5 · Stres ${s.latestStress}/5 · Tidur ${s.latestSleepHours}j'
                  : 'Ketuk + untuk mencatat mood & tidur hari ini.',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-mens':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.latestCycleDay != null
                  ? 'Hari ke-${s.latestCycleDay}'
                  : 'Belum ada catatan',
              style: AppTheme.displayStyle(context, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              s.latestMenstrualPhase != null
                  ? '${s.latestMenstrualPhase}${s.latestSymptoms.isNotEmpty ? ' · ${s.latestSymptoms.join(', ')}' : ''}'
                  : 'Catat siklus dan gejala melalui tombol +.',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-note':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.notesCount} catatan',
                style: AppTheme.displayStyle(context, fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              s.latestNoteTitle != null
                  ? 'Terbaru: "${s.latestNoteTitle}"'
                  : 'Belum ada catatan tersimpan.',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
      case 'w-rew':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.rewardsBalance} poin tersedia',
                style: AppTheme.displayStyle(context, fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              '${s.activeRewardsCount} hadiah aktif siap ditukar',
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        );
    }
  }
}

Future<void> _showCatalogSheet(
    BuildContext context, ChecklistProvider provider) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) {
      return Consumer<ChecklistProvider>(
        builder: (ctx, p, _) {
          final layout = p.lifeOsSummary?.layout ?? defaultDashboardLayout;
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                Text('Tambah / Atur Widget',
                    style: AppTheme.displayStyle(ctx, fontSize: 20)),
                const SizedBox(height: 12),
                ..._widgetCatalog.map((meta) {
                  final idx = layout.indexWhere((w) => w.id == meta.id);
                  final exists = idx >= 0;
                  final visible = exists && layout[idx].visible;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(meta.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(meta.module),
                    trailing: exists
                        ? Switch.adaptive(
                            value: visible,
                            onChanged: (_) => p.toggleWidgetVisible(meta.id),
                          )
                        : OutlinedButton(
                            onPressed: () => p.addWidgetToDashboard(meta.id),
                            child: const Text('+ Tambah'),
                          ),
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );
}
