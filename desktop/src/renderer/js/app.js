import {
  lifeState,
  loadLifeOsDashboard,
  openWidgetCatalogModal,
  loadModuleReportsView,
  loadAuditView,
  openQuickAddMenu,
  refreshAuditBadge,
} from './lifeos.js';

const api = window.electronAPI;

const DAYS = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
const MONTHS = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

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
  return `${DAYS[date.getDay()]}, ${d} ${MONTHS[m - 1]}`;
}

function fmtShortDay(dayStr) {
  if (!dayStr) return '';
  const parts = String(dayStr).split('-');
  if (parts.length < 3) return '';
  const m = parseInt(parts[1], 10) - 1;
  const d = parseInt(parts[2], 10);
  return `${d} ${MONTHS[m].slice(0, 3)}`;
}

function fmtShortMs(ms) {
  if (!ms) return '';
  const d = new Date(ms);
  return `${d.getDate()} ${MONTHS[d.getMonth()].slice(0, 3)}`;
}

const CHECK_SVG = `<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true">
  <path d="M3 8.5l3.2 3.2L13 4.8" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`;

let currentView = 'today';
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

const DOW_FULL = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const DOW_SHORT = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

function freqLabel(t) {
  if (!t || t.freq === 'daily' || !t.freq) return 'Setiap hari';
  const days = Array.isArray(t.freq_days) ? t.freq_days : (Array.isArray(t.freqDays) ? t.freqDays : []);
  if (t.freq === 'weekly') return days.map(d => DOW_FULL[d] || d).join(', ');
  if (t.freq === 'monthly') return 'Tanggal ' + days.join(', ');
  return 'Setiap hari';
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

applyTheme(localStorage.getItem('langkah-kecil-theme') || 'auto');

// --- RENDER TODAY & CHECKLIST CALENDAR ---
async function renderTodayCalendar() {
  const card = document.getElementById('todayCalCard');
  const toggleBtn = document.getElementById('calToggleBtn');
  card.hidden = !showTodayCal;
  toggleBtn.setAttribute('aria-pressed', showTodayCal ? 'true' : 'false');
  if (!showTodayCal) return;

  monthScheduleDots = await api.getMonthSchedule({ year: todayCalYear, month: todayCalMonth });
  document.getElementById('todayCalTitle').textContent = `${MONTHS[todayCalMonth - 1]} ${todayCalYear}`;

  const firstDay = new Date(todayCalYear, todayCalMonth - 1, 1).getDay();
  const offset = (firstDay + 6) % 7;
  const daysInMonth = new Date(todayCalYear, todayCalMonth, 0).getDate();

  let html = '';
  ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].forEach(d => {
    html += `<div class="dow">${d}</div>`;
  });
  for (let i = 0; i < offset; i++) html += '<div></div>';

  for (let day = 1; day <= daysInMonth; day++) {
    const dStr = `${todayCalYear}-${String(todayCalMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const dot = monthScheduleDots[dStr];
    const isToday = dStr === currentDay;
    const isSel = dStr === selectedTodayDate;
    html += `
      <button type="button" class="cday ${isToday ? 'today' : ''}" data-cday="${dStr}" aria-pressed="${isSel}" aria-label="${day} ${MONTHS[todayCalMonth - 1]}">
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
    document.getElementById('dateBannerText').textContent = 'Pratinjau jadwal mendatang (belum bisa dicentang).';
  } else if (isPast) {
    document.getElementById('dateBannerText').textContent = 'Melihat catatan tanggal sebelumnya.';
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

  let msg = 'Belum ada langkah terjadwal untuk tanggal ini.';
  if (total > 0) {
    if (isFuture) msg = 'Jadwal yang direncanakan pada tanggal ini.';
    else if (done === total) msg = 'Semua selesai hari ini. Kamu boleh istirahat.';
    else if (done === 0) msg = 'Belum mulai juga tidak apa-apa. Pilih satu yang paling kecil.';
    else msg = `Sudah ${done} langkah hari ini. Lanjut kalau masih ada tenaga.`;
  }

  document.getElementById('progressCard').innerHTML = `
    <div class="row" style="justify-content:space-between;align-items:baseline;margin-bottom:10px">
      <div class="big num">${done}<small> dari ${total} langkah</small></div>
      <div class="big num">${pct}<small>%</small></div>
    </div>
    <div class="progress" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${pct}" aria-label="Progres hari ini">
      <span style="width:${pct}%"></span>
    </div>
    <p class="muted small" style="margin:10px 0 0">${esc(msg)}</p>
    <div class="switch-row">
      <p><b>Hari berat</b><br><span class="muted small">Tampilkan hanya langkah inti (★).</span></p>
      <button class="switch" role="switch" id="liteSwitch" aria-checked="${liteMode}" aria-label="Mode hari berat"></button>
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
    document.getElementById('otherDayText').textContent = `${offDayCount} aktivitas mingguan/bulanan dijadwalkan di tanggal lain.`;
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
                 data-gid="${g.id}" value="${esc(g.name)}" placeholder="Nama kelompok" aria-label="Nama kelompok">
          <button class="move-g-btn" type="button" data-move-gid="${g.id}" data-dir="-1" ${isFirst ? 'disabled' : ''} title="Pindah ke atas" aria-label="Pindah kelompok ke atas">↑</button>
          <button class="move-g-btn" type="button" data-move-gid="${g.id}" data-dir="1" ${isLast ? 'disabled' : ''} title="Pindah ke bawah" aria-label="Pindah kelompok ke bawah">↓</button>
          <button class="btn deact-g-btn" data-gid="${g.id}">Nonaktifkan</button>
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
        const dueNote = t.scheduled === false ? '<span class="freq-tag offday">Bukan tanggal ini</span>' : '';
        html += `
          <li class="erow">
            <div class="erow-top">
              <button class="icon-btn core-btn ${t.core ? 'on' : ''}" data-tid="${t.id}" aria-pressed="${!!t.core}" aria-label="Tandai langkah inti">
                ${t.core ? '★' : '☆'}
              </button>
              <input class="text-in tname-input" id="t-${t.id}" data-tid="${t.id}" value="${esc(t.name)}" placeholder="Nama langkah" aria-label="Nama langkah">
              <button class="sched-btn ${cls}" type="button" data-sched="${t.id}" title="${esc(label)}" aria-label="Jadwal: ${esc(label)}">📅</button>
              <button class="icon-btn deact-t-btn" data-tid="${t.id}" aria-label="Nonaktifkan langkah">Nonaktifkan</button>
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
              <span class="nm">${esc(t.name)}${t.core && !liteMode ? '<span class="star">★ inti</span>' : ''}${badge}</span>
            </label>
          </li>
        `;
      }
    });
    html += `</ul>`;

    if (editMode) {
      html += `<button class="btn dashed add-t-btn" data-gid="${g.id}" style="margin-top:8px">+ Tambah langkah</button>`;
    }
    html += `</section>`;
  });

  if (editMode) {
    html += `<button class="btn dashed" id="addGroupBtn">+ Tambah kelompok</button>`;
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
      <p class="eyebrow">Selesai</p>
      <p class="focus-name">Semua langkah terjadwal sudah beres.</p>
      <p class="hint">Cek Hadiah kalau mau mengambil sesuatu.</p>
      <button class="btn primary" id="focusGoRewards">Lihat hadiah</button>
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
    <p class="eyebrow">Mulai dari sini</p>
    <p class="focus-name">${esc(next.name)}</p>
    <p class="hint">Cukup yang ini dulu. Yang lain boleh menunggu.</p>
    <div class="row">
      <button class="btn primary" id="focusDoneBtn" data-tid="${next.id}">Sudah selesai</button>
      <button class="btn" id="focusSkipBtn" data-tid="${next.id}">Lewati dulu</button>
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
        showToast('Langkah dinonaktifkan. Riwayat tetap tersimpan.', async () => {
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
        showToast('Kelompok dinonaktifkan. Riwayat tetap tersimpan.', async () => {
          await api.reactivateGroup(gid);
          await loadTodayData();
          await refreshInactiveCount();
        });
      };
    });

    document.querySelectorAll('.add-t-btn').forEach(btn => {
      btn.onclick = async () => {
        const gid = btn.dataset.gid;
        const saved = await api.saveTask({ group_id: gid, name: 'Langkah baru', core: 0 });
        await loadTodayData();
        const el = document.getElementById(`t-${saved.id}`);
        if (el) { el.focus(); el.select(); }
      };
    });

    const addGroupBtn = document.getElementById('addGroupBtn');
    if (addGroupBtn) {
      addGroupBtn.onclick = async () => {
        await api.saveGroup({ name: 'Kelompok baru', sort: todayData.groups.length });
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
  let html = '';

  rewards.forEach(r => {
    const canClaim = bal >= r.cost;
    const pct = Math.min(100, Math.round((bal / Math.max(1, r.cost)) * 100));

    if (editMode) {
      html += `
        <div class="card">
          <div class="row" style="flex-wrap:nowrap">
            <input class="text-in rname-in" data-rid="${r.id}" value="${esc(r.name)}" placeholder="Nama hadiah" aria-label="Nama hadiah">
            <input class="text-in num-in rcost-in" data-rid="${r.id}" type="number" min="1" max="999" value="${r.cost}" aria-label="Biaya poin">
            <button class="icon-btn deact-r-btn" data-rid="${r.id}" aria-label="Hapus hadiah">×</button>
          </div>
        </div>
      `;
    } else {
      html += `
        <div class="card">
          <p style="margin:0;font-weight:600">${esc(r.name)}</p>
          <p class="muted small num" style="margin:0 0 12px">${r.cost} poin</p>
          <div class="progress gold" style="margin-bottom:12px">
            <span style="width:${pct}%"></span>
          </div>
          <button class="btn ${canClaim ? 'gold' : ''} claim-btn" data-rid="${r.id}" ${canClaim ? '' : 'disabled'}>
            ${canClaim ? 'Ambil' : `Kurang ${r.cost - bal}`}
          </button>
        </div>
      `;
    }
  });

  if (editMode) {
    html += `<button class="btn dashed" id="addRewardBtn" style="grid-column:1/-1">+ Tambah hadiah</button>`;
  }

  container.innerHTML = html;

  const claimsList = document.getElementById('claimsList');
  if (claims.length === 0) {
    claimsList.innerHTML = '<li class="muted">Belum ada hadiah yang diambil.</li>';
  } else {
    claimsList.innerHTML = claims.slice(0, 10).map(c => `
      <li>
        <span>${esc(c.name)}</span>
        <span>${fmtShortDay(c.day)}</span>
      </li>
    `).join('');
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
        showToast('Hadiah dihapus.', async () => {
          await api.reactivateReward(rid);
          await loadRewards();
        });
      };
    });

    const addBtn = document.getElementById('addRewardBtn');
    if (addBtn) {
      addBtn.onclick = async () => {
        await api.saveReward({ name: 'Hadiah baru', cost: 10, sort: rewards.length });
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
          showToast(`Diambil: ${claim.name}. Nikmati tanpa rasa bersalah.`, async () => {
            const ok = await api.undoClaim(claim.id);
            if (!ok) {
              showToast('Sudah tersinkronisasi, tidak bisa diurungkan.');
            } else {
              await loadTodayData();
              await loadRewards();
            }
          });
        } catch (err) {
          showToast('Poin tidak mencukupi.');
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
    showToast,
  });
  const stats = await api.getDashboard({ period: currentPeriod, day: currentDay });

  document.getElementById('periodNote').textContent = `${stats.label} · ${stats.rate}% selesai`;
  document.getElementById('mRate').textContent = stats.rate;
  document.getElementById('mDone').textContent = stats.totalDone;
  document.getElementById('mDays').innerHTML = `${stats.activeDays}<small>/${stats.daysCount}</small>`;
  document.getElementById('mStreakText').textContent = `hari aktif · beruntun ${stats.currentStreak} hari`;
  document.getElementById('mPts').textContent = `+${stats.pointsEarned}`;

  const maxDayCount = Math.max(...stats.dailyChart.map(d => d.count), 5);
  document.getElementById('chartMaxCount').textContent = `maks ${maxDayCount}`;

  const chartEl = document.getElementById('dailyChart');
  chartEl.innerHTML = stats.dailyChart.map(d => {
    const heightPct = d.count === 0 ? 0 : Math.max(6, Math.round((d.count / maxDayCount) * 100));
    return `
      <div class="bc">
        <i class="${d.isToday ? 'today' : ''}" style="height:${heightPct}%" title="${d.count} langkah"></i>
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
  `).join('') || '<p class="muted small">Belum ada kelompok.</p>';

  const taskStatsEl = document.getElementById('taskStatsContainer');
  taskStatsEl.innerHTML = stats.taskStats.slice(0, 8).map(t => `
    <div class="item">
      <div class="item-top">
        <span>
          ${esc(t.name)}
          ${t.freq && t.freq !== 'daily' ? `<span class="freq-tag ${t.freq === 'monthly' ? 'monthly' : ''}">${esc(freqLabel(t))}</span>` : ''}
          ${!t.isActive ? `<span class="tag">Nonaktif sejak ${fmtShortMs(t.deactivatedAt)}</span>` : ''}
        </span>
        <span>${t.done}/${t.totalDays}</span>
      </div>
      <div class="progress">
        <span style="width:${t.rate}%;${!t.isActive ? 'background:var(--box-line)' : ''}"></span>
      </div>
    </div>
  `).join('') || '<p class="muted small">Belum ada langkah.</p>';
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
  document.getElementById('calMonthTitle').textContent = `${MONTHS[calMonth - 1]} ${calYear}`;

  const activity = await api.getMonthActivity({ year: calYear, month: calMonth });
  const calEl = document.getElementById('calContainer');

  let html = '';
  ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].forEach(d => {
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
              ${isFuture ? 'disabled' : ''} aria-label="${d} ${MONTHS[calMonth - 1]}">
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
  document.getElementById('dayLogDone').innerHTML = `${log.completedTasks}<small> dari ${log.totalTasks} langkah</small>`;
  document.getElementById('dayLogPoints').textContent = `+${log.completedTasks} poin`;
  document.getElementById('dayLogProgressBar').firstElementChild.style.width = `${log.rate}%`;

  const container = document.getElementById('dayLogGroups');
  if (log.groups.length === 0) {
    container.innerHTML = '<div class="card"><p class="muted" style="margin:0">Tidak ada catatan pada hari ini.</p></div>';
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
              ${!t.isActive ? `<span class="tag">Nonaktif sejak ${fmtShortMs(t.deactivatedAt)}</span>` : ''}
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
    tasksList.innerHTML = '<p class="muted small" style="margin:8px 0 0">Tidak ada langkah nonaktif.</p>';
  } else {
    tasksList.innerHTML = tasks.map(t => `
      <div class="off">
        <div>
          <p>${esc(t.name)}</p>
          <p class="muted small">${esc(t.group_name || 'Lainnya')} · dinonaktifkan ${fmtShortMs(t.deactivated_at)} · ${t.completed_count} kali selesai</p>
        </div>
        <button class="btn react-t-btn" data-tid="${t.id}">Aktifkan lagi</button>
      </div>
    `).join('');
  }

  const groupsList = document.getElementById('offGroupsList');
  if (groups.length === 0) {
    groupsList.innerHTML = '<p class="muted small" style="margin:8px 0 0">Tidak ada kelompok nonaktif.</p>';
  } else {
    groupsList.innerHTML = groups.map(g => `
      <div class="off">
        <div>
          <p>${esc(g.name)}</p>
          <p class="muted small">${g.task_count} langkah · dinonaktifkan ${fmtShortMs(g.deactivated_at)}</p>
        </div>
        <button class="btn react-g-btn" data-gid="${g.id}">Aktifkan lagi</button>
      </div>
    `).join('');
  }

  document.querySelectorAll('.react-t-btn').forEach(btn => {
    btn.onclick = async () => {
      await api.reactivateTask(btn.dataset.tid);
      await loadInactiveView();
      await loadTodayData();
      showToast('Langkah diaktifkan kembali.');
    };
  });

  document.querySelectorAll('.react-g-btn').forEach(btn => {
    btn.onclick = async () => {
      await api.reactivateGroup(btn.dataset.gid);
      await loadInactiveView();
      await loadTodayData();
      showToast('Kelompok diaktifkan kembali.');
    };
  });
}

// --- RENDER PENGATURAN & SIDEBAR SYNC ---
function updateSidebarSync(s) {
  document.getElementById('sidebarSyncSub').textContent = `Port ${s.syncPort}`;
  if (s.pairedDevices && s.pairedDevices.length > 0) {
    const latest = [...s.pairedDevices].sort((a, b) => (b.last_synced_at || 0) - (a.last_synced_at || 0))[0];
    const timeStr = latest.last_synced_at
      ? new Date(latest.last_synced_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
      : 'terhubung';
    document.getElementById('sidebarSyncDevice').textContent = `${latest.device_name} · ${timeStr}`;
  } else {
    document.getElementById('sidebarSyncDevice').textContent = 'Menunggu ponsel';
  }
}

async function loadSettingsView() {
  const s = await api.getSettings();
  updateSidebarSync(s);

  const verEl = document.getElementById('appVersionLabel');
  if (verEl && s.appVersion) verEl.textContent = `Versi ${s.appVersion}`;

  document.getElementById('settingsPairingCode').textContent = s.pairingCode;
  document.getElementById('syncStatusBadge').textContent = s.pairedDevices.length > 0 ? 'Tersambung' : 'Menunggu';

  const list = document.getElementById('pairedDevicesList');
  if (s.pairedDevices.length === 0) {
    list.innerHTML = '<li class="muted">Belum ada perangkat ponsel yang terhubung. Buka Langkah Kecil di ponsel untuk menyambungkan otomatis.</li>';
  } else {
    list.innerHTML = s.pairedDevices.map(d => {
      const syncTime = d.last_synced_at ? new Date(d.last_synced_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : 'Belum pernah';
      const expired = d.expires_at && Date.now() > d.expires_at;
      const expStr = d.expires_at ? (expired ? 'Kedaluwarsa' : `Berlaku hingga ${fmtShortMs(d.expires_at)}`) : '';
      return `
        <li>
          <div>
            <b>${esc(d.device_name)}</b><br>
            <span class="muted small">Terakhir sinkron: ${syncTime}${expStr ? ' · ' + expStr : ''}</span>
          </div>
          <button class="btn remove-dev-btn" data-did="${d.device_id}">Putuskan</button>
        </li>
      `;
    }).join('');

    document.querySelectorAll('.remove-dev-btn').forEach(btn => {
      btn.onclick = async () => {
        await api.removeDevice(btn.dataset.did);
        await loadSettingsView();
        showToast('Perangkat diputuskan.');
      };
    });
  }

  document.querySelectorAll('#ttlSeg button').forEach(btn => {
    const d = parseInt(btn.dataset.days, 10);
    btn.setAttribute('aria-pressed', d === s.tokenTtlDays ? 'true' : 'false');
    btn.onclick = async () => {
      await api.setTokenTtl(d);
      await loadSettingsView();
      showToast(`Masa berlaku token baru: ${d} hari.`);
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
  showToast('Kode sambungan baru dibuat.');
};

document.querySelectorAll('#themeSeg button').forEach(btn => {
  btn.onclick = () => applyTheme(btn.dataset.t);
});

// --- NAVIGATION ---
const viewTitles = {
  today: 'Hari ini',
  rewards: 'Hadiah',
  dash: 'Dasbor Personal Life OS',
  reports: 'Laporan Modul',
  log: 'Riwayat',
  off: 'Nonaktif',
  audit: 'Audit Log · API & Sync',
  settings: 'Pengaturan'
};

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
  }

  document.querySelectorAll('.view').forEach(v => {
    v.classList.toggle('on', v.id === `v-${viewName}`);
  });

  document.querySelectorAll('.nav[data-view]').forEach(n => {
    const isMatch = n.dataset.view === viewName && (viewName !== 'reports' || !n.dataset.mod || n.dataset.mod === lifeState.reportModule);
    if (isMatch) n.setAttribute('aria-current', 'page');
    else n.removeAttribute('aria-current');
  });

  document.getElementById('viewTitle').textContent = viewTitles[viewName] || 'Langkah Kecil';

  const editBtn = document.getElementById('editBtn');
  const canEdit = viewName === 'today' || viewName === 'rewards';
  editBtn.hidden = !canEdit;
  editBtn.setAttribute('aria-pressed', editMode ? 'true' : 'false');
  editBtn.textContent = editMode ? 'Selesai mengubah' : 'Ubah';
  document.getElementById('calToggleBtn').hidden = viewName !== 'today';
  document.getElementById('dashCustomizeBtn').hidden = viewName !== 'dash';
  document.getElementById('dashCustomizeBtn').setAttribute('aria-pressed', lifeState.customizeMode ? 'true' : 'false');
  document.getElementById('dashCustomizeBtn').textContent = lifeState.customizeMode ? '✓ Selesai atur' : '⊞ Atur Widget';
  document.getElementById('dashCatalogBtn').hidden = !(viewName === 'dash' && lifeState.customizeMode);
  document.getElementById('dashResetBtn').hidden = !(viewName === 'dash' && lifeState.customizeMode);
  document.getElementById('auditClearBtn').hidden = viewName !== 'audit';

  if (viewName !== 'today') {
    document.getElementById('currentDate').textContent = formatDisplayDate(currentDay);
  }

  document.getElementById('editNote').hidden = !(editMode && viewName === 'today');

  if (viewName === 'today') loadTodayData();
  else if (viewName === 'rewards') loadRewards();
  else if (viewName === 'dash') loadDashboard();
  else if (viewName === 'reports') loadModuleReportsView({ todayStr: currentDay, showToast });
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
  showToast,
});
document.getElementById('dashResetBtn').onclick = async () => {
  await api.resetDashboardLayout();
  showToast('Tata letak dasbor dikembalikan ke bawaan.');
  loadDashboard();
};
document.getElementById('auditClearBtn').onclick = async () => {
  await api.clearAuditLogs();
  await refreshAuditBadge(currentDay);
  showToast('Audit Log dibersihkan.');
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
  document.getElementById('editBtn').textContent = editMode ? 'Selesai mengubah' : 'Ubah';
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
  if (currentView === 'reports') loadModuleReportsView({ todayStr: currentDay, showToast });
  if (currentView === 'audit') loadAuditView({ todayStr: currentDay, showToast });
  if (currentView === 'log') loadLogView();
  if (currentView === 'settings') loadSettingsView();
});

api.onDevicePaired(async () => {
  const s = await api.getSettings();
  updateSidebarSync(s);
  if (currentView === 'settings') loadSettingsView();
  showToast('Perangkat baru berhasil disambungkan!');
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
    let wh = '';
    for (let d = 1; d <= 7; d++) {
      wh += `<button type="button" class="pill-pick" data-dow="${d}" aria-pressed="${draftDays.includes(d)}">${DOW_SHORT[d]}</button>`;
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
    document.getElementById('schedSummary').textContent = `Muncul setiap: ${draftDays.map(d => DOW_FULL[d]).join(', ')}.`;
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
    document.getElementById('schedSummary').textContent = `Muncul setiap bulan pada tanggal: ${draftDays.join(', ')}.`;
  } else {
    document.getElementById('schedSummary').textContent = 'Muncul setiap hari (Harian).';
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
  showToast('Jadwal aktivitas disimpan.');
};

