const api = window.electronAPI;

export const I18N = {
  en: {
    brand_sub: 'Personal Life OS',
    nav_main: 'Main',
    nav_home: 'Home',
    nav_today: 'Today Checklist',
    nav_spaces: 'Workspaces',
    nav_rewards: 'Rewards',
    nav_system: 'Trail & System',
    nav_history: 'History',
    nav_inactive: 'Inactive',
    nav_audit: 'Audit Log',
    nav_settings: 'Settings',
    mod_productivity: 'Productivity',
    mod_finance: 'Finance',
    mod_health: 'Health',
    mod_wellness: 'Wellness',
    mod_menstrual: 'Menstrual Cycle',
    mod_notes: 'Notes & Journal',
    home_spaces: 'Your spaces',
    home_spaces_sub: 'Everything you need, in one place.',
    hero_title: 'Take it one step at a time.',
    hero_sub: "You don't have to do everything today.",
    ach_title: 'Achievements',
    ach_sub: 'Unlocked from your real activity',
    pts_yours: 'YOUR POINTS',
    pts_note: 'Every checked step earns 1 point. Missed days never take points away.',
    claimed_title: 'Reward history',
    claimed_sub: 'Recently claimed',
    search_ph: 'Search tasks, notes, finance...',
    today_tasks: "Today's tasks",
    open_full_checklist: 'Open full checklist',
    add_step_ph: 'Add a small step for today...',
    add_btn: 'Add',
    save_btn: 'Save',
    cancel_btn: 'Cancel',
    edit_btn: 'Edit',
    done_btn: 'Done',
    delete_btn: 'Delete',
    restore_btn: 'Restore',
    delete_perm_btn: 'Delete Permanently',
    range_week: 'Weekly',
    range_month: 'Monthly',
    range_year: 'Yearly',
    range_custom: 'Custom',
    est_disclaimer: 'Cycle predictions are estimates based on your logged history, not medical certainty.',
    quick_add: 'Quick Add',
    sync_active: 'Sync active',
    quit_btn: 'Quit',
    cal_btn: '📅 Calendar',
    widgets_btn: '⊞ Widgets',
    add_widget_btn: '＋ Add Widget',
    reset_layout_btn: 'Reset Layout',
    clear_logs_btn: 'Clear Logs',
    undo_btn: 'Undo',
  },
  id: {
    brand_sub: 'Sistem Hidup Pribadi',
    nav_main: 'Utama',
    nav_home: 'Beranda',
    nav_today: 'Ceklis Hari Ini',
    nav_spaces: 'Ruang Kerja',
    nav_rewards: 'Hadiah',
    nav_system: 'Jejak & Sistem',
    nav_history: 'Riwayat',
    nav_inactive: 'Nonaktif',
    nav_audit: 'Log Audit',
    nav_settings: 'Pengaturan',
    mod_productivity: 'Produktivitas',
    mod_finance: 'Keuangan',
    mod_health: 'Kesehatan',
    mod_wellness: 'Kesejahteraan',
    mod_menstrual: 'Siklus Menstruasi',
    mod_notes: 'Catatan & Jurnal',
    home_spaces: 'Ruang kamu',
    home_spaces_sub: 'Semua yang kamu butuhkan di satu tempat.',
    hero_title: 'Satu langkah demi satu langkah.',
    hero_sub: 'Kamu tidak harus menyelesaikan semuanya hari ini.',
    ach_title: 'Pencapaian',
    ach_sub: 'Terbuka otomatis dari aktivitas nyatamu',
    pts_yours: 'POIN KAMU',
    pts_note: 'Setiap langkah selesai bernilai 1 poin. Hari yang terlewat tidak pernah mengurangi poin.',
    claimed_title: 'Riwayat hadiah',
    claimed_sub: 'Baru diambil',
    search_ph: 'Cari tugas, catatan, keuangan...',
    today_tasks: 'Tugas hari ini',
    open_full_checklist: 'Buka ceklis lengkap',
    add_step_ph: 'Tambah langkah kecil hari ini...',
    add_btn: 'Tambah',
    save_btn: 'Simpan',
    cancel_btn: 'Batal',
    edit_btn: 'Ubah',
    done_btn: 'Selesai',
    delete_btn: 'Hapus',
    restore_btn: 'Pulihkan',
    delete_perm_btn: 'Hapus Permanen',
    range_week: 'Mingguan',
    range_month: 'Bulanan',
    range_year: 'Tahunan',
    range_custom: 'Kustom',
    est_disclaimer: 'Prediksi siklus adalah perkiraan berdasarkan riwayat catatanmu, bukan kepastian medis.',
    quick_add: 'Tambah Cepat',
    sync_active: 'Sinkron aktif',
    quit_btn: 'Keluar',
    cal_btn: '📅 Kalender',
    widgets_btn: '⊞ Widget',
    add_widget_btn: '＋ Tambah Widget',
    reset_layout_btn: 'Atur Ulang Tata Letak',
    clear_logs_btn: 'Bersihkan Log',
    undo_btn: 'Urungkan',
  },
};

export function tr(lang, key) {
  const dict = I18N[lang === 'id' ? 'id' : 'en'] || I18N.en;
  return dict[key] || I18N.en[key] || key;
}

export function L(en, id) {
  return lifeState.lang === 'id' ? id : en;
}

const WIDGET_CATALOG = [
  { id: 'w-prod', module: 'Productivity', badge: 't-sage', title: 'Productivity & Focus', reportMod: 'productivity', defaultSize: 'm' },
  { id: 'w-fin',  module: 'Finance', badge: 't-butter', title: 'Finance & Budget', reportMod: 'finance', defaultSize: 'm' },
  { id: 'w-hlth', module: 'Health', badge: 't-sky', title: 'Health & Hydration', reportMod: 'health', defaultSize: 's' },
  { id: 'w-well', module: 'Wellness', badge: 't-lavender', title: 'Wellness Check-in', reportMod: 'wellness', defaultSize: 's' },
  { id: 'w-mens', module: 'Menstrual Cycle', badge: 't-blush', title: 'Menstrual Cycle', reportMod: 'menstrual', defaultSize: 's' },
  { id: 'w-note', module: 'Notes & Journal', badge: 't-peach', title: 'Notes & Journal', reportMod: 'notes', defaultSize: 'm' },
  { id: 'w-rew',  module: 'Rewards', badge: 't-butter', title: 'Rewards & Points', reportMod: null, defaultSize: 'm' },
];

export const lifeState = {
  customizeMode: false,
  editSpaces: false,
  littleNoteEditing: false,
  reportModule: 'productivity',
  reportRange: 'month',
  customStart: '',
  customEnd: '',
  auditFilter: 'all',
  auditSource: 'all',
  dragWid: null,
  lang: 'en',
  searchQuery: '',
  finFilter: 'all',
  finEditId: null,
  envEditId: null,
  prodTab: 'today',
  noteCat: 'all',
  selectedNoteId: null,
  wellnessMood: 'Calm',
  wellnessMoodScore: 4,
  selectedSymptoms: [],
  pomoSeconds: 25 * 60,
  pomoRunning: false,
  pomoTimer: null,
};

function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
}

function fmtRp(n) {
  return 'Rp ' + Math.round(n || 0).toLocaleString('id-ID');
}

function fmtDateTime(ms) {
  if (!ms) return '';
  const d = new Date(ms);
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function renderWidgetBody(id, summary) {
  if (!summary) return `<p class="muted small">${L('Loading...', 'Memuat...')}</p>`;
  if (id === 'w-prod') {
    const p = summary.productivity;
    const pct = p.total > 0 ? Math.round((p.done / p.total) * 100) : 0;
    return `
      <div class="big num">${p.done}<small> / ${p.total} ${L('tasks', 'tugas')}</small></div>
      <div class="progress"><span style="width:${pct}%"></span></div>
      <p class="muted small" style="margin:0">${pct}% ${L('done today', 'selesai hari ini')} · ${p.focusMinutesToday}m ${L('focus logged', 'fokus tercatat')}</p>
    `;
  }
  if (id === 'w-fin') {
    const f = summary.finance;
    return `
      <div class="big num">${fmtRp(f.balance)}</div>
      <p class="muted small" style="margin:0">${L('In', 'Masuk')} ${fmtRp(f.income)} · ${L('Out', 'Keluar')} ${fmtRp(f.expense)} · ${f.unpaidBills || 0} ${L('unpaid bills', 'tagihan belum bayar')}</p>
    `;
  }
  if (id === 'w-hlth') {
    const h = summary.health;
    return `
      <div class="big num">${h.latestWeight !== null ? `${h.latestWeight} kg` : '—'}</div>
      <p class="muted small" style="margin:0">${L('Water', 'Air')}: ${Math.round(h.waterTodayMl)} ml · ${L('Food', 'Makan')}: ${Math.round(h.kcalToday)} kcal</p>
    `;
  }
  if (id === 'w-well') {
    const w = summary.wellness;
    return `
      <div class="big">${w ? esc(w.mood) : L('No check-in', 'Belum diisi')}</div>
      <p class="muted small" style="margin:0">${w ? `${L('Energy', 'Energi')} ${w.energy}/5 · ${L('Stress', 'Stres')} ${w.stress}/5 · ${L('Sleep', 'Tidur')} ${w.sleep_hours}h` : L('Log a daily mood check-in.', 'Catat suasana hatimu hari ini.')}</p>
    `;
  }
  if (id === 'w-mens') {
    const m = summary.menstrual;
    return `
      <div class="big">${m ? `${L('Day', 'Hari')} ${m.cycle_day}` : L('No log', 'Belum ada')}</div>
      <p class="muted small" style="margin:0">${m ? `${esc(m.phase)}${m.symptoms.length ? ' · ' + esc(m.symptoms.join(', ')) : ''}` : L('Track period & cycle estimates.', 'Catat siklus & prakiraan haid.')}</p>
    `;
  }
  if (id === 'w-note') {
    const n = summary.notes;
    return `
      <div class="big num">${n.count}<small> ${L('notes', 'catatan')}</small></div>
      <p class="muted small" style="margin:0">${n.latestTitle ? `${L('Latest', 'Terbaru')}: "${esc(n.latestTitle)}"` : L('Write a quick reflection or brain dump.', 'Tulis refleksi atau curahan pikiranmu.')}</p>
    `;
  }
  if (id === 'w-rew') {
    const r = summary.rewards;
    return `
      <div class="big num">${r.balance}<small> ${L('pts available', 'poin tersedia')}</small></div>
      <p class="muted small" style="margin:0">${r.activeCount} ${L('rewards ready to claim', 'hadiah siap ditukar')}</p>
    `;
  }
  return '';
}

export async function refreshAuditBadge(todayStr) {
  const s = await api.getLifeOsSummary(todayStr);
  const badge = document.getElementById('navAuditErr');
  if (badge) {
    badge.textContent = String(s.errorAuditCount || 0);
    badge.hidden = !s.errorAuditCount;
  }
  return s;
}

export async function loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast }) {
  const [summary, todayData] = await Promise.all([
    api.getLifeOsSummary(todayStr),
    api.getToday(todayStr),
  ]);
  const layout = summary.layout && summary.layout.length
    ? summary.layout
    : WIDGET_CATALOG.map(w => ({ id: w.id, visible: true, size: w.defaultSize }));
  const visCountEl = document.getElementById('lifeosVisCount');
  if (visCountEl) {
    visCountEl.textContent = `${layout.filter(w => w.visible).length}/${layout.length} ${L('visible', 'tampil')}`;
  }

  // Inline Today's tasks card on Home
  const q = lifeState.searchQuery.trim().toLowerCase();
  const homeTasksCard = document.getElementById('homeQuickTasksCard');
  if (homeTasksCard) {
    const allSched = todayData.groups.flatMap(g => g.tasks.filter(t => t.scheduled).map(t => ({ ...t, groupName: g.name })));
    const filtered = q ? allSched.filter(t => t.name.toLowerCase().includes(q)) : allSched;
    const doneCnt = allSched.filter(t => t.done).length;
    const pct = allSched.length > 0 ? Math.round((doneCnt / allSched.length) * 100) : 0;
    homeTasksCard.innerHTML = `
      <div class="head" style="margin-bottom:4px">
        <h3 style="margin:0">${tr(lifeState.lang, 'today_tasks')}</h3>
        <span class="small muted num">${L(`${doneCnt} of ${allSched.length} done`, `${doneCnt} dari ${allSched.length} selesai`)}</span>
      </div>
      <div class="progress"><span style="width:${pct}%"></span></div>
      <ul class="list" style="margin-top:6px">
        ${filtered.slice(0, 6).map(t => `
          <li>
            <label style="display:flex;align-items:center;gap:10px;cursor:pointer;flex:1">
              <input type="checkbox" class="home-task-cb" data-tid="${t.id}" ${t.done ? 'checked' : ''} style="width:16px;height:16px;accent-color:var(--accent)">
              <span style="${t.done ? 'text-decoration:line-through;color:var(--muted)' : ''}">${esc(t.name)}</span>
              ${t.priority === 'high' ? `<span class="pill">${L('Priority', 'Prioritas')}</span>` : ''}
            </label>
          </li>
        `).join('')}
        ${filtered.length === 0 ? `<li class="muted">${L('No scheduled tasks match right now.', 'Tidak ada tugas terjadwal yang cocok.')}</li>` : ''}
      </ul>
      <div class="row" style="margin-top:10px">
        <input id="homeQuickTaskIn" type="text" placeholder="${tr(lifeState.lang, 'add_step_ph')}" style="flex:1;min-height:36px;padding:0 11px;border-radius:10px;border:1px solid var(--line);background:var(--bg)">
        <button class="btn primary" type="button" id="homeQuickTaskBtn" style="min-height:36px">${tr(lifeState.lang, 'add_btn')}</button>
        <button class="btn" type="button" id="homeOpenChecklistBtn" style="min-height:36px;background:var(--soft);color:var(--accent-deep)">${tr(lifeState.lang, 'open_full_checklist')} →</button>
      </div>
    `;
    document.getElementById('homeOpenChecklistBtn').onclick = () => onOpenToday();
    const saveHomeTask = async () => {
      const inp = document.getElementById('homeQuickTaskIn');
      const name = inp.value.trim();
      if (!name) return;
      await api.quickAdd({ kind: 'task', data: { name, day: todayStr } });
      inp.value = '';
      await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      showToast(L('Task added.', 'Tugas ditambahkan.'));
    };
    document.getElementById('homeQuickTaskBtn').onclick = saveHomeTask;
    document.getElementById('homeQuickTaskIn').onkeydown = e => { if (e.key === 'Enter') saveHomeTask(); };
    homeTasksCard.querySelectorAll('.home-task-cb').forEach(cb => {
      cb.onchange = async () => {
        await api.toggleCheck({ taskId: cb.dataset.tid, day: todayStr, checked: cb.checked });
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      };
    });
  }

  // Directly Editable "Your spaces" menu on Home
  const spacesEl = document.getElementById('homeSpacesGrid');
  if (spacesEl) {
    const spaceDefs = {
      'w-fin':  { mod: 'finance', ic: '♡', defaultName: tr(lifeState.lang, 'mod_finance'), sub: L('Money & budget', 'Uang & anggaran') },
      'w-prod': { mod: 'productivity', ic: '☷', defaultName: tr(lifeState.lang, 'mod_productivity'), sub: L('Tasks & plans', 'Tugas & rencana') },
      'w-hlth': { mod: 'health', ic: '✿', defaultName: tr(lifeState.lang, 'mod_health'), sub: L('Body & movement', 'Tubuh & gerak') },
      'w-well': { mod: 'wellness', ic: '☁', defaultName: tr(lifeState.lang, 'mod_wellness'), sub: L('Mood & self-care', 'Suasana hati') },
      'w-mens': { mod: 'menstrual', ic: '▦', defaultName: tr(lifeState.lang, 'mod_menstrual'), sub: L('Cycle & symptoms', 'Siklus & gejala') },
      'w-note': { mod: 'notes', ic: '✎', defaultName: tr(lifeState.lang, 'mod_notes'), sub: L('Thoughts & ideas', 'Pikiran & ide') },
      'w-rew':  { rewards: true, ic: '☆', defaultName: tr(lifeState.lang, 'nav_rewards'), sub: `${summary.rewards.balance} ${L('pts', 'poin')}` },
    };
    const editBtn = document.getElementById('editSpacesBtn');
    const resetSpBtn = document.getElementById('resetSpacesBtn');
    if (editBtn) {
      editBtn.textContent = lifeState.editSpaces ? L('Done', 'Selesai') : L('Edit', 'Ubah');
      editBtn.setAttribute('aria-pressed', lifeState.editSpaces ? 'true' : 'false');
    }
    if (resetSpBtn) {
      resetSpBtn.textContent = L('Reset', 'Atur ulang');
      resetSpBtn.hidden = !lifeState.editSpaces;
    }

    const visibleSpaces = lifeState.editSpaces ? layout : layout.filter(w => w.visible !== false);
    spacesEl.innerHTML = visibleSpaces.map((w, idx) => {
      const def = spaceDefs[w.id];
      if (!def) return '';
      const displayName = (w.label && w.label.trim()) ? w.label.trim() : def.defaultName;
      if (lifeState.editSpaces) {
        return `
          <div class="space-tile ${w.visible === false ? 'hidden-space' : ''}" style="cursor:default">
            <span class="symbol">${def.ic}</span>
            <input class="sp-name-in" data-spid="${w.id}" value="${esc(displayName)}" aria-label="${L('Space label', 'Nama ruang')}"
              style="width:100%;border:1px solid var(--line);border-radius:8px;padding:4px 7px;font-weight:700;font-size:.82rem;background:var(--bg)">
            <div class="edit-strip">
              <button class="mini-btn sp-move" type="button" data-spid="${w.id}" data-d="-1" ${idx === 0 ? 'disabled' : ''}>←</button>
              <button class="mini-btn sp-move" type="button" data-spid="${w.id}" data-d="1" ${idx === visibleSpaces.length - 1 ? 'disabled' : ''}>→</button>
              <button class="mini-btn sp-vis" type="button" data-spid="${w.id}">${w.visible === false ? L('Show', 'Tampilkan') : L('Hide', 'Sembunyikan')}</button>
            </div>
          </div>
        `;
      }
      return `
        <button type="button" class="space-tile" ${def.rewards ? 'data-openrew="1"' : `data-opensp="${def.mod}"`}>
          <div>
            <span class="symbol">${def.ic}</span>
            <strong style="display:block;font-size:13px">${esc(displayName)}</strong>
            <small class="muted" style="font-size:11px">${esc(def.sub)}</small>
          </div>
        </button>
      `;
    }).join('');

    if (lifeState.editSpaces) {
      spacesEl.querySelectorAll('.sp-name-in').forEach(inp => {
        inp.onchange = async () => {
          const w = layout.find(x => x.id === inp.dataset.spid);
          if (w) {
            w.label = inp.value.trim();
            await api.saveDashboardLayout(layout);
            await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
          }
        };
      });
      spacesEl.querySelectorAll('.sp-move').forEach(b => {
        b.onclick = async () => {
          const i = layout.findIndex(x => x.id === b.dataset.spid);
          const j = i + Number(b.dataset.d);
          if (i > -1 && j >= 0 && j < layout.length) {
            [layout[i], layout[j]] = [layout[j], layout[i]];
            await api.saveDashboardLayout(layout);
            await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
          }
        };
      });
      spacesEl.querySelectorAll('.sp-vis').forEach(b => {
        b.onclick = async () => {
          const w = layout.find(x => x.id === b.dataset.spid);
          if (w) {
            w.visible = w.visible === false;
            await api.saveDashboardLayout(layout);
            await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
          }
        };
      });
    } else {
      spacesEl.querySelectorAll('[data-opensp]').forEach(b => { b.onclick = () => onOpenReport(b.dataset.opensp); });
      const rewBtn = spacesEl.querySelector('[data-openrew]');
      if (rewBtn) rewBtn.onclick = () => onOpenRewards();
    }
  }

  // Right column 1: Mini Calendar Card
  const calCard = document.getElementById('homeMiniCalCard');
  if (calCard) {
    const [y, m, dNum] = todayStr.split('-').map(Number);
    const first = new Date(y, m - 1, 1);
    const offset = (first.getDay() + 6) % 7;
    const dim = new Date(y, m, 0).getDate();
    const monthLabel = first.toLocaleString(lifeState.lang === 'id' ? 'id-ID' : 'en-US', { month: 'long', year: 'numeric' });
    const dows = lifeState.lang === 'id' ? ['S', 'S', 'R', 'K', 'J', 'S', 'M'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    let cells = dows.map(d => `<span class="dow">${d}</span>`).join('');
    for (let i = 0; i < offset; i++) cells += '<span></span>';
    for (let i = 1; i <= dim; i++) cells += `<span class="${i === dNum ? 'today' : ''}">${i}</span>`;
    calCard.innerHTML = `<h3 style="margin:0 0 10px">${monthLabel}</h3><div class="mini-cal-grid">${cells}</div>`;
  }

  // Right column 2: How are you feeling? (live Mood check-in)
  const moodCard = document.getElementById('homeMoodCard');
  if (moodCard) {
    const moods = [
      { em: '😊', m: 'Happy', lb: L('Happy', 'Senang'), sc: 5 },
      { em: '🙂', m: 'Calm', lb: L('Calm', 'Tenang'), sc: 4 },
      { em: '😐', m: 'Neutral', lb: L('Neutral', 'Biasa'), sc: 3 },
      { em: '😔', m: 'Tired', lb: L('Tired', 'Lelah'), sc: 2 },
      { em: '😣', m: 'Stressed', lb: L('Stressed', 'Tertekan'), sc: 1 },
    ];
    const latestMood = summary.wellness?.mood;
    const matchedMood = moods.find(x => x.m === latestMood);
    moodCard.innerHTML = `
      <h3 style="margin:0 0 10px">${L('How are you feeling?', 'Bagaimana perasaanmu hari ini?')}</h3>
      <div class="mood-emoji-row">
        ${moods.map(x => `<button type="button" class="mood-emoji-btn" data-hmood="${x.m}" data-hlb="${x.lb}" data-hsc="${x.sc}" aria-pressed="${latestMood === x.m}" title="${x.lb}">${x.em}</button>`).join('')}
      </div>
      <p class="small muted" style="margin:8px 0 0">${latestMood ? `${L('Latest', 'Terbaru')}: ${esc(matchedMood ? matchedMood.lb : latestMood)} · ${L('Tap any emoji to check in.', 'Ketuk emoji untuk mencatat.')}` : L('A quick check-in. No pressure.', 'Catatan singkat, tanpa tekanan.')}</p>
    `;
    moodCard.querySelectorAll('.mood-emoji-btn').forEach(b => {
      b.onclick = async () => {
        await api.saveWellnessEntry({ day: todayStr, mood: b.dataset.hmood, mood_score: Number(b.dataset.hsc), energy: 4, stress: 2, sleep_hours: 7 });
        showToast(`${L('Mood saved', 'Suasana hati tersimpan')}: ${b.dataset.hlb}`);
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      };
    });
  }

  // Right column 3: Little note as Pinned Motivational Reminder card
  const lnCard = document.getElementById('homeLittleNoteCard');
  if (lnCard) {
    const rem = summary?.notes?.pinnedReminder;
    const defaultMotivation = L(
      'Small steps every day build a calmer, steadier rhythm.',
      'Langkah kecil setiap hari membangun ritme hidup yang lebih tenang dan terarah.',
    );
    const quoteText = (rem?.body && rem.body.trim()) ? rem.body.trim() : defaultMotivation;
    lnCard.innerHTML = `
      <div class="head" style="margin:0 0 10px">
        <div class="row" style="gap:8px;align-items:center">
          <h3 style="margin:0">${L('Little note', 'Catatan kecil')}</h3>
          <span class="pill-m6">📌 ${L('Pinned reminder', 'Pengingat disematkan')}</span>
        </div>
        <button class="mini-btn" id="homeLittleNoteToggleBtn" type="button">
          ${lifeState.littleNoteEditing ? L('Cancel', 'Batal') : `✎ ${L('Edit', 'Ubah')}`}
        </button>
      </div>
      <div class="note-box-m6" style="margin-bottom:${lifeState.littleNoteEditing ? '10px' : '0'}">
        <h4 style="margin:0 0 4px">${esc(rem?.title || L('Motivational Reminder ♡', 'Pengingat Motivasi ♡'))}</h4>
        <p style="margin:0;line-height:1.5;font-size:.94rem">${esc(quoteText)}</p>
      </div>
      ${lifeState.littleNoteEditing ? `
        <textarea id="homeLittleNoteBody" class="field" rows="3" placeholder="${L('Write a motivational reminder to pin here...', 'Tulis kata motivasi untuk disematkan di sini...')}" style="width:100%;border:1px solid var(--line);border-radius:10px;padding:10px;background:var(--bg);font-size:.92rem">${esc(rem?.body || '')}</textarea>
        <div class="row" style="justify-content:flex-end;gap:8px;margin-top:8px">
          <button class="btn primary" id="homeLittleNoteBtn" type="button">${L('Save reminder', 'Simpan pengingat')}</button>
        </div>
      ` : ''}
    `;
    document.getElementById('homeLittleNoteToggleBtn').onclick = () => {
      lifeState.littleNoteEditing = !lifeState.littleNoteEditing;
      loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
    };
    const saveRemBtn = document.getElementById('homeLittleNoteBtn');
    if (saveRemBtn) {
      saveRemBtn.onclick = async () => {
        const body = document.getElementById('homeLittleNoteBody').value.trim();
        if (!body) return;
        await api.saveNote({
          id: rem?.id || 'little-note-motivation',
          day: todayStr,
          title: L('Motivational Reminder ♡', 'Pengingat Motivasi ♡'),
          body,
          category: 'gratitude',
          is_pinned: 1,
        });
        lifeState.littleNoteEditing = false;
        showToast(L('Pinned reminder updated.', 'Pengingat motivasi diperbarui.'));
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      };
    }
  }

  const grid = document.getElementById('lifeosWidgetGrid');
  if (!grid) return;

  grid.hidden = !lifeState.customizeMode;
  if (!lifeState.customizeMode) return;

  const list = layout;
  grid.innerHTML = list.map((w, idx) => {
    const def = WIDGET_CATALOG.find(d => d.id === w.id) || WIDGET_CATALOG[0];
    const hiddenDim = (!w.visible && lifeState.customizeMode) ? 'opacity:.45;' : '';
    return `
      <article class="widget-card ${lifeState.customizeMode ? 'customizing' : ''}"
        data-wid="${w.id}" data-size="${w.size}" draggable="${lifeState.customizeMode}" style="${hiddenDim}">
        <div class="head" style="margin:0">
          <div class="row" style="gap:8px">
            <span class="pill ${def.badge}">${def.module}</span>
            <h2 style="font-size:1rem">${def.title}</h2>
          </div>
          ${def.reportMod ? `<button class="mini-btn" type="button" data-wopen="${def.reportMod}">${L('Open →', 'Buka →')}</button>`
            : `<button class="mini-btn" type="button" data-wrew="1">${L('Rewards →', 'Hadiah →')}</button>`}
        </div>
        <div>${renderWidgetBody(w.id, summary)}</div>
        ${lifeState.customizeMode ? `
          <div class="w-edit-bar">
            <div class="row" style="gap:4px">
              <button class="mini-btn" type="button" data-wmove="${w.id}" data-d="-1" ${idx === 0 ? 'disabled' : ''}>↑</button>
              <button class="mini-btn" type="button" data-wmove="${w.id}" data-d="1" ${idx === list.length - 1 ? 'disabled' : ''}>↓</button>
              ${['s', 'm', 'l'].map(sz => `<button class="mini-btn" type="button" data-wsize="${w.id}" data-sz="${sz}" aria-pressed="${w.size === sz}">${sz.toUpperCase()}</button>`).join('')}
            </div>
            <div class="row" style="gap:4px">
              <button class="mini-btn" type="button" data-wvis="${w.id}">${w.visible ? L('Hide', 'Sembunyikan') : L('Show', 'Tampilkan')}</button>
              <button class="mini-btn" type="button" data-wrem="${w.id}" style="color:var(--miss)">✕</button>
            </div>
          </div>
        ` : ''}
      </article>
    `;
  }).join('');

  grid.querySelectorAll('[data-wopen]').forEach(btn => { btn.onclick = () => onOpenReport(btn.dataset.wopen); });
  const wRewBtn = grid.querySelector('[data-wrew]');
  if (wRewBtn) wRewBtn.onclick = () => onOpenRewards();

  grid.querySelectorAll('[data-wmove]').forEach(btn => {
    btn.onclick = async () => {
      const i = layout.findIndex(x => x.id === btn.dataset.wmove);
      const j = i + Number(btn.dataset.d);
      if (i > -1 && j >= 0 && j < layout.length) {
        [layout[i], layout[j]] = [layout[j], layout[i]];
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wsize]').forEach(btn => {
    btn.onclick = async () => {
      const w = layout.find(x => x.id === btn.dataset.wsize);
      if (w) {
        w.size = btn.dataset.sz;
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wvis]').forEach(btn => {
    btn.onclick = async () => {
      const w = layout.find(x => x.id === btn.dataset.wvis);
      if (w) {
        w.visible = !w.visible;
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wrem]').forEach(btn => {
    btn.onclick = async () => {
      const next = layout.filter(x => x.id !== btn.dataset.wrem);
      await api.saveDashboardLayout(next);
      showToast(L('Widget removed.', 'Widget dihapus.'));
      await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
    };
  });
  if (lifeState.customizeMode) {
    grid.querySelectorAll('.widget-card').forEach(card => {
      card.addEventListener('dragstart', () => { lifeState.dragWid = card.dataset.wid; card.classList.add('dragging'); });
      card.addEventListener('dragend', () => { card.classList.remove('dragging'); grid.querySelectorAll('.widget-card').forEach(c => c.classList.remove('drag-over')); });
      card.addEventListener('dragover', e => { e.preventDefault(); card.classList.add('drag-over'); });
      card.addEventListener('dragleave', () => card.classList.remove('drag-over'));
      card.addEventListener('drop', async e => {
        e.preventDefault();
        const tid = card.dataset.wid;
        if (lifeState.dragWid && tid && lifeState.dragWid !== tid) {
          const from = layout.findIndex(w => w.id === lifeState.dragWid);
          const to = layout.findIndex(w => w.id === tid);
          if (from > -1 && to > -1) {
            const [item] = layout.splice(from, 1);
            layout.splice(to, 0, item);
            await api.saveDashboardLayout(layout);
            await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
          }
        }
      });
    });
  }
}

export async function openWidgetCatalogModal({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast }) {
  const layout = await api.getDashboardLayout();
  const modal = document.getElementById('lifeosModal');
  const card = document.getElementById('lifeosModalCard');
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">${L('Widget Catalog', 'Katalog Widget')}</p><h2>${L('Customize Dashboard', 'Atur Dasbor')}</h2></div>
      <button class="icon-btn" type="button" id="lmClose">×</button>
    </div>
    <ul class="list">
      ${WIDGET_CATALOG.map(def => {
        const cur = layout.find(w => w.id === def.id);
        return `
          <li>
            <span><span class="pill ${def.badge}">${def.module}</span> <b>${def.title}</b></span>
            ${cur
              ? `<button class="mini-btn" type="button" data-cvis="${def.id}">${cur.visible ? L('Visible ✓', 'Tampil ✓') : L('Hidden', 'Tersembunyi')}</button>`
              : `<button class="mini-btn" type="button" data-cadd="${def.id}">${L('＋ Add', '＋ Tambah')}</button>`}
          </li>
        `;
      }).join('')}
    </ul>
  `;
  modal.hidden = false;
  document.getElementById('lmClose').onclick = () => { modal.hidden = true; };
  card.querySelectorAll('[data-cvis]').forEach(b => {
    b.onclick = async () => {
      const w = layout.find(x => x.id === b.dataset.cvis);
      if (w) w.visible = !w.visible;
      await api.saveDashboardLayout(layout);
      await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      await openWidgetCatalogModal({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
    };
  });
  card.querySelectorAll('[data-cadd]').forEach(b => {
    b.onclick = async () => {
      const def = WIDGET_CATALOG.find(x => x.id === b.dataset.cadd);
      if (def) layout.push({ id: def.id, visible: true, size: def.defaultSize });
      await api.saveDashboardLayout(layout);
      await loadLifeOsDashboard({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
      await openWidgetCatalogModal({ todayStr, onOpenReport, onOpenRewards, onOpenToday, showToast });
    };
  });
}

function fmtClock(sec) {
  const m = String(Math.floor(sec / 60)).padStart(2, '0');
  const s = String(sec % 60).padStart(2, '0');
  return `${m}:${s}`;
}

function buildMonthCalendarHtml(todayStr, highlightDays = new Set()) {
  const parts = (todayStr || '2026-11-18').split('-').map(Number);
  const year = parts[0] || 2026;
  const month = parts[1] || 11;
  const firstDow = (new Date(year, month - 1, 1).getDay() + 6) % 7;
  const daysInMonth = new Date(year, month, 0).getDate();
  const dowLabels = lifeState.lang === 'id' ? ['S', 'S', 'R', 'K', 'J', 'S', 'M'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const dows = dowLabels.map(d => `<span class="day">${d}</span>`).join('');
  const blanks = Array.from({ length: firstDow }, () => '<span></span>').join('');
  const cells = Array.from({ length: daysInMonth }, (_, idx) => {
    const d = idx + 1;
    const ds = `${year}-${String(month).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const cls = ds === todayStr ? 'today' : (highlightDays.has(ds) ? 'period' : '');
    return `<span class="${cls}">${d}</span>`;
  }).join('');
  return {
    title: new Date(year, month - 1, 1).toLocaleDateString(lifeState.lang === 'id' ? 'id-ID' : 'en-US', { month: 'long', year: 'numeric' }),
    gridHtml: `<div class="cal-m6">${dows}${blanks}${cells}</div>`,
  };
}

function renderRangeBarHtml(rep) {
  return `
    <div class="row" style="gap:8px">
      <div class="seg" id="repRangeSeg">
        <button type="button" data-rng="week" aria-pressed="${lifeState.reportRange === 'week'}">${tr(lifeState.lang, 'range_week')}</button>
        <button type="button" data-rng="month" aria-pressed="${lifeState.reportRange === 'month'}">${tr(lifeState.lang, 'range_month')}</button>
        <button type="button" data-rng="year" aria-pressed="${lifeState.reportRange === 'year'}">${tr(lifeState.lang, 'range_year')}</button>
        <button type="button" data-rng="custom" aria-pressed="${lifeState.reportRange === 'custom'}">${tr(lifeState.lang, 'range_custom')}</button>
      </div>
      ${lifeState.reportRange === 'custom'
        ? `<input type="date" id="repStartIn" value="${lifeState.customStart}"> <span class="small muted">→</span> <input type="date" id="repEndIn" value="${lifeState.customEnd}">`
        : `<span class="small muted num">${rep.start} → ${rep.end}</span>`}
    </div>
  `;
}

export async function loadModuleReportsView({ todayStr, showToast, onAfterMutation = null }) {
  const root = document.getElementById('reportsRoot');
  if (!lifeState.customEnd) {
    lifeState.customEnd = todayStr;
    lifeState.customStart = todayStr.slice(0, 8) + '01';
  }
  const mod = lifeState.reportModule;
  const q = lifeState.searchQuery.trim().toLowerCase();
  const [rep, todayData, envelopes, prefs] = await Promise.all([
    api.getModuleReport({ module: mod, range: lifeState.reportRange, customStart: lifeState.customStart, customEnd: lifeState.customEnd, today: todayStr }),
    mod === 'productivity' ? api.getToday(todayStr) : Promise.resolve(null),
    mod === 'finance' ? api.getEnvelopes() : Promise.resolve([]),
    api.getPrefs(),
  ]);

  const reload = async () => {
    if (onAfterMutation) await onAfterMutation();
    await loadModuleReportsView({ todayStr, showToast, onAfterMutation });
  };

  let bodyHtml = '';

  if (mod === 'productivity') {
    const groups = todayData?.groups || [];
    const allTasks = groups.flatMap(g => g.tasks.map(t => ({ ...t, groupName: g.name })));
    const visTasks = allTasks.filter(t => {
      if (q && !t.name.toLowerCase().includes(q)) return false;
      if (lifeState.prodTab === 'today') return t.scheduled;
      if (lifeState.prodTab === 'done') return t.done;
      return true;
    });
    const todayScheduled = allTasks.filter(t => t.scheduled);
    const todayDoneCount = todayScheduled.filter(t => t.done).length;
    const todayPct = todayScheduled.length > 0 ? Math.round((todayDoneCount / todayScheduled.length) * 100) : 0;
    const prioCount = todayScheduled.filter(t => t.priority === 'high' && !t.done).length;
    const weekdayName = new Date(`${todayStr}T12:00:00`).toLocaleDateString(lifeState.lang === 'id' ? 'id-ID' : 'en-US', { weekday: 'long' });
    const cal = buildMonthCalendarHtml(todayStr);
    const maxDay = Math.max(1, ...(rep.dailyChart || []).map(d => d.done));

    bodyHtml = `
      <div class="ws-grid">
        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Today', 'Hari ini')} · ${weekdayName}</h2><span class="pill-m6 num">${todayPct}%</span></div>
            <div class="stats-m6">
              <div class="stat-m6"><b class="num">${todayScheduled.length}</b><span>${L('Tasks', 'Tugas')}</span></div>
              <div class="stat-m6"><b class="num">${todayDoneCount}</b><span>${L('Completed', 'Selesai')}</span></div>
              <div class="stat-m6"><b class="num">${prioCount}</b><span>${L('Priority', 'Prioritas')}</span></div>
            </div>
            <div class="progress" style="margin-top:12px"><span style="width:${todayPct}%"></span></div>
          </div>

          <div class="card">
            <div class="head">
              <h2>${L('My tasks', 'Daftar tugas')}</h2>
              <div class="row" style="gap:4px" id="prodFilterSeg">
                <button class="mini-btn" type="button" data-pf="today" aria-pressed="${lifeState.prodTab === 'today'}">${L('Today', 'Hari ini')}</button>
                <button class="mini-btn" type="button" data-pf="all" aria-pressed="${lifeState.prodTab === 'all'}">${L('All', 'Semua')}</button>
                <button class="mini-btn" type="button" data-pf="done" aria-pressed="${lifeState.prodTab === 'done'}">${L('Completed', 'Selesai')}</button>
              </div>
            </div>
            <div>
              ${visTasks.map(t => `
                <div class="task-m6 ${t.done ? 'done' : ''}">
                  <input type="checkbox" class="ws-t-cb" data-tid="${t.id}" ${t.done ? 'checked' : ''}>
                  <span class="t-txt" style="flex:1;min-width:0">${esc(t.name)}</span>
                  ${t.priority === 'high' ? `<span class="pill-m6">${L('Priority', 'Prioritas')}</span>` : `<span class="small muted">${esc(t.groupName)}</span>`}
                  <button class="mini-btn ws-t-del" type="button" data-tid="${t.id}" style="color:var(--miss)">✕</button>
                </div>
              `).join('') || `<p class="small muted">${L('No tasks in this filter.', 'Tidak ada tugas yang cocok.')}</p>`}
            </div>
            <div class="ws-form-row" style="margin-top:12px">
              <div class="field" style="grid-column:span 2"><input id="pTaskName" placeholder="${L('Write a task...', 'Tulis tugas baru...')}"></div>
              <div class="field"><select id="pTaskPri"><option value="normal">${L('Normal', 'Normal')}</option><option value="high">${L('Priority', 'Prioritas')}</option><option value="low">${L('Low', 'Rendah')}</option></select></div>
              <div class="field"><input id="pTaskDue" type="date" aria-label="${L('Due date', 'Tenggat')}"></div>
              <button class="btn primary" type="button" id="pTaskAddBtn">${tr(lifeState.lang, 'add_btn')}</button>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Projects', 'Proyek')}</h2></div>
            <div>
              ${rep.projects.map(p => `
                <div class="listrow">
                  <div style="flex:1;min-width:0">
                    <b>${esc(p.name)}</b>
                    <div class="progress" style="margin-top:6px"><span style="width:${p.progress}%"></span></div>
                  </div>
                  <span class="pill-m6">${p.is_someday ? L('Someday', 'Nanti') : (p.progress >= 100 ? L('Done', 'Selesai') : L('In progress', 'Berjalan'))}</span>
                  <button class="mini-btn ws-proj-step" type="button" data-pid="${p.id}" data-prog="${Math.min(100, p.progress + 25)}">+25%</button>
                  <button class="mini-btn ws-del" type="button" data-tbl="projects" data-id="${p.id}" style="color:var(--miss)">✕</button>
                </div>
              `).join('') || `<p class="small muted">${L('No projects yet.', 'Belum ada proyek.')}</p>`}
            </div>
            <div class="ws-form-row" style="margin-top:10px">
              <div class="field"><input id="pProjName" placeholder="${L('Project name...', 'Nama proyek...')}"></div>
              <div class="field"><select id="pProjSomeday"><option value="0">${L('In progress', 'Berjalan')}</option><option value="1">${L('Someday', 'Nanti')}</option></select></div>
              <button class="btn" type="button" id="pProjAddBtn">+ ${tr(lifeState.lang, 'add_btn')}</button>
            </div>
          </div>
        </div>

        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Calendar', 'Kalender')} · ${cal.title}</h2></div>
            ${cal.gridHtml}
          </div>

          <div class="card">
            <div class="head"><h2>${L('Daily routine', 'Rutinitas harian')}</h2></div>
            ${groups.map(g => {
              const sch = g.tasks.filter(t => t.scheduled);
              const dn = sch.filter(t => t.done).length;
              return `
                <div class="listrow">
                  <span><b>${esc(g.name)}</b></span>
                  <span class="pill-m6 num">${dn}/${sch.length}</span>
                </div>
              `;
            }).join('') || `<p class="small muted">${L('No routines yet.', 'Belum ada rutinitas.')}</p>`}
          </div>

          <div class="card">
            <div class="head"><h2>${L('Focus timer', 'Pengatur fokus')}</h2><span class="pill-m6 num">${rep.focusMinutes}m ${L('logged', 'tercatat')}</span></div>
            <div class="pomo-clock" id="pomoClock">${fmtClock(lifeState.pomoSeconds)}</div>
            <p class="small muted" style="text-align:center;margin:0 0 10px">${L('One thing at a time.', 'Satu hal pada satu waktu.')}</p>
            <button class="btn primary" type="button" id="pomoToggleBtn" style="width:100%">${lifeState.pomoRunning ? L('Pause', 'Jeda') : L('Start focus', 'Mulai fokus')}</button>
            <div class="row" style="margin-top:8px;justify-content:center">
              <button class="btn" type="button" id="pomoResetBtn" style="flex:1">${L('Reset', 'Atur ulang')}</button>
              <button class="btn" type="button" id="pomoLogBtn" style="flex:1">${L('Log 25m', 'Catat 25m')}</button>
            </div>
            ${rep.focusSessions.length ? `
              <div class="m6-divider"></div>
              ${rep.focusSessions.slice(0, 4).map(f => `<div class="listrow"><span>${esc(f.note || L('Focus', 'Fokus'))}</span><span class="small muted num">${f.day} · ${f.minutes}m</span></div>`).join('')}
            ` : ''}
          </div>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Insights & review', 'Wawasan & ulasan')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${rep.completionRate}%</b><span>${L('Task completion', 'Tingkat selesai')}</span></div>
          <div class="stat-m6"><b class="num">${rep.doneCount}/${rep.scheduledCount}</b><span>${L('Completed / scheduled', 'Selesai / terjadwal')}</span></div>
          <div class="stat-m6"><b class="num">${rep.projects.length}</b><span>${L('Active projects', 'Proyek aktif')}</span></div>
        </div>
        <div class="report-chart-block" style="margin-top:14px">
          <div class="chart" style="height:120px">
            ${(rep.dailyChart || []).slice(-10).map(d => `<div class="bc"><i style="height:${Math.max(4, Math.round((d.done / maxDay) * 100))}%"></i><span>${d.label}</span></div>`).join('')}
          </div>
        </div>
      </div>
    `;
  } else if (mod === 'finance') {
    const entries = rep.entries.filter(e => {
      if (lifeState.finFilter !== 'all' && e.type !== lifeState.finFilter) return false;
      if (q && !(e.note || e.category || '').toLowerCase().includes(q)) return false;
      return true;
    });
    const maxFin = Math.max(1, rep.income, rep.expense, rep.savings, rep.debt);
    const editingEnv = lifeState.envEditId ? envelopes.find(e => e.id === lifeState.envEditId) : null;
    bodyHtml = `
      <div class="stats-m6">
        <div class="stat-m6"><span>${L('Available balance', 'Saldo bersih')}</span><b class="num">${fmtRp(rep.net)}</b></div>
        <div class="stat-m6"><span>${L('Income this period', 'Pemasukan periode ini')}</span><b class="num">${fmtRp(rep.income)}</b></div>
        <div class="stat-m6"><span>${L('Expenses this period', 'Pengeluaran periode ini')}</span><b class="num">${fmtRp(rep.expense)}</b></div>
      </div>

      <div class="ws-grid">
        <div class="col">
          <div class="card" id="transactionForm">
            <div class="head"><h2>${lifeState.finEditId ? L('Edit transaction', 'Ubah transaksi') : L('New transaction', 'Transaksi baru')}</h2></div>
            <div class="ws-form-row">
              <div class="field"><label>${L('Type', 'Tipe')}</label><select id="fType"><option value="expense">${L('Expense', 'Pengeluaran')}</option><option value="income">${L('Income', 'Pemasukan')}</option></select></div>
              <div class="field"><label>${L('Amount (Rp)', 'Jumlah (Rp)')}</label><input id="fAmt" type="number" placeholder="50000"></div>
            </div>
            <div class="ws-form-row" style="margin-top:8px">
              <div class="field"><label>${L('Description', 'Keterangan')}</label><input id="fNote" placeholder="${L('Groceries, salary...', 'Belanja, gaji...')}"></div>
              <div class="field"><label>${L('Category', 'Kategori')}</label><select id="fCat"><option value="general">${L('General', 'Umum')}</option><option value="savings">${L('Savings', 'Tabungan')}</option><option value="debt">${L('Debt / Loan', 'Cicilan / Utang')}</option></select></div>
              <div class="field"><label>${L('Envelope', 'Amplop')}</label><select id="fEnv"><option value="">${L('None', 'Tanpa amplop')}</option>${envelopes.map(e => `<option value="${e.id}">${esc(e.name)}</option>`).join('')}</select></div>
            </div>
            <div class="row" style="margin-top:10px;gap:8px">
              <button class="btn primary" type="button" id="fSaveBtn">${lifeState.finEditId ? L('Update transaction', 'Perbarui transaksi') : L('Save transaction', 'Simpan transaksi')}</button>
              ${lifeState.finEditId ? `<button class="btn" type="button" id="fCancelEditBtn">${L('Cancel', 'Batal')}</button>` : ''}
            </div>
          </div>

          <div class="card">
            <div class="head">
              <h2>${L('Recent transactions', 'Transaksi terbaru')}</h2>
              <div class="row" style="gap:4px" id="finTypeSeg">
                <button class="mini-btn" type="button" data-ft="all" aria-pressed="${lifeState.finFilter === 'all'}">${L('All', 'Semua')}</button>
                <button class="mini-btn" type="button" data-ft="income" aria-pressed="${lifeState.finFilter === 'income'}">${L('In', 'Masuk')}</button>
                <button class="mini-btn" type="button" data-ft="expense" aria-pressed="${lifeState.finFilter === 'expense'}">${L('Out', 'Keluar')}</button>
              </div>
            </div>
            ${entries.slice(0, 20).map(e => `
              <div class="listrow">
                <div><b>${esc(e.note || e.category)}</b> <small class="muted">· ${e.category} · ${e.day}</small></div>
                <span class="row" style="gap:6px">
                  <b class="num" style="color:${e.type === 'income' ? 'var(--accent-deep)' : 'var(--miss)'}">${e.type === 'income' ? '+' : '-'}${fmtRp(e.amount)}</b>
                  <button class="mini-btn fin-edit-btn" type="button" data-id="${e.id}" title="${L('Edit', 'Ubah')}">✎</button>
                  <button class="mini-btn ws-del" type="button" data-tbl="finance_entries" data-id="${e.id}" style="color:var(--miss)" title="${L('Delete', 'Hapus')}">✕</button>
                </span>
              </div>
            `).join('') || `<p class="small muted">${L('No transactions recorded yet.', 'Belum ada transaksi tercatat.')}</p>`}
          </div>
        </div>

        <div class="col">
          <div class="card">
            <div class="head">
              <h2>${L('Envelope budget', 'Anggaran amplop')}</h2>
              ${editingEnv ? `<span class="pill-m6">${L('Editing', 'Mengubah')}: ${esc(editingEnv.name)}</span>` : ''}
            </div>
            ${rep.envelopeUsage.map(e => `
              <div class="listrow" style="flex-direction:column;align-items:stretch;gap:4px">
                <div class="row" style="justify-content:space-between">
                  <span><b>${esc(e.name)}</b></span>
                  <span class="row" style="gap:6px">
                    <span class="pill-m6 num">${fmtRp(e.used)} / ${fmtRp(e.monthly_budget)}</span>
                    <button class="mini-btn env-edit-btn" type="button" data-id="${e.id}" aria-label="${L('Edit envelope', 'Ubah amplop')}" title="${L('Edit envelope', 'Ubah amplop')}">✎</button>
                    <button class="mini-btn ws-del" type="button" data-tbl="finance_envelopes" data-id="${e.id}" aria-label="${L('Delete envelope', 'Hapus amplop')}" title="${L('Delete envelope', 'Hapus amplop')}" style="color:var(--miss)">✕</button>
                  </span>
                </div>
                <div class="progress"><span style="width:${e.pct}%"></span></div>
              </div>
            `).join('') || `<p class="small muted">${L('Set monthly limits by envelope.', 'Atur batas pengeluaran bulanan per amplop.')}</p>`}
            <div class="ws-form-row" style="margin-top:10px">
              <div class="field"><input id="envName" value="${esc(editingEnv?.name || '')}" placeholder="${L('Food / Transport', 'Makan / Transportasi')}"></div>
              <div class="field"><input id="envBud" type="number" value="${editingEnv ? editingEnv.monthly_budget : ''}" placeholder="${L('Monthly budget', 'Anggaran bulanan')}"></div>
              <button class="btn primary" type="button" id="envAddBtn">${editingEnv ? L('Save', 'Simpan') : `+ ${L('Add', 'Tambah')}`}</button>
              ${editingEnv ? `<button class="btn" type="button" id="envCancelEditBtn">${L('Cancel', 'Batal')}</button>` : ''}
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Savings goals', 'Target tabungan')}</h2></div>
            ${(rep.savingsGoals || []).map(g => {
              const pct = g.target_amount > 0 ? Math.min(100, Math.round((g.current_amount / g.target_amount) * 100)) : 0;
              return `
                <div class="pinkpanel" style="margin-bottom:8px">
                  <div class="row" style="justify-content:space-between">
                    <b>${esc(g.name)}</b>
                    <span class="row" style="gap:4px">
                      <button class="mini-btn goal-add-btn" type="button" data-id="${g.id}">+100k</button>
                      <button class="mini-btn ws-del" type="button" data-tbl="savings_goals" data-id="${g.id}" style="color:var(--miss)">✕</button>
                    </span>
                  </div>
                  <div class="progress" style="margin:8px 0"><span style="width:${pct}%"></span></div>
                  <span class="small muted num">${fmtRp(g.current_amount)} / ${fmtRp(g.target_amount)} (${pct}%)</span>
                </div>
              `;
            }).join('') || `<div class="pinkpanel"><b>${L('My savings goal', 'Target tabunganku')}</b><p class="small muted" style="margin:4px 0 0">${L('Add a goal below to start tracking progress.', 'Tambahkan target di bawah untuk memantau progres.')}</p></div>`}
            <div class="ws-form-row" style="margin-top:10px">
              <div class="field"><input id="finItemName" placeholder="${L('Goal / Bill name', 'Nama target / tagihan')}"></div>
              <div class="field"><select id="finItemKind"><option value="goal">${L('Savings Goal', 'Target Tabungan')}</option><option value="bill">${L('Recurring Bill', 'Tagihan Rutin')}</option><option value="debt">${L('Debt Payment', 'Cicilan Utang')}</option></select></div>
              <div class="field"><input id="finItemAmt" type="number" placeholder="${L('Amount', 'Jumlah')}"></div>
              <button class="btn" type="button" id="finItemAddBtn">+ ${tr(lifeState.lang, 'add_btn')}</button>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Bills & debt', 'Tagihan & cicilan')}</h2></div>
            ${(rep.recurringBills || []).map(b => `
              <div class="listrow">
                <span><b>${esc(b.name)}</b> <small class="muted">· ${b.kind} · ${L('day', 'tgl')} ${b.due_day}</small></span>
                <span class="row" style="gap:6px">
                  <span class="num small">${fmtRp(b.amount)}</span>
                  <button class="mini-btn bill-paid-btn" type="button" data-id="${b.id}" aria-pressed="${b.is_paid === 1}">${b.is_paid ? L('Paid ✓', 'Lunas ✓') : L('Unpaid', 'Belum lunas')}</button>
                  <button class="mini-btn ws-del" type="button" data-tbl="recurring_bills" data-id="${b.id}" style="color:var(--miss)">✕</button>
                </span>
              </div>
            `).join('') || `<p class="small muted">${L('No upcoming bills or installments.', 'Tidak ada tagihan atau cicilan.')}</p>`}
          </div>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Monthly report', 'Laporan bulanan')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${fmtRp(rep.income)}</b><span>${L('Total income', 'Total pemasukan')}</span></div>
          <div class="stat-m6"><b class="num">${fmtRp(rep.expense)}</b><span>${L('Total expenses', 'Total pengeluaran')}</span></div>
          <div class="stat-m6"><b class="num">${fmtRp(rep.net)}</b><span>${L('Net balance', 'Saldo bersih')}</span></div>
        </div>
        <div class="report-chart-block" style="margin-top:14px">
          <div class="chart" style="height:110px">
            ${[{ l: L('Income', 'Masuk'), v: rep.income }, { l: L('Expense', 'Keluar'), v: rep.expense }, { l: L('Savings', 'Tabungan'), v: rep.savings }, { l: L('Debt', 'Utang'), v: rep.debt }]
              .map(b => `<div class="bc"><i style="height:${Math.max(4, Math.round((b.v / maxFin) * 100))}%"></i><span>${b.l}</span></div>`).join('')}
          </div>
        </div>
      </div>
    `;
  } else if (mod === 'health') {
    const todayWaterMl = rep.waterLogs.filter(w => w.day === todayStr).reduce((a, b) => a + b.value_num, 0);
    const goalGlasses = prefs.waterGoalGlasses || 8;
    const filledGlasses = Math.round(todayWaterMl / 250);
    const waterPct = Math.min(100, Math.round((filledGlasses / Math.max(1, goalGlasses)) * 100));
    const meals = ['breakfast', 'lunch', 'dinner', 'snacks'];
    const mealLabels = {
      breakfast: L('Breakfast', 'Sarapan'),
      lunch: L('Lunch', 'Makan siang'),
      dinner: L('Dinner', 'Makan malam'),
      snacks: L('Snacks', 'Camilan'),
    };
    const measNames = ['Waist', 'Hip', 'Chest', 'Arm', 'Thigh'];
    const measLabels = {
      Waist: L('Waist', 'Pinggang'),
      Hip: L('Hip', 'Pinggul'),
      Chest: L('Chest', 'Dada'),
      Arm: L('Arm', 'Lengan'),
      Thigh: L('Thigh', 'Paha'),
    };

    bodyHtml = `
      <div class="stats-m6">
        <div class="stat-m6"><span>${L('Current weight', 'Berat saat ini')}</span><b class="num">${rep.latestWeight !== null ? `${rep.latestWeight} kg` : '— kg'}</b></div>
        <div class="stat-m6"><span>${L('Water today', 'Air hari ini')}</span><b class="num">${filledGlasses} / ${goalGlasses}</b></div>
        <div class="stat-m6"><span>${L('Movement', 'Aktivitas fisik')}</span><b class="num">${rep.totalWorkoutMin} ${L('min', 'mnt')}</b></div>
      </div>

      <div class="ws-grid">
        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Weight progress', 'Progres berat badan')}</h2></div>
            <div class="pinkpanel">
              <div class="amount-m6 num">${rep.latestWeight !== null ? `${rep.latestWeight} kg` : '— kg'}</div>
              <span class="small muted">${L('Current', 'Saat ini')} · ${L('Goal', 'Target')} ${prefs.weightGoalKg || '—'} kg</span>
              <div class="progress" style="margin-top:8px"><span style="width:${rep.latestWeight && prefs.weightGoalKg ? Math.min(100, Math.round((Number(prefs.weightGoalKg) / Math.max(1, rep.latestWeight)) * 100)) : 35}%"></span></div>
            </div>
            <div class="ws-form-row" style="margin-top:10px">
              <div class="field"><label>${L('Weight (kg)', 'Berat (kg)')}</label><input id="hWeightIn" type="number" step="0.1" placeholder="60.5"></div>
              <div class="field"><label>${L('Goal (kg)', 'Target (kg)')}</label><input id="hWeightGoalIn" type="number" step="0.1" value="${esc(prefs.weightGoalKg)}"></div>
              <button class="btn primary" type="button" id="hWeightBtn">${tr(lifeState.lang, 'save_btn')}</button>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Food diary', 'Catatan makan')}</h2><span class="pill-m6 num">${rep.totalCalories} kcal</span></div>
            <div class="ws-form-row" style="margin-bottom:10px">
              <div class="field"><label>${L('Meal', 'Waktu makan')}</label><select id="hMealSlot">${meals.map(m => `<option value="${m}">${mealLabels[m]}</option>`).join('')}</select></div>
              <div class="field"><label>${L('Food', 'Makanan')}</label><input id="hFoodName" placeholder="Oatmeal"></div>
              <div class="field"><label>kcal</label><input id="hFoodKcal" type="number" placeholder="350"></div>
              <button class="btn primary" type="button" id="hFoodBtn">+ ${L('Add food', 'Tambah')}</button>
            </div>
            ${meals.map(slot => {
              const items = rep.foodLogs.filter(f => (f.meal_slot || 'snacks') === slot);
              const kcal = items.reduce((a, b) => a + b.value_num, 0);
              return `
                <div class="listrow" style="flex-direction:column;align-items:stretch;gap:4px">
                  <div class="row" style="justify-content:space-between">
                    <span style="font-weight:600">${mealLabels[slot]}</span>
                    <span class="pill-m6 num">${kcal} kcal</span>
                  </div>
                  ${items.map(f => `<div class="row small" style="justify-content:space-between;color:var(--muted)"><span>${esc(f.name || L('Meal', 'Makan'))} · ${f.day}</span><span class="row" style="gap:6px"><span class="num">${f.value_num} kcal</span><button class="mini-btn ws-del" type="button" data-tbl="health_entries" data-id="${f.id}" style="color:var(--miss)">✕</button></span></div>`).join('')}
                </div>
              `;
            }).join('')}
          </div>
        </div>

        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Water tracker', 'Pantau minum air')}</h2><span class="small muted num">${Math.round(todayWaterMl)} ml</span></div>
            <div class="amount-m6 num">${filledGlasses} <span class="small muted" style="font-weight:500">${L('glasses', 'gelas')}</span></div>
            <div class="progress" style="margin:10px 0"><span style="width:${waterPct}%"></span></div>
            <div class="water-cups" id="waterCupsRow">
              ${Array.from({ length: goalGlasses }, (_, i) => `<button type="button" class="cup-btn ${i < filledGlasses ? 'filled' : ''}" title="+250 ml">💧</button>`).join('')}
            </div>
            <div class="row">
              <button class="btn primary" type="button" id="hAddGlassBtn">+ ${L('Add a glass', 'Tambah segelas')}</button>
              <button class="btn" type="button" id="hAddBottleBtn">+ 500 ml</button>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Workout', 'Olahraga')}</h2></div>
            <p class="small muted" style="margin:0 0 8px">${L('Any movement counts.', 'Setiap gerakan bermakna.')}</p>
            <div class="ws-form-row" style="margin-bottom:8px">
              <div class="field"><input id="hWoName" placeholder="${L('Walk / Yoga', 'Jalan santai / Yoga')}"></div>
              <div class="field"><input id="hWoMin" type="number" value="30"></div>
              <button class="btn" type="button" id="hWoBtn">+ ${L('Log workout', 'Catat latihan')}</button>
            </div>
            ${rep.workoutLogs.map(w => `
              <div class="listrow">
                <span>${esc(w.name || L('Workout', 'Olahraga'))} <small class="muted">(${w.day})</small></span>
                <span class="row" style="gap:6px"><span class="pill-m6 num">${w.value_num} ${L('min', 'mnt')}</span><button class="mini-btn ws-del" type="button" data-tbl="health_entries" data-id="${w.id}" style="color:var(--miss)">✕</button></span>
              </div>
            `).join('') || ''}
          </div>

          <div class="card">
            <div class="head"><h2>${L('Body measurements', 'Ukuran tubuh')}</h2></div>
            <div class="row" style="flex-wrap:wrap;gap:6px;margin-bottom:10px">
              ${measNames.map(n => {
                const m = (rep.latestMeasurements || {})[n];
                return `<span class="pill-m6">${measLabels[n]}: ${m ? `${m.value_num} cm` : '—'}</span>`;
              }).join('')}
            </div>
            <div class="ws-form-row">
              <div class="field"><select id="hMeasName">${measNames.map(m => `<option value="${m}">${measLabels[m]}</option>`).join('')}</select></div>
              <div class="field"><input id="hMeasVal" type="number" step="0.5" placeholder="cm"></div>
              <button class="btn" type="button" id="hMeasBtn">${L('Update measurements', 'Perbarui ukuran')}</button>
            </div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Health insights', 'Wawasan kesehatan')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${rep.latestWeight !== null ? `${rep.latestWeight} kg` : '— kg'}</b><span>${L('Current weight', 'Berat saat ini')}</span></div>
          <div class="stat-m6"><b class="num">${rep.totalCalories} kcal</b><span>${L('Total calories', 'Total kalori')}</span></div>
          <div class="stat-m6"><b class="num">${rep.totalWorkoutMin} ${L('min', 'mnt')}</b><span>${L('Workout time', 'Durasi olahraga')}</span></div>
        </div>
      </div>
    `;
  } else if (mod === 'wellness') {
    const moodChoices = [
      { emoji: '😊', label: 'Happy', disp: L('Happy', 'Senang'), score: 5 },
      { emoji: '🙂', label: 'Calm', disp: L('Calm', 'Tenang'), score: 4 },
      { emoji: '😐', label: 'Neutral', disp: L('Neutral', 'Biasa'), score: 3 },
      { emoji: '😔', label: 'Tired', disp: L('Tired', 'Lelah'), score: 2 },
      { emoji: '😣', label: 'Stressed', disp: L('Stressed', 'Tertekan'), score: 1 },
    ];
    const activeMood = moodChoices.find(m => m.label === lifeState.wellnessMood);
    const latestSleep = rep.entries[0]?.sleep_hours;
    bodyHtml = `
      <div class="ws-grid">
        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('How are you today?', 'Bagaimana kabarmu hari ini?')}</h2><span class="pill-m6">${esc(activeMood ? activeMood.disp : lifeState.wellnessMood)}</span></div>
            <div class="mood-m6" id="wMoodPicker">
              ${moodChoices.map(m => `<button type="button" data-wmood="${m.label}" data-wscore="${m.score}" aria-pressed="${lifeState.wellnessMood === m.label}" title="${m.disp}">${m.emoji}</button>`).join('')}
            </div>
            <div class="m6-divider"></div>
            <div class="ws-form-row">
              <div class="field"><label>${L('Energy level', 'Tingkat energi')}</label><select id="wEn"><option value="3">${L('Medium', 'Sedang')} (3/5)</option><option value="5">${L('High', 'Tinggi')} (5/5)</option><option value="4" selected>${L('Good', 'Baik')} (4/5)</option><option value="2">${L('Low', 'Rendah')} (2/5)</option><option value="1">${L('Very low', 'Sangat rendah')} (1/5)</option></select></div>
              <div class="field"><label>${L('Stress level', 'Tingkat stres')}</label><select id="wSt"><option value="2" selected>${L('Low', 'Rendah')} (2/5)</option><option value="1">${L('Calm', 'Tenang')} (1/5)</option><option value="3">${L('Medium', 'Sedang')} (3/5)</option><option value="4">${L('High', 'Tinggi')} (4/5)</option><option value="5">${L('Overwhelmed', 'Kewalahan')} (5/5)</option></select></div>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Daily journal', 'Jurnal harian')}</h2></div>
            <div class="field"><textarea id="wNote" rows="4" placeholder="${L('What is on your mind today?', 'Apa yang ada di pikiranmu hari ini?')}"></textarea></div>
            <button class="btn primary" type="button" id="wSaveBtn" style="margin-top:10px">${L('Save journal & check-in', 'Simpan jurnal & catatan')}</button>
            ${rep.entries.length ? `
              <div class="m6-divider"></div>
              ${rep.entries.slice(0, 8).map(e => `
                <div class="listrow">
                  <div>
                    <b>${esc(e.mood)}</b> <small class="muted">(${e.day}) · E:${e.energy} S:${e.stress} · ${e.sleep_hours}h</small>
                    ${e.gratitude_text ? `<div class="small" style="color:var(--accent-deep)">♡ ${esc(e.gratitude_text)}</div>` : ''}
                    ${e.note ? `<div class="small muted">${esc(e.note)}</div>` : ''}
                  </div>
                  <button class="mini-btn ws-del" type="button" data-tbl="wellness_entries" data-id="${e.id}" style="color:var(--miss)">✕</button>
                </div>
              `).join('')}
            ` : ''}
          </div>
        </div>

        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Sleep', 'Tidur')}</h2></div>
            <div class="amount-m6 num">${latestSleep ? `${latestSleep} ${L('hrs', 'jam')}` : `— ${L('hrs', 'jam')}`}</div>
            <p class="small muted" style="margin:4px 0 10px">${L("Record last night's sleep", 'Catat durasi tidur semalam')}</p>
            <div class="ws-form-row">
              <div class="field"><input id="wSl" type="number" step="0.5" value="7.5" placeholder="${L('Hours', 'Jam')}"></div>
              <button class="btn" type="button" id="wSleepSaveBtn">${L('Log sleep', 'Catat tidur')}</button>
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Emotional triggers', 'Pemicu emosi')}</h2></div>
            <div class="field"><textarea id="wTrig" rows="2" placeholder="${L('Anything that affected your mood? (comma separated)', 'Apa yang memengaruhi perasaanmu? (pisahkan dengan koma)')}"></textarea></div>
            ${rep.triggers.length ? `<div class="row" style="margin-top:8px">${rep.triggers.map(t => `<span class="pill-m6">${esc(t.name)} (${t.count})</span>`).join('')}</div>` : ''}
            <button class="btn" type="button" id="wTrigSaveBtn" style="margin-top:8px">${L('Save reflection', 'Simpan refleksi')}</button>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Small gratitude', 'Hal yang disyukuri')}</h2></div>
            <div class="field"><textarea id="wGrat" rows="3" placeholder="${L("One thing I'm grateful for...", 'Satu hal kecil yang kusyukuri hari ini...')}"></textarea></div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Weekly mental wellness review', 'Ulasan kesehatan mental')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${rep.avgMood || '—'}</b><span>${L('Common mood (/5)', 'Rata-rata suasana hati (/5)')}</span></div>
          <div class="stat-m6"><b class="num">${rep.avgEnergy || '—'}</b><span>${L('Average energy', 'Rata-rata energi')}</span></div>
          <div class="stat-m6"><b class="num">${rep.avgSleep ? `${rep.avgSleep} ${L('hrs', 'jam')}` : '—'}</b><span>${L('Average sleep', 'Rata-rata tidur')}</span></div>
        </div>
      </div>
    `;
  } else if (mod === 'menstrual') {
    const est = rep.nextPeriodEstimate;
    const periodReminder = prefs.periodReminders;
    const periodDaySet = new Set(rep.entries.filter(e => e.phase === 'Menstrual' || e.is_period_start).map(e => e.day));
    const cal = buildMonthCalendarHtml(todayStr, periodDaySet);
    const symptomChips = [
      { k: 'cramps', lb: L('cramps', 'kram') },
      { k: 'bloating', lb: L('bloating', 'kembung') },
      { k: 'headache', lb: L('headache', 'sakit kepala') },
      { k: 'fatigue', lb: L('fatigue', 'lelah') },
      { k: 'acne', lb: L('acne', 'jerawat') },
    ];

    bodyHtml = `
      <div class="ws-grid">
        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('Cycle calendar', 'Kalender siklus')} · ${cal.title}</h2></div>
            ${cal.gridHtml}
            <p class="small muted" style="margin:10px 0 0">${tr(lifeState.lang, 'est_disclaimer')}</p>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Cycle history', 'Riwayat siklus')}</h2></div>
            <div class="listrow"><span>${L('Previous cycle', 'Fase terakhir')}</span><span class="pill-m6">${rep.latestPhase ? esc(rep.latestPhase) : L('No record yet', 'Belum ada catatan')}</span></div>
            <div class="listrow"><span>${L('Average cycle length', 'Rata-rata panjang siklus')}</span><b class="num">${rep.avgCycleDuration ? `${rep.avgCycleDuration} ${L('days', 'hari')}` : `— ${L('days', 'hari')}`}</b></div>
            <div class="listrow"><span>${L('Recorded entries', 'Jumlah catatan')}</span><b class="num">${rep.entries.length}</b></div>
            ${rep.entries.slice(0, 6).map(e => `
              <div class="listrow">
                <div><b>${esc(e.phase)}</b> · ${L('Day', 'Hari ke-')} ${e.cycle_day} (${e.day}) ${e.is_period_start ? `<span class="pill-m6">${L('Start', 'Mulai')}</span>` : ''}<div class="small muted">${esc(e.symptoms.join(', ') || e.flow || '')}</div></div>
                <button class="mini-btn ws-del" type="button" data-tbl="menstrual_entries" data-id="${e.id}" style="color:var(--miss)">✕</button>
              </div>
            `).join('')}
            <div class="m6-divider"></div>
            <div class="ws-form-row">
              <div class="field"><label>${L('Date', 'Tanggal')}</label><input id="mDay" type="date" value="${todayStr}"></div>
              <div class="field"><label>${L('Phase', 'Fase')}</label><select id="mPhase"><option value="Menstrual">${L('Menstrual', 'Menstruasi')}</option><option value="Follicular">${L('Follicular', 'Folikular')}</option><option value="Ovulation">${L('Ovulation', 'Ovulasi')}</option><option value="Luteal">${L('Luteal', 'Luteal')}</option></select></div>
              <div class="field"><label>${L('Cycle Day', 'Hari Siklus')}</label><input id="mCycDay" type="number" min="1" max="60" value="1"></div>
              <div class="field"><label>${L('Flow', 'Volume')}</label><select id="mFlow"><option value="Light">${L('Light', 'Ringan')}</option><option value="None">${L('None', 'Tidak ada')}</option><option value="Medium">${L('Medium', 'Sedang')}</option><option value="Heavy">${L('Heavy', 'Deras')}</option></select></div>
              <div class="field"><label>${L('Period Start?', 'Hari pertama?')}</label><select id="mStart"><option value="0">${L('No', 'Tidak')}</option><option value="1">${L('Yes (Day 1)', 'Ya (Hari 1)')}</option></select></div>
              <div class="field"><label>${L('Cycle Len', 'Durasi Siklus')}</label><input id="mLen" type="number" min="18" max="60" value="28"></div>
            </div>
          </div>
        </div>

        <div class="col">
          <div class="pinkpanel">
            <span class="eyebrow">${L('NEXT PERIOD ESTIMATE', 'PERKIRAAN HAID BERIKUTNYA')}</span>
            <div class="amount-m6 num" style="margin:4px 0">${est ? est.estimatedStartDay : '—'}</div>
            <p class="small muted" style="margin:0 0 8px">${est ? `${L('Est. ovulation', 'Prakiraan ovulasi')}: ${est.estimatedOvulationDay}` : L('Add cycle records to calculate an estimate.', 'Tambahkan catatan siklus untuk menghitung prakiraan.')}</p>
            <label class="row small" style="gap:6px;cursor:pointer">
              <input type="checkbox" id="mReminderCb" ${periodReminder ? 'checked' : ''}> ${L('Optional estimate reminder', 'Pengingat prakiraan opsional')}
            </label>
          </div>

          <div class="card">
            <div class="head"><h2>${L("Today's symptoms", 'Gejala hari ini')}</h2></div>
            <div class="mood-m6" id="mSymChips">
              ${symptomChips.map(s => `<button type="button" class="chip-sym" data-msym="${s.k}" aria-pressed="${lifeState.selectedSymptoms.includes(s.k)}">${s.lb}</button>`).join('')}
            </div>
            <div class="field" style="margin-top:10px"><textarea id="mSym" rows="2" placeholder="${L('Other symptoms or notes...', 'Gejala lain atau catatan...')}"></textarea></div>
            <button class="btn primary" type="button" id="mSaveBtn" style="margin-top:8px">${L('Save symptoms & log', 'Simpan catatan siklus')}</button>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Mood during cycle', 'Suasana hati selama siklus')}</h2></div>
            <p class="small muted" style="margin:0 0 8px">${L('Logged symptom patterns from your records:', 'Pola gejala dari catatanmu:')}</p>
            <div class="row" style="flex-wrap:wrap;gap:6px;margin-bottom:10px">
              ${rep.symptomSummary.map(s => `<span class="pill-m6">${esc(s.name)} (${s.count})</span>`).join('') || `<span class="small muted">${L('No symptoms recorded yet.', 'Belum ada gejala tercatat.')}</span>`}
            </div>
            <button class="btn" type="button" id="mGoMoodBtn">${L('Open Wellness mood history', 'Buka riwayat suasana hati')}</button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Cycle insights', 'Wawasan siklus')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${rep.avgCycleDuration ? `${rep.avgCycleDuration} ${L('days', 'hari')}` : `— ${L('days', 'hari')}`}</b><span>${L('Average cycle', 'Rata-rata siklus')}</span></div>
          <div class="stat-m6"><b class="num">${rep.entries.length}</b><span>${L('Recorded entries', 'Total catatan')}</span></div>
          <div class="stat-m6"><b>${rep.latestPhase ? esc(rep.latestPhase) : '—'}</b><span>${L('Latest phase', 'Fase terbaru')}</span></div>
        </div>
      </div>
    `;
  } else {
    const noteCatLabels = {
      journal: L('Daily journal', 'Jurnal harian'),
      braindump: L('Brain dump', 'Curahan pikiran'),
      gratitude: L('Gratitude', 'Syukur'),
      quick: L('Quick note', 'Catatan cepat'),
    };
    const filteredNotes = rep.entries.filter(n => {
      if (lifeState.noteCat === 'pinned') {
        if (!n.is_pinned) return false;
      } else if (lifeState.noteCat !== 'all' && (n.category || 'journal') !== lifeState.noteCat) {
        return false;
      }
      if (q && !(n.title + ' ' + n.body).toLowerCase().includes(q)) return false;
      return true;
    });
    const pinnedNotes = rep.entries.filter(n => n.is_pinned);
    const activeNote = filteredNotes.find(n => n.id === lifeState.selectedNoteId) || rep.entries.find(n => n.id === lifeState.selectedNoteId) || null;
    bodyHtml = `
      <div class="ws-grid">
        <div class="col">
          <div class="card">
            <div class="head"><h2>${L('All notes', 'Semua catatan')} (${filteredNotes.length})</h2><button class="mini-btn" type="button" id="noteNewBtn">+ ${L('New note', 'Catatan baru')}</button></div>
            <div class="field"><input id="nSearchBox" value="${esc(lifeState.searchQuery)}" placeholder="⌕ ${L('Search your notes...', 'Cari catatanmu...')}"></div>
            <div class="m6-divider"></div>
            <div>
              ${filteredNotes.map(n => `
                <button type="button" class="listrow" style="width:100%;border:0;border-bottom:1px solid var(--line);background:${activeNote && activeNote.id === n.id ? 'var(--soft)' : 'transparent'};text-align:left;cursor:pointer;padding:10px 6px" data-nid="${n.id}">
                  <span style="min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${n.is_pinned ? '📌 ' : ''}${esc(n.title)}</span>
                  <span class="pill-m6">${esc(noteCatLabels[n.category || 'journal'] || n.category || 'journal')}</span>
                </button>
              `).join('') || `<p class="small muted">${L('No notes matching filter.', 'Tidak ada catatan yang cocok.')}</p>`}
            </div>
          </div>

          <div class="card">
            <div class="head"><h2>${L('Pinned notes', 'Catatan disematkan')}</h2></div>
            <div class="col" style="gap:8px">
              ${pinnedNotes.slice(0, 4).map(n => `
                <div class="note-box-m6">
                  <h4>${esc(n.title)} ♡</h4>
                  <p>${esc(n.body || '')}</p>
                </div>
              `).join('') || `<div class="note-box-m6"><h4>${L('Remember ♡', 'Ingatlah ♡')}</h4><p>${L('Small steps are still steps.', 'Langkah kecil tetaplah sebuah langkah.')}</p></div>`}
            </div>
          </div>
        </div>

        <div class="card">
          <div class="head">
            <h2>${activeNote ? L('Edit note', 'Ubah catatan') : L('Quick editor', 'Editor cepat')}</h2>
            ${activeNote ? `<button class="mini-btn ws-del" type="button" data-tbl="notes" data-id="${activeNote.id}" style="color:var(--miss)">${tr(lifeState.lang, 'delete_btn')}</button>` : ''}
          </div>
          <div class="field"><input id="nTitle" value="${esc(activeNote?.title || '')}" placeholder="${L('Note title', 'Judul catatan')}"></div>
          <div class="field" style="margin-top:9px">
            <textarea id="nBody" rows="9" placeholder="${L('Start writing...', 'Mulai menulis...')}">${esc(activeNote?.body || '')}</textarea>
          </div>
          <div class="ws-form-row" style="margin-top:10px">
            <div class="field"><select id="nCat">
              ${['journal', 'braindump', 'gratitude', 'quick'].map(c => `<option value="${c}" ${(activeNote?.category || 'journal') === c ? 'selected' : ''}>${noteCatLabels[c]}</option>`).join('')}
            </select></div>
            <div class="field"><input id="nTags" value="${esc((activeNote?.tags || []).join(', '))}" placeholder="${L('Tags (comma)', 'Tag (pisahkan koma)')}"></div>
            <button class="btn primary" type="button" id="nSaveBtn">${tr(lifeState.lang, 'save_btn')}</button>
          </div>
          <label class="row small muted" style="gap:6px;cursor:pointer;margin-top:10px"><input type="checkbox" id="nPin" ${activeNote?.is_pinned ? 'checked' : ''}> ${L('Pin note', 'Sematkan catatan')}</label>
        </div>
      </div>

      <div class="card">
        <div class="head" style="flex-wrap:wrap"><h2>${L('Browse & organize', 'Jelajahi & atur')}</h2>${renderRangeBarHtml(rep)}</div>
        <div class="row" style="flex-wrap:wrap;gap:8px;margin-bottom:12px">
          ${[
            { k: 'all', l: L('All notes', 'Semua catatan') },
            { k: 'journal', l: L('Daily journal', 'Jurnal harian') },
            { k: 'braindump', l: L('Brain dump', 'Curahan pikiran') },
            { k: 'gratitude', l: L('Gratitude', 'Syukur') },
            { k: 'quick', l: L('Quick note', 'Catatan cepat') },
            { k: 'pinned', l: L('Pinned', 'Disematkan') },
          ].map(c => `<button class="${lifeState.noteCat === c.k ? 'btn primary' : 'btn'}" type="button" data-ncat="${c.k}">${c.l}</button>`).join('')}
        </div>
        <div class="stats-m6">
          <div class="stat-m6"><b class="num">${rep.count}</b><span>${L('Entries in range', 'Catatan pada periode')}</span></div>
          <div class="stat-m6"><b class="num">${rep.totalWords}</b><span>${L('Total words', 'Total kata')}</span></div>
          <div class="stat-m6"><b class="num">${rep.uniqueTags}</b><span>${L('Unique tags', 'Tag unik')}</span></div>
        </div>
      </div>
    `;
  }

  root.innerHTML = bodyHtml;

  // Wire range controls & soft delete
  root.querySelectorAll('#repRangeSeg [data-rng]').forEach(b => {
    b.onclick = () => { lifeState.reportRange = b.dataset.rng; loadModuleReportsView({ todayStr, showToast, onAfterMutation }); };
  });
  const si = document.getElementById('repStartIn');
  const ei = document.getElementById('repEndIn');
  if (si && ei) {
    si.onchange = () => { lifeState.customStart = si.value; reload(); };
    ei.onchange = () => { lifeState.customEnd = ei.value; reload(); };
  }
  root.querySelectorAll('.ws-del').forEach(b => {
    b.onclick = async () => {
      await api.deleteLifeOsItem(b.dataset.tbl, b.dataset.id);
      if (b.dataset.tbl === 'notes' && lifeState.selectedNoteId === b.dataset.id) lifeState.selectedNoteId = null;
      if (b.dataset.tbl === 'finance_envelopes' && lifeState.envEditId === b.dataset.id) lifeState.envEditId = null;
      if (b.dataset.tbl === 'finance_entries' && lifeState.finEditId === b.dataset.id) lifeState.finEditId = null;
      showToast(L('Removed.', 'Dihapus.'));
      await reload();
    };
  });

  // Wire workspace-specific actions
  if (mod === 'productivity') {
    root.querySelectorAll('#prodFilterSeg [data-pf]').forEach(b => { b.onclick = () => { lifeState.prodTab = b.dataset.pf; reload(); }; });
    document.getElementById('pTaskAddBtn').onclick = async () => {
      const name = document.getElementById('pTaskName').value.trim();
      if (!name) return;
      await api.quickAdd({
        kind: 'task',
        data: { name, priority: document.getElementById('pTaskPri').value, due_date: document.getElementById('pTaskDue').value || null },
      });
      showToast(L('Task added.', 'Tugas ditambahkan.'));
      await reload();
    };
    root.querySelectorAll('.ws-t-cb').forEach(cb => {
      cb.onchange = async () => { await api.toggleCheck({ taskId: cb.dataset.tid, day: todayStr, checked: cb.checked }); await reload(); };
    });
    root.querySelectorAll('.ws-t-del').forEach(b => {
      b.onclick = async () => { await api.deactivateTask(b.dataset.tid); showToast(L('Task archived.', 'Tugas dinonaktifkan.')); await reload(); };
    });
    document.getElementById('pProjAddBtn').onclick = async () => {
      const name = document.getElementById('pProjName').value.trim();
      if (!name) return;
      await api.saveProject({ name, is_someday: document.getElementById('pProjSomeday').value === '1', progress: 0 });
      showToast(L('Project saved.', 'Proyek disimpan.'));
      await reload();
    };
    root.querySelectorAll('.ws-proj-step').forEach(b => {
      b.onclick = async () => {
        const cur = rep.projects.find(p => p.id === b.dataset.pid);
        if (cur) await api.saveProject({ ...cur, progress: Number(b.dataset.prog) });
        await reload();
      };
    });
    document.getElementById('pomoToggleBtn').onclick = () => {
      if (lifeState.pomoRunning) {
        clearInterval(lifeState.pomoTimer);
        lifeState.pomoTimer = null;
        lifeState.pomoRunning = false;
      } else {
        lifeState.pomoRunning = true;
        lifeState.pomoTimer = setInterval(async () => {
          lifeState.pomoSeconds = Math.max(0, lifeState.pomoSeconds - 1);
          const el = document.getElementById('pomoClock');
          if (el) el.textContent = fmtClock(lifeState.pomoSeconds);
          if (lifeState.pomoSeconds === 0) {
            clearInterval(lifeState.pomoTimer);
            lifeState.pomoTimer = null;
            lifeState.pomoRunning = false;
            lifeState.pomoSeconds = 25 * 60;
            await api.saveFocus({ day: todayStr, minutes: 25, note: L('Pomodoro session', 'Sesi Pomodoro') });
            showToast(L('25m Pomodoro logged!', 'Fokus 25 menit tercatat!'));
            await reload();
          }
        }, 1000);
      }
      document.getElementById('pomoToggleBtn').textContent = lifeState.pomoRunning ? L('Pause', 'Jeda') : L('Start focus', 'Mulai fokus');
    };
    document.getElementById('pomoResetBtn').onclick = () => {
      clearInterval(lifeState.pomoTimer);
      lifeState.pomoTimer = null;
      lifeState.pomoRunning = false;
      lifeState.pomoSeconds = 25 * 60;
      const el = document.getElementById('pomoClock');
      if (el) el.textContent = fmtClock(lifeState.pomoSeconds);
      document.getElementById('pomoToggleBtn').textContent = L('Start focus', 'Mulai fokus');
    };
    document.getElementById('pomoLogBtn').onclick = async () => {
      const elapsedMin = Math.max(5, Math.round((25 * 60 - lifeState.pomoSeconds) / 60) || 25);
      await api.saveFocus({ day: todayStr, minutes: elapsedMin, note: L('Focus sprint', 'Sesi fokus') });
      showToast(L(`Logged ${elapsedMin}m focus.`, `${elapsedMin}m fokus tercatat.`));
      await reload();
    };
  } else if (mod === 'finance') {
    root.querySelectorAll('#finTypeSeg [data-ft]').forEach(b => { b.onclick = () => { lifeState.finFilter = b.dataset.ft; reload(); }; });
    const editing = lifeState.finEditId ? rep.entries.find(e => e.id === lifeState.finEditId) : null;
    if (editing) {
      document.getElementById('fType').value = editing.type;
      document.getElementById('fCat').value = editing.category;
      document.getElementById('fEnv').value = editing.envelope_id || '';
      document.getElementById('fAmt').value = editing.amount;
      document.getElementById('fNote').value = editing.note || '';
    }
    const fCancel = document.getElementById('fCancelEditBtn');
    if (fCancel) fCancel.onclick = () => { lifeState.finEditId = null; reload(); };
    root.querySelectorAll('.fin-edit-btn').forEach(b => {
      b.onclick = () => { lifeState.finEditId = b.dataset.id; reload(); };
    });
    document.getElementById('fSaveBtn').onclick = async () => {
      await api.saveFinanceEntry({
        id: lifeState.finEditId || undefined,
        day: todayStr,
        type: document.getElementById('fType').value,
        category: document.getElementById('fCat').value,
        envelope_id: document.getElementById('fEnv').value || null,
        amount: Number(document.getElementById('fAmt').value) || 0,
        note: document.getElementById('fNote').value.trim(),
      });
      lifeState.finEditId = null;
      showToast(L('Transaction saved.', 'Transaksi disimpan.'));
      await reload();
    };
    root.querySelectorAll('.env-edit-btn').forEach(b => {
      b.onclick = () => { lifeState.envEditId = b.dataset.id; reload(); };
    });
    const envCancel = document.getElementById('envCancelEditBtn');
    if (envCancel) envCancel.onclick = () => { lifeState.envEditId = null; reload(); };
    document.getElementById('envAddBtn').onclick = async () => {
      const name = document.getElementById('envName').value.trim();
      if (!name) return;
      const existing = lifeState.envEditId ? envelopes.find(e => e.id === lifeState.envEditId) : null;
      await api.saveEnvelope({
        id: lifeState.envEditId || undefined,
        name,
        monthly_budget: Number(document.getElementById('envBud').value) || 0,
        color: existing?.color,
      });
      const wasEdit = !!lifeState.envEditId;
      lifeState.envEditId = null;
      showToast(wasEdit ? L('Envelope updated.', 'Amplop diperbarui.') : L('Envelope saved.', 'Amplop disimpan.'));
      await reload();
    };
    document.getElementById('finItemAddBtn').onclick = async () => {
      const name = document.getElementById('finItemName').value.trim();
      if (!name) return;
      const kind = document.getElementById('finItemKind').value;
      const amt = Number(document.getElementById('finItemAmt').value) || 0;
      if (kind === 'goal') await api.saveSavingsGoal({ name, target_amount: amt, current_amount: 0 });
      else await api.saveRecurringBill({ name, kind, amount: amt, due_day: new Date().getDate() });
      showToast(L('Saved.', 'Tersimpan.'));
      await reload();
    };
    root.querySelectorAll('.goal-add-btn').forEach(b => {
      b.onclick = async () => {
        const cur = (rep.savingsGoals || []).find(g => g.id === b.dataset.id);
        if (cur) await api.saveSavingsGoal({ ...cur, current_amount: cur.current_amount + 100000 });
        await reload();
      };
    });
    root.querySelectorAll('.bill-paid-btn').forEach(b => {
      b.onclick = async () => {
        const cur = (rep.recurringBills || []).find(x => x.id === b.dataset.id);
        if (cur) await api.saveRecurringBill({ ...cur, is_paid: cur.is_paid ? 0 : 1 });
        await reload();
      };
    });
  } else if (mod === 'health') {
    const addWater = async (ml) => {
      await api.saveHealthEntry({ day: todayStr, kind: 'water', name: 'Water', value_num: ml, unit: 'ml' });
      showToast(L(`+${ml} ml logged.`, `+${ml} ml tercatat.`));
      await reload();
    };
    document.getElementById('hAddGlassBtn').onclick = () => addWater(250);
    document.getElementById('hAddBottleBtn').onclick = () => addWater(500);
    root.querySelectorAll('#waterCupsRow .cup-btn').forEach(b => { b.onclick = () => addWater(250); });
    document.getElementById('hFoodBtn').onclick = async () => {
      await api.saveHealthEntry({
        day: todayStr, kind: 'food', meal_slot: document.getElementById('hMealSlot').value,
        name: document.getElementById('hFoodName').value.trim() || L('Meal', 'Makan'),
        value_num: Number(document.getElementById('hFoodKcal').value) || 0, unit: 'kcal',
      });
      showToast(L('Meal logged.', 'Makanan tercatat.'));
      await reload();
    };
    document.getElementById('hWeightBtn').onclick = async () => {
      const w = Number(document.getElementById('hWeightIn').value);
      const goal = document.getElementById('hWeightGoalIn').value.trim();
      await api.savePrefs({ weightGoalKg: goal });
      if (w > 0) await api.saveHealthEntry({ day: todayStr, kind: 'weight', value_num: w, unit: 'kg' });
      showToast(L('Weight updated.', 'Berat badan diperbarui.'));
      await reload();
    };
    document.getElementById('hMeasBtn').onclick = async () => {
      const val = Number(document.getElementById('hMeasVal').value);
      if (!val) return;
      await api.saveHealthEntry({ day: todayStr, kind: 'measurement', name: document.getElementById('hMeasName').value, value_num: val, unit: 'cm' });
      showToast(L('Measurement saved.', 'Ukuran tubuh disimpan.'));
      await reload();
    };
    document.getElementById('hWoBtn').onclick = async () => {
      await api.saveHealthEntry({
        day: todayStr, kind: 'workout', name: document.getElementById('hWoName').value.trim() || L('Workout', 'Olahraga'),
        value_num: Number(document.getElementById('hWoMin').value) || 20, unit: 'min',
      });
      showToast(L('Workout saved.', 'Olahraga disimpan.'));
      await reload();
    };
  } else if (mod === 'wellness') {
    root.querySelectorAll('#wMoodPicker [data-wmood]').forEach(btn => {
      btn.onclick = () => {
        lifeState.wellnessMood = btn.dataset.wmood;
        lifeState.wellnessMoodScore = Number(btn.dataset.wscore);
        reload();
      };
    });
    const saveWellness = async () => {
      await api.saveWellnessEntry({
        day: todayStr,
        mood: lifeState.wellnessMood,
        mood_score: lifeState.wellnessMoodScore,
        energy: Number(document.getElementById('wEn').value) || 3,
        stress: Number(document.getElementById('wSt').value) || 2,
        sleep_hours: Number(document.getElementById('wSl').value) || 7.5,
        triggers_text: document.getElementById('wTrig').value.trim(),
        gratitude_text: document.getElementById('wGrat').value.trim(),
        note: document.getElementById('wNote').value.trim(),
      });
      showToast(L('Wellness check-in saved.', 'Catatan kesejahteraan disimpan.'));
      await reload();
    };
    document.getElementById('wSaveBtn').onclick = saveWellness;
    document.getElementById('wSleepSaveBtn').onclick = saveWellness;
    document.getElementById('wTrigSaveBtn').onclick = saveWellness;
  } else if (mod === 'menstrual') {
    document.getElementById('mReminderCb').onchange = async e => {
      await api.savePrefs({ periodReminders: e.target.checked });
      showToast(L('Reminder preference updated.', 'Pengaturan pengingat diperbarui.'));
    };
    root.querySelectorAll('#mSymChips [data-msym]').forEach(btn => {
      btn.onclick = () => {
        const s = btn.dataset.msym;
        const i = lifeState.selectedSymptoms.indexOf(s);
        if (i >= 0) lifeState.selectedSymptoms.splice(i, 1);
        else lifeState.selectedSymptoms.push(s);
        reload();
      };
    });
    const moodBtn = document.getElementById('mGoMoodBtn');
    if (moodBtn) moodBtn.onclick = () => { lifeState.reportModule = 'wellness'; reload(); };
    document.getElementById('mSaveBtn').onclick = async () => {
      const rawSyms = document.getElementById('mSym').value.trim();
      const extra = rawSyms ? rawSyms.split(',').map(s => s.trim()).filter(Boolean) : [];
      const syms = Array.from(new Set([...lifeState.selectedSymptoms, ...extra]));
      await api.saveMenstrualEntry({
        day: document.getElementById('mDay').value || todayStr,
        phase: document.getElementById('mPhase').value,
        cycle_day: Number(document.getElementById('mCycDay').value) || 1,
        flow: document.getElementById('mFlow').value,
        is_period_start: document.getElementById('mStart').value === '1',
        cycle_length: Number(document.getElementById('mLen').value) || 28,
        symptoms: syms,
      });
      lifeState.selectedSymptoms = [];
      showToast(L('Cycle log saved.', 'Catatan siklus disimpan.'));
      await reload();
    };
  } else {
    const sBox = document.getElementById('nSearchBox');
    if (sBox) {
      sBox.oninput = () => { lifeState.searchQuery = sBox.value; reload(); };
    }
    root.querySelectorAll('[data-ncat]').forEach(b => { b.onclick = () => { lifeState.noteCat = b.dataset.ncat; reload(); }; });
    root.querySelectorAll('[data-nid]').forEach(b => { b.onclick = () => { lifeState.selectedNoteId = b.dataset.nid; reload(); }; });
    document.getElementById('noteNewBtn').onclick = () => { lifeState.selectedNoteId = null; reload(); };
    document.getElementById('nSaveBtn').onclick = async () => {
      const saved = await api.saveNote({
        id: lifeState.selectedNoteId || undefined,
        day: todayStr,
        title: document.getElementById('nTitle').value.trim() || L('Quick Note', 'Catatan Cepat'),
        category: document.getElementById('nCat').value,
        tags_text: document.getElementById('nTags').value,
        body: document.getElementById('nBody').value,
        is_pinned: document.getElementById('nPin').checked ? 1 : 0,
      });
      lifeState.selectedNoteId = saved.id;
      showToast(L('Note saved.', 'Catatan disimpan.'));
      await reload();
    };
  }
}

export async function loadAuditView({ todayStr, showToast }) {
  const root = document.getElementById('auditRoot');
  const allRangeLogs = await api.getAuditLogs({ category: 'all', source: 'all', range: lifeState.reportRange, today: todayStr });
  const logs = await api.getAuditLogs({ category: lifeState.auditFilter, source: lifeState.auditSource, range: lifeState.reportRange, today: todayStr });
  const syncFail = allRangeLogs.filter(l => (l.category === 'sync' || l.category === 'discovery') && l.level === 'error').length;
  const authWarn = allRangeLogs.filter(l => l.category === 'auth' || l.status_code === 401).length;
  const lastFail = allRangeLogs.find(l => l.level === 'error' || l.level === 'warn');

  const lvlPill = lv => lv === 'error' ? 't-danger' : (lv === 'warn' ? 't-butter' : 't-sage');

  root.innerHTML = `
    <div class="metrics">
      <div class="card metric"><div class="big num">${allRangeLogs.length}</div><p>${L('total audit logs', 'total log audit')}</p></div>
      <div class="card metric"><div class="big num">${syncFail}</div><p>${L('sync / discovery failed', 'gagal sinkron / penemuan')}</p></div>
      <div class="card metric"><div class="big num">${authWarn}</div><p>${L('auth / 401 warnings', 'peringatan autentikasi')}</p></div>
      <div class="card metric"><div class="big num" style="font-size:1.1rem">${lastFail ? fmtDateTime(lastFail.created_at) : '—'}</div><p>${L('last failure', 'kegagalan terakhir')}</p></div>
    </div>
    <div class="card" style="padding:12px 16px">
      <div class="row" style="justify-content:space-between">
        <div class="seg" id="audFilterSeg">
          <button type="button" data-af="all" aria-pressed="${lifeState.auditFilter === 'all'}">${L('All', 'Semua')}</button>
          <button type="button" data-af="sync" aria-pressed="${lifeState.auditFilter === 'sync'}">${L('Sync Failed', 'Gagal Sinkron')}</button>
          <button type="button" data-af="auth" aria-pressed="${lifeState.auditFilter === 'auth'}">${L('Auth / 401', 'Autentikasi')}</button>
          <button type="button" data-af="info" aria-pressed="${lifeState.auditFilter === 'info'}">${L('Recovered', 'Pulih')}</button>
        </div>
        <select id="audSrcSel" style="min-height:34px;padding:0 10px;border-radius:10px;border:1px solid var(--line);background:var(--bg)">
          <option value="all" ${lifeState.auditSource === 'all' ? 'selected' : ''}>${L('All Sources', 'Semua Sumber')}</option>
          <option value="Desktop" ${lifeState.auditSource === 'Desktop' ? 'selected' : ''}>${L('Desktop Server', 'Server Desktop')}</option>
          <option value="Mobile" ${lifeState.auditSource === 'Mobile' ? 'selected' : ''}>${L('Mobile Client', 'Klien Ponsel')}</option>
        </select>
      </div>
    </div>
    <div class="card">
      <div class="head">
        <h2>${L('API & Sync Audit Log', 'Log Audit API & Sinkron')}</h2>
        <span class="small muted">${L('Tokens redacted · Local only', 'Token disamarkan · Lokal saja')}</span>
      </div>
      ${logs.length ? logs.map(l => `
        <div class="audit-item">
          <div class="audit-head">
            <div class="row" style="gap:6px">
              <span class="pill ${lvlPill(l.level)}">${esc((l.level || 'error').toUpperCase())}</span>
              <span class="pill t-muted num">${esc(l.endpoint)}</span>
              <span class="pill t-sky num">${l.status_code ? `HTTP ${l.status_code}` : 'NET'} · ${esc(l.error_code || 'ERR')}</span>
            </div>
            <span class="small muted num">${esc(l.source)} · ${fmtDateTime(l.created_at)}</span>
          </div>
          <div>${esc(l.message)}</div>
          ${l.details ? `<details class="audit-details"><summary>${L('Technical details', 'Detail teknis')}</summary><pre>${esc(JSON.stringify(l.details, null, 2))}</pre></details>` : ''}
        </div>
      `).join('') : `<p class="muted small" style="margin:8px 0 0">${L('No API or sync error logs match this filter.', 'Tidak ada log error yang cocok.')}</p>`}
    </div>
  `;

  root.querySelectorAll('#audFilterSeg [data-af]').forEach(b => {
    b.onclick = () => { lifeState.auditFilter = b.dataset.af; loadAuditView({ todayStr, showToast }); };
  });
  document.getElementById('audSrcSel').onchange = e => {
    lifeState.auditSource = e.target.value;
    loadAuditView({ todayStr, showToast });
  };
}

export function openQuickAddMenu({ todayStr, showToast, onSaved }) {
  const modal = document.getElementById('lifeosModal');
  const card = document.getElementById('lifeosModalCard');
  const items = [
    { k: 'task', ic: '✓', lbl: L('Add task', 'Tambah tugas'), pill: 't-sage' },
    { k: 'finance', ic: '$', lbl: L('Income / Expense', 'Pemasukan / Pengeluaran'), pill: 't-butter' },
    { k: 'food', ic: '🍽', lbl: L('Food entry', 'Catatan makan'), pill: 't-sky' },
    { k: 'weight', ic: '⚖', lbl: L('Weight / Measure', 'Berat / Ukuran'), pill: 't-sky' },
    { k: 'water', ic: '💧', lbl: L('Water glass', 'Minum air'), pill: 't-sky' },
    { k: 'workout', ic: '🏃', lbl: L('Workout', 'Olahraga'), pill: 't-sage' },
    { k: 'mood', ic: '◐', lbl: L('Mood check-in', 'Catatan suasana hati'), pill: 't-lavender' },
    { k: 'menstrual', ic: '✿', lbl: L('Menstrual log', 'Catatan siklus'), pill: 't-blush' },
    { k: 'note', ic: '✎', lbl: L('Quick note', 'Catatan cepat'), pill: 't-peach' },
  ];
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">${L('Global Quick Add', 'Tambah Cepat Global')}</p><h2>${L('Capture from Anywhere', 'Catat Kapan Saja')}</h2></div>
      <button class="icon-btn" type="button" id="qaClose">×</button>
    </div>
    <div class="qa-grid">
      ${items.map(it => `<button class="qa-opt" type="button" data-qa="${it.k}"><span class="pill ${it.pill}">${it.ic}</span><span>${it.lbl}</span></button>`).join('')}
    </div>
  `;
  modal.hidden = false;
  document.getElementById('qaClose').onclick = () => { modal.hidden = true; };
  card.querySelectorAll('[data-qa]').forEach(b => {
    b.onclick = () => openQuickAddForm(b.dataset.qa, { todayStr, showToast, onSaved });
  });
}

export async function openQuickAddForm(kind, { todayStr, showToast, onSaved }) {
  const modal = document.getElementById('lifeosModal');
  const card = document.getElementById('lifeosModalCard');
  const envelopes = kind === 'finance' ? await api.getEnvelopes() : [];
  const projects = kind === 'focus' ? await api.getProjects() : [];
  const envOpts = `<option value="">${L('No envelope', 'Tanpa amplop')}</option>` + envelopes.map(e => `<option value="${e.id}">${esc(e.name)}</option>`).join('');
  const projOpts = `<option value="">${L('No project', 'Tanpa proyek')}</option>` + projects.map(p => `<option value="${p.id}">${esc(p.name)}</option>`).join('');

  const defs = {
    task: { title: L('Add Task', 'Tambah Tugas'), fields: `<div class="field"><label>${L('Step name', 'Nama langkah')}</label><input id="qf1" placeholder="${L('Write daily summary', 'Tulis ringkasan harian')}"></div>` },
    finance: { title: L('Add Income / Expense', 'Tambah Transaksi'), fields: `<div class="field"><label>${L('Type', 'Tipe')}</label><select id="qf1"><option value="expense">${L('Expense', 'Pengeluaran')}</option><option value="income">${L('Income', 'Pemasukan')}</option></select></div><div class="field"><label>${L('Category', 'Kategori')}</label><select id="qf2"><option value="general">${L('General', 'Umum')}</option><option value="savings">${L('Savings', 'Tabungan')}</option><option value="debt">${L('Debt', 'Utang')}</option></select></div><div class="field"><label>${L('Amount (Rp)', 'Jumlah (Rp)')}</label><input id="qf3" type="number" placeholder="50000"></div><div class="field"><label>${L('Envelope', 'Amplop')}</label><select id="qf4">${envOpts}</select></div><div class="field"><label>${L('Note', 'Catatan')}</label><input id="qf5" placeholder="${L('Short note', 'Catatan singkat')}"></div>` },
    food: { title: L('Add Food Entry', 'Tambah Makanan'), fields: `<div class="field"><label>${L('Meal item', 'Nama makanan')}</label><input id="qf1" placeholder="Oatmeal"></div><div class="field"><label>${L('Calories (kcal)', 'Kalori (kcal)')}</label><input id="qf2" type="number" placeholder="450"></div>` },
    weight: { title: L('Add Weight Entry', 'Tambah Berat Badan'), fields: `<div class="field"><label>${L('Weight (kg)', 'Berat (kg)')}</label><input id="qf1" type="number" step="0.1" placeholder="62.5"></div><div class="field"><label>${L('Waist (cm, optional)', 'Lingkar pinggang (cm, opsional)')}</label><input id="qf2" type="number" step="0.5" placeholder="76"></div>` },
    water: { title: L('Add Water Intake', 'Tambah Minum Air'), fields: `<div class="field"><label>${L('Volume (ml)', 'Volume (ml)')}</label><input id="qf1" type="number" step="50" value="250"></div>` },
    workout: { title: L('Add Workout', 'Tambah Olahraga'), fields: `<div class="field"><label>${L('Workout', 'Jenis olahraga')}</label><input id="qf1" placeholder="${L('Morning walk', 'Jalan pagi')}"></div><div class="field"><label>${L('Minutes', 'Durasi (menit)')}</label><input id="qf2" type="number" value="30"></div>` },
    mood: { title: L('Mood Check-in', 'Catatan Suasana Hati'), fields: `<div class="field"><label>${L('Mood', 'Suasana hati')}</label><select id="qf1"><option value="Calm|4">${L('Calm', 'Tenang')} (4/5)</option><option value="Focused|5">${L('Focused', 'Fokus')} (5/5)</option><option value="Neutral|3">${L('Neutral', 'Biasa')} (3/5)</option><option value="Tired|2">${L('Tired', 'Lelah')} (2/5)</option><option value="Stressed|1">${L('Stressed', 'Tertekan')} (1/5)</option></select></div><div class="field"><label>${L('Energy (1-5)', 'Energi (1-5)')}</label><input id="qf2" type="number" min="1" max="5" value="4"></div><div class="field"><label>${L('Stress (1-5)', 'Stres (1-5)')}</label><input id="qf3" type="number" min="1" max="5" value="2"></div><div class="field"><label>${L('Sleep (hrs)', 'Tidur (jam)')}</label><input id="qf4" type="number" step="0.5" value="7"></div><div class="field"><label>${L('Triggers', 'Pemicu')}</label><input id="qf5" placeholder="${L('good rest', 'istirahat cukup')}"></div>` },
    menstrual: { title: L('Menstrual Log', 'Catatan Siklus'), fields: `<div class="field"><label>${L('Phase', 'Fase')}</label><select id="qf1"><option value="Menstrual">${L('Menstrual', 'Menstruasi')}</option><option value="Follicular">${L('Follicular', 'Folikular')}</option><option value="Ovulation">${L('Ovulation', 'Ovulasi')}</option><option value="Luteal">${L('Luteal', 'Luteal')}</option></select></div><div class="field"><label>${L('Cycle Day', 'Hari Siklus')}</label><input id="qf2" type="number" min="1" max="60" value="1"></div><div class="field"><label>${L('Symptoms', 'Gejala')}</label><input id="qf3" placeholder="${L('cramps, tired', 'kram, lelah')}"></div><div class="field"><label>${L('Flow', 'Volume')}</label><select id="qf4"><option value="None">${L('None', 'Tidak ada')}</option><option value="Light">${L('Light', 'Ringan')}</option><option value="Medium">${L('Medium', 'Sedang')}</option><option value="Heavy">${L('Heavy', 'Deras')}</option></select></div><div class="field"><label>${L('Period started today?', 'Mulai haid hari ini?')}</label><select id="qf5"><option value="0">${L('No', 'Tidak')}</option><option value="1">${L('Yes (Day 1)', 'Ya (Hari 1)')}</option></select></div>` },
    note: { title: L('Create Quick Note', 'Buat Catatan Cepat'), fields: `<div class="field"><label>${L('Title', 'Judul')}</label><input id="qf1" placeholder="${L('Quick title', 'Judul singkat')}"></div><div class="field"><label>${L('Body', 'Isi catatan')}</label><textarea id="qf2" rows="3" placeholder="${L('Thoughts or reflections...', 'Pikiran atau refleksi...')}"></textarea></div><div class="field"><label>${L('Tags', 'Tag')}</label><input id="qf3" placeholder="${L('reflection, calm', 'refleksi, tenang')}"></div>` },
    project: { title: L('Add Project', 'Tambah Proyek'), fields: `<div class="field"><label>${L('Name', 'Nama')}</label><input id="qf1" placeholder="${L('Health Q4 Plan', 'Rencana Kesehatan')}"></div><div class="field"><label>${L('Progress (%)', 'Progres (%)')}</label><input id="qf2" type="number" min="0" max="100" value="25"></div>` },
    envelope: { title: L('Add Budget Envelope', 'Tambah Amplop Anggaran'), fields: `<div class="field"><label>${L('Name', 'Nama')}</label><input id="qf1" placeholder="${L('Food', 'Makanan')}"></div><div class="field"><label>${L('Monthly budget (Rp)', 'Anggaran bulanan (Rp)')}</label><input id="qf2" type="number" placeholder="1000000"></div>` },
    focus: { title: L('Log Focus Session', 'Catat Sesi Fokus'), fields: `<div class="field"><label>${L('Project', 'Proyek')}</label><select id="qf1">${projOpts}</select></div><div class="field"><label>${L('Minutes', 'Menit')}</label><input id="qf2" type="number" value="25"></div><div class="field"><label>${L('Note', 'Catatan')}</label><input id="qf3" placeholder="${L('Deep work...', 'Fokus mendalam...')}"></div>` },
  };

  const def = defs[kind] || defs.task;
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">${L('Quick Add', 'Tambah Cepat')}</p><h2>${def.title}</h2></div>
      <button class="icon-btn" type="button" id="qfBack">←</button>
    </div>
    ${def.fields}
    <div class="row" style="justify-content:flex-end">
      <button class="btn" type="button" id="qfCancel">${tr(lifeState.lang, 'cancel_btn')}</button>
      <button class="btn primary" type="button" id="qfSave">${tr(lifeState.lang, 'save_btn')}</button>
    </div>
  `;
  modal.hidden = false;
  document.getElementById('qfBack').onclick = () => openQuickAddMenu({ todayStr, showToast, onSaved });
  document.getElementById('qfCancel').onclick = () => { modal.hidden = true; };
  document.getElementById('qfSave').onclick = async () => {
    const v = id => document.getElementById(id)?.value?.trim() || '';
    let payloadData = { day: todayStr };
    if (kind === 'task') payloadData = { name: v('qf1') || L('New step', 'Langkah baru') };
    else if (kind === 'finance') payloadData = { day: todayStr, type: v('qf1'), category: v('qf2'), amount: Number(v('qf3')) || 0, envelope_id: v('qf4') || null, note: v('qf5') };
    else if (kind === 'food') payloadData = { day: todayStr, name: v('qf1') || L('Meal', 'Makan'), value_num: Number(v('qf2')) || 0, unit: 'kcal' };
    else if (kind === 'weight') payloadData = { day: todayStr, value_num: Number(v('qf1')) || 0, value_num2: v('qf2') ? Number(v('qf2')) : null, unit: 'kg' };
    else if (kind === 'water') payloadData = { day: todayStr, name: 'Water', value_num: Number(v('qf1')) || 250, unit: 'ml' };
    else if (kind === 'workout') payloadData = { day: todayStr, name: v('qf1') || L('Workout', 'Olahraga'), value_num: Number(v('qf2')) || 20, unit: 'min' };
    else if (kind === 'mood') {
      const [mood, sc] = (v('qf1') || 'Calm|4').split('|');
      payloadData = { day: todayStr, mood, mood_score: Number(sc), energy: Number(v('qf2')) || 3, stress: Number(v('qf3')) || 2, sleep_hours: Number(v('qf4')) || 7, triggers_text: v('qf5') };
    } else if (kind === 'menstrual') {
      payloadData = { day: todayStr, phase: v('qf1'), cycle_day: Number(v('qf2')) || 1, symptoms: v('qf3') ? v('qf3').split(',').map(x => x.trim()).filter(Boolean) : [], flow: v('qf4'), is_period_start: v('qf5') === '1' };
    } else if (kind === 'note') {
      payloadData = { day: todayStr, title: v('qf1') || L('Quick Note', 'Catatan Cepat'), body: v('qf2'), tags_text: v('qf3') };
    } else if (kind === 'project') {
      payloadData = { name: v('qf1') || L('Project', 'Proyek'), progress: Number(v('qf2')) || 0 };
    } else if (kind === 'envelope') {
      payloadData = { name: v('qf1') || L('Envelope', 'Amplop'), monthly_budget: Number(v('qf2')) || 0 };
    } else if (kind === 'focus') {
      payloadData = { day: todayStr, project_id: v('qf1') || null, minutes: Number(v('qf2')) || 25, note: v('qf3') };
    }
    await api.quickAdd({ kind, data: payloadData });
    modal.hidden = true;
    showToast(`${def.title} ${L('saved.', 'disimpan.')}`);
    await onSaved();
  };
}
