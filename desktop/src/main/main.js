const { app, BrowserWindow, Tray, Menu, nativeImage } = require('electron');
const path = require('node:path');
const { Database } = require('./data/db');
const { Repository } = require('./data/repository');
const { SyncServer } = require('./services/syncServer');
const { DiscoveryService } = require('./services/discoveryService');
const { registerIpcHandlers } = require('./ipc/handlers');

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

function createTrayIcon() {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <rect width="16" height="16" rx="4" fill="#1D7487"/>
    <path d="M4 8.5l3 3L12 5" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
  return nativeImage.createFromDataURL('data:image/svg+xml;base64,' + Buffer.from(svg).toString('base64'));
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
  const icon = createTrayIcon();
  tray = new Tray(icon);
  tray.setToolTip('Langkah Kecil — Checklist & Kebiasaan');

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Buka Langkah Kecil',
      click: () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
          mainWindow.show();
          mainWindow.focus();
        }
      }
    },
    { type: 'separator' },
    {
      label: 'Sinkron aktif (Port ' + (syncServer ? syncServer.port : 47800) + ')',
      enabled: false
    },
    { type: 'separator' },
    {
      label: 'Keluar (Exit)',
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
    backgroundColor: '#F2F5F7',
    icon: createTrayIcon(),
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

  syncServer = new SyncServer(db, repository);
  const port = await syncServer.start(47800);
  console.log(`Sync Server listening on port ${port}`);

  discoveryService = new DiscoveryService(db, port);
  discoveryService.start();

  registerIpcHandlers(repository, db, syncServer, () => mainWindow, quitCompletely);

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
