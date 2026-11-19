import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

Future<void> showQuickAddSheet(
    BuildContext context, ChecklistProvider provider) async {
  final s = AppStrings(provider.prefs.language);
  final quickAddOptions = [
    (kind: 'task', label: s.tr('Add task', 'Tambah tugas'), icon: '✓'),
    (kind: 'finance', label: s.tr('Income / expense', 'Keuangan'), icon: 'Rp'),
    (kind: 'food', label: s.tr('Food entry', 'Makanan'), icon: '🍽'),
    (kind: 'weight', label: s.tr('Weight entry', 'Berat badan'), icon: '⚖'),
    (kind: 'water', label: s.tr('Water intake', 'Minum air'), icon: '💧'),
    (kind: 'workout', label: s.tr('Workout', 'Olahraga'), icon: '🏃'),
    (kind: 'mood', label: s.tr('Mood check-in', 'Suasana hati'), icon: '◐'),
    (kind: 'menstrual', label: s.tr('Cycle symptom', 'Siklus haid'), icon: '✿'),
    (kind: 'note', label: s.tr('Quick note', 'Catatan cepat'), icon: '✎'),
  ];
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Global Quick Add', 'Tambah Cepat Global'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted(sheetCtx))),
              const SizedBox(height: 2),
              Text(s.tr('Capture from Anywhere', 'Catat Cepat Tanpa Pindah Halaman'),
                  style: AppTheme.displayStyle(sheetCtx, fontSize: 20)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quickAddOptions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 94,
                ),
                itemBuilder: (ctx, i) {
                  final opt = quickAddOptions[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      showQuickAddFormModal(context, provider, opt.kind);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg(sheetCtx),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line(sheetCtx)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(opt.icon, style: const TextStyle(fontSize: 18)),
                          Text(
                            opt.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
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

Future<void> showQuickAddFormModal(
  BuildContext context,
  ChecklistProvider provider,
  String kind,
) async {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  String sel1 = kind == 'finance'
      ? 'expense'
      : (kind == 'mood'
          ? 'Tenang|4'
          : (kind == 'menstrual' ? 'Menstruasi' : ''));
  String sel2 = kind == 'finance' ? 'general' : '';
  String? selectedEnvId;
  bool isPeriodStart = false;

  final titles = {
    'task': 'Add Task',
    'finance': 'Add Income / Expense',
    'food': 'Add Food Entry',
    'weight': 'Add Weight Entry',
    'water': 'Add Water Intake',
    'workout': 'Add Workout',
    'mood': 'Mood Check-in',
    'menstrual': 'Menstrual Symptom Entry',
    'note': 'Create Quick Note',
    'project': 'Tambah Proyek',
    'envelope': 'Tambah Amplop Anggaran',
  };

  if (kind == 'water') c1.text = '250';
  if (kind == 'workout') c2.text = '30';
  if (kind == 'mood') c2.text = '7';
  if (kind == 'menstrual') c1.text = '1';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titles[kind] ?? 'Quick Add',
                      style: AppTheme.displayStyle(ctx, fontSize: 20)),
                  const SizedBox(height: 14),
                  if (kind == 'task')
                    TextField(
                      controller: c1,
                      decoration:
                          const InputDecoration(labelText: 'Nama tugas / langkah'),
                    ),
                  if (kind == 'finance') ...[
                    DropdownButtonFormField<String>(
                      initialValue: sel1,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                      items: const [
                        DropdownMenuItem(
                            value: 'expense', child: Text('Pengeluaran')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Pemasukan')),
                      ],
                      onChanged: (v) => setState(() => sel1 = v ?? 'expense'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: sel2,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: const [
                        DropdownMenuItem(
                            value: 'general', child: Text('Umum')),
                        DropdownMenuItem(
                            value: 'savings', child: Text('Tabungan (Savings)')),
                        DropdownMenuItem(
                            value: 'debt', child: Text('Cicilan / Hutang')),
                      ],
                      onChanged: (v) => setState(() => sel2 = v ?? 'general'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: c1,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Nominal (Rp)'),
                    ),
                    if (provider.envelopes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedEnvId,
                        decoration:
                            const InputDecoration(labelText: 'Amplop (opsional)'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tanpa amplop')),
                          ...provider.envelopes.map((e) => DropdownMenuItem(
                              value: e['id'] as String,
                              child: Text(e['name'] as String))),
                        ],
                        onChanged: (v) => setState(() => selectedEnvId = v),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: c2,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                  ],
                  if (kind == 'food') ...[
                    TextField(
                        controller: c1,
                        decoration:
                            const InputDecoration(labelText: 'Nama makanan')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Kalori (kkal)')),
                  ],
                  if (kind == 'weight') ...[
                    TextField(
                        controller: c1,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Berat badan (kg)')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Lingkar pinggang (cm, opsional)')),
                  ],
                  if (kind == 'water')
                    TextField(
                        controller: c1,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Jumlah air (ml)')),
                  if (kind == 'workout') ...[
                    TextField(
                        controller: c1,
                        decoration:
                            const InputDecoration(labelText: 'Jenis olahraga')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Durasi (menit)')),
                  ],
                  if (kind == 'mood') ...[
                    DropdownButtonFormField<String>(
                      initialValue: sel1,
                      decoration:
                          const InputDecoration(labelText: 'Suasana hati'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Tenang|4', child: Text('Tenang (4/5)')),
                        DropdownMenuItem(
                            value: 'Fokus|5', child: Text('Fokus (5/5)')),
                        DropdownMenuItem(
                            value: 'Biasa|3', child: Text('Biasa (3/5)')),
                        DropdownMenuItem(
                            value: 'Lelah|2', child: Text('Lelah (2/5)')),
                      ],
                      onChanged: (v) =>
                          setState(() => sel1 = v ?? 'Tenang|4'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Durasi tidur (jam)')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c3,
                        decoration: const InputDecoration(
                            labelText: 'Pemicu emosional (pisahkan koma)')),
                  ],
                  if (kind == 'menstrual') ...[
                    DropdownButtonFormField<String>(
                      initialValue: sel1,
                      decoration: const InputDecoration(labelText: 'Fase'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Menstruasi', child: Text('Menstruasi')),
                        DropdownMenuItem(
                            value: 'Fase Folikuler',
                            child: Text('Fase Folikuler')),
                        DropdownMenuItem(
                            value: 'Ovulasi', child: Text('Ovulasi')),
                        DropdownMenuItem(
                            value: 'Fase Luteal', child: Text('Fase Luteal')),
                      ],
                      onChanged: (v) =>
                          setState(() => sel1 = v ?? 'Menstruasi'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c1,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Hari siklus ke-')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        decoration: const InputDecoration(
                            labelText: 'Gejala (pisahkan koma)')),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hari pertama haid?'),
                      value: isPeriodStart,
                      onChanged: (v) =>
                          setState(() => isPeriodStart = v == true),
                    ),
                  ],
                  if (kind == 'note') ...[
                    TextField(
                        controller: c1,
                        decoration: const InputDecoration(labelText: 'Judul')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Isi catatan')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c3,
                        decoration: const InputDecoration(
                            labelText: 'Tags (pisahkan koma)')),
                  ],
                  if (kind == 'project') ...[
                    TextField(
                        controller: c1,
                        decoration:
                            const InputDecoration(labelText: 'Nama proyek')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Progres (%)')),
                  ],
                  if (kind == 'envelope') ...[
                    TextField(
                        controller: c1,
                        decoration:
                            const InputDecoration(labelText: 'Nama amplop')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: c2,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Anggaran bulanan (Rp)')),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: AppColors.accent(ctx),
                        foregroundColor: AppColors.accentInk(ctx),
                      ),
                      onPressed: () async {
                        final data = <String, dynamic>{};
                        if (kind == 'task') {
                          data['name'] = c1.text.trim();
                        } else if (kind == 'finance') {
                          data['type'] = sel1;
                          data['category'] = sel2;
                          data['amount'] = int.tryParse(c1.text.trim()) ?? 0;
                          data['envelope_id'] = selectedEnvId;
                          data['note'] = c2.text.trim();
                        } else if (kind == 'food') {
                          data['name'] = c1.text.trim();
                          data['value_num'] =
                              double.tryParse(c2.text.trim()) ?? 0;
                          data['unit'] = 'kkal';
                        } else if (kind == 'weight') {
                          data['value_num'] =
                              double.tryParse(c1.text.trim()) ?? 0;
                          data['value_num2'] = double.tryParse(c2.text.trim());
                          data['unit'] = 'kg';
                        } else if (kind == 'water') {
                          data['name'] = 'Minum air';
                          data['value_num'] =
                              double.tryParse(c1.text.trim()) ?? 250;
                          data['unit'] = 'ml';
                        } else if (kind == 'workout') {
                          data['name'] = c1.text.trim();
                          data['value_num'] =
                              double.tryParse(c2.text.trim()) ?? 20;
                          data['unit'] = 'mnt';
                        } else if (kind == 'mood') {
                          final parts = sel1.split('|');
                          data['mood'] = parts[0];
                          data['mood_score'] = int.tryParse(parts[1]) ?? 4;
                          data['sleep_hours'] =
                              double.tryParse(c2.text.trim()) ?? 7.0;
                          data['triggers_text'] = c3.text.trim();
                        } else if (kind == 'menstrual') {
                          data['phase'] = sel1;
                          data['cycle_day'] = int.tryParse(c1.text.trim()) ?? 1;
                          data['symptoms'] = c2.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          data['is_period_start'] = isPeriodStart;
                        } else if (kind == 'note') {
                          data['title'] = c1.text.trim();
                          data['body'] = c2.text.trim();
                          data['tags_text'] = c3.text.trim();
                        } else if (kind == 'project') {
                          data['name'] = c1.text.trim();
                          data['progress'] =
                              int.tryParse(c2.text.trim()) ?? 0;
                        } else if (kind == 'envelope') {
                          data['name'] = c1.text.trim();
                          data['monthly_budget'] =
                              int.tryParse(c2.text.trim()) ?? 0;
                        }

                        await provider.saveQuickAdd(kind, data);
                        if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                        }
                        if (context.mounted) {
                          showCalmSnackBar(
                              context, '${titles[kind] ?? 'Entri'} tersimpan.');
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  c1.dispose();
  c2.dispose();
  c3.dispose();
}
