const os = require('node:os');
const { ipcMain, app } = require('electron');

function getDesktopLanIps() {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) {
        ips.push({ iface: name, address: net.address });
      }
    }
  }
  return ips;
}

function registerIpcHandlers(repository, db, syncServer, getMainWindow, onQuitApp, onApplyNetworkConfig = null) {
  ipcMain.handle('app:quit', async () => {
    if (typeof onQuitApp === 'function') {
      await onQuitApp();
    }
    return true;
  });
  ipcMain.handle('checklist:get-today', async (event, day) => {
    return repository.getTodayData(day);
  });

  ipcMain.handle('checklist:toggle-check', async (event, { taskId, day, checked }) => {
    repository.toggleCheck(taskId, day, checked);
    return repository.getTodayData(day);
  });

  ipcMain.handle('checklist:save-task', async (event, task) => {
    return repository.saveTask(task);
  });

  ipcMain.handle('checklist:deactivate-task', async (event, id) => {
    repository.deactivateTask(id);
    return true;
  });

  ipcMain.handle('checklist:reactivate-task', async (event, id) => {
    repository.reactivateTask(id);
    return true;
  });

  ipcMain.handle('checklist:delete-task-permanently', async (event, id) => {
    return repository.deleteTaskPermanently(id);
  });

  ipcMain.handle('checklist:save-group', async (event, group) => {
    return repository.saveGroup(group);
  });

  ipcMain.handle('checklist:move-group', async (event, { id, delta }) => {
    return repository.moveGroup(id, delta);
  });

  ipcMain.handle('checklist:deactivate-group', async (event, id) => {
    repository.deactivateGroup(id);
    return true;
  });

  ipcMain.handle('checklist:reactivate-group', async (event, id) => {
    repository.reactivateGroup(id);
    return true;
  });

  ipcMain.handle('checklist:get-rewards', async () => {
    return repository.getRewards(false);
  });

  ipcMain.handle('checklist:save-reward', async (event, reward) => {
    return repository.saveReward(reward);
  });

  ipcMain.handle('checklist:deactivate-reward', async (event, id) => {
    repository.deactivateReward(id);
    return true;
  });

  ipcMain.handle('checklist:reactivate-reward', async (event, id) => {
    repository.reactivateReward(id);
    return true;
  });

  ipcMain.handle('checklist:claim-reward', async (event, { rewardId, day }) => {
    return repository.claimReward(rewardId, day);
  });

  ipcMain.handle('checklist:undo-claim', async (event, claimId) => {
    return repository.undoClaim(claimId);
  });

  ipcMain.handle('checklist:get-claims', async () => {
    return repository.getClaims();
  });

  ipcMain.handle('checklist:get-dashboard', async (event, { period, day }) => {
    return repository.getDashboardStats(period, day);
  });

  ipcMain.handle('checklist:get-day-log', async (event, day) => {
    return repository.getDayLog(day);
  });

  ipcMain.handle('checklist:get-month-activity', async (event, { year, month }) => {
    return repository.getMonthActivity(year, month);
  });

  ipcMain.handle('checklist:get-month-schedule', async (event, { year, month }) => {
    return repository.getMonthScheduleDots(year, month);
  });

  ipcMain.handle('checklist:get-inactive', async () => {
    return repository.getInactiveItems();
  });

  // --- PERSONAL LIFE OS & AUDIT LOG ---
  ipcMain.handle('lifeos:get-summary', async (event, day) => {
    return repository.getLifeOsSummary(day);
  });

  ipcMain.handle('lifeos:get-layout', async () => {
    return repository.getDashboardLayout();
  });

  ipcMain.handle('lifeos:save-layout', async (event, layout) => {
    return repository.saveDashboardLayout(layout);
  });

  ipcMain.handle('lifeos:reset-layout', async () => {
    return repository.resetDashboardLayout();
  });

  ipcMain.handle('lifeos:get-report', async (event, params) => {
    return repository.getModuleReport(params || {});
  });

  ipcMain.handle('lifeos:quick-add', async (event, payload) => {
    return repository.quickAdd(payload);
  });

  ipcMain.handle('lifeos:get-projects', async () => {
    return repository.getProjects();
  });

  ipcMain.handle('lifeos:get-envelopes', async () => {
    return repository.getEnvelopes();
  });

  ipcMain.handle('lifeos:get-prefs', async () => {
    return repository.getAppPreferences();
  });

  ipcMain.handle('lifeos:save-prefs', async (event, prefs) => {
    return repository.saveAppPreferences(prefs || {});
  });

  ipcMain.handle('lifeos:save-project', async (event, p) => {
    return repository.saveProject(p || {});
  });

  ipcMain.handle('lifeos:save-focus', async (event, fs) => {
    return repository.saveFocusSession(fs || {});
  });

  ipcMain.handle('lifeos:save-envelope', async (event, env) => {
    return repository.saveEnvelope(env || {});
  });

  ipcMain.handle('lifeos:save-finance-entry', async (event, entry) => {
    return repository.saveFinanceEntry(entry || {});
  });

  ipcMain.handle('lifeos:save-savings-goal', async (event, goal) => {
    return repository.saveSavingsGoal(goal || {});
  });

  ipcMain.handle('lifeos:save-recurring-bill', async (event, bill) => {
    return repository.saveRecurringBill(bill || {});
  });

  ipcMain.handle('lifeos:save-health-entry', async (event, entry) => {
    return repository.saveHealthEntry(entry || {});
  });

  ipcMain.handle('lifeos:save-wellness-entry', async (event, entry) => {
    return repository.saveWellnessEntry(entry || {});
  });

  ipcMain.handle('lifeos:save-menstrual-entry', async (event, entry) => {
    return repository.saveMenstrualEntry(entry || {});
  });

  ipcMain.handle('lifeos:save-note', async (event, note) => {
    return repository.saveNote(note || {});
  });

  ipcMain.handle('lifeos:delete-item', async (event, { table, id }) => {
    return repository._softDeleteRow(table, id);
  });

  ipcMain.handle('lifeos:export-json', async () => {
    return repository.exportAllDataJson();
  });

  ipcMain.handle('lifeos:import-json', async (event, payload) => {
    return repository.importAllDataJson(payload);
  });

  ipcMain.handle('lifeos:get-audit-logs', async (event, params) => {
    return repository.getAuditLogs(params || {});
  });

  ipcMain.handle('lifeos:log-audit', async (event, entry) => {
    return repository.logAudit(entry || {});
  });

  ipcMain.handle('lifeos:clear-audit-logs', async () => {
    return repository.clearAuditLogs();
  });

  ipcMain.handle('settings:get', async () => {
    const loginSettings = app.getLoginItemSettings();
    const ttlDays = Math.min(7, Math.max(3, parseInt(db.getMeta('token_ttl_days') || '7', 10) || 7));
    const pairedDevices = JSON.parse(db.getMeta('paired_devices') || '[]').map(d => ({
      device_id: d.device_id,
      device_name: d.device_name,
      paired_at: d.paired_at,
      expires_at: d.expires_at || (d.paired_at + ttlDays * 24 * 60 * 60 * 1000),
      last_synced_at: d.last_synced_at || null
    }));
    const ips = getDesktopLanIps();
    return {
      deviceId: db.getMeta('device_id'),
      deviceName: db.getMeta('device_name') || 'Desktop',
      pairingCode: db.getMeta('pairing_code'),
      pairedDevices,
      syncPort: syncServer.port,
      bindHost: db.getMeta('sync_bind_ip') || syncServer.host || '0.0.0.0',
      configuredPort: parseInt(db.getMeta('sync_port') || String(syncServer.port), 10) || syncServer.port,
      localIp: ips.length > 0 ? ips[0].address : null,
      localIps: ips,
      autostart: loginSettings.openAtLogin,
      minimizeToTray: db.getMeta('minimize_to_tray') !== 'false',
      autoSync: db.getMeta('auto_sync') !== 'false',
      tokenTtlDays: ttlDays,
      prefs: repository.getAppPreferences(),
      appVersion: app.getVersion()
    };
  });

  ipcMain.handle('settings:rotate-code', async () => {
    const newCode = Math.floor(100000 + Math.random() * 900000).toString();
    db.setMeta('pairing_code', newCode);
    return newCode;
  });

  ipcMain.handle('settings:remove-device', async (event, deviceId) => {
    const paired = JSON.parse(db.getMeta('paired_devices') || '[]');
    const filtered = paired.filter(d => d.device_id !== deviceId);
    db.setMeta('paired_devices', JSON.stringify(filtered));
    return true;
  });

  ipcMain.handle('settings:toggle-autostart', async (event, enabled) => {
    app.setLoginItemSettings({
      openAtLogin: enabled,
      args: ['--hidden']
    });
    return enabled;
  });

  ipcMain.handle('settings:toggle-tray', async (event, enabled) => {
    db.setMeta('minimize_to_tray', enabled ? 'true' : 'false');
    return enabled;
  });

  ipcMain.handle('settings:toggle-autosync', async (event, enabled) => {
    db.setMeta('auto_sync', enabled ? 'true' : 'false');
    return enabled;
  });

  ipcMain.handle('settings:set-token-ttl', async (event, days) => {
    const clamped = Math.min(7, Math.max(3, parseInt(days, 10) || 7));
    db.setMeta('token_ttl_days', String(clamped));
    return clamped;
  });

  ipcMain.handle('settings:set-network', async (event, payload) => {
    const rawHost = String((payload && payload.host) || '0.0.0.0').trim() || '0.0.0.0';
    const rawPort = parseInt(payload && payload.port, 10);
    if (!Number.isInteger(rawPort) || rawPort < 1 || rawPort > 65535) {
      throw new Error('Port must be between 1 and 65535.');
    }
    const ipv4Ok = /^(\d{1,3}\.){3}\d{1,3}$/.test(rawHost)
      && rawHost.split('.').every(n => Number(n) >= 0 && Number(n) <= 255);
    if (rawHost !== '0.0.0.0' && rawHost !== 'localhost' && !ipv4Ok) {
      throw new Error('Bind IP must be 0.0.0.0, localhost, or a valid IPv4 address.');
    }
    let applied = { bindHost: rawHost, syncPort: rawPort };
    if (typeof onApplyNetworkConfig === 'function') {
      applied = await onApplyNetworkConfig({ host: rawHost, port: rawPort });
    }
    db.setMeta('sync_bind_ip', applied.bindHost || rawHost);
    db.setMeta('sync_port', String(applied.syncPort || rawPort));
    return { ok: true, ...applied };
  });

  syncServer.on('sync_completed', (data) => {
    const win = getMainWindow();
    if (win && !win.isDestroyed()) {
      win.webContents.send('sync:data-updated', data);
    }
  });

  syncServer.on('device_paired', (device) => {
    const win = getMainWindow();
    if (win && !win.isDestroyed()) {
      win.webContents.send('sync:device-paired', device);
    }
  });
}

module.exports = { registerIpcHandlers };
