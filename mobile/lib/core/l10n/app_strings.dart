class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  bool get isId => lang == 'id';

  String get hello => isId ? 'Halo' : 'Hello';
  String get navHome => isId ? 'Beranda' : 'Home';
  String get navTasks => isId ? 'Tugas' : 'Tasks';
  String get navMoney => isId ? 'Uang' : 'Money';
  String get navHealth => isId ? 'Sehat' : 'Health';
  String get navMore => isId ? 'Lainnya' : 'More';
  String get moreSpaces => isId ? 'Semua Ruang' : 'All Spaces';
  String get wellness => isId ? 'Kesejahteraan' : 'Wellness';
  String get menstrual => isId ? 'Siklus' : 'Menstrual';
  String get notes => isId ? 'Catatan' : 'Notes';
  String get rewards => isId ? 'Hadiah' : 'Rewards';
  String get history => isId ? 'Jejak' : 'History';
  String get auditLog => isId ? 'Log Audit' : 'Audit Log';
  String get settings => isId ? 'Pengaturan' : 'Settings';

  /// Inline bilingual helper for consistent English / Bahasa Indonesia UI copy.
  String tr(String en, String id) => isId ? id : en;

  String get saveBtn => tr('Save', 'Simpan');
  String get cancelBtn => tr('Cancel', 'Batal');
  String get editBtn => tr('Edit', 'Ubah');
  String get deleteBtn => tr('Delete', 'Hapus');
  String get restoreBtn => tr('Restore', 'Pulihkan');
  String get deletePermBtn => tr('Delete Permanently', 'Hapus Permanen');
  String get littleNoteTitle => tr('Little note', 'Catatan kecil');
  String get pinnedReminderBadge => tr('Pinned reminder', 'Pengingat disematkan');
  String get defaultMotivation => tr(
        'Small steps every day build a calmer, steadier rhythm.',
        'Langkah kecil setiap hari membangun ritme hidup yang lebih tenang dan terarah.',
      );
  String get yourSpaces => isId ? 'Ruang kamu' : 'Your spaces';
  String get todayTasks => isId ? 'Tugas hari ini' : "Today's tasks";
  String get customize => isId ? 'Atur' : 'Customize';
  String get done => isId ? 'Selesai' : 'Done';
  String get displayName => isId ? 'Nama tampilan' : 'Display name';
  String get paletteTitle => isId ? 'Palet warna' : 'Color palette';
  String get languageTitle => isId ? 'Bahasa' : 'Language';
  String get chartsTitle => isId ? 'Tampilkan grafik di laporan' : 'Show charts in reports';
  String get networkTitle => isId ? 'Jaringan Lokal & Sinkronisasi' : 'Local Network & Sync';
  String get phoneIp => isId ? 'IP Ponsel' : 'Phone IP';
  String get desktopIp => isId ? 'IP Desktop' : 'Desktop IP';
  String get manualSyncTitle => isId ? 'IP & Port Manual' : 'Manual IP & Port';
  String get manualHostLabel => isId ? 'IP / Host Desktop' : 'Desktop IP';
  String get manualPortLabel => 'Port';
  String get connectBtn => isId ? 'Simpan & Sambung' : 'Save & Connect';
  String get backupTitle => isId ? 'Cadangan & Pulihkan JSON' : 'JSON Backup & Restore';
  String get estDisclaimer => isId
      ? 'Prediksi siklus adalah perkiraan berdasarkan riwayat catatanmu, bukan kepastian medis.'
      : 'Cycle predictions are estimates based on your logged history, not medical certainty.';
}
