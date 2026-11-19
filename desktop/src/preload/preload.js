const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getToday: (day) => ipcRenderer.invoke('checklist:get-today', day),
  toggleCheck: (data) => ipcRenderer.invoke('checklist:toggle-check', data),
  saveTask: (task) => ipcRenderer.invoke('checklist:save-task', task),
  deactivateTask: (id) => ipcRenderer.invoke('checklist:deactivate-task', id),
  reactivateTask: (id) => ipcRenderer.invoke('checklist:reactivate-task', id),
  deleteTaskPermanently: (id) => ipcRenderer.invoke('checklist:delete-task-permanently', id),
  saveGroup: (group) => ipcRenderer.invoke('checklist:save-group', group),
  moveGroup: (data) => ipcRenderer.invoke('checklist:move-group', data),
  deactivateGroup: (id) => ipcRenderer.invoke('checklist:deactivate-group', id),
  reactivateGroup: (id) => ipcRenderer.invoke('checklist:reactivate-group', id),
  getRewards: () => ipcRenderer.invoke('checklist:get-rewards'),
  saveReward: (reward) => ipcRenderer.invoke('checklist:save-reward', reward),
  deactivateReward: (id) => ipcRenderer.invoke('checklist:deactivate-reward', id),
  reactivateReward: (id) => ipcRenderer.invoke('checklist:reactivate-reward', id),
  claimReward: (data) => ipcRenderer.invoke('checklist:claim-reward', data),
  undoClaim: (claimId) => ipcRenderer.invoke('checklist:undo-claim', claimId),
  getClaims: () => ipcRenderer.invoke('checklist:get-claims'),
  getDashboard: (data) => ipcRenderer.invoke('checklist:get-dashboard', data),
  getDayLog: (day) => ipcRenderer.invoke('checklist:get-day-log', day),
  getMonthActivity: (data) => ipcRenderer.invoke('checklist:get-month-activity', data),
  getMonthSchedule: (data) => ipcRenderer.invoke('checklist:get-month-schedule', data),
  getInactive: () => ipcRenderer.invoke('checklist:get-inactive'),

  getLifeOsSummary: (day) => ipcRenderer.invoke('lifeos:get-summary', day),
  getDashboardLayout: () => ipcRenderer.invoke('lifeos:get-layout'),
  saveDashboardLayout: (layout) => ipcRenderer.invoke('lifeos:save-layout', layout),
  resetDashboardLayout: () => ipcRenderer.invoke('lifeos:reset-layout'),
  getModuleReport: (params) => ipcRenderer.invoke('lifeos:get-report', params),
  quickAdd: (payload) => ipcRenderer.invoke('lifeos:quick-add', payload),
  getProjects: () => ipcRenderer.invoke('lifeos:get-projects'),
  getEnvelopes: () => ipcRenderer.invoke('lifeos:get-envelopes'),
  getPrefs: () => ipcRenderer.invoke('lifeos:get-prefs'),
  savePrefs: (prefs) => ipcRenderer.invoke('lifeos:save-prefs', prefs),
  saveProject: (p) => ipcRenderer.invoke('lifeos:save-project', p),
  saveFocus: (fs) => ipcRenderer.invoke('lifeos:save-focus', fs),
  saveEnvelope: (env) => ipcRenderer.invoke('lifeos:save-envelope', env),
  saveFinanceEntry: (entry) => ipcRenderer.invoke('lifeos:save-finance-entry', entry),
  saveSavingsGoal: (goal) => ipcRenderer.invoke('lifeos:save-savings-goal', goal),
  saveRecurringBill: (bill) => ipcRenderer.invoke('lifeos:save-recurring-bill', bill),
  saveHealthEntry: (entry) => ipcRenderer.invoke('lifeos:save-health-entry', entry),
  saveWellnessEntry: (entry) => ipcRenderer.invoke('lifeos:save-wellness-entry', entry),
  saveMenstrualEntry: (entry) => ipcRenderer.invoke('lifeos:save-menstrual-entry', entry),
  saveNote: (note) => ipcRenderer.invoke('lifeos:save-note', note),
  deleteLifeOsItem: (table, id) => ipcRenderer.invoke('lifeos:delete-item', { table, id }),
  exportAllDataJson: () => ipcRenderer.invoke('lifeos:export-json'),
  importAllDataJson: (payload) => ipcRenderer.invoke('lifeos:import-json', payload),
  getAuditLogs: (params) => ipcRenderer.invoke('lifeos:get-audit-logs', params),
  logAudit: (entry) => ipcRenderer.invoke('lifeos:log-audit', entry),
  clearAuditLogs: () => ipcRenderer.invoke('lifeos:clear-audit-logs'),

  getSettings: () => ipcRenderer.invoke('settings:get'),
  rotateCode: () => ipcRenderer.invoke('settings:rotate-code'),
  removeDevice: (deviceId) => ipcRenderer.invoke('settings:remove-device', deviceId),
  toggleAutostart: (enabled) => ipcRenderer.invoke('settings:toggle-autostart', enabled),
  toggleTray: (enabled) => ipcRenderer.invoke('settings:toggle-tray', enabled),
  toggleAutoSync: (enabled) => ipcRenderer.invoke('settings:toggle-autosync', enabled),
  setTokenTtl: (days) => ipcRenderer.invoke('settings:set-token-ttl', days),
  setNetworkConfig: (cfg) => ipcRenderer.invoke('settings:set-network', cfg),
  quitApp: () => ipcRenderer.invoke('app:quit'),

  onSyncUpdated: (callback) => {
    const handler = (event, data) => callback(data);
    ipcRenderer.on('sync:data-updated', handler);
    return () => ipcRenderer.removeListener('sync:data-updated', handler);
  },
  onDevicePaired: (callback) => {
    const handler = (event, data) => callback(data);
    ipcRenderer.on('sync:device-paired', handler);
    return () => ipcRenderer.removeListener('sync:device-paired', handler);
  }
});
