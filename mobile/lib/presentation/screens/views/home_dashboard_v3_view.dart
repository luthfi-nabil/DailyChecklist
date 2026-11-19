import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

class HomeDashboardV3View extends StatefulWidget {
  final void Function(int tabIndex) onNavigateTab;
  final void Function(String reportModule) onOpenModule;

  const HomeDashboardV3View({
    super.key,
    required this.onNavigateTab,
    required this.onOpenModule,
  });

  @override
  State<HomeDashboardV3View> createState() => _HomeDashboardV3ViewState();
}

class _HomeDashboardV3ViewState extends State<HomeDashboardV3View> {
  final _littleNoteCtrl = TextEditingController();
  bool _editingLittleNote = false;

  @override
  void dispose() {
    _littleNoteCtrl.dispose();
    super.dispose();
  }

  String _fmtRp(int n) {
    final s = n.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return n < 0 ? '-Rp $s' : 'Rp $s';
  }

  void _showAddTaskDialog(BuildContext context, ChecklistProvider provider, AppStrings s) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.todayTasks),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.tr('Add a small step...', 'Tambah langkah kecil...'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await provider.saveQuickAdd('task', {'name': name});
            },
            child: Text(s.tr('Add', 'Tambah')),
          ),
        ],
      ),
    );
  }

  void _showRenameSpaceDialog(BuildContext context, ChecklistProvider provider, AppStrings s, DashboardWidgetConfig w, String currentLabel) {
    final ctrl = TextEditingController(text: currentLabel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr('Rename space', 'Ubah nama ruang')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.tr('Space label', 'Nama ruang'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.renameDashboardWidget(w.id, ctrl.text);
            },
            child: Text(s.saveBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final sum = provider.lifeOsSummary;
    final s = AppStrings(provider.prefs.language);
    final layout = sum?.layout ?? defaultDashboardLayout;
    final schedTasks = provider.todayGroups.expand((g) => g.tasks).where((t) => t.scheduled).toList();
    final doneCnt = schedTasks.where((t) => t.done).length;
    final pct = schedTasks.isNotEmpty ? (doneCnt / schedTasks.length).clamp(0.0, 1.0) : 0.0;

    final spaceMeta = <String, ({String icon, String defName, String sub, int tab, String? mod})>{
      'w-fin':  (icon: '♡', defName: s.tr('Finance', 'Keuangan'), sub: _fmtRp(sum?.financeBalance ?? 0), tab: 2, mod: null),
      'w-prod': (icon: '☷', defName: s.tr('Productivity', 'Produktivitas'), sub: '${sum?.prodDone ?? 0}/${sum?.prodTotal ?? 0} ${s.tr('tasks', 'tugas')}', tab: 1, mod: null),
      'w-hlth': (icon: '✿', defName: s.navHealth, sub: '${(sum?.waterTodayMl ?? 0).round()} ml', tab: 3, mod: null),
      'w-well': (icon: '☁', defName: s.wellness, sub: sum?.latestMood ?? s.tr('Mood & sleep', 'Suasana hati & tidur'), tab: -1, mod: 'wellness'),
      'w-mens': (icon: '▦', defName: s.menstrual, sub: sum?.latestCycleDay != null ? '${s.tr('Day', 'Hari')} ${sum!.latestCycleDay}' : s.tr('Cycle notes', 'Catatan siklus'), tab: -1, mod: 'menstrual'),
      'w-note': (icon: '✎', defName: s.notes, sub: '${sum?.notesCount ?? 0} ${s.tr('notes', 'catatan')}', tab: -1, mod: 'notes'),
      'w-rew':  (icon: '☆', defName: s.rewards, sub: '${sum?.rewardsBalance ?? 0} ${s.tr('pts', 'poin')}', tab: 7, mod: null),
    };

    final displaySpaces = provider.customizeDashboard ? layout : layout.where((w) => w.visible).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        // 1. Soft Pink Hero Banner (matches DesignRevisionM6.html)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.accentSoft(context),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr('Take it one step at a time.', 'Satu langkah demi satu langkah.'), style: AppTheme.displayStyle(context, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      s.tr("You don't have to do everything today.", 'Kamu tidak harus menyelesaikan semuanya hari ini.'),
                      style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              Text('♡', style: TextStyle(fontSize: 26, color: AppColors.accentDeep(context))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Directly Editable "Your spaces" Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.yourSpaces, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.displayStyle(context, fontSize: 17)),
                  Text(s.tr('Everything you need, in one place.', 'Semua yang kamu butuhkan di satu tempat.'), style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.customizeDashboard)
                  TextButton(
                    onPressed: () => provider.resetDashboardLayout(),
                    child: Text(s.tr('Reset', 'Atur ulang')),
                  ),
                OutlinedButton(
                  key: const Key('edit_spaces_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: provider.customizeDashboard ? AppColors.accent(context) : AppColors.soft(context),
                    foregroundColor: provider.customizeDashboard ? AppColors.accentInk(context) : AppColors.accentDeep(context),
                    side: BorderSide(color: AppColors.line(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => provider.toggleCustomizeDashboard(),
                  child: Text(provider.customizeDashboard ? s.done : s.editBtn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (provider.customizeDashboard)
          ...List.generate(displaySpaces.length, (idx) {
            final w = displaySpaces[idx];
            final meta = spaceMeta[w.id];
            if (meta == null) return const SizedBox.shrink();
            final title = (w.label != null && w.label!.isNotEmpty) ? w.label! : meta.defName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: w.visible ? AppColors.line(context) : AppColors.accent(context).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Text(meta.icon, style: TextStyle(fontSize: 18, color: AppColors.accent(context))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: w.visible ? AppColors.ink(context) : AppColors.muted(context),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: s.tr('Rename', 'Ubah nama'),
                      icon: const Icon(Icons.edit, size: 17),
                      onPressed: () => _showRenameSpaceDialog(context, provider, s, w, title),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_upward, size: 17),
                      onPressed: idx == 0 ? null : () => provider.moveDashboardWidget(w.id, -1),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_downward, size: 17),
                      onPressed: idx == displaySpaces.length - 1 ? null : () => provider.moveDashboardWidget(w.id, 1),
                    ),
                    IconButton(
                      key: Key('space_vis_${w.id}'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(w.visible ? Icons.visibility : Icons.visibility_off, size: 18),
                      onPressed: () => provider.toggleWidgetVisible(w.id),
                    ),
                  ],
                ),
              ),
            );
          })
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displaySpaces.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 86,
            ),
            itemBuilder: (ctx, i) {
              final w = displaySpaces[i];
              final meta = spaceMeta[w.id]!;
              final label = (w.label != null && w.label!.isNotEmpty) ? w.label! : meta.defName;
              return InkWell(
                key: Key('space_card_${w.id}'),
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  if (meta.tab >= 0) {
                    widget.onNavigateTab(meta.tab);
                  } else if (meta.mod != null) {
                    widget.onOpenModule(meta.mod!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.line(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(meta.icon, style: TextStyle(fontSize: 19, color: AppColors.accent(context), height: 1)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(meta.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),

        // 3. Today's Tasks Card with pink progress bar + Open task list
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(s.todayTasks, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.displayStyle(context, fontSize: 16)),
                  ),
                  Text(s.tr('$doneCnt of ${schedTasks.length} done', '$doneCnt dari ${schedTasks.length} selesai'), style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                  IconButton(
                    tooltip: s.tr('Add task', 'Tambah tugas'),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showAddTaskDialog(context, provider, s),
                    icon: Icon(Icons.add_circle_outline, size: 20, color: AppColors.accentDeep(context)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  color: AppColors.accent(context),
                  backgroundColor: AppColors.accentSoft(context),
                ),
              ),
              const SizedBox(height: 6),
              if (schedTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(s.tr('No steps scheduled for today.', 'Belum ada langkah terjadwal hari ini.'), style: TextStyle(color: AppColors.muted(context))),
                ),
              ...schedTasks.take(5).map((t) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => provider.toggleTaskCheck(t.id, !t.done),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 19,
                            color: t.done ? AppColors.accent(context) : AppColors.boxLine(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: t.done ? TextDecoration.lineThrough : null,
                                color: t.done ? AppColors.muted(context) : AppColors.ink(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.soft(context),
                  foregroundColor: AppColors.accentDeep(context),
                  side: BorderSide(color: AppColors.line(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => widget.onNavigateTab(1),
                child: Text('${s.tr('Open task list', 'Buka daftar tugas')} →', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. How are you feeling? (quick emoji check-in)
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('How are you feeling?', 'Bagaimana perasaanmu hari ini?'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ('😊', 'Happy', s.tr('Happy', 'Senang'), 5),
                  ('🙂', 'Calm', s.tr('Calm', 'Tenang'), 4),
                  ('😐', 'Neutral', s.tr('Neutral', 'Biasa'), 3),
                  ('😔', 'Tired', s.tr('Tired', 'Lelah'), 2),
                  ('😣', 'Stressed', s.tr('Stressed', 'Tertekan'), 1),
                ].map((m) {
                  final selected = sum?.wellnessMood == m.$2;
                  return InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () async {
                      await provider.saveQuickAdd('mood', {'mood': m.$2, 'mood_score': m.$4, 'energy': 4, 'stress': 2, 'sleep_hours': 7.0});
                      if (context.mounted) showCalmSnackBar(context, '${s.tr('Mood saved', 'Suasana hati disimpan')}: ${m.$3}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentSoft(context) : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: selected ? AppColors.accent(context) : AppColors.line(context)),
                      ),
                      child: Text(m.$1, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                sum?.latestMood != null
                    ? '${s.tr('Latest', 'Terbaru')}: ${sum!.latestMood} · ${s.tr('Tap any emoji to check in.', 'Ketuk emoji untuk mencatat.')}'
                    : s.tr('A quick check-in. No pressure.', 'Catatan singkat, tanpa tekanan.'),
                style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 5. Little Note as Pinned Motivational Reminder card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(s.littleNoteTitle, style: AppTheme.displayStyle(context, fontSize: 16)),
                        M6Pill(text: '📌 ${s.pinnedReminderBadge}'),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('little_note_edit_btn'),
                    onPressed: () {
                      setState(() {
                        _editingLittleNote = !_editingLittleNote;
                        if (_editingLittleNote) {
                          _littleNoteCtrl.text = sum?.pinnedNoteBody ?? '';
                        }
                      });
                    },
                    child: Text(_editingLittleNote ? s.cancelBtn : '✎ ${s.editBtn}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.soft(context),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.line(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sum?.pinnedNoteTitle ?? s.tr('Motivational Reminder ♡', 'Pengingat Motivasi ♡'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (sum?.pinnedNoteBody != null && sum!.pinnedNoteBody!.trim().isNotEmpty)
                          ? sum.pinnedNoteBody!.trim()
                          : s.defaultMotivation,
                      style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink(context)),
                    ),
                  ],
                ),
              ),
              if (_editingLittleNote) ...[
                const SizedBox(height: 10),
                TextField(
                  key: const Key('little_note_input'),
                  controller: _littleNoteCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                  decoration: InputDecoration(
                    hintText: s.tr('Write a motivational reminder to pin here...', 'Tulis kata motivasi untuk disematkan di sini...'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('little_note_save_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.accentInk(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final body = _littleNoteCtrl.text.trim();
                    if (body.isEmpty) return;
                    await provider.saveQuickAdd('note', {
                      'id': sum?.pinnedNoteId ?? 'little-note-motivation',
                      'title': s.tr('Motivational Reminder ♡', 'Pengingat Motivasi ♡'),
                      'body': body,
                      'category': 'gratitude',
                      'is_pinned': true,
                    });
                    setState(() => _editingLittleNote = false);
                    _littleNoteCtrl.clear();
                    if (context.mounted) showCalmSnackBar(context, s.tr('Pinned reminder updated.', 'Pengingat motivasi diperbarui.'));
                  },
                  child: Text(s.tr('Save reminder', 'Simpan pengingat'), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

extension on LifeOsSummary {
  String? get wellnessMood => latestMood;
}
