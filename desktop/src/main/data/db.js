const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');

class Database {
  constructor(dbPath) {
    if (dbPath !== ':memory:') {
      const dir = path.dirname(dbPath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    }
    this.sqlite = new DatabaseSync(dbPath);
    this.initSchema();
  }

  initSchema() {
    this.sqlite.exec(`
      CREATE TABLE IF NOT EXISTS groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        core INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        freq TEXT NOT NULL DEFAULT 'daily',
        freq_days TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS rewards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cost INTEGER NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at INTEGER,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS checks (
        task_id TEXT NOT NULL,
        day TEXT NOT NULL,
        checked INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (task_id, day)
      );

      CREATE TABLE IF NOT EXISTS claims (
        id TEXT PRIMARY KEY,
        reward_id TEXT,
        name TEXT NOT NULL,
        cost INTEGER NOT NULL,
        day TEXT NOT NULL,
        claimed_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );

      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        progress INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        project_id TEXT,
        day TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        note TEXT,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS finance_envelopes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        monthly_budget INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

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
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS health_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        kind TEXT NOT NULL,
        name TEXT,
        value_num REAL NOT NULL,
        value_num2 REAL,
        unit TEXT,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS wellness_entries (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        mood TEXT NOT NULL,
        mood_score INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        stress INTEGER NOT NULL,
        sleep_hours REAL NOT NULL,
        triggers_text TEXT,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

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
        seq INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        day TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        tags_json TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL DEFAULT 0
      );

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
    `);

    // Migrate existing DBs missing freq / freq_days on tasks
    const taskCols = this.sqlite.prepare('PRAGMA table_info(tasks)').all().map(c => c.name);
    if (!taskCols.includes('freq')) {
      this.sqlite.exec("ALTER TABLE tasks ADD COLUMN freq TEXT NOT NULL DEFAULT 'daily'");
    }
    if (!taskCols.includes('freq_days')) {
      this.sqlite.exec('ALTER TABLE tasks ADD COLUMN freq_days TEXT');
    }

    this.ensureMeta('server_seq', '0');
    this.ensureMeta('device_id', crypto.randomUUID());
    this.ensureMeta('device_name', 'Desktop');
    this.ensureMeta('pairing_code', Math.floor(100000 + Math.random() * 900000).toString());
    this.ensureMeta('paired_devices', '[]');
    this.ensureMeta('auto_sync', 'true');
    this.ensureMeta('minimize_to_tray', 'true');
    this.ensureMeta('token_ttl_days', '7');

    const groupCount = this.sqlite.prepare('SELECT COUNT(*) as count FROM groups').get().count;
    if (groupCount === 0) {
      this.seedData();
    }

    if (!this.getMeta('seed_ts_migrated')) {
      this.sqlite.exec(`
        UPDATE groups SET updated_at = 1 WHERE id LIKE 'seed-%' AND seq = 1;
        UPDATE tasks SET updated_at = 1 WHERE id LIKE 'seed-%' AND seq = 1;
        UPDATE rewards SET updated_at = 1 WHERE id LIKE 'seed-%' AND seq = 1;
      `);
      this.setMeta('seed_ts_migrated', '1');
    }
  }

  ensureMeta(key, defaultValue) {
    const row = this.sqlite.prepare('SELECT value FROM meta WHERE key = ?').get(key);
    if (!row) {
      this.sqlite.prepare('INSERT INTO meta (key, value) VALUES (?, ?)').run(key, defaultValue);
    }
  }

  getMeta(key) {
    const row = this.sqlite.prepare('SELECT value FROM meta WHERE key = ?').get(key);
    return row ? row.value : null;
  }

  setMeta(key, value) {
    this.sqlite.prepare('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)').run(key, value);
  }

  nextSeq() {
    const current = parseInt(this.getMeta('server_seq') || '0', 10) + 1;
    this.setMeta('server_seq', current.toString());
    return current;
  }

  seedData() {
    const seedUpdatedAt = 1;
    const seq = this.nextSeq();

    const groups = [
      { id: 'seed-group-pagi', name: 'Pagi', sort: 0 },
      { id: 'seed-group-siang', name: 'Siang', sort: 1 },
      { id: 'seed-group-malam', name: 'Malam', sort: 2 }
    ];

    const tasks = [
      { id: 'seed-task-p1', group_id: 'seed-group-pagi', name: 'Minum segelas air', core: 1, sort: 0 },
      { id: 'seed-task-p2', group_id: 'seed-group-pagi', name: 'Sarapan, yang sederhana pun cukup', core: 1, sort: 1 },
      { id: 'seed-task-p3', group_id: 'seed-group-pagi', name: 'Cuci muka dulu, mandi menyusul', core: 0, sort: 2 },
      { id: 'seed-task-p4', group_id: 'seed-group-pagi', name: 'Peregangan 3 menit', core: 0, sort: 3 },
      { id: 'seed-task-s1', group_id: 'seed-group-siang', name: 'Buka 1 chat saja, balas 1 kalimat', core: 0, sort: 0 },
      { id: 'seed-task-s2', group_id: 'seed-group-siang', name: 'Kerjakan 1 hal selama 10 menit', core: 0, sort: 1 },
      { id: 'seed-task-s3', group_id: 'seed-group-siang', name: 'Makan siang', core: 1, sort: 2 },
      { id: 'seed-task-m1', group_id: 'seed-group-malam', name: 'Gerak 5 menit (jalan kaki atau peregangan)', core: 0, sort: 0 },
      { id: 'seed-task-m2', group_id: 'seed-group-malam', name: 'Makan malam', core: 1, sort: 1 },
      { id: 'seed-task-m3', group_id: 'seed-group-malam', name: 'Mulai bersiap tidur di jam yang sama', core: 1, sort: 2 }
    ];

    const rewards = [
      { id: 'seed-reward-1', name: 'Dengar playlist favorit 15 menit', cost: 5, sort: 0 },
      { id: 'seed-reward-2', name: 'Satu episode serial', cost: 10, sort: 1 },
      { id: 'seed-reward-3', name: 'Gambar bebas 30 menit, tanpa target', cost: 15, sort: 2 },
      { id: 'seed-reward-4', name: 'Camilan favorit', cost: 20, sort: 3 }
    ];

    const insertGroup = this.sqlite.prepare(`
      INSERT INTO groups (id, name, sort, is_active, deactivated_at, updated_at, seq)
      VALUES (?, ?, ?, 1, NULL, ?, ?)
    `);
    for (const g of groups) {
      insertGroup.run(g.id, g.name, g.sort, seedUpdatedAt, seq);
    }

    const insertTask = this.sqlite.prepare(`
      INSERT INTO tasks (id, group_id, name, core, sort, is_active, deactivated_at, updated_at, seq)
      VALUES (?, ?, ?, ?, ?, 1, NULL, ?, ?)
    `);
    for (const t of tasks) {
      insertTask.run(t.id, t.group_id, t.name, t.core, t.sort, seedUpdatedAt, seq);
    }

    const insertReward = this.sqlite.prepare(`
      INSERT INTO rewards (id, name, cost, sort, is_active, deactivated_at, updated_at, seq)
      VALUES (?, ?, ?, ?, 1, NULL, ?, ?)
    `);
    for (const r of rewards) {
      insertReward.run(r.id, r.name, r.cost, r.sort, seedUpdatedAt, seq);
    }
  }

  close() {
    this.sqlite.close();
  }
}

module.exports = { Database };
