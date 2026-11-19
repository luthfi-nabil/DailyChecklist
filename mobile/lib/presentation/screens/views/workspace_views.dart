import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

String fmtRp(num n) {
  final val = n.round();
  final s = val.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return val < 0 ? '-Rp $s' : 'Rp $s';
}

class _OptionalReportChart extends StatelessWidget {
  final List<({String label, int value})> bars;
  const _OptionalReportChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final show = context.watch<ChecklistProvider>().prefs.showReportCharts;
    if (!show || bars.isEmpty) return const SizedBox.shrink();
    final maxVal = bars.fold<int>(1, (m, b) => b.value > m ? b.value : m);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CalmCard(
        child: SizedBox(
          height: 112,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((b) {
              final h = ((b.value / maxVal) * 70).clamp(4.0, 70.0);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: h,
                      decoration: BoxDecoration(
                        color: AppColors.accent(context),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Interactive Pomodoro + Projects card shown in Tasks / Productivity
class ProductivityExtrasCard extends StatefulWidget {
  const ProductivityExtrasCard({super.key});

  @override
  State<ProductivityExtrasCard> createState() => _ProductivityExtrasCardState();
}

class _ProductivityExtrasCardState extends State<ProductivityExtrasCard> {
  int _sec = 25 * 60;
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle(ChecklistProvider provider) {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_sec <= 1) {
        _timer?.cancel();
        setState(() {
          _running = false;
          _sec = 25 * 60;
        });
        await provider.saveQuickAdd('focus', {'minutes': 25, 'note': 'Pomodoro'});
      } else {
        setState(() => _sec--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final st = AppStrings(provider.prefs.language);
    final m = (_sec ~/ 60).toString().padLeft(2, '0');
    final s = (_sec % 60).toString().padLeft(2, '0');
    final focusMin = provider.lifeOsSummary?.focusMinutesToday ?? 0;

    return CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(st.tr('Focus Pomodoro', 'Pengatur Fokus'), style: AppTheme.displayStyle(context, fontSize: 16)),
              M6Pill(text: '${focusMin}m ${st.tr('today', 'hari ini')}'),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('$m:$s', style: AppTheme.displayStyle(context, fontSize: 32)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(st.tr('One thing at a time.', 'Satu hal pada satu waktu.'), style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: m6PrimaryButtonStyle(context),
              onPressed: () => _toggle(provider),
              child: Text(_running ? st.tr('Pause', 'Jeda') : st.tr('Start focus', 'Mulai fokus')),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: m6GhostButtonStyle(context),
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _running = false;
                      _sec = 25 * 60;
                    });
                  },
                  child: Text(st.tr('Reset', 'Atur ulang')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: m6GhostButtonStyle(context),
                  onPressed: () async {
                    await provider.saveQuickAdd('focus', {'minutes': 25, 'note': 'Focus session'});
                    if (context.mounted) showCalmSnackBar(context, st.tr('25m focus logged.', 'Fokus 25m tercatat.'));
                  },
                  child: Text(st.tr('Log 25m', 'Catat 25m')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Complete Finance Workspace (Money Tab)
class FinanceWorkspaceView extends StatefulWidget {
  const FinanceWorkspaceView({super.key});

  @override
  State<FinanceWorkspaceView> createState() => _FinanceWorkspaceViewState();
}

class _FinanceWorkspaceViewState extends State<FinanceWorkspaceView> {
  String _typeFilter = 'all';
  String _search = '';
  String _formType = 'expense';
  String _formCat = 'general';
  String? _formEnvId;
  String? _envEditId;
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _envNameCtrl = TextEditingController();
  final _envBudCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _itemAmtCtrl = TextEditingController();
  String _itemKind = 'goal';

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    _envNameCtrl.dispose();
    _envBudCtrl.dispose();
    _itemCtrl.dispose();
    _itemAmtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final rep = provider.moduleReport?.module == 'finance' ? provider.moduleReport : null;
    final inc = (rep?.metrics['income'] as num?)?.toInt() ?? 0;
    final exp = (rep?.metrics['expense'] as num?)?.toInt() ?? 0;
    final sav = (rep?.metrics['savings'] as num?)?.toInt() ?? 0;
    final debt = (rep?.metrics['debt'] as num?)?.toInt() ?? 0;
    final envUsage = rep?.breakdown ?? [];
    final entries = (rep?.entries ?? []).where((e) {
      if (_typeFilter != 'all' && e['type'] != _typeFilter) return false;
      if (_search.isNotEmpty) {
        final txt = '${e['note'] ?? ''} ${e['category'] ?? ''}'.toLowerCase();
        if (!txt.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();

    final net = (rep?.metrics['net'] as num?)?.toInt() ?? (inc - exp);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.25,
          children: [
            _MetricCard(label: s.tr('Available balance', 'Saldo bersih'), value: fmtRp(net)),
            _MetricCard(label: s.tr('Income', 'Pemasukan'), value: fmtRp(inc)),
            _MetricCard(label: s.tr('Expense', 'Pengeluaran'), value: fmtRp(exp)),
            _MetricCard(label: s.tr('Savings', 'Tabungan'), value: fmtRp(sav)),
          ],
        ),
        const SizedBox(height: 12),
        _OptionalReportChart(bars: [
          (label: s.tr('In', 'Masuk'), value: inc),
          (label: s.tr('Out', 'Keluar'), value: exp),
          (label: s.tr('Sav', 'Tabung'), value: sav),
          (label: s.tr('Debt', 'Utang'), value: debt),
        ]),
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Log Transaction', 'Catat Transaksi'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _formType,
                      decoration: m6InputDecoration(context, label: s.tr('Type', 'Tipe')),
                      items: [
                        DropdownMenuItem(value: 'expense', child: Text(s.tr('Expense', 'Pengeluaran'), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'income', child: Text(s.tr('Income', 'Pemasukan'), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _formType = v ?? 'expense'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _formCat,
                      decoration: m6InputDecoration(context, label: s.tr('Category', 'Kategori')),
                      items: [
                        DropdownMenuItem(value: 'general', child: Text(s.tr('General', 'Umum'), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'savings', child: Text(s.tr('Savings', 'Tabungan'), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'debt', child: Text(s.tr('Debt', 'Utang'), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _formCat = v ?? 'general'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.envelopes.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _formEnvId,
                  decoration: m6InputDecoration(context, label: s.tr('Envelope (optional)', 'Amplop (opsional)')),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(s.tr('No envelope', 'Tanpa amplop'))),
                    ...provider.envelopes.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String))),
                  ],
                  onChanged: (v) => setState(() => _formEnvId = v),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amtCtrl,
                      keyboardType: TextInputType.number,
                      decoration: m6InputDecoration(context, label: s.tr('Amount (Rp)', 'Jumlah (Rp)')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      decoration: m6InputDecoration(context, label: s.tr('Note', 'Catatan')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: m6PrimaryButtonStyle(context),
                onPressed: () async {
                  final amt = int.tryParse(_amtCtrl.text.trim()) ?? 0;
                  if (amt <= 0) return;
                  await provider.saveQuickAdd('finance', {
                    'type': _formType,
                    'category': _formCat,
                    'envelope_id': _formEnvId,
                    'amount': amt,
                    'note': _noteCtrl.text.trim(),
                  });
                  _amtCtrl.clear();
                  _noteCtrl.clear();
                  if (context.mounted) showCalmSnackBar(context, s.tr('Transaction saved.', 'Transaksi disimpan.'));
                },
                child: Text(s.tr('Save transaction', 'Simpan transaksi')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Envelopes
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.tr('Envelope budget', 'Anggaran amplop'),
                      style: AppTheme.displayStyle(context, fontSize: 16),
                    ),
                  ),
                  if (_envEditId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _envEditId = null;
                          _envNameCtrl.clear();
                          _envBudCtrl.clear();
                        });
                      },
                      child: Text(s.cancelBtn),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('env_name_input'),
                      controller: _envNameCtrl,
                      decoration: m6InputDecoration(context, hint: s.tr('Food / Transport', 'Makan / Transportasi')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('env_budget_input'),
                      controller: _envBudCtrl,
                      keyboardType: TextInputType.number,
                      decoration: m6InputDecoration(context, hint: s.tr('Budget', 'Anggaran')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('env_save_btn'),
                    style: _envEditId != null ? m6PrimaryButtonStyle(context) : m6GhostButtonStyle(context),
                    onPressed: () async {
                      if (_envNameCtrl.text.trim().isEmpty) return;
                      final wasEdit = _envEditId != null;
                      await provider.saveQuickAdd('envelope', {
                        if (_envEditId != null) 'id': _envEditId,
                        'name': _envNameCtrl.text.trim(),
                        'monthly_budget': int.tryParse(_envBudCtrl.text.trim()) ?? 0,
                      });
                      setState(() {
                        _envEditId = null;
                        _envNameCtrl.clear();
                        _envBudCtrl.clear();
                      });
                      if (context.mounted) {
                        showCalmSnackBar(
                          context,
                          wasEdit
                              ? s.tr('Envelope updated.', 'Amplop diperbarui.')
                              : s.tr('Envelope saved.', 'Amplop disimpan.'),
                        );
                      }
                    },
                    child: Text(_envEditId != null ? s.saveBtn : '+ ${s.tr('Add', 'Tambah')}'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...envUsage.map((e) {
                final envId = e['id'] as String;
                final envName = e['name'] as String;
                final envBudget = (e['budget'] as num).toInt();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              envName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: M6Pill(text: '${fmtRp(e['used'] as num)} / ${fmtRp(envBudget)}'),
                          ),
                          IconButton(
                            key: Key('env_edit_$envId'),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: s.editBtn,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            onPressed: () {
                              setState(() {
                                _envEditId = envId;
                                _envNameCtrl.text = envName;
                                _envBudCtrl.text = envBudget.toString();
                              });
                            },
                          ),
                          IconButton(
                            key: Key('env_del_$envId'),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: s.deleteBtn,
                            icon: Icon(Icons.close, size: 17, color: AppColors.miss(context)),
                            onPressed: () async {
                              if (_envEditId == envId) {
                                setState(() {
                                  _envEditId = null;
                                  _envNameCtrl.clear();
                                  _envBudCtrl.clear();
                                });
                              }
                              await provider.softDeleteItem('finance_envelopes', envId);
                              if (context.mounted) showCalmSnackBar(context, s.tr('Envelope deleted.', 'Amplop dihapus.'));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      CalmProgressBar(percent: (e['pct'] as num).round().clamp(0, 100), height: 7),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Savings Goals & Recurring Bills
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Savings goals & bills', 'Target tabungan & tagihan'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _itemCtrl, decoration: m6InputDecoration(context, hint: s.tr('Goal / Bill', 'Target / Tagihan')))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _itemKind,
                    items: [
                      DropdownMenuItem(value: 'goal', child: Text(s.tr('Goal', 'Target'))),
                      DropdownMenuItem(value: 'bill', child: Text(s.tr('Bill', 'Tagihan'))),
                      DropdownMenuItem(value: 'debt', child: Text(s.tr('Debt', 'Cicilan'))),
                    ],
                    onChanged: (v) => setState(() => _itemKind = v ?? 'goal'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: TextField(controller: _itemAmtCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, hint: s.tr('Amount / Target', 'Jumlah / Target')))),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () async {
                      final nm = _itemCtrl.text.trim();
                      if (nm.isEmpty) return;
                      final amt = int.tryParse(_itemAmtCtrl.text.trim()) ?? 0;
                      if (_itemKind == 'goal') {
                        await provider.saveQuickAdd('savings_goal', {'name': nm, 'target_amount': amt, 'current_amount': 0});
                      } else {
                        await provider.saveQuickAdd('recurring_bill', {'name': nm, 'kind': _itemKind, 'amount': amt, 'due_day': DateTime.now().day});
                      }
                      _itemCtrl.clear();
                      _itemAmtCtrl.clear();
                    },
                    child: Text('+ ${s.tr('Add', 'Tambah')}'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...provider.savingsGoals.map((g) {
                final cur = (g['current_amount'] as num).toInt();
                final tgt = (g['target_amount'] as num).toInt();
                final pct = tgt > 0 ? ((cur / tgt) * 100).round().clamp(0, 100) : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.soft(context),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.line(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  style: m6GhostButtonStyle(context),
                                  onPressed: () => provider.saveQuickAdd('savings_goal', {...g, 'current_amount': cur + 100000}),
                                  child: const Text('+100k'),
                                ),
                                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('savings_goals', g['id'] as String)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CalmProgressBar(percent: pct, height: 7),
                        const SizedBox(height: 4),
                        Text('${fmtRp(cur)} / ${fmtRp(tgt)} ($pct%)', style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
                      ],
                    ),
                  ),
                );
              }),
              ...provider.recurringBills.map((b) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${b['name']} (${b['kind']})'),
                    subtitle: Text('${fmtRp(b['amount'] as num)} · ${s.tr('Day', 'Tgl')} ${b['due_day']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style: m6GhostButtonStyle(context),
                          onPressed: () => provider.saveQuickAdd('recurring_bill', {...b, 'is_paid': b['is_paid'] == 1 ? 0 : 1}),
                          child: Text(b['is_paid'] == 1 ? s.tr('Paid ✓', 'Lunas ✓') : s.tr('Unpaid', 'Belum lunas')),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('recurring_bills', b['id'] as String)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Transaction History + Search & Filter
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${s.tr('Recent transactions', 'Transaksi terbaru')} (${entries.length})',
                      style: AppTheme.displayStyle(context, fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: CalmSegmentedControl<String>(
                      items: [
                        (value: 'all', label: s.tr('All', 'Semua')),
                        (value: 'income', label: s.tr('In', 'Masuk')),
                        (value: 'expense', label: s.tr('Out', 'Keluar')),
                      ],
                      selected: _typeFilter,
                      onChanged: (v) => setState(() => _typeFilter = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: m6InputDecoration(context, hint: s.tr('Search transactions...', 'Cari transaksi...'), prefixIcon: const Icon(Icons.search, size: 18)),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty) Text(s.tr('No entries found.', 'Belum ada transaksi.'), style: TextStyle(color: AppColors.muted(context))),
              ...entries.take(25).map((e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e['note'] ?? e['category']}'),
                    subtitle: Text('${e['day']} · ${e['category']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${e['type'] == 'income' ? '+' : '-'}${fmtRp(e['amount'] as num)}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: e['type'] == 'income' ? AppColors.accentDeep(context) : AppColors.miss(context)),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('finance_entries', e['id'] as String)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Complete Health Workspace (Health Tab)
class HealthWorkspaceView extends StatefulWidget {
  const HealthWorkspaceView({super.key});

  @override
  State<HealthWorkspaceView> createState() => _HealthWorkspaceViewState();
}

class _HealthWorkspaceViewState extends State<HealthWorkspaceView> {
  String _mealSlot = 'breakfast';
  final _foodNameCtrl = TextEditingController();
  final _foodKcalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  String _measArea = 'Waist';
  final _measValCtrl = TextEditingController();
  final _woNameCtrl = TextEditingController();
  final _woMinCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _foodKcalCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _measValCtrl.dispose();
    _woNameCtrl.dispose();
    _woMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final rep = provider.moduleReport?.module == 'health' ? provider.moduleReport : null;
    final rows = rep?.entries ?? [];
    final foods = rows.where((r) => r['kind'] == 'food').toList();
    final workouts = rows.where((r) => r['kind'] == 'workout').toList();
    final goalCups = provider.prefs.waterGoalGlasses;
    final waterTodayMl = provider.lifeOsSummary?.waterTodayMl ?? 0;
    final filledCups = (waterTodayMl / 250).round();
    final latestWeight = provider.lifeOsSummary?.latestWeight;
    final totalWorkoutMin = workouts.fold<int>(0, (s, w) => s + ((w['value_num'] as num?)?.round() ?? 0));
    final latestMeas = (rep?.metrics['latestMeasurements'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(child: M6StatBox(label: s.tr('Current weight', 'Berat saat ini'), value: latestWeight != null ? '$latestWeight kg' : '— kg')),
            const SizedBox(width: 8),
            Expanded(child: M6StatBox(label: s.tr('Water today', 'Air hari ini'), value: '$filledCups / $goalCups')),
            const SizedBox(width: 8),
            Expanded(child: M6StatBox(label: s.tr('Movement', 'Aktivitas'), value: '$totalWorkoutMin m')),
          ],
        ),
        const SizedBox(height: 12),

        // Water Cups Interactive Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.tr('Water Intake', 'Minum Air'), style: AppTheme.displayStyle(context, fontSize: 16)),
                  M6Pill(text: '$filledCups/$goalCups ${s.tr('glasses', 'gelas')} · ${waterTodayMl.round()} ml'),
                ],
              ),
              const SizedBox(height: 8),
              CalmProgressBar(
                percent: goalCups > 0 ? ((filledCups / goalCups) * 100).round().clamp(0, 100) : 0,
                height: 7,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(goalCups, (i) {
                  final filled = i < filledCups;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => provider.saveQuickAdd('water', {'name': 'Water', 'value_num': 250, 'unit': 'ml'}),
                    child: Container(
                      width: 34,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.tabBg(context) : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: filled ? AppColors.accent(context) : AppColors.line(context)),
                      ),
                      child: const Text('💧'),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    style: m6PrimaryButtonStyle(context),
                    onPressed: () => provider.saveQuickAdd('water', {'name': 'Water', 'value_num': 250, 'unit': 'ml'}),
                    child: Text('+ ${s.tr('Add a glass', 'Tambah segelas')}'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () => provider.saveQuickAdd('water', {'name': 'Water', 'value_num': 500, 'unit': 'ml'}),
                    child: const Text('+ 500 ml'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Food Diary
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Food diary', 'Catatan makan'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _mealSlot,
                decoration: m6InputDecoration(context, label: s.tr('Meal', 'Waktu makan')),
                items: [
                  DropdownMenuItem(value: 'breakfast', child: Text(s.tr('Breakfast', 'Sarapan'))),
                  DropdownMenuItem(value: 'lunch', child: Text(s.tr('Lunch', 'Makan siang'))),
                  DropdownMenuItem(value: 'dinner', child: Text(s.tr('Dinner', 'Makan malam'))),
                  DropdownMenuItem(value: 'snacks', child: Text(s.tr('Snacks', 'Camilan'))),
                ],
                onChanged: (v) => setState(() => _mealSlot = v ?? 'breakfast'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _foodNameCtrl, decoration: m6InputDecoration(context, hint: s.tr('Food name', 'Nama makanan')))),
                  const SizedBox(width: 6),
                  SizedBox(width: 82, child: TextField(controller: _foodKcalCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, hint: 'kcal'))),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: m6PrimaryButtonStyle(context),
                    onPressed: () async {
                      if (_foodNameCtrl.text.trim().isEmpty) return;
                      await provider.saveQuickAdd('food', {
                        'meal_slot': _mealSlot,
                        'name': _foodNameCtrl.text.trim(),
                        'value_num': double.tryParse(_foodKcalCtrl.text.trim()) ?? 0,
                        'unit': 'kcal',
                      });
                      _foodNameCtrl.clear();
                      _foodKcalCtrl.clear();
                    },
                    child: const Text('+'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...foods.take(12).map((f) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${f['name'] ?? 'Meal'} (${f['meal_slot'] ?? 'snacks'})'),
                    subtitle: Text('${f['day']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        M6Pill(text: '${(f['value_num'] as num).round()} kcal'),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('health_entries', f['id'] as String)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Weight Progress & Measurements
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight progress', style: AppTheme.displayStyle(context, fontSize: 16)),
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
                    Text('${latestWeight ?? '—'} kg', style: AppTheme.displayStyle(context, fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      'Current · Goal ${provider.prefs.weightGoalKg.isNotEmpty ? provider.prefs.weightGoalKg : '—'} kg',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    CalmProgressBar(
                      percent: (latestWeight != null && double.tryParse(provider.prefs.weightGoalKg) != null && latestWeight > 0)
                          ? ((double.parse(provider.prefs.weightGoalKg) / latestWeight) * 100).round().clamp(0, 100)
                          : 35,
                      height: 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, label: 'Weight (kg)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _goalWeightCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, label: 'Goal (${provider.prefs.weightGoalKg})'))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: m6PrimaryButtonStyle(context),
                    onPressed: () async {
                      final w = double.tryParse(_weightCtrl.text.trim());
                      if (_goalWeightCtrl.text.trim().isNotEmpty) {
                        await provider.updateAppPreferences(weightGoalKg: _goalWeightCtrl.text.trim());
                      }
                      if (w != null && w > 0) {
                        await provider.saveQuickAdd('weight', {'value_num': w, 'unit': 'kg'});
                      }
                      _weightCtrl.clear();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _measArea,
                      decoration: m6InputDecoration(context),
                      items: const ['Waist', 'Hip', 'Chest', 'Arm', 'Thigh'].map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _measArea = v ?? 'Waist'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _measValCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, hint: 'cm'))),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () async {
                      final val = double.tryParse(_measValCtrl.text.trim());
                      if (val == null || val <= 0) return;
                      await provider.saveQuickAdd('measurement', {'name': _measArea, 'value_num': val, 'unit': 'cm'});
                      _measValCtrl.clear();
                    },
                    child: const Text('Log'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Waist', 'Hip', 'Chest', 'Arm', 'Thigh'].map((n) {
                  final m = latestMeas[n] as Map<String, dynamic>?;
                  return M6Pill(text: '$n: ${m != null ? '${m['value_num']} cm' : '—'}');
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Workouts
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workout', style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 2),
              Text('Any movement counts.', style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _woNameCtrl, decoration: m6InputDecoration(context, hint: 'Walk / Yoga'))),
                  const SizedBox(width: 8),
                  SizedBox(width: 70, child: TextField(controller: _woMinCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, hint: 'min'))),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () async {
                      await provider.saveQuickAdd('workout', {
                        'name': _woNameCtrl.text.trim().isEmpty ? 'Workout' : _woNameCtrl.text.trim(),
                        'value_num': double.tryParse(_woMinCtrl.text.trim()) ?? 20,
                        'unit': 'min',
                      });
                      _woNameCtrl.clear();
                    },
                    child: const Text('+ Log'),
                  ),
                ],
              ),
              ...workouts.take(8).map((w) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${w['name'] ?? 'Workout'}'),
                    subtitle: Text('${w['day']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        M6Pill(text: '${(w['value_num'] as num).round()} min'),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('health_entries', w['id'] as String)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Complete Wellness Workspace
class WellnessWorkspaceView extends StatefulWidget {
  const WellnessWorkspaceView({super.key});

  @override
  State<WellnessWorkspaceView> createState() => _WellnessWorkspaceViewState();
}

class _WellnessWorkspaceViewState extends State<WellnessWorkspaceView> {
  String _mood = 'Calm';
  int _moodScore = 4;
  int _energy = 4;
  int _stress = 2;
  final _sleepCtrl = TextEditingController(text: '7.5');
  final _trigCtrl = TextEditingController();
  final _gratCtrl = TextEditingController();
  final _journalCtrl = TextEditingController();

  @override
  void dispose() {
    _sleepCtrl.dispose();
    _trigCtrl.dispose();
    _gratCtrl.dispose();
    _journalCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCheckIn(ChecklistProvider provider) async {
    await provider.saveQuickAdd('mood', {
      'mood': _mood,
      'mood_score': _moodScore,
      'energy': _energy,
      'stress': _stress,
      'sleep_hours': double.tryParse(_sleepCtrl.text.trim()) ?? 7.5,
      'triggers_text': _trigCtrl.text.trim(),
      'gratitude_text': _gratCtrl.text.trim(),
      'note': _journalCtrl.text.trim(),
    });
    _trigCtrl.clear();
    _gratCtrl.clear();
    _journalCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final rep = provider.moduleReport?.module == 'wellness' ? provider.moduleReport : null;
    final entries = rep?.entries ?? [];
    final latestSleep = entries.isNotEmpty ? entries.first['sleep_hours'] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.tr('How are you today?', 'Bagaimana kabarmu hari ini?'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.displayStyle(context, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  M6Pill(text: _mood),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  (emoji: '😊', label: 'Happy', score: 5),
                  (emoji: '🙂', label: 'Calm', score: 4),
                  (emoji: '😐', label: 'Neutral', score: 3),
                  (emoji: '😔', label: 'Tired', score: 2),
                  (emoji: '😣', label: 'Stressed', score: 1),
                ].map((m) {
                  final sel = _mood == m.label;
                  return InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => setState(() {
                      _mood = m.label;
                      _moodScore = m.score;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.tabBg(context) : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: sel ? AppColors.accent(context) : AppColors.line(context)),
                      ),
                      child: Text(m.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              Divider(height: 22, color: AppColors.line(context)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _energy,
                      decoration: m6InputDecoration(context, label: 'Energy level'),
                      items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('$n/5'))).toList(),
                      onChanged: (v) => setState(() => _energy = v ?? 4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _stress,
                      decoration: m6InputDecoration(context, label: 'Stress level'),
                      items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('$n/5'))).toList(),
                      onChanged: (v) => setState(() => _stress = v ?? 2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep', style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                latestSleep != null ? '$latestSleep hrs' : '— hrs',
                style: AppTheme.displayStyle(context, fontSize: 24),
              ),
              Text('Record last night\'s sleep', style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sleepCtrl,
                      keyboardType: TextInputType.number,
                      decoration: m6InputDecoration(context, hint: 'Hours (e.g. 7.5)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () async {
                      await _saveCheckIn(provider);
                      if (context.mounted) showCalmSnackBar(context, 'Sleep logged.');
                    },
                    child: const Text('Log sleep'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Daily journal & gratitude', 'Jurnal harian & rasa syukur'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _journalCtrl,
                maxLines: 3,
                decoration: m6InputDecoration(context, hint: s.tr('What is on your mind today?', 'Apa yang ada di pikiranmu hari ini?')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _trigCtrl,
                decoration: m6InputDecoration(context, label: s.tr('Emotional triggers (comma)', 'Pemicu emosi (pisahkan koma)')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _gratCtrl,
                decoration: m6InputDecoration(context, label: s.tr('Small gratitude', 'Hal yang disyukuri')),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: m6PrimaryButtonStyle(context),
                onPressed: () async {
                  await _saveCheckIn(provider);
                  if (context.mounted) showCalmSnackBar(context, s.tr('Check-in saved.', 'Catatan kesejahteraan disimpan.'));
                },
                child: Text(s.tr('Save check-in', 'Simpan catatan')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.tr('Recent check-ins', 'Catatan terbaru')} (${entries.length})', style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 6),
              if (entries.isEmpty) Text(s.tr('No check-ins yet.', 'Belum ada catatan.'), style: TextStyle(color: AppColors.muted(context))),
              ...entries.take(15).map((e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e['mood']} (${e['day']})'),
                    subtitle: Text('E:${e['energy']}/5 S:${e['stress']}/5 · ${e['sleep_hours']}h${e['gratitude_text'] != null && e['gratitude_text'].toString().isNotEmpty ? ' · ♡ ${e['gratitude_text']}' : ''}'),
                    trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('wellness_entries', e['id'] as String)),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Complete Menstrual Workspace
class MenstrualWorkspaceView extends StatefulWidget {
  const MenstrualWorkspaceView({super.key});

  @override
  State<MenstrualWorkspaceView> createState() => _MenstrualWorkspaceViewState();
}

class _MenstrualWorkspaceViewState extends State<MenstrualWorkspaceView> {
  String _phase = 'Menstrual';
  String _flow = 'Light';
  bool _isStart = false;
  final Set<String> _pickedSymptoms = {};
  final _cycDayCtrl = TextEditingController(text: '1');
  final _lenCtrl = TextEditingController(text: '28');
  final _symCtrl = TextEditingController();

  @override
  void dispose() {
    _cycDayCtrl.dispose();
    _lenCtrl.dispose();
    _symCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final rep = provider.moduleReport?.module == 'menstrual' ? provider.moduleReport : null;
    final est = rep?.metrics['nextPeriodEstimate'] as Map<String, dynamic>?;
    final entries = rep?.entries ?? [];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDow = DateTime(now.year, now.month, 1).weekday - 1;
    final periodDays = entries
        .where((e) => e['phase'] == 'Menstrual' || e['is_period_start'] == 1)
        .map((e) => e['day'].toString())
        .toSet();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        CalmCard(
          color: AppColors.soft(context),
          borderColor: AppColors.line(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.tr('NEXT PERIOD ESTIMATE', 'PERKIRAAN HAID BERIKUTNYA'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.muted(context)),
              ),
              const SizedBox(height: 4),
              Text(
                est != null ? '${est['estimatedStartDay']}' : '—',
                style: AppTheme.displayStyle(context, fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                est != null ? '${s.tr('Est. ovulation', 'Prakiraan ovulasi')}: ${est['estimatedOvulationDay']}' : s.tr('Add cycle records to calculate an estimate.', 'Tambahkan catatan siklus untuk menghitung prakiraan.'),
                style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
              ),
              const SizedBox(height: 6),
              Text(s.estDisclaimer, style: TextStyle(fontSize: 11, color: AppColors.accentDeep(context))),
            ],
          ),
        ),
        const SizedBox(height: 12),

        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cycle calendar · ${now.year}-${now.month.toString().padLeft(2, '0')}', style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.25,
                children: [
                  ...['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Center(
                        child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted(context))),
                      )),
                  ...List.generate(firstDow, (_) => const SizedBox.shrink()),
                  ...List.generate(daysInMonth, (i) {
                    final dayNum = i + 1;
                    final ds = '${now.year}-${now.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                    final isToday = dayNum == now.day;
                    final isPeriod = periodDays.contains(ds);
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.accentSoft(context)
                            : (isPeriod ? AppColors.tabBg(context) : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: AppColors.accent(context)) : null,
                      ),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (isToday || isPeriod) ? FontWeight.w700 : FontWeight.w500,
                          color: (isToday || isPeriod) ? AppColors.accentDeep(context) : AppColors.ink(context),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr("Today's symptoms & log", 'Gejala & catatan hari ini'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['cramps', 'bloating', 'headache', 'fatigue', 'acne'].map((sym) {
                  final sel = _pickedSymptoms.contains(sym);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      if (sel) {
                        _pickedSymptoms.remove(sym);
                      } else {
                        _pickedSymptoms.add(sym);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.tabBg(context) : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? AppColors.accent(context) : AppColors.line(context)),
                      ),
                      child: Text(
                        sym,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? AppColors.accentDeep(context) : AppColors.ink(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _phase,
                      decoration: m6InputDecoration(context, label: 'Phase'),
                      items: const ['Menstrual', 'Follicular', 'Ovulation', 'Luteal'].map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _phase = v ?? 'Menstrual'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _flow,
                      decoration: m6InputDecoration(context, label: 'Flow'),
                      items: const ['None', 'Light', 'Medium', 'Heavy'].map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _flow = v ?? 'None'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _cycDayCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, label: 'Cycle day'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _lenCtrl, keyboardType: TextInputType.number, decoration: m6InputDecoration(context, label: 'Cycle length'))),
                ],
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(s.tr('Period started today (Day 1)', 'Mulai haid hari ini (Hari ke-1)')),
                value: _isStart,
                onChanged: (v) => setState(() => _isStart = v),
              ),
              TextField(controller: _symCtrl, decoration: m6InputDecoration(context, label: s.tr('Other symptoms or notes', 'Gejala lain atau catatan'))),
              const SizedBox(height: 10),
              ElevatedButton(
                style: m6PrimaryButtonStyle(context),
                onPressed: () async {
                  final raw = _symCtrl.text.trim();
                  final extra = raw.isEmpty ? <String>[] : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final syms = {..._pickedSymptoms, ...extra}.toList();
                  await provider.saveQuickAdd('menstrual', {
                    'phase': _phase,
                    'flow': _flow,
                    'cycle_day': int.tryParse(_cycDayCtrl.text.trim()) ?? 1,
                    'cycle_length': int.tryParse(_lenCtrl.text.trim()) ?? 28,
                    'is_period_start': _isStart ? 1 : 0,
                    'symptoms': syms,
                  });
                  _symCtrl.clear();
                  setState(() => _pickedSymptoms.clear());
                  if (context.mounted) showCalmSnackBar(context, s.tr('Cycle log saved.', 'Catatan siklus disimpan.'));
                },
                child: Text(s.tr('Save symptoms & log', 'Simpan catatan siklus')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cycle history (${entries.length})', style: AppTheme.displayStyle(context, fontSize: 16)),
              ...entries.take(15).map((e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e['phase']} · Day ${e['cycle_day']} (${e['day']})'),
                    subtitle: Text('${e['flow'] ?? ''} ${e['is_period_start'] == 1 ? '· Start' : ''}'),
                    trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => provider.softDeleteItem('menstrual_entries', e['id'] as String)),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Complete Notes & Journal Workspace
class NotesWorkspaceView extends StatefulWidget {
  const NotesWorkspaceView({super.key});

  @override
  State<NotesWorkspaceView> createState() => _NotesWorkspaceViewState();
}

class _NotesWorkspaceViewState extends State<NotesWorkspaceView> {
  String _catFilter = 'all';
  String _search = '';
  String? _editId;
  String _editCat = 'journal';
  bool _editPinned = false;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final rep = provider.moduleReport?.module == 'notes' ? provider.moduleReport : null;
    final allNotes = rep?.entries ?? [];
    final pinned = allNotes.where((n) => n['is_pinned'] == 1).toList();
    final notes = allNotes.where((n) {
      if (_catFilter == 'pinned') {
        if (n['is_pinned'] != 1) return false;
      } else if (_catFilter != 'all' && (n['category'] ?? 'journal') != _catFilter) {
        return false;
      }
      if (_search.isNotEmpty) {
        final txt = '${n['title']} ${n['body']}'.toLowerCase();
        if (!txt.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();

    final catLabels = {
      'all': s.tr('All', 'Semua'),
      'journal': s.tr('Daily journal', 'Jurnal harian'),
      'braindump': s.tr('Brain dump', 'Curahan pikiran'),
      'gratitude': s.tr('Gratitude', 'Syukur'),
      'quick': s.tr('Quick note', 'Catatan cepat'),
      'pinned': s.tr('Pinned', 'Disematkan'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // 1. Comfortable Quick Editor (larger readable input font)
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_editId == null ? s.tr('Quick editor', 'Editor cepat') : s.tr('Edit note', 'Ubah catatan'), style: AppTheme.displayStyle(context, fontSize: 17)),
                  if (_editId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _editId = null;
                          _editPinned = false;
                          _titleCtrl.clear();
                          _bodyCtrl.clear();
                          _tagsCtrl.clear();
                        });
                      },
                      child: Text('+ ${s.tr('New note', 'Catatan baru')}'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('note_title_input'),
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
                decoration: m6InputDecoration(context, hint: s.tr('Note title', 'Judul catatan')),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('note_body_input'),
                controller: _bodyCtrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 15, height: 1.55),
                decoration: m6InputDecoration(context, hint: s.tr('Start writing...', 'Mulai menulis...')),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _editCat,
                      decoration: m6InputDecoration(context, label: s.tr('Category', 'Kategori')),
                      items: ['journal', 'braindump', 'gratitude', 'quick']
                          .map((c) => DropdownMenuItem(value: c, child: Text(catLabels[c] ?? c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _editCat = v ?? 'journal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _tagsCtrl, style: const TextStyle(fontSize: 14), decoration: m6InputDecoration(context, label: 'Tag'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          value: _editPinned,
                          onChanged: (v) => setState(() => _editPinned = v ?? false),
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: Text(s.tr('Pin note', 'Sematkan catatan'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('note_save_btn'),
                    style: m6PrimaryButtonStyle(context),
                    onPressed: () async {
                      await provider.saveQuickAdd('note', {
                        if (_editId != null) 'id': _editId,
                        'title': _titleCtrl.text.trim().isEmpty ? s.tr('Quick Note', 'Catatan Cepat') : _titleCtrl.text.trim(),
                        'body': _bodyCtrl.text,
                        'category': _editCat,
                        'tags_text': _tagsCtrl.text,
                        'is_pinned': _editPinned,
                      });
                      setState(() {
                        _editId = null;
                        _editPinned = false;
                        _titleCtrl.clear();
                        _bodyCtrl.clear();
                        _tagsCtrl.clear();
                      });
                      if (context.mounted) showCalmSnackBar(context, s.tr('Note saved.', 'Catatan disimpan.'));
                    },
                    child: Text(s.tr('Save note', 'Simpan catatan')),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Saved Notes List (newest / just-saved FIRST right below the editor!)
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.notes} (${notes.length})', style: AppTheme.displayStyle(context, fontSize: 17)),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(fontSize: 14.5),
                decoration: m6InputDecoration(context, hint: s.tr('Search your notes...', 'Cari catatanmu...'), prefixIcon: const Icon(Icons.search, size: 18)),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['all', 'journal', 'braindump', 'gratitude', 'quick', 'pinned'].map((c) {
                  final sel = _catFilter == c;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _catFilter = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.tabBg(context) : AppColors.soft(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? AppColors.accent(context) : AppColors.line(context)),
                      ),
                      child: Text(
                        catLabels[c] ?? c,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? AppColors.accentDeep(context) : AppColors.muted(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(s.tr('No notes match this filter.', 'Tidak ada catatan yang cocok.'), style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
                ),
              ...notes.map((n) {
                final body = (n['body'] as String? ?? '').trim();
                final cat = (n['category'] as String?) ?? 'journal';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      setState(() {
                        _editId = n['id'] as String?;
                        _editCat = cat;
                        _editPinned = n['is_pinned'] == 1;
                        _titleCtrl.text = n['title'] as String? ?? '';
                        _bodyCtrl.text = body;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.line(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${n['is_pinned'] == 1 ? '📌 ' : ''}${n['title']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              M6Pill(text: catLabels[cat] ?? cat),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.close, size: 17, color: AppColors.miss(context)),
                                onPressed: () => provider.softDeleteItem('notes', n['id'] as String),
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, height: 1.48, color: AppColors.ink(context).withValues(alpha: 0.85)),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text('${n['day']}', style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Pinned Reminders / Motivational Notes Box
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Pinned notes', 'Catatan disematkan'), style: AppTheme.displayStyle(context, fontSize: 16)),
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
                      pinned.isNotEmpty ? '${pinned.first['title']} ♡' : s.tr('Remember ♡', 'Ingatlah ♡'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pinned.isNotEmpty ? '${pinned.first['body'] ?? ''}' : s.defaultMotivation,
                      style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return M6StatBox(label: label, value: value);
  }
}
