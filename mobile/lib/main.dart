import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/checklist_repository.dart';
import 'data/services/sync_service.dart';
import 'presentation/providers/checklist_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final repository = ChecklistRepository(dbHelper: dbHelper);
  final syncService = SyncService(repository: repository);
  final provider = ChecklistProvider(
    repository: repository,
    syncService: syncService,
  );
  await provider.init();

  runApp(LangkahKecilApp(provider: provider));
}

class LangkahKecilApp extends StatelessWidget {
  final ChecklistProvider provider;
  final bool useGoogleFonts;

  const LangkahKecilApp({
    super.key,
    required this.provider,
    this.useGoogleFonts = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<ChecklistProvider>(
        builder: (context, prov, _) {
          return MaterialApp(
            title: 'Langkah Kecil',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
            darkTheme: AppTheme.dark(useGoogleFonts: useGoogleFonts),
            themeMode: prov.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
