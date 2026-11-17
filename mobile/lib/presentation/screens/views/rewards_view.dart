import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _fmtDay(String dayStr) {
  final p = dayStr.split('-');
  if (p.length < 3) return dayStr;
  final m = int.tryParse(p[1]) ?? 1;
  final d = int.tryParse(p[2]) ?? 1;
  return '$d ${_monthsShort[m - 1]}';
}

class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final bal = provider.pointsBalance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        CalmCard(
          color: AppColors.goldSoft(context),
          borderColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POIN KAMU',
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
                  text: '$bal',
                  style: AppTheme.displayStyle(
                    context,
                    fontSize: 44,
                    color: AppColors.goldInk(context),
                  ),
                  children: const [
                    TextSpan(
                      text: ' poin',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Setiap langkah yang dicentang menambah 1 poin. Hari yang terlewat tidak mengurangi poin.',
                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...provider.rewards.map((r) {
          final canClaim = bal >= r.cost;
          final pct = ((bal / (r.cost > 0 ? r.cost : 1)) * 100).round().clamp(0, 100);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CalmCard(
              child: provider.editMode
                  ? _EditRewardRow(reward: r)
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${r.cost} poin',
                                    style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: canClaim ? AppColors.gold(context) : AppColors.surface(context),
                                foregroundColor: canClaim ? const Color(0xFF2A1B02) : AppColors.muted(context),
                                side: canClaim ? null : BorderSide(color: AppColors.line(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: canClaim
                                  ? () async {
                                      final claim = await provider.claimReward(r.id);
                                      if (context.mounted) {
                                        showCalmSnackBar(
                                          context,
                                          'Diambil: ${claim.name}. Nikmati tanpa rasa bersalah.',
                                          onUndo: () async {
                                            final ok = await provider.undoClaim(claim.id);
                                            if (!ok && context.mounted) {
                                              showCalmSnackBar(context, 'Sudah tersinkronisasi, tidak bisa diurungkan.');
                                            }
                                          },
                                        );
                                      }
                                    }
                                  : null,
                              child: Text(canClaim ? 'Ambil' : 'Kurang ${r.cost - bal}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CalmProgressBar(percent: pct, gold: true),
                      ],
                    ),
            ),
          );
        }),

        if (provider.editMode)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                side: BorderSide(color: AppColors.line(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => provider.addReward(),
              child: Text(
                '+ Tambah hadiah',
                style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
              ),
            ),
          ),

        if (!provider.editMode && provider.claims.isNotEmpty) ...[
          const SizedBox(height: 4),
          CalmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sudah diambil', style: AppTheme.displayStyle(context, fontSize: 17)),
                const SizedBox(height: 8),
                ...provider.claims.take(8).map((c) => Column(
                      children: [
                        Divider(height: 1, color: AppColors.line(context)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 15))),
                              Text(
                                _fmtDay(c.day),
                                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EditRewardRow extends StatefulWidget {
  final RewardItem reward;
  const _EditRewardRow({required this.reward});

  @override
  State<_EditRewardRow> createState() => _EditRewardRowState();
}

class _EditRewardRowState extends State<_EditRewardRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _costCtrl;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.reward.name);
    _costCtrl = TextEditingController(text: widget.reward.cost.toString());
    _nameFocus.addListener(_saveIfBlurred);
    _costFocus.addListener(_saveIfBlurred);
  }

  void _saveIfBlurred() {
    if (!_nameFocus.hasFocus && !_costFocus.hasFocus) {
      _save();
    }
  }

  void _save() {
    final cost = (int.tryParse(_costCtrl.text) ?? widget.reward.cost).clamp(1, 999);
    context.read<ChecklistProvider>().updateReward(
          widget.reward,
          name: _nameCtrl.text.trim(),
          cost: cost,
        );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _costFocus.dispose();
    _nameCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChecklistProvider>();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            decoration: InputDecoration(
              hintText: 'Nama hadiah',
              filled: true,
              fillColor: AppColors.bg(context),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: TextField(
            controller: _costCtrl,
            focusNode: _costFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bg(context),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () async {
            await provider.deactivateReward(widget.reward.id);
            if (context.mounted) {
              showCalmSnackBar(
                context,
                'Hadiah dihapus.',
                onUndo: () => provider.reactivateReward(widget.reward.id),
              );
            }
          },
          icon: Icon(Icons.close, color: AppColors.muted(context)),
        ),
      ],
    );
  }
}
