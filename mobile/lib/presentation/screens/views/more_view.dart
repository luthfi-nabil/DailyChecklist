import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
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
  if (ms == null) return 'Never';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class MoreView extends StatefulWidget {
  const MoreView({super.key});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  final _nameCtrl = TextEditingController();
  final _manualIpCtrl = TextEditingController();
  final _manualPortCtrl = TextEditingController(text: '47800');
  bool _nameInit = false;
  bool _manualInit = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manualIpCtrl.dispose();
    _manualPortCtrl.dispose();
    super.dispose();
  }

  void _showPairingDialog(BuildContext context, ChecklistProvider provider) {
    final s = AppStrings(provider.prefs.language);
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr('Pair with Desktop', 'Sambungkan dengan Desktop')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.tr('Enter the 6-digit pairing code shown in Desktop Settings:', 'Masukkan kode sambungan 6 digit yang muncul di Pengaturan Desktop:')),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(hintText: '123456', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.length < 4) return;
              Navigator.pop(ctx);
              final ok = await provider.pairWithDesktop(code);
              if (context.mounted) {
                showCalmSnackBar(
                  context,
                  ok ? s.tr('Paired with Desktop!', 'Terhubung ke Desktop!') : (provider.syncService.errorMessage ?? s.tr('Pairing failed.', 'Gagal menyambungkan.')),
                );
              }
            },
            child: Text(s.tr('Pair', 'Sambungkan')),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportJsonDialog(BuildContext context, ChecklistProvider provider) async {
    final s = AppStrings(provider.prefs.language);
    final data = await provider.exportAllDataJson();
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr('JSON Backup Export', 'Ekspor Cadangan JSON')),
        content: SizedBox(
          width: double.maxFinite,
          height: 220,
          child: SingleChildScrollView(
            child: SelectableText(pretty, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.tr('Close', 'Tutup'))),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pretty));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) showCalmSnackBar(context, s.tr('Backup JSON copied to clipboard.', 'Cadangan JSON disalin ke papan klip.'));
            },
            child: Text(s.tr('Copy JSON', 'Salin JSON')),
          ),
        ],
      ),
    );
  }

  void _showRestoreJsonDialog(BuildContext context, ChecklistProvider provider) {
    final s = AppStrings(provider.prefs.language);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr('Restore JSON Backup', 'Pulihkan Cadangan JSON')),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: s.tr('Paste exported backup JSON here...', 'Tempel JSON cadangan di sini...'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              try {
                final decoded = json.decode(ctrl.text.trim()) as Map<String, dynamic>;
                Navigator.pop(ctx);
                await provider.importAllDataJson(decoded);
                if (context.mounted) showCalmSnackBar(context, s.tr('Backup restored!', 'Cadangan berhasil dipulihkan!'));
              } catch (e) {
                if (context.mounted) showCalmSnackBar(context, '${s.tr('Invalid JSON', 'JSON tidak valid')}: $e');
              }
            },
            child: Text(s.restoreBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final sync = provider.syncService;
    final s = AppStrings(provider.prefs.language);

    if (!_nameInit) {
      _nameCtrl.text = provider.prefs.userName;
      _nameInit = true;
    }
    if (!_manualInit) {
      _manualIpCtrl.text = sync.manualHost;
      _manualPortCtrl.text = sync.manualPort.toString();
      _manualInit = true;
    }

    String statusLabel = s.tr('Ready', 'Siap');
    if (sync.status == SyncStatus.discovering) {
      statusLabel = s.tr('Searching Desktop...', 'Mencari Desktop...');
    } else if (sync.status == SyncStatus.syncing) {
      statusLabel = s.tr('Syncing...', 'Menyinkronkan...');
    } else if (sync.status == SyncStatus.connected) {
      statusLabel = s.tr('Connected', 'Terhubung');
    } else if (sync.status == SyncStatus.notFound) {
      statusLabel = s.tr('Desktop not found', 'Desktop tidak ditemukan');
    } else if (sync.status == SyncStatus.unauthorized) {
      statusLabel = s.tr('Needs pairing', 'Perlu sambung ulang');
    } else if (sync.status == SyncStatus.error) {
      statusLabel = sync.errorMessage ?? s.tr('Sync error', 'Gagal sinkron');
    }

    final inactiveCount = provider.inactiveTasks.length + provider.inactiveGroups.length;
    final phoneIpDisplay = provider.localIp ?? s.tr('No active LAN IP', 'Tidak ada IP LAN aktif');
    final desktopIpDisplay = sync.currentServer != null
        ? '${sync.currentServer!.host}:${sync.currentServer!.port}'
        : s.tr('Not connected', 'Belum terhubung');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // 1. Profile & Color Palette Picker Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.settings, style: AppTheme.displayStyle(context, fontSize: 17)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('settings_name_input'),
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: s.displayName,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('settings_name_save'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.accentInk(context),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final clean = _nameCtrl.text.trim();
                      if (clean.isEmpty) return;
                      await provider.updateAppPreferences(userName: clean);
                      if (context.mounted) showCalmSnackBar(context, '${s.hello}, $clean ♡');
                    },
                    child: Text(s.saveBtn),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.paletteTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppColors.specFor(provider.prefs.colorPalette).label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentDeep(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: AppColors.palettes.map((pal) {
                  final selected = provider.prefs.colorPalette == pal.id;
                  return Tooltip(
                    message: pal.label,
                    child: InkWell(
                      key: Key('palette_${pal.id}'),
                      customBorder: const CircleBorder(),
                      onTap: () => provider.updateAppPreferences(colorPalette: pal.id),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pal.swatchAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: selected ? 2.5 : 1.5,
                            color: selected ? AppColors.ink(context) : AppColors.line(context),
                          ),
                        ),
                        child: selected
                            ? const Text('✓', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              CalmSegmentedControl<ThemeMode>(
                items: [
                  (value: ThemeMode.system, label: s.tr('Auto', 'Otomatis')),
                  (value: ThemeMode.light, label: s.tr('Light', 'Terang')),
                  (value: ThemeMode.dark, label: s.tr('Dark', 'Gelap')),
                ],
                selected: provider.themeMode,
                onChanged: (mode) => provider.setThemeMode(mode),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(s.languageTitle, style: const TextStyle(fontWeight: FontWeight.w600))),
                  SizedBox(
                    width: 140,
                    child: CalmSegmentedControl<String>(
                      items: const [(value: 'en', label: 'EN'), (value: 'id', label: 'ID')],
                      selected: provider.prefs.language,
                      onChanged: (lang) => provider.updateAppPreferences(language: lang),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text(s.chartsTitle, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Switch.adaptive(
                    value: provider.prefs.showReportCharts,
                    activeTrackColor: AppColors.accent(context),
                    onChanged: (v) => provider.updateAppPreferences(showReportCharts: v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Network IP (Milestone 5) & Sync Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(s.networkTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.displayStyle(context, fontSize: 17))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentDeep(context))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.phoneIp, style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                            Text(
                              phoneIpDisplay,
                              key: const Key('phone_ip_value'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: s.tr('Refresh IP', 'Perbarui IP'),
                          onPressed: () => provider.refreshLocalIp(),
                          icon: const Icon(Icons.refresh, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.desktopIp}: $desktopIpDisplay · ${s.tr('Last sync', 'Terakhir sinkron')}: ${sync.lastSyncTime == null ? s.tr('Never', 'Belum pernah') : _fmtClock(sync.lastSyncTime)}',
                      style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                    ),
                    if (provider.localIps.length > 1)
                      Text(
                        '${s.tr('Interfaces', 'Antarmuka')}: ${provider.localIps.map((e) => '${e.iface} ${e.address}').join(' · ')}',
                        style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      s.tr(
                        'Local Wi-Fi IP lookup uses standard network sockets; no extra OS permissions required.',
                        'Deteksi IP Wi-Fi lokal menggunakan soket jaringan standar; tanpa izin OS tambahan.',
                      ),
                      style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.soft(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.manualSyncTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(
                                sync.useManualEndpoint && sync.manualHost.isNotEmpty
                                    ? '${s.tr('Using', 'Memakai')} ${sync.manualHost}:${sync.manualPort}'
                                    : s.tr('Override auto LAN discovery with explicit IP & port', 'Gunakan IP & port manual alih-alih deteksi otomatis'),
                                style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          key: const Key('manual_sync_switch'),
                          value: sync.useManualEndpoint,
                          activeTrackColor: AppColors.accent(context),
                          onChanged: (val) async {
                            final host = SyncService.normalizeHost(_manualIpCtrl.text);
                            final port = SyncService.parsePort(_manualPortCtrl.text) ?? 47800;
                            if (val && host.isEmpty) {
                              showCalmSnackBar(context, s.tr('Enter Desktop IP address first.', 'Masukkan alamat IP Desktop terlebih dahulu.'));
                              return;
                            }
                            await provider.configureManualSync(
                              enabled: val,
                              host: host,
                              port: port,
                              testAndSync: val,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            key: const Key('manual_ip_input'),
                            controller: _manualIpCtrl,
                            keyboardType: TextInputType.url,
                            decoration: m6InputDecoration(context, label: s.manualHostLabel, hint: '192.168.1.10'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('manual_port_input'),
                            controller: _manualPortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: m6InputDecoration(context, label: s.manualPortLabel, hint: '47800'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          key: const Key('manual_connect_btn'),
                          style: m6PrimaryButtonStyle(context),
                          onPressed: () async {
                            final host = SyncService.normalizeHost(_manualIpCtrl.text);
                            final port = SyncService.parsePort(_manualPortCtrl.text);
                            if (host.isEmpty || port == null) {
                              showCalmSnackBar(context, s.tr('Enter a valid IP/host and port (1–65535).', 'Masukkan IP/host dan port yang valid (1–65535).'));
                              return;
                            }
                            _manualIpCtrl.text = host;
                            _manualPortCtrl.text = port.toString();
                            final res = await provider.configureManualSync(
                              enabled: true,
                              host: host,
                              port: port,
                              testAndSync: true,
                            );
                            if (!context.mounted) return;
                            if (res.server == null) {
                              showCalmSnackBar(context, '${s.tr('Cannot reach', 'Tidak dapat menjangkau')} $host:$port');
                            } else if (sync.status == SyncStatus.unauthorized) {
                              _showPairingDialog(context, provider);
                            } else if (res.synced) {
                              showCalmSnackBar(context, '${s.tr('Connected & synced with', 'Terhubung & tersinkron ke')} $host:$port');
                            } else {
                              showCalmSnackBar(context, '${s.tr('Connected to', 'Terhubung ke')} $host:$port');
                            }
                          },
                          child: Text(s.connectBtn),
                        ),
                        if (sync.useManualEndpoint)
                          OutlinedButton(
                            style: m6GhostButtonStyle(context),
                            onPressed: () async {
                              await provider.configureManualSync(
                                enabled: false,
                                host: sync.manualHost,
                                port: sync.manualPort,
                                testAndSync: false,
                              );
                              if (context.mounted) showCalmSnackBar(context, s.tr('Switched back to Auto LAN discovery.', 'Kembali ke deteksi LAN otomatis.'));
                            },
                            child: Text(s.tr('Use Auto LAN', 'Gunakan LAN Otomatis')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: m6PrimaryButtonStyle(context),
                    onPressed: () async {
                      final ok = await provider.syncNow();
                      if (context.mounted) {
                        if (sync.status == SyncStatus.unauthorized) {
                          _showPairingDialog(context, provider);
                        } else {
                          showCalmSnackBar(
                            context,
                            ok
                                ? s.tr('Sync complete.', 'Sinkronisasi selesai.')
                                : (sync.useManualEndpoint ? (sync.errorMessage ?? s.tr('Cannot reach manual server.', 'Server manual tidak terjangkau.')) : s.tr('Desktop not found on LAN.', 'Desktop tidak ditemukan di LAN.')),
                          );
                        }
                      }
                    },
                    child: Text(s.tr('Sync Now', 'Sinkron Sekarang'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton(
                    style: m6GhostButtonStyle(context),
                    onPressed: () => _showPairingDialog(context, provider),
                    child: Text(s.tr('Enter Code', 'Masukkan Kode')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(s.tr('Auto-sync on LAN', 'Sinkron otomatis di LAN'), style: const TextStyle(fontWeight: FontWeight.w600))),
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

        // 3. JSON Backup & Restore Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.backupTitle, style: AppTheme.displayStyle(context, fontSize: 17)),
              const SizedBox(height: 6),
              Text(
                s.tr(
                  'Local SQLite DB auto-backs up before upgrades. Export or restore a JSON snapshot anytime.',
                  'Database SQLite dicadangkan otomatis sebelum pembaruan. Ekspor atau pulihkan cadangan JSON kapan saja.',
                ),
                style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.accentInk(context),
                      elevation: 0,
                    ),
                    onPressed: () => _showExportJsonDialog(context, provider),
                    child: Text(s.tr('Export JSON', 'Ekspor JSON')),
                  ),
                  OutlinedButton(
                    onPressed: () => _showRestoreJsonDialog(context, provider),
                    child: Text(s.tr('Restore JSON', 'Pulihkan JSON')),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Inactive Items Card
        CalmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.tr('Inactive Steps & Groups', 'Langkah & Kelompok Nonaktif'),
                      style: AppTheme.displayStyle(context, fontSize: 17),
                    ),
                  ),
                  Text('$inactiveCount', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                ],
              ),
              if (inactiveCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.tr('No inactive steps or groups.', 'Tidak ada langkah atau kelompok nonaktif.'),
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                ),
              ...provider.inactiveTasks.map((t) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text(
                          '${t.groupName} · ${_fmtMs(t.deactivatedAt)}',
                          style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton(
                              key: Key('restore_task_${t.id}'),
                              style: m6GhostButtonStyle(context),
                              onPressed: () async {
                                await provider.reactivateTask(t.id);
                                if (context.mounted) showCalmSnackBar(context, s.tr('Step restored.', 'Langkah dipulihkan.'));
                              },
                              child: Text(s.restoreBtn),
                            ),
                            OutlinedButton(
                              key: Key('delete_perm_task_${t.id}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.miss(context),
                                side: BorderSide(color: AppColors.miss(context).withValues(alpha: 0.45)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(s.deletePermBtn),
                                    content: Text(
                                      s.tr(
                                        'Permanently delete "${t.name}" and its completion history? This cannot be undone.',
                                        'Hapus permanen "${t.name}" beserta riwayat ceklisnya? Tindakan ini tidak bisa dibatalkan.',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(s.cancelBtn),
                                      ),
                                      ElevatedButton(
                                        key: const Key('confirm_delete_perm_btn'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.miss(ctx),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(s.deletePermBtn),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await provider.deleteTaskPermanently(t.id);
                                  if (context.mounted) {
                                    showCalmSnackBar(context, s.tr('Step permanently deleted.', 'Langkah dihapus permanen.'));
                                  }
                                }
                              },
                              child: Text(s.deletePermBtn),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              ...provider.inactiveGroups.map((g) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${s.tr('Group', 'Kelompok')} ${g.name}'),
                    subtitle: Text('${g.taskCount} ${s.tr('steps', 'langkah')} · ${_fmtMs(g.deactivatedAt)}'),
                    trailing: TextButton(onPressed: () => provider.reactivateGroup(g.id), child: Text(s.restoreBtn)),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset('assets/icon.png', width: 20, height: 20, fit: BoxFit.cover),
              ),
              const SizedBox(width: 7),
              Text('Lifolio v0.3.1', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
