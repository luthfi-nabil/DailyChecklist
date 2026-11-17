import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/sync_service.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/calm_widgets.dart';

const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _fmtMs(int? ms) {
  if (ms == null) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day} ${_monthsShort[d.month - 1]}';
}

String _fmtClock(int? ms) {
  if (ms == null) return 'Belum pernah';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  void _showPairingDialog(BuildContext context, ChecklistProvider provider) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sambungkan ke Desktop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan 6 digit kode yang tampil di halaman Pengaturan aplikasi Desktop:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.length < 4) return;
              Navigator.pop(ctx);
              final ok = await provider.pairWithDesktop(code);
              if (context.mounted) {
                showCalmSnackBar(
                  context,
                  ok ? 'Berhasil tersambung ke Desktop!' : (provider.syncService.errorMessage ?? 'Gagal menyambungkan.'),
                );
              }
            },
            child: const Text('Sambungkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final sync = provider.syncService;

    String statusLabel = 'Siap';
    if (sync.status == SyncStatus.discovering) {
      statusLabel = 'Mencari desktop...';
    } else if (sync.status == SyncStatus.syncing) {
      statusLabel = 'Menyinkronkan...';
    } else if (sync.status == SyncStatus.connected) {
      statusLabel = 'Tersambung';
    } else if (sync.status == SyncStatus.notFound) {
      statusLabel = 'Desktop tidak ditemukan';
    } else if (sync.status == SyncStatus.unauthorized) {
      statusLabel = 'Perlu sambungkan';
    } else if (sync.status == SyncStatus.error) {
      statusLabel = 'Gagal';
    }

    final desktopName = sync.currentServer?.deviceName ?? 'Desktop';
    final inactiveCount = provider.inactiveTasks.length + provider.inactiveGroups.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. Sync Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sinkronisasi', style: AppTheme.displayStyle(context, fontSize: 17)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ponsel menemukan aplikasi desktop di jaringan Wi-Fi yang sama secara otomatis. Tidak perlu mengisi IP.',
                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.line(context)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(desktopName),
                    Text(
                      sync.currentServer != null ? 'Ditemukan otomatis' : 'Belum ditemukan',
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.line(context)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Terakhir sinkron'),
                    Text(
                      _fmtClock(sync.lastSyncTime),
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              if (sync.tokenExpiresAt != null) ...[
                Divider(height: 1, color: AppColors.line(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Token berlaku hingga'),
                      Text(
                        _fmtMs(sync.tokenExpiresAt),
                        style: TextStyle(color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
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
                    onPressed: () async {
                      final ok = await provider.syncNow();
                      if (context.mounted) {
                        if (sync.status == SyncStatus.unauthorized) {
                          _showPairingDialog(context, provider);
                        } else {
                          showCalmSnackBar(
                            context,
                            ok ? 'Sinkronisasi selesai.' : 'Desktop tidak ditemukan di jaringan lokal.',
                          );
                        }
                      }
                    },
                    child: const Text('Sinkronkan sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: AppColors.line(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showPairingDialog(context, provider),
                    child: const Text('Masukkan kode', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
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
                        const Text('Sinkron otomatis', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'Dua arah, saat di jaringan yang sama.',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: sync.autoSyncEnabled,
                    activeTrackColor: AppColors.accent(context),
                    onChanged: (val) => provider.setAutoSync(val),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Inactive items Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Langkah nonaktif', style: AppTheme.displayStyle(context, fontSize: 17)),
                  Text('$inactiveCount', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Menghapus langkah atau kelompok hanya menonaktifkannya. Riwayat dan poin tetap aman.',
                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
              ),
              if (inactiveCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Tidak ada langkah atau kelompok nonaktif.', style: TextStyle(color: AppColors.muted(context))),
                ),
              ...provider.inactiveTasks.map((t) => Column(
                    children: [
                      const SizedBox(height: 8),
                      Divider(height: 1, color: AppColors.line(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name),
                                  Text(
                                    '${t.groupName} · ${_fmtMs(t.deactivatedAt)} · ${t.completedCount} kali selesai',
                                    style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                side: BorderSide(color: AppColors.line(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await provider.reactivateTask(t.id);
                                if (context.mounted) {
                                  showCalmSnackBar(context, 'Diaktifkan lagi. Muncul di daftar hari ini.');
                                }
                              },
                              child: const Text('Aktifkan lagi'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
              ...provider.inactiveGroups.map((g) => Column(
                    children: [
                      const SizedBox(height: 8),
                      Divider(height: 1, color: AppColors.line(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kelompok ${g.name}'),
                                  Text(
                                    '${g.taskCount} langkah · dinonaktifkan ${_fmtMs(g.deactivatedAt)}',
                                    style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                side: BorderSide(color: AppColors.line(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await provider.reactivateGroup(g.id);
                                if (context.mounted) {
                                  showCalmSnackBar(context, 'Kelompok diaktifkan lagi.');
                                }
                              },
                              child: const Text('Aktifkan lagi'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Theme Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tampilan', style: AppTheme.displayStyle(context, fontSize: 17)),
              const SizedBox(height: 12),
              CalmSegmentedControl<ThemeMode>(
                items: const [
                  (value: ThemeMode.system, label: 'Otomatis'),
                  (value: ThemeMode.light, label: 'Terang'),
                  (value: ThemeMode.dark, label: 'Gelap'),
                ],
                selected: provider.themeMode,
                onChanged: (mode) => provider.setThemeMode(mode),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Langkah Kecil v0.1.0',
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
