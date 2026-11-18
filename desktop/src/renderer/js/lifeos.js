const api = window.electronAPI;

const WIDGET_CATALOG = [
  { id: 'w-prod', module: 'Productivity', badge: 't-sage', title: 'Productivity & Fokus', reportMod: 'productivity', defaultSize: 'm' },
  { id: 'w-fin',  module: 'Finance', badge: 't-butter', title: 'Finance & Budget', reportMod: 'finance', defaultSize: 'm' },
  { id: 'w-hlth', module: 'Health', badge: 't-sky', title: 'Health & Hydration', reportMod: 'health', defaultSize: 's' },
  { id: 'w-well', module: 'Wellness', badge: 't-lavender', title: 'Wellness Check-in', reportMod: 'wellness', defaultSize: 's' },
  { id: 'w-mens', module: 'Menstrual Cycle', badge: 't-blush', title: 'Menstrual Cycle', reportMod: 'menstrual', defaultSize: 's' },
  { id: 'w-note', module: 'Notes & Journal', badge: 't-peach', title: 'Notes & Journal', reportMod: 'notes', defaultSize: 'm' },
  { id: 'w-rew',  module: 'Rewards', badge: 't-butter', title: 'Rewards & Poin', reportMod: null, defaultSize: 'm' },
];

export const lifeState = {
  customizeMode: false,
  reportModule: 'productivity',
  reportRange: 'week',
  customStart: '',
  customEnd: '',
  auditFilter: 'all',
  auditSource: 'all',
  dragWid: null,
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
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function renderWidgetBody(id, summary) {
  if (!summary) return '<p class="muted small">Memuat...</p>';
  if (id === 'w-prod') {
    const p = summary.productivity;
    const pct = p.total > 0 ? Math.round((p.done / p.total) * 100) : 0;
    return `
      <div class="big num">${p.done}<small> / ${p.total} langkah</small></div>
      <div class="progress"><span style="width:${pct}%"></span></div>
      <p class="muted small" style="margin:0">${pct}% selesai hari ini · ${p.focusMinutesToday} menit fokus tercatat</p>
    `;
  }
  if (id === 'w-fin') {
    const f = summary.finance;
    return `
      <div class="big num">${fmtRp(f.balance)}</div>
      <p class="muted small" style="margin:0">Masuk ${fmtRp(f.income)} · Keluar ${fmtRp(f.expense)} (${f.count} entri)</p>
    `;
  }
  if (id === 'w-hlth') {
    const h = summary.health;
    return `
      <div class="big num">${h.latestWeight !== null ? `${h.latestWeight} kg` : '—'}</div>
      <p class="muted small" style="margin:0">Air hari ini: ${Math.round(h.waterTodayMl)} ml · Kalori: ${Math.round(h.kcalToday)} kkal</p>
    `;
  }
  if (id === 'w-well') {
    const w = summary.wellness;
    return `
      <div class="big">${w ? esc(w.mood) : 'Belum ada'}</div>
      <p class="muted small" style="margin:0">${w ? `Energi ${w.energy}/5 · Stres ${w.stress}/5 · Tidur ${w.sleep_hours}j` : 'Belum ada mood check-in tersimpan.'}</p>
    `;
  }
  if (id === 'w-mens') {
    const m = summary.menstrual;
    return `
      <div class="big">${m ? `Hari ke-${m.cycle_day}` : 'Belum ada'}</div>
      <p class="muted small" style="margin:0">${m ? `${esc(m.phase)}${m.symptoms.length ? ' · ' + esc(m.symptoms.join(', ')) : ''}` : 'Belum ada catatan siklus tersimpan.'}</p>
    `;
  }
  if (id === 'w-note') {
    const n = summary.notes;
    return `
      <div class="big num">${n.count}<small> catatan</small></div>
      <p class="muted small" style="margin:0">${n.latestTitle ? `Terbaru: "${esc(n.latestTitle)}"` : 'Belum ada catatan jurnal tersimpan.'}</p>
    `;
  }
  if (id === 'w-rew') {
    const r = summary.rewards;
    return `
      <div class="big num">${r.balance}<small> poin tersedia</small></div>
      <p class="muted small" style="margin:0">${r.activeCount} hadiah aktif tersedia</p>
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

export async function loadLifeOsDashboard({ todayStr, onOpenReport, showToast }) {
  const summary = await api.getLifeOsSummary(todayStr);
  const layout = summary.layout || [];
  const bar = document.getElementById('lifeosCustomBar');
  const grid = document.getElementById('lifeosWidgetGrid');
  const visCount = document.getElementById('lifeosVisCount');
  const badge = document.getElementById('navAuditErr');
  if (badge) {
    badge.textContent = String(summary.errorAuditCount || 0);
    badge.hidden = !summary.errorAuditCount;
  }

  bar.hidden = !lifeState.customizeMode;
  visCount.textContent = `${layout.filter(w => w.visible).length}/${layout.length} tampil`;

  const displayList = layout.filter(w => lifeState.customizeMode || w.visible);
  if (displayList.length === 0) {
    grid.innerHTML = `<div class="card" style="grid-column:span 12;text-align:center"><p class="muted" style="margin:0">Semua widget disembunyikan. Klik <b>Atur Widget → Tambah Widget</b> atau <b>Reset ke bawaan</b>.</p></div>`;
    return;
  }

  grid.innerHTML = displayList.map((cfg, idx) => {
    const def = WIDGET_CATALOG.find(d => d.id === cfg.id);
    if (!def) return '';
    return `
      <article class="widget-card ${lifeState.customizeMode ? 'customizing' : ''}"
               style="${!cfg.visible ? 'opacity:.52' : ''}"
               data-wid="${cfg.id}" data-size="${cfg.size || def.defaultSize}"
               draggable="${lifeState.customizeMode}">
        <div class="head" style="margin:0">
          <div>
            <span class="pill ${def.badge}">${def.module}</span>
            <h2 style="margin-top:6px">${def.title}</h2>
          </div>
          ${!lifeState.customizeMode && def.reportMod
            ? `<button class="mini-btn" type="button" data-open-rep="${def.reportMod}">Laporan →</button>`
            : (lifeState.customizeMode ? '<span class="small muted">⠿ Seret</span>' : '')}
        </div>
        ${renderWidgetBody(cfg.id, summary)}
        ${lifeState.customizeMode ? `
          <div class="w-edit-bar">
            <div class="row" style="gap:4px">
              <button class="mini-btn" type="button" data-wmove="${cfg.id}" data-dir="-1" ${idx === 0 ? 'disabled' : ''}>↑</button>
              <button class="mini-btn" type="button" data-wmove="${cfg.id}" data-dir="1" ${idx === displayList.length - 1 ? 'disabled' : ''}>↓</button>
              ${['s', 'm', 'l'].map(sz => `<button class="mini-btn" type="button" data-wsize="${cfg.id}" data-sz="${sz}" aria-pressed="${cfg.size === sz}">${sz.toUpperCase()}</button>`).join('')}
            </div>
            <div class="row" style="gap:4px">
              <button class="mini-btn" type="button" data-wvis="${cfg.id}">${cfg.visible ? '👁 Tampil' : '🚫 Sembunyi'}</button>
              <button class="mini-btn" type="button" data-wrem="${cfg.id}" style="color:var(--p-danger-ink)">✕</button>
            </div>
          </div>
        ` : ''}
      </article>
    `;
  }).join('');

  grid.querySelectorAll('[data-open-rep]').forEach(btn => {
    btn.onclick = () => onOpenReport(btn.dataset.openRep);
  });
  grid.querySelectorAll('[data-wmove]').forEach(btn => {
    btn.onclick = async () => {
      const i = layout.findIndex(w => w.id === btn.dataset.wmove);
      const j = i + Number(btn.dataset.dir);
      if (i >= 0 && j >= 0 && j < layout.length) {
        [layout[i], layout[j]] = [layout[j], layout[i]];
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wsize]').forEach(btn => {
    btn.onclick = async () => {
      const w = layout.find(x => x.id === btn.dataset.wsize);
      if (w) {
        w.size = btn.dataset.sz;
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wvis]').forEach(btn => {
    btn.onclick = async () => {
      const w = layout.find(x => x.id === btn.dataset.wvis);
      if (w) {
        w.visible = !w.visible;
        await api.saveDashboardLayout(layout);
        await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
      }
    };
  });
  grid.querySelectorAll('[data-wrem]').forEach(btn => {
    btn.onclick = async () => {
      const next = layout.filter(x => x.id !== btn.dataset.wrem);
      await api.saveDashboardLayout(next);
      showToast('Widget dihapus. Bisa ditambah kembali lewat Tambah Widget.');
      await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
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
            await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
          }
        }
      });
    });
  }
}

export async function openWidgetCatalogModal({ todayStr, onOpenReport, showToast }) {
  const layout = await api.getDashboardLayout();
  const modal = document.getElementById('lifeosModal');
  const card = document.getElementById('lifeosModalCard');
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">Widget Catalog</p><h2>Tambah / Atur Visibilitas</h2></div>
      <button class="icon-btn" type="button" id="lmClose">×</button>
    </div>
    <ul class="list">
      ${WIDGET_CATALOG.map(def => {
        const cur = layout.find(w => w.id === def.id);
        return `
          <li>
            <span><span class="pill ${def.badge}">${def.module}</span> <b>${def.title}</b></span>
            ${cur
              ? `<button class="mini-btn" type="button" data-cvis="${def.id}">${cur.visible ? 'Tampil ✓' : 'Tersembunyi'}</button>`
              : `<button class="mini-btn" type="button" data-cadd="${def.id}">＋ Tambah</button>`}
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
      await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
      await openWidgetCatalogModal({ todayStr, onOpenReport, showToast });
    };
  });
  card.querySelectorAll('[data-cadd]').forEach(b => {
    b.onclick = async () => {
      const def = WIDGET_CATALOG.find(x => x.id === b.dataset.cadd);
      if (def) layout.push({ id: def.id, visible: true, size: def.defaultSize });
      await api.saveDashboardLayout(layout);
      await loadLifeOsDashboard({ todayStr, onOpenReport, showToast });
      await openWidgetCatalogModal({ todayStr, onOpenReport, showToast });
    };
  });
}

export async function loadModuleReportsView({ todayStr, showToast }) {
  const root = document.getElementById('reportsRoot');
  if (!lifeState.customEnd) {
    lifeState.customEnd = todayStr;
    lifeState.customStart = todayStr.slice(0, 8) + '01';
  }
  const rep = await api.getModuleReport({
    module: lifeState.reportModule,
    range: lifeState.reportRange,
    customStart: lifeState.customStart,
    customEnd: lifeState.customEnd,
    today: todayStr,
  });

  const mods = [
    { id: 'productivity', label: 'Productivity' },
    { id: 'finance', label: 'Finance' },
    { id: 'health', label: 'Health' },
    { id: 'wellness', label: 'Wellness' },
    { id: 'menstrual', label: 'Menstrual' },
    { id: 'notes', label: 'Notes & Journal' },
  ];

  let bodyHtml = '';
  if (lifeState.reportModule === 'productivity') {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num">${rep.completionRate}<small>%</small></div><p>task completion</p></div>
        <div class="card metric"><div class="big num">${rep.doneCount}<small>/${rep.scheduledCount}</small></div><p>selesai / terjadwal</p></div>
        <div class="card metric"><div class="big num">${rep.focusMinutes}<small>m</small></div><p>focus time</p></div>
        <div class="card metric"><div class="big num">${rep.projects.length}</div><p>proyek aktif</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <div class="head"><h2>Project Progress</h2><button class="mini-btn" type="button" id="repAddProjBtn">＋ Proyek / Fokus</button></div>
          ${rep.projects.length ? rep.projects.map(p => `
            <div class="item">
              <div class="item-top"><span>${esc(p.name)}</span><span class="num">${p.progress}%</span></div>
              <div class="progress"><span style="width:${p.progress}%"></span></div>
            </div>
          `).join('') : '<p class="muted small">Belum ada proyek tersimpan.</p>'}
        </div>
        <div class="card">
          <div class="head"><h2>Focus Sessions (${rep.focusSessions.length})</h2></div>
          ${rep.focusSessions.length ? `<ul class="list">${rep.focusSessions.map(f => `<li><span>${esc(f.note || 'Sesi fokus')}</span><span class="num">${f.day} · ${f.minutes} mnt</span></li>`).join('')}</ul>`
          : '<p class="muted small">Belum ada sesi fokus tercatat pada rentang ini.</p>'}
        </div>
      </div>
    `;
  } else if (lifeState.reportModule === 'finance') {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num" style="font-size:1.35rem">${fmtRp(rep.income)}</div><p>income</p></div>
        <div class="card metric"><div class="big num" style="font-size:1.35rem">${fmtRp(rep.expense)}</div><p>expenses</p></div>
        <div class="card metric"><div class="big num" style="font-size:1.35rem">${fmtRp(rep.savings)}</div><p>savings</p></div>
        <div class="card metric"><div class="big num" style="font-size:1.35rem">${fmtRp(rep.debt)}</div><p>debt</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <div class="head"><h2>Envelope Usage</h2><button class="mini-btn" type="button" id="repAddEnvBtn">＋ Amplop</button></div>
          ${rep.envelopeUsage.length ? rep.envelopeUsage.map(e => `
            <div class="item">
              <div class="item-top"><span>${esc(e.name)}</span><span class="num">${fmtRp(e.used)} / ${fmtRp(e.monthly_budget)}</span></div>
              <div class="progress"><span style="width:${e.pct}%"></span></div>
            </div>
          `).join('') : '<p class="muted small">Belum ada amplop anggaran tersimpan.</p>'}
        </div>
        <div class="card">
          <div class="head"><h2>Riwayat Transaksi (${rep.entries.length})</h2></div>
          ${rep.entries.length ? `<ul class="list">${rep.entries.map(e => `<li><span>${esc(e.note || e.category)} (${e.day})</span><span class="pill ${e.type === 'income' ? 't-sage' : 't-butter'} num">${e.type === 'income' ? '+' : '-'}${fmtRp(e.amount)}</span></li>`).join('')}</ul>`
          : '<p class="muted small">Belum ada entri keuangan pada rentang ini.</p>'}
        </div>
      </div>
    `;
  } else if (lifeState.reportModule === 'health') {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num">${rep.latestWeight !== null ? `${rep.latestWeight} kg` : '—'}</div><p>latest weight</p></div>
        <div class="card metric"><div class="big num">${rep.totalCalories}</div><p>calorie intake (kkal)</p></div>
        <div class="card metric"><div class="big num">${rep.totalWaterMl} ml</div><p>water intake</p></div>
        <div class="card metric"><div class="big num">${rep.totalWorkoutMin} mnt</div><p>workout duration</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <h2>Weight &amp; Body Measurements</h2>
          <ul class="list" style="margin-top:8px">
            ${rep.weightHistory.map(w => `<li><span>Berat badan (${w.day})</span><span class="num"><b>${w.value_num} kg</b>${w.value_num2 ? ` · Lingkar ${w.value_num2} cm` : ''}</span></li>`).join('')}
            ${rep.measurementLogs.map(m => `<li><span>${esc(m.name || 'Pengukuran')} (${m.day})</span><span class="num">${m.value_num} ${esc(m.unit || 'cm')}</span></li>`).join('')}
            ${(!rep.weightHistory.length && !rep.measurementLogs.length) ? '<li class="muted">Belum ada catatan berat atau ukuran tubuh.</li>' : ''}
          </ul>
        </div>
        <div class="card">
          <h2>Food, Water &amp; Workout History</h2>
          <ul class="list" style="margin-top:8px">
            ${rep.foodLogs.map(f => `<li><span>🍽 ${esc(f.name || 'Makanan')} (${f.day})</span><span class="num">${f.value_num} kkal</span></li>`).join('')}
            ${rep.workoutLogs.map(w => `<li><span>🏃 ${esc(w.name || 'Olahraga')} (${w.day})</span><span class="num">${w.value_num} mnt</span></li>`).join('')}
            ${rep.waterLogs.map(w => `<li><span>💧 Minum air (${w.day})</span><span class="num">${w.value_num} ml</span></li>`).join('')}
            ${(!rep.foodLogs.length && !rep.workoutLogs.length && !rep.waterLogs.length) ? '<li class="muted">Belum ada catatan pada rentang ini.</li>' : ''}
          </ul>
        </div>
      </div>
    `;
  } else if (lifeState.reportModule === 'wellness') {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num">${rep.avgMood || '—'}</div><p>rata-rata mood (/5)</p></div>
        <div class="card metric"><div class="big num">${rep.avgEnergy || '—'}</div><p>rata-rata energi (/5)</p></div>
        <div class="card metric"><div class="big num">${rep.avgStress || '—'}</div><p>rata-rata stres (/5)</p></div>
        <div class="card metric"><div class="big num">${rep.avgSleep ? `${rep.avgSleep}j` : '—'}</div><p>rata-rata tidur</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <h2>Check-in History (${rep.count})</h2>
          ${rep.entries.length ? `<ul class="list" style="margin-top:8px">${rep.entries.map(e => `<li><div><b>${esc(e.mood)}</b> (${e.day})<div class="small muted">Energi ${e.energy}/5 · Stres ${e.stress}/5 · Tidur ${e.sleep_hours}j</div></div><span>${esc(e.triggers_text || '')}</span></li>`).join('')}</ul>`
          : '<p class="muted small">Belum ada mood check-in pada rentang ini.</p>'}
        </div>
        <div class="card">
          <h2>Emotional Triggers</h2>
          <div class="row" style="margin-top:10px">
            ${rep.triggers.length ? rep.triggers.map(t => `<span class="pill t-lavender">${esc(t.name)} (${t.count})</span>`).join('')
            : '<p class="muted small">Belum ada pemicu emosional tercatat.</p>'}
          </div>
        </div>
      </div>
    `;
  } else if (lifeState.reportModule === 'menstrual') {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num">${rep.count}</div><p>total entri</p></div>
        <div class="card metric"><div class="big num">${rep.avgCycleDuration ? `${rep.avgCycleDuration} hr` : '—'}</div><p>rata-rata durasi siklus</p></div>
        <div class="card metric"><div class="big num">${rep.periodCount}</div><p>period starts</p></div>
        <div class="card metric"><div class="big" style="font-size:1.3rem">${rep.latestPhase ? esc(rep.latestPhase) : '—'}</div><p>fase terakhir</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <h2>Cycle &amp; Period History</h2>
          ${rep.entries.length ? `<ul class="list" style="margin-top:8px">${rep.entries.map(e => `<li><span><b>${esc(e.phase)}</b> · Hari ke-${e.cycle_day} (${e.day})</span><span>${esc(e.symptoms.join(', ') || e.flow || '')}</span></li>`).join('')}</ul>`
          : '<p class="muted small">Belum ada catatan siklus menstruasi pada rentang ini.</p>'}
        </div>
        <div class="card">
          <h2>Gejala Tercatat</h2>
          <div class="row" style="margin-top:10px">
            ${rep.symptomSummary.length ? rep.symptomSummary.map(s => `<span class="pill t-blush">${esc(s.name)} (${s.count})</span>`).join('')
            : '<p class="muted small">Belum ada gejala tercatat.</p>'}
          </div>
        </div>
      </div>
    `;
  } else {
    bodyHtml = `
      <div class="metrics">
        <div class="card metric"><div class="big num">${rep.count}</div><p>writing entries</p></div>
        <div class="card metric"><div class="big num">${rep.totalWords}</div><p>total kata</p></div>
        <div class="card metric"><div class="big num">${rep.uniqueTags}</div><p>unique tags</p></div>
        <div class="card metric"><div class="big num" style="font-size:1.2rem">${rep.entries[0] ? rep.entries[0].day : '—'}</div><p>entri terbaru</p></div>
      </div>
      <div class="cols">
        <div class="card">
          <h2>Entry History</h2>
          ${rep.entries.length ? `<ul class="list" style="margin-top:8px">${rep.entries.map(n => `<li><div><b>${esc(n.title)}</b> (${n.day})<div class="small muted">${esc(n.body)}</div></div><span>${n.tags.map(t => '#' + esc(t)).join(' ')}</span></li>`).join('')}</ul>`
          : '<p class="muted small">Belum ada catatan pada rentang ini.</p>'}
        </div>
        <div class="card">
          <h2>Tags</h2>
          <div class="row" style="margin-top:10px">
            ${rep.tags.length ? rep.tags.map(t => `<span class="pill t-peach">#${esc(t.name)} (${t.count})</span>`).join('')
            : '<p class="muted small">Belum ada tag catatan.</p>'}
          </div>
        </div>
      </div>
    `;
  }

  root.innerHTML = `
    <div class="module-tabs">
      ${mods.map(m => `<button class="mod-tab" type="button" data-rmod="${m.id}" aria-selected="${lifeState.reportModule === m.id}">${m.label}</button>`).join('')}
    </div>
    <div class="card" style="padding:12px 16px">
      <div class="row" style="justify-content:space-between">
        <div class="seg" id="repRangeSeg">
          <button type="button" data-rng="week" aria-pressed="${lifeState.reportRange === 'week'}">Mingguan</button>
          <button type="button" data-rng="month" aria-pressed="${lifeState.reportRange === 'month'}">Bulanan</button>
          <button type="button" data-rng="year" aria-pressed="${lifeState.reportRange === 'year'}">Tahunan</button>
          <button type="button" data-rng="custom" aria-pressed="${lifeState.reportRange === 'custom'}">Rentang Kustom</button>
        </div>
        <div class="row">
          ${lifeState.reportRange === 'custom'
            ? `<input type="date" id="repStartIn" value="${lifeState.customStart}"> <span class="small muted">s/d</span> <input type="date" id="repEndIn" value="${lifeState.customEnd}">`
            : `<span class="small muted num">${rep.start} s/d ${rep.end}</span>`}
        </div>
      </div>
    </div>
    ${bodyHtml}
  `;

  root.querySelectorAll('[data-rmod]').forEach(b => {
    b.onclick = () => { lifeState.reportModule = b.dataset.rmod; loadModuleReportsView({ todayStr, showToast }); };
  });
  root.querySelectorAll('#repRangeSeg [data-rng]').forEach(b => {
    b.onclick = () => { lifeState.reportRange = b.dataset.rng; loadModuleReportsView({ todayStr, showToast }); };
  });
  const si = document.getElementById('repStartIn');
  const ei = document.getElementById('repEndIn');
  if (si && ei) {
    si.onchange = () => { lifeState.customStart = si.value; loadModuleReportsView({ todayStr, showToast }); };
    ei.onchange = () => { lifeState.customEnd = ei.value; loadModuleReportsView({ todayStr, showToast }); };
  }
  const addProjBtn = document.getElementById('repAddProjBtn');
  if (addProjBtn) {
    addProjBtn.onclick = () => openQuickAddForm('project', { todayStr, showToast, onSaved: () => loadModuleReportsView({ todayStr, showToast }) });
  }
  const addEnvBtn = document.getElementById('repAddEnvBtn');
  if (addEnvBtn) {
    addEnvBtn.onclick = () => openQuickAddForm('envelope', { todayStr, showToast, onSaved: () => loadModuleReportsView({ todayStr, showToast }) });
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
      <div class="card metric"><div class="big num">${allRangeLogs.length}</div><p>total audit log</p></div>
      <div class="card metric"><div class="big num">${syncFail}</div><p>sync / discovery failed</p></div>
      <div class="card metric"><div class="big num">${authWarn}</div><p>auth / 401 warnings</p></div>
      <div class="card metric"><div class="big num" style="font-size:1.1rem">${lastFail ? fmtDateTime(lastFail.created_at) : '—'}</div><p>gagal terakhir</p></div>
    </div>
    <div class="card" style="padding:12px 16px">
      <div class="row" style="justify-content:space-between">
        <div class="seg" id="audFilterSeg">
          <button type="button" data-af="all" aria-pressed="${lifeState.auditFilter === 'all'}">Semua</button>
          <button type="button" data-af="sync" aria-pressed="${lifeState.auditFilter === 'sync'}">Sync Failed</button>
          <button type="button" data-af="auth" aria-pressed="${lifeState.auditFilter === 'auth'}">Auth / 401</button>
          <button type="button" data-af="info" aria-pressed="${lifeState.auditFilter === 'info'}">Pulih</button>
        </div>
        <select id="audSrcSel" style="min-height:34px;padding:0 10px;border-radius:10px;border:1px solid var(--line);background:var(--bg)">
          <option value="all" ${lifeState.auditSource === 'all' ? 'selected' : ''}>Semua Sumber</option>
          <option value="Desktop" ${lifeState.auditSource === 'Desktop' ? 'selected' : ''}>Desktop Server</option>
          <option value="Mobile" ${lifeState.auditSource === 'Mobile' ? 'selected' : ''}>Mobile Client</option>
        </select>
      </div>
    </div>
    <div class="card">
      <div class="head">
        <h2>Riwayat Error API &amp; Sinkronisasi</h2>
        <span class="small muted">Token &amp; rahasia disanitasi · Disimpan lokal</span>
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
          ${l.details ? `<details class="audit-details"><summary>Detail teknis</summary><pre>${esc(JSON.stringify(l.details, null, 2))}</pre></details>` : ''}
        </div>
      `).join('') : '<p class="muted small" style="margin:8px 0 0">Tidak ada log error API atau sinkronisasi pada filter ini.</p>'}
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
    { k: 'task', ic: '✓', lbl: 'Add task', pill: 't-sage' },
    { k: 'finance', ic: 'Rp', lbl: 'Add income/expense', pill: 't-butter' },
    { k: 'food', ic: '🍽', lbl: 'Add food entry', pill: 't-sky' },
    { k: 'weight', ic: '⚖', lbl: 'Add weight entry', pill: 't-sky' },
    { k: 'water', ic: '💧', lbl: 'Add water intake', pill: 't-sky' },
    { k: 'workout', ic: '🏃', lbl: 'Add workout', pill: 't-sage' },
    { k: 'mood', ic: '◐', lbl: 'Mood check-in', pill: 't-lavender' },
    { k: 'menstrual', ic: '✿', lbl: 'Menstrual symptom', pill: 't-blush' },
    { k: 'note', ic: '✎', lbl: 'Create quick note', pill: 't-peach' },
  ];
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">Global Quick Add</p><h2>Catat Cepat Tanpa Pindah Halaman</h2></div>
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

  const envOpts = `<option value="">Tanpa amplop</option>` + envelopes.map(e => `<option value="${e.id}">${esc(e.name)}</option>`).join('');
  const projOpts = `<option value="">Tanpa proyek</option>` + projects.map(p => `<option value="${p.id}">${esc(p.name)}</option>`).join('');

  const defs = {
    task: { title: 'Add Task', fields: `<div class="field"><label>Nama langkah</label><input id="qf1" placeholder="Contoh: Tulis ringkasan harian"></div>` },
    finance: { title: 'Add Income / Expense', fields: `<div class="field"><label>Jenis</label><select id="qf1"><option value="expense">Pengeluaran</option><option value="income">Pemasukan</option></select></div><div class="field"><label>Kategori</label><select id="qf2"><option value="general">Umum</option><option value="savings">Tabungan (Savings)</option><option value="debt">Cicilan / Hutang (Debt)</option></select></div><div class="field"><label>Nominal (Rp)</label><input id="qf3" type="number" placeholder="50000"></div><div class="field"><label>Amplop</label><select id="qf4">${envOpts}</select></div><div class="field"><label>Catatan</label><input id="qf5" placeholder="Keterangan singkat"></div>` },
    food: { title: 'Add Food Entry', fields: `<div class="field"><label>Menu</label><input id="qf1" placeholder="Contoh: Nasi ayam panggang"></div><div class="field"><label>Kalori (kkal)</label><input id="qf2" type="number" placeholder="450"></div>` },
    weight: { title: 'Add Weight Entry', fields: `<div class="field"><label>Berat badan (kg)</label><input id="qf1" type="number" step="0.1" placeholder="62.5"></div><div class="field"><label>Lingkar pinggang (cm, opsional)</label><input id="qf2" type="number" step="0.5" placeholder="76"></div>` },
    water: { title: 'Add Water Intake', fields: `<div class="field"><label>Jumlah air (ml)</label><input id="qf1" type="number" step="50" value="250"></div>` },
    workout: { title: 'Add Workout', fields: `<div class="field"><label>Olahraga</label><input id="qf1" placeholder="Contoh: Jalan pagi"></div><div class="field"><label>Durasi (menit)</label><input id="qf2" type="number" value="30"></div>` },
    mood: { title: 'Mood Check-in', fields: `<div class="field"><label>Suasana hati</label><select id="qf1"><option value="Tenang|4">Tenang (4/5)</option><option value="Fokus|5">Fokus (5/5)</option><option value="Biasa|3">Biasa (3/5)</option><option value="Lelah|2">Lelah (2/5)</option><option value="Tertekan|1">Tertekan (1/5)</option></select></div><div class="field"><label>Energi (1-5)</label><input id="qf2" type="number" min="1" max="5" value="4"></div><div class="field"><label>Stres (1-5)</label><input id="qf3" type="number" min="1" max="5" value="2"></div><div class="field"><label>Durasi tidur (jam)</label><input id="qf4" type="number" step="0.5" value="7"></div><div class="field"><label>Pemicu emosional (pisahkan koma)</label><input id="qf5" placeholder="Contoh: tidur cukup, kerja tenang"></div>` },
    menstrual: { title: 'Menstrual Symptom Entry', fields: `<div class="field"><label>Fase siklus</label><select id="qf1"><option>Menstruasi</option><option>Fase Folikuler</option><option>Ovulasi</option><option>Fase Luteal</option></select></div><div class="field"><label>Hari ke-</label><input id="qf2" type="number" min="1" max="60" value="1"></div><div class="field"><label>Gejala (pisahkan koma)</label><input id="qf3" placeholder="Contoh: kram ringan, lelah"></div><div class="field"><label>Aliran / Flow</label><select id="qf4"><option value="None">Tidak ada</option><option value="Light">Ringan</option><option value="Medium">Sedang</option><option value="Heavy">Deras</option></select></div><div class="field"><label>Mulai haid hari ini?</label><select id="qf5"><option value="0">Tidak</option><option value="1">Ya (Hari 1 siklus baru)</option></select></div>` },
    note: { title: 'Create Quick Note', fields: `<div class="field"><label>Judul</label><input id="qf1" placeholder="Judul singkat"></div><div class="field"><label>Isi catatan</label><textarea id="qf2" rows="3" placeholder="Tulis pikiran atau refleksi..."></textarea></div><div class="field"><label>Tags (pisahkan koma)</label><input id="qf3" placeholder="refleksi, pagi"></div>` },
    project: { title: 'Tambah Proyek / Focus', fields: `<div class="field"><label>Nama proyek</label><input id="qf1" placeholder="Contoh: Rencana Sehat Q4"></div><div class="field"><label>Progres (%)</label><input id="qf2" type="number" min="0" max="100" value="25"></div><div class="field"><label>Atau catat sesi fokus hari ini (menit, opsional)</label><input id="qf3" type="number" min="0" placeholder="25"></div>` },
    envelope: { title: 'Tambah Amplop Anggaran', fields: `<div class="field"><label>Nama amplop</label><input id="qf1" placeholder="Contoh: Makan & Minum"></div><div class="field"><label>Anggaran bulanan (Rp)</label><input id="qf2" type="number" placeholder="1000000"></div>` },
    focus: { title: 'Catat Sesi Fokus', fields: `<div class="field"><label>Proyek</label><select id="qf1">${projOpts}</select></div><div class="field"><label>Durasi (menit)</label><input id="qf2" type="number" value="25"></div><div class="field"><label>Catatan</label><input id="qf3" placeholder="Fokus mengerjakan..."></div>` },
  };

  const def = defs[kind] || defs.task;
  card.innerHTML = `
    <div class="head" style="margin:0">
      <div><p class="eyebrow">Quick Add</p><h2>${def.title}</h2></div>
      <button class="icon-btn" type="button" id="qfBack">←</button>
    </div>
    ${def.fields}
    <div class="row" style="justify-content:flex-end">
      <button class="btn" type="button" id="qfCancel">Batal</button>
      <button class="btn primary" type="button" id="qfSave">Simpan</button>
    </div>
  `;
  modal.hidden = false;
  document.getElementById('qfBack').onclick = () => openQuickAddMenu({ todayStr, showToast, onSaved });
  document.getElementById('qfCancel').onclick = () => { modal.hidden = true; };
  document.getElementById('qfSave').onclick = async () => {
    const v = id => document.getElementById(id)?.value?.trim() || '';
    let payloadData = { day: todayStr };
    if (kind === 'task') payloadData = { name: v('qf1') || 'Langkah baru' };
    else if (kind === 'finance') payloadData = { day: todayStr, type: v('qf1'), category: v('qf2'), amount: Number(v('qf3')) || 0, envelope_id: v('qf4') || null, note: v('qf5') };
    else if (kind === 'food') payloadData = { day: todayStr, name: v('qf1') || 'Makanan', value_num: Number(v('qf2')) || 0, unit: 'kkal' };
    else if (kind === 'weight') payloadData = { day: todayStr, value_num: Number(v('qf1')) || 0, value_num2: v('qf2') ? Number(v('qf2')) : null, unit: 'kg' };
    else if (kind === 'water') payloadData = { day: todayStr, name: 'Minum air', value_num: Number(v('qf1')) || 250, unit: 'ml' };
    else if (kind === 'workout') payloadData = { day: todayStr, name: v('qf1') || 'Olahraga', value_num: Number(v('qf2')) || 20, unit: 'mnt' };
    else if (kind === 'mood') {
      const [mood, sc] = (v('qf1') || 'Tenang|4').split('|');
      payloadData = { day: todayStr, mood, mood_score: Number(sc), energy: Number(v('qf2')) || 3, stress: Number(v('qf3')) || 2, sleep_hours: Number(v('qf4')) || 7, triggers_text: v('qf5') };
    } else if (kind === 'menstrual') {
      payloadData = {
        day: todayStr, phase: v('qf1'), cycle_day: Number(v('qf2')) || 1,
        symptoms: v('qf3') ? v('qf3').split(',').map(x => x.trim()).filter(Boolean) : [],
        flow: v('qf4'), is_period_start: v('qf5') === '1'
      };
    } else if (kind === 'note') {
      payloadData = { day: todayStr, title: v('qf1') || 'Catatan cepat', body: v('qf2'), tags_text: v('qf3') };
    } else if (kind === 'project') {
      const savedProj = await api.quickAdd({ kind: 'project', data: { name: v('qf1') || 'Proyek', progress: Number(v('qf2')) || 0 } });
      if (Number(v('qf3')) > 0) {
        await api.quickAdd({ kind: 'focus', data: { day: todayStr, project_id: savedProj.id, minutes: Number(v('qf3')), note: savedProj.name } });
      }
      modal.hidden = true;
      showToast('Proyek disimpan.');
      await onSaved();
      return;
    } else if (kind === 'envelope') {
      payloadData = { name: v('qf1') || 'Amplop baru', monthly_budget: Number(v('qf2')) || 0 };
    } else if (kind === 'focus') {
      payloadData = { day: todayStr, project_id: v('qf1') || null, minutes: Number(v('qf2')) || 25, note: v('qf3') };
    }

    await api.quickAdd({ kind, data: payloadData });
    modal.hidden = true;
    showToast(`${def.title} tersimpan.`);
    await onSaved();
  };
}
