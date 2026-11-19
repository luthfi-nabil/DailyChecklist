const { app, BrowserWindow, Tray, Menu, nativeImage } = require('electron');
const path = require('node:path');
const fs = require('node:fs');
const { Database } = require('./data/db');
const { Repository } = require('./data/repository');
const { SyncServer } = require('./services/syncServer');
const { DiscoveryService } = require('./services/discoveryService');
const { registerIpcHandlers } = require('./ipc/handlers');

app.setName('Lifolio');

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
  process.exit(0);
}

let mainWindow = null;
let tray = null;
let isQuitting = false;
let cleanedUp = false;
let db = null;
let repository = null;
let syncServer = null;
let discoveryService = null;

function createAppIcon(forTray = false) {
  const candidates = forTray
    ? [
        path.join(__dirname, '../assets/tray-icon.png'),
        path.join(__dirname, '../assets/icon.png'),
      ]
    : [
        path.join(__dirname, process.platform === 'win32' ? '../assets/icon.ico' : '../assets/icon.png'),
        path.join(__dirname, '../assets/icon.png'),
      ];
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      const img = nativeImage.createFromPath(p);
      if (!img.isEmpty()) return img;
    }
  }
  return nativeImage.createEmpty();
}

async function shutdownServices() {
  if (cleanedUp) return;
  cleanedUp = true;
  if (discoveryService) {
    discoveryService.stop();
    discoveryService = null;
  }
  if (syncServer) {
    await syncServer.stop();
    syncServer = null;
  }
  if (tray) {
    try {
      tray.destroy();
    } catch (_) {}
    tray = null;
  }
  if (db) {
    try {
      db.close();
    } catch (_) {}
    db = null;
  }
}

async function quitCompletely() {
  if (isQuitting) return;
  isQuitting = true;
  await shutdownServices();
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.destroy();
  }
  app.quit();
}

function setupAppMenu() {
  const template = [
    {
      label: 'Aplikasi',
      submenu: [
        {
          label: 'Sembunyikan ke Baki Sistem',
          click: () => {
            if (mainWindow && !mainWindow.isDestroyed()) {
              mainWindow.hide();
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Keluar (Exit)',
          accelerator: 'CmdOrCtrl+Q',
          click: () => {
            quitCompletely();
          }
        }
      ]
    },
    {
      label: 'Sunting',
      submenu: [
        { role: 'undo', label: 'Urungkan' },
        { role: 'redo', label: 'Ulangi' },
        { type: 'separator' },
        { role: 'cut', label: 'Potong' },
        { role: 'copy', label: 'Salin' },
        { role: 'paste', label: 'Tempel' },
        { role: 'selectAll', label: 'Pilih Semua' }
      ]
    },
    {
      label: 'Tampilan',
      submenu: [
        { role: 'reload', label: 'Muat Ulang' },
        { role: 'togglefullscreen', label: 'Layar Penuh' },
        { type: 'separator' },
        { role: 'toggleDevTools', label: 'Alat Pengembang' }
      ]
    }
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

function setupTray() {
  const icon = createAppIcon(true);
  if (tray) {
    try {
      tray.destroy();
    } catch (_) {}
  }
  tray = new Tray(icon);
  tray.setToolTip('Lifolio — Personal Life OS');

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Open Lifolio',
      click: () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
          mainWindow.show();
          mainWindow.focus();
        }
      }
    },
    { type: 'separator' },
    {
      label: 'Sync active (Port ' + (syncServer ? syncServer.port : 47800) + ')',
      enabled: false
    },
    { type: 'separator' },
    {
      label: 'Quit Lifolio',
      click: () => {
        quitCompletely();
      }
    }
  ]);

  tray.setContextMenu(contextMenu);
  tray.on('double-click', () => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1120,
    height: 780,
    minWidth: 800,
    minHeight: 560,
    title: 'Lifolio',
    backgroundColor: '#F2F5F7',
    icon: createAppIcon(false),
    webPreferences: {
      preload: path.join(__dirname, '../preload/preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

  mainWindow.on('close', (event) => {
    if (isQuitting) return;
    const minimizeToTray = db ? db.getMeta('minimize_to_tray') !== 'false' : true;
    if (minimizeToTray) {
      event.preventDefault();
      mainWindow.hide();
    } else {
      isQuitting = true;
    }
  });
}

app.on('second-instance', () => {
  if (mainWindow && !mainWindow.isDestroyed()) {
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.show();
    mainWindow.focus();
  }
});

app.whenReady().then(async () => {
  const dbPath = path.join(app.getPath('userData'), 'langkah_kecil.db');
  db = new Database(dbPath);
  repository = new Repository(db);

  const savedBindIp = (db.getMeta('sync_bind_ip') || '0.0.0.0').trim() || '0.0.0.0';
  const savedPort = Math.min(65535, Math.max(1, parseInt(db.getMeta('sync_port') || '47800', 10) || 47800));

  syncServer = new SyncServer(db, repository);
  let port;
  try {
    port = await syncServer.start(savedPort, savedBindIp, { fallbackRange: true });
  } catch (err) {
    console.warn(`Saved network endpoint ${savedBindIp}:${savedPort} failed (${err.message}); falling back to 0.0.0.0:47800`);
    db.setMeta('sync_bind_ip', '0.0.0.0');
    db.setMeta('sync_port', '47800');
    port = await syncServer.start(47800, '0.0.0.0', { fallbackRange: true });
  }
  console.log(`Sync Server listening on ${syncServer.host}:${port}`);

  discoveryService = new DiscoveryService(db, port);
  discoveryService.start();

  const onApplyNetworkConfig = async ({ host, port: nextPort }) => {
    const actualPort = await syncServer.restart(nextPort, host, { fallbackRange: false });
    if (discoveryService) discoveryService.updatePort(actualPort);
    setupTray();
    return { bindHost: syncServer.host, syncPort: actualPort };
  };

  registerIpcHandlers(repository, db, syncServer, () => mainWindow, quitCompletely, onApplyNetworkConfig);

  setupAppMenu();
  setupTray();

  const startHidden = process.argv.includes('--hidden');
  createWindow();
  if (startHidden) {
    mainWindow.hide();
  }
});

app.on('before-quit', () => {
  isQuitting = true;
});

app.on('will-quit', (event) => {
  if (!cleanedUp) {
    event.preventDefault();
    shutdownServices().then(() => app.exit(0));
  }
});

app.on('window-all-closed', () => {
  const minimizeToTray = db ? db.getMeta('minimize_to_tray') !== 'false' : true;
  if (isQuitting || !minimizeToTray || process.platform !== 'win32') {
    quitCompletely();
  }
});
