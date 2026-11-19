import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static Database? _database;
  final Database? customDb;

  DatabaseHelper({this.customDb});

  Future<Database> get database async {
    if (customDb != null) return customDb!;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<void> _addColumnIfMissing(Database db, String table, String colDef, String colName) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains(colName)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $colDef');
    }
  }

  static Future<String?> createPreM6Backup(String dbPath) async {
    final file = File(dbPath);
    if (!await file.exists()) return null;
    final backupPath = '$dbPath.pre-m6.bak';
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      await file.copy(backupPath);
    }
    return backupPath;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'langkah_kecil.db');
    await createPreM6Backup(path);
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await createTables(db);
        await seedDefaultData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(db, 'tasks', "freq TEXT NOT NULL DEFAULT 'daily'", 'freq');
          await _addColumnIfMissing(db, 'tasks', 'freq_days TEXT', 'freq_days');
        }
        if (oldVersion < 3) {
          await createLifeOsTables(db);
        }
        if (oldVersion < 4) {
          await upgradeToV4(db);
        }
      },
      onOpen: (db) async {
        await migrateUntouchedSeedRows(db);
        await ensureDefaultPrefsMeta(db);
      },
    );
  }

  static Future<void> ensureDefaultPrefsMeta(Database db) async {
    const defaults = {
      'color_palette': 'pink',
      'user_name': 'User',
      'language': 'en',
      'show_report_charts': 'true',
      'period_reminders': 'false',
      'water_goal_glasses': '8',
      'weight_goal_kg': '',
    };
    for (final e in defaults.entries) {
      await db.insert('meta', {'key': e.key, 'value': e.value}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final migrated = await db.query('meta', where: 'key = ?', whereArgs: ['user_name_default_v2']);
    if (migrated.isEmpty) {
      final cur = await db.query('meta', where: 'key = ?', whereArgs: ['user_name']);
      final cust = await db.query('meta', where: 'key = ?', whereArgs: ['user_name_customized']);
      if (cur.isNotEmpty && cur.first['value'] == 'Ara' && (cust.isEmpty || cust.first['value'] != 'true')) {
        await db.insert('meta', {'key': 'user_name', 'value': 'User'}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await db.insert('meta', {'key': 'user_name_default_v2', 'value': '1'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<void> upgradeToV4(Database db) async {
    await createLifeOsTables(db);
    await _addColumnIfMissing(db, 'tasks', "priority TEXT NOT NULL DEFAULT 'normal'", 'priority');
    await _addColumnIfMissing(db, 'tasks', 'due_date TEXT', 'due_date');
    await _addColumnIfMissing(db, 'projects', 'is_someday INTEGER NOT NULL DEFAULT 0', 'is_someday');
    await _addColumnIfMissing(db, 'health_entries', 'meal_slot TEXT', 'meal_slot');
    await _addColumnIfMissing(db, 'wellness_entries', 'gratitude_text TEXT', 'gratitude_text');
    await _addColumnIfMissing(db, 'notes', "category TEXT NOT NULL DEFAULT 'journal'", 'category');
    await _addColumnIfMissing(db, 'notes', 'is_pinned INTEGER NOT NULL DEFAULT 0', 'is_pinned');
    await ensureDefaultPrefsMeta(db);
  }

  static Future<void> migrateUntouchedSeedRows(Database db) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['seed_ts_migrated']);
    if (rows.isNotEmpty) return;

    await db.update('groups', {'updated_at': 1}, where: "id LIKE 'seed-%' AND dirty = 0");
    await db.update('tasks', {'updated_at': 1}, where: "id LIKE 'seed-%' AND dirty = 0");
    await db.update('rewards', {'updated_at': 1}, where: "id LIKE 'seed-%' AND dirty = 0");
    await db.insert(
      'meta',
      {'key': 'last_sync_cursor', 'value': '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'meta',
      {'key': 'seed_ts_migrated', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        core INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        freq TEXT NOT NULL DEFAULT 'daily',
        freq_days TEXT,
        priority TEXT NOT NULL DEFAULT 'normal',
        due_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE rewards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cost INTEGER NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE checks (
        task_id TEXT NOT NULL,
        day TEXT NOT NULL,
        checked INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (task_id, day)
      );
    ''');

    await db.execute('''
      CREATE TABLE claims (
        id TEXT PRIMARY KEY,
        reward_id TEXT,
        name TEXT NOT NULL,
        cost INTEGER NOT NULL,
        day TEXT NOT NULL,
        claimed_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    await createLifeOsTables(db);

    final uuid = const Uuid().v4();
    await db.insert('meta', {'key': 'device_id', 'value': uuid});
    await db.insert('meta', {'key': 'device_name', 'value': 'Ponsel'});
    await db.insert('meta', {'key': 'last_sync_cursor', 'value': '0'});
    await db.insert('meta', {'key': 'auto_sync', 'value': 'true'});
    await ensureDefaultPrefsMeta(db);
  }

  static Future<void> createLifeOsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        progress INTEGER NOT NULL DEFAULT 0,
        is_someday INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        project_id TEXT,
        day TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        note TEXT,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS finance_envelopes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        monthly_budget INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS finance_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        amount INTEGER NOT NULL,
        envelope_id TEXT,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL DEFAULT 0,
        current_amount INTEGER NOT NULL DEFAULT 0,
        deadline TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_bills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'bill',
        amount INTEGER NOT NULL DEFAULT 0,
        due_day INTEGER NOT NULL DEFAULT 1,
        is_paid INTEGER NOT NULL DEFAULT 0,
        last_paid_month TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        kind TEXT NOT NULL,
        name TEXT,
        meal_slot TEXT,
        value_num REAL NOT NULL,
        value_num2 REAL,
        unit TEXT,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wellness_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        mood TEXT NOT NULL,
        mood_score INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        stress INTEGER NOT NULL,
        sleep_hours REAL NOT NULL,
        triggers_text TEXT,
        gratitude_text TEXT,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS menstrual_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        phase TEXT NOT NULL,
        cycle_day INTEGER NOT NULL DEFAULT 1,
        flow TEXT,
        symptoms_json TEXT,
        is_period_start INTEGER NOT NULL DEFAULT 0,
        cycle_length INTEGER,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        tags_json TEXT,
        category TEXT NOT NULL DEFAULT 'journal',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        day TEXT NOT NULL,
        source TEXT NOT NULL,
        category TEXT NOT NULL,
        level TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        status_code INTEGER,
        error_code TEXT,
        message TEXT NOT NULL,
        details_json TEXT
      );
    ''');
  }

  static Future<void> seedDefaultData(Database db) async {
    const seedUpdatedAt = 1;

    final groups = [
      {'id': 'seed-group-pagi', 'name': 'Pagi', 'sort': 0},
      {'id': 'seed-group-siang', 'name': 'Siang', 'sort': 1},
      {'id': 'seed-group-malam', 'name': 'Malam', 'sort': 2},
    ];

    final tasks = [
      {'id': 'seed-task-p1', 'group_id': 'seed-group-pagi', 'name': 'Minum segelas air', 'core': 1, 'sort': 0},
      {'id': 'seed-task-p2', 'group_id': 'seed-group-pagi', 'name': 'Sarapan, yang sederhana pun cukup', 'core': 1, 'sort': 1},
      {'id': 'seed-task-p3', 'group_id': 'seed-group-pagi', 'name': 'Cuci muka dulu, mandi menyusul', 'core': 0, 'sort': 2},
      {'id': 'seed-task-p4', 'group_id': 'seed-group-pagi', 'name': 'Peregangan 3 menit', 'core': 0, 'sort': 3},
      {'id': 'seed-task-s1', 'group_id': 'seed-group-siang', 'name': 'Buka 1 chat saja, balas 1 kalimat', 'core': 0, 'sort': 0},
      {'id': 'seed-task-s2', 'group_id': 'seed-group-siang', 'name': 'Kerjakan 1 hal selama 10 menit', 'core': 0, 'sort': 1},
      {'id': 'seed-task-s3', 'group_id': 'seed-group-siang', 'name': 'Makan siang', 'core': 1, 'sort': 2},
      {'id': 'seed-task-m1', 'group_id': 'seed-group-malam', 'name': 'Gerak 5 menit (jalan kaki atau peregangan)', 'core': 0, 'sort': 0},
      {'id': 'seed-task-m2', 'group_id': 'seed-group-malam', 'name': 'Makan malam', 'core': 1, 'sort': 1},
      {'id': 'seed-task-m3', 'group_id': 'seed-group-malam', 'name': 'Mulai bersiap tidur di jam yang sama', 'core': 1, 'sort': 2},
    ];

    final rewards = [
      {'id': 'seed-reward-1', 'name': 'Dengar playlist favorit 15 menit', 'cost': 5, 'sort': 0},
      {'id': 'seed-reward-2', 'name': 'Satu episode serial', 'cost': 10, 'sort': 1},
      {'id': 'seed-reward-3', 'name': 'Gambar bebas 30 menit, tanpa target', 'cost': 15, 'sort': 2},
      {'id': 'seed-reward-4', 'name': 'Camilan favorit', 'cost': 20, 'sort': 3},
    ];

    for (final g in groups) {
      await db.insert('groups', {
        'id': g['id'],
        'name': g['name'],
        'sort': g['sort'],
        'is_active': 1,
        'deactivated_at': null,
        'updated_at': seedUpdatedAt,
        'dirty': 0,
      });
    }

    for (final t in tasks) {
      await db.insert('tasks', {
        'id': t['id'],
        'group_id': t['group_id'],
        'name': t['name'],
        'core': t['core'],
        'sort': t['sort'],
        'is_active': 1,
        'deactivated_at': null,
        'updated_at': seedUpdatedAt,
        'dirty': 0,
      });
    }

    for (final r in rewards) {
      await db.insert('rewards', {
        'id': r['id'],
        'name': r['name'],
        'cost': r['cost'],
        'sort': r['sort'],
        'is_active': 1,
        'deactivated_at': null,
        'updated_at': seedUpdatedAt,
        'dirty': 0,
      });
    }
    await db.insert(
      'meta',
      {'key': 'seed_ts_migrated', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
