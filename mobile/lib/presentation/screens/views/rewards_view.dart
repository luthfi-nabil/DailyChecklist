import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

const _monthsShortEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsShortId = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _fmtDay(String dayStr, AppStrings s) {
  final p = dayStr.split('-');
  if (p.length < 3) return dayStr;
  final m = int.tryParse(p[1]) ?? 1;
  final d = int.tryParse(p[2]) ?? 1;
  final arr = s.isId ? _monthsShortId : _monthsShortEn;
  return '$d ${arr[(m - 1).clamp(0, 11)]}';
}

class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final bal = provider.pointsBalance;
    const rewardIcons = ['♡', '✿', '☆', '✦'];

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
                s.tr('YOUR POINTS', 'POIN KAMU'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
                    fontSize: 38,
                    color: AppColors.ink(context),
                  ),
                  children: [
                    TextSpan(
                      text: ' ${s.tr('points', 'poin')}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.tr(
                  'Every checked step earns 1 point. Missed days never take points away.',
                  'Setiap langkah selesai bernilai 1 poin. Hari yang terlewat tidak pernah mengurangi poin.',
                ),
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...provider.rewards.asMap().entries.map((entry) {
          final idx = entry.key;
          final r = entry.value;
          final canClaim = bal >= r.cost;
          final pct = ((bal / (r.cost > 0 ? r.cost : 1)) * 100).round().clamp(0, 100);
          final icon = rewardIcons[idx % rewardIcons.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CalmCard(
              child: provider.editMode
                  ? _EditRewardRow(reward: r)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              icon,
                              style: TextStyle(fontSize: 22, color: AppColors.accentDeep(context), height: 1),
                            ),
                            OutlinedButton(
                              style: canClaim ? m6GhostButtonStyle(context) : OutlinedButton.styleFrom(
                                backgroundColor: AppColors.surface(context),
                                foregroundColor: AppColors.muted(context),
                                side: BorderSide(color: AppColors.line(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: canClaim
                                  ? () async {
                                      final claim = await provider.claimReward(r.id);
                                      if (context.mounted) {
                                        showCalmSnackBar(
                                          context,
                                          s.tr(
                                            'Redeemed: ${claim.name}. Enjoy guilt-free.',
                                            'Ditukar: ${claim.name}. Nikmati tanpa rasa bersalah.',
                                          ),
                                          undoLabel: s.tr('Undo', 'Urungkan'),
                                          onUndo: () async {
                                            final ok = await provider.undoClaim(claim.id);
                                            if (!ok && context.mounted) {
                                              showCalmSnackBar(context, s.tr('Already synced, cannot undo.', 'Sudah tersinkronisasi, tidak bisa dibatalkan.'));
                                            }
                                          },
                                        );
                                      }
                                    }
                                  : null,
                              child: Text(canClaim ? s.tr('Redeem', 'Tukar') : s.tr('Need ${r.cost - bal} more', 'Kurang ${r.cost - bal} lagi')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(r.name, style: AppTheme.displayStyle(context, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '${r.cost} ${s.tr('points', 'poin')}',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        CalmProgressBar(percent: pct, height: 7),
                      ],
                    ),
            ),
          );
        }),

        if (provider.editMode)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: m6GhostButtonStyle(context),
              onPressed: () => provider.addReward(),
              child: Text('+ ${s.tr('Create reward', 'Buat hadiah')}'),
            ),
          ),

        const SizedBox(height: 6),
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.tr('Achievements', 'Pencapaian'), style: AppTheme.displayStyle(context, fontSize: 16)),
              const SizedBox(height: 8),
              ...(provider.lifeOsSummary?.achievements ?? const []).map((a) {
                final labels = {
                  'first-step': s.tr('First step (1+ check)', 'Langkah pertama (1+ selesai)'),
                  'streak-7': s.tr('Consistency week (7-day streak)', 'Pekan konsisten (7 hari beruntun)'),
                  'checks-25': s.tr('Little by little (25 checks)', 'Sedikit demi sedikit (25 selesai)'),
                  'focus-60': s.tr('Deep calm focus (60m focus)', 'Fokus tenang mendalam (60m fokus)'),
                  'self-care-1': s.tr('Kind treat (1 reward claimed)', 'Apresiasi diri (1 hadiah ditukar)'),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line(context))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          labels[a.id] ?? a.id,
                          style: TextStyle(
                            fontWeight: a.unlocked ? FontWeight.w700 : FontWeight.w500,
                            color: a.unlocked ? AppColors.ink(context) : AppColors.muted(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      M6Pill(text: a.unlocked ? s.tr('Unlocked ✓', 'Terbuka ✓') : '${a.progress}/${a.target}'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        if (!provider.editMode && provider.claims.isNotEmpty) ...[
          const SizedBox(height: 12),
          CalmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tr('Reward history', 'Riwayat hadiah'), style: AppTheme.displayStyle(context, fontSize: 16)),
                const SizedBox(height: 8),
                ...provider.claims.take(8).map((c) => Column(
                      children: [
                        Divider(height: 1, color: AppColors.line(context)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 14))),
                              Text(
                                _fmtDay(c.day, s),
                                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
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
            decoration: m6InputDecoration(context, hint: 'Reward name'),
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
            decoration: m6InputDecoration(context),
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
