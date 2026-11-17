import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/checklist_repository.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

const _calDaysId = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _calMonthsId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _formatIndoDay(String dayStr) {
  final d = parseLocalDay(dayStr);
  return '${_calDaysId[d.weekday - 1]}, ${d.day} ${_calMonthsId[d.month - 1]}';
}
const _calWeekdaysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _schedWeekdays = [
  (value: 1, label: 'Sen'),
  (value: 2, label: 'Sel'),
  (value: 3, label: 'Rab'),
  (value: 4, label: 'Kam'),
  (value: 5, label: 'Jum'),
  (value: 6, label: 'Sab'),
  (value: 7, label: 'Min'),
];

class TodayView extends StatelessWidget {
  final VoidCallback onGoRewards;

  const TodayView({super.key, required this.onGoRewards});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final total = provider.totalCount;
    final done = provider.doneCount;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;

    String progressMsg = 'Belum ada langkah dijadwalkan pada tanggal ini.';
    if (total > 0) {
      if (provider.isFutureSelectedDate) {
        progressMsg = 'Pratinjau: $total langkah dijadwalkan pada tanggal ini.';
      } else if (done == total) {
        progressMsg = 'Semua selesai hari ini. Kamu boleh istirahat.';
      } else if (done == 0) {
        progressMsg = 'Belum mulai juga tidak apa-apa. Pilih satu yang paling kecil.';
      } else {
        progressMsg = 'Sudah $done langkah hari ini. Lanjut kalau masih ada tenaga.';
      }
    }

    final focusTask = provider.nextFocusTask;
    final isToday = provider.selectedDate == provider.currentDay;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 0. Schedule Calendar Card
        if (provider.showCalendar) ...[
          const _ChecklistCalendarCard(),
          const SizedBox(height: 12),
        ],

        // 0b. Selected Date Banner (past or future)
        if (!isToday) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: provider.isFutureSelectedDate
                  ? AppColors.goldSoft(context)
                  : AppColors.accentSoft(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.isFutureSelectedDate
                        ? 'Pratinjau jadwal mendatang (${_formatIndoDay(provider.selectedDate)}). Belum bisa dicentang.'
                        : 'Melihat catatan ${_formatIndoDay(provider.selectedDate)}.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: provider.isFutureSelectedDate
                          ? AppColors.goldInk(context)
                          : AppColors.ink(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: AppColors.surface(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () => provider.backToToday(),
                  child: Text(
                    'Kembali ke hari ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 1. Progress Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$done',
                      style: AppTheme.displayStyle(context, fontSize: 32),
                      children: [
                        TextSpan(
                          text: ' dari $total langkah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '$pct',
                      style: AppTheme.displayStyle(context, fontSize: 32),
                      children: [
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CalmProgressBar(percent: pct),
              const SizedBox(height: 10),
              Text(
                progressMsg,
                style: TextStyle(color: AppColors.muted(context), fontSize: 15),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.line(context)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hari berat', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'Tampilkan hanya langkah inti (★).',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: provider.liteMode,
                    activeTrackColor: AppColors.accent(context),
                    onChanged: (_) => provider.toggleLiteMode(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Focus Card ("Mulai dari sini")
        if (!provider.editMode && total > 0 && !provider.isFutureSelectedDate) ...[
          CalmCard(
            color: AppColors.accentSoft(context),
            borderColor: Colors.transparent,
            child: focusTask == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELESAI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.muted(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua langkah hari ini sudah beres.',
                        style: AppTheme.displayStyle(context, fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cek tab Hadiah kalau mau mengambil sesuatu.',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: AppColors.accent(context),
                          foregroundColor: AppColors.accentInk(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: onGoRewards,
                        child: const Text('Lihat hadiah', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MULAI DARI SINI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.muted(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        focusTask.name,
                        style: AppTheme.displayStyle(context, fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cukup yang ini dulu. Yang lain boleh menunggu.',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppColors.accent(context),
                              foregroundColor: AppColors.accentInk(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => provider.toggleTaskCheck(focusTask.id, true),
                            child: const Text('Sudah selesai', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppColors.surface(context),
                              foregroundColor: AppColors.ink(context),
                              side: BorderSide(color: AppColors.line(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => provider.skipFocusTask(focusTask.id),
                            child: const Text('Lewati dulu', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Edit Mode Note
        if (provider.editMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.goldSoft(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Mode ubah aktif. Bintang menandai langkah inti. Nonaktifkan menyembunyikan langkah, riwayatnya tetap tersimpan.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Groups & Tasks
        ...provider.todayGroups.asMap().entries.map((entry) {
          final gIdx = entry.key;
          final g = entry.value;
          final isFirstGroup = gIdx == 0;
          final isLastGroup = gIdx == provider.todayGroups.length - 1;
          final visible = g.tasks
              .where((t) =>
                  provider.editMode ||
                  (t.scheduled && (!provider.liteMode || t.core)))
              .toList();
          if (!provider.editMode && visible.isEmpty) return const SizedBox.shrink();
          final gDone = visible.where((t) => t.done).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CalmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.editMode)
                    Row(
                      children: [
                        Expanded(
                          child: _InlineTextField(
                            initialValue: g.name,
                            hint: 'Nama kelompok',
                            bold: true,
                            onSubmitted: (val) => provider.updateGroupName(g, val),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          key: Key('move_group_up_${g.id}'),
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                          padding: EdgeInsets.zero,
                          tooltip: 'Pindah ke atas',
                          onPressed: isFirstGroup
                              ? null
                              : () => provider.moveGroup(g.id, -1),
                          icon: Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: isFirstGroup
                                ? AppColors.line(context)
                                : AppColors.muted(context),
                          ),
                        ),
                        IconButton(
                          key: Key('move_group_down_${g.id}'),
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                          padding: EdgeInsets.zero,
                          tooltip: 'Pindah ke bawah',
                          onPressed: isLastGroup
                              ? null
                              : () => provider.moveGroup(g.id, 1),
                          icon: Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: isLastGroup
                                ? AppColors.line(context)
                                : AppColors.muted(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(color: AppColors.line(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            await provider.deactivateGroup(g.id);
                            if (context.mounted) {
                              showCalmSnackBar(
                                context,
                                'Kelompok dinonaktifkan. Riwayat tetap tersimpan.',
                                onUndo: () => provider.reactivateGroup(g.id),
                              );
                            }
                          },
                          child: Text(
                            'Nonaktifkan',
                            style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g.name, style: AppTheme.displayStyle(context, fontSize: 17)),
                        Text(
                          '$gDone/${visible.length}',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  ...List.generate(visible.length, (idx) {
                    final t = visible[idx];
                    return Column(
                      children: [
                        if (idx > 0) Divider(height: 1, color: AppColors.line(context)),
                        if (provider.editMode)
                          _EditTaskRow(task: t)
                        else
                          _CheckTaskRow(
                            task: t,
                            showStar: t.core && !provider.liteMode,
                            readOnly: provider.isFutureSelectedDate,
                          ),
                      ],
                    );
                  }),
                  if (provider.editMode) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: AppColors.line(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => provider.addTask(g.id),
                        child: Text(
                          '+ Tambah langkah',
                          style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        if (!provider.editMode && provider.offDayCount > 0) ...[
          CalmCard(
            color: AppColors.surface(context),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.offDayCount} aktivitas mingguan/bulanan dijadwalkan di tanggal lain.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.setEditMode(true),
                  child: Text(
                    'Lihat / Ubah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (provider.editMode)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                side: BorderSide(color: AppColors.line(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => provider.addGroup(),
              child: Text(
                '+ Tambah kelompok',
                style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
              ),
            ),
          ),

        const SizedBox(height: 16),
        Center(
          child: Text(
            'Tersimpan di perangkat ini',
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _FreqPill extends StatelessWidget {
  final String freq;
  final String label;

  const _FreqPill({required this.freq, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (freq == 'weekly') {
      bg = AppColors.accentSoft(context);
      fg = AppColors.accent(context);
    } else if (freq == 'monthly') {
      bg = AppColors.goldSoft(context);
      fg = AppColors.goldInk(context);
    } else {
      bg = AppColors.tabBg(context);
      fg = AppColors.muted(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CheckTaskRow extends StatelessWidget {
  final TaskItem task;
  final bool showStar;
  final bool readOnly;

  const _CheckTaskRow({
    required this.task,
    required this.showStar,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChecklistProvider>();
    return InkWell(
      onTap: readOnly ? null : () => provider.toggleTaskCheck(task.id, !task.done),
      child: Opacity(
        opacity: readOnly ? 0.72 : 1.0,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: task.done ? AppColors.accent(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 2,
                    color: task.done ? AppColors.accent(context) : AppColors.boxLine(context),
                  ),
                ),
                child: task.done
                    ? Icon(Icons.check, size: 18, color: AppColors.accentInk(context))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: task.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: task.done ? AppColors.muted(context) : AppColors.ink(context),
                          decoration: task.done ? TextDecoration.lineThrough : null,
                        ),
                        children: [
                          if (showStar)
                            TextSpan(
                              text: '  ★ inti',
                              style: TextStyle(
                                color: AppColors.goldInk(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (task.freq != 'daily') ...[
                      const SizedBox(height: 4),
                      _FreqPill(freq: task.freq, label: task.freqLabel),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditTaskRow extends StatelessWidget {
  final TaskItem task;

  const _EditTaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChecklistProvider>();
    final freqLabel = task.freqLabel;
    final bool isWeekly = task.freq == 'weekly';
    final bool isMonthly = task.freq == 'monthly';
    final Color calBg = isWeekly
        ? AppColors.accentSoft(context)
        : (isMonthly ? AppColors.goldSoft(context) : AppColors.surface(context));
    final Color calBorder = isWeekly
        ? AppColors.accent(context)
        : (isMonthly ? AppColors.gold(context) : AppColors.line(context));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => provider.toggleTaskCore(task),
                icon: Text(
                  task.core ? '★' : '☆',
                  style: TextStyle(
                    fontSize: 20,
                    color: task.core ? AppColors.gold(context) : AppColors.muted(context),
                  ),
                ),
              ),
              Expanded(
                child: _InlineTextField(
                  initialValue: task.name,
                  hint: 'Nama langkah',
                  onSubmitted: (val) => provider.updateTaskName(task, val),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: freqLabel,
                child: Semantics(
                  label: freqLabel,
                  button: true,
                  child: InkWell(
                    key: Key('sched_btn_${task.id}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _showScheduleSheet(context, provider, task);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: calBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: calBorder),
                      ),
                      child: const Text('📅', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(color: AppColors.line(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await provider.deactivateTask(task.id);
                  if (context.mounted) {
                    showCalmSnackBar(
                      context,
                      'Langkah dinonaktifkan. Riwayat tetap tersimpan.',
                      onUndo: () => provider.reactivateTask(task.id),
                    );
                  }
                },
                child: Text(
                  'Nonaktifkan',
                  style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FreqPill(freq: task.freq, label: freqLabel),
                if (!task.scheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tabBg(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Bukan tanggal ini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCalendarCard extends StatelessWidget {
  const _ChecklistCalendarCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final year = provider.checklistCalYear;
    final month = provider.checklistCalMonth;
    final firstOfMonth = DateTime(year, month, 1);
    final offset = firstOfMonth.weekday - 1; // 0 = Monday
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final dots = provider.monthScheduleDots;
    final isSelectedToday = provider.selectedDate == provider.currentDay;

    return CalmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => provider.changeChecklistCalMonth(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Bulan sebelumnya',
              ),
              Expanded(
                child: Text(
                  '${_calMonthsId[month - 1]} $year',
                  textAlign: TextAlign.center,
                  style: AppTheme.displayStyle(context, fontSize: 17),
                ),
              ),
              if (!isSelectedToday)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => provider.backToToday(),
                  child: Text(
                    'Hari ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => provider.changeChecklistCalMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Bulan berikutnya',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: _calWeekdaysShort
                .map(
                  (w) => Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (ctx, index) {
              final dayNum = index - offset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final dayKey = formatLocalDay(DateTime(year, month, dayNum));
              final isSelected = dayKey == provider.selectedDate;
              final isTodayCell = dayKey == provider.currentDay;
              final dotInfo = dots[dayKey];
              final hasWeekly = dotInfo?.hasWeekly ?? false;
              final hasMonthly = dotInfo?.hasMonthly ?? false;

              return GestureDetector(
                onTap: () => provider.selectChecklistDate(dayKey),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentSoft(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: isSelected || isTodayCell ? 1.5 : 1,
                      color: isSelected
                          ? AppColors.accent(context)
                          : (isTodayCell
                              ? AppColors.gold(context)
                              : Colors.transparent),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isTodayCell
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.accent(context)
                              : AppColors.ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasWeekly)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.accent(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasMonthly)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.gold(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (!hasWeekly && !hasMonthly)
                            const SizedBox(height: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Mingguan',
                style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
              ),
              const SizedBox(width: 14),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.gold(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Bulanan',
                style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showScheduleSheet(
  BuildContext context,
  ChecklistProvider provider,
  TaskItem task,
) async {
  String freq = task.freq;
  final Set<int> weeklyDays = task.freq == 'weekly' && task.freqDays.isNotEmpty
      ? task.freqDays.toSet()
      : {DateTime.now().weekday};
  final Set<int> monthlyDays = task.freq == 'monthly' && task.freqDays.isNotEmpty
      ? task.freqDays.toSet()
      : {DateTime.now().day};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final List<int> activeDays = freq == 'weekly'
              ? (weeklyDays.toList()..sort())
              : (freq == 'monthly' ? (monthlyDays.toList()..sort()) : const []);
          final summaryText = formatFreqLabel(freq, activeDays);

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atur Jadwal Aktivitas',
                    style: AppTheme.displayStyle(ctx, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.name,
                    style: TextStyle(fontSize: 14, color: AppColors.muted(ctx)),
                  ),
                  const SizedBox(height: 14),
                  CalmSegmentedControl<String>(
                    items: const [
                      (value: 'daily', label: 'Harian'),
                      (value: 'weekly', label: 'Mingguan'),
                      (value: 'monthly', label: 'Bulanan'),
                    ],
                    selected: freq,
                    onChanged: (v) => setState(() => freq = v),
                  ),
                  const SizedBox(height: 16),
                  if (freq == 'daily')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg(ctx),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Aktivitas ini akan muncul setiap hari di daftar ceklis.',
                        style: TextStyle(fontSize: 14, color: AppColors.muted(ctx)),
                      ),
                    ),
                  if (freq == 'weekly') ...[
                    Text(
                      'Pilih hari dalam seminggu:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted(ctx),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _schedWeekdays.map((wd) {
                        final selected = weeklyDays.contains(wd.value);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                if (weeklyDays.length > 1) {
                                  weeklyDays.remove(wd.value);
                                }
                              } else {
                                weeklyDays.add(wd.value);
                              }
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accent(ctx)
                                  : AppColors.surface(ctx),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accent(ctx)
                                    : AppColors.line(ctx),
                              ),
                            ),
                            child: Text(
                              wd.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.accentInk(ctx)
                                    : AppColors.ink(ctx),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (freq == 'monthly') ...[
                    Text(
                      'Pilih tanggal dalam sebulan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted(ctx),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 31,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (c, idx) {
                        final dNum = idx + 1;
                        final selected = monthlyDays.contains(dNum);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                if (monthlyDays.length > 1) {
                                  monthlyDays.remove(dNum);
                                }
                              } else {
                                monthlyDays.add(dNum);
                              }
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.goldSoft(c)
                                  : AppColors.surface(c),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? AppColors.gold(c)
                                    : AppColors.line(c),
                              ),
                            ),
                            child: Text(
                              '$dNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected
                                    ? AppColors.goldInk(c)
                                    : AppColors.ink(c),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.tabBg(ctx),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Jadwal: $summaryText',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink(ctx),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: AppColors.line(ctx)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: AppColors.muted(ctx)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: AppColors.accent(ctx),
                          foregroundColor: AppColors.accentInk(ctx),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await provider.updateTaskSchedule(task, freq, activeDays);
                          if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                          }
                        },
                        child: const Text(
                          'Simpan jadwal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _InlineTextField extends StatefulWidget {
  final String initialValue;
  final String hint;
  final bool bold;
  final ValueChanged<String> onSubmitted;

  const _InlineTextField({
    required this.initialValue,
    required this.hint,
    this.bold = false,
    required this.onSubmitted,
  });

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        widget.onSubmitted(_ctrl.text.trim());
      }
    });
  }

  @override
  void didUpdateWidget(covariant _InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_focus.hasFocus) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      style: TextStyle(fontWeight: widget.bold ? FontWeight.w600 : FontWeight.w400),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: AppColors.bg(context),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(context)),
        ),
      ),
      onSubmitted: (val) => widget.onSubmitted(val.trim()),
    );
  }
}
