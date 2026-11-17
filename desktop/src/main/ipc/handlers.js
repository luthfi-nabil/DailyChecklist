const { ipcMain, app } = require('electron');

function registerIpcHandlers(repository, db, syncServer, getMainWindow, onQuitApp) {
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
    return {
      deviceId: db.getMeta('device_id'),
      deviceName: db.getMeta('device_name') || 'Desktop',
      pairingCode: db.getMeta('pairing_code'),
      pairedDevices,
      syncPort: syncServer.port,
      autostart: loginSettings.openAtLogin,
      minimizeToTray: db.getMeta('minimize_to_tray') !== 'false',
      autoSync: db.getMeta('auto_sync') !== 'false',
      tokenTtlDays: ttlDays,
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
