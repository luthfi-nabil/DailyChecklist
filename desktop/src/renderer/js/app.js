import {
  lifeState,
  tr,
  L,
  loadLifeOsDashboard,
  openWidgetCatalogModal,
  loadModuleReportsView,
  loadAuditView,
  openQuickAddMenu,
  refreshAuditBadge,
} from './lifeos.js';

const api = window.electronAPI;

const DAYS_EN = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const DAYS_ID = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
const MONTHS_EN = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const MONTHS_ID = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

function activeDays() { return lifeState.lang === 'id' ? DAYS_ID : DAYS_EN; }
function activeMonths() { return lifeState.lang === 'id' ? MONTHS_ID : MONTHS_EN; }

function formatLocalDay(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseLocalDay(dateStr) {
  const [y, m, d] = String(dateStr || '').split('-').map(Number);
  if (!y || !m || !d) return new Date();
  return new Date(y, m - 1, d);
}

function getTodayStr() {
  return formatLocalDay(new Date());
}

function formatDisplayDate(dateStr) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const date = new Date(y, m - 1, d);
  return `${activeDays()[date.getDay()]}, ${d} ${activeMonths()[m - 1]}`;
}

function fmtShortDay(dayStr) {
  if (!dayStr) return '';
  const parts = String(dayStr).split('-');
  if (parts.length < 3) return '';
  const m = parseInt(parts[1], 10) - 1;
  const d = parseInt(parts[2], 10);
  return `${d} ${activeMonths()[m].slice(0, 3)}`;
}

function fmtShortMs(ms) {
  if (!ms) return '';
  const d = new Date(ms);
  return `${d.getDate()} ${activeMonths()[d.getMonth()].slice(0, 3)}`;
}

const CHECK_SVG = `<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true">
  <path d="M3 8.5l3.2 3.2L13 4.8" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`;

let currentView = 'dash';
let appPrefs = { colorPalette: 'pink', userName: 'User', language: 'en', showReportCharts: true };
let editMode = false;
let liteMode = localStorage.getItem('langkah-kecil-lite') === 'true';
let skippedTasks = {};
let todayData = null;
let currentDay = getTodayStr();
let selectedTodayDate = currentDay;
let todayCalYear = new Date().getFullYear();
let todayCalMonth = new Date().getMonth() + 1;
let showTodayCal = localStorage.getItem('langkah-kecil-cal') !== 'false';
let monthScheduleDots = {};

let calYear = new Date().getFullYear();
let calMonth = new Date().getMonth() + 1;
let selectedLogDay = getTodayStr();

let undoAction = null;
let toastTimer = null;

const DOW_FULL_EN = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const DOW_FULL_ID = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const DOW_SHORT_EN = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const DOW_SHORT_ID = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

function freqLabel(t) {
  if (!t || t.freq === 'daily' || !t.freq) return L('Daily', 'Setiap hari');
  const days = Array.isArray(t.freq_days) ? t.freq_days : (Array.isArray(t.freqDays) ? t.freqDays : []);
  const dowFull = lifeState.lang === 'id' ? DOW_FULL_ID : DOW_FULL_EN;
  if (t.freq === 'weekly') return days.map(d => dowFull[d] || d).join(', ');
  if (t.freq === 'monthly') return (lifeState.lang === 'id' ? 'Tanggal ' : 'Day ') + days.join(', ');
  return L('Daily', 'Setiap hari');
}

function esc(s) {
  return String(s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function showToast(msg, onUndo = null) {
  const toast = document.getElementById('toast');
  const toastMsg = document.getElementById('toastMsg');
  const toastUndo = document.getElementById('toastUndo');

  toastMsg.textContent = msg;
  undoAction = onUndo;
  toastUndo.hidden = !onUndo;
  toast.hidden = false;

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.hidden = true;
    undoAction = null;
  }, 6000);
}

// Theme init
function applyTheme(t) {
  if (t === 'auto') {
    document.documentElement.removeAttribute('data-theme');
  } else {
    document.documentElement.setAttribute('data-theme', t);
  }
  localStorage.setItem('langkah-kecil-theme', t);
  document.querySelectorAll('#themeSeg button').forEach(b => {
    b.setAttribute('aria-pressed', b.dataset.t === t ? 'true' : 'false');
  });
}

const PALETTE_LABELS = {
  pink: 'White & Pink',
  sage: 'Pastel Sage',
  teal: 'Slate Teal',
  lavender: 'Lavender Mist',
  peach: 'Warm Peach',
};

function applyPalette(palette) {
  const safe = PALETTE_LABELS[palette] ? palette : 'pink';
  if (safe === 'pink') document.documentElement.removeAttribute('data-palette');
  else document.documentElement.setAttribute('data-palette', safe);
  document.querySelectorAll('#paletteGrid [data-palette]').forEach(b => {
    const active = b.dataset.palette === safe;
    b.setAttribute('aria-pressed', active ? 'true' : 'false');
    b.textContent = active ? '✓' : '';
  });
  const badge = document.getElementById('activePaletteBadge');
  if (badge) badge.textContent = PALETTE_LABELS[safe];
}

function applyLanguage(lang) {
  lifeState.lang = lang === 'id' ? 'id' : 'en';
  document.documentElement.lang = lifeState.lang;
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    el.textContent = tr(lifeState.lang, key);
  });
  const searchEl = document.getElementById('globalSearchInput');
  if (searchEl) searchEl.placeholder = tr(lifeState.lang, 'search_ph');
  document.querySelectorAll('#langSeg [data-lang]').forEach(b => {
    b.setAttribute('aria-pressed', b.dataset.lang === lifeState.lang ? 'true' : 'false');
  });

  const staticPairs = {
    backTodayBtn: ['Back to today', 'Kembali ke hari ini'],
    openEditFromNote: ['View / Edit', 'Lihat / Ubah'],
    calLegWeekly: ['Weekly', 'Mingguan'],
    calLegMonthly: ['Monthly', 'Bulanan'],
    ptsUnitLabel: ['points', 'poin'],
    dashCustomTitle: ['Dashboard Customization Active', 'Mode Atur Dasbor Aktif'],
    dashCustomSub: ['Drag widgets to reorder, resize (S/M/L), toggle visibility, or add/remove modules.', 'Seret widget untuk mengatur urutan, ubah ukuran (S/M/L), atur visibilitas, atau tambah/hapus modul.'],
    dashAnalysisTitle: ['Checklist Analytics', 'Analisis Ceklis'],
    perWeekBtn: ['This week', 'Minggu ini'],
    perMonthBtn: ['This month', 'Bulan ini'],
    perAllBtn: ['All time', 'Semua'],
    mRateLabel: ['completion rate', 'tingkat selesai'],
    mDoneLabel: ['steps completed', 'langkah selesai'],
    mPtsLabel: ['points earned', 'poin didapat'],
    chartPerDayTitle: ['Steps per day', 'Langkah per hari'],
    statPerGroupTitle: ['By group', 'Per kelompok'],
    statPerTaskTitle: ['By step', 'Per langkah'],
    statMostFreqSub: ['most frequent first', 'paling sering dulu'],
    statInactiveFootnote: ['Deactivated steps are still counted on days when they were active, keeping historical trends intact.', 'Langkah nonaktif tetap dihitung pada hari ketika masih aktif, sehingga tren riwayat tidak berubah.'],
    calHeatFootnote: ['Darker shades mean more completed steps.', 'Makin pekat warnanya, makin banyak langkah selesai.'],
    offTasksTitle: ['Inactive steps', 'Langkah nonaktif'],
    offGroupsTitle: ['Inactive groups', 'Kelompok nonaktif'],
    setProfTitle: ['Profile & Appearance', 'Profil & Tampilan'],
    setNameLabel: ['Display name (updates greeting)', 'Nama tampilan (untuk sapaan)'],
    setPaletteLabel: ['Color palette (default: White & Pink)', 'Palet warna (bawaan: White & Pink)'],
    setThemeLabel: ['Theme mode', 'Mode tema'],
    themeAutoBtn: ['Auto', 'Otomatis'],
    themeLightBtn: ['Light', 'Terang'],
    themeDarkBtn: ['Dark', 'Gelap'],
    setLangTitle: ['Language', 'Bahasa'],
    setLangSub: ['Switch app labels between English & Bahasa Indonesia.', 'Ganti label aplikasi antara Bahasa Inggris & Bahasa Indonesia.'],
    setChartsTitle: ['Show charts in reports', 'Tampilkan grafik di laporan'],
    setChartsSub: ['Optional visual bars; off = calm numeric tables only.', 'Batang visual opsional; nonaktif = angka ringkas saja.'],
    setBackupTitle: ['Backup & Restore', 'Cadangan & Pulihkan'],
    setBackupSub: ['Your SQLite database is stored locally and auto-backed up before schema upgrades. Export or restore a full JSON snapshot anytime.', 'Database SQLite disimpan lokal dan dicadangkan otomatis sebelum pembaruan. Ekspor atau pulihkan cadangan JSON kapan saja.'],
    exportJsonBtn: ['⬇ Export JSON Backup', '⬇ Ekspor Cadangan JSON'],
    importJsonBtn: ['⬆ Restore JSON Backup', '⬆ Pulihkan Cadangan JSON'],
    setLanTitle: ['Local LAN Sync', 'Sinkronisasi LAN Lokal'],
    setLanSub: ['Local-only sync server announced via mDNS and UDP 47899. Phone finds this Desktop automatically without manual cloud accounts.', 'Server sinkron lokal via mDNS dan UDP 47899. Ponsel menemukan Desktop ini secara otomatis tanpa akun cloud.'],
    setIpPortLbl: ['Desktop LAN IP & Port:', 'IP & Port LAN Desktop:'],
    setPairCodeLbl: ['Pairing code:', 'Kode sambungan:'],
    rotateCodeBtn: ['Rotate code', 'Acak kode'],
    setManualEndpointTitle: ['Manual Listen IP & Port', 'IP & Port Manual'],
    setBindIpLbl: ['Bind IP', 'IP Bind'],
    setBindPortLbl: ['Port', 'Port'],
    resetSyncNetBtn: ['Reset 47800', 'Atur ulang 47800'],
    saveSyncNetBtn: ['Apply', 'Terapkan'],
    setPairedTitle: ['Paired Devices', 'Perangkat Terhubung'],
    setTokenTitle: ['Token lifetime', 'Masa berlaku token'],
    setTokenSub: ['Phone re-pairs after expiry.', 'Ponsel menyambung ulang setelah kedaluwarsa.'],
    setAutoSyncTitle: ['Auto-sync on LAN', 'Sinkron otomatis di LAN'],
    setAutoSyncSub: ['Two-way LWW merge.', 'Penggabungan LWW dua arah.'],
    setBgTitle: ['Desktop Background', 'Latar Belakang Desktop'],
    setAutostartTitle: ['Launch on startup', 'Jalankan saat startup'],
    setAutostartSub: ['Starts minimized in system tray.', 'Mulai diminimalkan ke baki sistem.'],
    setTrayTitle: ['Keep running on close', 'Tetap berjalan saat ditutup'],
    setTraySub: ['Keep sync server alive in tray.', 'Menjaga server sinkron tetap aktif di baki sistem.'],
    setQuitTitle: ['Quit completely', 'Keluar sepenuhnya'],
    setQuitSub: ['Stops tray process and sync server.', 'Menghentikan proses baki dan server sinkron.'],
    schedModalEyebrow: ['Task Schedule', 'Atur Jadwal Aktivitas'],
    freqDailyBtn: ['Daily', 'Harian'],
    freqWeeklyBtn: ['Weekly', 'Mingguan'],
    freqMonthlyBtn: ['Monthly', 'Bulanan'],
    schedWeeklyPrompt: ['Choose which days this step appears:', 'Pilih hari apa saja aktivitas ini muncul:'],
    schedMonthlyPrompt: ['Choose which dates each month:', 'Pilih tanggal berapa saja setiap bulan:'],
    saveSchedModalBtn: ['Save schedule', 'Simpan jadwal'],
  };
  Object.entries(staticPairs).forEach(([id, [en, idTxt]]) => {
    const el = document.getElementById(id);
    if (el) el.textContent = L(en, idTxt);
  });
  const editNoteEl = document.getElementById('editNote');
  if (editNoteEl) {
    editNoteEl.innerHTML = L(
      'Edit mode active. All tasks are visible (including tasks scheduled on other days). Tap 📅 to set a <b>Daily</b>, <b>Weekly</b>, or <b>Monthly</b> schedule.',
      'Mode ubah aktif. Semua langkah ditampilkan (termasuk yang terjadwal di hari lain). Ketuk 📅 untuk mengatur jadwal <b>Harian</b>, <b>Mingguan</b>, atau <b>Bulanan</b>.',
    );
  }
  const offIntroEl = document.getElementById('offIntroNote');
  if (offIntroEl) {
    offIntroEl.innerHTML = L(
      'Deactivating a step or group keeps your history and earned points safe. You can <b>Restore</b> it anytime, or <b>Delete Permanently</b> to remove it completely.',
      'Menonaktifkan langkah atau kelompok menjaga riwayat dan poinmu tetap aman. Kamu bisa memilih <b>Pulihkan</b> kapan saja, atau <b>Hapus Permanen</b> untuk menghapusnya.',
    );
  }
}

function applyPreferences(prefs) {
  if (!prefs) return;
  appPrefs = prefs;
  applyPalette(prefs.colorPalette || 'pink');
  applyLanguage(prefs.language || 'en');
  document.body.classList.toggle('hide-report-charts', prefs.showReportCharts === false);
  const nameIn = document.getElementById('userNameInput');
  if (nameIn && document.activeElement !== nameIn) nameIn.value = prefs.userName || 'User';
  const chSw = document.getElementById('showChartsSwitch');
  if (chSw) chSw.setAttribute('aria-checked', prefs.showReportCharts === false ? 'false' : 'true');
  if (currentView === 'dash') {
    document.getElementById('viewTitle').textContent = `${tr(lifeState.lang, 'hello')}, ${prefs.userName || 'User'} ♡`;
  }
}

applyTheme(localStorage.getItem('langkah-kecil-theme') || 'auto');

// --- RENDER TODAY & CHECKLIST CALENDAR ---
async function renderTodayCalendar() {
  const card = document.getElementById('todayCalCard');
  const toggleBtn = document.getElementById('calToggleBtn');
  card.hidden = !showTodayCal;
  toggleBtn.setAttribute('aria-pressed', showTodayCal ? 'true' : 'false');
  if (!showTodayCal) return;

  monthScheduleDots = await api.getMonthSchedule({ year: todayCalYear, month: todayCalMonth });
  document.getElementById('todayCalTitle').textContent = `${activeMonths()[todayCalMonth - 1]} ${todayCalYear}`;

  const firstDay = new Date(todayCalYear, todayCalMonth - 1, 1).getDay();
  const offset = (firstDay + 6) % 7;
  const daysInMonth = new Date(todayCalYear, todayCalMonth, 0).getDate();

  let html = '';
  (lifeState.lang === 'id' ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'] : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']).forEach(d => {
    html += `<div class="dow">${d}</div>`;
  });
  for (let i = 0; i < offset; i++) html += '<div></div>';

  for (let day = 1; day <= daysInMonth; day++) {
    const dStr = `${todayCalYear}-${String(todayCalMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const dot = monthScheduleDots[dStr];
    const isToday = dStr === currentDay;
    const isSel = dStr === selectedTodayDate;
    html += `
      <button type="button" class="cday ${isToday ? 'today' : ''}" data-cday="${dStr}" aria-pressed="${isSel}" aria-label="${day} ${activeMonths()[todayCalMonth - 1]}">
        <span>${day}</span>
        <span class="dots">
          ${dot && dot.hasWeekly ? '<i class="dot w"></i>' : ''}
          ${dot && dot.hasMonthly ? '<i class="dot m"></i>' : ''}
        </span>
      </button>
    `;
  }

  const grid = document.getElementById('todayCalGrid');
  grid.innerHTML = html;
  grid.querySelectorAll('[data-cday]').forEach(btn => {
    btn.onclick = () => {
      selectedTodayDate = btn.dataset.cday;
      loadTodayData();
    };
  });
}

async function loadTodayData() {
  todayData = await api.getToday(selectedTodayDate);
  await renderTodayCalendar();
  renderToday();
}

function renderToday() {
  if (!todayData) return;

  document.getElementById('currentDate').textContent = formatDisplayDate(selectedTodayDate);
  const isFuture = selectedTodayDate > currentDay;
  const isPast = selectedTodayDate < currentDay;
  const banner = document.getElementById('dateBanner');
  banner.hidden = selectedTodayDate === currentDay;
  if (isFuture) {
    document.getElementById('dateBannerText').textContent = L('Previewing upcoming schedule (cannot check off yet).', 'Pratinjau jadwal mendatang (belum bisa dicentang).');
  } else if (isPast) {
    document.getElementById('dateBannerText').textContent = L('Viewing a previous day record.', 'Melihat catatan tanggal sebelumnya.');
  }

  const allTasks = [];
  todayData.groups.forEach(g => g.tasks.forEach(t => allTasks.push(t)));

  const scheduledAll = allTasks.filter(t => t.scheduled !== false);
  const offDayCount = allTasks.length - scheduledAll.length;
  const counted = scheduledAll.filter(t => !liteMode || t.core);
  const total = counted.length;
  const done = counted.filter(t => t.done).length;
  const pct = total ? Math.round((done / total) * 100) : 0;

  document.getElementById('navCount').textContent = `${done}/${total}`;
  document.getElementById('navPts').textContent = todayData.balance;

  let msg = L('No steps scheduled for this date.', 'Belum ada langkah terjadwal untuk tanggal ini.');
  if (total > 0) {
    if (isFuture) msg = L('Scheduled steps planned for this date.', 'Jadwal yang direncanakan pada tanggal ini.');
    else if (done === total) msg = L('All done for today. You can rest.', 'Semua selesai hari ini. Kamu boleh istirahat.');
    else if (done === 0) msg = L('It is okay not to start yet. Pick the smallest step.', 'Belum mulai juga tidak apa-apa. Pilih satu yang paling kecil.');
    else msg = L(`${done} steps done today. Keep going if you still have energy.`, `Sudah ${done} langkah hari ini. Lanjut kalau masih ada tenaga.`);
  }

  document.getElementById('progressCard').innerHTML = `
    <div class="row" style="justify-content:space-between;align-items:baseline;margin-bottom:10px">
      <div class="big num">${done}<small> ${L('of', 'dari')} ${total} ${L('steps', 'langkah')}</small></div>
      <div class="big num">${pct}<small>%</small></div>
    </div>
    <div class="progress" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${pct}" aria-label="${L('Today progress', 'Progres hari ini')}">
      <span style="width:${pct}%"></span>
    </div>
    <p class="muted small" style="margin:10px 0 0">${esc(msg)}</p>
    <div class="switch-row">
      <p><b>${L('Low-energy day', 'Hari berat')}</b><br><span class="muted small">${L('Show core steps (★) only.', 'Tampilkan hanya langkah inti (★).')}</span></p>
      <button class="switch" role="switch" id="liteSwitch" aria-checked="${liteMode}" aria-label="${L('Low-energy day mode', 'Mode hari berat')}"></button>
    </div>
  `;

  document.getElementById('liteSwitch').onclick = () => {
    liteMode = !liteMode;
    localStorage.setItem('langkah-kecil-lite', liteMode ? 'true' : 'false');
    renderToday();
  };

  renderFocus(counted, isFuture);

  const otherNote = document.getElementById('otherDayNote');
  otherNote.hidden = editMode || offDayCount === 0;
  if (!otherNote.hidden) {
    document.getElementById('otherDayText').textContent = L(
      `${offDayCount} weekly/monthly activities are scheduled for other days.`,
      `${offDayCount} aktivitas mingguan/bulanan dijadwalkan di tanggal lain.`,
    );
  }

  const container = document.getElementById('groupsContainer');
  let html = '';

  todayData.groups.forEach((g, gIdx) => {
    const visibleTasks = g.tasks.filter(t => editMode || (t.scheduled !== false && (!liteMode || t.core)));
    if (!editMode && visibleTasks.length === 0) return;
    const gDone = visibleTasks.filter(t => t.done).length;

    html += `<section class="card" aria-label="${esc(g.name)}">`;

    if (editMode) {
      const isFirst = gIdx === 0;
      const isLast = gIdx === todayData.groups.length - 1;
      html += `
        <div class="head" style="gap:6px">
          <input class="text-in gname-input" style="font-family:var(--font-display);font-weight:600"
                 data-gid="${g.id}" value="${esc(g.name)}" placeholder="${L('Group name', 'Nama kelompok')}" aria-label="${L('Group name', 'Nama kelompok')}">
          <button class="move-g-btn" type="button" data-move-gid="${g.id}" data-dir="-1" ${isFirst ? 'disabled' : ''} title="${L('Move up', 'Pindah ke atas')}">↑</button>
          <button class="move-g-btn" type="button" data-move-gid="${g.id}" data-dir="1" ${isLast ? 'disabled' : ''} title="${L('Move down', 'Pindah ke bawah')}">↓</button>
          <button class="btn deact-g-btn" data-gid="${g.id}">${L('Deactivate', 'Nonaktifkan')}</button>
        </div>
      `;
    } else {
      html += `
        <div class="head">
          <h2>${esc(g.name)}</h2>
          <span class="count num">${gDone}/${visibleTasks.length}</span>
        </div>
      `;
    }

    html += `<ul class="tasks">`;
    visibleTasks.forEach(t => {
      if (editMode) {
        const cls = t.freq === 'weekly' ? 'weekly' : (t.freq === 'monthly' ? 'monthly' : '');
        const label = freqLabel(t);
        const dueNote = t.scheduled === false ? `<span class="freq-tag offday">${L('Not scheduled today', 'Bukan tanggal ini')}</span>` : '';
        html += `
          <li class="erow">
            <div class="erow-top">
              <button class="icon-btn core-btn ${t.core ? 'on' : ''}" data-tid="${t.id}" aria-pressed="${!!t.core}" aria-label="${L('Mark core step', 'Tandai langkah inti')}">
                ${t.core ? '★' : '☆'}
              </button>
              <input class="text-in tname-input" id="t-${t.id}" data-tid="${t.id}" value="${esc(t.name)}" placeholder="${L('Step name', 'Nama langkah')}" aria-label="${L('Step name', 'Nama langkah')}">
              <button class="sched-btn ${cls}" type="button" data-sched="${t.id}" title="${esc(label)}" aria-label="${L('Schedule', 'Jadwal')}: ${esc(label)}">📅</button>
              <button class="icon-btn deact-t-btn" data-tid="${t.id}" aria-label="${L('Deactivate step', 'Nonaktifkan langkah')}">${L('Deactivate', 'Nonaktifkan')}</button>
            </div>
            <div class="erow-sub">
              <span class="freq-pill ${cls}">${esc(label)}</span>
              ${dueNote}
            </div>
          </li>
        `;
      } else {
        const badge = t.freq && t.freq !== 'daily'
          ? `<span class="freq-tag ${t.freq === 'monthly' ? 'monthly' : ''}">${esc(freqLabel(t))}</span>`
          : '';
        html += `
          <li class="task ${t.done ? 'done' : ''}">
            <label class="check">
              <input type="checkbox" class="chk-task" data-tid="${t.id}" ${t.done ? 'checked' : ''} ${isFuture ? 'disabled' : ''}>
              <span class="box">${CHECK_SVG}</span>
              <span class="nm">${esc(t.name)}${t.core && !liteMode ? `<span class="star">★ ${L('core', 'inti')}</span>` : ''}${badge}</span>
            </label>
          </li>
        `;
      }
    });
    html += `</ul>`;

    if (editMode) {
      html += `<button class="btn dashed add-t-btn" data-gid="${g.id}" style="margin-top:8px">+ ${L('Add step', 'Tambah langkah')}</button>`;
    }
    html += `</section>`;
  });

  if (editMode) {
    html += `<button class="btn dashed" id="addGroupBtn">+ ${L('Add group', 'Tambah kelompok')}</button>`;
  }

  container.innerHTML = html;
  bindTodayEvents();
}

function renderFocus(countedTasks, isFuture = false) {
  const focusEl = document.getElementById('focusCard');
  if (editMode || isFuture || countedTasks.length === 0) {
    focusEl.hidden = true;
    return;
  }

  focusEl.hidden = false;
  const uncompleted = countedTasks.filter(t => !t.done);

  if (uncompleted.length === 0) {
    focusEl.innerHTML = `
      <p class="eyebrow">${L('Done', 'Selesai')}</p>
      <p class="focus-name">${L('All scheduled steps are complete.', 'Semua langkah terjadwal sudah beres.')}</p>
      <p class="hint">${L('Check Rewards if you want to redeem something.', 'Cek Hadiah kalau mau menukar poin.')}</p>
      <button class="btn primary" id="focusGoRewards">${L('View rewards', 'Lihat hadiah')}</button>
    `;
    document.getElementById('focusGoRewards').onclick = () => switchView('rewards');
    return;
  }

  let next = uncompleted.find(t => !skippedTasks[t.id]);
  if (!next) {
    skippedTasks = {};
    next = uncompleted[0];
  }

  focusEl.innerHTML = `
    <p class="eyebrow">${L('Start here', 'Mulai dari sini')}</p>
    <p class="focus-name">${esc(next.name)}</p>
    <p class="hint">${L('Just this one first. Everything else can wait.', 'Cukup yang ini dulu. Yang lain boleh menunggu.')}</p>
    <div class="row">
      <button class="btn primary" id="focusDoneBtn" data-tid="${next.id}">${L('Done', 'Sudah selesai')}</button>
      <button class="btn" id="focusSkipBtn" data-tid="${next.id}">${L('Skip for now', 'Lewati dulu')}</button>
    </div>
  `;

  document.getElementById('focusDoneBtn').onclick = async () => {
    await api.toggleCheck({ taskId: next.id, day: selectedTodayDate, checked: true });
    await loadTodayData();
  };

  document.getElementById('focusSkipBtn').onclick = () => {
    skippedTasks[next.id] = true;
    renderFocus(countedTasks, isFuture);
  };
}

function bindTodayEvents() {
  document.querySelectorAll('.chk-task').forEach(chk => {
    chk.onchange = async (e) => {
      const tid = e.target.dataset.tid;
      const checked = e.target.checked;
      await api.toggleCheck({ taskId: tid, day: selectedTodayDate, checked });
      await loadTodayData();
    };
  });

  if (editMode) {
    document.querySelectorAll('[data-sched]').forEach(btn => {
      btn.onclick = () => openSchedModal(btn.dataset.sched);
    });
    document.querySelectorAll('.tname-input').forEach(input => {
      let timer;
      const save = async () => {
        const tid = input.dataset.tid;
        const task = findTask(tid);
        if (task) {
          task.name = input.value;
          await api.saveTask(task);
        }
      };
      input.oninput = () => { clearTimeout(timer); timer = setTimeout(save, 300); };
      input.onchange = () => { clearTimeout(timer); save(); };
    });

    document.querySelectorAll('.gname-input').forEach(input => {
      let timer;
      const save = async () => {
        const gid = input.dataset.gid;
        const group = todayData.groups.find(g => g.id === gid);
        if (group) {
          group.name = input.value;
          await api.saveGroup({ id: group.id, name: input.value, sort: group.sort });
        }
      };
      input.oninput = () => { clearTimeout(timer); timer = setTimeout(save, 300); };
      input.onchange = () => { clearTimeout(timer); save(); };
    });

    document.querySelectorAll('.core-btn').forEach(btn => {
      btn.onclick = async () => {
        const tid = btn.dataset.tid;
        const task = findTask(tid);
        if (task) {
          task.core = task.core ? 0 : 1;
          await api.saveTask(task);
          await loadTodayData();
        }
      };
    });

    document.querySelectorAll('.deact-t-btn').forEach(btn => {
      btn.onclick = async () => {
        const tid = btn.dataset.tid;
        await api.deactivateTask(tid);
        await loadTodayData();
        await refreshInactiveCount();
        showToast(L('Step deactivated. History kept.', 'Langkah dinonaktifkan. Riwayat tetap tersimpan.'), async () => {
          await api.reactivateTask(tid);
          await loadTodayData();
          await refreshInactiveCount();
        });
      };
    });

    document.querySelectorAll('.move-g-btn').forEach(btn => {
      btn.onclick = async () => {
        const id = btn.dataset.moveGid;
        const delta = Number(btn.dataset.dir);
        await api.moveGroup({ id, delta });
        await loadTodayData();
      };
    });

    document.querySelectorAll('.deact-g-btn').forEach(btn => {
      btn.onclick = async () => {
        const gid = btn.dataset.gid;
        await api.deactivateGroup(gid);
        await loadTodayData();
        await refreshInactiveCount();
        showToast(L('Group deactivated. History kept.', 'Kelompok dinonaktifkan. Riwayat tetap tersimpan.'), async () => {
          await api.reactivateGroup(gid);
          await loadTodayData();
          await refreshInactiveCount();
        });
      };
    });

    document.querySelectorAll('.add-t-btn').forEach(btn => {
      btn.onclick = async () => {
        const gid = btn.dataset.gid;
        const saved = await api.saveTask({ group_id: gid, name: L('New step', 'Langkah baru'), core: 0 });
        await loadTodayData();
        const el = document.getElementById(`t-${saved.id}`);
        if (el) { el.focus(); el.select(); }
      };
    });

    const addGroupBtn = document.getElementById('addGroupBtn');
    if (addGroupBtn) {
      addGroupBtn.onclick = async () => {
        await api.saveGroup({ name: L('New group', 'Kelompok baru'), sort: todayData.groups.length });
        await loadTodayData();
      };
    }
  }
}

function findTask(tid) {
  if (!todayData) return null;
  for (const g of todayData.groups) {
    for (const t of g.tasks) {
      if (t.id === tid) return t;
    }
  }
  return null;
}

// --- RENDER HADIAH ---
async function loadRewards() {
  const rewards = await api.getRewards();
  const claims = await api.getClaims();
  if (!todayData) todayData = await api.getToday(currentDay);
  const bal = todayData.balance;

  document.getElementById('ptsBalance').textContent = bal;
  document.getElementById('navPts').textContent = bal;

  const container = document.getElementById('rewardsContainer');
  const icons = ['♡', '✿', '☆', '✦'];
  let html = '';

  rewards.forEach((r, idx) => {
    const canClaim = bal >= r.cost;
    const pct = Math.min(100, Math.round((bal / Math.max(1, r.cost)) * 100));

    if (editMode) {
      html += `
        <div class="reward-m6">
          <div class="row" style="flex-wrap:nowrap">
            <input class="text-in rname-in" data-rid="${r.id}" value="${esc(r.name)}" placeholder="${L('Reward name', 'Nama hadiah')}" aria-label="${L('Reward name', 'Nama hadiah')}">
            <input class="text-in num-in rcost-in" data-rid="${r.id}" type="number" min="1" max="999" value="${r.cost}" aria-label="${L('Points cost', 'Harga poin')}">
            <button class="icon-btn deact-r-btn" data-rid="${r.id}" aria-label="${L('Remove reward', 'Hapus hadiah')}">×</button>
          </div>
        </div>
      `;
    } else {
      html += `
        <div class="reward-m6">
          <div>
            <div class="star">${icons[idx % icons.length]}</div>
            <h4>${esc(r.name)}</h4>
            <p class="num">${r.cost} ${L('points', 'poin')}</p>
            <div class="progress" style="margin:10px 0 0"><span style="width:${pct}%"></span></div>
          </div>
          <button class="btn claim-btn" style="margin-top:12px;width:fit-content" data-rid="${r.id}" ${canClaim ? '' : 'disabled'}>
            ${canClaim ? L('Redeem', 'Tukar') : L(`Need ${r.cost - bal} more`, `Kurang ${r.cost - bal} lagi`)}
          </button>
        </div>
      `;
    }
  });

  if (editMode) {
    html += `<button class="btn dashed" id="addRewardBtn" style="grid-column:1/-1">+ ${L('Create reward', 'Buat hadiah')}</button>`;
  }

  container.innerHTML = html;

  const claimsList = document.getElementById('claimsList');
  if (claims.length === 0) {
    claimsList.innerHTML = `<li class="muted">${L('No rewards claimed yet.', 'Belum ada hadiah yang ditukar.')}</li>`;
  } else {
    claimsList.innerHTML = claims.slice(0, 10).map(c => `
      <li>
        <span>${esc(c.name)}</span>
        <span>${fmtShortDay(c.day)}</span>
      </li>
    `).join('');
  }

  const achEl = document.getElementById('rewardsAchievementsContainer');
  if (achEl) {
    const sum = await api.getLifeOsSummary(currentDay);
    const achDefs = {
      'first-step': { name: L('First step', 'Langkah pertama'), desc: L('Complete your first task', 'Selesaikan langkah pertamamu') },
      'streak-7': { name: L('Consistency week', 'Pekan konsisten'), desc: L('7-day active streak', 'Aktif 7 hari beruntun') },
      'checks-25': { name: L('Little by little', 'Sedikit demi sedikit'), desc: L('25 completed steps', '25 langkah terselesaikan') },
      'focus-60': { name: L('Deep calm focus', 'Fokus tenang mendalam'), desc: L('60m focus logged', '60m fokus tercatat') },
      'self-care-1': { name: L('Kind treat', 'Apresiasi diri'), desc: L('Claim your first reward', 'Tukar hadiah pertamamu') },
    };
    achEl.innerHTML = (sum.achievements || []).map(a => {
      const def = achDefs[a.id] || { name: a.id, desc: '' };
      return `
        <div class="listrow">
          <div>
            <b>${def.name}</b>
            <div class="muted small">${def.desc} · <span class="num">${a.progress}/${a.target}</span></div>
          </div>
          <span class="pill-m6">${a.unlocked ? L('Unlocked ✓', 'Terbuka ✓') : L('Not unlocked', 'Belum terbuka')}</span>
        </div>
      `;
    }).join('');
  }

  if (editMode) {
    document.querySelectorAll('.rname-in').forEach(input => {
      let timer;
      const save = async () => {
        const reward = rewards.find(x => x.id === input.dataset.rid);
        if (reward) {
          reward.name = input.value;
          await api.saveReward(reward);
        }
      };
      input.oninput = () => { clearTimeout(timer); timer = setTimeout(save, 300); };
      input.onchange = () => { clearTimeout(timer); save(); };
    });

    document.querySelectorAll('.rcost-in').forEach(input => {
      let timer;
      const save = async () => {
        const reward = rewards.find(x => x.id === input.dataset.rid);
        if (reward) {
          const val = Math.max(1, Math.min(999, parseInt(input.value, 10) || 1));
          reward.cost = val;
          await api.saveReward(reward);
        }
      };
      input.oninput = () => { clearTimeout(timer); timer = setTimeout(save, 300); };
      input.onchange = () => { clearTimeout(timer); save(); };
    });

    document.querySelectorAll('.deact-r-btn').forEach(btn => {
      btn.onclick = async () => {
        const rid = btn.dataset.rid;
        await api.deactivateReward(rid);
        await loadRewards();
        showToast(L('Reward deleted.', 'Hadiah dihapus.'), async () => {
          await api.reactivateReward(rid);
          await loadRewards();
        });
      };
    });

    const addBtn = document.getElementById('addRewardBtn');
    if (addBtn) {
      addBtn.onclick = async () => {
        await api.saveReward({ name: L('New reward', 'Hadiah baru'), cost: 10, sort: rewards.length });
        await loadRewards();
      };
    }
  } else {
    document.querySelectorAll('.claim-btn').forEach(btn => {
      btn.onclick = async () => {
        const rid = btn.dataset.rid;
        try {
          const claim = await api.claimReward({ rewardId: rid, day: currentDay });
          await loadTodayData();
          await loadRewards();
          showToast(L(`Claimed: ${claim.name}. Enjoy guilt-free!`, `Ditukar: ${claim.name}. Nikmati tanpa rasa bersalah.`), async () => {
            const ok = await api.undoClaim(claim.id);
            if (!ok) {
              showToast(L('Already synced, cannot undo.', 'Sudah tersinkronisasi, tidak bisa dibatalkan.'));
            } else {
              await loadTodayData();
              await loadRewards();
            }
          });
        } catch (err) {
          showToast(L('Not enough points.', 'Poin tidak mencukupi.'));
        }
      };
    });
  }
}

// --- RENDER DASBOR ---
let currentPeriod = 'week';

async function loadDashboard() {
  await loadLifeOsDashboard({
    todayStr: currentDay,
    onOpenReport: (mod) => {
      lifeState.reportModule = mod;
      switchView('reports');
    },
    onOpenRewards: () => switchView('rewards'),
    onOpenToday: () => switchView('today'),
    showToast,
  });
  const stats = await api.getDashboard({ period: currentPeriod, day: currentDay });

  document.getElementById('periodNote').textContent = `${stats.label} · ${stats.rate}% ${L('done', 'selesai')}`;
  document.getElementById('mRate').textContent = stats.rate;
  document.getElementById('mDone').textContent = stats.totalDone;
  document.getElementById('mDays').innerHTML = `${stats.activeDays}<small>/${stats.daysCount}</small>`;
  document.getElementById('mStreakText').textContent = L(`active days · ${stats.currentStreak}-day streak`, `hari aktif · beruntun ${stats.currentStreak} hari`);
  document.getElementById('mPts').textContent = `+${stats.pointsEarned}`;

  const maxDayCount = Math.max(...stats.dailyChart.map(d => d.count), 5);
  document.getElementById('chartMaxCount').textContent = `${L('max', 'maks')} ${maxDayCount}`;

  const chartEl = document.getElementById('dailyChart');
  chartEl.innerHTML = stats.dailyChart.map(d => {
    const heightPct = d.count === 0 ? 0 : Math.max(6, Math.round((d.count / maxDayCount) * 100));
    return `
      <div class="bc">
        <i class="${d.isToday ? 'today' : ''}" style="height:${heightPct}%" title="${d.count} ${L('steps', 'langkah')}"></i>
        <span>${esc(d.dow)}</span>
      </div>
    `;
  }).join('');

  const groupStatsEl = document.getElementById('groupStatsContainer');
  groupStatsEl.innerHTML = stats.groupStats.map(g => `
    <div class="item">
      <div class="item-top"><span>${esc(g.name)}</span><span>${g.rate}%</span></div>
      <div class="progress"><span style="width:${g.rate}%"></span></div>
    </div>
  `).join('') || `<p class="muted small">${L('No groups yet.', 'Belum ada kelompok.')}</p>`;

  const taskStatsEl = document.getElementById('taskStatsContainer');
  taskStatsEl.innerHTML = stats.taskStats.slice(0, 8).map(t => `
    <div class="item">
      <div class="item-top">
        <span>
          ${esc(t.name)}
          ${t.freq && t.freq !== 'daily' ? `<span class="freq-tag ${t.freq === 'monthly' ? 'monthly' : ''}">${esc(freqLabel(t))}</span>` : ''}
          ${!t.isActive ? `<span class="tag">${L('Inactive since', 'Nonaktif sejak')} ${fmtShortMs(t.deactivatedAt)}</span>` : ''}
        </span>
        <span>${t.done}/${t.totalDays}</span>
      </div>
      <div class="progress">
        <span style="width:${t.rate}%;${!t.isActive ? 'background:var(--box-line)' : ''}"></span>
      </div>
    </div>
  `).join('') || `<p class="muted small">${L('No steps yet.', 'Belum ada langkah.')}</p>`;
}

document.querySelectorAll('#periodSeg button').forEach(btn => {
  btn.onclick = () => {
    document.querySelectorAll('#periodSeg button').forEach(b => b.setAttribute('aria-pressed', 'false'));
    btn.setAttribute('aria-pressed', 'true');
    currentPeriod = btn.dataset.p;
    loadDashboard();
  };
});

// --- RENDER RIWAYAT ---
async function loadLogView() {
  document.getElementById('calMonthTitle').textContent = `${activeMonths()[calMonth - 1]} ${calYear}`;

  const activity = await api.getMonthActivity({ year: calYear, month: calMonth });
  const calEl = document.getElementById('calContainer');

  let html = '';
  (lifeState.lang === 'id' ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'] : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']).forEach(d => {
    html += `<div class="dow">${d}</div>`;
  });

  const firstDay = new Date(calYear, calMonth - 1, 1).getDay();
  const offset = (firstDay + 6) % 7;
  for (let i = 0; i < offset; i++) {
    html += `<div></div>`;
  }

  const daysInMonth = new Date(calYear, calMonth, 0).getDate();
  const todayStr = getTodayStr();
  const now = new Date();
  const isCurrentMonth = calYear === now.getFullYear() && calMonth === (now.getMonth() + 1);
  document.getElementById('nextMonthBtn').disabled = isCurrentMonth;

  for (let d = 1; d <= daysInMonth; d++) {
    const dStr = `${calYear}-${String(calMonth).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const act = activity[dStr];
    const levelClass = act ? `l${act.level}` : '';
    const isSelected = dStr === selectedLogDay;
    const isFuture = dStr > todayStr;

    html += `
      <button class="day ${levelClass}" data-day="${dStr}" aria-pressed="${isSelected}"
              ${isFuture ? 'disabled' : ''} aria-label="${d} ${activeMonths()[calMonth - 1]}">
        ${d}
      </button>
    `;
  }

  calEl.innerHTML = html;

  calEl.querySelectorAll('.day').forEach(b => {
    b.onclick = () => {
      selectedLogDay = b.dataset.day;
      loadLogView();
    };
  });

  await loadDayLogDetail(selectedLogDay);
}

async function loadDayLogDetail(day) {
  const log = await api.getDayLog(day);

  document.getElementById('dayLogLabel').textContent = formatDisplayDate(day);
  document.getElementById('dayLogDone').innerHTML = `${log.completedTasks}<small> ${L('of', 'dari')} ${log.totalTasks} ${L('steps', 'langkah')}</small>`;
  document.getElementById('dayLogPoints').textContent = `+${log.completedTasks} ${L('points', 'poin')}`;
  document.getElementById('dayLogProgressBar').firstElementChild.style.width = `${log.rate}%`;

  const container = document.getElementById('dayLogGroups');
  if (log.groups.length === 0) {
    container.innerHTML = `<div class="card"><p class="muted" style="margin:0">${L('No records for this day.', 'Tidak ada catatan pada hari ini.')}</p></div>`;
    return;
  }

  container.innerHTML = log.groups.map(g => `
    <div class="card">
      <div class="head">
        <h2>${esc(g.name)}</h2>
        <span class="count">${g.doneCount}/${g.totalCount}</span>
      </div>
      <ul class="logs">
        ${g.tasks.map(t => `
          <li>
            <span class="ico ${t.done ? 'ok' : 'no'}">${t.done ? '✓' : '–'}</span>
            <span class="nm ${t.done ? '' : 'muted'}">
              ${esc(t.name)}
              ${!t.isActive ? `<span class="tag">${L('Inactive since', 'Nonaktif sejak')} ${fmtShortMs(t.deactivatedAt)}</span>` : ''}
            </span>
            <time>${esc(t.time)}</time>
          </li>
        `).join('')}
      </ul>
    </div>
  `).join('');
}

document.getElementById('prevMonthBtn').onclick = () => {
  calMonth--;
  if (calMonth < 1) { calMonth = 12; calYear--; }
  loadLogView();
};

document.getElementById('nextMonthBtn').onclick = () => {
  calMonth++;
  if (calMonth > 12) { calMonth = 1; calYear++; }
  loadLogView();
};

// --- RENDER NONAKTIF ---
async function refreshInactiveCount() {
  const { tasks, groups } = await api.getInactive();
  document.getElementById('navOff').textContent = tasks.length + groups.length;
  return { tasks, groups };
}

async function loadInactiveView() {
  const { tasks, groups } = await refreshInactiveCount();
  document.getElementById('offTasksCount').textContent = tasks.length;
  document.getElementById('offGroupsCount').textContent = groups.length;

  const tasksList = document.getElementById('offTasksList');
  if (tasks.length === 0) {
    tasksList.innerHTML = `<p class="muted small" style="margin:8px 0 0">${L('No inactive steps.', 'Tidak ada langkah nonaktif.')}</p>`;
  } else {
    tasksList.innerHTML = tasks.map(t => `
      <div class="off">
        <div>
          <p>${esc(t.name)}</p>
          <p class="muted small">${esc(t.group_name || L('Other', 'Lainnya'))} · ${L('deactivated', 'dinonaktifkan')} ${fmtShortMs(t.deactivated_at)} · ${t.completed_count} ${L('completions', 'kali selesai')}</p>
        </div>
        <div class="row" style="gap:8px;flex-wrap:wrap;justify-content:flex-end">
          <button class="btn react-t-btn" data-tid="${t.id}">${tr(lifeState.lang, 'restore_btn')}</button>
          <button class="btn del-perm-t-btn" data-tid="${t.id}" data-tname="${esc(t.name)}" style="color:var(--miss);border-color:var(--miss-soft)">${tr(lifeState.lang, 'delete_perm_btn')}</button>
        </div>
      </div>
    `).join('');
  }

  const groupsList = document.getElementById('offGroupsList');
  if (groups.length === 0) {
    groupsList.innerHTML = `<p class="muted small" style="margin:8px 0 0">${L('No inactive groups.', 'Tidak ada kelompok nonaktif.')}</p>`;
  } else {
    groupsList.innerHTML = groups.map(g => `
      <div class="off">
        <div>
          <p>${esc(g.name)}</p>
          <p class="muted small">${g.task_count} ${L('steps', 'langkah')} · ${L('deactivated', 'dinonaktifkan')} ${fmtShortMs(g.deactivated_at)}</p>
        </div>
        <button class="btn react-g-btn" data-gid="${g.id}">${tr(lifeState.lang, 'restore_btn')}</button>
      </div>
    `).join('');
  }

  document.querySelectorAll('.react-t-btn').forEach(btn => {
    btn.onclick = async () => {
      await api.reactivateTask(btn.dataset.tid);
      await loadInactiveView();
      await loadTodayData();
      showToast(L('Step restored.', 'Langkah dipulihkan.'));
    };
  });

  document.querySelectorAll('.del-perm-t-btn').forEach(btn => {
    btn.onclick = async () => {
      const tname = btn.dataset.tname || L('this step', 'langkah ini');
      const ok = window.confirm(L(
        `Permanently delete "${tname}" and its completion history? This cannot be undone.`,
        `Hapus permanen "${tname}" beserta riwayat ceklisnya? Tindakan ini tidak bisa dibatalkan.`,
      ));
      if (!ok) return;
      await api.deleteTaskPermanently(btn.dataset.tid);
      await loadInactiveView();
      await loadTodayData();
      showToast(L('Step permanently deleted.', 'Langkah dihapus permanen.'));
    };
  });

  document.querySelectorAll('.react-g-btn').forEach(btn => {
    btn.onclick = async () => {
      await api.reactivateGroup(btn.dataset.gid);
      await loadInactiveView();
      await loadTodayData();
      showToast(L('Group restored.', 'Kelompok dipulihkan.'));
    };
  });
}

// --- RENDER PENGATURAN & SIDEBAR SYNC ---
function updateSidebarSync(s) {
  document.getElementById('sidebarSyncSub').textContent = `Port ${s.syncPort}`;
  if (s.pairedDevices && s.pairedDevices.length > 0) {
    const latest = [...s.pairedDevices].sort((a, b) => (b.last_synced_at || 0) - (a.last_synced_at || 0))[0];
    const loc = lifeState.lang === 'id' ? 'id-ID' : 'en-US';
    const timeStr = latest.last_synced_at
      ? new Date(latest.last_synced_at).toLocaleTimeString(loc, { hour: '2-digit', minute: '2-digit' })
      : L('connected', 'terhubung');
    document.getElementById('sidebarSyncDevice').textContent = `${latest.device_name} · ${timeStr}`;
  } else {
    document.getElementById('sidebarSyncDevice').textContent = L('Waiting for phone', 'Menunggu ponsel');
  }
}

async function loadSettingsView() {
  const s = await api.getSettings();
  updateSidebarSync(s);

  const verEl = document.getElementById('appVersionLabel');
  if (verEl && s.appVersion) verEl.textContent = `${L('Version', 'Versi')} ${s.appVersion}`;
  if (s.prefs) applyPreferences(s.prefs);

  const ipEl = document.getElementById('desktopIpBadge');
  if (ipEl) {
    const hostDisp = (s.bindHost && s.bindHost !== '0.0.0.0') ? s.bindHost : (s.localIp || 'localhost');
    ipEl.textContent = `${hostDisp}:${s.syncPort}`;
  }

  const netHostIn = document.getElementById('settingsSyncHost');
  const netPortIn = document.getElementById('settingsSyncPort');
  const netSuggest = document.getElementById('desktopIpSuggestions');
  if (netHostIn) netHostIn.value = s.bindHost || '0.0.0.0';
  if (netPortIn) netPortIn.value = s.configuredPort || s.syncPort || 47800;
  if (netSuggest) {
    const opts = [{ address: '0.0.0.0', iface: L('All interfaces', 'Semua antarmuka') }, ...(s.localIps || [])];
    netSuggest.innerHTML = opts.map(o => `<option value="${esc(o.address)}">${esc(o.iface)}</option>`).join('');
  }
  updateSidebarSync(s);

  document.getElementById('settingsPairingCode').textContent = s.pairingCode;
  document.getElementById('syncStatusBadge').textContent = s.pairedDevices.length > 0 ? L('Connected', 'Terhubung') : L('Waiting', 'Menunggu');

  const list = document.getElementById('pairedDevicesList');
  if (s.pairedDevices.length === 0) {
    list.innerHTML = `<li class="muted">${L('No phone paired yet. Open Lifolio on your phone to connect over LAN.', 'Belum ada perangkat ponsel yang terhubung. Buka Lifolio di ponsel untuk menyambungkan lewat LAN.')}</li>`;
  } else {
    const loc = lifeState.lang === 'id' ? 'id-ID' : 'en-US';
    list.innerHTML = s.pairedDevices.map(d => {
      const syncTime = d.last_synced_at ? new Date(d.last_synced_at).toLocaleTimeString(loc, { hour: '2-digit', minute: '2-digit' }) : L('Never', 'Belum pernah');
      const expired = d.expires_at && Date.now() > d.expires_at;
      const expStr = d.expires_at ? (expired ? L('Expired', 'Kedaluwarsa') : `${L('Valid until', 'Berlaku hingga')} ${fmtShortMs(d.expires_at)}`) : '';
      return `
        <li>
          <div>
            <b>${esc(d.device_name)}</b><br>
            <span class="muted small">${L('Last sync', 'Terakhir sinkron')}: ${syncTime}${expStr ? ' · ' + expStr : ''}</span>
          </div>
          <button class="btn remove-dev-btn" data-did="${d.device_id}">${L('Disconnect', 'Putuskan')}</button>
        </li>
      `;
    }).join('');

    document.querySelectorAll('.remove-dev-btn').forEach(btn => {
      btn.onclick = async () => {
        await api.removeDevice(btn.dataset.did);
        await loadSettingsView();
        showToast(L('Device disconnected.', 'Perangkat diputuskan.'));
      };
    });
  }

  document.querySelectorAll('#ttlSeg button').forEach(btn => {
    const d = parseInt(btn.dataset.days, 10);
    btn.setAttribute('aria-pressed', d === s.tokenTtlDays ? 'true' : 'false');
    btn.onclick = async () => {
      await api.setTokenTtl(d);
      await loadSettingsView();
      showToast(L(`New token lifetime: ${d} days.`, `Masa berlaku token baru: ${d} hari.`));
    };
  });

  const autostartSwitch = document.getElementById('autostartSwitch');
  autostartSwitch.setAttribute('aria-checked', s.autostart ? 'true' : 'false');
  autostartSwitch.onclick = async () => {
    const next = autostartSwitch.getAttribute('aria-checked') !== 'true';
    await api.toggleAutostart(next);
    autostartSwitch.setAttribute('aria-checked', next ? 'true' : 'false');
  };

  const traySwitch = document.getElementById('minimizeToTraySwitch');
  traySwitch.setAttribute('aria-checked', s.minimizeToTray ? 'true' : 'false');
  traySwitch.onclick = async () => {
    const next = traySwitch.getAttribute('aria-checked') !== 'true';
    await api.toggleTray(next);
    traySwitch.setAttribute('aria-checked', next ? 'true' : 'false');
  };

  const autoSyncSwitch = document.getElementById('autoSyncSwitch');
  autoSyncSwitch.setAttribute('aria-checked', s.autoSync ? 'true' : 'false');
  autoSyncSwitch.onclick = async () => {
    const next = autoSyncSwitch.getAttribute('aria-checked') !== 'true';
    await api.toggleAutoSync(next);
    autoSyncSwitch.setAttribute('aria-checked', next ? 'true' : 'false');
  };
}

document.getElementById('rotateCodeBtn').onclick = async () => {
  const newCode = await api.rotateCode();
  document.getElementById('settingsPairingCode').textContent = newCode;
  showToast(L('New pairing code generated.', 'Kode sambungan baru dibuat.'));
};

const saveNetBtn = document.getElementById('saveSyncNetBtn');
if (saveNetBtn) {
  saveNetBtn.onclick = async () => {
    const host = (document.getElementById('settingsSyncHost').value || '0.0.0.0').trim() || '0.0.0.0';
    const port = parseInt(document.getElementById('settingsSyncPort').value, 10);
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      showToast(L('Invalid port (must be 1–65535).', 'Port tidak valid (harus 1–65535).'));
      return;
    }
    try {
      const res = await api.setNetworkConfig({ host, port });
      await loadSettingsView();
      showToast(L(`Sync server listening on ${res.bindHost}:${res.syncPort}`, `Server sinkron aktif di ${res.bindHost}:${res.syncPort}`));
    } catch (err) {
      showToast(`${L('Failed to apply endpoint', 'Gagal menerapkan endpoint')}: ${err.message}`);
    }
  };
}
const resetNetBtn = document.getElementById('resetSyncNetBtn');
if (resetNetBtn) {
  resetNetBtn.onclick = async () => {
    try {
      await api.setNetworkConfig({ host: '0.0.0.0', port: 47800 });
      await loadSettingsView();
      showToast(L('Sync endpoint reset to 0.0.0.0:47800', 'Endpoint sinkron diatur ulang ke 0.0.0.0:47800'));
    } catch (err) {
      showToast(`${L('Reset failed', 'Gagal mengatur ulang')}: ${err.message}`);
    }
  };
}

document.querySelectorAll('#themeSeg button').forEach(btn => {
  btn.onclick = () => applyTheme(btn.dataset.t);
});

document.getElementById('saveUserNameBtn').onclick = async () => {
  const val = document.getElementById('userNameInput').value.trim();
  if (!val) return;
  const prefs = await api.savePrefs({ userName: val });
  applyPreferences(prefs);
  showToast(L(`Greeting updated for ${prefs.userName}!`, `Sapaan diperbarui untuk ${prefs.userName}!`));
};

document.querySelectorAll('#paletteGrid [data-palette]').forEach(btn => {
  btn.onclick = async () => {
    const prefs = await api.savePrefs({ colorPalette: btn.dataset.palette });
    applyPreferences(prefs);
    showToast(`${L('Palette', 'Palet')}: ${PALETTE_LABELS[prefs.colorPalette] || prefs.colorPalette}`);
  };
});

document.querySelectorAll('#langSeg [data-lang]').forEach(btn => {
  btn.onclick = async () => {
    const prefs = await api.savePrefs({ language: btn.dataset.lang });
    applyPreferences(prefs);
    switchView(currentView);
    showToast(prefs.language === 'id' ? 'Bahasa Indonesia aktif.' : 'English language active.');
  };
});

document.getElementById('showChartsSwitch').onclick = async () => {
  const cur = document.getElementById('showChartsSwitch').getAttribute('aria-checked') === 'true';
  const prefs = await api.savePrefs({ showReportCharts: !cur });
  applyPreferences(prefs);
  showToast(prefs.showReportCharts ? L('Report charts shown.', 'Grafik laporan ditampilkan.') : L('Report charts hidden.', 'Grafik laporan disembunyikan.'));
};

document.getElementById('exportJsonBtn').onclick = async () => {
  const payload = await api.exportAllDataJson();
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `lifolio-backup-${currentDay}.json`;
  a.click();
  URL.revokeObjectURL(url);
  document.getElementById('backupStatusText').textContent = L(`Exported JSON backup (${currentDay}).`, `Cadangan JSON diekspor (${currentDay}).`);
  showToast(L('JSON backup exported.', 'Cadangan JSON diekspor.'));
};

document.getElementById('importJsonBtn').onclick = () => {
  document.getElementById('importJsonInput').click();
};
document.getElementById('importJsonInput').onchange = async e => {
  const file = e.target.files && e.target.files[0];
  if (!file) return;
  try {
    const text = await file.text();
    const parsed = JSON.parse(text);
    await api.importAllDataJson(parsed);
    const prefs = await api.getPrefs();
    applyPreferences(prefs);
    await loadTodayData();
    await loadSettingsView();
    document.getElementById('backupStatusText').textContent = L(`Restored backup from ${file.name}.`, `Cadangan dipulihkan dari ${file.name}.`);
    showToast(L('Backup restored successfully!', 'Cadangan berhasil dipulihkan!'));
  } catch (err) {
    showToast(`${L('Restore failed', 'Gagal memulihkan')}: ${err.message}`);
  }
  e.target.value = '';
};

const searchEl = document.getElementById('globalSearchInput');
if (searchEl) {
  searchEl.oninput = () => {
    lifeState.searchQuery = searchEl.value;
    if (currentView === 'dash') loadDashboard();
    else if (currentView === 'reports') loadModuleReportsView({ todayStr: currentDay, showToast, onAfterMutation: handleQuickAddSaved });
  };
}

// --- NAVIGATION ---
function getViewTitle(viewName) {
  if (viewName === 'dash') return `${tr(lifeState.lang, 'hello')}, ${appPrefs.userName || 'User'} ♡`;
  if (viewName === 'today') return tr(lifeState.lang, 'nav_today');
  if (viewName === 'rewards') return tr(lifeState.lang, 'nav_rewards');
  if (viewName === 'reports') return tr(lifeState.lang, `mod_${lifeState.reportModule}`);
  if (viewName === 'log') return tr(lifeState.lang, 'nav_history');
  if (viewName === 'off') return tr(lifeState.lang, 'nav_inactive');
  if (viewName === 'audit') return tr(lifeState.lang, 'nav_audit');
  if (viewName === 'settings') return tr(lifeState.lang, 'nav_settings');
  return 'Lifolio';
}

function getModuleMeta(mod) {
  const map = {
    productivity: { eyebrow: L('PLAN YOUR DAY', 'RENCANAKAN HARIMU'), sub: L('A gentle place for your plans and priorities.', 'Ruang tenang untuk rencana dan prioritasmu.') },
    finance: { eyebrow: L('YOUR MONEY, YOUR PACE', 'KEUANGANMU, RITMEMU'), sub: L('Keep track without making it complicated.', 'Catat keuangan tanpa membuatnya rumit.') },
    health: { eyebrow: L('CARE FOR YOUR BODY', 'RAWAT TUBUHMU'), sub: L('Track gently. Progress, not perfection.', 'Catat perlahan. Progres, bukan kesempurnaan.') },
    wellness: { eyebrow: L('A MOMENT FOR YOURSELF', 'WAKTU UNTUK DIRIMU'), sub: L('Notice how you feel, without judging it.', 'Kenali perasaanmu tanpa menghakimi.') },
    menstrual: { eyebrow: L('YOUR CYCLE, YOUR RECORD', 'SIKLUSMU, CATATANMU'), sub: L('Personal cycle notes and estimates.', 'Catatan siklus pribadi dan prakiraan.') },
    notes: { eyebrow: L('YOUR THOUGHTS LIVE HERE', 'TEMPAT PIKIRANMU TINGGAL'), sub: L('A quiet space to write things down.', 'Ruang tenang untuk menuliskan segalanya.') },
  };
  return map[mod] || { eyebrow: '', sub: '' };
}

function getViewSub(viewName) {
  if (viewName === 'dash') return L('A little progress is still progress.', 'Kemajuan kecil tetaplah kemajuan.');
  if (viewName === 'reports') return getModuleMeta(lifeState.reportModule).sub;
  if (viewName === 'rewards') return L('Earn points for showing up for yourself.', 'Kumpulkan poin dengan merawat dirimu.');
  if (viewName === 'settings') return L('Only app-level preferences and sync live here.', 'Pengaturan aplikasi dan sinkronisasi ada di sini.');
  return '';
}

function switchView(viewName) {
  if (document.activeElement && document.activeElement.tagName === 'INPUT') {
    document.activeElement.blur();
  }
  currentView = viewName;
  if (viewName !== 'today' && viewName !== 'rewards') {
    editMode = false;
  }
  if (viewName !== 'dash') {
    lifeState.customizeMode = false;
    lifeState.editSpaces = false;
  }

  document.querySelectorAll('.view').forEach(v => {
    v.classList.toggle('on', v.id === `v-${viewName}`);
  });

  document.querySelectorAll('.nav[data-view]').forEach(n => {
    const isMatch = n.dataset.view === viewName && (viewName !== 'reports' || !n.dataset.mod || n.dataset.mod === lifeState.reportModule);
    if (isMatch) n.setAttribute('aria-current', 'page');
    else n.removeAttribute('aria-current');
  });

  document.getElementById('viewTitle').textContent = getViewTitle(viewName);
  const subEl = document.getElementById('viewSub');
  if (subEl) {
    const subTxt = getViewSub(viewName);
    subEl.textContent = subTxt;
    subEl.hidden = !subTxt;
  }

  const editBtn = document.getElementById('editBtn');
  const canEdit = viewName === 'today' || viewName === 'rewards';
  editBtn.hidden = !canEdit;
  editBtn.setAttribute('aria-pressed', editMode ? 'true' : 'false');
  editBtn.textContent = editMode ? tr(lifeState.lang, 'done_btn') : tr(lifeState.lang, 'edit_btn');
  document.getElementById('calToggleBtn').hidden = viewName !== 'today';
  document.getElementById('dashCustomizeBtn').hidden = viewName !== 'dash';
  document.getElementById('dashCustomizeBtn').setAttribute('aria-pressed', lifeState.customizeMode ? 'true' : 'false');
  document.getElementById('dashCustomizeBtn').textContent = lifeState.customizeMode ? `✓ ${tr(lifeState.lang, 'done_btn')}` : tr(lifeState.lang, 'widgets_btn');
  document.getElementById('dashCatalogBtn').hidden = !(viewName === 'dash' && lifeState.customizeMode);
  document.getElementById('dashResetBtn').hidden = !(viewName === 'dash' && lifeState.customizeMode);
  document.getElementById('auditClearBtn').hidden = viewName !== 'audit';

  if (viewName === 'reports') {
    document.getElementById('currentDate').textContent = getModuleMeta(lifeState.reportModule).eyebrow || formatDisplayDate(currentDay);
  } else if (viewName === 'rewards') {
    document.getElementById('currentDate').textContent = L('CELEBRATE YOUR LITTLE WINS', 'RAYAKAN KEMENANGAN KECILMU');
  } else if (viewName === 'settings') {
    document.getElementById('currentDate').textContent = L('MAKE IT YOURS', 'SESUAIKAN DENGANMU');
  } else if (viewName !== 'today') {
    document.getElementById('currentDate').textContent = formatDisplayDate(currentDay);
  }

  document.getElementById('editNote').hidden = !(editMode && viewName === 'today');

  if (viewName === 'today') loadTodayData();
  else if (viewName === 'rewards') loadRewards();
  else if (viewName === 'dash') loadDashboard();
  else if (viewName === 'reports') loadModuleReportsView({ todayStr: currentDay, showToast, onAfterMutation: handleQuickAddSaved });
  else if (viewName === 'log') loadLogView();
  else if (viewName === 'off') loadInactiveView();
  else if (viewName === 'audit') loadAuditView({ todayStr: currentDay, showToast });
  else if (viewName === 'settings') loadSettingsView();
}

document.querySelectorAll('.nav[data-view]').forEach(btn => {
  btn.onclick = () => {
    if (btn.dataset.mod) lifeState.reportModule = btn.dataset.mod;
    switchView(btn.dataset.view);
  };
});

document.getElementById('collapseSidebarBtn').onclick = () => {
  document.getElementById('appShell').classList.toggle('collapsed');
};

document.getElementById('dashCustomizeBtn').onclick = () => {
  lifeState.customizeMode = !lifeState.customizeMode;
  switchView('dash');
};
document.getElementById('dashCatalogBtn').onclick = () => openWidgetCatalogModal({
  todayStr: currentDay,
  onOpenReport: (mod) => { lifeState.reportModule = mod; switchView('reports'); },
  onOpenRewards: () => switchView('rewards'),
  onOpenToday: () => switchView('today'),
  showToast,
});
document.getElementById('dashResetBtn').onclick = async () => {
  await api.resetDashboardLayout();
  showToast(L('Dashboard layout reset to default.', 'Tata letak dasbor dikembalikan ke bawaan.'));
  loadDashboard();
};

const editSpBtn = document.getElementById('editSpacesBtn');
if (editSpBtn) {
  editSpBtn.onclick = () => {
    lifeState.editSpaces = !lifeState.editSpaces;
    loadDashboard();
  };
}
const resetSpBtn = document.getElementById('resetSpacesBtn');
if (resetSpBtn) {
  resetSpBtn.onclick = async () => {
    await api.resetDashboardLayout();
    showToast(L('Spaces order & labels reset.', 'Urutan & label ruang dikembalikan.'));
    loadDashboard();
  };
}
document.getElementById('auditClearBtn').onclick = async () => {
  await api.clearAuditLogs();
  await refreshAuditBadge(currentDay);
  showToast(L('Audit Log cleared.', 'Log Audit dibersihkan.'));
  loadAuditView({ todayStr: currentDay, showToast });
};

const handleQuickAddSaved = async () => {
  await loadTodayData();
  await refreshAuditBadge(currentDay);
  if (currentView === 'dash') await loadDashboard();
  else if (currentView === 'reports') await loadModuleReportsView({ todayStr: currentDay, showToast });
  else if (currentView === 'audit') await loadAuditView({ todayStr: currentDay, showToast });
};
document.getElementById('globalQuickAddBtn').onclick = () => openQuickAddMenu({ todayStr: currentDay, showToast, onSaved: handleQuickAddSaved });
document.getElementById('sidebarQuickAdd').onclick = () => openQuickAddMenu({ todayStr: currentDay, showToast, onSaved: handleQuickAddSaved });
document.getElementById('lifeosModal').onclick = e => {
  if (e.target.id === 'lifeosModal') document.getElementById('lifeosModal').hidden = true;
};

document.getElementById('editBtn').onclick = () => {
  if (document.activeElement && document.activeElement.tagName === 'INPUT') {
    document.activeElement.blur();
  }
  editMode = !editMode;
  document.getElementById('editBtn').setAttribute('aria-pressed', editMode ? 'true' : 'false');
  document.getElementById('editBtn').textContent = editMode ? tr(lifeState.lang, 'done_btn') : tr(lifeState.lang, 'edit_btn');
  document.getElementById('editNote').hidden = !(editMode && currentView === 'today');

  if (currentView === 'today') loadTodayData();
  else if (currentView === 'rewards') loadRewards();
};

document.getElementById('toastUndo').onclick = () => {
  if (undoAction) {
    undoAction();
    undoAction = null;
  }
  document.getElementById('toast').hidden = true;
};

// --- INITIALIZE & PUSH LISTENERS ---
document.getElementById('currentDate').textContent = formatDisplayDate(currentDay);

api.onSyncUpdated(async () => {
  await loadTodayData();
  await refreshInactiveCount();
  await refreshAuditBadge(currentDay);
  const s = await api.getSettings();
  updateSidebarSync(s);
  if (currentView === 'rewards') loadRewards();
  if (currentView === 'dash') loadDashboard();
  if (currentView === 'reports') loadModuleReportsView({ todayStr: currentDay, showToast, onAfterMutation: handleQuickAddSaved });
  if (currentView === 'audit') loadAuditView({ todayStr: currentDay, showToast });
  if (currentView === 'log') loadLogView();
  if (currentView === 'settings') loadSettingsView();
});

api.onDevicePaired(async () => {
  const s = await api.getSettings();
  updateSidebarSync(s);
  if (currentView === 'settings') loadSettingsView();
  showToast(L('New device paired successfully!', 'Perangkat baru berhasil disambungkan!'));
});

function checkRollover() {
  const newDay = getTodayStr();
  if (newDay !== currentDay) {
    if (selectedTodayDate === currentDay) selectedTodayDate = newDay;
    currentDay = newDay;
    selectedLogDay = newDay;
    skippedTasks = {};
    document.getElementById('currentDate').textContent = formatDisplayDate(selectedTodayDate);
    loadTodayData();
  }
}

document.addEventListener('visibilitychange', () => {
  if (!document.hidden) checkRollover();
});
setInterval(checkRollover, 60000);

loadTodayData();
refreshInactiveCount();
refreshAuditBadge(currentDay);
api.getPrefs().then((prefs) => {
  applyPreferences(prefs);
  switchView('dash');
});
api.getSettings().then(updateSidebarSync);

document.getElementById('sidebarQuitBtn').onclick = () => api.quitApp();
document.getElementById('settingsQuitBtn').onclick = () => api.quitApp();

// --- MILESTONE 3: CALENDAR & SCHEDULE MODAL ---
document.getElementById('calToggleBtn').onclick = () => {
  showTodayCal = !showTodayCal;
  localStorage.setItem('langkah-kecil-cal', showTodayCal ? 'true' : 'false');
  renderTodayCalendar();
};

document.getElementById('todayCalPrevBtn').onclick = () => {
  todayCalMonth--;
  if (todayCalMonth < 1) { todayCalMonth = 12; todayCalYear--; }
  renderTodayCalendar();
};

document.getElementById('todayCalNextBtn').onclick = () => {
  todayCalMonth++;
  if (todayCalMonth > 12) { todayCalMonth = 1; todayCalYear++; }
  renderTodayCalendar();
};

document.getElementById('backTodayBtn').onclick = () => {
  selectedTodayDate = currentDay;
  const now = parseLocalDay(currentDay);
  todayCalYear = now.getFullYear();
  todayCalMonth = now.getMonth() + 1;
  loadTodayData();
};

document.getElementById('openEditFromNote').onclick = () => {
  document.getElementById('editBtn').click();
};

let schedEditingTask = null;
let draftFreq = 'daily';
let draftDays = [];

function openSchedModal(tid) {
  schedEditingTask = findTask(tid);
  if (!schedEditingTask) return;
  const dObj = parseLocalDay(selectedTodayDate);
  const isoDow = dObj.getDay() === 0 ? 7 : dObj.getDay();
  draftFreq = schedEditingTask.freq || 'daily';
  draftDays = Array.isArray(schedEditingTask.freq_days) ? [...schedEditingTask.freq_days] : [];
  if (draftFreq === 'weekly' && draftDays.length === 0) draftDays = [isoDow];
  if (draftFreq === 'monthly' && draftDays.length === 0) draftDays = [dObj.getDate()];
  document.getElementById('schedModalTitle').textContent = schedEditingTask.name || 'Langkah';
  renderSchedModal();
  document.getElementById('schedModal').hidden = false;
}

function renderSchedModal() {
  document.querySelectorAll('#freqTypeSeg button').forEach(b => {
    b.setAttribute('aria-pressed', b.dataset.f === draftFreq ? 'true' : 'false');
  });
  document.getElementById('panelWeekly').hidden = draftFreq !== 'weekly';
  document.getElementById('panelMonthly').hidden = draftFreq !== 'monthly';

  if (draftFreq === 'weekly') {
    const dowShort = lifeState.lang === 'id' ? DOW_SHORT_ID : DOW_SHORT_EN;
    const dowFull = lifeState.lang === 'id' ? DOW_FULL_ID : DOW_FULL_EN;
    let wh = '';
    for (let d = 1; d <= 7; d++) {
      wh += `<button type="button" class="pill-pick" data-dow="${d}" aria-pressed="${draftDays.includes(d)}">${dowShort[d]}</button>`;
    }
    const grid = document.getElementById('dowGrid');
    grid.innerHTML = wh;
    grid.querySelectorAll('[data-dow]').forEach(b => {
      b.onclick = () => {
        const v = Number(b.dataset.dow);
        const idx = draftDays.indexOf(v);
        if (idx === -1) draftDays.push(v);
        else if (draftDays.length > 1) draftDays.splice(idx, 1);
        draftDays.sort((a, b) => a - b);
        renderSchedModal();
      };
    });
    document.getElementById('schedSummary').textContent = `${L('Appears every', 'Muncul setiap')}: ${draftDays.map(d => dowFull[d]).join(', ')}.`;
  } else if (draftFreq === 'monthly') {
    let mh = '';
    for (let m = 1; m <= 31; m++) {
      mh += `<button type="button" class="dom-pick" data-dom="${m}" aria-pressed="${draftDays.includes(m)}">${m}</button>`;
    }
    const grid = document.getElementById('domGrid');
    grid.innerHTML = mh;
    grid.querySelectorAll('[data-dom]').forEach(b => {
      b.onclick = () => {
        const v = Number(b.dataset.dom);
        const idx = draftDays.indexOf(v);
        if (idx === -1) draftDays.push(v);
        else if (draftDays.length > 1) draftDays.splice(idx, 1);
        draftDays.sort((a, b) => a - b);
        renderSchedModal();
      };
    });
    document.getElementById('schedSummary').textContent = `${L('Appears every month on day(s)', 'Muncul setiap bulan pada tanggal')}: ${draftDays.join(', ')}.`;
  } else {
    document.getElementById('schedSummary').textContent = L('Appears every day (Daily).', 'Muncul setiap hari (Harian).');
  }
}

document.querySelectorAll('#freqTypeSeg button').forEach(b => {
  b.onclick = () => {
    const dObj = parseLocalDay(selectedTodayDate);
    const isoDow = dObj.getDay() === 0 ? 7 : dObj.getDay();
    draftFreq = b.dataset.f;
    if (draftFreq === 'weekly' && (draftDays.length === 0 || draftDays.some(x => x > 7))) draftDays = [isoDow];
    if (draftFreq === 'monthly' && draftDays.length === 0) draftDays = [dObj.getDate()];
    renderSchedModal();
  };
});

document.getElementById('closeSchedModalBtn').onclick =
document.getElementById('cancelSchedModalBtn').onclick = () => {
  document.getElementById('schedModal').hidden = true;
};

document.getElementById('schedModal').onclick = (e) => {
  if (e.target.id === 'schedModal') {
    document.getElementById('schedModal').hidden = true;
  }
};

document.getElementById('saveSchedModalBtn').onclick = async () => {
  if (schedEditingTask) {
    schedEditingTask.freq = draftFreq;
    schedEditingTask.freq_days = draftFreq === 'daily' ? [] : [...draftDays];
    await api.saveTask(schedEditingTask);
  }
  document.getElementById('schedModal').hidden = true;
  await loadTodayData();
  showToast(L('Activity schedule saved.', 'Jadwal aktivitas disimpan.'));
};

