import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

class AuditLogView extends StatelessWidget {
  const AuditLogView({super.key});

  String _fmtTs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final s = AppStrings(provider.prefs.language);
    final logs = provider.auditLogs;
    final syncFail = logs
        .where((l) =>
            (l.category == 'sync' || l.category == 'discovery') &&
            l.level == 'error')
        .length;
    final authWarn =
        logs.where((l) => l.category == 'auth' || l.statusCode == 401).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: CalmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr('Sync Failed', 'Gagal Sinkron'),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted(context))),
                    const SizedBox(height: 4),
                    Text('$syncFail',
                        style: AppTheme.displayStyle(context, fontSize: 22)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CalmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr('Auth / 401', 'Autentikasi'),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted(context))),
                    const SizedBox(height: 4),
                    Text('$authWarn',
                        style: AppTheme.displayStyle(context, fontSize: 22)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        CalmSegmentedControl<String>(
          items: [
            (value: 'all', label: s.tr('All', 'Semua')),
            (value: 'sync', label: s.tr('Sync Failed', 'Gagal')),
            (value: 'auth', label: 'Auth/401'),
            (value: 'info', label: s.tr('Recovered', 'Pulih')),
          ],
          selected: provider.auditFilter,
          onChanged: (v) => provider.setAuditFilter(v),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.tr('Total ${logs.length} local entries', 'Total ${logs.length} entri lokal'),
                style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
            if (logs.isNotEmpty)
              TextButton(
                onPressed: () => provider.clearAuditLogs(),
                child: Text(s.tr('Clear Logs', 'Bersihkan Log')),
              ),
          ],
        ),

        if (logs.isEmpty)
          CalmCard(
            child: Text(
              s.tr('No API or sync error logs.', 'Tidak ada log error API atau sinkronisasi.'),
              style: TextStyle(color: AppColors.muted(context)),
            ),
          )
        else
          ...logs.map((l) {
            final isErr = l.level == 'error';
            final isWarn = l.level == 'warn';
            final bg = isErr
                ? AppColors.missSoft(context)
                : (isWarn
                    ? AppColors.goldSoft(context)
                    : AppColors.accentSoft(context));
            final fg = isErr
                ? AppColors.miss(context)
                : (isWarn
                    ? AppColors.goldInk(context)
                    : AppColors.accent(context));

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CalmCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l.level.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: fg),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(l.endpoint,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted(context))),
                        const Spacer(),
                        Text(_fmtTs(l.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: AppColors.muted(context))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(l.message, style: const TextStyle(fontSize: 14)),
                    if (l.details != null)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('Detail teknis',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent(context))),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bg(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(l.details),
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
